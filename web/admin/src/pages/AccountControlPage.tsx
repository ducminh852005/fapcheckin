import { KeyRound, LoaderCircle, LockKeyhole, Plus, RotateCw, Search, ShieldCheck, Trash2, UserCog, X } from "lucide-react"
import { useCallback, useMemo, useState } from "react"
import { Button, Field, PageHeader } from "../components/ui"
import type { AdminProfile } from "../firebase/admin-auth"
import { readError, useAsyncData } from "../hooks/useAsyncData"
import {
  createInvite,
  listAccountData,
  revokeInvite,
  setAccountActive,
  setAccountRole,
  type AccountRow,
  type InviteRow,
} from "../repositories/accountRepository"

type InviteForm = { email: string; fullName: string; memberCode: string; role: "user" | "staff"; rollNumber: string }
const emptyInvite: InviteForm = { email: "", fullName: "", memberCode: "", role: "user", rollNumber: "" }

export function AccountControl({ currentAdmin }: { currentAdmin: AdminProfile }) {
  const loader = useCallback(listAccountData, [])
  const { data, loading, error, reload } = useAsyncData(loader)
  const [tab, setTab] = useState<"users" | "invites">("users")
  const [search, setSearch] = useState("")
  const [selected, setSelected] = useState<AccountRow | null>(null)
  const [selectedRole, setSelectedRole] = useState<"user" | "staff">("user")
  const [inviteOpen, setInviteOpen] = useState(false)
  const [invite, setInvite] = useState<InviteForm>(emptyInvite)
  const [busy, setBusy] = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const accounts = useMemo(() => (data?.accounts ?? []).filter((item) => `${item.fullName} ${item.email} ${item.memberCode}`.toLowerCase().includes(search.toLowerCase())), [data, search])
  const invites = useMemo(() => (data?.invites ?? []).filter((item) => `${item.fullName} ${item.email} ${item.memberCode}`.toLowerCase().includes(search.toLowerCase())), [data, search])
  const canonicalEmails = useMemo(() => new Set((data?.accounts ?? []).filter((item) => item.canonical).map((item) => item.email.toLowerCase())), [data])
  const inviteEmails = useMemo(() => new Set((data?.invites ?? []).map((item) => item.email.toLowerCase())), [data])

  const openAccount = (account: AccountRow) => {
    setSelected(account)
    setSelectedRole(account.role === "staff" || account.role === "GV" ? "staff" : "user")
    setActionError(null)
    setMessage(null)
  }
  const run = async (action: () => Promise<unknown>, success: string, close = false) => {
    setBusy(true); setActionError(null); setMessage(null)
    try { await action(); setMessage(success); reload(); if (close) setSelected(null) } catch (reason) { setActionError(readError(reason)) } finally { setBusy(false) }
  }
  const saveInvite = () => run(async () => {
    await createInvite(invite)
    setInvite(emptyInvite)
    setInviteOpen(false)
  }, "Đã cấp quyền đăng nhập.")
  const grantLegacy = (account: AccountRow) => run(() => createInvite({
    email: account.email,
    fullName: account.fullName,
    memberCode: account.memberCode,
    role: account.role === "GV" ? "staff" : "user",
    ...(account.role === "GV" ? {} : { rollNumber: account.rollNumber }),
  }), "Đã tạo quyền đăng nhập từ hồ sơ dữ liệu cũ.")

  return (
    <>
      <PageHeader eyebrow="QUYỀN TRUY CẬP" title="Tài khoản" description="Cấp quyền đăng nhập, kiểm tra hồ sơ, khóa tài khoản và quản lý vai trò." actions={<Button icon={<KeyRound size={18} />} onClick={() => setInviteOpen(true)}>Cấp quyền đăng nhập</Button>} />
      <section className="account-guide">
        <div className="account-guide-head"><span><ShieldCheck size={19} /></span><div><h3>Admin có thể làm gì ở đây?</h3><p>Quản lý quyền truy cập hệ thống mà không cần biết mật khẩu của người dùng.</p></div></div>
        <div className="account-guide-grid">
          <article><i>1</i><div><b>Quản lý tài khoản</b><p>Xem hồ sơ, vai trò và trạng thái; khóa/mở hoặc đổi giữa Sinh viên và Giảng viên.</p></div></article>
          <article><i>2</i><div><b>Cấp quyền đăng nhập</b><p>Cho phép một email Google đăng nhập lần đầu. Đây không phải email mời và không tự gửi thư.</p></div></article>
          <article><i>3</i><div><b>Hiểu trạng thái liên kết</b><p>“Đã liên kết” là hồ sơ đã gắn Auth UID. “Dữ liệu cũ” cần cấp quyền để liên kết khi người dùng đăng nhập.</p></div></article>
          <article><i>4</i><div><b>Khóa và thu hồi</b><p>Khóa sẽ chặn truy cập bằng active = false. Thu hồi chỉ xóa quyền đăng nhập chưa dùng.</p></div></article>
        </div>
        <p className="account-guide-foot">Lưu ý: xóa hoàn toàn một người dùng khỏi Firebase Authentication cần backend Admin SDK; trang này không xóa tài khoản Google.</p>
      </section>
      {(error || actionError) && <section className="data-error"><b>Thao tác chưa hoàn tất</b><span>{actionError ?? error}</span></section>}
      {message && <section className="data-success"><b>Thành công</b><span>{message}</span></section>}
      <div className="tabs"><button className={tab === "users" ? "active" : ""} onClick={() => setTab("users")}>Tài khoản <span>{data?.accounts.length ?? 0}</span></button><button className={tab === "invites" ? "active" : ""} onClick={() => setTab("invites")}>Quyền đăng nhập <span>{data?.invites.length ?? 0}</span></button></div>
      <article className="card table-card">
        <div className="table-toolbar"><label className="search-box"><Search size={18} /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Tìm email, mã thành viên hoặc họ tên..." /></label><Button variant="secondary" icon={<RotateCw size={16} />} onClick={reload} disabled={loading}>Làm mới</Button></div>
        {loading ? <Loading /> : tab === "users" ? <AccountsTable rows={accounts} currentUid={currentAdmin.uid} open={openAccount} /> : <InvitesTable rows={invites} canonicalEmails={canonicalEmails} revoke={(row) => void run(() => revokeInvite(row.id), "Đã thu hồi quyền đăng nhập.")} />}
      </article>

      {selected && <div className="drawer-layer"><div className="scrim" onClick={() => setSelected(null)} /><aside className="drawer account-drawer"><div className="drawer-head"><div><span className="eyebrow">CHI TIẾT TÀI KHOẢN</span><h2>{selected.fullName || selected.memberCode}</h2><p>{selected.email}</p></div><Button variant="icon" onClick={() => setSelected(null)}><X size={20} /></Button></div><div className="drawer-body"><div className="account-summary"><span className="large-avatar">{initials(selected.fullName)}</span><div><b>{selected.memberCode}</b><small>{roleLabel(selected.role)}</small></div><span className={`status ${selected.canonical ? "status-success" : "status-warning"}`}><i />{selected.canonical ? "Đã liên kết" : "Dữ liệu cũ"}</span></div><dl className="detail-list"><div><dt>Document ID</dt><dd>{selected.id}</dd></div><div><dt>Roll number</dt><dd>{selected.rollNumber || "—"}</dd></div><div><dt>Trạng thái</dt><dd>{selected.active === null ? "Chưa liên kết đăng nhập" : selected.active ? "Đang hoạt động" : "Đã khóa"}</dd></div></dl>{selected.canonical ? <section className="account-actions"><h4>Quản lý quyền</h4>{selected.role !== "admin" && <><label className="select-wrap field-select"><span>Vai trò</span><select value={selectedRole} onChange={(event) => setSelectedRole(event.target.value as "user" | "staff")}><option value="user">Sinh viên</option><option value="staff">Giảng viên</option></select></label><Button variant="secondary" icon={<UserCog size={17} />} disabled={busy} onClick={() => void run(() => setAccountRole(selected, selectedRole), "Đã cập nhật vai trò.")}>Lưu vai trò</Button></>}<Button variant={selected.active ? "danger" : "secondary"} icon={<LockKeyhole size={17} />} disabled={busy || selected.id === currentAdmin.uid} onClick={() => void run(() => setAccountActive(selected, selected.active !== true), selected.active ? "Đã khóa tài khoản." : "Đã mở tài khoản.", true)}>{selected.active ? "Khóa tài khoản" : "Mở tài khoản"}</Button>{selected.id === currentAdmin.uid && <small>Không thể tự khóa tài khoản đang đăng nhập.</small>}</section> : <section className="legacy-action"><h4>Hồ sơ dữ liệu cũ</h4><p>Hồ sơ này chưa liên kết với tài khoản Google. Hãy cấp quyền theo email để người dùng tạo hồ sơ đăng nhập mới.</p><Button icon={<KeyRound size={17} />} disabled={busy || !selected.email || inviteEmails.has(selected.email.toLowerCase())} onClick={() => void grantLegacy(selected)}>{inviteEmails.has(selected.email.toLowerCase()) ? "Đã có quyền đăng nhập" : "Cấp quyền từ hồ sơ này"}</Button></section>}</div></aside></div>}

      {inviteOpen && <InviteModal invite={invite} setInvite={setInvite} busy={busy} close={() => setInviteOpen(false)} save={() => void saveInvite()} />}
    </>
  )
}

function AccountsTable({ rows, currentUid, open }: { rows: AccountRow[]; currentUid: string; open: (row: AccountRow) => void }) {
  if (!rows.length) return <Empty label="Không tìm thấy tài khoản" />
  return <div className="table-scroll"><table className="admin-data-table"><thead><tr><th>Người dùng</th><th>Mã thành viên</th><th>Vai trò</th><th>Liên kết đăng nhập</th><th>Trạng thái</th><th /></tr></thead><tbody>{rows.map((row) => <tr key={row.id} onClick={() => open(row)}><td><b>{row.fullName || "Chưa có tên"}</b><small className="cell-note">{row.email}</small></td><td>{row.memberCode}</td><td>{roleLabel(row.role)}</td><td><span className={`status ${row.canonical ? "status-success" : "status-warning"}`}><i />{row.canonical ? "Đã liên kết" : "Dữ liệu cũ"}</span></td><td>{row.active === null ? "Chưa liên kết đăng nhập" : row.active ? "Đang hoạt động" : "Đã khóa"}{row.id === currentUid && <small className="cell-note">Tài khoản hiện tại</small>}</td><td><Button variant="secondary" onClick={() => open(row)}>Quản lý</Button></td></tr>)}</tbody></table></div>
}

function InvitesTable({ rows, canonicalEmails, revoke }: { rows: InviteRow[]; canonicalEmails: Set<string>; revoke: (row: InviteRow) => void }) {
  if (!rows.length) return <Empty label="Chưa cấp quyền đăng nhập" />
  return <div className="table-scroll"><table className="admin-data-table"><thead><tr><th>Người dùng</th><th>Mã thành viên</th><th>Vai trò</th><th>Trạng thái</th><th /></tr></thead><tbody>{rows.map((row) => { const used = canonicalEmails.has(row.email.toLowerCase()); return <tr key={row.id}><td><b>{row.fullName}</b><small className="cell-note">{row.email}</small></td><td>{row.memberCode}</td><td>{roleLabel(row.role)}</td><td><span className={`status ${used ? "status-success" : "status-warning"}`}><i />{used ? "Đã đăng nhập" : "Chờ đăng nhập"}</span></td><td><Button variant="danger" icon={<Trash2 size={15} />} onClick={() => revoke(row)}>Thu hồi</Button></td></tr> })}</tbody></table></div>
}

function InviteModal({ invite, setInvite, busy, close, save }: { invite: InviteForm; setInvite: (value: InviteForm) => void; busy: boolean; close: () => void; save: () => void }) {
  return <div className="modal-layer"><div className="scrim" onClick={close} /><section className="modal"><div className="modal-head"><div><span className="eyebrow">FIREBASE ACCESS</span><h2>Cấp quyền đăng nhập</h2></div><Button variant="icon" onClick={close}><X size={20} /></Button></div><div className="form-grid"><Field label="Email Google *" value={invite.email} onChange={(value) => setInvite({ ...invite, email: value })} /><Field label="Họ tên *" value={invite.fullName} onChange={(value) => setInvite({ ...invite, fullName: value })} /><Field label="Mã thành viên *" value={invite.memberCode} onChange={(value) => setInvite({ ...invite, memberCode: value })} /><label className="select-wrap field-select"><span>Vai trò *</span><select value={invite.role} onChange={(event) => setInvite({ ...invite, role: event.target.value as "user" | "staff" })}><option value="user">Sinh viên</option><option value="staff">Giảng viên</option></select></label>{invite.role === "user" && <Field label="Roll number *" value={invite.rollNumber} onChange={(value) => setInvite({ ...invite, rollNumber: value })} />}</div><div className="modal-actions"><Button variant="secondary" onClick={close}>Hủy</Button><Button icon={busy ? <LoaderCircle className="spin" size={17} /> : <Plus size={17} />} onClick={save} disabled={busy}>Cấp quyền</Button></div></section></div>
}

function roleLabel(role: string) { return ({ user: "Sinh viên", SV: "Sinh viên (dữ liệu cũ)", staff: "Giảng viên", GV: "Giảng viên (dữ liệu cũ)", admin: "Admin" } as Record<string, string>)[role] ?? role }
function initials(name: string) { return name.trim().split(/\s+/).slice(-2).map((word) => word[0]?.toUpperCase()).join("") || "?" }
function Loading() { return <div className="data-loading"><LoaderCircle className="spin" size={24} /><span>Đang tải tài khoản...</span></div> }
function Empty({ label }: { label: string }) { return <div className="empty-state compact-empty"><span><ShieldCheck size={28} /></span><h3>{label}</h3></div> }
