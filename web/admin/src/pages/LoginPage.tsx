import { useMemo, useState, type ReactNode } from "react"
import {
  Archive,
  Bell,
  BookOpen,
  CalendarDays,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  CircleAlert,
  Clock3,
  FileCheck2,
  GraduationCap,
  Inbox,
  LayoutDashboard,
  LoaderCircle,
  LogOut,
  Menu,
  MessageSquareText,
  MoreHorizontal,
  Pencil,
  Plus,
  Search,
  Send,
  ShieldCheck,
  SlidersHorizontal,
  Sparkles,
  Users,
  WifiOff,
  X,
  XCircle,
} from "lucide-react"
import { campusPhoto } from "../data/mock-data"
import type { LoginState } from "../types/admin"
import { Button, Logo } from "../components/ui"
export function Login({ onLogin }: { onLogin: () => void }) {
  const [state, setState] = useState<LoginState>("idle")
  const login = () => {
    setState("loading")
    window.setTimeout(() => {
      setState("idle")
      onLogin()
    }, 850)
  }
  const errorContent = {
    wrong: [
      "Không đúng tài khoản",
      "Vui lòng sử dụng email do FPT Education cấp.",
    ],
    denied: [
      "Bạn chưa có quyền truy cập",
      "Hệ thống chỉ dành cho Staff và Admin.",
    ],
    network: ["Không thể kết nối", "Kiểm tra mạng và thử lại sau ít phút."],
  }

  return (
    <main className="login-page">
      <section
        className="login-visual"
        style={{
          backgroundImage: `linear-gradient(180deg, rgba(9,25,39,.08), rgba(9,25,39,.68)), url(${campusPhoto})`,
        }}
      >
        <Logo inverse />
        <div className="visual-copy">
          <span className="eyebrow-light">
            FPT EDUCATION · ACADEMIC OPERATIONS
          </span>
          <h1>
            Chuyên cần minh bạch.
            <br />
            Vận hành hiệu quả.
          </h1>
          <p>
            Một không gian tập trung để Phòng Đào tạo theo dõi, xác minh và quản
            lý dữ liệu check-in.
          </p>
        </div>
        <span className="photo-credit">Ảnh: Khoi Do / Unsplash</span>
      </section>
      <section className="login-panel">
        <div className="mobile-login-logo">
          <Logo />
        </div>
        <div className="login-card">
          <span className="login-icon">
            <ShieldCheck size={26} />
          </span>
          <div>
            <span className="eyebrow">CỔNG QUẢN TRỊ</span>
            <h2>Chào mừng trở lại</h2>
            <p className="muted">
              Đăng nhập bằng tài khoản Google của FPT Education để tiếp tục.
            </p>
          </div>
          {state !== "idle" && state !== "loading" && (
            <div className="login-error">
              {state === "network" ? (
                <WifiOff size={19} />
              ) : state === "denied" ? (
                <ShieldCheck size={19} />
              ) : (
                <CircleAlert size={19} />
              )}
              <div>
                <b>{errorContent[state][0]}</b>
                <span>{errorContent[state][1]}</span>
              </div>
            </div>
          )}
          <Button
            className="google-btn"
            variant="secondary"
            onClick={login}
            disabled={state === "loading"}
            icon={
              state === "loading" ? (
                <LoaderCircle className="spin" size={19} />
              ) : (
                <span className="google-g">G</span>
              )
            }
          >
            {state === "loading" ? "Đang xác thực..." : "Tiếp tục với Google"}
          </Button>
          <div className="login-note">
            <ShieldCheck size={16} />
            <span>Chỉ Staff/Admin được cấp quyền mới có thể truy cập.</span>
          </div>
          <details className="state-preview">
            <summary>Xem trạng thái lỗi</summary>
            <div>
              <button onClick={() => setState("wrong")}>Sai tài khoản</button>
              <button onClick={() => setState("denied")}>Không có quyền</button>
              <button onClick={() => setState("network")}>Lỗi mạng</button>
            </div>
          </details>
        </div>
        <p className="login-footer">
          © 2025 FPT Education · Chính sách bảo mật · Trợ giúp
        </p>
      </section>
    </main>
  )
}


