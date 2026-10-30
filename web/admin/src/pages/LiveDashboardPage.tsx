import { useCallback } from "react"
import {
  AlertTriangle,
  ArrowRight,
  BookOpen,
  Check,
  ClipboardCheck,
  Download,
  ExternalLink,
  Info,
  Server,
  ShieldAlert,
  Users,
} from "lucide-react"
import { useAsyncData } from "../hooks/useAsyncData"
import { getDashboardStats } from "../repositories/dashboardRepository"
import type { AdminPage } from "../types/admin-v2"

export function LiveDashboard({
  onNavigate,
}: {
  onNavigate: (page: AdminPage) => void
}) {
  const loader = useCallback(getDashboardStats, [])
  const { data, loading, error, reload } = useAsyncData(loader)

  const handleReload = () => {
    void reload()
  }

  // Real data from Firestore (0 fallback when loading/empty, no mock data)
  const activeUsersCount = data?.activeUsers ?? 0
  const totalUsersCount = data?.totalUsers ?? 0
  const adminCount = data?.adminCount ?? 0
  const classesCount = data?.classes ?? 0
  const subjectsCount = data?.subjects ?? 0
  const openSessionsCount = data?.openSessions ?? 0
  const totalSessionsCount = data?.totalSessions ?? 0
  const legacyAccountsCount = data?.legacyAccounts ?? 0
  const pendingInvitesCount = data?.pendingInvites ?? 0
  const pendingRequestsCount = data?.pendingRequests ?? 0
  const unsyncedRecordsCount = data?.unsyncedRecords ?? 0
  const warningCount = data?.warningCount ?? 0
  const checkedInStudents = data?.checkedInStudents ?? 0
  const latencyMs = data?.latencyMs ?? 0
  const liveSessions = data?.liveSessions ?? []
  const slotTimeline = data?.slotTimeline ?? []

  const todayFormatted = new Intl.DateTimeFormat("vi-VN", {
    weekday: "long",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date())

  const handleExportSessionReport = () => {
    const rows = [
      [
        "SessionID",
        "MaLop",
        "MonHoc",
        "Slot",
        "NgayHoc",
        "Phong",
        "GiangVien",
        "CoMat",
        "SiSo",
        "TrangThai",
      ],
      ...liveSessions.map((s) => [
        s.id,
        s.classCode,
        s.subjectName,
        s.slotCode,
        s.sessionDate,
        s.room,
        s.teacherName,
        String(s.presentCount),
        String(s.totalCount),
        s.statusText,
      ]),
    ]
    const csvContent =
      "data:text/csv;charset=utf-8,\uFEFF" + rows.map((r) => r.join(",")).join("\n")
    const encodedUri = encodeURI(csvContent)
    const link = document.createElement("a")
    link.setAttribute("href", encodedUri)
    link.setAttribute("download", `Bao_cao_ca_hoc_FAP_${new Date().toISOString().slice(0, 10)}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-[28px] font-extrabold text-slate-900 tracking-tight leading-tight">
            Tổng quan quản trị
          </h1>
          <p className="text-xs text-slate-500 mt-1 max-w-2xl leading-relaxed">
            Các chỉ số hoạt động và phiên điểm danh trực tiếp được đồng bộ thời gian thực từ Cloud Firestore &amp; FAP Core.
          </p>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2.5 shrink-0">
          <button
            onClick={handleExportSessionReport}
            disabled={loading}
            className="h-9 flex items-center gap-2 px-4 bg-[#C2410C] hover:bg-[#9A3412] text-white rounded-xl text-xs font-semibold shadow-xs transition-colors cursor-pointer disabled:opacity-50"
          >
            <Download size={14} />
            <span>Xuất báo cáo ca học</span>
          </button>
        </div>
      </div>

      {/* Error state if any */}
      {error && (
        <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl text-xs text-rose-700 flex items-center justify-between">
          <span>Không thể tải số liệu từ Firestore: {error}</span>
          <button onClick={handleReload} className="font-bold underline cursor-pointer">
            Thử lại
          </button>
        </div>
      )}

      {/* Row of 4 KPI Metric Cards */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1: Tài khoản hoạt động */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:border-slate-300 transition-all">
          <div>
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs text-slate-500 font-medium">Tài khoản hoạt động</span>
                <div className="flex items-baseline gap-2 mt-1">
                  <span className="text-3xl font-extrabold text-slate-900 tracking-tight">
                    {loading ? "…" : activeUsersCount}
                  </span>
                  <span className="text-xs text-slate-400 font-normal">
                    / {loading ? "…" : totalUsersCount} hồ sơ
                  </span>
                </div>
              </div>
              <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                <Users size={18} />
              </div>
            </div>
          </div>
          <div className="border-t border-slate-100 pt-3 mt-4 flex items-center justify-between text-xs">
            <span className="flex items-center gap-1.5 text-slate-500 text-[11px]">
              <i className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
              {adminCount} Admin quản trị hệ thống
            </span>
            <button
              onClick={() => onNavigate("accounts")}
              className="text-[11px] font-bold text-slate-700 hover:text-orange-600 cursor-pointer"
            >
              Chi tiết
            </button>
          </div>
        </div>

        {/* Card 2: Lớp đang quản lý */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:border-slate-300 transition-all">
          <div>
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs text-slate-500 font-medium">Lớp đang quản lý</span>
                <div className="flex items-baseline gap-1 mt-1">
                  <span className="text-3xl font-extrabold text-slate-900 tracking-tight">
                    {loading ? "…" : classesCount}
                  </span>
                  <span className="text-xs text-slate-400 font-normal">
                    {" "}
                    · {loading ? "…" : subjectsCount} môn học
                  </span>
                </div>
              </div>
              <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <BookOpen size={18} />
              </div>
            </div>
          </div>
          <div className="border-t border-slate-100 pt-3 mt-4 flex items-center justify-between text-xs">
            <span className="flex items-center gap-1 text-slate-500 text-[11px]">
              <span className="text-slate-400">Tổng số phiên:</span>
              <b className="text-slate-700">{loading ? "…" : totalSessionsCount} phiên</b>
            </span>
            <button
              onClick={() => onNavigate("academic")}
              className="text-[11px] font-bold text-slate-700 hover:text-orange-600 cursor-pointer"
            >
              Xem lớp
            </button>
          </div>
        </div>

        {/* Card 3: Phiên đang mở (ĐƯỢC HIGHLIGHT VIỀN CAM) */}
        <div className="bg-gradient-to-b from-orange-50/30 to-white border-2 border-[#EA580C] rounded-2xl p-5 shadow-xs flex flex-col justify-between relative hover:shadow-md transition-all">
          <div>
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs text-slate-700 font-semibold flex items-center gap-1.5">
                  Phiên đang mở
                  <span className="w-1.5 h-1.5 rounded-full bg-[#EA580C] animate-pulse" />
                </span>
                <div className="flex items-baseline gap-2 mt-1">
                  <span className="text-3xl font-extrabold text-[#C2410C] tracking-tight">
                    {loading ? "…" : openSessionsCount}
                  </span>
                  <span className="bg-orange-100 text-[#C2410C] text-[10px] font-bold px-2 py-0.5 rounded-full inline-flex items-center">
                    Live QR
                  </span>
                </div>
              </div>
              <div className="w-10 h-10 rounded-xl bg-orange-100 text-[#EA580C] flex items-center justify-center">
                <ClipboardCheck size={18} />
              </div>
            </div>
          </div>
          <div className="border-t border-orange-100 pt-3 mt-4 flex items-center justify-between text-xs">
            <span className="text-slate-600 font-medium text-[11px]">
              {loading ? "…" : checkedInStudents} lượt điểm danh đã ghi nhận
            </span>
            <button
              onClick={() => onNavigate("attendance")}
              className="text-[11px] font-extrabold text-[#EA580C] hover:underline cursor-pointer"
            >
              Giám sát
            </button>
          </div>
        </div>

        {/* Card 4: Tài khoản chưa liên kết */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:border-slate-300 transition-all">
          <div>
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs text-slate-500 font-medium">Tài khoản chưa liên kết</span>
                <div className="flex items-baseline gap-2 mt-1">
                  <span className="text-3xl font-extrabold text-slate-900 tracking-tight">
                    {loading ? "…" : legacyAccountsCount}
                  </span>
                  <span className="bg-rose-100 text-rose-700 text-[10px] font-bold px-2 py-0.5 rounded-full inline-flex items-center">
                    {legacyAccountsCount > 0 ? "Cần xử lý" : "Đã đồng bộ"}
                  </span>
                </div>
              </div>
              <div className="w-10 h-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center">
                <AlertTriangle size={18} />
              </div>
            </div>
          </div>
          <div className="border-t border-slate-100 pt-3 mt-4 flex items-center justify-between text-xs">
            <span className="text-slate-500 text-[11px]">
              {pendingInvitesCount} quyền chờ đăng nhập
            </span>
            <button
              onClick={() => onNavigate("accounts")}
              className="text-[11px] font-bold text-rose-600 hover:underline cursor-pointer flex items-center gap-0.5"
            >
              Xử lý <ArrowRight size={11} />
            </button>
          </div>
        </div>
      </section>

      {/* Section: Công việc quản trị */}
      <section className="bg-white border border-slate-200/80 rounded-2xl p-5 sm:p-6 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-4 mb-2 gap-2 border-b border-slate-100">
          <div>
            <h2 className="text-base font-bold text-slate-900">Công việc quản trị</h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Đi nhanh tới khu vực cần kiểm tra và xử lý dữ liệu học vụ từ Firestore
            </p>
          </div>
          <span className="text-xs text-slate-400 font-medium">
            Sắp xếp theo: <b className="text-slate-600 font-semibold">Mức độ ưu tiên</b>
          </span>
        </div>

        <div className="divide-y divide-slate-100">
          {/* Row 1: Tài khoản và quyền truy cập */}
          <div className="py-3.5 flex flex-col md:flex-row md:items-center justify-between gap-3 hover:bg-slate-50/60 rounded-xl px-2.5 -mx-2.5 transition-colors">
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0 mt-0.5">
                <Users size={17} />
              </div>
              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-xs font-bold text-slate-800">Tài khoản và quyền truy cập</span>
                  <span className="bg-blue-50 text-blue-700 border border-blue-200 text-[10px] font-bold px-2 py-0.5 rounded-full">
                    {loading ? "…" : `${pendingInvitesCount} lời mời chờ duyệt`}
                  </span>
                </div>
                <p className="text-[11.5px] text-slate-500 mt-0.5">
                  Cấp quyền giảng viên, khóa tài khoản tạm ngừng học và liên kết dữ liệu hồ sơ cũ ({legacyAccountsCount} hồ sơ)
                </p>
              </div>
            </div>
            <div className="flex items-center justify-between md:justify-end gap-6 shrink-0 pl-12 md:pl-0">
              <span className="text-xs text-slate-400">
                Tổng: <b className="text-slate-600 font-medium">{totalUsersCount} tài khoản</b>
              </span>
              <button
                onClick={() => onNavigate("accounts")}
                className="text-xs font-bold text-slate-700 hover:text-orange-600 flex items-center gap-1 cursor-pointer"
              >
                <span>Đi tới</span>
                <ArrowRight size={13} />
              </button>
            </div>
          </div>

          {/* Row 2: Phiên và bản ghi điểm danh */}
          <div className="py-3.5 flex flex-col md:flex-row md:items-center justify-between gap-3 hover:bg-slate-50/60 rounded-xl px-2.5 -mx-2.5 transition-colors">
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-orange-50 text-orange-600 flex items-center justify-center shrink-0 mt-0.5">
                <ClipboardCheck size={17} />
              </div>
              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-xs font-bold text-slate-800">Phiên và bản ghi điểm danh</span>
                  <span className="bg-orange-50 text-orange-700 border border-orange-200 text-[10px] font-bold px-2 py-0.5 rounded-full">
                    {loading ? "…" : `${unsyncedRecordsCount} bản ghi chưa đồng bộ FAP`}
                  </span>
                </div>
                <p className="text-[11.5px] text-slate-500 mt-0.5">
                  Theo dõi {openSessionsCount} phiên đang mở và {pendingRequestsCount} đơn yêu cầu điểm danh bù từ sinh viên/giảng viên
                </p>
              </div>
            </div>
            <div className="flex items-center justify-between md:justify-end gap-6 shrink-0 pl-12 md:pl-0">
              <span className="text-xs text-slate-500 font-semibold">
                {openSessionsCount} phiên mở
              </span>
              <button
                onClick={() => onNavigate("attendance")}
                className="text-xs font-bold text-slate-700 hover:text-orange-600 flex items-center gap-1 cursor-pointer"
              >
                <span>Đi tới</span>
                <ArrowRight size={13} />
              </button>
            </div>
          </div>

          {/* Row 3: Dữ liệu học vụ & Thời khóa biểu */}
          <div className="py-3.5 flex flex-col md:flex-row md:items-center justify-between gap-3 hover:bg-slate-50/60 rounded-xl px-2.5 -mx-2.5 transition-colors">
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0 mt-0.5">
                <BookOpen size={17} />
              </div>
              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-xs font-bold text-slate-800">Dữ liệu học vụ &amp; Thời khóa biểu</span>
                  <span className="bg-emerald-50 text-emerald-700 border border-emerald-200 text-[10px] font-bold px-2 py-0.5 rounded-full">
                    {classesCount} lớp · {subjectsCount} môn
                  </span>
                </div>
                <p className="text-[11.5px] text-slate-500 mt-0.5">
                  Xem lớp, môn học, phân công giảng viên và khung giờ các ca học đang áp dụng trên Firestore
                </p>
              </div>
            </div>
            <div className="flex items-center justify-between md:justify-end gap-6 shrink-0 pl-12 md:pl-0">
              <span className="text-xs text-slate-400">
                Realtime Firestore
              </span>
              <button
                onClick={() => onNavigate("academic")}
                className="text-xs font-bold text-slate-700 hover:text-orange-600 flex items-center gap-1 cursor-pointer"
              >
                <span>Đi tới</span>
                <ArrowRight size={13} />
              </button>
            </div>
          </div>

          {/* Row 4: Nhật ký hệ thống & Cảnh báo gian lận */}
          <div className="py-3.5 flex flex-col md:flex-row md:items-center justify-between gap-3 hover:bg-slate-50/60 rounded-xl px-2.5 -mx-2.5 transition-colors">
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center shrink-0 mt-0.5">
                <ShieldAlert size={17} />
              </div>
              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-xs font-bold text-slate-800">Nhật ký hệ thống &amp; Cảnh báo mạng</span>
                  <span className="bg-rose-50 text-rose-700 border border-rose-200 text-[10px] font-bold px-2 py-0.5 rounded-full">
                    {loading ? "…" : `${warningCount} phát hiện`}
                  </span>
                </div>
                <p className="text-[11.5px] text-slate-500 mt-0.5">
                  Giám sát phát hiện sai lệch địa chỉ IP hoặc bản ghi điểm danh bất thường trong các phiên học
                </p>
              </div>
            </div>
            <div className="flex items-center justify-between md:justify-end gap-6 shrink-0 pl-12 md:pl-0">
              <span className="text-xs text-rose-600 font-bold">
                {warningCount} lượt cảnh báo
              </span>
              <button
                onClick={() => onNavigate("attendance")}
                className="text-xs font-bold text-slate-700 hover:text-orange-600 flex items-center gap-1 cursor-pointer"
              >
                <span>Đi tới</span>
                <ArrowRight size={13} />
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Two-Column Lower Grid (Slot Timeline & Phiên trực tiếp) */}
      <section className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column: Giám sát ca học trong ngày (Slot Timeline) */}
        <div className="lg:col-span-8 bg-white border border-slate-200/80 rounded-2xl p-5 sm:p-6 shadow-xs flex flex-col justify-between">
          <div>
            <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-4 mb-4 gap-2 border-b border-slate-100">
              <div>
                <h2 className="text-base font-bold text-slate-900">Giám sát ca học (Slot Timeline)</h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Tỷ lệ hiện diện và phân bổ lớp học qua các khung giờ chuẩn từ Firestore
                </p>
              </div>
              <span className="bg-emerald-50 text-emerald-700 text-[11px] font-semibold px-2.5 py-1 rounded-full border border-emerald-200 self-start sm:self-auto capitalize">
                {todayFormatted}
              </span>
            </div>

            {/* Real Slot Timeline Cards from Firestore */}
            {slotTimeline.length === 0 ? (
              <div className="py-12 text-center text-xs text-slate-400">
                {loading ? "Đang tải khung giờ từ Firestore..." : "Chưa có dữ liệu khung giờ (slots) trên Firestore."}
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {slotTimeline.map((slot) => {
                  const isLive = slot.status === "live"
                  const isCompleted = slot.status === "completed"
                  const rateDisplay = slot.attendanceRate !== null ? `${slot.attendanceRate}%` : "--%"
                  const progressWidth = slot.attendanceRate !== null ? `${Math.min(100, slot.attendanceRate)}%` : "0%"

                  return (
                    <div
                      key={slot.slotCode}
                      className={
                        isLive
                          ? "bg-orange-50/25 border-2 border-[#EA580C] rounded-xl p-3.5 flex flex-col justify-between shadow-2xs"
                          : "bg-slate-50/70 border border-slate-200/70 rounded-xl p-3.5 flex flex-col justify-between"
                      }
                    >
                      <div>
                        <div className="flex items-center justify-between text-xs mb-1">
                          <span className={`font-bold ${isLive ? "text-[#EA580C]" : "text-slate-800"}`}>
                            {slot.label}
                          </span>
                          {isLive ? (
                            <span className="text-[10px] font-bold text-[#EA580C] bg-orange-100 px-1.5 py-0.5 rounded flex items-center gap-1">
                              <i className="w-1.5 h-1.5 rounded-full bg-[#EA580C] animate-pulse" /> Đang mở
                            </span>
                          ) : isCompleted ? (
                            <span className="text-[10px] font-bold text-blue-700 bg-blue-50 px-1.5 py-0.5 rounded flex items-center gap-1">
                              <Check size={10} /> Đã học
                            </span>
                          ) : (
                            <span className="text-[10px] text-slate-400 font-medium">{slot.period}</span>
                          )}
                        </div>
                        <span
                          className={`text-[10px] block mb-2 ${
                            isLive ? "text-orange-600/80 font-medium" : "text-slate-400"
                          }`}
                        >
                          {slot.timeRange}
                        </span>
                        <div
                          className={`text-2xl font-extrabold ${
                            isLive
                              ? "text-[#C2410C]"
                              : slot.attendanceRate !== null
                                ? "text-slate-900"
                                : "text-slate-300"
                          }`}
                        >
                          {rateDisplay}
                        </div>
                        <div
                          className={`w-full h-1.5 rounded-full overflow-hidden mt-1.5 ${
                            isLive ? "bg-orange-200" : "bg-slate-200"
                          }`}
                        >
                          {slot.attendanceRate !== null && (
                            <div
                              className={`h-full rounded-full ${isLive ? "bg-[#EA580C]" : "bg-blue-600"}`}
                              style={{ width: progressWidth }}
                            />
                          )}
                        </div>
                      </div>
                      <span
                        className={`text-[10px] mt-3 block text-right ${
                          isLive ? "text-orange-700 font-bold" : "text-slate-400"
                        }`}
                      >
                        {slot.classCount} lớp · {slot.sessionCount} phiên
                      </span>
                    </div>
                  )
                })}
              </div>
            )}
          </div>

          {/* Bottom info of Slot Timeline */}
          <div className="border-t border-slate-100 pt-3 mt-4 flex flex-col sm:flex-row sm:items-center justify-between text-xs text-slate-500 gap-2">
            <span className="flex items-center gap-1.5 text-[11px] text-slate-400">
              <Info size={14} className="text-slate-400 shrink-0" />
              Số liệu tổng hợp trực tiếp từ các bảng slots, classes, sessions và attendance_records.
            </span>
            <button
              onClick={() => onNavigate("academic")}
              className="text-[11px] font-bold text-slate-700 hover:text-orange-600 cursor-pointer self-end sm:self-auto"
            >
              Chi tiết ca học
            </button>
          </div>
        </div>

        {/* Right Column: Phiên trực tiếp tiêu biểu */}
        <div className="lg:col-span-4 bg-white border border-slate-200/80 rounded-2xl p-5 sm:p-6 shadow-xs flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-4 mb-4 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse" />
                <h2 className="text-base font-bold text-slate-900">Phiên điểm danh gần nhất</h2>
              </div>
              <span className="text-xs text-slate-400 font-semibold">{openSessionsCount} ca mở</span>
            </div>

            {/* Live session cards list from Firestore */}
            {liveSessions.length === 0 ? (
              <div className="py-12 text-center text-xs text-slate-400">
                {loading ? "Đang tải phiên điểm danh..." : "Chưa có phiên điểm danh nào trên Firestore."}
              </div>
            ) : (
              <div className="space-y-3">
                {liveSessions.map((session) => {
                  const pct =
                    session.totalCount > 0
                      ? Math.min(100, Math.round((session.presentCount / session.totalCount) * 100))
                      : 0
                  const isFull = session.statusType === "full"
                  const isLive = session.statusType === "live"

                  return (
                    <div
                      key={session.id}
                      onClick={() => onNavigate("attendance")}
                      className={`p-3 bg-slate-50 border border-slate-200/70 rounded-xl transition-colors cursor-pointer ${
                        isFull ? "hover:border-emerald-200" : "hover:border-orange-200"
                      }`}
                    >
                      <div className="flex items-start justify-between">
                        <div>
                          <b className="text-xs font-bold text-slate-900 block">
                            {session.classCode}
                            {session.subjectName ? ` - ${session.subjectName}` : ""}
                          </b>
                          <span className="text-[11px] text-slate-500">
                            Phòng {session.room} · Slot {session.slotCode || "—"} · {session.sessionDate}
                          </span>
                        </div>
                        <span
                          className={`text-xs font-extrabold ${
                            isFull ? "text-emerald-600" : "text-slate-800"
                          }`}
                        >
                          {session.presentCount}/{session.totalCount}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-[11px] mt-2">
                        <span className="text-slate-500">GV: {session.teacherName}</span>
                        {isFull ? (
                          <span className="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-1.5 py-0.5 rounded flex items-center gap-1">
                            <Check size={10} /> {session.statusText}
                          </span>
                        ) : isLive ? (
                          <span className="text-[10px] font-bold text-orange-600 bg-orange-100/80 px-1.5 py-0.5 rounded">
                            {session.statusText}
                          </span>
                        ) : (
                          <span className="text-[10px] font-semibold text-slate-600 bg-slate-200/70 px-1.5 py-0.5 rounded">
                            {session.statusText}
                          </span>
                        )}
                      </div>
                      <div className="w-full bg-slate-200 h-1 rounded-full overflow-hidden mt-2">
                        <div
                          className={`h-full rounded-full ${
                            isFull ? "bg-emerald-500" : isLive ? "bg-orange-500" : "bg-slate-500"
                          }`}
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>

          {/* Bottom Bar of Live Sessions */}
          <div className="border-t border-slate-100 pt-3 mt-4 flex items-center justify-between text-xs text-slate-500">
            <span className="text-[11px] text-slate-400">Độ trễ phản hồi: {latencyMs}ms</span>
            <button
              onClick={() => onNavigate("attendance")}
              className="text-[11px] font-bold text-orange-600 hover:underline flex items-center gap-1 cursor-pointer"
            >
              <span>Giám sát toàn bộ phiên</span>
              <ExternalLink size={12} />
            </button>
          </div>
        </div>
      </section>

      {/* Infrastructure & Cloud Status Banner */}
      <section className="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center shrink-0">
            <Server size={19} />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-slate-900">Cơ sở hạ tầng &amp; Máy chủ FAP Cloud</span>
              <span className="bg-emerald-50 text-emerald-700 border border-emerald-200 text-[10px] font-bold px-2 py-0.5 rounded-full">
                {error ? "Gián đoạn" : "Ổn định"}
              </span>
            </div>
            <p className="text-[11px] text-slate-500 mt-0.5">
              Cloud Firestore Latency: <b className="text-slate-700">{latencyMs}ms</b> · Tổng phiên:{" "}
              <b className="text-slate-700">{totalSessionsCount}</b> · FPT Edu OAuth2 Gateway:{" "}
              <b className="text-emerald-600">Healthy</b>
            </p>
          </div>
        </div>
        <button
          onClick={() => onNavigate("settings")}
          className="text-xs font-semibold px-3 py-1.5 bg-slate-50 hover:bg-slate-100 text-slate-700 rounded-xl border border-slate-200 transition-colors cursor-pointer self-start md:self-auto shrink-0"
        >
          Cấu hình hệ thống
        </button>
      </section>

      {/* Footer */}
      <footer className="pt-2 pb-6 border-t border-slate-200/60 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-[11px] text-slate-400">
        <p>© 2026 FPT University - Academic Portal (FAP Check-in System). Phát triển bởi Ban Đào tạo &amp; Khối Công nghệ</p>
        <div className="flex items-center gap-4">
          <button onClick={() => onNavigate("settings")} className="hover:text-slate-600 underline cursor-pointer">
            Chính sách bảo mật
          </button>
          <button onClick={() => onNavigate("reports")} className="hover:text-slate-600 underline cursor-pointer">
            Báo cáo chuyên cần
          </button>
          <span className="font-mono text-slate-300">HL-CAMPUS-DC01</span>
        </div>
      </footer>
    </div>
  )
}
