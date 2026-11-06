import {
  collection,
  doc,
  getCountFromServer,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  where,
} from "firebase/firestore"
import { firestore } from "../firebase/client"

type DataRow = { id: string; [key: string]: any }

export type SessionRow = {
  id: string
  classCode: string
  sessionDate: string
  slotCode: string
  teacherMemberCode: string
  sessionStatus: string
  ipCheck: boolean
  totalStudents: number
  presentCount: number
  absentCount: number
  lateCount: number
  notRecordedCount: number
  unsyncedCount: number
  warningCount: number
  warnings: string[]
  overdue: boolean
}

export type AttendanceRecordRow = {
  id: string
  rollNumber: string
  classCode: string
  status: string
  networkResult: string
  syncedToFap: boolean
  fullName: string
  email: string
  enrolled: boolean
  warning: string
}

export type AttendanceData = {
  sessions: SessionRow[]
  totalSessions?: number
  openCount: number
  unsyncedCount: number
  classes: string[]
  teachers: string[]
  slots: string[]
}

export type PaginatedSessionsResult = {
  sessions: SessionRow[]
  totalSessions: number
  openCount: number
  unsyncedCount: number
  page: number
  pageSize: number
  totalPages: number
  classes: string[]
  teachers: string[]
  slots: string[]
}

/**
 * Phân trang phiên điểm danh dưới backend Firestore (Tối đa 10 phiên/trang)
 * Chỉ truy vấn bản ghi điểm danh và sinh viên cho đúng 10 phiên được hiển thị,
 * không tải toàn bộ bản ghi của trường để tránh quá tải backend Firestore.
 */
export async function listAttendanceSessionsPaginated(options: {
  page?: number
  pageSize?: number
  search?: string
  status?: string
  classCode?: string
  teacher?: string
  slot?: string
  sync?: string
  warning?: string
  selectedDate?: string
}): Promise<PaginatedSessionsResult> {
  const page = Math.max(1, options.page ?? 1)
  const pageSize = options.pageSize ?? 10
  const search = (options.search ?? "").trim().toLowerCase()
  const status = options.status ?? "all"
  const classCode = options.classCode ?? "all"
  const teacher = options.teacher ?? "all"
  const slot = options.slot ?? "all"
  const selectedDate = options.selectedDate ?? ""

  // 1. Đếm tổng số phiên và thống kê trực tiếp từ Firestore metadata server
  const [totalSnap, openSnap, unsyncedSnap, slotsSnapshot, timesSnapshot] = await Promise.all([
    getCountFromServer(collection(firestore, "sessions")).catch(() => null),
    getCountFromServer(query(collection(firestore, "sessions"), where("sessionStatus", "==", "open"))).catch(() => null),
    getCountFromServer(query(collection(firestore, "attendance_records"), where("syncedToFap", "==", false))).catch(() => null),
    getDocs(collection(firestore, "slots")).catch(() => null),
    getDocs(collection(firestore, "timeSlots")).catch(() => null),
  ])

  const totalSessionsFromDb = totalSnap ? totalSnap.data().count : 0
  const openCount = openSnap ? openSnap.data().count : 0
  const unsyncedCount = unsyncedSnap ? unsyncedSnap.data().count : 0

  // 2. Tải cửa sổ phiên vừa đủ cho trang yêu cầu (tối đa page * pageSize)
  const fetchLimit = Math.min(Math.max(pageSize, page * pageSize), 100)
  const sessionsSnapshot = await getDocs(
    query(collection(firestore, "sessions"), orderBy("sessionDate", "desc"), limit(fetchLimit))
  )

  let rawSessions: Array<Record<string, any> & { id: string }> = sessionsSnapshot.docs.map((docSnap) => ({
    id: docSnap.id,
    ...docSnap.data(),
  }))

  // Lọc theo điều kiện tìm kiếm và thuộc tính
  if (status !== "all") {
    rawSessions = rawSessions.filter((s) => s.sessionStatus === status)
  }
  if (classCode !== "all") {
    rawSessions = rawSessions.filter((s) => s.classCode === classCode)
  }
  if (teacher !== "all") {
    rawSessions = rawSessions.filter((s) => s.teacherMemberCode === teacher)
  }
  if (slot !== "all") {
    rawSessions = rawSessions.filter((s) => s.slotCode === slot)
  }
  if (selectedDate) {
    rawSessions = rawSessions.filter((s) => s.sessionDate === selectedDate)
  }
  if (search) {
    rawSessions = rawSessions.filter((s) =>
      `${s.classCode} ${s.id} ${s.teacherMemberCode}`.toLowerCase().includes(search)
    )
  }

  const effectiveTotal = Math.max(totalSessionsFromDb, rawSessions.length)
  const startIndex = (page - 1) * pageSize
  const pageRawSessions = rawSessions.slice(startIndex, startIndex + pageSize)

  // 3. CHỈ TẢI BẢN GHI CHO 10 PHIÊN TRÊN TRANG HIỆN TẠI (Tối ưu Firestore reads)
  const pageSessionIds = pageRawSessions.map((s) => s.id)
  const pageClassCodes = [...new Set(pageRawSessions.map((s) => String(s.classCode ?? "")).filter(Boolean))]

  const [recordGroups, enrollmentsSnapshot] = await Promise.all([
    pageSessionIds.length > 0
      ? Promise.all(
          chunk(pageSessionIds, 30).map((ids) =>
            getDocs(query(collection(firestore, "attendance_records"), where("sessionId", "in", ids)))
          )
        )
      : Promise.resolve([]),
    pageClassCodes.length > 0
      ? getDocs(query(collection(firestore, "enrollments"), where("classCode", "in", pageClassCodes.slice(0, 30))))
      : Promise.resolve({ docs: [] } as any),
  ])

  const records: DataRow[] = recordGroups.flatMap((group: any) =>
    group.docs.map((item: any) => ({ id: item.id, ...item.data() }))
  )
  const enrollmentRows: DataRow[] = enrollmentsSnapshot.docs.map((item: any) => ({
    id: item.id,
    ...item.data(),
  }))

  const enrollmentsByClass = groupBy(enrollmentRows, (item) => String(item.classCode ?? ""))
  const recordsBySession = groupBy(records, (item) => String(item.sessionId ?? ""))
  const slotsMap = new Map((slotsSnapshot?.docs ?? []).map((item) => [item.id, item.data()]))
  const timesMap = new Map((timesSnapshot?.docs ?? []).map((item) => [item.id, item.data()]))

  const processedSessions: SessionRow[] = pageRawSessions.map((data: any): SessionRow => {
    const itemClassCode = String(data.classCode ?? "")
    const teacherMemberCode = String(data.teacherMemberCode ?? "")
    const sessionRecords = recordsBySession.get(data.id) ?? []
    const enrollments = enrollmentsByClass.get(itemClassCode) ?? []
    const enrolledRolls = new Set(enrollments.map((entry) => String(entry.rollNumber ?? "")))
    const counts = new Map<string, number>()
    sessionRecords.forEach((record) => {
      const roll = String(record.rollNumber ?? "")
      counts.set(roll, (counts.get(roll) ?? 0) + 1)
    })

    const warnings: string[] = []
    const sessionDate = String(data.sessionDate ?? "")
    const slotCode = String(data.slotCode ?? "")
    const overdue = String(data.sessionStatus ?? "") === "open" && isOverdue(sessionDate, slotCode, slotsMap, timesMap)
    if (overdue) warnings.push("Phiên mở quá giờ")
    if (String(data.sessionStatus ?? "") === "closed" && sessionRecords.length === 0) {
      warnings.push("Phiên đã đóng nhưng không có bản ghi")
    }

    const orphanCount = sessionRecords.filter((record) => !enrolledRolls.has(String(record.rollNumber ?? ""))).length
    const duplicateCount = [...counts.values()].filter((count) => count > 1).length
    const mismatchCount = sessionRecords.filter(
      (record) =>
        String(record.classCode ?? "") !== itemClassCode ||
        (record.teacherMemberCode && String(record.teacherMemberCode) !== teacherMemberCode)
    ).length

    if (orphanCount) warnings.push(`${orphanCount} bản ghi ngoài danh sách lớp`)
    if (duplicateCount) warnings.push(`${duplicateCount} sinh viên có bản ghi trùng`)
    if (mismatchCount) warnings.push(`${mismatchCount} bản ghi sai lớp hoặc giảng viên`)

    const statusCount = (name: string) =>
      sessionRecords.filter((record) => String(record.status ?? "").toLowerCase() === name).length
    const recordedEnrolled = new Set(
      sessionRecords
        .filter((record) => enrolledRolls.has(String(record.rollNumber ?? "")))
        .map((record) => String(record.rollNumber ?? ""))
    ).size

    const totalStudents = enrollments.length || Number(data.totalStudents ?? 24)

    return {
      id: data.id,
      classCode: itemClassCode,
      sessionDate,
      slotCode,
      teacherMemberCode,
      sessionStatus: String(data.sessionStatus ?? ""),
      ipCheck: data.ipCheck === true,
      totalStudents,
      presentCount: statusCount("present"),
      absentCount: statusCount("absent"),
      lateCount: statusCount("late"),
      notRecordedCount: Math.max(0, totalStudents - recordedEnrolled),
      unsyncedCount: sessionRecords.filter((record) => record.syncedToFap !== true).length,
      warningCount: warnings.length,
      warnings,
      overdue,
    }
  })

  const totalPages = Math.max(1, Math.ceil(effectiveTotal / pageSize))

  return {
    sessions: processedSessions,
    totalSessions: effectiveTotal,
    openCount,
    unsyncedCount,
    page,
    pageSize,
    totalPages,
    classes: unique(rawSessions.map((s) => String(s.classCode ?? ""))),
    teachers: unique(rawSessions.map((s) => String(s.teacherMemberCode ?? ""))),
    slots: unique(rawSessions.map((s) => String(s.slotCode ?? ""))),
  }
}

/**
 * Hàm tương thích ngược: gọi listAttendanceSessionsPaginated trang 1
 */
export async function listAttendanceData(): Promise<AttendanceData> {
  const result = await listAttendanceSessionsPaginated({ page: 1, pageSize: 10 })
  return {
    sessions: result.sessions,
    totalSessions: result.totalSessions,
    openCount: result.openCount,
    unsyncedCount: result.unsyncedCount,
    classes: result.classes,
    teachers: result.teachers,
    slots: result.slots,
  }
}

export async function listSessionRecords(sessionId: string): Promise<AttendanceRecordRow[]> {
  const sessionSnapshot = await getDoc(doc(firestore, "sessions", sessionId))
  if (!sessionSnapshot.exists()) throw new Error("Không tìm thấy phiên điểm danh.")
  const session = sessionSnapshot.data()
  const classCode = String(session.classCode ?? "")
  const [recordsSnapshot, enrollmentsSnapshot] = await Promise.all([
    getDocs(query(collection(firestore, "attendance_records"), where("sessionId", "==", sessionId), limit(100))),
    getDocs(query(collection(firestore, "enrollments"), where("classCode", "==", classCode))),
  ])
  const enrollments: DataRow[] = enrollmentsSnapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
  const records: DataRow[] = recordsSnapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
  const recordsByRoll = groupBy(records, (item) => String(item.rollNumber ?? ""))
  const rows: AttendanceRecordRow[] = enrollments.map((enrollment) => {
    const rollNumber = String(enrollment.rollNumber ?? "")
    const matches = recordsByRoll.get(rollNumber) ?? []
    const record = matches[0]
    return {
      id: record?.id ?? `missing_${rollNumber}`,
      rollNumber,
      classCode,
      status: String(record?.status ?? "Chưa điểm danh"),
      networkResult: String(record?.networkVerificationResult ?? "—"),
      syncedToFap: record?.syncedToFap === true,
      fullName: String(enrollment.fullName ?? ""),
      email: String(enrollment.email ?? ""),
      enrolled: true,
      warning:
        matches.length > 1
          ? "Bản ghi trùng"
          : record &&
            (String(record.classCode ?? "") !== classCode ||
              (record.teacherMemberCode &&
                String(record.teacherMemberCode) !== String(session.teacherMemberCode ?? "")))
          ? "Sai lớp hoặc giảng viên"
          : "",
    }
  })
  const enrolledRolls = new Set(enrollments.map((item) => String(item.rollNumber ?? "")))
  records
    .filter((record) => !enrolledRolls.has(String(record.rollNumber ?? "")))
    .forEach((record) =>
      rows.push({
        id: record.id,
        rollNumber: String(record.rollNumber ?? ""),
        classCode: String(record.classCode ?? ""),
        status: String(record.status ?? ""),
        networkResult: String(record.networkVerificationResult ?? ""),
        syncedToFap: record.syncedToFap === true,
        fullName: String(record.fullName ?? ""),
        email: String(record.email ?? ""),
        enrolled: false,
        warning: "Không thuộc danh sách lớp",
      })
    )
  return rows.sort((a, b) => a.rollNumber.localeCompare(b.rollNumber))
}

function groupBy<T>(items: T[], key: (item: T) => string) {
  const result = new Map<string, T[]>()
  items.forEach((item) => {
    const value = key(item)
    result.set(value, [...(result.get(value) ?? []), item])
  })
  return result
}

function unique(items: string[]) {
  return [...new Set(items.filter(Boolean))].sort()
}

function chunk<T>(items: T[], size: number) {
  const result: T[][] = []
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size))
  }
  return result
}

function isOverdue(
  date: string,
  slotCode: string,
  slots: Map<string, Record<string, unknown>>,
  times: Map<string, Record<string, unknown>>
) {
  const slot = slots.get(slotCode)
  const time = slot ? times.get(String(slot.timeSlotId ?? "")) : null
  const end = String(time?.endTime ?? "")
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !/^\d{1,2}:\d{2}$/.test(end)) return false
  const endAt = new Date(`${date}T${end}:00`)
  return Number.isFinite(endAt.getTime()) && Date.now() > endAt.getTime() + 30 * 60 * 1000
}
