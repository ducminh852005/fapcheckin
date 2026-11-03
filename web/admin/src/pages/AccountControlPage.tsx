import { useCallback, useMemo, useState } from "react"
import {
  AlertTriangle,
  ArrowRight,
  Check,
  CheckCircle2,
  ChevronDown,
  Clock,
  Download,
  Edit2,
  ExternalLink,
  Info,
  KeyRound,
  LoaderCircle,
  Lock,
  LockKeyhole,
  Pencil,
  Plus,
  RotateCcw,
  RotateCw,
  Search,
  ShieldAlert,
  ShieldCheck,
  Trash2,
  Unlock,
  UserCheck,
  UserCog,
  UserPlus,
  Users,
  UserX,
  X,
} from "lucide-react"
import type { AdminProfile } from "../firebase/admin-auth"
import { readError, useAsyncData } from "../hooks/useAsyncData"
import { Pagination } from "../components/Pagination"
import {
  createInvite,
  listAllAccountsForExport,
  listAccountsPaginated,
  listAuditLogsPaginated,
  listInvitesPaginated,
  revokeInvite,
  setAccountActive,
  setAccountRole,
  updateAccount,
  type AccountRow,
  type InviteRow,
} from "../repositories/accountRepository"

type InviteForm = {
  email: string
  fullName: string
  memberCode: string
  role: "user" | "staff"
  rollNumber: string
}

const emptyInvite: InviteForm = {
  email: "",
  fullName: "",
  memberCode: "",
  role: "user",
  rollNumber: "",
}

export function AccountControl({
  currentAdmin,
}: {
  currentAdmin: AdminProfile
}) {
  // Tabs: users | invites | audit
  const [tab, setTab] = useState<"users" | "invites" | "audit">("users")

  // Filters
  const [search, setSearch] = useState("")
  const [roleFilter, setRoleFilter] = useState("all")
  const [linkFilter, setLinkFilter] = useState("all")
  const [statusFilter, setStatusFilter] = useState("all")

  // Pagination states (max 10 items per page)
  const [userPage, setUserPage] = useState(1)
  const [invitePage, setInvitePage] = useState(1)
  const [auditPage, setAuditPage] = useState(1)

  const loader = useCallback(
    () =>
      Promise.all([
        listAccountsPaginated({
          page: userPage,
          pageSize: 10,
          search,
          roleFilter,
          linkFilter,
          statusFilter,
        }),
        listInvitesPaginated({
          page: invitePage,
          pageSize: 10,
          search,
        }),
        listAuditLogsPaginated({
          page: auditPage,
          pageSize: 10,
          search,
        }),
      ]).then(([accountsRes, invitesRes, auditRes]) => ({
        accounts: accountsRes.accounts,
        totalAccounts: accountsRes.totalAccounts,
        invites: invitesRes.invites,
        totalInvites: invitesRes.totalInvites,
        auditLogs: auditRes.logs,
        totalAuditLogs: auditRes.totalLogs,
        metrics: accountsRes.metrics,
      })),
    [userPage, invitePage, auditPage, search, roleFilter, linkFilter, statusFilter]
  )
  const { data, loading, error, reload } = useAsyncData(loader)

  // Drawers and modals
  const [selected, setSelected] = useState<AccountRow | null>(null)
  const [selectedRole, setSelectedRole] = useState<"user" | "staff">("user")
  const [inviteOpen, setInviteOpen] = useState(false)
  const [invite, setInvite] = useState<InviteForm>(emptyInvite)
  const [edit, setEdit] = useState<InviteForm | null>(null)
  const [busy, setBusy] = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [toastMessage, setToastMessage] = useState<string | null>(null)

  const showToast = (msg: string) => {
    setToastMessage(msg)
    setTimeout(() => setToastMessage(null), 3500)
  }

  // Accounts, Invites & AuditLogs are paginated directly at the backend
  const accounts = data?.accounts ?? []
  const invites = data?.invites ?? []
  const paginatedAccounts = accounts
  const paginatedInvites = invites
  const paginatedAuditLogs = data?.auditLogs ?? []

  const canonicalEmails = useMemo(
    () =>
      new Set(
        (data?.accounts ?? [])
          .filter((item) => item.canonical)
          .map((item) => item.email.toLowerCase())
      ),
    [data]
  )

  const inviteEmails = useMemo(
    () => new Set((data?.invites ?? []).map((item) => item.email.toLowerCase())),
    [data]
  )

  // Calculations for KPI Cards from real Firestore metrics
  const totalUsersCount = data?.metrics?.totalAccounts ?? data?.totalAccounts ?? 0
  const canonicalCount = data?.metrics?.canonicalAccounts ?? 0
  const legacyCount = data?.metrics?.legacyAccounts ?? 0
  const lockedCount = data?.metrics?.lockedAccounts ?? 0

  const openAccount = (account: AccountRow) => {
    setSelected(account)
    setSelectedRole(account.role === "staff" ? "staff" : "user")
    setActionError(null)
    setMessage(null)
  }

  const run = async (action: () => Promise<unknown>, success: string, close = false) => {
    setBusy(true)
    setActionError(null)
    setMessage(null)
    try {
      await action()
      showToast(success)
      reload()
      if (close) setSelected(null)
    } catch (reason) {
      setActionError(readError(reason))
      showToast(`Lỗi: ${readError(reason)}`)
    } finally {
      setBusy(false)
    }
  }

  const saveInvite = () =>
    run(async () => {
      await createInvite(invite)
      setInvite(emptyInvite)
      setInviteOpen(false)
    }, "Đã tạo lời mời đăng nhập. Người dùng sẽ liên kết tài khoản khi đăng nhập Google lần đầu.")

  const grantLegacy = (account: AccountRow) =>
    run(
      () =>
        createInvite({
          email: account.email,
          fullName: account.fullName,
          memberCode: account.memberCode,
          role: account.role === "staff" ? "staff" : "user",
          ...(account.role === "staff" ? {} : { rollNumber: account.rollNumber }),
        }),
      "Đã tạo quyền đăng nhập từ hồ sơ dữ liệu cũ."
    )

  const openEdit = (account: AccountRow) =>
    setEdit({
      email: account.email,
      fullName: account.fullName,
      memberCode: account.memberCode,
      role: account.role === "staff" ? "staff" : "user",
      rollNumber: account.rollNumber,
    })

  const saveEdit = () => {
    if (!selected || !edit) return
    void run(
      async () => {
        await updateAccount(selected, edit)
        setEdit(null)
      },
      "Đã cập nhật tài khoản.",
      true
    )
  }

  const handleExportExcel = async () => {
    showToast("Đang tạo tệp danh sách tài khoản CSV...")
    const exportAccounts = await listAllAccountsForExport()
    const rows = [
      ["MemberCode", "RollNumber", "FullName", "Email", "Role", "Active", "Canonical"],
      ...exportAccounts.map((a) => [
        a.memberCode,
        a.rollNumber,
        a.fullName,
        a.email,
        a.role,
        a.active ? "Active" : "Locked",
        a.canonical ? "Linked" : "Legacy",
      ]),
    ]
    const csvContent =
      "data:text/csv;charset=utf-8,\uFEFF" + rows.map((e) => e.map(csvCell).join(",")).join("\n")
    const encodedUri = encodeURI(csvContent)
    const link = document.createElement("a")
    link.setAttribute("href", encodedUri)
    link.setAttribute("download", `Danh_sach_tai_khoan_FAP_${Date.now()}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  const resetFilters = () => {
    setSearch("")
    setRoleFilter("all")
    setLinkFilter("all")
    setStatusFilter("all")
    setUserPage(1)
    setInvitePage(1)
  }

  return (
    <div className="space-y-6 text-slate-800 pb-12">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed top-5 right-5 z-50 flex items-center gap-2.5 bg-slate-900 text-white px-4 py-3 rounded-xl shadow-xl text-xs font-medium animate-in fade-in slide-in-from-top-2 duration-200">
          <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
          <span>{toastMessage}</span>
          <button
            onClick={() => setToastMessage(null)}
            className="ml-2 text-slate-400 hover:text-white"
          >
            <X size={14} />
          </button>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              Tài khoản &amp; Phân quyền
            </h1>
            <span className="px-2 py-0.5 rounded-md text-[11px] font-semibold bg-slate-100 text-slate-600 border border-slate-200/80">
              FAP v4.2 Cloud
            </span>
          </div>
          <p className="text-xs text-slate-400 mt-1 max-w-2xl">
            Cấp quyền đăng nhập lần đầu, kiểm tra hồ sơ xác thực, phân quyền vai trò (Giảng viên, Sinh viên, Ban Đào tạo) và quản lý trạng thái khóa/kích hoạt tài khoản người dùng.
          </p>
        </div>

        {/* Top Right Action Buttons */}
        <div className="flex items-center gap-2.5">
          <button
            type="button"
            onClick={handleExportExcel}
            className="h-9 flex items-center gap-2 px-3.5 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 rounded-xl text-xs font-semibold shadow-xs transition cursor-pointer"
          >
            <Download size={14} className="text-slate-500" />
            <span>Tải CSV</span>
          </button>

          <button
            type="button"
            onClick={() => setInviteOpen(true)}
            className="h-9 flex items-center gap-2 px-4 bg-[#C2410C] hover:bg-[#9A3412] text-white rounded-xl text-xs font-semibold shadow-xs transition cursor-pointer"
          >
            <KeyRound size={14} />
            <span>+ Tạo lời mời đăng nhập</span>
          </button>
        </div>
      </div>

      {/* 4 KPI Metric Cards */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1: Tổng tài khoản hệ thống */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:shadow-md transition">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-slate-500">Tổng tài khoản hệ thống</span>
              <span className="w-7 h-7 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center">
                <Users size={16} />
              </span>
            </div>
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight mb-2">
              {loading ? "..." : totalUsersCount.toLocaleString("en-US")}
            </div>
          </div>
          <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-50">
            <span className="text-emerald-700 font-semibold flex items-center gap-1">
              <Check size={13} className="text-emerald-600" />
              100% đồng bộ
            </span>
            <span className="text-slate-400 text-[11px]">• Sinh viên &amp; GV</span>
          </div>
        </div>

        {/* Card 2: Đã liên kết Auth UID */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:shadow-md transition">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-slate-500">Đã liên kết Auth UID</span>
              <span className="w-7 h-7 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <ShieldCheck size={16} />
              </span>
            </div>
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight mb-2">
              {loading ? "..." : canonicalCount.toLocaleString("en-US")}
            </div>
          </div>
          <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-50">
            <span className="text-emerald-700 font-semibold">92.3%</span>
            <span className="text-slate-400 text-[11px]">Google SSO @fpt.edu.vn</span>
          </div>
        </div>

        {/* Card 3: Dữ liệu cũ (Chưa liên kết) */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:shadow-md transition">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-slate-500">
                Dữ liệu cũ (Chưa liên kết)
              </span>
              <span className="w-7 h-7 rounded-lg bg-orange-50 text-[#EA580C] flex items-center justify-center">
                <KeyRound size={16} />
              </span>
            </div>
            <div className="text-3xl font-extrabold text-[#EA580C] tracking-tight mb-2">
              {loading ? "..." : legacyCount.toLocaleString("en-US")}
            </div>
          </div>
          <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-50">
            <span className="text-[#EA580C] font-semibold bg-[#FFF0E6] px-1.5 py-0.2 rounded text-[11px]">
              Cần cấp quyền
            </span>
            <span className="text-slate-400 text-[11px]">Khóa K19, K20</span>
          </div>
        </div>

        {/* Card 4: Tài khoản bị khóa */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:shadow-md transition">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-slate-500">Tài khoản bị khóa</span>
              <span className="w-7 h-7 rounded-lg bg-red-50 text-red-500 flex items-center justify-center">
                <Lock size={16} />
              </span>
            </div>
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight mb-2">
              {loading ? "..." : lockedCount.toLocaleString("en-US")}
            </div>
          </div>
          <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-50">
            <span className="text-red-600 font-semibold text-[11px]">active = false</span>
            <span className="text-slate-400 text-[11px]">• Tạm ngưng học vụ</span>
          </div>
        </div>
      </section>

      {/* Guide Banner: "Admin có thể làm gì ở đây?" */}
      <section className="bg-blue-50/40 border border-blue-100/90 rounded-2xl p-5 shadow-xs space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
          <div className="flex items-center gap-2.5">
            <span className="w-7 h-7 rounded-full bg-blue-100/70 text-blue-700 flex items-center justify-center">
              <ShieldCheck size={16} />
            </span>
            <h3 className="text-sm font-bold text-slate-900">
              Admin có thể làm gì ở đây?
            </h3>
          </div>
          <span className="text-[10px] font-semibold text-slate-600 bg-white border border-slate-200 px-2.5 py-0.5 rounded-full shadow-2xs self-start sm:self-auto">
            Quyền quản trị cấp cao • Security Scope
          </span>
        </div>

        <p className="text-xs text-slate-600 leading-relaxed max-w-4xl">
          Quản lý quyền truy cập hệ thống mà không cần biết mật khẩu của người dùng. Cấp quyền đăng nhập một lần, kiểm tra hồ sơ gắn Auth UID, khóa và thu hồi quyền truy cập tức thì.
        </p>

        {/* 4 Process Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 pt-1">
          <div className="bg-white p-3.5 rounded-xl border border-slate-100 shadow-2xs space-y-1">
            <div className="flex items-center gap-1.5 font-bold text-xs text-slate-800">
              <span className="w-4 h-4 rounded-full bg-slate-200 text-slate-700 text-[10px] font-bold flex items-center justify-center">
                1
              </span>
              <span>Quản lý tài khoản</span>
            </div>
            <p className="text-[11px] text-slate-500 leading-normal">
              Xem hồ sơ, vai trò và trạng thái; khóa/mở hoặc đổi giữa Sinh viên và Giảng viên.
            </p>
          </div>

          <div className="bg-white p-3.5 rounded-xl border border-slate-100 shadow-2xs space-y-1">
            <div className="flex items-center gap-1.5 font-bold text-xs text-slate-800">
              <span className="w-4 h-4 rounded-full bg-slate-200 text-slate-700 text-[10px] font-bold flex items-center justify-center">
                2
              </span>
              <span>Cấp quyền đăng nhập</span>
            </div>
            <p className="text-[11px] text-slate-500 leading-normal">
              Cho phép một email Google đăng nhập lần đầu. Không phải email mời và không tự gửi thư.
            </p>
          </div>

          <div className="bg-white p-3.5 rounded-xl border border-slate-100 shadow-2xs space-y-1">
            <div className="flex items-center gap-1.5 font-bold text-xs text-slate-800">
              <span className="w-4 h-4 rounded-full bg-slate-200 text-slate-700 text-[10px] font-bold flex items-center justify-center">
                3
              </span>
              <span>Hiểu trạng thái liên kết</span>
            </div>
            <p className="text-[11px] text-slate-500 leading-normal">
              &quot;Đã liên kết&quot; là hồ sơ đã gắn Auth UID. &quot;Dữ liệu cũ&quot; cần cấp quyền để liên kết khi đăng nhập.
            </p>
          </div>

          <div className="bg-white p-3.5 rounded-xl border border-slate-100 shadow-2xs space-y-1">
            <div className="flex items-center gap-1.5 font-bold text-xs text-slate-800">
              <span className="w-4 h-4 rounded-full bg-slate-200 text-slate-700 text-[10px] font-bold flex items-center justify-center">
                4
              </span>
              <span>Khóa và thu hồi</span>
            </div>
            <p className="text-[11px] text-slate-500 leading-normal">
              Khóa sẽ chặn truy cập bằng active = false. Thu hồi chỉ xóa quyền đăng nhập chưa dùng.
            </p>
          </div>
        </div>

        <div className="text-[11px] text-slate-400 flex items-center gap-1.5 pt-1">
          <Info size={13} className="shrink-0" />
          <span>Lưu ý: xóa hoàn toàn một người dùng khỏi Firebase Authentication cần backend Admin SDK; trang này không xóa tài khoản Google.</span>
        </div>
      </section>

      {/* Tabs & Table Card */}
      <section className="bg-white border border-slate-100 rounded-2xl shadow-xs overflow-hidden">
        {/* Tab Headers */}
        <div className="px-6 pt-4 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div className="flex items-center gap-6 text-xs">
            <button
              type="button"
              onClick={() => setTab("users")}
              className={`pb-3 font-bold flex items-center gap-2 border-b-2 transition cursor-pointer ${
                tab === "users"
                  ? "border-[#EA580C] text-[#C2410C]"
                  : "border-transparent text-slate-500 hover:text-slate-800"
              }`}
            >
              <span>Tài khoản người dùng</span>
              <span
                className={`text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                  tab === "users" ? "bg-[#FFF0E6] text-[#EA580C]" : "bg-slate-100 text-slate-500"
                }`}
              >
                {data?.totalAccounts ?? (data?.metrics?.totalAccounts ?? 2904)}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setTab("invites")}
              className={`pb-3 font-bold flex items-center gap-2 border-b-2 transition cursor-pointer ${
                tab === "invites"
                  ? "border-[#EA580C] text-[#C2410C]"
                  : "border-transparent text-slate-500 hover:text-slate-800"
              }`}
            >
              <span>Quyền đăng nhập chờ duyệt</span>
              <span
                className={`text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                  tab === "invites" ? "bg-[#FFF0E6] text-[#EA580C]" : "bg-slate-100 text-slate-500"
                }`}
              >
                {data?.totalInvites ?? data?.metrics?.totalInvites ?? 0}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setTab("audit")}
              className={`pb-3 font-bold flex items-center gap-2 border-b-2 transition cursor-pointer ${
                tab === "audit"
                  ? "border-[#EA580C] text-[#C2410C]"
                  : "border-transparent text-slate-500 hover:text-slate-800"
              }`}
            >
              <span>Nhật ký truy cập (Audit Log)</span>
              <span
                className={`text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                  tab === "audit" ? "bg-[#FFF0E6] text-[#EA580C]" : "bg-slate-100 text-slate-500"
                }`}
              >
                {data?.totalAuditLogs ?? 0}
              </span>
            </button>
          </div>

          <div className="pb-3 text-slate-400 text-xs flex items-center gap-2 self-end sm:self-auto">
            <span>Đồng bộ thời gian thực từ Firestore</span>
            <button
              type="button"
              onClick={reload}
              title="Tải lại dữ liệu"
              className="p-1 hover:bg-slate-100 rounded text-slate-500 cursor-pointer"
            >
              <RotateCw size={12} className={loading ? "animate-spin" : ""} />
            </button>
          </div>
        </div>

        {/* Filter Toolbar */}
        <div className="p-4 bg-slate-50/50 border-b border-slate-100 flex flex-wrap items-center gap-3 text-xs">
          {/* Search Box */}
          <div className="relative flex-1 min-w-[240px]">
            <Search size={14} className="absolute left-3 top-2.5 text-slate-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value)
                setUserPage(1)
                setInvitePage(1)
              }}
              placeholder="Tìm email, mã thành viên (Roll/MemberCode), tên..."
              className="w-full pl-8 pr-3 py-1.5 text-xs bg-white border border-slate-200 rounded-xl text-slate-700 placeholder:text-slate-400 focus:outline-none focus:border-[#EA580C]"
            />
          </div>

          {/* Role Filter */}
          <div className="relative">
            <select
              value={roleFilter}
              onChange={(e) => {
                setRoleFilter(e.target.value)
                setUserPage(1)
              }}
              className="text-xs bg-white border border-slate-200 text-slate-700 px-3 py-1.5 rounded-xl appearance-none pr-7 focus:outline-none focus:border-[#EA580C] cursor-pointer"
            >
              <option value="all">Tất cả vai trò</option>
              <option value="user">Sinh viên</option>
              <option value="staff">Giảng viên</option>
              <option value="admin">Quản trị viên (Admin)</option>
            </select>
            <ChevronDown size={12} className="absolute right-2.5 top-2.5 text-slate-400 pointer-events-none" />
          </div>

          {/* Link Status Filter */}
          <div className="relative">
            <select
              value={linkFilter}
              onChange={(e) => {
                setLinkFilter(e.target.value)
                setUserPage(1)
              }}
              className="text-xs bg-white border border-slate-200 text-slate-700 px-3 py-1.5 rounded-xl appearance-none pr-7 focus:outline-none focus:border-[#EA580C] cursor-pointer"
            >
              <option value="all">Tất cả liên kết</option>
              <option value="canonical">Đã liên kết UID</option>
              <option value="legacy">Chưa liên kết (Dữ liệu cũ)</option>
            </select>
            <ChevronDown size={12} className="absolute right-2.5 top-2.5 text-slate-400 pointer-events-none" />
          </div>

          {/* Status Filter */}
          <div className="relative">
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value)
                setUserPage(1)
              }}
              className="text-xs bg-white border border-slate-200 text-slate-700 px-3 py-1.5 rounded-xl appearance-none pr-7 focus:outline-none focus:border-[#EA580C] cursor-pointer"
            >
              <option value="all">Trạng thái: Tất cả</option>
              <option value="active">Đang hoạt động</option>
              <option value="inactive">Đã khóa</option>
            </select>
            <ChevronDown size={12} className="absolute right-2.5 top-2.5 text-slate-400 pointer-events-none" />
          </div>

          {/* Reset Filters */}
          <button
            type="button"
            onClick={resetFilters}
            className="flex items-center gap-1 text-slate-500 hover:text-slate-800 text-xs px-2 py-1.5 rounded hover:bg-slate-100 transition cursor-pointer"
          >
            <RotateCcw size={12} />
            <span>Đặt lại</span>
          </button>
        </div>

        {/* Tab 1: User Accounts Table */}
        {tab === "users" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 text-slate-500 font-semibold border-b border-slate-100 text-xs uppercase tracking-wider">
                  <th className="py-3.5 px-5">Thành viên / Họ tên</th>
                  <th className="py-3.5 px-4">Mã số / Roll</th>
                  <th className="py-3.5 px-4">Vai trò</th>
                  <th className="py-3.5 px-4">Liên kết Auth UID</th>
                  <th className="py-3.5 px-4">Trạng thái</th>
                  <th className="py-3.5 px-5 text-right w-28">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="py-12 text-center text-slate-400">
                      <div className="flex items-center justify-center gap-2">
                        <LoaderCircle className="animate-spin text-[#EA580C]" size={18} />
                        <span>Đang tải danh sách tài khoản...</span>
                      </div>
                    </td>
                  </tr>
                ) : accounts.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-12 text-center text-slate-400">
                      Không tìm thấy tài khoản nào phù hợp với bộ lọc.
                    </td>
                  </tr>
                ) : (
                  paginatedAccounts.map((row) => (
                    <tr
                      key={row.id}
                      onClick={() => openAccount(row)}
                      className="hover:bg-slate-50/70 transition group cursor-pointer"
                    >
                      {/* Name & Email */}
                      <td className="py-3.5 px-5">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-full bg-orange-50 text-[#C2410C] font-bold text-xs flex items-center justify-center shrink-0">
                            {initials(row.fullName || row.memberCode)}
                          </div>
                          <div>
                            <div className="font-bold text-slate-900 group-hover:text-[#C2410C] transition text-sm">
                              {row.fullName || "Chưa có tên"}
                            </div>
                            <div className="text-xs text-slate-400 truncate max-w-[240px]">
                              {row.email}
                            </div>
                          </div>
                        </div>
                      </td>

                      {/* MemberCode / RollNumber */}
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-slate-800 text-sm">{row.memberCode}</div>
                        {row.rollNumber && (
                          <div className="text-xs text-slate-400 font-mono">
                            {row.rollNumber}
                          </div>
                        )}
                      </td>

                      {/* Role */}
                      <td className="py-3.5 px-4">
                        {row.role === "admin" && (
                          <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-purple-50 text-purple-700 border border-purple-200">
                            Admin
                          </span>
                        )}
                        {row.role === "staff" && (
                          <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                            Giảng viên
                          </span>
                        )}
                        {row.role === "user" && (
                          <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200">
                            Sinh viên
                          </span>
                        )}
                      </td>

                      {/* Link status */}
                      <td className="py-3.5 px-4">
                        {row.canonical ? (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                            Đã liên kết
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700">
                            <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
                            Dữ liệu cũ
                          </span>
                        )}
                      </td>

                      {/* Active status */}
                      <td className="py-3.5 px-4">
                        {row.active === false ? (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-red-50 text-red-600">
                            <span className="w-1.5 h-1.5 rounded-full bg-red-500" />
                            Đã khóa
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                            Đang hoạt động
                          </span>
                        )}
                        {row.id === currentAdmin.uid && (
                          <span className="ml-1 text-xs text-slate-400 font-normal">
                            (Bạn)
                          </span>
                        )}
                      </td>

                      {/* Actions */}
                      <td className="py-3.5 px-5 text-right">
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation()
                            openAccount(row)
                          }}
                          className="px-3.5 py-1.5 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 rounded-lg text-xs font-semibold shadow-2xs transition cursor-pointer"
                        >
                          Quản lý
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 2: Invites Table */}
        {tab === "invites" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 text-slate-500 font-semibold border-b border-slate-100 text-xs uppercase tracking-wider">
                  <th className="py-3.5 px-5">Người dùng / Email</th>
                  <th className="py-3.5 px-4">Mã số</th>
                  <th className="py-3.5 px-4">Vai trò cấp</th>
                  <th className="py-3.5 px-4">Trạng thái đăng nhập</th>
                  <th className="py-3.5 px-5 text-right w-28">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {invites.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="py-12 text-center text-slate-400">
                      Chưa có lời cấp quyền đăng nhập nào đang chờ.
                    </td>
                  </tr>
                ) : (
                  paginatedInvites.map((row) => {
                    const used = canonicalEmails.has(row.email.toLowerCase())
                    return (
                      <tr key={row.id} className="hover:bg-slate-50/70 transition">
                        <td className="py-3.5 px-5">
                          <div className="font-bold text-slate-900 text-sm">{row.fullName}</div>
                          <div className="text-xs text-slate-400">{row.email}</div>
                        </td>
                        <td className="py-3.5 px-4 font-mono font-bold text-slate-800 text-sm">
                          {row.memberCode}
                        </td>
                        <td className="py-3.5 px-4 font-semibold text-slate-700 text-sm">
                          {row.role === "staff" ? "Giảng viên" : "Sinh viên"}
                        </td>
                        <td className="py-3.5 px-4">
                          <span
                            className={`px-2.5 py-1 rounded-full text-xs font-semibold ${
                              used
                                ? "bg-emerald-50 text-emerald-700"
                                : "bg-amber-50 text-amber-700"
                            }`}
                          >
                            {used ? "Đã đăng nhập" : "Chờ đăng nhập lần đầu"}
                          </span>
                        </td>
                        <td className="py-3.5 px-5 text-right">
                          <button
                            type="button"
                            onClick={() =>
                              void run(
                                () => revokeInvite(row.id),
                                "Đã thu hồi quyền đăng nhập."
                              )
                            }
                            className="px-3 py-1.5 text-xs text-red-600 hover:bg-red-50 rounded-lg font-semibold transition cursor-pointer"
                          >
                            Thu hồi
                          </button>
                        </td>
                      </tr>
                    )
                  })
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 3: Audit Log Table */}
        {tab === "audit" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 text-slate-500 font-semibold border-b border-slate-100 text-xs uppercase tracking-wider">
                  <th className="py-3.5 px-5">Thời gian</th>
                  <th className="py-3.5 px-4">Người thực hiện</th>
                  <th className="py-3.5 px-4">Hành động</th>
                  <th className="py-3.5 px-4">Đối tượng / Tài khoản</th>
                  <th className="py-3.5 px-4">Vai trò</th>
                  <th className="py-3.5 px-5 text-right">Trạng thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {paginatedAuditLogs.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-12 text-center text-slate-400">
                      {loading ? "Đang tải nhật ký truy cập từ Firestore..." : "Chưa có nhật ký truy cập nào trên Firestore."}
                    </td>
                  </tr>
                ) : (
                  paginatedAuditLogs.map((log) => (
                    <tr key={log.id} className="hover:bg-slate-50/70 transition">
                      <td className="py-3.5 px-5 font-mono text-slate-500 text-xs">
                        {log.time}
                      </td>
                      <td className="py-3.5 px-4 font-bold text-slate-800 text-sm">
                        {log.actor}
                      </td>
                      <td className="py-3.5 px-4 font-semibold text-[#C2410C] text-sm">
                        {log.action}
                      </td>
                      <td className="py-3.5 px-4 text-slate-700 text-sm">
                        {log.target}
                      </td>
                      <td className="py-3.5 px-4">
                        <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">
                          {log.role}
                        </span>
                      </td>
                      <td className="py-3.5 px-5 text-right">
                        <span
                          className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                            log.status === "Thành công"
                              ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                              : "bg-amber-50 text-amber-700 border border-amber-200"
                          }`}
                        >
                          {log.status}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Table Footer & Synchronized Pagination */}
        {tab === "users" && (
          <Pagination
            currentPage={userPage}
            totalItems={data?.totalAccounts ?? 0}
            pageSize={10}
            onPageChange={setUserPage}
            itemLabel="tài khoản người dùng"
            syncNote="Phân trang Firestore Backend"
          />
        )}
        {tab === "invites" && (
          <Pagination
            currentPage={invitePage}
            totalItems={data?.totalInvites ?? 0}
            pageSize={10}
            onPageChange={setInvitePage}
            itemLabel="lời mời cấp quyền"
            syncNote="Phân trang Firestore Backend"
          />
        )}
        {tab === "audit" && (
          <Pagination
            currentPage={auditPage}
            totalItems={data?.totalAuditLogs ?? 0}
            pageSize={10}
            onPageChange={setAuditPage}
            itemLabel="nhật ký truy cập"
            syncNote="Nhật ký từ Cloud Firestore"
          />
        )}
      </section>

      {/* Account Details Modal (Popup nổi chính giữa) */}
      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs transition"
            onClick={() => setSelected(null)}
          />
          <div className="relative bg-white rounded-2xl shadow-2xl border border-slate-100 w-full max-w-lg overflow-hidden animate-in fade-in zoom-in-95 duration-150 max-h-[90vh] flex flex-col">
            {/* Modal Head */}
            <div className="p-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/70 shrink-0">
              <div>
                <span className="text-[11px] font-bold text-[#EA580C] uppercase tracking-wider">
                  Chi tiết tài khoản
                </span>
                <h3 className="text-base font-bold text-slate-900 mt-0.5">
                  {selected.fullName || selected.memberCode}
                </h3>
                <p className="text-xs text-slate-400">{selected.email}</p>
              </div>
              <button
                onClick={() => setSelected(null)}
                className="w-8 h-8 rounded-full hover:bg-slate-200 text-slate-400 hover:text-slate-700 flex items-center justify-center cursor-pointer"
              >
                <X size={18} />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-5 space-y-4 text-xs overflow-y-auto flex-1">
              {/* User Summary Pill */}
              <div className="flex items-center gap-3 bg-slate-50 p-3.5 rounded-xl border border-slate-100">
                <div className="w-10 h-10 rounded-full bg-orange-100 text-[#C2410C] font-bold text-sm flex items-center justify-center shrink-0">
                  {initials(selected.fullName || selected.memberCode)}
                </div>
                <div className="flex-1">
                  <div className="font-bold text-slate-900 text-sm">
                    {selected.memberCode}
                  </div>
                  <div className="text-slate-500">{roleLabel(selected.role)}</div>
                </div>
                <span
                  className={`px-2 py-0.5 rounded-full text-[11px] font-semibold ${
                    selected.canonical
                      ? "bg-emerald-50 text-emerald-700"
                      : "bg-amber-50 text-amber-700"
                  }`}
                >
                  {selected.canonical ? "Đã liên kết" : "Dữ liệu cũ"}
                </span>
              </div>

              {/* Details list */}
              <div className="space-y-2 border border-slate-100 rounded-xl p-3.5 divide-y divide-slate-100">
                <div className="flex justify-between py-1.5 first:pt-0">
                  <span className="text-slate-400">Document ID:</span>
                  <span className="font-mono text-slate-700 truncate max-w-[240px]">
                    {selected.id}
                  </span>
                </div>
                <div className="flex justify-between py-1.5">
                  <span className="text-slate-400">Roll number:</span>
                  <span className="font-bold text-slate-800">
                    {selected.rollNumber || "—"}
                  </span>
                </div>
                <div className="flex justify-between py-1.5 last:pb-0">
                  <span className="text-slate-400">Trạng thái:</span>
                  <span
                    className={`font-semibold ${
                      selected.active === false
                        ? "text-red-600"
                        : selected.active
                        ? "text-emerald-600"
                        : "text-amber-600"
                    }`}
                  >
                    {selected.active === null
                      ? "Chưa liên kết đăng nhập"
                      : selected.active
                      ? "Đang hoạt động"
                      : "Đã khóa"}
                  </span>
                </div>
              </div>

              {/* Actions */}
              <div className="space-y-3 pt-1">
                <h4 className="font-bold text-slate-800 text-xs">
                  Thao tác quản trị quyền
                </h4>

                {selected.canonical ? (
                  <div className="space-y-2.5">
                    {selected.role !== "admin" && (
                      <>
                        <button
                          type="button"
                          onClick={() => openEdit(selected)}
                          className="w-full h-9 flex items-center justify-center gap-2 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 rounded-xl font-semibold shadow-xs transition cursor-pointer"
                        >
                          <Pencil size={14} />
                          <span>Chỉnh sửa thông tin tài khoản</span>
                        </button>

                        <div className="flex items-center gap-2">
                          <select
                            value={selectedRole}
                            onChange={(e) =>
                              setSelectedRole(e.target.value as "user" | "staff")
                            }
                            className="flex-1 h-9 px-3 bg-white border border-slate-200 rounded-xl text-slate-700 font-semibold focus:outline-none focus:border-[#EA580C]"
                          >
                            <option value="user">Sinh viên</option>
                            <option value="staff">Giảng viên</option>
                          </select>

                          <button
                            type="button"
                            disabled={busy}
                            onClick={() =>
                              void run(
                                () => setAccountRole(selected, selectedRole),
                                "Đã cập nhật vai trò tài khoản."
                              )
                            }
                            className="h-9 px-4 bg-[#C2410C] hover:bg-[#9A3412] text-white rounded-xl font-semibold shadow-xs transition cursor-pointer disabled:opacity-50"
                          >
                            Lưu vai trò
                          </button>
                        </div>
                      </>
                    )}

                    {/* Lock / Unlock Toggle button */}
                    <button
                      type="button"
                      disabled={busy || selected.id === currentAdmin.uid}
                      onClick={() =>
                        void run(
                          () => setAccountActive(selected, selected.active !== true),
                          selected.active ? "Đã khóa tài khoản." : "Đã mở khóa tài khoản.",
                          true
                        )
                      }
                      className={`w-full h-9 flex items-center justify-center gap-2 rounded-xl font-semibold transition cursor-pointer shadow-xs disabled:opacity-50 ${
                        selected.active
                          ? "bg-red-50 text-red-600 hover:bg-red-100 border border-red-200"
                          : "bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200"
                      }`}
                    >
                      {selected.active ? <Lock size={14} /> : <Unlock size={14} />}
                      <span>
                        {selected.active ? "Khóa tài khoản (Chặn đăng nhập)" : "Mở khóa tài khoản"}
                      </span>
                    </button>

                    {selected.id === currentAdmin.uid && (
                      <p className="text-[11px] text-slate-400 text-center">
                        Không thể tự khóa tài khoản Admin đang đăng nhập.
                      </p>
                    )}
                  </div>
                ) : (
                  <div className="space-y-2.5 bg-amber-50/60 border border-amber-200/80 rounded-xl p-3.5">
                    <p className="text-[11px] text-amber-900 leading-relaxed font-normal">
                      Hồ sơ này chưa gắn Firebase Auth UID. Bạn có thể cấp quyền để người dùng liên kết khi đăng nhập Google lần đầu.
                    </p>
                    <button
                      type="button"
                      disabled={
                        busy ||
                        !selected.email ||
                        inviteEmails.has(selected.email.toLowerCase())
                      }
                      onClick={() => void grantLegacy(selected)}
                      className="w-full h-9 flex items-center justify-center gap-2 bg-[#C2410C] hover:bg-[#9A3412] text-white rounded-xl font-semibold shadow-xs transition cursor-pointer disabled:opacity-50"
                    >
                      <KeyRound size={14} />
                      <span>
                        {inviteEmails.has(selected.email.toLowerCase())
                          ? "Đã có quyền đăng nhập"
                          : "Cấp quyền từ hồ sơ này"}
                      </span>
                    </button>
                  </div>
                )}
              </div>
            </div>

            {/* Modal Footer */}
            <div className="p-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-end shrink-0">
              <button
                type="button"
                onClick={() => setSelected(null)}
                className="h-9 px-5 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 rounded-xl font-semibold transition cursor-pointer"
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Invite Modal (Cấp quyền tài khoản) */}
      {inviteOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs transition"
            onClick={() => setInviteOpen(false)}
          />
          <div className="relative bg-white rounded-2xl shadow-2xl border border-slate-100 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="p-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/70">
              <div>
                <span className="text-[11px] font-bold text-[#EA580C] uppercase tracking-wider">
                  Lời mời đăng nhập mới
                </span>
                <h3 className="text-base font-bold text-slate-900 mt-0.5">
                  Tạo dữ liệu để liên kết khi người dùng đăng nhập Google lần đầu
                </h3>
              </div>
              <button
                onClick={() => setInviteOpen(false)}
                className="w-8 h-8 rounded-full hover:bg-slate-200 text-slate-400 hover:text-slate-700 flex items-center justify-center cursor-pointer"
              >
                <X size={18} />
              </button>
            </div>

            <div className="p-5 space-y-3.5 text-xs">
              <div>
                <label className="font-bold text-slate-700 block mb-1">
                  Email Google FPT <span className="text-[#EA580C]">*</span>
                </label>
                <input
                  type="email"
                  value={invite.email}
                  onChange={(e) => setInvite({ ...invite, email: e.target.value })}
                  placeholder="VD: kiethn@fpt.edu.vn"
                  className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-[#EA580C]"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">
                  Họ và tên <span className="text-[#EA580C]">*</span>
                </label>
                <input
                  type="text"
                  value={invite.fullName}
                  onChange={(e) => setInvite({ ...invite, fullName: e.target.value })}
                  placeholder="VD: Nguyễn Tuấn Kiệt"
                  className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-[#EA580C]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    Mã thành viên <span className="text-[#EA580C]">*</span>
                  </label>
                  <input
                    type="text"
                    value={invite.memberCode}
                    onChange={(e) => setInvite({ ...invite, memberCode: e.target.value })}
                    placeholder="VD: KietNT"
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-[#EA580C]"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    Vai trò <span className="text-[#EA580C]">*</span>
                  </label>
                  <select
                    value={invite.role}
                    onChange={(e) =>
                      setInvite({
                        ...invite,
                        role: e.target.value as "user" | "staff",
                      })
                    }
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-[#EA580C]"
                  >
                    <option value="user">Sinh viên</option>
                    <option value="staff">Giảng viên</option>
                  </select>
                </div>
              </div>

              {invite.role === "user" && (
                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    Roll Number (Mã sinh viên) <span className="text-[#EA580C]">*</span>
                  </label>
                  <input
                    type="text"
                    value={invite.rollNumber}
                    onChange={(e) => setInvite({ ...invite, rollNumber: e.target.value })}
                    placeholder="VD: HE170241"
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-[#EA580C]"
                  />
                </div>
              )}

              <div className="pt-2 flex items-center justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setInviteOpen(false)}
                  className="h-9 px-4 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 rounded-xl font-semibold transition cursor-pointer"
                >
                  Hủy
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={saveInvite}
                  className="h-9 px-4 bg-[#C2410C] hover:bg-[#9A3412] text-white rounded-xl font-semibold shadow-xs transition cursor-pointer disabled:opacity-50"
                >
                  {busy ? "Đang tạo..." : "Tạo lời mời"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Account Modal */}
      {edit && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs transition"
            onClick={() => setEdit(null)}
          />
          <div className="relative bg-white rounded-2xl shadow-2xl border border-slate-100 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="p-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/70">
              <h3 className="text-base font-bold text-slate-900">
                Chỉnh sửa thông tin tài khoản
              </h3>
              <button
                onClick={() => setEdit(null)}
                className="w-8 h-8 rounded-full hover:bg-slate-200 text-slate-400 hover:text-slate-700 flex items-center justify-center cursor-pointer"
              >
                <X size={18} />
              </button>
            </div>

            <div className="p-5 space-y-3.5 text-xs">
              <div>
                <label className="font-bold text-slate-500 block mb-1">Email Google</label>
                <input
                  type="email"
                  value={edit.email}
                  disabled
                  className="w-full px-3.5 py-2 bg-slate-100 border border-slate-200 rounded-xl text-slate-500 cursor-not-allowed"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">
                  Họ và tên <span className="text-[#EA580C]">*</span>
                </label>
                <input
                  type="text"
                  value={edit.fullName}
                  onChange={(e) => setEdit({ ...edit, fullName: e.target.value })}
                  className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-[#EA580C]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    Mã thành viên <span className="text-[#EA580C]">*</span>
                  </label>
                  <input
                    type="text"
                    value={edit.memberCode}
                    onChange={(e) => setEdit({ ...edit, memberCode: e.target.value })}
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-[#EA580C]"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    Vai trò <span className="text-[#EA580C]">*</span>
                  </label>
                  <select
                    value={edit.role}
                    onChange={(e) =>
                      setEdit({
                        ...edit,
                        role: e.target.value as "user" | "staff",
                      })
                    }
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-[#EA580C]"
                  >
                    <option value="user">Sinh viên</option>
                    <option value="staff">Giảng viên</option>
                  </select>
                </div>
              </div>

              {edit.role === "user" && (
                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    Roll Number <span className="text-[#EA580C]">*</span>
                  </label>
                  <input
                    type="text"
                    value={edit.rollNumber}
                    onChange={(e) => setEdit({ ...edit, rollNumber: e.target.value })}
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-[#EA580C]"
                  />
                </div>
              )}

              <div className="pt-2 flex items-center justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => setEdit(null)}
                  className="h-9 px-4 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 rounded-xl font-semibold transition cursor-pointer"
                >
                  Hủy
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={saveEdit}
                  className="h-9 px-4 bg-[#C2410C] hover:bg-[#9A3412] text-white rounded-xl font-semibold shadow-xs transition cursor-pointer disabled:opacity-50"
                >
                  {busy ? "Đang lưu..." : "Lưu thay đổi"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function roleLabel(role: string) {
  return (
    ({
      user: "Sinh viên",
      SV: "Sinh viên (dữ liệu cũ)",
      staff: "Giảng viên",
      GV: "Giảng viên (dữ liệu cũ)",
      admin: "Quản trị viên (Admin)",
    } as Record<string, string>)[role] ?? role
  )
}

function initials(name: string) {
  return (
    name
      .trim()
      .split(/\s+/)
      .slice(-2)
      .map((word) => word[0]?.toUpperCase())
      .join("") || "?"
  )
}

function csvCell(value: string | number | boolean) {
  const text = String(value)
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text
}
