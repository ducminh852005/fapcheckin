import {
  addDoc,
  collection,
  getCountFromServer,
  getDocs,
  limit,
  query,
  serverTimestamp,
} from "firebase/firestore"
import { firestore } from "../firebase/client"

export type AbsentSessionRecord = {
  date: string
  slot: string
  reason: string
}

export type StudentRiskItem = {
  id: string
  rollNumber: string
  fullName: string
  major: string
  subjectCode: string
  classCode: string
  teacherName: string
  absentCount: number
  maxAllowed: number
  percentOfMax: number
  attendanceRate: number
  riskLevel: "danger" | "warning_1" | "suspended"
  riskLabel: string
  lastAbsentDate?: string
  lastAbsentSlot?: string
  absentHistory?: AbsentSessionRecord[]
}

export type AttendanceReportStats = {
  averageAttendanceRate: number
  rateChange: number
  atRiskCount: number
  totalRecorded: number
  qrCodePercentage: number
  manualPercentage: number
  lowestClass: {
    subjectCode: string
    classCode: string
    attendanceRate: number
    highAbsentCount: number
  }
  slotAbsence: Array<{
    slot: string
    time: string
    rate: number
    highest?: boolean
  }>
  weeklyTrends: Array<{
    week: string
    rate: number
    isCurrent?: boolean
    isFuture?: boolean
  }>
  riskStudents: StudentRiskItem[]
}

export type PaginatedRiskStudentsResult = {
  items: StudentRiskItem[]
  totalCount: number
  page: number
  pageSize: number
  totalPages: number
}

function inferMajorFromRoll(rollNumber: string, explicitMajor?: unknown): string {
  if (typeof explicitMajor === "string" && explicitMajor.trim()) return explicitMajor.trim()
  const upper = rollNumber.toUpperCase()
  if (upper.startsWith("HE") || upper.startsWith("SE")) return "Kỹ thuật phần mềm (SE)"
  if (upper.startsWith("AI")) return "Trí tuệ nhân tạo (AI)"
  if (upper.startsWith("IA")) return "An toàn thông tin (IA)"
  if (upper.startsWith("GD")) return "Thiết kế mỹ thuật số (GD)"
  if (upper.startsWith("IS")) return "Hệ thống thông tin (IS)"
  if (upper.startsWith("IB") || upper.startsWith("BA")) return "Quản trị kinh doanh (BZ)"
  return "Công nghệ thông tin (IT)"
}

export async function getAttendanceReportStats(): Promise<AttendanceReportStats> {
  const [
    totalSnap,
    recordsSnap,
    sessionsSnap,
    classesSnap,
    enrollmentsSnap,
    slotsSnap,
    timesSnap,
    usersSnap,
  ] = await Promise.all([
    getCountFromServer(collection(firestore, "attendance_records")).catch(() => null),
    getDocs(query(collection(firestore, "attendance_records"), limit(1500))),
    getDocs(query(collection(firestore, "sessions"), limit(500))),
    getDocs(collection(firestore, "classes")),
    getDocs(query(collection(firestore, "enrollments"), limit(1500))),
    getDocs(collection(firestore, "slots")),
    getDocs(collection(firestore, "timeSlots")),
    getDocs(query(collection(firestore, "users"), limit(1000))),
  ])

  const totalRecorded = totalSnap ? totalSnap.data().count : recordsSnap.size

  // Map users (teachers and students)
  const teacherNames = new Map<string, string>()
  const studentProfiles = new Map<string, { fullName: string; major: string }>()
  usersSnap.docs.forEach((docSnap) => {
    const d = docSnap.data()
    const role = String(d.role ?? "")
    const memberCode = String(d.memberCode ?? "").trim()
    const rollNumber = String(d.rollNumber ?? d.memberCode ?? "").trim()
    const fullName = String(d.fullName ?? "").trim()
    if (["staff", "GV"].includes(role) && memberCode) {
      teacherNames.set(memberCode, fullName || memberCode)
    }
    if (rollNumber) {
      studentProfiles.set(rollNumber, {
        fullName,
        major: inferMajorFromRoll(rollNumber, d.major),
      })
    }
  })

  // Map timeSlots & slots
  const timeSlotsMap = new Map<string, { startTime: string; endTime: string }>()
  timesSnap.docs.forEach((docSnap) => {
    const d = docSnap.data()
    timeSlotsMap.set(docSnap.id, {
      startTime: String(d.startTime ?? "07:30"),
      endTime: String(d.endTime ?? "09:00"),
    })
  })

  const slotTimeLabelMap = new Map<string, string>()
  slotsSnap.docs.forEach((docSnap) => {
    const d = docSnap.data()
    const slotCode = String(d.slotCode ?? docSnap.id)
    const timeSlotId = String(d.timeSlotId ?? "")
    const time = timeSlotsMap.get(timeSlotId)
    if (time) {
      slotTimeLabelMap.set(slotCode, `${time.startTime} - ${time.endTime}`)
    }
  })

  // Map classes
  const classesMap = new Map<
    string,
    {
      classCode: string
      subjectCode: string
      teacherMemberCode: string
      teacherName: string
      slotCode: string
      studentCount: number
    }
  >()
  classesSnap.docs.forEach((docSnap) => {
    const d = docSnap.data()
    const classCode = String(d.classCode ?? docSnap.id)
    const teacherMemberCode = String(d.teacherMemberCode ?? "")
    classesMap.set(classCode, {
      classCode,
      subjectCode: String(d.subjectCode ?? classCode.split("_")[0] ?? "FAP"),
      teacherMemberCode,
      teacherName: teacherNames.get(teacherMemberCode) || teacherMemberCode || "Chưa phân công",
      slotCode: String(d.slotCode ?? ""),
      studentCount: Number(d.studentCount ?? 0),
    })
  })

  // Map sessions
  const sessionsMap = new Map<
    string,
    {
      id: string
      classCode: string
      subjectCode: string
      slotCode: string
      sessionDate: string
      status: string
    }
  >()
  const sessionsByClass = new Map<string, number>()
  sessionsSnap.docs.forEach((docSnap) => {
    const d = docSnap.data()
    const classCode = String(d.classCode ?? "")
    const cls = classesMap.get(classCode)
    const slotCode = String(d.slotCode ?? cls?.slotCode ?? "SLOT_1")
    const sessionDate = String(d.sessionDate ?? d.date ?? "")
    sessionsMap.set(docSnap.id, {
      id: docSnap.id,
      classCode,
      subjectCode: String(d.subjectCode ?? cls?.subjectCode ?? ""),
      slotCode,
      sessionDate,
      status: String(d.status ?? "closed").toLowerCase(),
    })
    if (classCode) {
      sessionsByClass.set(classCode, (sessionsByClass.get(classCode) ?? 0) + 1)
    }
  })

  // Map enrollments for fallback student metadata
  const enrollmentNameMap = new Map<string, { fullName: string; classCode: string }>()
  enrollmentsSnap.docs.forEach((docSnap) => {
    const d = docSnap.data()
    const roll = String(d.rollNumber ?? d.memberCode ?? "").trim()
    const classCode = String(d.classCode ?? "").trim()
    const fullName = String(d.fullName ?? "").trim()
    if (roll && classCode) {
      enrollmentNameMap.set(`${classCode}_${roll}`, { fullName, classCode })
    }
  })

  // Aggregate attendance_records
  let presentTotal = 0
  let lateTotal = 0
  let absentTotal = 0
  let qrCount = 0
  let manualCount = 0

  type StudentClassAgg = {
    classCode: string
    rollNumber: string
    fullName: string
    present: number
    late: number
    absent: number
    absentHistory: AbsentSessionRecord[]
  }
  const studentClassMap = new Map<string, StudentClassAgg>()
  const classAttendanceStats = new Map<string, { attended: number; total: number }>()
  const slotStats = new Map<string, { absent: number; total: number }>()
  const dateStats = new Map<string, { attended: number; total: number }>()

  recordsSnap.docs.forEach((docSnap) => {
    const d = docSnap.data()
    const sessionId = String(d.sessionId ?? "")
    const session = sessionsMap.get(sessionId)
    const classCode = String(d.classCode ?? session?.classCode ?? "").trim()
    const rollNumber = String(d.rollNumber ?? d.memberCode ?? d.studentId ?? "").trim()
    const statusRaw = String(d.status ?? "").toLowerCase()
    const methodRaw = String(d.method ?? d.checkInMethod ?? d.networkResult ?? "").toLowerCase()

    if (methodRaw.includes("manual") || methodRaw.includes("thủ công") || d.manualOverride === true) {
      manualCount += 1
    } else {
      qrCount += 1
    }

    const isPresent = statusRaw === "present" || statusRaw === "có mặt"
    const isLate = statusRaw === "late" || statusRaw === "đi muộn"
    const isAbsent = statusRaw === "absent" || statusRaw === "vắng" || statusRaw === "vắng mặt"

    if (isPresent) presentTotal += 1
    else if (isLate) lateTotal += 1
    else if (isAbsent) absentTotal += 1

    const counted = isPresent || isLate || isAbsent
    if (!counted) return

    // Update class stats
    if (classCode) {
      const cStat = classAttendanceStats.get(classCode) ?? { attended: 0, total: 0 }
      if (isPresent || isLate) cStat.attended += 1
      cStat.total += 1
      classAttendanceStats.set(classCode, cStat)
    }

    // Update slot stats
    const slotCode = String(d.slotCode ?? session?.slotCode ?? classesMap.get(classCode)?.slotCode ?? "SLOT_1")
    const sStat = slotStats.get(slotCode) ?? { absent: 0, total: 0 }
    if (isAbsent) sStat.absent += 1
    sStat.total += 1
    slotStats.set(slotCode, sStat)

    // Update date stats
    const recordDate = String(d.sessionDate ?? session?.sessionDate ?? "").slice(0, 10)
    if (recordDate) {
      const dStat = dateStats.get(recordDate) ?? { attended: 0, total: 0 }
      if (isPresent || isLate) dStat.attended += 1
      dStat.total += 1
      dateStats.set(recordDate, dStat)
    }

    // Update student+class risk aggregation
    if (rollNumber && classCode) {
      const key = `${classCode}_${rollNumber}`
      const profile = studentProfiles.get(rollNumber)
      const enrollInfo = enrollmentNameMap.get(key)
      const existing = studentClassMap.get(key) ?? {
        classCode,
        rollNumber,
        fullName:
          String(d.fullName ?? "").trim() ||
          profile?.fullName ||
          enrollInfo?.fullName ||
          rollNumber,
        present: 0,
        late: 0,
        absent: 0,
        absentHistory: [],
      }

      if (isPresent) existing.present += 1
      else if (isLate) existing.late += 1
      else if (isAbsent) {
        existing.absent += 1
        const dateStr = recordDate || "Học kỳ hiện tại"
        const timeRange = slotTimeLabelMap.get(slotCode) || "07:30 - 09:00"
        existing.absentHistory.push({
          date: dateStr,
          slot: `${slotCode} (${timeRange})`,
          reason: String(d.note ?? d.warning ?? "Vắng không phép"),
        })
      }
      studentClassMap.set(key, existing)
    }
  })

  const totalEvaluated = presentTotal + lateTotal + absentTotal
  const averageAttendanceRate =
    totalEvaluated > 0
      ? Number((((presentTotal + lateTotal) / totalEvaluated) * 100).toFixed(1))
      : 0

  const totalMethods = qrCount + manualCount
  const qrCodePercentage =
    totalMethods > 0 ? Number(((qrCount / totalMethods) * 100).toFixed(1)) : 0
  const manualPercentage =
    totalMethods > 0 ? Number((100 - qrCodePercentage).toFixed(1)) : 0

  // Build riskStudents from real studentClassMap where absent >= 1
  const riskStudents: StudentRiskItem[] = []
  const highAbsentPerClass = new Map<string, number>()

  studentClassMap.forEach((agg, key) => {
    if (agg.absent < 1) return
    const cls = classesMap.get(agg.classCode)
    const maxAllowed = 4
    const totalStudentSessions = Math.max(
      agg.present + agg.late + agg.absent,
      sessionsByClass.get(agg.classCode) ?? 0,
      1
    )
    const attended = agg.present + agg.late
    const attendanceRate = Number(((attended / totalStudentSessions) * 100).toFixed(1))
    const percentOfMax = Math.min(100, Math.round((agg.absent / maxAllowed) * 100))

    let riskLevel: "danger" | "warning_1" | "suspended" = "warning_1"
    let riskLabel = "Vắng 1–2 buổi"
    if (agg.absent >= maxAllowed) {
      riskLevel = "suspended"
      riskLabel = `Vắng từ ${maxAllowed} buổi`
    } else if (agg.absent >= maxAllowed - 1) {
      riskLevel = "danger"
      riskLabel = `Vắng ${maxAllowed - 1} buổi`
    }

    if (agg.absent >= 2) {
      highAbsentPerClass.set(agg.classCode, (highAbsentPerClass.get(agg.classCode) ?? 0) + 1)
    }

    const sortedHistory = [...agg.absentHistory].sort((a, b) => b.date.localeCompare(a.date))
    const latestAbsent = sortedHistory[0]
    const profile = studentProfiles.get(agg.rollNumber)

    riskStudents.push({
      id: key,
      rollNumber: agg.rollNumber,
      fullName: agg.fullName,
      major: profile?.major || inferMajorFromRoll(agg.rollNumber),
      subjectCode: cls?.subjectCode || agg.classCode.split("_")[0] || "FAP",
      classCode: agg.classCode,
      teacherName: cls?.teacherName || "Chưa phân công",
      absentCount: agg.absent,
      maxAllowed,
      percentOfMax,
      attendanceRate,
      riskLevel,
      riskLabel,
      lastAbsentDate: latestAbsent?.date,
      lastAbsentSlot: latestAbsent?.slot,
      absentHistory: sortedHistory,
    })
  })

  riskStudents.sort((a, b) => b.absentCount - a.absentCount || a.attendanceRate - b.attendanceRate)

  // Determine lowestClass from real classAttendanceStats
  let lowestClass = {
    subjectCode: "—",
    classCode: "Chưa có dữ liệu",
    attendanceRate: 0,
    highAbsentCount: 0,
  }

  let minRate = 101
  classAttendanceStats.forEach((stat, classCode) => {
    if (stat.total === 0) return
    const rate = Number(((stat.attended / stat.total) * 100).toFixed(1))
    if (rate < minRate) {
      minRate = rate
      const cls = classesMap.get(classCode)
      lowestClass = {
        subjectCode: cls?.subjectCode || classCode.split("_")[0] || classCode,
        classCode,
        attendanceRate: rate,
        highAbsentCount:
          highAbsentPerClass.get(classCode) ??
          riskStudents.filter((s) => s.classCode === classCode).length,
      }
    }
  })

  if (minRate === 101 && classesMap.size > 0) {
    const firstClass = Array.from(classesMap.values())[0]
    lowestClass = {
      subjectCode: firstClass.subjectCode,
      classCode: firstClass.classCode,
      attendanceRate: 100,
      highAbsentCount: 0,
    }
  }

  // Build slotAbsence from real slots / timeSlots / slotStats
  const slotEntries: Array<{ slot: string; time: string; rate: number; highest?: boolean }> = []
  const uniqueSlots = Array.from(slotTimeLabelMap.entries()).slice(0, 6)

  if (uniqueSlots.length > 0) {
    uniqueSlots.forEach(([slotCode, timeRange], idx) => {
      const sStat = slotStats.get(slotCode)
      const rate =
        sStat && sStat.total > 0 ? Number(((sStat.absent / sStat.total) * 100).toFixed(1)) : 0
      slotEntries.push({
        slot: slotCode.replace("_", " "),
        time: timeRange,
        rate,
        highest: false,
      })
      void idx
    })
  } else {
    slotStats.forEach((sStat, slotCode) => {
      const rate = sStat.total > 0 ? Number(((sStat.absent / sStat.total) * 100).toFixed(1)) : 0
      slotEntries.push({
        slot: slotCode,
        time: slotTimeLabelMap.get(slotCode) || "Ca tiêu chuẩn",
        rate,
        highest: false,
      })
    })
  }

  let maxSlotRate = -1
  let maxSlotIdx = -1
  slotEntries.forEach((entry, index) => {
    if (entry.rate > maxSlotRate && entry.rate > 0) {
      maxSlotRate = entry.rate
      maxSlotIdx = index
    }
  })
  if (maxSlotIdx >= 0) {
    slotEntries[maxSlotIdx].highest = true
  }

  // Build weeklyTrends from real session dates
  const sortedDates = Array.from(dateStats.keys()).sort()
  const weeklyTrends: Array<{
    week: string
    rate: number
    isCurrent?: boolean
    isFuture?: boolean
  }> = []

  if (sortedDates.length > 0) {
    const bucketCount = Math.min(6, sortedDates.length)
    const chunkSize = Math.max(1, Math.ceil(sortedDates.length / bucketCount))
    for (let i = 0; i < bucketCount; i++) {
      const slice = sortedDates.slice(i * chunkSize, (i + 1) * chunkSize)
      let att = 0
      let tot = 0
      slice.forEach((dt) => {
        const st = dateStats.get(dt)
        if (st) {
          att += st.attended
          tot += st.total
        }
      })
      const rate = tot > 0 ? Number(((att / tot) * 100).toFixed(1)) : averageAttendanceRate
      weeklyTrends.push({
        week: `T${i + 1}`,
        rate,
        isCurrent: i === bucketCount - 1,
      })
    }
    for (let w = weeklyTrends.length + 1; w <= 10; w++) {
      weeklyTrends.push({ week: `T${w}`, rate: 0, isFuture: true })
    }
  } else {
    for (let w = 1; w <= 10; w++) {
      weeklyTrends.push({
        week: `T${w}`,
        rate: w === 1 ? averageAttendanceRate : 0,
        isCurrent: w === 1,
        isFuture: w > 1,
      })
    }
  }

  const prevWeekRate =
    weeklyTrends.length >= 2 && !weeklyTrends[weeklyTrends.length - 2]?.isFuture
      ? weeklyTrends[0].rate
      : averageAttendanceRate
  const rateChange = Number((averageAttendanceRate - prevWeekRate).toFixed(1))

  return {
    averageAttendanceRate,
    rateChange,
    atRiskCount: riskStudents.length,
    totalRecorded,
    qrCodePercentage,
    manualPercentage,
    lowestClass,
    slotAbsence: slotEntries,
    weeklyTrends,
    riskStudents,
  }
}

export async function sendAttendanceWarningNotification(
  students: StudentRiskItem[],
  adminEmail = "admin"
): Promise<void> {
  if (students.length === 0) return
  const isSingle = students.length === 1
  const targetStudent = students[0]

  const title = isSingle
    ? `Cảnh báo chuyên cần môn ${targetStudent.subjectCode} (${targetStudent.classCode})`
    : `Cảnh báo nguy cơ chuyên cần học kỳ hiện tại (${students.length} sinh viên)`

  const body = isSingle
    ? `Sinh viên ${targetStudent.fullName} (${targetStudent.rollNumber}) đã vắng ${targetStudent.absentCount}/${targetStudent.maxAllowed} buổi tại lớp ${targetStudent.classCode} (Tỷ lệ chuyên cần: ${targetStudent.attendanceRate}% - ${targetStudent.riskLabel}). Vui lòng đi học đầy đủ để đảm bảo điều kiện dự thi.`
    : `Hệ thống FAP ghi nhận ${students.length} sinh viên chạm ngưỡng cảnh báo chuyên cần. Đề nghị sinh viên kiểm tra lịch sử điểm danh trên ứng dụng FAP Check-in.`

  await addDoc(collection(firestore, "announcements"), {
    title,
    body,
    content: body,
    audience: "user",
    targetAudience: "students",
    selectedClasses: Array.from(new Set(students.map((s) => s.classCode))),
    recipientRollNumbers: students.map((s) => s.rollNumber),
    recipientCount: students.length,
    priority: "urgent",
    status: "sent",
    createdBy: adminEmail,
    createdAt: serverTimestamp(),
  })

  await addDoc(collection(firestore, "audit_logs"), {
    actionType: "warning",
    actionLabel: isSingle ? "Cảnh báo chuyên cần SV" : "Cảnh báo FCM hàng loạt",
    actor: adminEmail,
    targetEmail: isSingle
      ? `${targetStudent.rollNumber} (${targetStudent.classCode})`
      : `${students.length} sinh viên nguy cơ`,
    detail: title,
    createdAt: serverTimestamp(),
  }).catch(() => {})
}

export async function recordAcademicIntervention(
  student: StudentRiskItem,
  adminEmail = "admin"
): Promise<void> {
  await addDoc(collection(firestore, "audit_logs"), {
    actionType: "update",
    actionLabel: "Can thiệp học vụ",
    actor: adminEmail,
    targetEmail: `${student.rollNumber} (${student.classCode})`,
    detail: `Đã ghi nhận can thiệp học vụ đối với SV ${student.fullName} (${student.rollNumber}) - Lớp ${student.classCode} (${student.absentCount}/${student.maxAllowed} buổi vắng).`,
    createdAt: serverTimestamp(),
  })
}
