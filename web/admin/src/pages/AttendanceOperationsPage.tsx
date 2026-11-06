import { AlertTriangle, ClipboardCheck, Clock3, LoaderCircle, Search, SlidersHorizontal, Users, X } from "lucide-react"
import { useCallback, useMemo, useState } from "react"
import { Button, PageHeader } from "../components/ui"
import { Pagination } from "../components/Pagination"
import { readError, useAsyncData } from "../hooks/useAsyncData"
import { listAttendanceData, listAttendanceSessionsPaginated, listSessionRecords, type AttendanceRecordRow, type SessionRow } from "../repositories/attendanceRepository"

export function AttendanceOperations() {
  const [sessionPage, setSessionPage] = useState(1)
  const [search, setSearch] = useState("")
  const [status, setStatus] = useState("all")
  const [classCode, setClassCode] = useState("all")
  const [teacher, setTeacher] = useState("all")
  const [slot, setSlot] = useState("all")
  const [warning, setWarning] = useState("all")
  const [selectedDate, setSelectedDate] = useState("")
  const [advancedOpen, setAdvancedOpen] = useState(false)
  const [selected, setSelected] = useState<SessionRow | null>(null)
  const [records, setRecords] = useState<AttendanceRecordRow[]>([])
  const [detailLoading, setDetailLoading] = useState(false)
  const [detailError, setDetailError] = useState<string | null>(null)

  const loader = useCallback(
    () =>
      listAttendanceSessionsPaginated({
        page: sessionPage,
        pageSize: 10,
        search,
        status,
        classCode,
        teacher,
        slot,
        warning,
        selectedDate,
      }),
    [sessionPage, search, status, classCode, teacher, slot, warning, selectedDate]
  )
  const { data, loading, error } = useAsyncData(loader)

  const sessions = data?.sessions ?? []
  const totalSessions = data?.totalSessions ?? sessions.length
  const warningSessions = data?.sessions.filter((item) => item.warningCount > 0).length ?? 0
  const overdueSessions = data?.sessions.filter((item) => item.overdue).length ?? 0
  const activeAdvancedFilters = [classCode, teacher, slot, warning].filter((value) => value !== "all").length + (selectedDate ? 1 : 0)

  const open = async (session: SessionRow) => {
    setSelected(session); setDetailLoading(true); setDetailError(null)
    try { setRecords(await listSessionRecords(session.id)) } catch (reason) { setDetailError(readError(reason)) }
    finally { setDetailLoading(false) }
  }
  const clearFilters = () => { setSearch(""); setStatus("all"); setClassCode("all"); setTeacher("all"); setSlot("all"); setWarning("all"); setSelectedDate(""); setSessionPage(1) }

  const paginatedSessions = sessions

  return <>
    <PageHeader title="Giám sát điểm danh" description="Theo dõi phiên, tỷ lệ tham dự và các bất thường mà không hiển thị QR secret hoặc địa chỉ IP." />
    {error && <section className="data-error"><b>Không thể tải điểm danh</b><span>{error}</span></section>}
    <section className="monitor-grid attendance-kpis"><Metric icon={<ClipboardCheck size={21} />} tone="warning" label="PHIÊN ĐANG MỞ" value={loading ? "…" : data?.openCount ?? 0} /><Metric icon={<Clock3 size={21} />} tone="danger" label="MỞ QUÁ GIỜ" value={loading ? "…" : overdueSessions} /><Metric icon={<AlertTriangle size={21} />} tone="danger" label="PHIÊN CÓ CẢNH BÁO" value={loading ? "…" : warningSessions} /></section>
    <section className={`card attendance-filters ${advancedOpen ? "is-open" : ""}`}><div className="attendance-filter-main"><label className="search-box"><Search size={18} /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Tìm lớp, giảng viên hoặc session ID..." /></label><Filter value={status} set={setStatus} label="Trạng thái" options={[["all", "Tất cả"], ["open", "Đang mở"], ["closed", "Đã đóng"]]} /><Button variant="secondary" icon={<SlidersHorizontal size={16} />} onClick={() => setAdvancedOpen(!advancedOpen)}>Bộ lọc nâng cao{activeAdvancedFilters ? ` (${activeAdvancedFilters})` : ""}</Button></div>{advancedOpen && <div className="attendance-filter-advanced"><Filter value={classCode} set={setClassCode} label="Lớp học" options={[["all", "Tất cả lớp"], ...(data?.classes ?? []).map((value) => [value, value])]} /><Filter value={teacher} set={setTeacher} label="Giảng viên" options={[["all", "Tất cả GV"], ...(data?.teachers ?? []).map((value) => [value, value])]} /><Filter value={slot} set={setSlot} label="Slot" options={[["all", "Tất cả slot"], ...(data?.slots ?? []).map((value) => [value, value])]} /><Filter value={warning} set={setWarning} label="Cảnh báo" options={[["all", "Tất cả"], ["warning", "Có cảnh báo"], ["clean", "Bình thường"]]} /><label className="field"><span>Ngày</span><input type="date" value={selectedDate} onChange={(event) => setSelectedDate(event.target.value)} /></label><Button variant="ghost" onClick={clearFilters}>Xóa bộ lọc</Button></div>}</section>
    <article className="card table-card"><div className="table-toolbar"><div><b>{sessions.length} / {totalSessions} phiên gần nhất</b></div></div>{loading ? <div className="data-loading"><LoaderCircle className="spin" size={24} /><span>Đang tải và đối chiếu phiên...</span></div> : <><SessionsTable rows={paginatedSessions} open={open} /><Pagination currentPage={sessionPage} totalItems={totalSessions} pageSize={10} onPageChange={setSessionPage} itemLabel="phiên điểm danh" /></>}</article>
    {selected && <SessionDrawer session={selected} records={records} loading={detailLoading} error={detailError} close={() => setSelected(null)} />}
  </>
}

function Metric({ icon, tone, label, value }: { icon: React.ReactNode; tone: string; label: string; value: string | number }) { return <article className="card monitor-card"><span className={`monitor-icon ${tone}`}>{icon}</span><div><small>{label}</small><strong>{value}</strong></div></article> }
function Filter({ value, set, label, options }: { value: string; set: (value: string) => void; label: string; options: string[][] }) { return <label className="select-wrap"><span>{label}</span><select value={value} onChange={(event) => set(event.target.value)}>{options.map(([key, text]) => <option key={key} value={key}>{text}</option>)}</select></label> }

function SessionsTable({ rows, open }: { rows: SessionRow[]; open: (row: SessionRow) => void }) {
  if (!rows.length) return <div className="empty-state compact-empty"><span><ClipboardCheck size={28} /></span><h3>Không tìm thấy phiên</h3></div>
  return <div className="table-scroll"><table className="admin-data-table attendance-table"><thead><tr><th>Ngày / lớp</th><th>Giảng viên</th><th>Trạng thái</th><th>Tham dự</th><th>Chưa ghi nhận</th><th>Cảnh báo</th></tr></thead><tbody>{rows.map((row) => { const attended = row.presentCount + row.lateCount; const rate = row.totalStudents ? Math.round(attended / row.totalStudents * 100) : 0; return <tr key={row.id} onClick={() => void open(row)}><td className="session-identity"><b className="code-link">{row.classCode}</b><small className="cell-note">{row.sessionDate} · {row.slotCode}</small><small className="session-id">{row.id}</small></td><td><b className="teacher-code">{row.teacherMemberCode}</b></td><td><span className={`status ${row.overdue ? "status-error" : row.sessionStatus === "open" ? "status-warning" : "status-success"}`}><i />{row.overdue ? "Mở quá giờ" : row.sessionStatus === "open" ? "Đang mở" : "Đã đóng"}</span></td><td className="attendance-rate"><div><b>{attended}/{row.totalStudents}</b><strong>{rate}%</strong></div><span className="attendance-progress"><i style={{ width: `${rate}%` }} /></span><small>Vắng {row.absentCount} · Muộn {row.lateCount}</small></td><td><b className={row.notRecordedCount ? "count-danger" : "count-ok"}>{row.notRecordedCount}</b></td><td>{row.warningCount ? <span className="status status-error"><i />{row.warningCount} cảnh báo</span> : <span className="status status-success"><i />Bình thường</span>}</td></tr> })}</tbody></table></div>
}

function SessionDrawer({ session, records, loading, error, close }: { session: SessionRow; records: AttendanceRecordRow[]; loading: boolean; error: string | null; close: () => void }) {
  return <div className="drawer-layer"><div className="scrim" onClick={close} /><aside className="drawer attendance-drawer"><div className="drawer-head"><div><span className="eyebrow">CHI TIẾT PHIÊN</span><h2>{session.classCode}</h2><p>{session.sessionDate} · {session.slotCode} · {session.id}</p></div><Button variant="icon" onClick={close}><X size={20} /></Button></div><div className="drawer-body">
    <div className="session-summary"><Summary label="Sĩ số" value={session.totalStudents} /><Summary label="Có mặt" value={session.presentCount} /><Summary label="Đi muộn" value={session.lateCount} /><Summary label="Vắng" value={session.absentCount} /><Summary label="Chưa ghi nhận" value={session.notRecordedCount} /></div>
    {session.warnings.length > 0 && <section className="session-warnings"><h3><AlertTriangle size={17} /> Cảnh báo dữ liệu</h3>{session.warnings.map((item) => <p key={item}>{item}</p>)}</section>}
    {error && <section className="data-error"><span>{error}</span></section>}
    {loading ? <div className="data-loading"><LoaderCircle className="spin" size={24} /><span>Đang ghép danh sách lớp và bản ghi...</span></div> : <RecordsTable rows={records} />}
  </div></aside></div>
}
function Summary({ label, value }: { label: string; value: number }) { return <div><span>{label}</span><b>{value}</b></div> }
function RecordsTable({ rows }: { rows: AttendanceRecordRow[] }) {
  const [recordPage, setRecordPage] = useState(1)
  const paginated = useMemo(() => {
    const start = (recordPage - 1) * 10
    return rows.slice(start, start + 10)
  }, [rows, recordPage])

  if (!rows.length) return <div className="empty-state compact-empty"><span><Users size={28} /></span><h3>Lớp chưa có sinh viên</h3></div>
  return (
    <div>
      <div className="table-scroll">
        <table className="drawer-table attendance-records">
          <thead>
            <tr><th>Sinh viên</th><th>Trạng thái</th><th>Mạng</th><th>Kiểm tra</th></tr>
          </thead>
          <tbody>
            {paginated.map((row) => (
              <tr key={row.id} className={!row.enrolled || row.warning ? "record-warning" : ""}>
                <td><b>{row.fullName || row.rollNumber}</b><small className="cell-note">{row.rollNumber} · {row.email}</small></td>
                <td><AttendanceStatus value={row.status} /></td>
                <td>{row.networkResult}</td>
                <td>{row.warning ? <span className="status status-error"><i />{row.warning}</span> : <span className="status status-success"><i />Hợp lệ</span>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination
        currentPage={recordPage}
        totalItems={rows.length}
        pageSize={10}
        onPageChange={setRecordPage}
        itemLabel="sinh viên trong phiên"
      />
    </div>
  )
}
function AttendanceStatus({ value }: { value: string }) {
  const normalized = value.toLowerCase()
  const tone = normalized === "present" ? "success" : normalized === "late" ? "warning" : normalized === "absent" ? "error" : "neutral"
  const label = normalized === "present" ? "Có mặt" : normalized === "late" ? "Đi muộn" : normalized === "absent" ? "Vắng mặt" : value
  return <span className={`status status-${tone}`}><i />{label}</span>
}
