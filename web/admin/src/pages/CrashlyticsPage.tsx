import { Activity, ExternalLink, Info, RotateCcw, Smartphone } from "lucide-react"

const CRASHLYTICS_URL =
  "https://console.firebase.google.com/project/ducminh-41459/crashlytics/app/android:com.example.fapcheckin/issues"

export function CrashlyticsPage() {
  return (
    <div className="space-y-6 text-slate-800">
      <div>
        <div className="flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-orange-50 text-[#EA580C]">
            <Activity size={22} />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              Firebase Crashlytics
            </h1>
            <p className="mt-1 text-xs text-slate-400">
              Theo dõi lỗi nghiêm trọng và độ ổn định của ứng dụng di động.
            </p>
          </div>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-100 bg-white p-6 shadow-xs">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
          <div className="max-w-2xl space-y-3">
            <h2 className="text-base font-bold text-slate-900">
              Xem báo cáo trong Firebase Console
            </h2>
            <p className="text-sm leading-6 text-slate-500">
              Crashlytics được Firebase lưu và phân tích riêng, không nằm trong
              Firestore. Quản trị viên mở Firebase Console để xem stack trace,
              phiên bản ứng dụng, thiết bị và số người dùng bị ảnh hưởng.
            </p>
          </div>
          <a
            href={CRASHLYTICS_URL}
            target="_blank"
            rel="noreferrer"
            className="inline-flex h-11 shrink-0 items-center justify-center gap-2 rounded-xl bg-[#C2410C] px-5 text-sm font-semibold text-white transition hover:bg-[#9A3412]"
          >
            Mở Firebase Crashlytics
            <ExternalLink size={16} />
          </a>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <StepCard
          icon={<Smartphone size={19} />}
          title="1. Tạo lỗi kiểm thử"
          description="Trong app, vào Cài đặt & Trợ giúp và nhấn Tạo crash kiểm thử."
        />
        <StepCard
          icon={<RotateCcw size={19} />}
          title="2. Mở lại ứng dụng"
          description="Sau khi app đóng, mở lại để Crashlytics gửi báo cáo đang chờ."
        />
        <StepCard
          icon={<Info size={19} />}
          title="3. Chờ Firebase xử lý"
          description="Báo cáo đầu tiên thường cần vài phút trước khi xuất hiện trên Console."
        />
      </div>

      <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs leading-5 text-amber-900">
        Tài khoản quản trị cần được cấp quyền truy cập dự án Firebase
        <strong> ducminh-41459</strong> để xem báo cáo.
      </div>
    </div>
  )
}

function StepCard({
  icon,
  title,
  description,
}: {
  icon: React.ReactNode
  title: string
  description: string
}) {
  return (
    <div className="rounded-2xl border border-slate-100 bg-white p-5 shadow-xs">
      <div className="mb-3 flex h-9 w-9 items-center justify-center rounded-lg bg-orange-50 text-[#EA580C]">
        {icon}
      </div>
      <h3 className="text-sm font-bold text-slate-900">{title}</h3>
      <p className="mt-1.5 text-xs leading-5 text-slate-500">{description}</p>
    </div>
  )
}
