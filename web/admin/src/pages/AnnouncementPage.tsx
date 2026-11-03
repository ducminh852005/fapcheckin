import { useCallback, useEffect, useMemo, useRef, useState } from "react"
import { Pagination } from "../components/Pagination"
import { useAsyncData } from "../hooks/useAsyncData"
import {
  AlertCircle,
  Bell,
  Bold,
  Check,
  CheckCircle2,
  ChevronDown,
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
  const targetAudience = "teachers" as const
  const [priority, setPriority] = useState<"normal" | "important" | "urgent">(
    "urgent"
  )
  const [content, setContent] = useState(
    "Kính gửi quý Thầy Cô, đề nghị kiểm tra lịch dạy và phòng học cập nhật trực tiếp trên ứng dụng FAP Check-in trước giờ vào ca."
  )
  const [contentText, setContentText] = useState(content)
  const [pinToTop, setPinToTop] = useState(false)

  // Feedback State
  const [isSending, setIsSending] = useState(false)
  const [toastMessage, setToastMessage] = useState<string | null>(null)
  const [showHistory, setShowHistory] = useState(false)
  const [historyList, setHistoryList] = useState<AnnouncementHistoryItem[]>([])
  const [historyPage, setHistoryPage] = useState(1)
  const contentRef = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (contentRef.current && !contentRef.current.textContent) {
      contentRef.current.textContent = contentText
    }
  }, [])
  const paginatedHistory = useMemo(() => {
    const start = (historyPage - 1) * 10
    return historyList.slice(start, start + 10)
  }, [historyList, historyPage])

  const estimatedRecipients = targetsData?.teacherCount ?? 0

  const showToast = (msg: string) => {
    setToastMessage(msg)
    setTimeout(() => setToastMessage(null), 3500)
  }

  const handleSend = async () => {
    if (!title.trim() || !contentText.trim()) {
      showToast("Vui lòng nhập đầy đủ tiêu đề và nội dung thông báo.")
      return
    }
    setIsSending(true)
    try {
      await sendAnnouncement({
        title,
        content: contentText,
        richContent: content,
        targetAudience,
        priority,
        pinToTop,
        recipientCount: estimatedRecipients,
        createdBy: adminEmail,
      })
      showToast(`Đã đăng thông báo cho ${estimatedRecipients.toLocaleString("vi-VN")} giảng viên.`)
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
        content: contentText,
        richContent: content,
        targetAudience,
        priority,
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

  const syncEditorContent = () => {
    const editor = contentRef.current
    if (!editor) return
    const text = editor.innerText.replace(/\u00a0/g, " ")
    if (text.length > 1000) {
      editor.innerText = text.slice(0, 1000)
      placeCaretAtEnd(editor)
    }
    setContent(editor.innerHTML)
    setContentText(editor.innerText.replace(/\u00a0/g, " ").slice(0, 1000))
  }

  const applyFormat = (command: "bold" | "italic" | "underline" | "insertUnorderedList" | "insertOrderedList") => {
    contentRef.current?.focus()
    document.execCommand(command)
    syncEditorContent()
  }

  const insertLink = () => {
    const url = window.prompt("Nhập địa chỉ liên kết (https://…):")?.trim()
    if (!url) return
    if (!/^https?:\/\//i.test(url)) {
      showToast("Liên kết phải bắt đầu bằng http:// hoặc https://")
      return
    }
    contentRef.current?.focus()
    const selection = window.getSelection()
    if (!selection || selection.isCollapsed) {
      document.execCommand("insertHTML", false, `<a href="${escapeHtml(url)}" target="_blank" rel="noreferrer">${escapeHtml(url)}</a>`)
    } else {
      document.execCommand("createLink", false, url)
    }
    syncEditorContent()
  }

  const insertVariable = (tag: string) => {
    contentRef.current?.focus()
    document.execCommand("insertText", false, tag)
    syncEditorContent()
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
            Gửi thông tin tức thời hoặc hẹn giờ phát sóng tới giảng viên trên ứng dụng FAP Mobile.
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
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs">
            <div className="flex items-center gap-3 rounded-xl border border-orange-200 bg-orange-50 p-4">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white text-[#EA580C] shadow-xs">
                <GraduationCap size={20} />
              </div>
              <div>
                <div className="text-xs font-bold text-slate-900">Gửi tới toàn bộ giảng viên</div>
                <div className="mt-1 text-[11px] text-slate-500">
                  {(targetsData?.teacherCount ?? 0).toLocaleString("vi-VN")} tài khoản giảng viên trên FAP Mobile
                </div>
              </div>
            </div>
          </div>

          {/* 3. Mức độ ưu tiên */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs">
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

          </div>

          {/* 4. Nội dung thông báo */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-3">
            <div className="flex items-center justify-between text-xs">
              <label className="font-bold text-slate-800">
                Nội dung thông báo <span className="text-[#EA580C]">*</span>
              </label>
              <span className="text-slate-400 text-[11px]">
                {contentText.length} / 1000 ký tự
              </span>
            </div>

            {/* Formatting Toolbar */}
            <div className="flex flex-wrap items-center justify-between gap-2 p-2 bg-slate-50 border border-slate-200/80 rounded-xl">
              <div className="flex items-center gap-1 text-slate-600">
                <button
                  type="button"
                  title="In đậm"
                  onMouseDown={(event) => {
                    event.preventDefault()
                    applyFormat("bold")
                  }}
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center font-bold text-xs"
                >
                  <Bold size={13} />
                </button>
                <button
                  type="button"
                  title="In nghiêng"
                  onMouseDown={(event) => {
                    event.preventDefault()
                    applyFormat("italic")
                  }}
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center text-xs"
                >
                  <Italic size={13} />
                </button>
                <button
                  type="button"
                  title="Gạch chân"
                  onMouseDown={(event) => {
                    event.preventDefault()
                    applyFormat("underline")
                  }}
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center text-xs"
                >
                  <Underline size={13} />
                </button>
                <span className="h-4 w-px bg-slate-300 mx-1" />
                <button
                  type="button"
                  title="Danh sách gạch đầu dòng"
                  onMouseDown={(event) => {
                    event.preventDefault()
                    applyFormat("insertUnorderedList")
                  }}
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center"
                >
                  <List size={13} />
                </button>
                <button
                  type="button"
                  title="Danh sách số"
                  onMouseDown={(event) => {
                    event.preventDefault()
                    applyFormat("insertOrderedList")
                  }}
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center"
                >
                  <ListOrdered size={13} />
                </button>
                <button
                  type="button"
                  title="Chèn liên kết"
                  onMouseDown={(event) => {
                    event.preventDefault()
                    insertLink()
                  }}
                  className="w-7 h-7 rounded hover:bg-slate-200 flex items-center justify-center"
                >
                  <Link2 size={13} />
                </button>
              </div>

              {/* Dynamic Variables */}
              <div className="flex items-center gap-1.5 text-[11px]">
                <span className="text-slate-400 font-medium">Chèn biến động:</span>
                {[
                  { tag: "[teacher_name]", label: "[teacher_name]" },
                  { tag: "[class_id]", label: "[class_id]" },
                  { tag: "[room_number]", label: "[room_number]" },
                ].map((item) => (
                  <button
                    key={item.tag}
                    type="button"
                    onMouseDown={(event) => {
                      event.preventDefault()
                      insertVariable(item.tag)
                    }}
                    className="px-2 py-0.5 rounded bg-white border border-slate-200 text-slate-700 hover:border-[#EA580C] hover:text-[#EA580C] font-mono text-[10px] transition cursor-pointer"
                  >
                    {item.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Rich-text editor */}
            <div
              ref={contentRef}
              contentEditable
              suppressContentEditableWarning
              role="textbox"
              aria-multiline="true"
              aria-label="Nội dung thông báo"
              onInput={syncEditorContent}
              onPaste={(event) => {
                event.preventDefault()
                document.execCommand("insertText", false, event.clipboardData.getData("text/plain"))
                syncEditorContent()
              }}
              className="min-h-[156px] w-full overflow-y-auto text-xs text-slate-800 leading-relaxed bg-slate-50/70 border border-slate-200 rounded-xl p-3.5 focus:outline-none focus:border-[#EA580C] focus:bg-white transition [&_a]:text-blue-600 [&_a]:underline [&_ol]:list-decimal [&_ol]:pl-5 [&_ul]:list-disc [&_ul]:pl-5"
            />
          </div>

          {/* 5. Tùy chọn hiển thị */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-4">
            <h3 className="text-xs font-bold text-slate-800">
              Tùy chọn hiển thị
            </h3>
            <div className="flex items-center justify-between">
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
                role="switch"
                aria-checked={pinToTop}
                aria-label="Ghim thông báo lên đầu bảng tin"
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
                  {(targetsData?.linkedTeachers ?? 0).toLocaleString("vi-VN")}
                </div>
                <div className="text-[10px] text-slate-400 mt-0.5">
                  Nhận thông báo tức thời
                </div>
              </div>
            </div>

          </div>

          {/* 2. Xem trước trong ứng dụng giảng viên */}
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-xs space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Smartphone size={16} className="text-[#EA580C]" />
                <span className="text-xs font-bold text-slate-900">
                  Xem trước trong app giảng viên
                </span>
              </div>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                Xem trước
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
                    <span className="text-[9px]">FAP GV</span>
                  </div>
                </div>

                {/* In-app announcement preview */}
                <div className="space-y-3">
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
                      {contentText || "Nội dung..."}
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
              Nội dung hiển thị trong bảng thông báo của ứng dụng giảng viên.
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
              <span>
                {isSending ? "Đang xử lý..." : "Đăng thông báo cho giảng viên"}
              </span>
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
                        {item.status === "draft"
                          ? "Bản nháp"
                          : item.status === "scheduled"
                            ? "Lịch cũ (chưa đăng)"
                            : `Đã gửi (${item.recipientCount} GV)`}
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

function placeCaretAtEnd(element: HTMLElement) {
  const range = document.createRange()
  range.selectNodeContents(element)
  range.collapse(false)
  const selection = window.getSelection()
  selection?.removeAllRanges()
  selection?.addRange(range)
}

function escapeHtml(value: string) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
}

