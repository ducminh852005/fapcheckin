import { collection, getCountFromServer, getDocs, limit, query, where } from "firebase/firestore"
import { firestore } from "../firebase/client"

export type LiveSessionItem = {
  id: string
  classCode: string
  subjectName: string
  slotCode: string
  sessionDate: string
  room: string
  teacherName: string
  teacherMemberCode: string
  presentCount: number
  totalCount: number
  statusText: string
  statusType: "live" | "full" | "closed"
}

export type SlotTimelineItem = {
  slotCode: string
  label: string
  timeRange: string
  period: string
  classCount: number
  sessionCount: number
  attendanceRate: number | null
  status: "live" | "completed" | "upcoming"
}

export type DashboardStats = {
  activeUsers: number
  totalUsers: number
  adminCount: number
  classes: number
  subjects: number
  openSessions: number
  totalSessions: number
  legacyAccounts: number
  pendingInvites: number
  pendingRequests: number
  unsyncedRecords: number
  warningCount: number
  checkedInStudents: number
  latencyMs: number
  liveSessions: LiveSessionItem[]
  slotTimeline: SlotTimelineItem[]
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const startTime = performance.now()

  const [
    activeUsersSnap,
    totalUsersSnap,
    adminsSnap,
    classesCountSnap,
    subjectsCountSnap,
    openSessionsCountSnap,
    totalSessionsCountSnap,
    legacyUsersSnap,
    invitesCountSnap,
    pendingRequestsSnap,
    unsyncedRecordsSnap,
    classesDocsSnap,
    timeSlotsSnap,
    slotsSnap,
    sessionsDocsSnap,
    teachersDocsSnap,
  ] = await Promise.all([
    getCountFromServer(query(collection(firestore, "users"), where("active", "==", true))),
    getCountFromServer(collection(firestore, "users")),
    getCountFromServer(query(collection(firestore, "users"), where("role", "==", "admin"))),
    getCountFromServer(collection(firestore, "classes")),
    getCountFromServer(collection(firestore, "subjects")),
    getCountFromServer(query(collection(firestore, "sessions"), where("sessionStatus", "==", "open"))),
    getCountFromServer(collection(firestore, "sessions")),
    getCountFromServer(query(collection(firestore, "users"), where("legacyRole", "in", ["SV", "GV"]))),
    getCountFromServer(collection(firestore, "user_invites")),
    getCountFromServer(query(collection(firestore, "requests"), where("status", "==", "pending"))),
    getCountFromServer(query(collection(firestore, "attendance_records"), where("syncedToFap", "==", false))),
    getDocs(query(collection(firestore, "classes"), limit(200))),
    getDocs(collection(firestore, "timeSlots")),
    getDocs(collection(firestore, "slots")),
    getDocs(query(collection(firestore, "sessions"), limit(50))),
    getDocs(query(collection(firestore, "users"), where("role", "==", "staff"), limit(100))),
  ])

  const latencyMs = Math.max(1, Math.round(performance.now() - startTime))

  // Map teachers by memberCode
  const teacherMap = new Map<string, string>()
  teachersDocsSnap.docs.forEach((d) => {
    const data = d.data()
    const code = String(data.memberCode ?? "").trim()
    const name = String(data.fullName ?? "").trim()
    if (code) teacherMap.set(code, name)
  })

  // Map classes by classCode
  const classMap = new Map<
    string,
    { subjectCode: string; subjectName: string; room: string; slotCode: string; studentCount: number; teacherMemberCode: string }
  >()
  classesDocsSnap.docs.forEach((d) => {
    const data = d.data()
    const classCode = String(data.classCode ?? d.id)
    classMap.set(classCode, {
      subjectCode: String(data.subjectCode ?? ""),
      subjectName: String(data.subjectName ?? ""),
      room: String(data.room ?? ""),
      slotCode: String(data.slotCode ?? ""),
      studentCount: Number(data.studentCount ?? 0),
      teacherMemberCode: String(data.teacherMemberCode ?? ""),
    })
  })

  // Map timeSlots
  const timeSlotMap = new Map<string, { startTime: string; endTime: string; period: string; daySlotNo: number }>()
  timeSlotsSnap.docs.forEach((d) => {
    const data = d.data()
    timeSlotMap.set(d.id, {
      startTime: String(data.startTime ?? ""),
      endTime: String(data.endTime ?? ""),
      period: String(data.period ?? ""),
      daySlotNo: Number(data.daySlotNo ?? 0),
    })
  })

  // Fetch attendance_records for the fetched sessions to compute real present/late/warning counts
  const rawSessions: Array<{ id: string } & Record<string, unknown>> = sessionsDocsSnap.docs.map((d) => ({
    id: d.id,
    ...(d.data() as Record<string, unknown>),
  }))

  // Sort sessions: open first, then by sessionDate desc
  rawSessions.sort((a, b) => {
    const aOpen = a.sessionStatus === "open" ? 0 : 1
    const bOpen = b.sessionStatus === "open" ? 0 : 1
    if (aOpen !== bOpen) return aOpen - bOpen
    return String(b.sessionDate ?? "").localeCompare(String(a.sessionDate ?? ""))
  })

  const sessionIdsForStats = rawSessions.slice(0, 30).map((s) => s.id)
  const recordsBySession = new Map<string, Array<Record<string, unknown>>>()
  let warningCount = 0
  let checkedInStudents = 0

  if (sessionIdsForStats.length > 0) {
    const recordsSnap = await getDocs(
      query(collection(firestore, "attendance_records"), where("sessionId", "in", sessionIdsForStats))
    )
    recordsSnap.docs.forEach((rDoc) => {
      const rData = rDoc.data()
      const sid = String(rData.sessionId ?? "")
      const list = recordsBySession.get(sid) ?? []
      list.push(rData)
      recordsBySession.set(sid, list)

      const st = String(rData.status ?? "").toLowerCase()
      if (st === "present" || st === "late" || st === "manualbygv") {
        checkedInStudents++
      }
      if (String(rData.networkVerificationResult ?? "") === "Mismatch") {
        warningCount++
      }
    })
  }

  // Build real liveSessions (top 5 open or most recent sessions from Firestore)
  const liveSessions: LiveSessionItem[] = rawSessions.slice(0, 5).map((s) => {
    const classCode = String(s.classCode ?? s.id)
    const cls = classMap.get(classCode)
    const teacherMemberCode = String(s.teacherMemberCode ?? cls?.teacherMemberCode ?? "")
    const teacherName = teacherMap.get(teacherMemberCode) || teacherMemberCode || "Chưa phân công"
    const records = recordsBySession.get(s.id) ?? []
    const presentCount = records.filter((r) => {
      const st = String(r.status ?? "").toLowerCase()
      return st === "present" || st === "late" || st === "manualbygv"
    }).length
    const totalCount = cls?.studentCount || records.length || 0
    const isOpen = String(s.sessionStatus ?? "") === "open"
    const isFull = totalCount > 0 && presentCount >= totalCount

    return {
      id: s.id,
      classCode,
      subjectName: cls?.subjectName ?? "",
      slotCode: String(s.slotCode ?? cls?.slotCode ?? ""),
      sessionDate: String(s.sessionDate ?? ""),
      room: String(s.room ?? cls?.room ?? "—"),
      teacherName,
      teacherMemberCode,
      presentCount,
      totalCount,
      statusText: isFull ? "Đã đủ 100%" : isOpen ? "Đang mở QR" : "Đã đóng",
      statusType: isFull ? "full" : isOpen ? "live" : "closed",
    }
  })

  // Build real Slot Timeline from Firestore slots/timeSlots + classes + sessions
  const sortedSlots = slotsSnap.docs
    .map((d) => {
      const data = d.data()
      const slotCode = String(data.slotCode ?? d.id)
      const timeSlotId = String(data.timeSlotId ?? "")
      const ts = timeSlotMap.get(timeSlotId)
      return {
        slotCode,
        timeSlotId,
        startTime: ts?.startTime ?? "",
        endTime: ts?.endTime ?? "",
        period: ts?.period ?? "",
      }
    })
    .sort((a, b) => a.slotCode.localeCompare(b.slotCode))

  const slotTimeline: SlotTimelineItem[] = sortedSlots.slice(0, 6).map((slot) => {
    const classesInSlot = Array.from(classMap.values()).filter((c) => c.slotCode === slot.slotCode)
    const sessionsInSlot = rawSessions.filter((s) => String(s.slotCode ?? "") === slot.slotCode)
    const hasOpen = sessionsInSlot.some((s) => s.sessionStatus === "open")

    let attended = 0
    let total = 0
    sessionsInSlot.forEach((s) => {
      const recs = recordsBySession.get(s.id) ?? []
      recs.forEach((r) => {
        total++
        const st = String(r.status ?? "").toLowerCase()
        if (st === "present" || st === "late" || st === "manualbygv") attended++
      })
    })

    const attendanceRate = total > 0 ? Number(((attended / total) * 100).toFixed(1)) : null
    const status: "live" | "completed" | "upcoming" = hasOpen
      ? "live"
      : sessionsInSlot.length > 0
        ? "completed"
        : "upcoming"

    return {
      slotCode: slot.slotCode,
      label: `Slot ${slot.slotCode}`,
      timeRange: slot.startTime && slot.endTime ? `${slot.startTime} - ${slot.endTime}` : slot.timeSlotId,
      period: slot.period === "Morning" ? "Sáng" : slot.period === "Afternoon" ? "Chiều" : slot.period,
      classCount: classesInSlot.length,
      sessionCount: sessionsInSlot.length,
      attendanceRate,
      status,
    }
  })

  const legacyUsersCount = legacyUsersSnap.data().count
  const invitesCount = invitesCountSnap.data().count

  return {
    activeUsers: activeUsersSnap.data().count,
    totalUsers: totalUsersSnap.data().count,
    adminCount: adminsSnap.data().count,
    classes: classesCountSnap.data().count,
    subjects: subjectsCountSnap.data().count,
    openSessions: openSessionsCountSnap.data().count,
    totalSessions: totalSessionsCountSnap.data().count,
    legacyAccounts: legacyUsersCount + invitesCount,
    pendingInvites: invitesCount,
    pendingRequests: pendingRequestsSnap.data().count,
    unsyncedRecords: unsyncedRecordsSnap.data().count,
    warningCount,
    checkedInStudents,
    latencyMs,
    liveSessions,
    slotTimeline,
  }
}
