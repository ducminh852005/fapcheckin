import {
  addDoc,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getCountFromServer,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} from "firebase/firestore"
import { auth, firestore } from "../firebase/client"

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

export type AuditLogRow = {
  id: string
  time: string
  timestampMs: number
  actor: string
  action: string
  target: string
  role: string
  status: "Thành công" | "Cảnh báo"
}

export type AccountMetrics = {
  totalAccounts: number
  canonicalAccounts: number
  legacyAccounts: number
  lockedAccounts: number
  totalInvites: number
}

export type PaginatedAccountsResult = {
  accounts: AccountRow[]
  totalAccounts: number
  page: number
  pageSize: number
  totalPages: number
  metrics: AccountMetrics
}

export type PaginatedInvitesResult = {
  invites: InviteRow[]
  totalInvites: number
  page: number
  pageSize: number
  totalPages: number
}

export type PaginatedAuditLogsResult = {
  logs: AuditLogRow[]
  totalLogs: number
  page: number
  pageSize: number
  totalPages: number
}

export type AccountData = {
  accounts: AccountRow[]
  invites: InviteRow[]
  metrics?: AccountMetrics
}

function formatFirestoreTime(val: unknown): { text: string; ms: number } {
  if (val instanceof Timestamp) {
    const d = val.toDate()
    return {
      text: new Intl.DateTimeFormat("vi-VN", {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        day: "2-digit",
        month: "2-digit",
        year: "numeric",
      }).format(d),
      ms: d.getTime(),
    }
  }
  if (typeof val === "string" && val.trim()) {
    const parsed = Date.parse(val)
    if (!Number.isNaN(parsed)) {
      const d = new Date(parsed)
      return {
        text: new Intl.DateTimeFormat("vi-VN", {
          hour: "2-digit",
          minute: "2-digit",
          day: "2-digit",
          month: "2-digit",
          year: "numeric",
        }).format(d),
        ms: parsed,
      }
    }
    return { text: val, ms: 0 }
  }
  return { text: "Đã ghi nhận", ms: 0 }
}

function mapRoleLabel(role: string): string {
  if (role === "admin") return "Admin"
  if (role === "staff" || role === "GV") return "Giảng viên"
  if (role === "user" || role === "SV") return "Sinh viên"
  return role || "Hệ thống"
}

export async function recordAuditLog(entry: {
  action: string
  target: string
  role: string
  status?: "Thành công" | "Cảnh báo"
  actor?: string
}) {
  try {
    const currentEmail = auth.currentUser?.email || auth.currentUser?.displayName || "Admin"
    await addDoc(collection(firestore, "audit_logs"), {
      actor: entry.actor || currentEmail,
      action: entry.action,
      target: entry.target,
      role: entry.role,
      status: entry.status ?? "Thành công",
      createdAt: serverTimestamp(),
    })
  } catch {
    // Ignore if audit_logs rule is not yet deployed on remote environment
  }
}

/**
 * Lấy số liệu thống kê tài khoản thực tế từ Firestore bằng getCountFromServer
 */
export async function getAccountMetrics(): Promise<AccountMetrics> {
  const [totalSnap, lockedSnap, legacyUsersSnap, invitesSnap] = await Promise.all([
    getCountFromServer(collection(firestore, "users")),
    getCountFromServer(query(collection(firestore, "users"), where("active", "==", false))),
    getCountFromServer(query(collection(firestore, "users"), where("role", "in", ["SV", "GV"]))),
    getCountFromServer(collection(firestore, "user_invites")),
  ])

  const totalAccounts = totalSnap.data().count
  const lockedAccounts = lockedSnap.data().count
  const legacyUsers = legacyUsersSnap.data().count
  const totalInvites = invitesSnap.data().count
  const canonicalAccounts = Math.max(0, totalAccounts - legacyUsers)
  const legacyAccounts = legacyUsers + totalInvites

  return {
    totalAccounts,
    canonicalAccounts,
    legacyAccounts,
    lockedAccounts,
    totalInvites,
  }
}

/**
 * Phân trang danh sách tài khoản dưới backend Firestore (Tối đa 10 người/trang)
 */
export async function listAccountsPaginated(options: {
  page?: number
  pageSize?: number
  search?: string
  roleFilter?: string
  linkFilter?: string
  statusFilter?: string
}): Promise<PaginatedAccountsResult> {
  const page = Math.max(1, options.page ?? 1)
  const pageSize = options.pageSize ?? 10
  const search = (options.search ?? "").trim().toLowerCase()
  const roleFilter = options.roleFilter ?? "all"
  const linkFilter = options.linkFilter ?? "all"
  const statusFilter = options.statusFilter ?? "all"

  const constraints: any[] = []
  if (roleFilter === "user") {
    constraints.push(where("role", "in", ["user", "SV"]))
  } else if (roleFilter === "staff") {
    constraints.push(where("role", "in", ["staff", "GV"]))
  } else if (roleFilter === "admin") {
    constraints.push(where("role", "==", "admin"))
  }

  if (statusFilter === "active") {
    constraints.push(where("active", "==", true))
  } else if (statusFilter === "inactive") {
    constraints.push(where("active", "==", false))
  }

  const baseQuery = query(collection(firestore, "users"), ...constraints)

  const hasClientFilter = Boolean(search) || linkFilter !== "all"
  const fetchLimit = hasClientFilter ? 500 : Math.min(Math.max(pageSize, page * pageSize), 200)

  const [countSnap, usersSnapshot, metrics] = await Promise.all([
    getCountFromServer(baseQuery),
    getDocs(query(baseQuery, limit(fetchLimit))),
    getAccountMetrics(),
  ])

  let allAccounts: AccountRow[] = usersSnapshot.docs.map((snapshot) => {
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
  })

  if (linkFilter === "canonical") {
    allAccounts = allAccounts.filter((a) => a.canonical)
  } else if (linkFilter === "legacy") {
    allAccounts = allAccounts.filter((a) => !a.canonical)
  }

  if (search) {
    allAccounts = allAccounts.filter((a) =>
      `${a.fullName} ${a.email} ${a.memberCode} ${a.rollNumber}`.toLowerCase().includes(search)
    )
  }

  allAccounts.sort((a, b) => a.fullName.localeCompare(b.fullName, "vi"))

  const startIndex = (page - 1) * pageSize
  const paginatedAccounts = allAccounts.slice(startIndex, startIndex + pageSize)
  const effectiveTotal = hasClientFilter ? allAccounts.length : countSnap.data().count
  const totalPages = Math.max(1, Math.ceil(effectiveTotal / pageSize))

  return {
    accounts: paginatedAccounts,
    totalAccounts: effectiveTotal,
    page,
    pageSize,
    totalPages,
    metrics,
  }
}

/**
 * Phân trang danh sách quyền đăng nhập chờ duyệt (user_invites) dưới backend Firestore
 */
export async function listInvitesPaginated(options: {
  page?: number
  pageSize?: number
  search?: string
}): Promise<PaginatedInvitesResult> {
  const page = Math.max(1, options.page ?? 1)
  const pageSize = options.pageSize ?? 10
  const search = (options.search ?? "").trim().toLowerCase()

  const baseQuery = collection(firestore, "user_invites")
  const fetchLimit = search ? 500 : Math.min(Math.max(pageSize, page * pageSize), 200)

  const [countSnap, invitesSnapshot] = await Promise.all([
    getCountFromServer(baseQuery),
    getDocs(query(baseQuery, limit(fetchLimit))),
  ])

  let allInvites: InviteRow[] = invitesSnapshot.docs.map((snapshot) => {
    const data = snapshot.data()
    return {
      id: snapshot.id,
      memberCode: String(data.memberCode ?? ""),
      fullName: String(data.fullName ?? ""),
      email: String(data.email ?? snapshot.id),
      role: String(data.role ?? ""),
      rollNumber: String(data.rollNumber ?? ""),
    }
  })

  if (search) {
    allInvites = allInvites.filter((item) =>
      `${item.fullName} ${item.email} ${item.memberCode}`.toLowerCase().includes(search)
    )
  }

  allInvites.sort((a, b) => a.fullName.localeCompare(b.fullName, "vi"))

  const startIndex = (page - 1) * pageSize
  const paginatedInvites = allInvites.slice(startIndex, startIndex + pageSize)
  const effectiveTotal = search ? allInvites.length : countSnap.data().count
  const totalPages = Math.max(1, Math.ceil(effectiveTotal / pageSize))

  return {
    invites: paginatedInvites,
    totalInvites: effectiveTotal,
    page,
    pageSize,
    totalPages,
  }
}

/**
 * Phân trang Nhật ký truy cập & thao tác (Audit Log) thực tế từ Firestore
 * Kết hợp từ audit_logs, user_invites, users và requests
 */
export async function listAuditLogsPaginated(options: {
  page?: number
  pageSize?: number
  search?: string
}): Promise<PaginatedAuditLogsResult> {
  const page = Math.max(1, options.page ?? 1)
  const pageSize = options.pageSize ?? 10
  const search = (options.search ?? "").trim().toLowerCase()

  const [auditDocsSnap, usersSnap, invitesSnap, requestsSnap] = await Promise.all([
    getDocs(query(collection(firestore, "audit_logs"), orderBy("createdAt", "desc"), limit(50))).catch(() => null),
    getDocs(query(collection(firestore, "users"), limit(50))),
    getDocs(query(collection(firestore, "user_invites"), limit(50))),
    getDocs(query(collection(firestore, "requests"), limit(30))).catch(() => null),
  ])

  const logs: AuditLogRow[] = []

  // 1. Explicit audit_logs documents
  if (auditDocsSnap && !auditDocsSnap.empty) {
    auditDocsSnap.docs.forEach((d) => {
      const data = d.data()
      const t = formatFirestoreTime(data.createdAt)
      logs.push({
        id: `audit_${d.id}`,
        time: t.text,
        timestampMs: t.ms || Date.now(),
        actor: String(data.actor ?? "Admin"),
        action: String(data.action ?? "Cập nhật hệ thống"),
        target: String(data.target ?? d.id),
        role: mapRoleLabel(String(data.role ?? "")),
        status: data.status === "Cảnh báo" ? "Cảnh báo" : "Thành công",
      })
    })
  }

  // 2. Real events from user_invites (Cấp quyền đăng nhập)
  invitesSnap.docs.forEach((d) => {
    const data = d.data()
    const t = formatFirestoreTime(data.createdAt)
    logs.push({
      id: `invite_${d.id}`,
      time: t.text,
      timestampMs: t.ms,
      actor: "Ban Đào Tạo (Admin)",
      action: "Cấp quyền đăng nhập (Invite)",
      target: String(data.email ?? d.id),
      role: mapRoleLabel(String(data.role ?? "")),
      status: "Thành công",
    })
  })

  // 3. Real events from users (Liên kết Auth UID / Khóa tài khoản)
  usersSnap.docs.forEach((d) => {
    const data = d.data()
    const email = String(data.email ?? d.id)
    const role = String(data.role ?? "")
    const isLocked = data.active === false
    const t = formatFirestoreTime(data.updatedAt ?? data.createdAt)
    logs.push({
      id: `user_${d.id}`,
      time: t.text,
      timestampMs: t.ms,
      actor: isLocked ? "Ban Đào Tạo (Admin)" : "Firebase Auth SSO",
      action: isLocked
        ? "Khóa tài khoản người dùng"
        : d.id !== String(data.memberCode ?? "")
          ? "Liên kết hồ sơ Auth UID"
          : "Đồng bộ hồ sơ người dùng",
      target: `${email} (${String(data.memberCode ?? d.id)})`,
      role: mapRoleLabel(role),
      status: isLocked ? "Cảnh báo" : "Thành công",
    })
  })

  // 4. Real events from requests (Đơn yêu cầu điểm danh / nghỉ phép)
  if (requestsSnap && !requestsSnap.empty) {
    requestsSnap.docs.forEach((d) => {
      const data = d.data()
      const t = formatFirestoreTime(data.resolvedAt ?? data.createdAt)
      logs.push({
        id: `req_${d.id}`,
        time: t.text,
        timestampMs: t.ms,
        actor: String(data.authorMemberCode ?? data.authorUid ?? "Người dùng"),
        action:
          data.status === "approved"
            ? "Đã duyệt đơn điểm danh"
            : data.status === "rejected"
              ? "Từ chối đơn điểm danh"
              : "Gửi đơn yêu cầu hỗ trợ",
        target: String(data.classCode ?? d.id),
        role: "Học vụ",
        status: data.status === "rejected" ? "Cảnh báo" : "Thành công",
      })
    })
  }

  logs.sort((a, b) => b.timestampMs - a.timestampMs)

  const filtered = search
    ? logs.filter((l) =>
        `${l.actor} ${l.action} ${l.target} ${l.role}`.toLowerCase().includes(search)
      )
    : logs

  const totalLogs = filtered.length
  const totalPages = Math.max(1, Math.ceil(totalLogs / pageSize))
  const startIndex = (page - 1) * pageSize
  const paginatedLogs = filtered.slice(startIndex, startIndex + pageSize)

  return {
    logs: paginatedLogs,
    totalLogs,
    page,
    pageSize,
    totalPages,
  }
}

/**
 * Hàm tương thích ngược: tải trang 1 (10 accounts & invites) + metrics
 */
export async function listAccountData(): Promise<AccountData> {
  const [accountsResult, invitesResult] = await Promise.all([
    listAccountsPaginated({ page: 1, pageSize: 10 }),
    listInvitesPaginated({ page: 1, pageSize: 10 }),
  ])
  return {
    accounts: accountsResult.accounts,
    invites: invitesResult.invites,
    metrics: accountsResult.metrics,
  }
}

export async function listAllAccountsForExport(): Promise<AccountRow[]> {
  const snapshot = await getDocs(collection(firestore, "users"))
  return snapshot.docs
    .map((item) => {
      const data = item.data()
      const memberCode = String(data.memberCode ?? "")
      return {
        id: item.id,
        memberCode,
        fullName: String(data.fullName ?? ""),
        email: String(data.email ?? ""),
        role: String(data.role ?? ""),
        rollNumber: String(data.rollNumber ?? ""),
        active: typeof data.active === "boolean" ? data.active : null,
        canonical: item.id !== memberCode && typeof data.active === "boolean",
      } satisfies AccountRow
    })
    .sort((a, b) => a.fullName.localeCompare(b.fullName, "vi"))
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
  void recordAuditLog({
    action: "Cấp quyền tài khoản",
    target: email,
    role: input.role,
    status: "Thành công",
  })
}

export async function setAccountActive(account: AccountRow, active: boolean) {
  if (!account.canonical) throw new Error("Tài khoản legacy phải được migrate trước khi khóa hoặc mở.")
  await updateDoc(doc(firestore, "users", account.id), { active })
  void recordAuditLog({
    action: active ? "Mở khóa tài khoản" : "Khóa tài khoản",
    target: account.email || account.id,
    role: String(account.role),
    status: active ? "Thành công" : "Cảnh báo",
  })
}

export async function setAccountRole(account: AccountRow, role: "user" | "staff") {
  if (!account.canonical) throw new Error("Tài khoản legacy phải được migrate trước khi đổi vai trò.")
  if (account.role === "admin") throw new Error("Không đổi vai trò admin từ màn hình này.")
  if (role === "user" && !account.rollNumber) throw new Error("Không thể chuyển thành sinh viên khi hồ sơ chưa có roll number.")
  await updateDoc(doc(firestore, "users", account.id), { role })
  void recordAuditLog({
    action: "Đổi vai trò tài khoản",
    target: account.email || account.id,
    role,
    status: "Thành công",
  })
}

export async function updateAccount(account: AccountRow, input: {
  fullName: string
  memberCode: string
  role: "user" | "staff"
  rollNumber?: string
}) {
  if (account.role === "admin") throw new Error("Không chỉnh sửa tài khoản admin từ màn hình này.")
  const fullName = input.fullName.trim()
  const memberCode = input.memberCode.trim()
  const rollNumber = input.rollNumber?.trim() ?? ""
  if (!fullName || !memberCode) throw new Error("Vui lòng nhập đủ thông tin bắt buộc.")
  if (input.role === "user" && !rollNumber) throw new Error("Sinh viên phải có roll number.")
  await updateDoc(doc(firestore, "users", account.id), {
    fullName,
    memberCode,
    role: account.canonical ? input.role : input.role === "staff" ? "GV" : "SV",
    rollNumber: input.role === "user" ? rollNumber : deleteField(),
    updatedAt: serverTimestamp(),
  })
  void recordAuditLog({
    action: "Cập nhật thông tin tài khoản",
    target: account.email || account.id,
    role: input.role,
    status: "Thành công",
  })
}

export async function revokeInvite(inviteId: string) {
  await deleteDoc(doc(firestore, "user_invites", inviteId))
  void recordAuditLog({
    action: "Thu hồi quyền đăng nhập",
    target: inviteId,
    role: "Invite",
    status: "Cảnh báo",
  })
}
