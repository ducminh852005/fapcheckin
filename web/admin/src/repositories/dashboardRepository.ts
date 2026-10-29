import { collection, getCountFromServer, query, where } from "firebase/firestore"
import { firestore } from "../firebase/client"

export type DashboardStats = {
  activeUsers: number
  classes: number
  openSessions: number
  legacyAccounts: number
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const [users, classes, sessions, legacy] = await Promise.all([
    getCountFromServer(query(collection(firestore, "users"), where("active", "==", true))),
    getCountFromServer(collection(firestore, "classes")),
    getCountFromServer(query(collection(firestore, "sessions"), where("sessionStatus", "==", "open"))),
    getCountFromServer(query(collection(firestore, "users"), where("role", "in", ["SV", "GV"]))),
  ])
  return {
    activeUsers: users.data().count,
    classes: classes.data().count,
    openSessions: sessions.data().count,
    legacyAccounts: legacy.data().count,
  }
}
