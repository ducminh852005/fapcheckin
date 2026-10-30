import { useCallback, useState } from "react"
import {
  AlertTriangle,
  ArrowRight,
  CheckCircle2,
  Clock,
  Database,
  ExternalLink,
  Flame,
  Globe,
  Info,
  Lock,
  Network,
  QrCode,
  RotateCcw,
  Save,
  Shield,
  ShieldAlert,
  ShieldCheck,
  SlidersHorizontal,
  Wifi,
  X,
} from "lucide-react"
import { useAsyncData } from "../hooks/useAsyncData"
import {
  DEFAULT_SETTINGS,
  getSystemSettings,
  saveSystemSettings,
  triggerFapSyncNow,
  type SystemSettings,
} from "../repositories/settingsRepository"

export function SystemSettingsPage({
  adminEmail = "admin.hac@fpt.edu.vn",
}: {
  adminEmail?: string
}) {
  const loader = useCallback(getSystemSettings, [])
  const { data, reload } = useAsyncData(loader)

  // Local editable settings state
  const [settings, setSettings] = useState<SystemSettings>(DEFAULT_SETTINGS)
  const [isDirty, setIsDirty] = useState(false)
  const [activeTab, setActiveTab] = useState<
    "qr" | "security" | "slots" | "sync" | "logs"
  >("qr")
  const [toastMessage, setToastMessage] = useState<string | null>(null)
  const [isSyncing, setIsSyncing] = useState(false)
  const [lastSyncText, setLastSyncText] = useState<string | null>(null)

  // Sync state once data loaded
  const currentSettings = isDirty ? settings : data ?? DEFAULT_SETTINGS

  const showToast = (msg: string) => {
    setToastMessage(msg)
    setTimeout(() => setToastMessage(null), 3500)
  }

  const updateField = <K extends keyof SystemSettings>(
    key: K,
    val: SystemSettings[K]
  ) => {
    setSettings((prev) => ({
      ...(isDirty ? prev : data ?? DEFAULT_SETTINGS),
      [key]: val,
    }))
    setIsDirty(true)
  }

  const handleSave = async () => {
    try {
      await saveSystemSettings(currentSettings, adminEmail)
      setIsDirty(false)
      reload()
      showToast("Đã lưu các thay đổi tham số toàn hệ thống vào Firestore thành công!")
    } catch {
      showToast("Lỗi khi lưu cấu hình vào Firestore.")
    }
  }

  const handleReset = () => {
    setSettings(DEFAULT_SETTINGS)
    setIsDirty(true)
    showToast("Đã khôi phục các tham số mặc định theo tiêu chuẩn FPT Edu.")
  }

  const handleSyncNow = async () => {
    setIsSyncing(true)
    try {
      const result = await triggerFapSyncNow(adminEmail)
      setLastSyncText(result.lastSyncAt)
      reload()
      showToast(
        `Đồng bộ dữ liệu thời gian thực thành công (${result.syncedCount} bản ghi điểm danh)!`
      )
    } catch {
      showToast("Không thể đồng bộ dữ liệu lúc này. Vui lòng kiểm tra quyền quản trị.")
    } finally {
      setIsSyncing(false)
    }
  }

  return (
    <div className="space-y-6 text-slate-800">
      {/* Toast notification */}
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
              Cài đặt &amp; Tham số Hệ thống
            </h1>
            <span className="px-2 py-0.5 rounded-md text-[11px] font-semibold bg-slate-100 text-slate-600 border border-slate-200/80">
              {currentSettings.version}
            </span>
          </div>
          <p className="text-xs text-slate-400 mt-1 max-w-2xl">
            Điều phối các giao thức quét mã QR, bán kính Geofencing, ràng buộc dải IP Hòa Lạc và tích hợp Core FAP.
          </p>
        </div>

        {/* Top Right Actions */}
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={handleReset}
            className="h-9 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 px-3.5 rounded-xl text-xs font-semibold flex items-center gap-2 shadow-xs transition cursor-pointer"
          >
            <RotateCcw size={14} className="text-slate-500" />
            <span>Khôi phục mặc định</span>
          </button>

          <button
            type="button"
            onClick={handleSave}
            className="h-9 bg-[#C2410C] hover:bg-[#9A3412] text-white px-4 rounded-xl text-xs font-semibold flex items-center gap-2 shadow-xs transition cursor-pointer"
          >
            <Save size={14} />
            <span>Lưu thay đổi</span>
          </button>
        </div>
      </div>

      {/* Tab Navigation Bar */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 border-b border-slate-200/80 text-xs">
        <button
          type="button"
          onClick={() => setActiveTab("qr")}
          className={`px-3.5 py-2 rounded-lg font-semibold flex items-center gap-2 transition whitespace-nowrap cursor-pointer ${
            activeTab === "qr"
              ? "bg-[#FFF0E6] text-[#C2410C] border border-[#FDBA74]"
              : "text-slate-600 hover:bg-slate-100"
          }`}
        >
          <QrCode size={15} />
          <span>Quy chế Điểm danh QR</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("security")}
          className={`px-3.5 py-2 rounded-lg font-semibold flex items-center gap-2 transition whitespace-nowrap cursor-pointer ${
            activeTab === "security"
              ? "bg-[#FFF0E6] text-[#C2410C] border border-[#FDBA74]"
              : "text-slate-600 hover:bg-slate-100"
          }`}
        >
          <Shield size={15} />
          <span>Bảo mật &amp; Giới hạn IP</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("slots")}
          className={`px-3.5 py-2 rounded-lg font-semibold flex items-center gap-2 transition whitespace-nowrap cursor-pointer ${
            activeTab === "slots"
              ? "bg-[#FFF0E6] text-[#C2410C] border border-[#FDBA74]"
              : "text-slate-600 hover:bg-slate-100"
          }`}
        >
          <Clock size={15} />
          <span>Khung giờ Ca học (Slots)</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("sync")}
          className={`px-3.5 py-2 rounded-lg font-semibold flex items-center gap-2 transition whitespace-nowrap cursor-pointer ${
            activeTab === "sync"
              ? "bg-[#FFF0E6] text-[#C2410C] border border-[#FDBA74]"
              : "text-slate-600 hover:bg-slate-100"
          }`}
        >
          <Network size={15} />
          <span>Tích hợp FAP Core &amp; Firestore</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("logs")}
          className={`px-3.5 py-2 rounded-lg font-semibold flex items-center gap-2 transition whitespace-nowrap cursor-pointer ${
            activeTab === "logs"
              ? "bg-[#FFF0E6] text-[#C2410C] border border-[#FDBA74]"
              : "text-slate-600 hover:bg-slate-100"
          }`}
        >
          <Database size={15} />
          <span>Giám sát &amp; Logs</span>
        </button>
      </div>

      {/* Main Settings Grid: 2 Columns */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* CARD 1: Tham số Điểm danh Live QR */}
        <div className="bg-white border border-slate-100 rounded-2xl p-6 shadow-xs flex flex-col justify-between">
          <div className="space-y-6">
            {/* Card Header */}
            <div className="flex items-start justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-orange-50 text-[#EA580C] flex items-center justify-center shrink-0">
                  <QrCode size={20} />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">
                    Tham số Điểm danh Live QR
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Cấu hình thuật toán sinh chuỗi token động chống gian lận
                  </p>
                </div>
              </div>
              <span className="text-[11px] font-bold text-[#EA580C] bg-[#FFF0E6] border border-[#FDBA74] px-2 py-0.5 rounded-full whitespace-nowrap">
                Slot Live
              </span>
            </div>

            {/* Parameter 1: QR Refresh Rate */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-xs font-bold text-slate-800">
                    Thời gian làm mới mã QR động (Dynamic QR Refresh Rate)
                  </h4>
                  <p className="text-[11px] text-slate-400">
                    Chu kỳ thay đổi hash động trên màn hình máy chiếu phòng học
                  </p>
                </div>
                <span className="text-[11px] font-medium text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                  60 giây (Khuyến nghị)
                </span>
              </div>

              {/* 3 Pills Selector */}
              <div className="grid grid-cols-3 gap-3 pt-1">
                {[
                  { seconds: 30, label: "30 giây" },
                  { seconds: 45, label: "45 giây" },
                  { seconds: 60, label: "60 giây (Tối ưu)" },
                ].map((item) => {
                  const isSelected = currentSettings.qrRefreshRate === item.seconds
                  return (
                    <button
                      key={item.seconds}
                      type="button"
                      onClick={() => updateField("qrRefreshRate", item.seconds)}
                      className={`py-2 px-3 rounded-xl text-xs font-semibold text-center border transition cursor-pointer ${
                        isSelected
                          ? "bg-[#FFF0E6] border-[#FDBA74] text-[#C2410C] shadow-xs"
                          : "bg-white border-slate-200 text-slate-600 hover:bg-slate-50"
                      }`}
                    >
                      {item.label}
                    </button>
                  )
                })}
              </div>
            </div>

            {/* Parameter 2: Grace period */}
            <div className="flex items-center justify-between pt-2">
              <div className="pr-4">
                <h4 className="text-xs font-bold text-slate-800">
                  Thời gian cho phép điểm danh sau khi bắt đầu ca (Grace Period)
                </h4>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Sinh viên vào trễ sau thời gian này sẽ tự động bị hệ thống đánh dấu &apos;Vắng&apos;
                </p>
              </div>
              <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 shrink-0">
                <input
                  type="number"
                  min={1}
                  max={60}
                  value={currentSettings.gracePeriodMinutes}
                  onChange={(e) => updateField("gracePeriodMinutes", Number(e.target.value))}
                  className="w-10 text-xs font-bold text-slate-800 bg-transparent text-right focus:outline-none"
                />
                <span className="text-xs text-slate-500 font-medium">phút</span>
              </div>
            </div>

            {/* Parameter 3: Teacher manual approval toggle */}
            <div className="flex items-center justify-between pt-2">
              <div className="pr-4">
                <h4 className="text-xs font-bold text-slate-800">
                  Cho phép Giảng viên duyệt đơn điểm danh bù
                </h4>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Giảng viên bộ môn có quyền xác thực sinh viên điểm danh bù thủ công khi gặp sự cố camera
                </p>
              </div>
              <button
                type="button"
                onClick={() =>
                  updateField(
                    "allowTeacherManualApproval",
                    !currentSettings.allowTeacherManualApproval
                  )
                }
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                  currentSettings.allowTeacherManualApproval ? "bg-[#EA580C]" : "bg-slate-200"
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    currentSettings.allowTeacherManualApproval ? "translate-x-5" : "translate-x-0"
                  }`}
                />
              </button>
            </div>
          </div>

          {/* Footer note */}
          <div className="pt-4 mt-6 border-t border-slate-100 flex items-center gap-2 text-[11px] text-slate-400">
            <Info size={14} className="text-[#EA580C] shrink-0" />
            <span>Mỗi mã QR mã hóa SHA-256 kèm theo Timestamp định danh duy nhất theo từng Slot.</span>
          </div>
        </div>

        {/* CARD 2: Bảo mật Campus & Địa lý */}
        <div className="bg-white border border-slate-100 rounded-2xl p-6 shadow-xs flex flex-col justify-between">
          <div className="space-y-6">
            {/* Card Header */}
            <div className="flex items-start justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0">
                  <Shield size={20} />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">
                    Bảo mật Campus &amp; Địa lý
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Ràng buộc không gian vật lý chống điểm danh hộ
                  </p>
                </div>
              </div>
            </div>

            {/* Setting 1: Require Campus IP */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-xs font-bold text-slate-800">
                    Bắt buộc kiểm tra IP Campus FPT
                  </h4>
                  <p className="text-[11px] text-slate-400">
                    Chỉ chấp nhận thiết bị kết nối Wi-Fi FPT-Education
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    updateField("requireCampusIp", !currentSettings.requireCampusIp)
                  }
                  className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                    currentSettings.requireCampusIp ? "bg-[#EA580C]" : "bg-slate-200"
                  }`}
                >
                  <span
                    className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                      currentSettings.requireCampusIp ? "translate-x-5" : "translate-x-0"
                    }`}
                  />
                </button>
              </div>

              {/* IP Range Chip */}
              <div className="flex items-center gap-2 bg-slate-50 border border-slate-100 rounded-xl p-2.5 text-xs">
                <span className="font-mono font-bold text-slate-800 bg-white border border-slate-200 px-2 py-0.5 rounded shadow-2xs">
                  {currentSettings.campusIpRange}
                </span>
                <span className="text-slate-500 text-[11px]">
                  Dải IP mạng Hòa Lạc (Đang áp dụng)
                </span>
              </div>
            </div>

            {/* Setting 2: Geofencing Radius Slider */}
            <div className="space-y-2 pt-1">
              <div className="flex items-center justify-between">
                <h4 className="text-xs font-bold text-slate-800">
                  Bán kính GPS Geofencing cho phép
                </h4>
                <span className="text-xs font-bold text-[#EA580C] bg-[#FFF0E6] px-2 py-0.5 rounded">
                  {currentSettings.geofenceRadiusMeters} mét
                </span>
              </div>

              <input
                type="range"
                min={50}
                max={500}
                step={25}
                value={currentSettings.geofenceRadiusMeters}
                onChange={(e) =>
                  updateField("geofenceRadiusMeters", Number(e.target.value))
                }
                className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-[#EA580C]"
              />

              <div className="flex items-center justify-between text-[11px] text-slate-400 pt-0.5">
                <span>50m (Cực hẹp)</span>
                <span className="font-medium text-slate-600">Tòa nhà Alpha / Beta / Delta</span>
                <span>500m (Rộng)</span>
              </div>
            </div>

            {/* Setting 3: Device Fingerprint */}
            <div className="flex items-center justify-between pt-1">
              <div className="pr-4">
                <h4 className="text-xs font-bold text-slate-800">
                  Khóa thiết bị sinh viên (Device Fingerprint)
                </h4>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Mỗi tài khoản FPT chỉ được check-in trên 1 thiết bị duy nhất trong mỗi ca học
                </p>
              </div>
              <button
                type="button"
                onClick={() =>
                  updateField(
                    "enableDeviceFingerprint",
                    !currentSettings.enableDeviceFingerprint
                  )
                }
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                  currentSettings.enableDeviceFingerprint ? "bg-[#EA580C]" : "bg-slate-200"
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    currentSettings.enableDeviceFingerprint ? "translate-x-5" : "translate-x-0"
                  }`}
                />
              </button>
            </div>
          </div>

          {/* Verification Badge Box */}
          <div className="mt-6 bg-emerald-50/70 border border-emerald-200/60 rounded-xl p-3 flex items-center gap-2.5 text-xs text-emerald-800">
            <CheckCircle2 size={16} className="text-emerald-600 shrink-0" />
            <span className="font-medium">Hệ thống kích hoạt chuẩn chứng thực FPT Edu 2.0</span>
          </div>
        </div>

        {/* CARD 3: Ngưỡng Cảnh báo & Khóa môn */}
        <div className="bg-white border border-slate-100 rounded-2xl p-6 shadow-xs flex flex-col justify-between">
          <div className="space-y-6">
            {/* Card Header */}
            <div className="flex items-start justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-red-50 text-red-500 flex items-center justify-center shrink-0">
                  <AlertTriangle size={20} />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">
                    Ngưỡng Cảnh báo &amp; Khóa môn
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Quy chế học vụ Đại học FPT về tỷ lệ chuyên cần
                  </p>
                </div>
              </div>
              <span className="text-[11px] font-bold text-red-600 bg-red-50 border border-red-200/80 px-2 py-0.5 rounded-full whitespace-nowrap">
                Học vụ FPT
              </span>
            </div>

            {/* Setting 1: Absent percentage threshold */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-xs font-bold text-slate-800">
                    Ngưỡng cấm thi tự động
                  </h4>
                  <p className="text-[11px] text-slate-400">
                    Tỷ lệ vắng tối đa trước khi hệ thống đánh trượt PE/FE
                  </p>
                </div>
                <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 shrink-0">
                  <input
                    type="number"
                    min={5}
                    max={50}
                    value={currentSettings.maxAbsentThresholdPercent}
                    onChange={(e) =>
                      updateField("maxAbsentThresholdPercent", Number(e.target.value))
                    }
                    className="w-10 text-xs font-bold text-slate-800 bg-transparent text-right focus:outline-none"
                  />
                  <span className="text-xs text-slate-500 font-medium">%</span>
                </div>
              </div>

              {/* Info Note */}
              <div className="flex items-center gap-2 bg-slate-50 border border-slate-100 rounded-xl p-2.5 text-xs text-slate-600">
                <Info size={14} className="text-slate-400 shrink-0" />
                <span>
                  Tương đương: Nghỉ quá <b>4 buổi</b> trên tổng số 20 buổi của môn tiêu chuẩn (3 tín chỉ).
                </span>
              </div>
            </div>

            {/* Setting 2: Auto FCM Notice */}
            <div className="flex items-center justify-between pt-1">
              <div className="pr-4">
                <h4 className="text-xs font-bold text-slate-800">
                  Tự động gửi thông báo FCM nhắc nhở
                </h4>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Gửi cảnh báo qua FAP Mobile App tới sinh viên khi bắt đầu vắng từ buổi thứ 2
                </p>
              </div>
              <button
                type="button"
                onClick={() =>
                  updateField("autoSendFcmNotice", !currentSettings.autoSendFcmNotice)
                }
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                  currentSettings.autoSendFcmNotice ? "bg-[#EA580C]" : "bg-slate-200"
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    currentSettings.autoSendFcmNotice ? "translate-x-5" : "translate-x-0"
                  }`}
                />
              </button>
            </div>

            {/* Setting 3: Advisor weekly summary email */}
            <div className="flex items-center justify-between pt-1">
              <div className="pr-4">
                <h4 className="text-xs font-bold text-slate-800">
                  Cảnh báo GVCN &amp; Cố vấn học tập
                </h4>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Tự động gửi email tổng hợp sinh viên có nguy cơ cấm thi vào thứ 6 hàng tuần
                </p>
              </div>
              <button
                type="button"
                onClick={() =>
                  updateField("notifyAdvisorWeekly", !currentSettings.notifyAdvisorWeekly)
                }
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                  currentSettings.notifyAdvisorWeekly ? "bg-[#EA580C]" : "bg-slate-200"
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    currentSettings.notifyAdvisorWeekly ? "translate-x-5" : "translate-x-0"
                  }`}
                />
              </button>
            </div>
          </div>

          {/* Footer note */}
          <div className="pt-4 mt-6 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-400">
            <span>Áp dụng toàn bộ sinh viên Đại học chính quy</span>
            <a
              href="#policy"
              onClick={(e) => {
                e.preventDefault()
                showToast("Đang mở quy chế đào tạo Đại học FPT...")
              }}
              className="text-[#C2410C] font-semibold hover:underline flex items-center gap-1"
            >
              Chi tiết Quy chế Học vụ &rarr;
            </a>
          </div>
        </div>

        {/* CARD 4: Trạng thái Dịch vụ & FAP API Sync */}
        <div className="bg-white border border-slate-100 rounded-2xl p-6 shadow-xs flex flex-col justify-between">
          <div className="space-y-6">
            {/* Card Header */}
            <div className="flex items-start justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                  <Network size={20} />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">
                    Trạng thái Dịch vụ &amp; FAP API Sync
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Liên kết cơ sở dữ liệu thời gian thực và Core Portal
                  </p>
                </div>
              </div>
              <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200/80 px-2 py-0.5 rounded-full whitespace-nowrap">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                Connected
              </span>
            </div>

            {/* Service 1: Firebase Firestore */}
            <div className="flex items-center justify-between p-3.5 bg-slate-50/70 border border-slate-100 rounded-xl hover:bg-slate-50 transition">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-lg bg-orange-100/70 text-[#EA580C] flex items-center justify-center shrink-0">
                  <Flame size={18} />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-slate-900">Firebase Firestore</span>
                    <span className="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-1.5 py-0.2 rounded">
                      Online
                    </span>
                  </div>
                  <p className="text-[11px] text-slate-500 mt-0.5">
                    Ping: <b>{data?.pingMs ?? 0}ms</b> • Đã đồng bộ{" "}
                    <b>{(data?.totalSyncedAccounts ?? 0).toLocaleString("en-US")}</b> tài khoản
                  </p>
                </div>
              </div>
              <CheckCircle2 size={18} className="text-emerald-600 shrink-0" />
            </div>

            {/* Service 2: FAP Core Portal */}
            <div className="flex items-center justify-between p-3.5 bg-slate-50/70 border border-slate-100 rounded-xl hover:bg-slate-50 transition">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-lg bg-blue-100/70 text-blue-600 flex items-center justify-center shrink-0">
                  <Globe size={18} />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-slate-900">FAP Core Portal</span>
                    <span className="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-1.5 py-0.2 rounded">
                      Kết nối thành công
                    </span>
                  </div>
                  <p className="text-[11px] text-slate-500 mt-0.5">
                    Lần đồng bộ gần nhất:{" "}
                    <b>{lastSyncText ?? data?.lastSyncAt ?? data?.lastUpdated ?? "Trực tuyến"}</b> •
                    Chờ đồng bộ: <b>{data?.unsyncedRecordsCount ?? 0}</b> bản ghi
                  </p>
                </div>
              </div>
              <CheckCircle2 size={18} className="text-emerald-600 shrink-0" />
            </div>
          </div>

          {/* Card Footer: Manual Sync Button */}
          <div className="pt-4 mt-6 border-t border-slate-100 flex items-center justify-between text-xs">
            <div className="flex items-center gap-1.5 text-slate-400 text-[11px]">
              <Clock size={13} />
              <span>Tự động đồng bộ mỗi 15 phút</span>
            </div>

            <button
              type="button"
              disabled={isSyncing}
              onClick={handleSyncNow}
              className="border border-[#FDBA74] text-[#C2410C] hover:bg-[#FFF0E6] px-3.5 py-1.5 rounded-xl font-semibold flex items-center gap-1.5 transition shadow-2xs cursor-pointer disabled:opacity-50"
            >
              <RotateCcw
                size={13}
                className={isSyncing ? "animate-spin text-[#C2410C]" : ""}
              />
              <span>{isSyncing ? "Đang đồng bộ..." : "Đồng bộ dữ liệu ngay lập tức"}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Bottom Footer Strip: Metadata & Audit Info */}
      <div className="p-4 bg-white border border-slate-100 rounded-2xl shadow-xs flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-xs text-slate-500">
        <div className="flex items-center gap-2">
          <ShieldCheck size={16} className="text-[#EA580C] shrink-0" />
          <span>
            Phiên đăng nhập quản trị gần nhất: <b>08:14 Hôm nay</b> bởi <b>{adminEmail}</b> (IP: 10.22.4.15)
          </span>
        </div>

        <div className="flex items-center gap-4 text-[11px] text-slate-500 font-medium">
          <a
            href="#audit"
            onClick={(e) => {
              e.preventDefault()
              showToast("Đang mở nhật ký Audit Log...")
            }}
            className="hover:text-slate-800 transition"
          >
            Nhật ký Audit Log
          </a>
          <span>•</span>
          <a
            href="#api"
            onClick={(e) => {
              e.preventDefault()
              showToast("Đang mở tài liệu FAP API Gateway...")
            }}
            className="hover:text-slate-800 transition"
          >
            Tài liệu API FAP
          </a>
          <span>•</span>
          <span className="flex items-center gap-1 text-slate-600">
            <Lock size={12} className="text-emerald-600" />
            Bảo mật SSL 256-bit
          </span>
        </div>
      </div>
    </div>
  )
}

