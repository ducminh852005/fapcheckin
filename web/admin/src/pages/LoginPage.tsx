import { useState } from "react"
import {
  ArrowLeft,
  CircleAlert,
  LoaderCircle,
  ShieldCheck,
  WifiOff,
} from "lucide-react"
import type { LoginState } from "../types/admin"

export function Login({ onLogin }: { onLogin: () => void }) {
  const [state, setState] = useState<LoginState>("idle")
  const [isEmailMode, setIsEmailMode] = useState(false)
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")

  const handleLogin = (_provider?: string) => {
    setState("loading")
    window.setTimeout(() => {
      setState("idle")
      onLogin()
    }, 850)
  }

  const handleEmailSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    handleLogin("email")
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
    <main className="relative w-full h-screen min-h-screen overflow-hidden flex items-center justify-center select-none">
      {/* 1. Nền tràn viền toàn màn hình: Hình ảnh trường FPT HCM Campus */}
      <div className="absolute inset-0 w-full h-full">
        <img
          src="/fpt_hcm_campus.jpg"
          alt="Cơ sở Đại học FPT TP.HCM"
          className="w-full h-full object-cover object-center"
        />
        {/* Lớp phủ gradient nhẹ nhàng, giữ ảnh trường sáng rõ và sắc nét */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background:
              "linear-gradient(135deg, rgba(15, 23, 42, 0.25) 0%, rgba(15, 23, 42, 0.08) 50%, rgba(15, 23, 42, 0.3) 100%)",
          }}
        />
      </div>

      {/* 2. Chú thích góc dưới bên trái */}
      <div className="hidden xl:block absolute left-10 bottom-10 z-10 text-white max-w-md pointer-events-none">
        <p className="text-xs font-bold uppercase tracking-wider text-[#FED7AA] mb-1.5 drop-shadow-md">
          CƠ SỞ GIẢNG ĐƯỜNG &amp; THƯ VIỆN SỐ
        </p>
        <p className="text-sm font-medium text-slate-100 drop-shadow-md leading-relaxed">
          Môi trường học tập chủ động và sáng tạo không ngừng
        </p>
      </div>

      {/* 3. Popup đăng nhập nổi ở chính giữa màn hình với độ trong suốt cao nhìn thấu trường học phía sau */}
      <section className="relative z-20 w-full max-w-[540px] mx-4 sm:mx-6 my-auto">
        <div className="w-full bg-white/20 backdrop-blur-xs rounded-3xl sm:rounded-[32px] shadow-[0_20px_60px_-10px_rgba(0,0,0,0.35)] border border-white/50 p-6 sm:px-9 sm:py-9 flex flex-col justify-between max-h-[94vh] overflow-y-auto">
          {/* Logo FPT Education */}
          <div className="flex items-center justify-center sm:justify-start w-full mb-6">
            <img
              src="/fpt_logo.png"
              alt="FPT Education - TRƯỜNG ĐẠI HỌC FPT"
              className="h-10 sm:h-12 w-auto object-contain drop-shadow-sm"
            />
          </div>

          {/* Tiêu đề & Lời chào */}
          <div className="w-full text-center">
            <h1 className="text-lg sm:text-[22px] md:text-[25px] font-black text-[#9A3412] tracking-tight leading-tight mb-2.5 drop-shadow-[0_1px_2px_rgba(255,255,255,0.7)] whitespace-nowrap">
              Hệ thống điểm danh FAP
            </h1>
            <p className="text-xs sm:text-[13.5px] text-slate-800 font-semibold leading-relaxed mb-7 max-w-[420px] mx-auto drop-shadow-[0_1px_1px_rgba(255,255,255,0.5)]">
              Dành cho Cán bộ, Giảng viên &amp; Sinh viên Đại học FPT.
              <br />
              Vui lòng sử dụng tài khoản nội bộ để tiếp tục.
            </p>

            {/* Error banner if state error */}
            {state !== "idle" && state !== "loading" && (
              <div className="mb-5 p-3 rounded-xl bg-red-50/95 backdrop-blur-xs border border-red-200 text-red-700 flex items-center gap-3 text-left shadow-sm">
                {state === "network" ? (
                  <WifiOff className="w-5 h-5 shrink-0 text-red-600" />
                ) : state === "denied" ? (
                  <ShieldCheck className="w-5 h-5 shrink-0 text-red-600" />
                ) : (
                  <CircleAlert className="w-5 h-5 shrink-0 text-red-600" />
                )}
                <div>
                  <b className="block text-xs font-semibold">
                    {errorContent[state][0]}
                  </b>
                  <span className="block text-[11px] text-red-600/90 mt-0.5">
                    {errorContent[state][1]}
                  </span>
                </div>
              </div>
            )}

            {!isEmailMode ? (
              <div className="w-full max-w-[340px] sm:max-w-[360px] mx-auto flex flex-col gap-3">
                {/* Button 1: Tiếp tục với Google */}
                <button
                  type="button"
                  onClick={() => handleLogin("google")}
                  disabled={state === "loading"}
                  className="w-full h-11 sm:h-12 rounded-full border border-white/80 bg-white/85 hover:bg-white hover:border-[#9A3412] text-[#1E293B] font-semibold text-sm transition-all duration-150 flex items-center justify-center gap-3 shadow-md disabled:opacity-60 cursor-pointer"
                >
                  {state === "loading" ? (
                    <LoaderCircle className="w-5 h-5 animate-spin text-[#9A3412]" />
                  ) : (
                    <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24">
                      <path
                        d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.66-5.17 3.66-9.17z"
                        fill="#4285F4"
                      />
                      <path
                        d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"
                        fill="#34A853"
                      />
                      <path
                        d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 10.02 0 12s.45 3.82 1.25 5.42l4.03-3.15z"
                        fill="#FBBC05"
                      />
                      <path
                        d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"
                        fill="#EA4335"
                      />
                    </svg>
                  )}
                  <span>
                    {state === "loading"
                      ? "Đang xử lý..."
                      : "Tiếp tục với Google"}
                  </span>
                </button>

                {/* Button 2: Đăng nhập với FE Edu SSO */}
                <button
                  type="button"
                  onClick={() => handleLogin("sso")}
                  disabled={state === "loading"}
                  className="w-full h-11 sm:h-12 rounded-full border border-white/80 bg-white/85 hover:bg-white hover:border-[#9A3412] text-[#1E293B] font-semibold text-sm transition-all duration-150 flex items-center justify-center gap-3 shadow-md disabled:opacity-60 cursor-pointer"
                >
                  <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24">
                    <path
                      fill="#1E293B"
                      d="M12 3 1 9l11 6 9-4.91V17h2V9L12 3Zm0 14.2L5 13.38V17c0 1.66 3.13 3 7 3s7-1.34 7-3v-3.62l-7 3.82Z"
                    />
                  </svg>
                  <span>Đăng nhập với FE Edu SSO</span>
                </button>

                {/* Divider */}
                <div className="relative my-3.5 sm:my-4 flex items-center justify-center">
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-slate-400/40" />
                  </div>
                  <span className="relative bg-white/70 backdrop-blur-xs px-3 text-xs font-bold tracking-widest text-slate-700 rounded-full">
                    HOẶC
                  </span>
                </div>

                {/* Button 3: Đăng nhập với email & mật khẩu */}
                <button
                  type="button"
                  onClick={() => setIsEmailMode(true)}
                  className="w-full h-11 sm:h-12 rounded-full bg-[#9A3412] hover:bg-[#7C2D12] text-white font-semibold text-sm transition-colors duration-150 flex items-center justify-center shadow-lg cursor-pointer"
                >
                  Đăng nhập với email &amp; mật khẩu
                </button>
              </div>
            ) : (
              /* Email & Password Input Form */
              <form onSubmit={handleEmailSubmit} className="w-full max-w-[340px] sm:max-w-[360px] mx-auto space-y-3.5 text-left">
                <div>
                  <label className="block text-xs font-bold text-slate-800 mb-1 ml-3">
                    Email FPT
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="admin@fpt.edu.vn"
                    required
                    className="w-full h-11 px-4 rounded-full border border-white/80 bg-white/80 focus:bg-white focus:outline-none focus:border-[#9A3412] focus:ring-2 focus:ring-orange-200 text-sm font-medium text-slate-900 shadow-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-800 mb-1 ml-3">
                    Mật khẩu
                  </label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    required
                    className="w-full h-11 px-4 rounded-full border border-white/80 bg-white/80 focus:bg-white focus:outline-none focus:border-[#9A3412] focus:ring-2 focus:ring-orange-200 text-sm font-medium text-slate-900 shadow-sm"
                  />
                </div>
                <button
                  type="submit"
                  disabled={state === "loading"}
                  className="w-full h-11 sm:h-12 rounded-full bg-[#9A3412] hover:bg-[#7C2D12] text-white font-semibold text-sm transition-colors duration-150 flex items-center justify-center shadow-lg disabled:opacity-60 cursor-pointer mt-2"
                >
                  {state === "loading" ? "Đang xác thực..." : "Đăng nhập"}
                </button>
                <button
                  type="button"
                  onClick={() => setIsEmailMode(false)}
                  className="w-full py-2 text-xs text-slate-800 hover:text-black font-semibold transition-colors text-center cursor-pointer flex items-center justify-center gap-1.5"
                >
                  <ArrowLeft className="w-3.5 h-3.5" />
                  <span>Quay lại các phương thức khác</span>
                </button>
              </form>
            )}
          </div>

          {/* Bottom: Terms and Privacy Policy */}
          <p className="text-[11.5px] text-slate-800 font-semibold text-center leading-relaxed pt-5 mt-2 border-t border-slate-400/30">
            Bằng việc đăng nhập, bạn đồng ý với{" "}
            <a href="#terms" className="underline text-[#9A3412] hover:text-[#7C2D12]">
              Điều khoản dịch vụ
            </a>
            <br />
            và{" "}
            <a href="#privacy" className="underline text-[#9A3412] hover:text-[#7C2D12]">
              Chính sách quyền riêng tư
            </a>{" "}
            của FAP Edu.
          </p>
        </div>
      </section>
    </main>
  )
}
