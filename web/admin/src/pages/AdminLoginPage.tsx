import { useState } from "react"
import { ArrowLeft, CircleAlert, LoaderCircle } from "lucide-react"

export function AdminLogin({
  loading,
  error,
  onLogin,
}: {
  loading: boolean
  error: string | null
  onLogin: () => Promise<void>
}) {
  const [isEmailMode, setIsEmailMode] = useState(false)
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")

  const handleEmailSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    void onLogin()
  }

  return (
    <main className="w-full h-screen min-h-screen grid grid-cols-1 md:grid-cols-2 bg-white overflow-hidden">
      {/* Cột trái: Form đăng nhập */}
      <section className="flex flex-col justify-between h-full w-full p-6 sm:p-10 lg:p-12 overflow-y-auto">
        {/* Góc trên bên trái: Logo FPT Education */}
        <div className="flex items-start justify-start w-full">
          <img
            src="/fpt_logo.png"
            alt="FPT Education - TRƯỜNG ĐẠI HỌC FPT"
            className="h-12 sm:h-14 w-auto object-contain"
          />
        </div>

        {/* Khu vực trung tâm */}
        <div className="my-auto py-6 sm:py-8 flex flex-col items-center justify-center w-full">
          <div className="w-full max-w-[390px] text-center">
            <h1 className="text-2xl sm:text-[30px] font-extrabold text-[#9A3412] tracking-tight leading-tight mb-2.5">
              Hệ thống điểm danh FAP
            </h1>
            <p className="text-xs sm:text-[13.5px] text-slate-500 leading-relaxed mb-8 max-w-[340px] mx-auto">
              Dành cho Cán bộ, Giảng viên &amp; Sinh viên Đại học FPT.
              <br />
              Vui lòng sử dụng tài khoản nội bộ để tiếp tục.
            </p>

            {/* Thông báo lỗi nếu có */}
            {error && (
              <div className="mb-5 p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 flex items-center gap-3 text-left">
                <CircleAlert className="w-5 h-5 shrink-0 text-red-600" />
                <div>
                  <b className="block text-xs font-semibold">Không thể truy cập</b>
                  <span className="block text-[11px] text-red-600/90 mt-0.5">
                    {error}
                  </span>
                </div>
              </div>
            )}

            {!isEmailMode ? (
              <div className="w-full flex flex-col gap-3">
                {/* Nút 1: Tiếp tục với Google */}
                <button
                  type="button"
                  onClick={() => void onLogin()}
                  disabled={loading}
                  className="w-full h-11 sm:h-12 rounded-full border border-[#CBD5E1] bg-white hover:bg-orange-50/40 hover:border-[#9A3412] text-[#334155] font-medium text-sm transition-all duration-150 flex items-center justify-center gap-3 shadow-xs disabled:opacity-60 cursor-pointer"
                >
                  {loading ? (
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
                  <span>{loading ? "Đang xác thực..." : "Tiếp tục với Google"}</span>
                </button>

                {/* Nút 2: Đăng nhập với FE Edu SSO */}
                <button
                  type="button"
                  onClick={() => void onLogin()}
                  disabled={loading}
                  className="w-full h-11 sm:h-12 rounded-full border border-[#CBD5E1] bg-white hover:bg-orange-50/40 hover:border-[#9A3412] text-[#334155] font-medium text-sm transition-all duration-150 flex items-center justify-center gap-3 shadow-xs disabled:opacity-60 cursor-pointer"
                >
                  <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24">
                    <path
                      fill="#1E293B"
                      d="M12 3 1 9l11 6 9-4.91V17h2V9L12 3Zm0 14.2L5 13.38V17c0 1.66 3.13 3 7 3s7-1.34 7-3v-3.62l-7 3.82Z"
                    />
                  </svg>
                  <span>Đăng nhập với FE Edu SSO</span>
                </button>

                {/* Phân cách */}
                <div className="relative my-4 sm:my-5 flex items-center justify-center">
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-[#E2E8F0]" />
                  </div>
                  <span className="relative bg-white px-3 text-xs font-semibold tracking-widest text-[#94A3B8]">
                    HOẶC
                  </span>
                </div>

                {/* Nút 3: Đăng nhập với email & mật khẩu */}
                <button
                  type="button"
                  onClick={() => setIsEmailMode(true)}
                  className="w-full h-11 sm:h-12 rounded-full bg-[#9A3412] hover:bg-[#7C2D12] text-white font-semibold text-sm transition-colors duration-150 flex items-center justify-center shadow-xs cursor-pointer"
                >
                  Đăng nhập với email &amp; mật khẩu
                </button>
              </div>
            ) : (
              /* Form nhập email & mật khẩu */
              <form onSubmit={handleEmailSubmit} className="space-y-3.5 text-left">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1 ml-3">
                    Email FPT
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="admin@fpt.edu.vn"
                    required
                    className="w-full h-11 px-4 rounded-full border border-slate-300 focus:outline-none focus:border-[#9A3412] focus:ring-2 focus:ring-orange-100 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1 ml-3">
                    Mật khẩu
                  </label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    required
                    className="w-full h-11 px-4 rounded-full border border-slate-300 focus:outline-none focus:border-[#9A3412] focus:ring-2 focus:ring-orange-100 text-sm"
                  />
                </div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full h-11 sm:h-12 rounded-full bg-[#9A3412] hover:bg-[#7C2D12] text-white font-semibold text-sm transition-colors duration-150 flex items-center justify-center shadow-xs disabled:opacity-60 cursor-pointer mt-2"
                >
                  {loading ? "Đang xác thực..." : "Đăng nhập"}
                </button>
                <button
                  type="button"
                  onClick={() => setIsEmailMode(false)}
                  className="w-full py-2 text-xs text-slate-500 hover:text-slate-800 transition-colors text-center cursor-pointer flex items-center justify-center gap-1.5"
                >
                  <ArrowLeft className="w-3.5 h-3.5" />
                  <span>Quay lại các phương thức khác</span>
                </button>
              </form>
            )}
          </div>
        </div>

        {/* Chân trang */}
        <p className="text-[11.5px] text-[#94A3B8] text-center leading-relaxed pt-4">
          Bằng việc đăng nhập, bạn đồng ý với{" "}
          <a href="#terms" className="underline hover:text-slate-600">
            Điều khoản dịch vụ
          </a>
          <br />
          và{" "}
          <a href="#privacy" className="underline hover:text-slate-600">
            Chính sách quyền riêng tư
          </a>{" "}
          của FAP Edu.
        </p>
      </section>

      {/* Cột phải: Ảnh khuôn viên trường FPT tràn viền */}
      <section className="hidden md:block relative h-full w-full bg-[#0F172A] overflow-hidden select-none">
        <img
          src="/fpt_hcm_campus.jpg"
          alt="Cơ sở Đại học FPT"
          className="absolute inset-0 w-full h-full object-cover object-center"
        />
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background:
              "linear-gradient(to top, rgba(0,0,0,0.68) 0%, rgba(0,0,0,0.2) 28%, rgba(0,0,0,0.05) 50%, rgba(0,0,0,0.12) 100%)",
          }}
        />
        <div className="absolute left-8 right-8 bottom-8 z-10 text-white">
          <p className="text-xs font-semibold uppercase tracking-wider text-[#E2E8F0] mb-1 drop-shadow-sm">
            CƠ SỞ GIẢNG ĐƯỜNG &amp; THƯ VIỆN SỐ
          </p>
          <p className="text-sm font-light text-[#F1F5F9] drop-shadow-sm">
            Môi trường học tập chủ động và sáng tạo không ngừng
          </p>
        </div>
      </section>
    </main>
  )
}
