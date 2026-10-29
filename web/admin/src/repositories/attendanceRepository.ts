import {
  collection,
  getCountFromServer,
  getDocs,
  limit,
  orderBy,
  query,
  where,
} from "firebase/firestore"
import { firestore } from "../firebase/client"

export type SessionRow = {
  id: string
  classCode: string
  sessionDate: string
  slotCode: string
  teacherMemberCode: string
  sessionStatus: string
  ipCheck: boolean
}
export type AttendanceRecordRow = {
  id: string
  rollNumber: string
  classCode: string
  status: string
  networkResult: string
  syncedToFap: boolean
}
export type AttendanceData = { sessions: SessionRow[]; openCount: number; unsyncedCount: number }

export async function listAttendanceData(): Promise<AttendanceData> {
  const [sessionsSnapshot, open, unsynced] = await Promise.all([
    getDocs(query(collection(firestore, "sessions"), orderBy("sessionDate", "desc"), limit(100))),
    getCountFromServer(query(collection(firestore, "sessions"), where("sessionStatus", "==", "open"))),
    getCountFromServer(query(collection(firestore, "attendance_records"), where("syncedToFap", "==", false))),
  ])
  return {
    sessions: sessionsSnapshot.docs.map((item) => ({
      id: item.id,
      classCode: String(item.data().classCode ?? ""),
      sessionDate: String(item.data().sessionDate ?? ""),
      slotCode: String(item.data().slotCode ?? ""),
      teacherMemberCode: String(item.data().teacherMemberCode ?? ""),
      sessionStatus: String(item.data().sessionStatus ?? ""),
      ipCheck: item.data().ipCheck === true,
    })),
    openCount: open.data().count,
    unsyncedCount: unsynced.data().count,
  }
}

export async function listSessionRecords(sessionId: string): Promise<AttendanceRecordRow[]> {
  const snapshot = await getDocs(query(collection(firestore, "attendance_records"), where("sessionId", "==", sessionId), limit(200)))
  return snapshot.docs.map((item) => ({
    id: item.id,
    rollNumber: String(item.data().rollNumber ?? ""),
    classCode: String(item.data().classCode ?? ""),
    status: String(item.data().status ?? ""),
    networkResult: String(item.data().networkVerificationResult ?? ""),
    syncedToFap: item.data().syncedToFap === true,
  })).sort((a, b) => a.rollNumber.localeCompare(b.rollNumber))
}
