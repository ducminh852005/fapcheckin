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
export type AttendanceData = { sessions: SessionRow[]; openCount: number; unsyncedCount: number; classes: string[]; teachers: string[]; slots: string[] }

export async function listAttendanceData(): Promise<AttendanceData> {
  const [sessionsSnapshot, open, unsynced, enrollmentsSnapshot, slotsSnapshot, timesSnapshot] = await Promise.all([
    getDocs(query(collection(firestore, "sessions"), orderBy("sessionDate", "desc"), limit(100))),
    getCountFromServer(query(collection(firestore, "sessions"), where("sessionStatus", "==", "open"))),
    getCountFromServer(query(collection(firestore, "attendance_records"), where("syncedToFap", "==", false))),
    getDocs(collection(firestore, "enrollments")),
    getDocs(collection(firestore, "slots")),
    getDocs(collection(firestore, "timeSlots")),
  ])
  const sessionDocs = sessionsSnapshot.docs
  const recordGroups = await Promise.all(chunk(sessionDocs.map((item) => item.id), 30).map((ids) => getDocs(query(collection(firestore, "attendance_records"), where("sessionId", "in", ids)))))
  const records: DataRow[] = recordGroups.flatMap((group) => group.docs.map((item) => ({ id: item.id, ...item.data() })))
  const enrollmentRows: DataRow[] = enrollmentsSnapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
  const enrollmentsByClass = groupBy(enrollmentRows, (item) => String(item.classCode ?? ""))
  const recordsBySession = groupBy(records, (item) => String(item.sessionId ?? ""))
  const slots = new Map(slotsSnapshot.docs.map((item) => [item.id, item.data()]))
  const times = new Map(timesSnapshot.docs.map((item) => [item.id, item.data()]))
  const sessions = sessionDocs.map((item): SessionRow => {
    const data = item.data()
    const classCode = String(data.classCode ?? "")
    const teacherMemberCode = String(data.teacherMemberCode ?? "")
    const sessionRecords = recordsBySession.get(item.id) ?? []
    const enrollments = enrollmentsByClass.get(classCode) ?? []
    const enrolledRolls = new Set(enrollments.map((entry) => String(entry.rollNumber ?? "")))
    const counts = new Map<string, number>()
    sessionRecords.forEach((record) => { const roll = String(record.rollNumber ?? ""); counts.set(roll, (counts.get(roll) ?? 0) + 1) })
    const warnings: string[] = []
    const sessionDate = String(data.sessionDate ?? "")
    const slotCode = String(data.slotCode ?? "")
    const overdue = String(data.sessionStatus ?? "") === "open" && isOverdue(sessionDate, slotCode, slots, times)
    if (overdue) warnings.push("Phiên mở quá giờ")
    if (String(data.sessionStatus ?? "") === "closed" && sessionRecords.length === 0) warnings.push("Phiên đã đóng nhưng không có bản ghi")
    const orphanCount = sessionRecords.filter((record) => !enrolledRolls.has(String(record.rollNumber ?? ""))).length
    const duplicateCount = [...counts.values()].filter((count) => count > 1).length
    const mismatchCount = sessionRecords.filter((record) => String(record.classCode ?? "") !== classCode || (record.teacherMemberCode && String(record.teacherMemberCode) !== teacherMemberCode)).length
    if (orphanCount) warnings.push(`${orphanCount} bản ghi ngoài danh sách lớp`)
    if (duplicateCount) warnings.push(`${duplicateCount} sinh viên có bản ghi trùng`)
    if (mismatchCount) warnings.push(`${mismatchCount} bản ghi sai lớp hoặc giảng viên`)
    const statusCount = (name: string) => sessionRecords.filter((record) => String(record.status ?? "").toLowerCase() === name).length
    const recordedEnrolled = new Set(sessionRecords.filter((record) => enrolledRolls.has(String(record.rollNumber ?? ""))).map((record) => String(record.rollNumber ?? ""))).size
    return {
      id: item.id, classCode, sessionDate, slotCode, teacherMemberCode,
      sessionStatus: String(data.sessionStatus ?? ""), ipCheck: data.ipCheck === true,
      totalStudents: enrollments.length, presentCount: statusCount("present"), absentCount: statusCount("absent"), lateCount: statusCount("late"),
      notRecordedCount: Math.max(0, enrollments.length - recordedEnrolled),
      unsyncedCount: sessionRecords.filter((record) => record.syncedToFap !== true).length,
      warningCount: warnings.length, warnings, overdue,
    }
  })
  return {
    sessions,
    openCount: open.data().count,
    unsyncedCount: unsynced.data().count,
    classes: unique(sessions.map((item) => item.classCode)),
    teachers: unique(sessions.map((item) => item.teacherMemberCode)),
    slots: unique(sessions.map((item) => item.slotCode)),
  }
}

export async function listSessionRecords(sessionId: string): Promise<AttendanceRecordRow[]> {
  const sessionSnapshot = await getDoc(doc(firestore, "sessions", sessionId))
  if (!sessionSnapshot.exists()) return []
  const session = sessionSnapshot.data()
  const classCode = String(session.classCode ?? "")
  const [recordsSnapshot, enrollmentsSnapshot] = await Promise.all([
    getDocs(query(collection(firestore, "attendance_records"), where("sessionId", "==", sessionId), limit(500))),
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
      id: record?.id ?? `missing_${rollNumber}`, rollNumber, classCode,
      status: String(record?.status ?? "Chưa điểm danh"), networkResult: String(record?.networkVerificationResult ?? "—"),
      syncedToFap: record?.syncedToFap === true, fullName: String(enrollment.fullName ?? ""), email: String(enrollment.email ?? ""), enrolled: true,
      warning: matches.length > 1 ? "Bản ghi trùng" : record && (String(record.classCode ?? "") !== classCode || (record.teacherMemberCode && String(record.teacherMemberCode) !== String(session.teacherMemberCode ?? ""))) ? "Sai lớp hoặc giảng viên" : "",
    }
  })
  const enrolledRolls = new Set(enrollments.map((item) => String(item.rollNumber ?? "")))
  records.filter((record) => !enrolledRolls.has(String(record.rollNumber ?? ""))).forEach((record) => rows.push({
    id: record.id, rollNumber: String(record.rollNumber ?? ""), classCode: String(record.classCode ?? ""), status: String(record.status ?? ""),
    networkResult: String(record.networkVerificationResult ?? ""), syncedToFap: record.syncedToFap === true,
    fullName: String(record.fullName ?? ""), email: String(record.email ?? ""), enrolled: false, warning: "Không thuộc danh sách lớp",
  }))
  return rows.sort((a, b) => a.rollNumber.localeCompare(b.rollNumber))
}

function groupBy<T>(items: T[], key: (item: T) => string) { const result = new Map<string, T[]>(); items.forEach((item) => { const value = key(item); result.set(value, [...(result.get(value) ?? []), item]) }); return result }
function unique(items: string[]) { return [...new Set(items.filter(Boolean))].sort() }
function chunk<T>(items: T[], size: number) { const result: T[][] = []; for (let index = 0; index < items.length; index += size) result.push(items.slice(index, index + size)); return result }
function isOverdue(date: string, slotCode: string, slots: Map<string, Record<string, unknown>>, times: Map<string, Record<string, unknown>>) {
  const slot = slots.get(slotCode); const time = slot ? times.get(String(slot.timeSlotId ?? "")) : null; const end = String(time?.endTime ?? "")
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !/^\d{1,2}:\d{2}$/.test(end)) return false
  const endAt = new Date(`${date}T${end}:00`); return Number.isFinite(endAt.getTime()) && Date.now() > endAt.getTime() + 30 * 60 * 1000
}
