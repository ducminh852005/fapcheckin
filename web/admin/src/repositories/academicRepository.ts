import {
  collection,
  doc,
  getCountFromServer,
  getDoc,
  getDocs,
  limit,
  query,
  runTransaction,
  serverTimestamp,
  updateDoc,
  where,
  writeBatch,
} from "firebase/firestore"
import { firestore } from "../firebase/client"

export type ClassRow = {
  classCode: string
  subjectCode: string
  subjectName: string
  credits: number
  room: string
  slotCode: string
  studentCount: number
  teacherMemberCode: string
  teacherName: string
}
export type SubjectRow = { subjectCode: string; subjectName: string; credits: number }
export type SlotRow = { slotCode: string; timeSlotId: string; weekdays: number[]; startTime: string; endTime: string; period: string }
export type AcademicData = { classes: ClassRow[]; subjects: SubjectRow[]; slots: SlotRow[] }
export type StudentOption = { id: string; memberCode: string; rollNumber: string; fullName: string; email: string; active: boolean | null }
export type EnrollmentRow = { id: string; rollNumber: string; fullName: string; email: string }
export type TeacherOption = { id: string; memberCode: string; fullName: string; active: boolean | null }
export type CreateClassInput = { classCode: string; subjectCode: string; teacherMemberCode: string; slotCode: string; room: string; capacity: number }

export async function listAcademicData(): Promise<AcademicData> {
  const [classesSnapshot, subjectsSnapshot, slotsSnapshot, timesSnapshot, usersSnapshot] = await Promise.all([
    getDocs(collection(firestore, "classes")),
    getDocs(collection(firestore, "subjects")),
    getDocs(collection(firestore, "slots")),
    getDocs(collection(firestore, "timeSlots")),
    getDocs(query(collection(firestore, "users"), where("role", "in", ["staff", "GV"]))),
  ])
  const teachers = new Map(usersSnapshot.docs.map((item) => [String(item.data().memberCode ?? ""), String(item.data().fullName ?? "")]))
  const times = new Map(timesSnapshot.docs.map((item) => [item.id, item.data()]))
  const classes = classesSnapshot.docs.map((item) => {
    const data = item.data()
    const teacherMemberCode = String(data.teacherMemberCode ?? "")
    return {
      classCode: String(data.classCode ?? item.id),
      subjectCode: String(data.subjectCode ?? ""),
      subjectName: String(data.subjectName ?? ""),
      credits: Number(data.credits ?? 0),
      room: String(data.room ?? ""),
      slotCode: String(data.slotCode ?? ""),
      studentCount: Number(data.studentCount ?? 0),
      teacherMemberCode,
      teacherName: teachers.get(teacherMemberCode) ?? "",
    }
  }).sort((a, b) => a.classCode.localeCompare(b.classCode))
  const subjects = subjectsSnapshot.docs.map((item) => ({
    subjectCode: String(item.data().subjectCode ?? item.id),
    subjectName: String(item.data().subjectName ?? ""),
    credits: Number(item.data().credits ?? 0),
  })).sort((a, b) => a.subjectCode.localeCompare(b.subjectCode))
  const slots = slotsSnapshot.docs.map((item) => {
    const data = item.data()
    const timeSlotId = String(data.timeSlotId ?? "")
    const time = times.get(timeSlotId) ?? {}
    return {
      slotCode: String(data.slotCode ?? item.id),
      timeSlotId,
      weekdays: Array.isArray(data.weekdays) ? data.weekdays.map(Number) : [],
      startTime: String(time.startTime ?? ""),
      endTime: String(time.endTime ?? ""),
      period: String(time.period ?? ""),
    }
  }).sort((a, b) => a.slotCode.localeCompare(b.slotCode))
  return { classes, subjects, slots }
}

export type PaginatedAcademicResult = {
  classes: ClassRow[]
  subjects: SubjectRow[]
  slots: SlotRow[]
  totalClasses: number
  totalSubjects: number
  totalSlots: number
  page: number
  pageSize: number
}

/**
 * Phân trang dữ liệu học vụ dưới backend Firestore (Tối đa 10 mục/trang)
 * Chỉ tải collection của tab đang chọn với limit cửa sổ trang để giảm tải backend
 */
export async function listAcademicDataPaginated(options: {
  tab?: "classes" | "subjects" | "slots"
  page?: number
  pageSize?: number
  search?: string
}): Promise<PaginatedAcademicResult> {
  const page = Math.max(1, options.page ?? 1)
  const pageSize = options.pageSize ?? 10
  const search = (options.search ?? "").trim().toLowerCase()
  const tab = options.tab ?? "classes"

  const [classesCountSnap, subjectsCountSnap, slotsCountSnap] = await Promise.all([
    getCountFromServer(collection(firestore, "classes")).catch(() => null),
    getCountFromServer(collection(firestore, "subjects")).catch(() => null),
    getCountFromServer(collection(firestore, "slots")).catch(() => null),
  ])

  let totalClasses = classesCountSnap ? classesCountSnap.data().count : 0
  let totalSubjects = subjectsCountSnap ? subjectsCountSnap.data().count : 0
  let totalSlots = slotsCountSnap ? slotsCountSnap.data().count : 0

  const fetchLimit = search ? 200 : Math.min(Math.max(pageSize, page * pageSize), 100)

  let classes: ClassRow[] = []
  let subjects: SubjectRow[] = []
  let slots: SlotRow[] = []

  if (tab === "classes") {
    const [classesSnapshot, usersSnapshot] = await Promise.all([
      getDocs(query(collection(firestore, "classes"), limit(fetchLimit))),
      getDocs(query(collection(firestore, "users"), where("role", "in", ["staff", "GV"]), limit(100))),
    ])
    const teachers = new Map(
      usersSnapshot.docs.map((item) => [String(item.data().memberCode ?? ""), String(item.data().fullName ?? "")])
    )
    classes = classesSnapshot.docs.map((item) => {
      const data = item.data()
      const teacherMemberCode = String(data.teacherMemberCode ?? "")
      return {
        classCode: String(data.classCode ?? item.id),
        subjectCode: String(data.subjectCode ?? ""),
        subjectName: String(data.subjectName ?? ""),
        credits: Number(data.credits ?? 0),
        room: String(data.room ?? ""),
        slotCode: String(data.slotCode ?? ""),
        studentCount: Number(data.studentCount ?? 0),
        teacherMemberCode,
        teacherName: teachers.get(teacherMemberCode) ?? "",
      }
    })
    if (search) {
      classes = classes.filter((row) =>
        `${row.classCode} ${row.subjectName} ${row.teacherName} ${row.teacherMemberCode}`
          .toLowerCase()
          .includes(search)
      )
      totalClasses = classes.length
    }
    classes.sort((a, b) => a.classCode.localeCompare(b.classCode))
    classes = classes.slice((page - 1) * pageSize, page * pageSize)
  } else if (tab === "subjects") {
    const subjectsSnapshot = await getDocs(query(collection(firestore, "subjects"), limit(fetchLimit)))
    subjects = subjectsSnapshot.docs.map((item) => ({
      subjectCode: String(item.data().subjectCode ?? item.id),
      subjectName: String(item.data().subjectName ?? ""),
      credits: Number(item.data().credits ?? 0),
    }))
    if (search) {
      subjects = subjects.filter((row) =>
        `${row.subjectCode} ${row.subjectName}`.toLowerCase().includes(search)
      )
      totalSubjects = subjects.length
    }
    subjects.sort((a, b) => a.subjectCode.localeCompare(b.subjectCode))
    subjects = subjects.slice((page - 1) * pageSize, page * pageSize)
  } else {
    const [slotsSnapshot, timesSnapshot] = await Promise.all([
      getDocs(query(collection(firestore, "slots"), limit(fetchLimit))),
      getDocs(collection(firestore, "timeSlots")),
    ])
    const times = new Map(timesSnapshot.docs.map((item) => [item.id, item.data()]))
    slots = slotsSnapshot.docs.map((item) => {
      const data = item.data()
      const timeSlotId = String(data.timeSlotId ?? "")
      const time = times.get(timeSlotId) ?? {}
      return {
        slotCode: String(data.slotCode ?? item.id),
        timeSlotId,
        weekdays: Array.isArray(data.weekdays) ? data.weekdays.map(Number) : [],
        startTime: String(time.startTime ?? ""),
        endTime: String(time.endTime ?? ""),
        period: String(time.period ?? ""),
      }
    })
    if (search) {
      slots = slots.filter((row) => `${row.slotCode} ${row.timeSlotId}`.toLowerCase().includes(search))
      totalSlots = slots.length
    }
    slots.sort((a, b) => a.slotCode.localeCompare(b.slotCode))
    slots = slots.slice((page - 1) * pageSize, page * pageSize)
  }

  return {
    classes,
    subjects,
    slots,
    totalClasses,
    totalSubjects,
    totalSlots,
    page,
    pageSize,
  }
}

export async function reassignClassTeacher(classCode: string, teacherMemberCode: string) {
  const enrollments = await getDocs(query(collection(firestore, "enrollments"), where("classCode", "==", classCode)))
  if (enrollments.size > 498) throw new Error("Lớp có quá nhiều enrollment để cập nhật trong một batch.")
  const batch = writeBatch(firestore)
  batch.update(doc(firestore, "classes", classCode), { teacherMemberCode })
  enrollments.docs.forEach((item) => batch.update(item.ref, { teacherMemberCode }))
  await batch.commit()
}

export function updateClassRoomAndSlot(classCode: string, room: string, slotCode: string) {
  return updateDoc(doc(firestore, "classes", classCode), { room: room.trim(), slotCode })
}

export async function listClassAssignmentData(classCode: string) {
  const [studentsSnapshot, enrollmentsSnapshot] = await Promise.all([
    getDocs(query(collection(firestore, "users"), limit(500))),
    getDocs(query(collection(firestore, "enrollments"), where("classCode", "==", classCode))),
  ])
  const students: StudentOption[] = studentsSnapshot.docs
    .filter((item) => ["user", "SV"].includes(String(item.data().role ?? "")))
    .map((item) => ({
      id: item.id,
      memberCode: String(item.data().memberCode ?? ""),
      rollNumber: String(item.data().rollNumber ?? item.data().memberCode ?? ""),
      fullName: String(item.data().fullName ?? ""),
      email: String(item.data().email ?? ""),
      active: typeof item.data().active === "boolean" ? item.data().active : null,
    }))
    .filter((item) => item.rollNumber)
    .sort((a, b) => a.fullName.localeCompare(b.fullName, "vi"))
  const enrollments: EnrollmentRow[] = enrollmentsSnapshot.docs.map((item) => ({
    id: item.id,
    rollNumber: String(item.data().rollNumber ?? ""),
    fullName: String(item.data().fullName ?? ""),
    email: String(item.data().email ?? ""),
  })).sort((a, b) => a.fullName.localeCompare(b.fullName, "vi"))
  return { students, enrollments }
}

export async function assignStudentToClass(classCode: string, student: StudentOption) {
  if (!student.rollNumber) throw new Error("Sinh viên chưa có roll number.")
  if (student.active === false) throw new Error("Tài khoản sinh viên đang bị khóa.")

  const targetRef = doc(firestore, "classes", classCode)
  const [targetSnapshot, studentEnrollments, slotsSnapshot, timesSnapshot, targetRoster] = await Promise.all([
    getDoc(targetRef),
    getDocs(query(collection(firestore, "enrollments"), where("rollNumber", "==", student.rollNumber))),
    getDocs(collection(firestore, "slots")),
    getDocs(collection(firestore, "timeSlots")),
    getDocs(query(collection(firestore, "enrollments"), where("classCode", "==", classCode))),
  ])
  if (!targetSnapshot.exists()) throw new Error("Lớp học không còn tồn tại.")
  const target = targetSnapshot.data()
  if (studentEnrollments.docs.some((item) => String(item.data().classCode ?? "") === classCode)) throw new Error("Sinh viên đã có trong lớp này.")

  const enrolledClassCodes = studentEnrollments.docs.map((item) => String(item.data().classCode ?? "")).filter(Boolean)
  const enrolledClassSnapshots = await Promise.all(enrolledClassCodes.map((code) => getDoc(doc(firestore, "classes", code))))
  const enrolledClasses = enrolledClassSnapshots.filter((item) => item.exists()).map((item) => item.data())
  const targetSubject = String(target.subjectCode ?? "")
  if (targetSubject && enrolledClasses.some((item) => String(item.subjectCode ?? "") === targetSubject)) {
    throw new Error("Sinh viên đã học môn này ở một lớp khác.")
  }

  const slots = new Map(slotsSnapshot.docs.map((item) => [item.id, item.data()]))
  const times = new Map(timesSnapshot.docs.map((item) => [item.id, item.data()]))
  const targetSchedule = scheduleOf(String(target.slotCode ?? ""), slots, times)
  if (!targetSchedule) throw new Error("Lớp chưa có cấu hình ngày và giờ học hợp lệ.")
  for (const enrolled of enrolledClasses) {
    const schedule = scheduleOf(String(enrolled.slotCode ?? ""), slots, times)
    if (!schedule) throw new Error(`Không thể kiểm tra lịch của lớp ${String(enrolled.classCode ?? "đã đăng ký")}.`)
    const sameDay = schedule.weekdays.some((day) => targetSchedule.weekdays.includes(day))
    const overlaps = targetSchedule.start < schedule.end && schedule.start < targetSchedule.end
    if (sameDay && overlaps) throw new Error(`Trùng lịch với lớp ${String(enrolled.classCode ?? "khác")}.`)
  }

  const capacity = Number(target.capacity ?? target.maxStudents ?? target.studentLimit ?? 0)
  if (capacity > 0 && targetRoster.size >= capacity) throw new Error(`Lớp đã đủ sĩ số tối đa (${capacity}).`)

  const enrollmentRef = doc(firestore, "enrollments", `${classCode}_${student.rollNumber}`)
  await runTransaction(firestore, async (transaction) => {
    const [freshClass, existingEnrollment] = await Promise.all([transaction.get(targetRef), transaction.get(enrollmentRef)])
    if (!freshClass.exists()) throw new Error("Lớp học không còn tồn tại.")
    if (existingEnrollment.exists()) throw new Error("Sinh viên đã có trong lớp này.")
    const freshData = freshClass.data()
    const freshCapacity = Number(freshData.capacity ?? freshData.maxStudents ?? freshData.studentLimit ?? 0)
    const currentCount = Math.max(Number(freshData.studentCount ?? 0), targetRoster.size)
    if (freshCapacity > 0 && currentCount >= freshCapacity) throw new Error(`Lớp đã đủ sĩ số tối đa (${freshCapacity}).`)
    transaction.set(enrollmentRef, {
      classCode,
      rollNumber: student.rollNumber,
      memberCode: student.memberCode,
      fullName: student.fullName,
      email: student.email,
      teacherMemberCode: String(freshData.teacherMemberCode ?? ""),
      createdAt: serverTimestamp(),
    })
    transaction.update(targetRef, { studentCount: currentCount + 1, updatedAt: serverTimestamp() })
  })
}

export async function listClassTeachers() {
  const snapshot = await getDocs(query(collection(firestore, "users"), limit(500)))
  return snapshot.docs
    .filter((item) => ["staff", "GV"].includes(String(item.data().role ?? "")))
    .map((item): TeacherOption => ({
      id: item.id,
      memberCode: String(item.data().memberCode ?? ""),
      fullName: String(item.data().fullName ?? ""),
      active: typeof item.data().active === "boolean" ? item.data().active : null,
    }))
    .filter((item) => item.memberCode)
    .sort((a, b) => a.fullName.localeCompare(b.fullName, "vi"))
}

export async function createClass(input: CreateClassInput) {
  const classCode = input.classCode.trim().toUpperCase()
  const room = input.room.trim()
  if (!classCode || !input.subjectCode || !input.teacherMemberCode || !input.slotCode || !room) throw new Error("Vui lòng nhập đủ thông tin bắt buộc.")
  if (!/^[A-Z0-9_.-]+$/.test(classCode)) throw new Error("Mã lớp chỉ được chứa chữ, số, dấu gạch dưới, chấm hoặc gạch ngang.")
  if (!Number.isInteger(input.capacity) || input.capacity <= 0 || input.capacity > 500) throw new Error("Sức chứa phải là số nguyên từ 1 đến 500.")

  const [classSnapshot, subjectsSnapshot, teachersSnapshot, classesSnapshot, slotsSnapshot, timesSnapshot] = await Promise.all([
    getDoc(doc(firestore, "classes", classCode)),
    getDocs(collection(firestore, "subjects")),
    getDocs(query(collection(firestore, "users"), limit(500))),
    getDocs(collection(firestore, "classes")),
    getDocs(collection(firestore, "slots")),
    getDocs(collection(firestore, "timeSlots")),
  ])
  if (classSnapshot.exists()) throw new Error("Mã lớp đã tồn tại.")
  const subjectDoc = subjectsSnapshot.docs.find((item) => String(item.data().subjectCode ?? item.id) === input.subjectCode)
  if (!subjectDoc) throw new Error("Môn học không tồn tại.")
  const teacherDoc = teachersSnapshot.docs.find((item) => String(item.data().memberCode ?? "") === input.teacherMemberCode && ["staff", "GV"].includes(String(item.data().role ?? "")))
  if (!teacherDoc) throw new Error("Giảng viên không tồn tại hoặc sai vai trò.")
  if (teacherDoc.data().active === false) throw new Error("Tài khoản giảng viên đang bị khóa.")

  const slots = new Map(slotsSnapshot.docs.map((item) => [item.id, item.data()]))
  const times = new Map(timesSnapshot.docs.map((item) => [item.id, item.data()]))
  const targetSchedule = scheduleOf(input.slotCode, slots, times)
  if (!targetSchedule) throw new Error("Slot chưa có cấu hình ngày và giờ hợp lệ.")
  for (const item of classesSnapshot.docs) {
    const existing = item.data()
    const sameTeacher = String(existing.teacherMemberCode ?? "") === input.teacherMemberCode
    const sameRoom = String(existing.room ?? "").trim().toLowerCase() === room.toLowerCase()
    if (!sameTeacher && !sameRoom) continue
    const schedule = scheduleOf(String(existing.slotCode ?? ""), slots, times)
    if (!schedule) throw new Error(`Không thể kiểm tra lịch của lớp ${String(existing.classCode ?? item.id)}.`)
    const sameDay = schedule.weekdays.some((day) => targetSchedule.weekdays.includes(day))
    const overlaps = targetSchedule.start < schedule.end && schedule.start < targetSchedule.end
    if (sameDay && overlaps && sameTeacher) throw new Error(`Giảng viên bị trùng lịch với lớp ${String(existing.classCode ?? item.id)}.`)
    if (sameDay && overlaps && sameRoom) throw new Error(`Phòng ${room} bị trùng lịch với lớp ${String(existing.classCode ?? item.id)}.`)
  }

  const subject = subjectDoc.data()
  const classRef = doc(firestore, "classes", classCode)
  await runTransaction(firestore, async (transaction) => {
    const fresh = await transaction.get(classRef)
    if (fresh.exists()) throw new Error("Mã lớp đã tồn tại.")
    transaction.set(classRef, {
      classCode,
      subjectCode: input.subjectCode,
      subjectName: String(subject.subjectName ?? ""),
      credits: Number(subject.credits ?? 0),
      teacherMemberCode: input.teacherMemberCode,
      slotCode: input.slotCode,
      room,
      capacity: input.capacity,
      studentCount: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    })
  })
}

function scheduleOf(slotCode: string, slots: Map<string, Record<string, unknown>>, times: Map<string, Record<string, unknown>>) {
  const slot = slots.get(slotCode)
  if (!slot) return null
  const time = times.get(String(slot.timeSlotId ?? ""))
  const weekdays = Array.isArray(slot.weekdays) ? slot.weekdays.map(Number).filter(Number.isFinite) : []
  const start = minutes(String(time?.startTime ?? ""))
  const end = minutes(String(time?.endTime ?? ""))
  return weekdays.length && start !== null && end !== null && start < end ? { weekdays, start, end } : null
}

function minutes(value: string) {
  const match = /^(\d{1,2}):(\d{2})$/.exec(value)
  if (!match) return null
  const result = Number(match[1]) * 60 + Number(match[2])
  return result >= 0 && result < 24 * 60 ? result : null
}
