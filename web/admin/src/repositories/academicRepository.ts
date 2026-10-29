import {
  collection,
  doc,
  getDocs,
  query,
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
