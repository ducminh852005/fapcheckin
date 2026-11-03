import { Search, ShieldCheck, UserPlus, Users } from "lucide-react"
import { useState } from "react"
import { Button, PageHeader } from "../components/ui"

export function Accounts() {
  const [tab, setTab] = useState<"users" | "invites">("users")
  return (
    <>
      <PageHeader eyebrow="QUYỀN TRUY CẬP" title="Tài khoản" description="Quản lý hồ sơ, vai trò, trạng thái hoạt động và lời mời đăng nhập." actions={<Button disabled icon={<UserPlus size={18} />}>Tạo lời mời</Button>} />
      <section className="scope-note"><ShieldCheck size={18} /><div><b>Quy tắc an toàn</b><p>Admin chỉ đổi quyền hoặc khóa tài khoản; không sửa dữ liệu cá nhân và không tự tạo mật khẩu cho người dùng.</p></div></section>
      <div className="tabs">
        <button className={tab === "users" ? "active" : ""} onClick={() => setTab("users")}>Tài khoản</button>
        <button className={tab === "invites" ? "active" : ""} onClick={() => setTab("invites")}>Lời mời</button>
      </div>
      <article className="card table-card">
        <div className="table-toolbar"><label className="search-box"><Search size={18} /><input placeholder="Tìm email, mã thành viên hoặc họ tên..." disabled /></label><span className="source-chip">Nguồn: {tab === "users" ? "users" : "user_invites"}</span></div>
        <div className="empty-state compact-empty"><span><Users size={28} /></span><h3>Chưa thể tải {tab === "users" ? "tài khoản" : "lời mời"}</h3><p>{tab === "users" ? "Cần migrate hồ sơ legacy sang users/{authUid} trước khi bật quản lý tài khoản." : "Kết nối Firestore repository để đọc và tạo user_invites."}</p></div>
      </article>
    </>
  )
}
