import { useCallback, useState } from "react"
import {
  Activity,
  AlertTriangle,
  Bug,
  ExternalLink,
  RefreshCw,
  Settings,
  Smartphone,
  Users,
} from "lucide-react"
import { useAsyncData } from "../hooks/useAsyncData"
import { getCrashlyticsData, type CrashlyticsIssue } from "../repositories/crashlyticsRepository"

const CRASHLYTICS_URL =
  "https://console.firebase.google.com/project/ducminh-41459/crashlytics/app/android:com.example.fapcheckin/issues?time=7d&state=open&types=crash"
const INTEGRATIONS_URL =
  "https://console.firebase.google.com/project/ducminh-41459/settings/integrations"

export function CrashlyticsPage() {
  const [days, setDays] = useState(7)
  const loader = useCallback(() => getCrashlyticsData(days), [days])
  const { data, loading, error, reload } = useAsyncData(loader)
  const needsSetup = error?.includes("BigQuery") || error?.toLowerCase().includes("export")

  return (
    <div className="space-y-6 text-slate-800">
      <header className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-orange-50 text-[#EA580C]">
            <Activity size={22} />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">Firebase Crashlytics</h1>
            <p className="mt-1 text-xs text-slate-500">
              Fatal crashes của ứng dụng Android com.example.fapcheckin.
            </p>
          </div>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <select
            value={days}
            onChange={(event) => setDays(Number(event.target.value))}
            className="h-10 rounded-xl border border-slate-200 bg-white px-3 text-xs font-semibold text-slate-700 outline-none focus:border-orange-400"
            aria-label="Khoảng thời gian"
          >
            <option value={1}>24 giờ qua</option>
            <option value={7}>7 ngày qua</option>
            <option value={30}>30 ngày qua</option>
            <option value={90}>90 ngày qua</option>
          </select>
          <button
            type="button"
            onClick={reload}
            disabled={loading}
            className="inline-flex h-10 items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 text-xs font-semibold text-slate-700 transition hover:bg-slate-50 disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} /> Làm mới
          </button>
          <a
            href={CRASHLYTICS_URL}
            target="_blank"
            rel="noreferrer"
            className="inline-flex h-10 items-center gap-2 rounded-xl bg-[#C2410C] px-4 text-xs font-semibold text-white transition hover:bg-[#9A3412]"
          >
            Firebase Console <ExternalLink size={14} />
          </a>
        </div>
      </header>

      {error && <SetupOrError error={error} needsSetup={Boolean(needsSetup)} onRetry={reload} />}

      <section className="grid gap-4 sm:grid-cols-3">
        <MetricCard icon={<Bug size={19} />} label="Fatal crash events" value={loading ? "…" : data?.totals.events ?? 0} tone="rose" />
        <MetricCard icon={<Users size={19} />} label="Người dùng bị ảnh hưởng" value={loading ? "…" : data?.totals.users ?? 0} tone="amber" />
        <MetricCard icon={<AlertTriangle size={19} />} label="Nhóm sự cố" value={loading ? "…" : data?.totals.issues ?? 0} tone="orange" />
      </section>

      <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xs">
        <div className="flex flex-col gap-2 border-b border-slate-100 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-sm font-bold text-slate-900">Sự cố theo số lần xảy ra</h2>
            <p className="mt-0.5 text-[11px] text-slate-500">
              Dữ liệu fatal từ BigQuery; trạng thái Open/Closed vẫn được quản lý trong Firebase Console.
            </p>
          </div>
          {data && (
            <span className="text-[11px] text-slate-400">
              {data.source === "bigquery-realtime" ? "Realtime export" : "Daily export"} · cập nhật {formatDate(data.updatedAt)}
            </span>
          )}
        </div>

        {loading ? (
          <div className="space-y-3 p-5">
            {[1, 2, 3].map((item) => <div key={item} className="h-16 animate-pulse rounded-xl bg-slate-100" />)}
          </div>
        ) : data?.issues.length ? (
          <div className="divide-y divide-slate-100">
            {data.issues.map((issue) => <IssueRow key={issue.id} issue={issue} />)}
          </div>
        ) : (
          <div className="px-5 py-16 text-center">
            <Smartphone size={28} className="mx-auto text-emerald-500" />
            <h3 className="mt-3 text-sm font-bold text-slate-800">Không có fatal crash</h3>
            <p className="mt-1 text-xs text-slate-500">
              Không tìm thấy sự cố fatal trong {days} ngày qua, hoặc dữ liệu export chưa đồng bộ.
            </p>
          </div>
        )}
      </section>
    </div>
  )
}

function SetupOrError({ error, needsSetup, onRetry }: { error: string; needsSetup: boolean; onRetry: () => void }) {
  return (
    <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-amber-950">
      <div className="flex items-start gap-3">
        <Settings size={20} className="mt-0.5 shrink-0" />
        <div className="min-w-0 flex-1">
          <h2 className="text-sm font-bold">{needsSetup ? "Cần bật Crashlytics export sang BigQuery" : "Không thể tải Crashlytics"}</h2>
          <p className="mt-1 text-xs leading-5">{error}</p>
          <div className="mt-3 flex flex-wrap gap-2">
            {needsSetup && (
              <a href={INTEGRATIONS_URL} target="_blank" rel="noreferrer" className="inline-flex h-9 items-center gap-2 rounded-lg bg-amber-900 px-3 text-xs font-semibold text-white">
                Mở Firebase Integrations <ExternalLink size={13} />
              </a>
            )}
            <button type="button" onClick={onRetry} className="h-9 rounded-lg border border-amber-300 px-3 text-xs font-semibold">Thử lại</button>
          </div>
        </div>
      </div>
    </div>
  )
}

function IssueRow({ issue }: { issue: CrashlyticsIssue }) {
  return (
    <a
      href={CRASHLYTICS_URL}
      target="_blank"
      rel="noreferrer"
      className="grid gap-3 px-5 py-4 transition hover:bg-slate-50 sm:grid-cols-[minmax(0,1fr)_100px_80px_115px] sm:items-center"
    >
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <span className="rounded-md bg-rose-50 px-1.5 py-0.5 text-[10px] font-bold text-rose-700">FATAL</span>
          <h3 className="truncate text-xs font-bold text-slate-900">{issue.title}</h3>
        </div>
        <p className="mt-1 truncate text-[11px] text-slate-500">{issue.subtitle || `Issue ${issue.id}`}</p>
      </div>
      <div className="text-xs text-slate-600"><span className="sm:hidden">Phiên bản: </span>{issue.version}</div>
      <div className="text-xs"><b className="text-slate-900">{issue.eventCount}</b> <span className="text-slate-400">events</span></div>
      <div className="text-[11px] text-slate-500">{issue.userCount} users · {formatDate(issue.lastSeen)}</div>
    </a>
  )
}

function MetricCard({ icon, label, value, tone }: { icon: React.ReactNode; label: string; value: number | string; tone: "rose" | "amber" | "orange" }) {
  const colors = { rose: "bg-rose-50 text-rose-600", amber: "bg-amber-50 text-amber-600", orange: "bg-orange-50 text-orange-600" }
  return (
    <div className="flex items-center justify-between rounded-2xl border border-slate-200 bg-white p-5 shadow-xs">
      <div><p className="text-xs font-medium text-slate-500">{label}</p><p className="mt-1 text-3xl font-extrabold text-slate-900">{value}</p></div>
      <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${colors[tone]}`}>{icon}</div>
    </div>
  )
}

function formatDate(value: string | null) {
  if (!value) return "—"
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return "—"
  return new Intl.DateTimeFormat("vi-VN", { day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit" }).format(date)
}
