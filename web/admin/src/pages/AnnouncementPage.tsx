import { useCallback, useMemo, useState } from "react"
import { Pagination } from "../components/Pagination"
import { useAsyncData } from "../hooks/useAsyncData"
import {
  AlertCircle,
  Bell,
  BellRing,
  Bold,
  BookOpen,
  Calendar,
  Check,
  CheckCircle2,
  ChevronDown,
  Clock,
  ExternalLink,
  Flame,
  GraduationCap,
  History,
  Info,
  Italic,
  Link2,
  List,
  ListOrdered,
  Lock,
  MessageSquare,
  Pin,
  Play,
  Radio,
  Save,
  Send,
  Shield,
  Smartphone,
  Underline,
  User,
  Users,
  Wifi,
  X,
} from "lucide-react"
import {
  getAnnouncementHistory,
  getAnnouncementTargets,
  saveAnnouncementDraft,
  sendAnnouncement,
  type AnnouncementHistoryItem,
} from "../repositories/announcementRepository"
import type { AdminPage } from "../types/admin-v2"

export function AnnouncementPage({
  onNavigate,
  adminEmail = "admin.hac@fpt.edu.vn",
}: {
  onNavigate: (page: AdminPage) => void
  adminEmail?: string
}) {
  const targetsLoader = useCallback(getAnnouncementTargets, [])
  const { data: targetsData } = useAsyncData(targetsLoader)

  // Form State
  const [title, setTitle] = useState(
    "Thông báo thay đổi phòng học & cập nhật lịch thi Slot 2"
  )
  const [targetAudience, setTargetAudience] = useState<
    "all" | "teachers" | "students" | "specific_class"
  >("all")
  const [selectedChips, setSelectedChips] = useState<string[]>([])
  const [priority, setPriority] = useState<"normal" | "important" | "urgent">(
    "urgent"
  )
  const [fcmPush, setFcmPush] = useState(true)
  const [inAppInbox, setInAppInbox] = useState(true)
  const [kioskPopup, setKioskPopup] = useState(false)
  const [content, setContent] = useState(
    "Kính gửi quý Thầy Cô và Sinh viên, đề nghị kiểm tra lịch học và phòng học cập nhật trực tiếp trên ứng dụng FAP Check-in trước giờ vào ca."
  )
  const [scheduleType, setScheduleType] = useState<"immediate" | "scheduled">(
    "immediate"
  )
  const [enableSound, setEnableSound] = useState(true)
  const [pinToTop, setPinToTop] = useState(false)

  // Feedback State
  const [isSending, setIsSending] = useState(false)
  const [toastMessage, setToastMessage] = useState<string | null>(null)
  const [showHistory, setShowHistory] = useState(false)
  const [historyList, setHistoryList] = useState<AnnouncementHistoryItem[]>([])
  const [historyPage, setHistoryPage] = useState(1)
  const paginatedHistory = useMemo(() => {
    const start = (historyPage - 1) * 10
    return historyList.slice(start, start + 10)
  }, [historyList, historyPage])

  const estimatedRecipients = useMemo(() => {
    const total = targetsData?.totalUsers ?? 0
    const teachers = targetsData?.teacherCount ?? 0
    const students = targetsData?.studentCount ?? 0
    if (targetAudience === "teachers") return teachers
    if (targetAudience === "students") return students
    if (targetAudience === "specific_class") {
      if (selectedChips.length === 0) return 0
      const chipsMap = new Map(
        (targetsData?.classChips ?? []).map((c) => [c.label, c.studentCount])
      )
      return selectedChips.reduce((acc, chip) => acc + (chipsMap.get(chip) ?? 0), 0)
    }
    return total
  }, [targetAudience, targetsData, selectedChips])

  const showToast = (msg: string) => {
    setToastMessage(msg)
    setTimeout(() => setToastMessage(null), 3500)
  }

  const handleSend = async () => {
    if (!title.trim() || !content.trim()) {
      showToast("Vui lòng nhập đầy đủ tiêu đề và nội dung thông báo.")
      return
    }

    setIsSending(true)
    try {
      await sendAnnouncement({
        title,
        content,
        targetAudience,
        selectedClasses: selectedChips,
        priority,
        channels: { fcmPush, inAppInbox, kioskPopup },
        scheduleType,
        enableSoundAndVibration: enableSound,
        pinToTop,
        recipientCount: estimatedRecipients,
        createdBy: adminEmail,
      })
      showToast(
        scheduleType === "immediate"
          ? `Phát sóng thông báo thành công tới ${estimatedRecipients.toLocaleString("en-US")} người nhận trên Firestore!`
          : "Đã lên lịch phát sóng thông báo thành công trên Firestore!"
      )
    } catch {
      showToast("Lỗi khi lưu thông báo lên Firestore. Vui lòng kiểm tra quyền quản trị.")
    } finally {
      setIsSending(false)
    }
  }

  const handleSaveDraft = async () => {
    try {
      await saveAnnouncementDraft({
        title,
        content,
        targetAudience,
        selectedClasses: selectedChips,
        priority,
        channels: { fcmPush, inAppInbox, kioskPopup },
        scheduleType,
        enableSoundAndVibration: enableSound,
        pinToTop,
        recipientCount: estimatedRecipients,
        createdBy: adminEmail,
      })
      showToast("Đã lưu bản nháp thông báo vào Firestore thành công.")
    } catch {
      showToast("Không thể lưu bản nháp vào Firestore.")
    }
  }

  const openHistory = async () => {
    setShowHistory(true)
    const list = await getAnnouncementHistory()
    setHistoryList(list)
  }

  const insertVariable = (tag: string) => {
    setContent((prev) => `${prev} ${tag}`)
  }

  const toggleChip = (chip: string) => {
    if (selectedChips.includes(chip)) {
      setSelectedChips(selectedChips.filter((c) => c !== chip))
    } else {
      setSelectedChips([...selectedChips, chip])
    }
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

      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Tạo thông báo &amp; Truyền thông FAP
          </h1>
          <p className="text-xs text-slate-400 mt-1 max-w-2xl">
            Gửi thông tin tức thời hoặc hẹn giờ phát sóng tới giảng viên, sinh viên và các lớp học theo thời gian thực.
          </p>
        </div>

        {/* Top Right Actions */}
        <div className="flex items-center gap-2.5">
          <button
            type="button"
            onClick={openHistory}
            className="h-9 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 px-3.5 rounded-xl text-xs font-semibold flex items-center gap-2 shadow-xs transition cursor-pointer"
          >
            <History size={14} className="text-slate-500" />
            <span>Xem lịch sử thông báo</span>
          </button>

          <button
            type="button"
            onClick={handleSaveDraft}
            className="h-9 flex items-center gap-2 px-4 bg-[#C2410C] hover:bg-[#9A3412] text-white rounded-xl text-xs font-semibold shadow-xs transition cursor-pointer"
          >
            <Save size={14} />
            <span>Lưu bản nháp</span>
          </button>
        </div>
      </div>

      {/* Main 2-Column Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* LEFT COLUMN: FORM (lg:col-span-8 ~ 67%) */}
        <div className="lg:col-span-8 space-y-5">
          {/* 1. Tiêu đề thông báo */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-2">
            <div className="flex items-center justify-between text-xs">
              <label className="font-bold text-slate-800">
                Tiêu đề thông báo <span className="text-[#EA580C]">*</span>
              </label>
              <span className="text-slate-400 text-[11px]">Ngắn gọn, rõ mục đích</span>
            </div>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Nhập tiêu đề thông báo..."
              className="w-full text-xs font-semibold text-slate-800 bg-slate-50/70 border border-slate-200 rounded-xl px-4 py-2.5 focus:outline-none focus:border-[#EA580C] focus:bg-white transition"
            />
          </div>

          {/* 2. Đối tượng người nhận */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-3">
            <div className="flex items-center justify-between text-xs">
              <label className="font-bold text-slate-800">
                Đối tượng người nhận <span className="text-[#EA580C]">*</span>
              </label>
              <a
                href="#advanced"
                onClick={(e) => {
                  e.preventDefault()
                  showToast("Mở bộ lọc người nhận nâng cao...")
                }}
                className="text-[#C2410C] font-semibold hover:underline text-[11px]"
              >
                Chọn theo bộ lọc nâng cao
              </a>
            </div>

            {/* 4 Audience Cards */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {[
                {
                  id: "all" as const,
                  label: "Tất cả (Kỳ)",
                  sub: `${(targetsData?.totalUsers ?? 0).toLocaleString("en-US")} tài khoản`,
                  icon: <Users size={16} />,
                },
                {
                  id: "teachers" as const,
                  label: "Giảng viên",
                  sub: `${(targetsData?.teacherCount ?? 0).toLocaleString("en-US")} cán bộ`,
                  icon: <GraduationCap size={16} />,
                },
                {
                  id: "students" as const,
                  label: "Sinh viên",
                  sub: `${(targetsData?.studentCount ?? 0).toLocaleString("en-US")} sinh viên`,
                  icon: <User size={16} />,
                },
                {
                  id: "specific_class" as const,
                  label: "Lớp cụ thể",
                  sub: `${(targetsData?.classChips.length ?? 0)} lớp đang mở`,
                  icon: <BookOpen size={16} />,
                },
              ].map((item) => {
                const isSelected = targetAudience === item.id
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setTargetAudience(item.id)}
                    className={`p-3.5 rounded-xl border text-left transition flex flex-col justify-between cursor-pointer ${
                      isSelected
                        ? "bg-[#FFF0E6] border-[#FDBA74] text-[#C2410C] shadow-xs"
                        : "bg-white border-slate-200/90 text-slate-700 hover:bg-slate-50"
                    }`}
                  >
                    <div
                      className={`w-7 h-7 rounded-lg flex items-center justify-center mb-2 ${
                        isSelected
                          ? "bg-white text-[#EA580C] shadow-2xs"
                          : "bg-slate-100 text-slate-500"
                      }`}
                    >
                      {item.icon}
                    </div>
                    <div>
                      <div className="text-xs font-bold">{item.label}</div>
                      <div className="text-[10px] text-slate-400 mt-0.5">{item.sub}</div>
                    </div>
                  </button>
                )
              })}
            </div>

            {/* Quick Filter Suggestion Chips from real Firestore classes */}
            <div className="pt-2 flex flex-wrap items-center gap-2 text-xs">
              <span className="text-[11px] text-slate-400 font-medium">
                Gợi ý lọc nhanh lớp học thực tế:
              </span>
              {(targetsData?.classChips ?? []).slice(0, 8).map((chipItem) => {
                const cleanName = chipItem.label
                const isSelected = selectedChips.includes(cleanName)
                return (
                  <button
                    key={chipItem.classCode}
                    type="button"
                    onClick={() => {
                      toggleChip(cleanName)
                      if (targetAudience !== "specific_class") {
                        setTargetAudience("specific_class")
                      }
                    }}
                    className={`px-2.5 py-1 rounded-lg text-[11px] font-semibold transition cursor-pointer ${
                      isSelected
                        ? "bg-[#EA580C] text-white shadow-2xs"
                        : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                    }`}
                  >
                    {isSelected ? `${cleanName} ✕` : `+ ${cleanName}`}
                  </button>
                )
              })}
            </div>
          </div>

          {/* 3. Mức độ ưu tiên & Kênh phát sóng */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Priority */}
            <div className="space-y-2">
              <label className="text-xs font-bold text-slate-800 block">
                Mức độ ưu tiên
              </label>
              <div className="relative">
                <select
                  value={priority}
                  onChange={(e) => setPriority(e.target.value as any)}
                  className="w-full text-xs font-semibold text-slate-800 bg-slate-50/70 border border-slate-200 rounded-xl px-3.5 py-2.5 appearance-none focus:outline-none focus:border-[#EA580C] cursor-pointer"
                >
                  <option value="urgent">Khẩn cấp / Cảnh báo tức thì</option>
                  <option value="important">Quan trọng / Cần chú ý</option>
                  <option value="normal">Bình thường / Tin tức</option>
                </select>
                <ChevronDown
                  size={14}
                  className="absolute right-3.5 top-3 text-slate-400 pointer-events-none"
                />
              </div>
            </div>

            {/* Channels */}
            <div className="space-y-2">
              <label className="text-xs font-bold text-slate-800 block">
                Kênh phát sóng chính
              </label>
              <div className="space-y-2 text-xs">
                <label className="flex items-center gap-2 cursor-pointer font-medium text-slate-700">
                  <input
                    type="checkbox"
                    checked={fcmPush}
                    onChange={(e) => setFcmPush(e.target.checked)}
                    className="accent-[#EA580C] w-4 h-4 rounded cursor-pointer"
                  />
                  <span>Push notification FCM (Điện thoại)</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer font-medium text-slate-700">
                  <input
                    type="checkbox"
                    checked={inAppInbox}
                    onChange={(e) => setInAppInbox(e.target.checked)}
                    className="accent-[#EA580C] w-4 h-4 rounded cursor-pointer"
                  />
                  <span>Hộp thư Inbox FAP Mobile App</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer font-medium text-slate-700">
                  <input
                    type="checkbox"
                    checked={kioskPopup}
                    onChange={(e) => setKioskPopup(e.target.checked)}
                    className="accent-[#EA580C] w-4 h-4 rounded cursor-pointer"
                  />
                  <span>Pop-up khẩn cấp tại cổng trường (Kiosk)</span>
                </label>
              </div>
            </div>
          </div>

          {/* 4. Nội dung thông báo */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-3">
            <div className="flex items-center justify-between text-xs">
              <label className="font-bold text-slate-800">
                Nội dung thông báo <span className="text-[#EA580C]">*</span>
              </label>
              <span className="text-slate-400 text-[11px]">
                {content.length} / 1000 ký tự
              </span>
            </div>

            {/* Formatting Toolbar */}
            <div className="flex flex-wrap items-center justify-between gap-2 p-2 bg-slate-50 border border-slate-200/80 rounded-xl">
              <div className="flex items-center gap-1 text-slate-600">
                <button
                  type="button"
                  title="In đậm"
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center font-bold text-xs"
                >
                  <Bold size={13} />
                </button>
                <button
                  type="button"
                  title="In nghiêng"
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center text-xs"
                >
                  <Italic size={13} />
                </button>
                <button
                  type="button"
                  title="Gạch chân"
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center text-xs"
                >
                  <Underline size={13} />
                </button>
                <span className="h-4 w-px bg-slate-300 mx-1" />
                <button
                  type="button"
                  title="Danh sách gạch đầu dòng"
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center"
                >
                  <List size={13} />
                </button>
                <button
                  type="button"
                  title="Danh sách số"
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center"
                >
                  <ListOrdered size={13} />
                </button>
                <button
                  type="button"
                  title="Chèn liên kết"
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center"
                >
                  <Link2 size={13} />
                </button>
              </div>

              {/* Dynamic Variables */}
              <div className="flex items-center gap-1.5 text-[11px]">
                <span className="text-slate-400 font-medium">Chèn biến động:</span>
                {[
                  { tag: "[student_name]", label: "[student_name]" },
                  { tag: "[class_id]", label: "[class_id]" },
                  { tag: "[room_number]", label: "[room_number]" },
                ].map((item) => (
                  <button
                    key={item.tag}
                    type="button"
                    onClick={() => insertVariable(item.tag)}
                    className="px-2 py-0.5 rounded bg-white border border-slate-200 text-slate-700 hover:border-[#EA580C] hover:text-[#EA580C] font-mono text-[10px] transition cursor-pointer"
                  >
                    {item.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Textarea */}
            <textarea
              rows={4}
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="Nhập nội dung thông báo gửi tới sinh viên và giảng viên..."
              className="w-full text-xs text-slate-800 leading-relaxed bg-slate-50/70 border border-slate-200 rounded-xl p-3.5 focus:outline-none focus:border-[#EA580C] focus:bg-white transition"
            />
          </div>

          {/* 5. Thời gian phát sóng */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-3">
            <label className="text-xs font-bold text-slate-800 block">
              Thời gian phát sóng
            </label>

            {/* 2 Options */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setScheduleType("immediate")}
                className={`p-3.5 rounded-xl border text-left transition flex items-start gap-3 cursor-pointer ${
                  scheduleType === "immediate"
                    ? "bg-[#FFF0E6] border-[#FDBA74] text-[#C2410C]"
                    : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
                }`}
              >
                <div className="mt-0.5">
                  <span
                    className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                      scheduleType === "immediate"
                        ? "border-[#EA580C] bg-[#EA580C]"
                        : "border-slate-300"
                    }`}
                  >
                    {scheduleType === "immediate" && (
                      <span className="w-1.5 h-1.5 rounded-full bg-white" />
                    )}
                  </span>
                </div>
                <div>
                  <div className="text-xs font-bold">Gửi ngay lập tức</div>
                  <div className="text-[11px] text-slate-400 mt-0.5">
                    Phát sóng thông báo đến tất cả thiết bị chỉ trong ~3 giây
                  </div>
                </div>
              </button>

              <button
                type="button"
                onClick={() => setScheduleType("scheduled")}
                className={`p-3.5 rounded-xl border text-left transition flex items-start gap-3 cursor-pointer ${
                  scheduleType === "scheduled"
                    ? "bg-[#FFF0E6] border-[#FDBA74] text-[#C2410C]"
                    : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
                }`}
              >
                <div className="mt-0.5">
                  <span
                    className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                      scheduleType === "scheduled"
                        ? "border-[#EA580C] bg-[#EA580C]"
                        : "border-slate-300"
                    }`}
                  >
                    {scheduleType === "scheduled" && (
                      <span className="w-1.5 h-1.5 rounded-full bg-white" />
                    )}
                  </span>
                </div>
                <div>
                  <div className="text-xs font-bold">Lên lịch phát sóng</div>
                  <div className="text-[11px] text-slate-400 mt-0.5">
                    Chọn ngày &amp; khung giờ cụ thể trước ca học
                  </div>
                </div>
              </button>
            </div>

            {/* Broadcast estimate info box */}
            <div className="bg-slate-50 border border-slate-100 rounded-xl p-3 flex items-center justify-between text-xs">
              <div className="flex items-center gap-2 text-slate-600">
                <Clock size={14} className="text-[#EA580C]" />
                <span>
                  Thời gian dự kiến phát: <b>Bây giờ (Thứ Sáu, 24/10/2026 - 09:20 AM)</b>
                </span>
              </div>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-100 text-emerald-700">
                Độ trễ thấp &lt; 500ms
              </span>
            </div>
          </div>

          {/* 6. Tùy chọn tương tác nâng cao */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-4">
            <h3 className="text-xs font-bold text-slate-800">
              Tùy chọn tương tác nâng cao
            </h3>

            {/* Option 1: Sound & Vibrate */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-orange-50 text-[#EA580C] flex items-center justify-center shrink-0">
                  <BellRing size={16} />
                </div>
                <div>
                  <div className="text-xs font-bold text-slate-800">
                    Bật âm thanh &amp; rung Push Notification
                  </div>
                  <div className="text-[11px] text-slate-400">
                    Rung máy ngay lập tức khi nhận được thông báo quan trọng
                  </div>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setEnableSound(!enableSound)}
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                  enableSound ? "bg-[#EA580C]" : "bg-slate-200"
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    enableSound ? "translate-x-5" : "translate-x-0"
                  }`}
                />
              </button>
            </div>

            {/* Option 2: Pin to top */}
            <div className="flex items-center justify-between pt-2 border-t border-slate-50">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center shrink-0">
                  <Pin size={16} />
                </div>
                <div>
                  <div className="text-xs font-bold text-slate-800">
                    Ghim lên đầu bảng tin FAP Mobile
                  </div>
                  <div className="text-[11px] text-slate-400">
                    Giữ thông báo ở vị trí ưu tiên số 1 trong vòng 24 giờ
                  </div>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setPinToTop(!pinToTop)}
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                  pinToTop ? "bg-[#EA580C]" : "bg-slate-200"
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    pinToTop ? "translate-x-5" : "translate-x-0"
                  }`}
                />
              </button>
            </div>
          </div>
        </div>

        {/* RIGHT COLUMN: PREVIEW & STATS (lg:col-span-4 ~ 33%) */}
        <div className="lg:col-span-4 space-y-5">
          {/* 1. Phạm vi phủ sóng ước tính */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                Phạm vi phủ sóng ước tính
              </span>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-100 text-emerald-700">
                Sẵn sàng
              </span>
            </div>

            {/* 2 Stat Boxes */}
            <div className="grid grid-cols-2 gap-3">
              <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-100">
                <div className="text-[11px] text-slate-400 font-medium">
                  Tổng người nhận
                </div>
                <div className="text-2xl font-extrabold text-slate-900 mt-0.5">
                  {estimatedRecipients.toLocaleString("en-US")}
                </div>
                <div className="text-[10px] text-slate-400 mt-0.5">
                  Theo đối tượng đã chọn
                </div>
              </div>

              <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-100">
                <div className="text-[11px] text-slate-400 font-medium">
                  Đã liên kết Auth UID
                </div>
                <div className="text-2xl font-extrabold text-[#EA580C] mt-0.5">
                  {(targetsData?.linkedUsers ?? 0).toLocaleString("en-US")}
                </div>
                <div className="text-[10px] text-slate-400 mt-0.5">
                  Nhận thông báo tức thời
                </div>
              </div>
            </div>

            {/* Certificate */}
            <div className="flex items-center gap-2 text-[11px] text-slate-500 pt-1">
              <CheckCircle2 size={13} className="text-emerald-600 shrink-0" />
              <span>Chứng chỉ máy chủ FCM FPT Cloud ID: <b>fap-cloud-hl-prod</b></span>
            </div>
          </div>

          {/* 2. Mô phỏng hiển thị trên Mobile (Live Smartphone Mockup) */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Smartphone size={16} className="text-[#EA580C]" />
                <span className="text-xs font-bold text-slate-900">
                  Mô phỏng hiển thị trên Mobile
                </span>
              </div>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                Live Preview
              </span>
            </div>

            {/* Realistic Phone Case Mockup */}
            <div className="relative mx-auto w-full max-w-[270px] bg-slate-900 rounded-[36px] p-2.5 shadow-xl border-4 border-slate-800">
              {/* Phone Speaker Notch */}
              <div className="absolute top-4 left-1/2 -translate-x-1/2 w-16 h-3 bg-slate-800 rounded-full z-20 flex items-center justify-center">
                <div className="w-2.5 h-2.5 rounded-full bg-slate-950" />
              </div>

              {/* Phone Screen */}
              <div className="relative bg-slate-50 rounded-[28px] overflow-hidden min-h-[380px] flex flex-col justify-between pt-6 pb-3 px-3 shadow-inner">
                {/* Status bar */}
                <div className="flex items-center justify-between text-[10px] text-slate-600 font-semibold px-1 mb-3">
                  <span>09:20</span>
                  <div className="flex items-center gap-1 text-slate-500">
                    <Wifi size={10} />
                    <span className="text-[9px]">100%</span>
                  </div>
                </div>

                {/* Main Push Banner (App Notification) */}
                <div className="space-y-3">
                  {/* Lockscreen style notification bubble */}
                  <div className="bg-white/95 backdrop-blur-md rounded-2xl p-3 shadow-md border border-slate-200/80 space-y-1.5 text-left transition-all">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5">
                        <div className="w-4 h-4 rounded bg-[#EA580C] text-white flex items-center justify-center text-[9px] font-extrabold">
                          F
                        </div>
                        <span className="text-[10px] font-bold text-slate-700 tracking-wider">
                          FAP CHECK-IN
                        </span>
                      </div>
                      <span className="text-[9px] text-slate-400">Vừa xong</span>
                    </div>

                    <div className="text-[11px] font-bold text-slate-900 line-clamp-2">
                      {title || "Tiêu đề thông báo..."}
                    </div>

                    <div className="text-[10px] text-slate-600 line-clamp-3 leading-tight font-normal">
                      {content || "Nội dung thông báo..."}
                    </div>
                  </div>

                  {/* Inside-app banner card preview */}
                  <div className="bg-[#EA580C] text-white rounded-2xl p-3 shadow-sm text-left space-y-1">
                    <div className="flex items-center justify-between">
                      <span className="text-[9px] font-bold uppercase tracking-wider bg-white/20 px-1.5 py-0.2 rounded">
                        Thông báo mới
                      </span>
                      <span className="text-[9px] opacity-80">vừa gửi</span>
                    </div>
                    <div className="text-[11px] font-bold line-clamp-1">
                      {title || "Tiêu đề thông báo..."}
                    </div>
                    <div className="text-[10px] text-orange-100 line-clamp-2 leading-tight">
                      {content || "Nội dung..."}
                    </div>
                  </div>
                </div>

                {/* Phone Bottom Home Bar / App Navigation */}
                <div className="pt-4 border-t border-slate-200/70 flex items-center justify-around text-slate-400">
                  <span className="text-[#EA580C]">●</span>
                  <span>■</span>
                  <span>▲</span>
                </div>
              </div>
            </div>

            <p className="text-[11px] text-slate-400 text-center">
              Giao diện thông báo xuất hiện đồng thời trên iOS &amp; Android FAP App
            </p>
          </div>

          {/* 3. Send Action Block */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-3">
            <button
              type="button"
              disabled={isSending}
              onClick={handleSend}
              className="w-full bg-[#C2410C] hover:bg-[#9A3412] text-white py-3 px-4 rounded-xl font-bold flex items-center justify-center gap-2 shadow-xs transition cursor-pointer text-sm disabled:opacity-60"
            >
              <Play size={15} fill="currentColor" />
              <span>{isSending ? "Đang phát sóng..." : "Phát thông báo ngay lập tức"}</span>
            </button>

            <div className="grid grid-cols-2 gap-2 text-xs">
              <button
                type="button"
                onClick={handleSaveDraft}
                className="py-2 px-3 bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 rounded-xl font-semibold transition cursor-pointer text-center"
              >
                Lưu bản nháp
              </button>
              <button
                type="button"
                onClick={() => onNavigate("dashboard")}
                className="py-2 px-3 text-slate-500 hover:text-slate-800 rounded-xl font-semibold transition cursor-pointer text-center"
              >
                Hủy bỏ
              </button>
            </div>

            <div className="pt-2 border-t border-slate-100 flex items-center gap-1.5 text-[11px] text-slate-400">
              <Lock size={12} className="text-slate-400 shrink-0" />
              <span>Thao tác được ghi vết nhật ký kiểm toán bởi Admin HL.</span>
            </div>
          </div>
        </div>
      </div>

      {/* History Drawer Modal */}
      {showHistory && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs transition"
            onClick={() => setShowHistory(false)}
          />
          <div className="relative bg-white rounded-2xl shadow-2xl border border-slate-100 w-full max-w-xl overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="p-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/70">
              <div>
                <span className="text-[11px] font-bold text-[#EA580C] uppercase tracking-wider">
                  Lịch sử truyền thông
                </span>
                <h3 className="text-base font-bold text-slate-900 mt-0.5">
                  Các thông báo đã phát sóng gần đây
                </h3>
              </div>
              <button
                onClick={() => setShowHistory(false)}
                className="w-8 h-8 rounded-full hover:bg-slate-200 text-slate-400 hover:text-slate-700 flex items-center justify-center"
              >
                <X size={18} />
              </button>
            </div>

            <div className="p-5 space-y-3 text-xs max-h-[60vh] overflow-y-auto divide-y divide-slate-100">
              {paginatedHistory.length === 0 ? (
                <div className="text-center py-8 text-slate-400">Chưa có lịch sử phát thông báo.</div>
              ) : (
                paginatedHistory.map((item) => (
                  <div key={item.id} className="pt-3 first:pt-0 space-y-1">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-slate-900 text-sm">
                        {item.title}
                      </span>
                      <span className="text-[10px] font-bold bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full border border-emerald-200">
                        Đã gửi ({item.recipientCount} SV)
                      </span>
                    </div>
                    <div className="text-[11px] text-slate-400 flex items-center gap-3">
                      <span>Thời gian: {item.sentAt}</span>
                      <span>•</span>
                      <span>Đối tượng: {item.targetAudience}</span>
                    </div>
                  </div>
                ))
              )}
            </div>
            <Pagination
              currentPage={historyPage}
              totalItems={historyList.length}
              pageSize={10}
              onPageChange={setHistoryPage}
              itemLabel="thông báo"
            />
          </div>
        </div>
      )}
    </div>
  )
}

