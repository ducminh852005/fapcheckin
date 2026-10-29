import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  limit,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
} from "firebase/firestore"
import { firestore } from "../firebase/client"

export type AccountRole = "user" | "staff" | "admin" | "SV" | "GV" | string

export type AccountRow = {
  id: string
  memberCode: string
  fullName: string
  email: string
  role: AccountRole
  rollNumber: string
  active: boolean | null
  canonical: boolean
}

export type InviteRow = {
  id: string
  memberCode: string
  fullName: string
  email: string
  role: string
  rollNumber: string
}

export type AccountData = { accounts: AccountRow[]; invites: InviteRow[] }

export async function listAccountData(): Promise<AccountData> {
  const [usersSnapshot, invitesSnapshot] = await Promise.all([
    getDocs(query(collection(firestore, "users"), limit(500))),
    getDocs(query(collection(firestore, "user_invites"), limit(500))),
  ])
  const accounts = usersSnapshot.docs.map((snapshot) => {
    const data = snapshot.data()
    const memberCode = String(data.memberCode ?? "")
    return {
      id: snapshot.id,
      memberCode,
      fullName: String(data.fullName ?? ""),
      email: String(data.email ?? ""),
      role: String(data.role ?? ""),
      rollNumber: String(data.rollNumber ?? ""),
      active: typeof data.active === "boolean" ? data.active : null,
      canonical: snapshot.id !== memberCode && typeof data.active === "boolean",
    }
  }).sort((a, b) => a.fullName.localeCompare(b.fullName, "vi"))

  const invites = invitesSnapshot.docs.map((snapshot) => {
    const data = snapshot.data()
    return {
      id: snapshot.id,
      memberCode: String(data.memberCode ?? ""),
      fullName: String(data.fullName ?? ""),
      email: String(data.email ?? snapshot.id),
      role: String(data.role ?? ""),
      rollNumber: String(data.rollNumber ?? ""),
    }
  }).sort((a, b) => a.fullName.localeCompare(b.fullName, "vi"))
  return { accounts, invites }
}

export async function createInvite(input: {
  email: string
  fullName: string
  memberCode: string
  role: "user" | "staff"
  rollNumber?: string
}) {
  const email = input.email.trim().toLowerCase()
  if (!email || !input.fullName.trim() || !input.memberCode.trim()) throw new Error("Vui lòng nhập đủ thông tin bắt buộc.")
  if (input.role === "user" && !input.rollNumber?.trim()) throw new Error("Sinh viên phải có roll number.")
  await setDoc(doc(firestore, "user_invites", email), {
    email,
    fullName: input.fullName.trim(),
    memberCode: input.memberCode.trim(),
    role: input.role,
    ...(input.role === "user" ? { rollNumber: input.rollNumber!.trim() } : {}),
    createdAt: serverTimestamp(),
  })
}

export async function setAccountActive(account: AccountRow, active: boolean) {
  if (!account.canonical) throw new Error("Tài khoản legacy phải được migrate trước khi khóa hoặc mở.")
  await updateDoc(doc(firestore, "users", account.id), { active })
}

export async function setAccountRole(account: AccountRow, role: "user" | "staff") {
  if (!account.canonical) throw new Error("Tài khoản legacy phải được migrate trước khi đổi vai trò.")
  if (account.role === "admin") throw new Error("Không đổi vai trò admin từ màn hình này.")
  if (role === "user" && !account.rollNumber) throw new Error("Không thể chuyển thành sinh viên khi hồ sơ chưa có roll number.")
  await updateDoc(doc(firestore, "users", account.id), { role })
}

export function revokeInvite(inviteId: string) {
  return deleteDoc(doc(firestore, "user_invites", inviteId))
}
