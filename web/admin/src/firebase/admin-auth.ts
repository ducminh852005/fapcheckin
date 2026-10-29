import {
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signOut,
  type User,
} from "firebase/auth"
import { doc, getDoc } from "firebase/firestore"
import { auth, firestore } from "./client"

export type AdminProfile = {
  uid: string
  memberCode: string
  fullName: string
  email: string
  role: "admin"
  active: true
}

export class AdminAuthError extends Error {
  constructor(public readonly code: string, message: string) {
    super(message)
    this.name = "AdminAuthError"
  }
}

async function requireAdminProfile(user: User): Promise<AdminProfile> {
  if (!user.emailVerified) {
    throw new AdminAuthError("EMAIL_NOT_VERIFIED", "Email Google chưa được xác minh.")
  }

  const snapshot = await getDoc(doc(firestore, "users", user.uid))
  if (!snapshot.exists()) {
    throw new AdminAuthError("PROFILE_NOT_FOUND", "Không tìm thấy hồ sơ admin theo Firebase Auth UID.")
  }

  const data = snapshot.data()
  if (data.role !== "admin") {
    throw new AdminAuthError("ACCESS_DENIED", "Tài khoản này không có vai trò admin.")
  }
  if (data.active !== true) {
    throw new AdminAuthError("ACCOUNT_DISABLED", "Tài khoản admin đang bị khóa.")
  }

  return {
    uid: user.uid,
    memberCode: String(data.memberCode ?? ""),
    fullName: String(data.fullName ?? user.displayName ?? "Quản trị viên"),
    email: String(data.email ?? user.email ?? ""),
    role: "admin",
    active: true,
  }
}

export async function signInAdmin(): Promise<AdminProfile> {
  const provider = new GoogleAuthProvider()
  provider.setCustomParameters({ prompt: "select_account" })
  try {
    const result = await signInWithPopup(auth, provider)
    return await requireAdminProfile(result.user)
  } catch (error) {
    await signOut(auth).catch(() => undefined)
    throw normalizeAuthError(error)
  }
}

export function observeAdminSession(onReady: (profile: AdminProfile | null, error?: AdminAuthError) => void) {
  let revision = 0
  return onAuthStateChanged(auth, async (user) => {
    const currentRevision = ++revision
    if (!user) {
      onReady(null)
      return
    }
    try {
      const profile = await requireAdminProfile(user)
      if (currentRevision === revision) onReady(profile)
    } catch (error) {
      await signOut(auth).catch(() => undefined)
      if (currentRevision === revision) onReady(null, normalizeAuthError(error))
    }
  })
}

export function signOutAdmin() {
  return signOut(auth)
}

function normalizeAuthError(error: unknown): AdminAuthError {
  if (error instanceof AdminAuthError) return error
  const code = typeof error === "object" && error && "code" in error ? String(error.code) : "AUTH_ERROR"
  const messages: Record<string, string> = {
    "auth/popup-closed-by-user": "Bạn đã đóng cửa sổ đăng nhập Google.",
    "auth/popup-blocked": "Trình duyệt đang chặn cửa sổ đăng nhập Google.",
    "auth/network-request-failed": "Không thể kết nối Firebase. Hãy kiểm tra mạng.",
    "auth/unauthorized-domain": "Tên miền hiện tại chưa được cho phép trong Firebase Authentication.",
  }
  return new AdminAuthError(code, messages[code] ?? "Không thể xác thực tài khoản admin.")
}
