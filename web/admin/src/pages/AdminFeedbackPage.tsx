import { useEffect, useMemo, useState } from "react"
import {
  AlertCircle,
  Bug,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Clock3,
  ExternalLink,
  History,
  Lightbulb,
  Loader2,
  MessageSquareText,
  Paperclip,
  RefreshCw,
  Search,
  Send,
  X,
} from "lucide-react"
import {
  getFeedbackAttachmentUrl,
  listFeedback,
  reopenAdminFeedback,
  resolveAdminFeedback,
  type AdminFeedback,
  type FeedbackCategory,
  type FeedbackStatus,
} from "../repositories/feedbackRepository"

const PAGE_SIZE = 10
const CATEGORY_LABEL: Record<FeedbackCategory, string> = {
  bug: "Báo lỗi",
  suggestion: "Góp ý",
  other: "Khác",
}

export function FeedbackInboxPage() {
  return <FeedbackPage status="pending" />
}

export function FeedbackHistoryPage() {
  return <FeedbackPage status="resolved" />
}

function FeedbackPage({ status }: { status: FeedbackStatus }) {
  const [items, setItems] = useState<AdminFeedback[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")
  const [queryText, setQueryText] = useState("")
  const [category, setCategory] = useState<"all" | FeedbackCategory>("all")
  const [page, setPage] = useState(1)
  const [selected, setSelected] = useState<AdminFeedback | null>(null)

  const load = async () => {
    setLoading(true)
    setError("")
    try {
      setItems(await listFeedback(status))
    } catch (loadError) {
      setError(readableError(loadError, "Không thể tải danh sách góp ý."))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    setPage(1)
    setSelected(null)
    void load()
  }, [status])

  const filtered = useMemo(() => {
    const keyword = queryText.trim().toLocaleLowerCase("vi")
    return items.filter((item) => {
      if (category !== "all" && item.category !== category) return false
      if (!keyword) return true
      return [item.message, item.authorName, item.authorEmail, item.memberCode]
        .join(" ")
        .toLocaleLowerCase("vi")
        .includes(keyword)
    })
  }, [category, items, queryText])

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const visibleItems = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  useEffect(() => {
    if (page > totalPages) setPage(totalPages)
  }, [page, totalPages])

  const isPending = status === "pending"

  return (
    <section className="space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="mb-1.5 flex items-center gap-2 text-xs font-bold uppercase tracking-[0.14em] text-[#EA580C]">
            {isPending ? <MessageSquareText size={15} /> : <History size={15} />}
            Phản hồi người dùng
          </div>
          <h1 className="text-2xl font-bold text-slate-900">
            {isPending ? "Tiếp nhận báo lỗi & góp ý" : "Lịch sử góp ý đã xử lý"}
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            {isPending
              ? "Kiểm tra nội dung người dùng gửi, xem tệp đính kèm và phản hồi ngay trên hệ thống."
              : "Tra cứu các phản hồi đã hoàn tất và nội dung quản trị viên đã trả lời."}
          </p>
        </div>
        <button
          type="button"
          onClick={() => void load()}
          disabled={loading}
          className="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-3.5 py-2.5 text-xs font-semibold text-slate-600 shadow-sm transition hover:bg-slate-50 disabled:opacity-50"
        >
          <RefreshCw size={15} className={loading ? "animate-spin" : ""} />
          Tải lại
        </button>
      </div>

      <div className="grid gap-3 sm:grid-cols-3">
        <SummaryCard label={isPending ? "Đang chờ xử lý" : "Đã xử lý"} value={items.length} icon={isPending ? <Clock3 size={20} /> : <CheckCircle2 size={20} />} tone={isPending ? "orange" : "green"} />
        <SummaryCard label="Báo lỗi" value={items.filter((item) => item.category === "bug").length} icon={<Bug size={20} />} tone="red" />
        <SummaryCard label="Góp ý / đề xuất" value={items.filter((item) => item.category === "suggestion").length} icon={<Lightbulb size={20} />} tone="blue" />
      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="flex flex-col gap-3 border-b border-slate-100 p-4 sm:flex-row sm:items-center">
          <label className="relative flex-1">
            <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              value={queryText}
              onChange={(event) => { setQueryText(event.target.value); setPage(1) }}
              placeholder="Tìm theo nội dung, tên, email hoặc mã cán bộ..."
              className="w-full rounded-xl border border-slate-200 py-2.5 pl-10 pr-3 text-sm outline-none transition focus:border-orange-400 focus:ring-2 focus:ring-orange-100"
            />
          </label>
          <select
            value={category}
            onChange={(event) => { setCategory(event.target.value as typeof category); setPage(1) }}
            className="rounded-xl border border-slate-200 bg-white px-3.5 py-2.5 text-sm font-medium text-slate-600 outline-none focus:border-orange-400"
          >
            <option value="all">Tất cả loại</option>
            <option value="bug">Báo lỗi</option>
            <option value="suggestion">Góp ý</option>
            <option value="other">Khác</option>
          </select>
        </div>

        {error ? (
          <div className="m-4 flex items-start gap-2 rounded-xl border border-rose-200 bg-rose-50 p-3 text-sm text-rose-700">
            <AlertCircle size={17} className="mt-0.5 shrink-0" /> {error}
          </div>
        ) : null}

        {loading ? (
          <div className="flex min-h-64 items-center justify-center gap-2 text-sm text-slate-500">
            <Loader2 size={20} className="animate-spin text-[#EA580C]" /> Đang tải dữ liệu...
          </div>
        ) : visibleItems.length === 0 ? (
          <div className="flex min-h-64 flex-col items-center justify-center px-6 text-center">
            <div className="mb-3 rounded-2xl bg-slate-100 p-3 text-slate-400">
              {isPending ? <CheckCircle2 size={28} /> : <History size={28} />}
            </div>
            <p className="font-semibold text-slate-700">{isPending ? "Không còn góp ý chờ xử lý" : "Chưa có lịch sử phù hợp"}</p>
            <p className="mt-1 text-xs text-slate-400">{queryText || category !== "all" ? "Thử thay đổi điều kiện tìm kiếm." : "Dữ liệu mới sẽ xuất hiện tại đây."}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[850px] text-left">
              <thead className="bg-slate-50 text-[11px] font-bold uppercase tracking-wider text-slate-500">
                <tr><th className="px-5 py-3">Người gửi</th><th className="px-5 py-3">Loại</th><th className="px-5 py-3">Nội dung</th><th className="px-5 py-3">Tệp</th><th className="px-5 py-3">{isPending ? "Thời gian gửi" : "Đã xử lý"}</th><th className="px-5 py-3 text-right">Thao tác</th></tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {visibleItems.map((item) => (
                  <tr key={item.id} className="transition hover:bg-slate-50/70">
                    <td className="px-5 py-4"><p className="text-sm font-semibold text-slate-800">{item.authorName}</p><p className="mt-0.5 text-[11px] text-slate-400">{item.memberCode || item.authorEmail || "Không có thông tin"}</p></td>
                    <td className="px-5 py-4"><CategoryBadge category={item.category} /></td>
                    <td className="max-w-md px-5 py-4"><p className="line-clamp-2 text-sm leading-5 text-slate-600">{item.message}</p></td>
                    <td className="px-5 py-4 text-xs font-semibold text-slate-500">{item.attachments.length ? `${item.attachments.length} tệp` : "—"}</td>
                    <td className="px-5 py-4 text-xs text-slate-500">{formatDate(isPending ? item.createdAt : item.resolvedAt)}</td>
                    <td className="px-5 py-4 text-right"><button type="button" onClick={() => setSelected(item)} className="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-600 transition hover:border-orange-200 hover:bg-orange-50 hover:text-[#C2410C]">Xem chi tiết</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {!loading && filtered.length > 0 ? (
          <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3 text-xs text-slate-500">
            <span>Hiển thị {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, filtered.length)} / {filtered.length}</span>
            <div className="flex items-center gap-2"><button type="button" disabled={page === 1} onClick={() => setPage((value) => value - 1)} className="rounded-lg border border-slate-200 p-1.5 disabled:opacity-40"><ChevronLeft size={15} /></button><span className="font-semibold text-slate-700">{page}/{totalPages}</span><button type="button" disabled={page === totalPages} onClick={() => setPage((value) => value + 1)} className="rounded-lg border border-slate-200 p-1.5 disabled:opacity-40"><ChevronRight size={15} /></button></div>
          </div>
        ) : null}
      </div>

      {selected ? <FeedbackDetail item={selected} onClose={() => setSelected(null)} onChanged={async () => { setSelected(null); await load() }} /> : null}
    </section>
  )
}

function FeedbackDetail({ item, onClose, onChanged }: { item: AdminFeedback; onClose: () => void; onChanged: () => Promise<void> }) {
  const [reply, setReply] = useState(item.reply)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState("")

  const submit = async () => {
    if (!reply.trim()) { setError("Vui lòng nhập nội dung phản hồi trước khi hoàn tất."); return }
    setSaving(true); setError("")
    try { await resolveAdminFeedback(item.id, reply.trim()); await onChanged() }
    catch (submitError) { setError(readableError(submitError, "Không thể xử lý góp ý.")); setSaving(false) }
  }

  const reopen = async () => {
    setSaving(true); setError("")
    try { await reopenAdminFeedback(item.id); await onChanged() }
    catch (submitError) { setError(readableError(submitError, "Không thể đưa góp ý về trạng thái chờ.")); setSaving(false) }
  }

  const openAttachment = async (path: string) => {
    setError("")
    try { window.open(await getFeedbackAttachmentUrl(path), "_blank", "noopener,noreferrer") }
    catch (openError) { setError(readableError(openError, "Không thể mở tệp đính kèm.")) }
  }

  return (
    <div className="fixed inset-0 z-[70] flex items-center justify-center bg-slate-950/45 p-4 backdrop-blur-sm" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
      <div role="dialog" aria-modal="true" className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-2xl bg-white shadow-2xl">
        <div className="sticky top-0 z-10 flex items-start justify-between border-b border-slate-100 bg-white px-5 py-4"><div><div className="flex items-center gap-2"><CategoryBadge category={item.category} />{item.status === "resolved" ? <span className="rounded-full bg-emerald-50 px-2 py-1 text-[10px] font-bold text-emerald-700">Đã xử lý</span> : null}</div><h2 className="mt-2 text-lg font-bold text-slate-900">Chi tiết phản hồi</h2></div><button type="button" onClick={onClose} className="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600"><X size={19} /></button></div>
        <div className="space-y-5 p-5">
          <div className="grid gap-3 rounded-xl bg-slate-50 p-4 text-sm sm:grid-cols-2"><div><p className="text-[11px] font-bold uppercase text-slate-400">Người gửi</p><p className="mt-1 font-semibold text-slate-800">{item.authorName}</p><p className="text-xs text-slate-500">{item.memberCode || item.authorEmail || item.authorUid}</p></div><div><p className="text-[11px] font-bold uppercase text-slate-400">Thời gian gửi</p><p className="mt-1 font-medium text-slate-700">{formatDate(item.createdAt)}</p></div></div>
          <div><p className="mb-2 text-xs font-bold uppercase tracking-wide text-slate-500">Nội dung</p><div className="whitespace-pre-wrap rounded-xl border border-slate-200 p-4 text-sm leading-6 text-slate-700">{item.message}</div></div>
          {item.attachments.length ? <div><p className="mb-2 flex items-center gap-1.5 text-xs font-bold uppercase tracking-wide text-slate-500"><Paperclip size={14} /> Tệp đính kèm</p><div className="flex flex-wrap gap-2">{item.attachments.map((path, index) => <button key={path} type="button" onClick={() => void openAttachment(path)} className="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-600 hover:border-orange-200 hover:bg-orange-50 hover:text-[#C2410C]">Tệp {index + 1}<ExternalLink size={13} /></button>)}</div></div> : null}
          {item.status === "pending" ? <div><label htmlFor="feedback-reply" className="mb-2 block text-xs font-bold uppercase tracking-wide text-slate-500">Phản hồi cho người gửi</label><textarea id="feedback-reply" value={reply} onChange={(event) => setReply(event.target.value)} maxLength={4000} rows={5} placeholder="Nhập kết quả xử lý hoặc hướng dẫn cho người gửi..." className="w-full resize-y rounded-xl border border-slate-200 p-3 text-sm outline-none focus:border-orange-400 focus:ring-2 focus:ring-orange-100"/><p className="mt-1 text-right text-[11px] text-slate-400">{reply.length}/4000</p></div> : <div><p className="mb-2 text-xs font-bold uppercase tracking-wide text-slate-500">Phản hồi của quản trị viên</p><div className="whitespace-pre-wrap rounded-xl border border-emerald-100 bg-emerald-50/60 p-4 text-sm leading-6 text-slate-700">{item.reply || "Không có nội dung phản hồi."}</div><p className="mt-1.5 text-xs text-slate-400">Hoàn tất: {formatDate(item.resolvedAt)}</p></div>}
          {error ? <div className="flex gap-2 rounded-xl bg-rose-50 p-3 text-sm text-rose-700"><AlertCircle size={17} className="shrink-0" />{error}</div> : null}
        </div>
        <div className="sticky bottom-0 flex justify-end gap-2 border-t border-slate-100 bg-white px-5 py-4"><button type="button" onClick={onClose} disabled={saving} className="rounded-xl border border-slate-200 px-4 py-2.5 text-xs font-semibold text-slate-600">Đóng</button>{item.status === "pending" ? <button type="button" onClick={() => void submit()} disabled={saving || !reply.trim()} className="inline-flex items-center gap-2 rounded-xl bg-[#EA580C] px-4 py-2.5 text-xs font-bold text-white hover:bg-[#C2410C] disabled:opacity-50">{saving ? <Loader2 size={15} className="animate-spin" /> : <Send size={15} />} Phản hồi & hoàn tất</button> : <button type="button" onClick={() => void reopen()} disabled={saving} className="inline-flex items-center gap-2 rounded-xl border border-amber-200 bg-amber-50 px-4 py-2.5 text-xs font-bold text-amber-700 disabled:opacity-50">{saving ? <Loader2 size={15} className="animate-spin" /> : <RefreshCw size={15} />} Mở lại xử lý</button>}</div>
      </div>
    </div>
  )
}

function CategoryBadge({ category }: { category: FeedbackCategory }) {
  const styles = category === "bug" ? "bg-rose-50 text-rose-700" : category === "suggestion" ? "bg-blue-50 text-blue-700" : "bg-slate-100 text-slate-600"
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-[11px] font-bold ${styles}`}>{CATEGORY_LABEL[category]}</span>
}

function SummaryCard({ label, value, icon, tone }: { label: string; value: number; icon: React.ReactNode; tone: "orange" | "green" | "red" | "blue" }) {
  const styles = { orange: "bg-orange-50 text-orange-600", green: "bg-emerald-50 text-emerald-600", red: "bg-rose-50 text-rose-600", blue: "bg-blue-50 text-blue-600" }[tone]
  return <div className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"><span className={`rounded-xl p-2.5 ${styles}`}>{icon}</span><div><p className="text-2xl font-bold text-slate-900">{value}</p><p className="text-xs font-medium text-slate-500">{label}</p></div></div>
}

function formatDate(date: Date | null) {
  return date ? new Intl.DateTimeFormat("vi-VN", { dateStyle: "short", timeStyle: "short" }).format(date) : "Chưa xác định"
}

function readableError(error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback
  const message = error.message.replace(/^Firebase:\s*/i, "").replace(/\s*\(functions\/[\w-]+\)\.?$/i, "")
  return message || fallback
}
