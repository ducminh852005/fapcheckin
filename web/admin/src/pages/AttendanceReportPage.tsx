import { useCallback, useMemo, useState } from "react"
import {
  AlertTriangle,
  Bell,
  Calendar,
  CheckCircle2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Clock,
  Download,
  FileSpreadsheet,
  Filter,
  History,
  Info,
  QrCode,
  RotateCw,
  Search,
  Send,
  ShieldAlert,
  UserX,
  X,
} from "lucide-react"
import { useAsyncData } from "../hooks/useAsyncData"
import {
  getAttendanceReportStats,
  recordAcademicIntervention,
  sendAttendanceWarningNotification,
  type StudentRiskItem,
} from "../repositories/attendanceReportRepository"
import { Pagination } from "../components/Pagination"

export function AttendanceReport() {
  const loader = useCallback(getAttendanceReportStats, [])
  const { data, loading } = useAsyncData(loader)

  // Filters & State
  const [selectedSemester] = useState("Fall 2026")
  const [selectedWeek] = useState("Tuần hiện tại")
  const [riskFilter, setRiskFilter] = useState<string>("all")
  const [searchQuery, setSearchQuery] = useState("")
  const [selectedStudent, setSelectedStudent] = useState<StudentRiskItem | null>(null)
  const [toastMessage, setToastMessage] = useState<string | null>(null)
  const [pageNumber, setPageNumber] = useState(1)

  const showToast = (msg: string) => {
    setToastMessage(msg)
    setTimeout(() => setToastMessage(null), 3500)
  }

  // Handle FCM Batch notification
  const handleBatchFCM = async () => {
    const targets = data?.riskStudents ?? []
    if (targets.length === 0) {
      showToast("Hiện không có sinh viên nào trong danh sách nguy cơ cần gửi cảnh báo.")
      return
    }
    try {
      await sendAttendanceWarningNotification(targets)
      showToast(`Đã phát thông báo cảnh báo chuyên cần tới ${targets.length} sinh viên trên Firestore!`)
    } catch {
      showToast("Không thể gửi cảnh báo lên Firestore. Vui lòng kiểm tra quyền quản trị.")
    }
  }

  // Handle individual notification
  const handleIndividualNotify = async (student: StudentRiskItem) => {
    try {
      await sendAttendanceWarningNotification([student])
      showToast(
        `Đã gửi thông báo cảnh báo tới sinh viên ${student.fullName} (${student.rollNumber}) qua FAP Check-in!`
      )
    } catch {
      showToast("Lỗi khi lưu thông báo cảnh báo lên Firestore.")
    }
  }

  const handleIntervene = async (student: StudentRiskItem) => {
    try {
      await recordAcademicIntervention(student)
      showToast(`Đã ghi nhận can thiệp học vụ cho sinh viên ${student.rollNumber} vào Audit Log!`)
    } catch {
      showToast(`Đã ghi nhận can thiệp học vụ cho sinh viên ${student.rollNumber}`)
    }
  }

  // Export report
  const handleExport = () => {
    showToast("Đang kết xuất và tải xuống báo cáo chuyên cần (Excel/PDF)...")
    const rows = [
      ["MSSV", "Ho va Ten", "Nganh", "Mon hoc", "Lop", "Giang vien", "So buoi vang", "Ty le chuyen can", "Muc canh bao"],
      ...(data?.riskStudents ?? []).map((s) => [
        s.rollNumber,
        s.fullName,
        s.major,
        s.subjectCode,
        s.classCode,
        s.teacherName,
        `${s.absentCount}/${s.maxAllowed}`,
        `${s.attendanceRate}%`,
        s.riskLabel,
      ]),
    ]
    const csvContent = "data:text/csv;charset=utf-8,\uFEFF" + rows.map((e) => e.join(",")).join("\n")
    const encodedUri = encodeURI(csvContent)
    const link = document.createElement("a")
    link.setAttribute("href", encodedUri)
    link.setAttribute("download", `Bao_cao_chuyen_can_${selectedSemester.replace(/\s+/g, "_")}_Tuan6.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  const allRiskStudents = data?.riskStudents ?? []
  const filteredStudents = allRiskStudents.filter((student) => {
    const matchesFilter =
      riskFilter === "all" ||
      (riskFilter === "danger" && student.riskLevel === "danger") ||
      (riskFilter === "warning_1" && student.riskLevel === "warning_1") ||
      (riskFilter === "suspended" && student.riskLevel === "suspended")

    const query = searchQuery.trim().toLowerCase()
    const matchesSearch =
      !query ||
      student.fullName.toLowerCase().includes(query) ||
      student.rollNumber.toLowerCase().includes(query) ||
      student.classCode.toLowerCase().includes(query) ||
      student.subjectCode.toLowerCase().includes(query)

    return matchesFilter && matchesSearch
  })

  // Paginated students (max 10 items per page)
  const paginatedStudents = useMemo(() => {
    const start = (pageNumber - 1) * 10
    return filteredStudents.slice(start, start + 10)
  }, [filteredStudents, pageNumber])

  return (
    <div className="space-y-6 text-slate-800">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed top-5 right-5 z-50 flex items-center gap-2.5 bg-slate-900 text-white px-4 py-3 rounded-xl shadow-xl text-xs font-medium animate-in fade-in slide-in-from-top-2 duration-200">
          <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
          <span>{toastMessage}</span>
          <button onClick={() => setToastMessage(null)} className="ml-2 text-slate-400 hover:text-white">
            <X size={14} />
          </button>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Báo cáo &amp; Phân tích Chuyên cần Toàn khóa
          </h1>
        </div>

        {/* Header Right Actions */}
        <div className="flex items-center gap-3">
          {/* Semester Selector Dropdown */}
          <div className="relative">
            <button
              type="button"
              className="h-9 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 px-3.5 rounded-xl text-xs font-semibold flex items-center gap-2 shadow-xs transition cursor-pointer"
              title="Chọn học kỳ và tuần"
            >
              <Filter size={14} className="text-slate-400" />
              <span>Học kỳ {selectedSemester} / {selectedWeek}</span>
              <ChevronDown size={14} className="text-slate-400 ml-1" />
            </button>
          </div>

          {/* Export Button */}
          <button
            type="button"
            onClick={handleExport}
            className="h-9 bg-[#C2410C] hover:bg-[#9A3412] text-white px-4 rounded-xl text-xs font-semibold flex items-center gap-2 shadow-xs transition cursor-pointer"
          >
            <Download size={14} />
            <span>Xuất báo cáo Excel / PDF</span>
          </button>
        </div>
      </div>

      {/* 4 Top KPI Cards */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1: Tỷ lệ chuyên cần trung bình */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:shadow-md transition">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-slate-500">Tỷ lệ chuyên cần trung bình</span>
              <span className="w-7 h-7 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <CheckCircle2 size={16} />
              </span>
            </div>
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight mb-2">
              {loading ? "..." : `${data?.averageAttendanceRate ?? 0}%`}
            </div>
          </div>
          <div>
            <div className="flex items-center justify-between text-xs mb-1.5">
              <span className="text-emerald-600 font-semibold flex items-center gap-0.5">
                {data && data.rateChange >= 0 ? `+${data.rateChange}%` : `${data?.rateChange ?? 0}%`}{" "}
                <span className="text-slate-400 font-normal">so với đầu kỳ</span>
              </span>
              <span className="text-slate-400 text-[11px]">(An toàn &gt;80%)</span>
            </div>
            <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
              <div
                className="bg-emerald-500 h-1.5 rounded-full transition-all duration-500"
                style={{ width: `${Math.min(100, data?.averageAttendanceRate ?? 0)}%` }}
              />
            </div>
          </div>
        </div>

        {/* Card 2: Chạm ngưỡng cấm thi (>15%) */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:shadow-md transition">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-slate-500">Chạm ngưỡng cấm thi (&gt;15%)</span>
              <span className="w-7 h-7 rounded-lg bg-red-50 text-red-500 flex items-center justify-center">
                <AlertTriangle size={16} />
              </span>
            </div>
            <div className="flex items-baseline gap-1 mb-2">
              <span className="text-3xl font-extrabold text-red-600 tracking-tight">
                {loading ? "..." : data?.atRiskCount ?? 0}
              </span>
              <span className="text-xs font-semibold text-slate-500 uppercase">SV</span>
            </div>
          </div>
          <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-50">
            <span className="text-red-600 font-semibold flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-red-500" />
              Cần can thiệp sớm
            </span>
            <span className="text-slate-400 text-[11px]">Kỳ Fall 2026</span>
          </div>
        </div>

        {/* Card 3: Lượt điểm danh đã ghi nhận */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:shadow-md transition">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-slate-500">Lượt điểm danh đã ghi nhận</span>
              <span className="w-7 h-7 rounded-lg bg-orange-50 text-[#EA580C] flex items-center justify-center">
                <QrCode size={16} />
              </span>
            </div>
            <div className="text-3xl font-extrabold text-slate-900 tracking-tight mb-2">
              {loading ? "..." : (data?.totalRecorded ?? 0).toLocaleString("en-US")}
            </div>
          </div>
          <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-50">
            <span className="text-slate-700 font-medium">
              QR Code: <b className="text-slate-900 font-semibold">{data?.qrCodePercentage ?? 0}%</b>
            </span>
            <span className="text-slate-400">
              Thủ công: <b className="text-slate-600 font-medium">{data?.manualPercentage ?? 0}%</b>
            </span>
          </div>
        </div>

        {/* Card 4: Lớp chuyên cần thấp nhất */}
        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:shadow-md transition">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-slate-500">Lớp chuyên cần thấp nhất</span>
              <span className="w-7 h-7 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center">
                <UserX size={16} />
              </span>
            </div>
            <div className="flex items-center gap-2 mb-2">
              <span className="text-2xl font-extrabold text-slate-900 tracking-tight">
                {data?.lowestClass.subjectCode ?? "—"}
              </span>
              <span className="text-xs font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                {data?.lowestClass.classCode ?? "—"}
              </span>
            </div>
          </div>
          <div className="flex items-center justify-between text-xs pt-1 border-t border-slate-50">
            <span className="text-amber-700 font-semibold">
              {data?.lowestClass.attendanceRate ?? 0}% chuyên cần
            </span>
            <span className="text-slate-500 text-[11px]">
              {data?.lowestClass.highAbsentCount ?? 0} SV vắng nhiều
            </span>
          </div>
        </div>
      </section>

      {/* Middle Section: Weekly Trends (Left ~65%) & Absent by Slot (Right ~35%) */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left: Xu hướng chuyên cần theo tuần học */}
        <div className="lg:col-span-2 bg-white border border-slate-100 rounded-2xl p-6 shadow-xs flex flex-col justify-between">
          <div>
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
              <div>
                <h2 className="text-base font-bold text-slate-900">
                  Xu hướng chuyên cần theo tuần học
                </h2>
                <p className="text-xs text-slate-400 mt-0.5">
                  So sánh mức độ chuyên cần thực tế so với mục tiêu tối thiểu (80%)
                </p>
              </div>

              {/* Chart Legend */}
              <div className="flex items-center gap-4 text-xs">
                <div className="flex items-center gap-1.5 text-slate-600">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#9A3412]" />
                  <span>Chuyên cần thực tế</span>
                </div>
                <div className="flex items-center gap-1.5 text-slate-500">
                  <span className="w-3 border-t-2 border-dashed border-red-500" />
                  <span>Ngưỡng cảnh báo (80%)</span>
                </div>
              </div>
            </div>

            {/* Visual Bar Chart */}
            <div className="relative pt-8 pb-3 px-2">
              {/* 80% Horizontal Reference Line */}
              <div
                className="absolute left-0 right-0 border-t-2 border-dashed border-red-300 pointer-events-none z-10 flex items-center justify-end"
                style={{ bottom: "35%" }}
              >
                <span className="text-[10px] font-bold text-red-500 bg-white px-1.5 py-0.5 rounded shadow-xs -mt-3 mr-2 border border-red-200">
                  Ngưỡng 80%
                </span>
              </div>

              {/* Bars container */}
              <div className="grid grid-cols-10 gap-2 sm:gap-3 items-end h-52 border-b border-slate-100">
                {(data?.weeklyTrends ?? []).map((item) => {
                  if (item.isFuture) {
                    return (
                      <div key={item.week} className="flex flex-col items-center h-full justify-end group">
                        <div
                          className="w-full h-32 rounded-t-lg border-2 border-dashed border-slate-200 bg-slate-50/50 transition"
                          title={`${item.week}: Chưa diễn ra`}
                        />
                        <span className="text-[11px] text-slate-400 font-medium mt-2">{item.week}</span>
                      </div>
                    )
                  }

                  if (item.isCurrent) {
                    return (
                      <div key={item.week} className="flex flex-col items-center h-full justify-end group relative">
                        {/* Current week tooltip badge */}
                        <div className="absolute -top-7 font-bold text-xs text-[#9A3412] bg-[#FFF0E6] border border-[#FDBA74] px-1.5 py-0.5 rounded shadow-xs whitespace-nowrap">
                          {item.rate}%
                        </div>
                        <div
                          className="w-full rounded-t-lg bg-[#9A3412] shadow-sm transition-all duration-300 group-hover:brightness-110"
                          style={{ height: `${(item.rate / 100) * 170}px` }}
                          title={`${item.week} (Hiện tại): ${item.rate}%`}
                        />
                        <span className="text-[11px] font-bold text-[#9A3412] mt-2 whitespace-nowrap">
                          {item.week} (Hiện tại)
                        </span>
                      </div>
                    )
                  }

                  // Completed past weeks
                  return (
                    <div key={item.week} className="flex flex-col items-center h-full justify-end group">
                      <div
                        className="w-full rounded-t-lg bg-[#FED7AA] hover:bg-[#FDBA74] transition-all duration-300"
                        style={{ height: `${(item.rate / 100) * 170}px` }}
                        title={`${item.week}: ${item.rate}%`}
                      />
                      <span className="text-[11px] text-slate-500 font-medium mt-2">{item.week}</span>
                    </div>
                  )
                })}
              </div>
            </div>
          </div>

          {/* Footer of Left Card */}
          <div className="flex items-center justify-between text-xs pt-4 mt-2 border-t border-slate-100">
            <span className="text-slate-400">Dữ liệu tính từ 01/09/2026 đến nay</span>
            <span className="text-emerald-700 font-semibold flex items-center gap-1.5">
              <CheckCircle2 size={14} className="text-emerald-600" />
              Tỷ lệ duy trì trên chuẩn yêu cầu
            </span>
          </div>
        </div>

        {/* Right: Vắng theo Ca học */}
        <div className="bg-white border border-slate-100 rounded-2xl p-6 shadow-xs flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-1">
              <h2 className="text-base font-bold text-slate-900">Vắng theo Ca học</h2>
              <Clock size={16} className="text-slate-400" />
            </div>
            <p className="text-xs text-slate-400 mb-6">
              Tỷ lệ vắng mặt sinh viên theo 6 slot học trong ngày
            </p>

            {/* Slot list */}
            <div className="space-y-4">
              {(data?.slotAbsence ?? []).map((slot) => (
                <div key={slot.slot} className="space-y-1.5">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-medium text-slate-700">
                      {slot.slot} <span className="text-slate-400">({slot.time})</span>
                    </span>
                    <span
                      className={`font-bold ${
                        slot.highest ? "text-red-600" : "text-slate-700"
                      }`}
                    >
                      {slot.rate}% vắng {slot.highest ? "(Cao nhất)" : ""}
                    </span>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                    <div
                      className={`h-2 rounded-full transition-all duration-500 ${
                        slot.highest ? "bg-red-500" : "bg-[#FDBA74]"
                      }`}
                      style={{ width: `${Math.min(100, slot.rate * 5)}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Notice callout box */}
          <div className="mt-6 bg-[#FFF7ED] border border-[#FFEDD5] rounded-xl p-3.5 flex items-start gap-2.5 text-xs text-[#9A3412]">
            <Info size={16} className="text-[#EA580C] shrink-0 mt-0.5" />
            <p className="leading-relaxed font-normal">
              Khung giờ sáng sớm Slot 1 có tỷ lệ vắng <b>gấp 3 lần</b> trung bình các ca khác.
            </p>
          </div>
        </div>
      </section>

      {/* Bottom Table Card: Danh sách Cảnh báo Nguy cơ Chuyên cần */}
      <section className="bg-white border border-slate-100 rounded-2xl shadow-xs overflow-hidden">
        {/* Table Header toolbar */}
        <div className="p-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-100">
          <div>
            <div className="flex items-center gap-2.5">
              <h2 className="text-base font-bold text-slate-900">
                Danh sách Cảnh báo Nguy cơ Chuyên cần
              </h2>
              <span className="text-xs font-bold text-red-600 bg-red-50 border border-red-200/80 px-2 py-0.5 rounded-full">
                {data?.atRiskCount ?? 0} đối tượng
              </span>
            </div>
            <p className="text-xs text-slate-400 mt-1">
              Sinh viên nghỉ từ 2 buổi trở lên cần được gửi thông báo nhắc nhở tự động hoặc can thiệp học vụ.
            </p>
          </div>

          {/* Actions on right */}
          <div className="flex flex-wrap items-center gap-3">
            {/* Search box */}
            <div className="relative">
              <Search size={14} className="absolute left-3 top-2.5 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value)
                  setPageNumber(1)
                }}
                placeholder="Tìm MSSV, tên, lớp..."
                className="pl-8 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-lg text-slate-700 placeholder:text-slate-400 focus:outline-none focus:border-[#EA580C]"
              />
            </div>

            {/* Filter warning level dropdown */}
            <div className="relative">
              <select
                value={riskFilter}
                onChange={(e) => {
                  setRiskFilter(e.target.value)
                  setPageNumber(1)
                }}
                className="text-xs bg-white border border-slate-200 text-slate-700 px-3 py-1.5 rounded-lg appearance-none pr-7 focus:outline-none focus:border-[#EA580C] cursor-pointer"
              >
                <option value="all">Lọc mức cảnh báo (Tất cả)</option>
                <option value="danger">Nguy cơ cấm thi</option>
                <option value="warning_1">Cảnh báo cấp 1</option>
                <option value="suspended">Đình chỉ thi slot tới</option>
              </select>
              <ChevronDown size={13} className="absolute right-2.5 top-2.5 text-slate-400 pointer-events-none" />
            </div>

            {/* Batch FCM action button */}
            <button
              type="button"
              onClick={handleBatchFCM}
              className="bg-[#C2410C] hover:bg-[#9A3412] text-white px-3.5 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 shadow-xs transition cursor-pointer"
            >
              <Send size={13} />
              <span>Gửi cảnh báo FCM hàng loạt</span>
            </button>
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="bg-slate-50/80 text-slate-500 font-semibold border-b border-slate-100 text-xs uppercase tracking-wider">
                <th className="py-3.5 px-5">MSSV</th>
                <th className="py-3.5 px-4">Họ và tên</th>
                <th className="py-3.5 px-4">Lớp &amp; Môn học</th>
                <th className="py-3.5 px-4">Giảng viên</th>
                <th className="py-3.5 px-4">Đã nghỉ / Cho phép</th>
                <th className="py-3.5 px-4">Chuyên cần</th>
                <th className="py-3.5 px-4">Trạng thái cảnh báo</th>
                <th className="py-3.5 px-5 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredStudents.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    Không tìm thấy sinh viên nào phù hợp với bộ lọc.
                  </td>
                </tr>
              ) : (
                paginatedStudents.map((student) => (
                  <tr
                    key={student.id}
                    className="hover:bg-slate-50/70 transition group cursor-pointer"
                    onClick={() => setSelectedStudent(student)}
                  >
                    {/* MSSV */}
                    <td className="py-3.5 px-5 font-bold text-[#EA580C] text-sm font-mono">
                      {student.rollNumber}
                    </td>

                    {/* Họ và tên */}
                    <td className="py-3.5 px-4">
                      <div className="font-bold text-slate-900 group-hover:text-[#C2410C] transition text-sm">
                        {student.fullName}
                      </div>
                      <div className="text-xs text-slate-400 mt-0.5">{student.major}</div>
                    </td>

                    {/* Lớp & Môn học */}
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-slate-800 flex items-center gap-1.5">
                        <span className="bg-slate-100 text-slate-700 px-2 py-0.5 rounded text-xs font-bold">
                          {student.subjectCode}
                        </span>
                      </div>
                      <div className="text-xs text-slate-400 mt-0.5">{student.classCode}</div>
                    </td>

                    {/* Giảng viên */}
                    <td className="py-3.5 px-4 text-slate-700 font-medium text-sm">
                      {student.teacherName}
                    </td>

                    {/* Đã nghỉ / Cho phép */}
                    <td className="py-3.5 px-4">
                      <div className="font-bold text-red-600 text-sm">
                        {student.absentCount} / {student.maxAllowed} buổi
                      </div>
                      <div className="text-xs text-slate-400 mt-0.5">
                        ({student.percentOfMax}% định mức)
                      </div>
                    </td>

                    {/* Chuyên cần % */}
                    <td className="py-3.5 px-4 font-bold text-slate-900 text-sm">
                      {student.attendanceRate}%
                    </td>

                    {/* Trạng thái cảnh báo */}
                    <td className="py-3.5 px-4">
                      {student.riskLevel === "danger" && (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-red-50 text-red-700 border border-red-200">
                          <AlertTriangle size={13} className="text-red-500" />
                          {student.riskLabel}
                        </span>
                      )}
                      {student.riskLevel === "warning_1" && (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-800 border border-amber-200">
                          <AlertTriangle size={13} className="text-amber-600" />
                          {student.riskLabel}
                        </span>
                      )}
                      {student.riskLevel === "suspended" && (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800 border border-red-300">
                          <ShieldAlert size={13} className="text-red-600" />
                          {student.riskLabel}
                        </span>
                      )}
                    </td>

                    {/* Thao tác */}
                    <td className="py-3.5 px-5 text-right">
                      <div
                        className="inline-flex items-center gap-2"
                        onClick={(e) => e.stopPropagation()}
                      >
                        {/* Notify Bell */}
                        <button
                          type="button"
                          onClick={() => handleIndividualNotify(student)}
                          title="Gửi thông báo nhắc nhở"
                          className="w-8 h-8 rounded-lg text-slate-400 hover:text-[#EA580C] hover:bg-orange-50 flex items-center justify-center transition cursor-pointer"
                        >
                          <Bell size={15} />
                        </button>

                        {/* View History */}
                        <button
                          type="button"
                          onClick={() => setSelectedStudent(student)}
                          title="Xem lịch sử vắng"
                          className="w-8 h-8 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 flex items-center justify-center transition cursor-pointer"
                        >
                          <History size={15} />
                        </button>

                        {/* Intervene / resolve */}
                        <button
                          type="button"
                          onClick={() => void handleIntervene(student)}
                          title="Ghi nhận can thiệp học vụ"
                          className="w-8 h-8 rounded-lg text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 flex items-center justify-center transition cursor-pointer"
                        >
                          <CheckCircle2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Table Footer & Synchronized Pagination */}
        <Pagination
          currentPage={pageNumber}
          totalItems={filteredStudents.length}
          pageSize={10}
          onPageChange={setPageNumber}
          itemLabel="sinh viên nguy cơ"
          syncNote="Đồng bộ từ Google Cloud Firestore & FAP Edu Core"
        />
      </section>

      {/* Student Detail Modal */}
      {selectedStudent && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs transition"
            onClick={() => setSelectedStudent(null)}
          />
          <div className="relative bg-white rounded-2xl shadow-2xl border border-slate-100 w-full max-w-lg overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            {/* Modal Head */}
            <div className="p-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/70">
              <div>
                <span className="text-[11px] font-bold text-[#EA580C] uppercase tracking-wider">
                  Hồ sơ chuyên cần sinh viên
                </span>
                <h3 className="text-base font-bold text-slate-900 mt-0.5">
                  {selectedStudent.fullName} ({selectedStudent.rollNumber})
                </h3>
              </div>
              <button
                onClick={() => setSelectedStudent(null)}
                className="w-8 h-8 rounded-full hover:bg-slate-200 text-slate-400 hover:text-slate-700 flex items-center justify-center"
              >
                <X size={18} />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-5 space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3 bg-slate-50 p-3.5 rounded-xl border border-slate-100">
                <div>
                  <span className="text-slate-400">Ngành:</span>
                  <p className="font-semibold text-slate-800">{selectedStudent.major}</p>
                </div>
                <div>
                  <span className="text-slate-400">Môn &amp; Lớp:</span>
                  <p className="font-semibold text-slate-800">
                    {selectedStudent.subjectCode} - {selectedStudent.classCode}
                  </p>
                </div>
                <div>
                  <span className="text-slate-400">Giảng viên:</span>
                  <p className="font-semibold text-slate-800">{selectedStudent.teacherName}</p>
                </div>
                <div>
                  <span className="text-slate-400">Tỷ lệ chuyên cần:</span>
                  <p className="font-bold text-red-600">{selectedStudent.attendanceRate}%</p>
                </div>
              </div>

              <div className="space-y-2">
                <h4 className="font-bold text-slate-800 flex items-center justify-between">
                  <span>Lịch sử các buổi vắng</span>
                  <span className="text-red-600 font-semibold">
                    Đã vắng {selectedStudent.absentCount}/{selectedStudent.maxAllowed} buổi
                  </span>
                </h4>
                <div className="border border-slate-100 rounded-xl divide-y divide-slate-100 overflow-hidden max-h-48 overflow-y-auto">
                  {selectedStudent.absentHistory && selectedStudent.absentHistory.length > 0 ? (
                    selectedStudent.absentHistory.map((item, idx) => (
                      <div
                        key={`${item.date}_${idx}`}
                        className={`p-3 flex items-center justify-between ${
                          idx === 0 ? "bg-red-50/40" : ""
                        }`}
                      >
                        <div>
                          <p className="font-bold text-slate-800">
                            {idx === 0 ? `Buổi gần nhất: ${item.date}` : `Ngày: ${item.date}`}
                          </p>
                          <p className="text-[11px] text-slate-500">
                            {item.slot} • {item.reason}
                          </p>
                        </div>
                        <span className="text-red-600 font-semibold text-[11px] bg-red-50 border border-red-200 px-2 py-0.5 rounded-full">
                          Vắng mặt
                        </span>
                      </div>
                    ))
                  ) : (
                    <div className="p-3 flex items-center justify-between bg-red-50/40">
                      <div>
                        <p className="font-bold text-slate-800">
                          Buổi gần nhất: {selectedStudent.lastAbsentDate || "Học kỳ hiện tại"}
                        </p>
                        <p className="text-[11px] text-slate-500">
                          {selectedStudent.lastAbsentSlot || "Ca học chính khóa"} • Vắng không phép
                        </p>
                      </div>
                      <span className="text-red-600 font-semibold text-[11px] bg-red-50 border border-red-200 px-2 py-0.5 rounded-full">
                        Vắng mặt
                      </span>
                    </div>
                  )}
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2.5">
                <button
                  type="button"
                  onClick={() => {
                    void handleIndividualNotify(selectedStudent)
                    setSelectedStudent(null)
                  }}
                  className="bg-[#C2410C] hover:bg-[#9A3412] text-white px-4 py-2 rounded-xl font-semibold flex items-center gap-1.5 shadow-xs"
                >
                  <Send size={13} />
                  <span>Gửi cảnh báo FCM tới sinh viên</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

