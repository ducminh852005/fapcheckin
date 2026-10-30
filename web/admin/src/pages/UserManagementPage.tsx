import { LoaderCircle, Plus, RotateCw, Search, ShieldCheck, UserPlus, X } from "lucide-react"
import { useCallback, useMemo, useState } from "react"
import { Button, Field, PageHeader } from "../components/ui"
import { Pagination } from "../components/Pagination"
import type { AdminProfile } from "../firebase/admin-auth"
import { readError, useAsyncData } from "../hooks/useAsyncData"
import { createInvite, listAccountData, setAccountActive, type AccountRow } from "../repositories/accountRepository"

const emptyInvite = { email: "", fullName: "", memberCode: "", role: "user" as "user" | "staff", rollNumber: "" }

export function UserManagement({ currentAdmin }: { currentAdmin: AdminProfile }) {
  const loader = useCallback(listAccountData, [])
  const { data, loading, error, reload } = useAsyncData(loader)
  const [tab, setTab] = useState<"users" | "invites">("users")
  const [search, setSearch] = useState("")
  const [page, setPage] = useState(1)
  const [inviteOpen, setInviteOpen] = useState(false)
  const [invite, setInvite] = useState(emptyInvite)
  const [saving, setSaving] = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)

  const accounts = useMemo(() => (data?.accounts ?? []).filter((item) => `${item.fullName} ${item.email} ${item.memberCode}`.toLowerCase().includes(search.toLowerCase())), [data, search])
  const invites = useMemo(() => (data?.invites ?? []).filter((item) => `${item.fullName} ${item.email} ${item.memberCode}`.toLowerCase().includes(search.toLowerCase())), [data, search])
  const paginatedAccounts = useMemo(() => accounts.slice((page - 1) * 10, page * 10), [accounts, page])
  const paginatedInvites = useMemo(() => invites.slice((page - 1) * 10, page * 10), [invites, page])

  const toggle = async (account: AccountRow) => {
    if (account.id === currentAdmin.uid) return setActionError("Không thể tự khóa tài khoản đang đăng nhập.")
    setActionError(null)
    try { await setAccountActive(account, account.active !== true); reload() } catch (reason) { setActionError(readError(reason)) }
  }
  const saveInvite = async () => {
    setSaving(true); setActionError(null)
    try { await createInvite(invite); setInvite(emptyInvite); setInviteOpen(false); reload() } catch (reason) { setActionError(readError(reason)) } finally { setSaving(false) }
  }

  return (
    <>
      <PageHeader eyebrow="QUYỀN TRUY CẬP" title="Tài khoản" description="Quản lý hồ sơ canonical, trạng thái hoạt động và lời mời đăng nhập." actions={<Button icon={<UserPlus size={18} />} onClick={() => setInviteOpen(true)}>Tạo lời mời</Button>} />
      <section className="scope-note"><ShieldCheck size={18} /><div><b>Dữ liệu legacy được đánh dấu riêng</b><p>Document dùng memberCode làm ID hoặc role SV/GV chỉ được xem; cần migrate trước khi khóa/mở.</p></div></section>
      {(error || actionError) && <section className="data-error"><b>Thao tác chưa hoàn tất</b><span>{actionError ?? error}</span></section>}
      <div className="tabs"><button className={tab === "users" ? "active" : ""} onClick={() => { setTab("users"); setPage(1) }}>Tài khoản <span>{data?.accounts.length ?? 0}</span></button><button className={tab === "invites" ? "active" : ""} onClick={() => { setTab("invites"); setPage(1) }}>Lời mời <span>{data?.invites.length ?? 0}</span></button></div>
      <article className="card table-card">
        <div className="table-toolbar"><label className="search-box"><Search size={18} /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Tìm email, mã thành viên hoặc họ tên..." /></label><Button variant="secondary" icon={<RotateCw size={16} />} onClick={reload} disabled={loading}>Làm mới</Button></div>
        {loading ? <LoadingRows /> : tab === "users" ? <><AccountsTable rows={paginatedAccounts} currentUid={currentAdmin.uid} toggle={toggle} /><Pagination currentPage={page} totalItems={accounts.length} pageSize={10} onPageChange={setPage} itemLabel="tài khoản" /></> : <><InvitesTable rows={paginatedInvites} /><Pagination currentPage={page} totalItems={invites.length} pageSize={10} onPageChange={setPage} itemLabel="lời mời" /></>}
      </article>
      {inviteOpen && <div className="modal-layer"><div className="scrim" onClick={() => setInviteOpen(false)} /><section className="modal"><div className="modal-head"><div><span className="eyebrow">CẤP QUYỀN ĐĂNG NHẬP</span><h2>Tạo lời mời</h2></div><Button variant="icon" onClick={() => setInviteOpen(false)}><X size={20} /></Button></div><div className="form-grid"><Field label="Email *" value={invite.email} onChange={(value) => setInvite({ ...invite, email: value })} /><Field label="Họ tên *" value={invite.fullName} onChange={(value) => setInvite({ ...invite, fullName: value })} /><Field label="Mã thành viên *" value={invite.memberCode} onChange={(value) => setInvite({ ...invite, memberCode: value })} /><label className="select-wrap field-select"><span>Vai trò *</span><select value={invite.role} onChange={(event) => setInvite({ ...invite, role: event.target.value as "user" | "staff" })}><option value="user">Sinh viên</option><option value="staff">Giảng viên</option></select></label>{invite.role === "user" && <Field label="Roll number *" value={invite.rollNumber} onChange={(value) => setInvite({ ...invite, rollNumber: value })} />}</div><div className="modal-actions"><Button variant="secondary" onClick={() => setInviteOpen(false)}>Hủy</Button><Button icon={saving ? <LoaderCircle className="spin" size={17} /> : <Plus size={17} />} onClick={() => void saveInvite()} disabled={saving}>Tạo lời mời</Button></div></section></div>}
    </>
  )
}

function AccountsTable({ rows, currentUid, toggle }: { rows: AccountRow[]; currentUid: string; toggle: (row: AccountRow) => void }) {
  if (!rows.length) return <Empty label="Không tìm thấy tài khoản" />
  return <div className="table-scroll"><table className="admin-data-table"><thead><tr><th>Người dùng</th><th>Mã thành viên</th><th>Vai trò</th><th>Schema</th><th>Trạng thái</th><th /></tr></thead><tbody>{rows.map((row) => <tr key={row.id}><td><b>{row.fullName || "Chưa có tên"}</b><small className="cell-note">{row.email}</small></td><td>{row.memberCode}</td><td>{roleLabel(row.role)}</td><td><span className={`status ${row.canonical ? "status-success" : "status-warning"}`}><i />{row.canonical ? "Canonical" : "Legacy"}</span></td><td>{row.active === null ? "Chưa có active" : row.active ? "Đang hoạt động" : "Đã khóa"}</td><td><Button variant="secondary" disabled={!row.canonical || row.id === currentUid} onClick={() => toggle(row)}>{row.active ? "Khóa" : "Mở"}</Button></td></tr>)}</tbody></table></div>
}

function InvitesTable({ rows }: { rows: Array<{ id: string; fullName: string; email: string; memberCode: string; role: string; rollNumber: string }> }) {
  if (!rows.length) return <Empty label="Chưa có lời mời" />
  return <div className="table-scroll"><table className="admin-data-table"><thead><tr><th>Người được mời</th><th>Mã thành viên</th><th>Vai trò</th><th>Roll number</th></tr></thead><tbody>{rows.map((row) => <tr key={row.id}><td><b>{row.fullName}</b><small className="cell-note">{row.email}</small></td><td>{row.memberCode}</td><td>{roleLabel(row.role)}</td><td>{row.rollNumber || "—"}</td></tr>)}</tbody></table></div>
}

function roleLabel(role: string) { return ({ user: "Sinh viên", SV: "Sinh viên (legacy)", staff: "Giảng viên", GV: "Giảng viên (legacy)", admin: "Admin" } as Record<string, string>)[role] ?? role }
function LoadingRows() { return <div className="data-loading"><LoaderCircle className="spin" size={24} /><span>Đang tải dữ liệu...</span></div> }
function Empty({ label }: { label: string }) { return <div className="empty-state compact-empty"><span><ShieldCheck size={28} /></span><h3>{label}</h3></div> }
