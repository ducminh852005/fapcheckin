import { CircleAlert, LoaderCircle, ShieldCheck } from "lucide-react"
import { Button, Logo } from "../components/ui"

const campusPhoto = "https://images.unsplash.com/photo-1709949906671-de1000f3d9c8?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=88&w=1600"

export function AdminLogin({ loading, error, onLogin }: {
  loading: boolean
  error: string | null
  onLogin: () => Promise<void>
}) {
  return (
    <main className="login-page admin-login">
      <section className="login-visual" style={{ backgroundImage: `linear-gradient(180deg, rgba(9,25,39,.08), rgba(9,25,39,.72)), url(${campusPhoto})` }}>
        <Logo inverse />
        <div className="visual-copy">
          <span className="eyebrow-light">FPT EDUCATION · SYSTEM OPERATIONS</span>
          <h1>Vận hành rõ ràng.<br />Dữ liệu nhất quán.</h1>
          <p>Không gian dành riêng cho quản trị tài khoản, dữ liệu học vụ và hệ thống điểm danh.</p>
        </div>
        <span className="photo-credit">FAP Check-in Administration</span>
      </section>
      <section className="login-panel">
        <div className="mobile-login-logo"><Logo /></div>
        <div className="login-card">
          <span className="login-icon"><ShieldCheck size={26} /></span>
          <div><span className="eyebrow">CỔNG QUẢN TRỊ</span><h2>Đăng nhập quản trị</h2><p className="muted">Chỉ tài khoản có vai trò Admin và đang hoạt động mới được phép truy cập.</p></div>
          {error && <div className="login-error"><CircleAlert size={19} /><div><b>Không thể truy cập</b><span>{error}</span></div></div>}
          <Button className="google-btn" variant="secondary" onClick={() => void onLogin()} disabled={loading} icon={loading ? <LoaderCircle className="spin" size={19} /> : <span className="google-g">G</span>}>{loading ? "Đang xác thực..." : "Tiếp tục với Google"}</Button>
          <div className="login-note"><ShieldCheck size={16} /><span>Chỉ hồ sơ có role admin và active = true được phép truy cập.</span></div>
        </div>
        <p className="login-footer">© 2026 FPT Education · FAP Check-in</p>
      </section>
    </main>
  )
}
