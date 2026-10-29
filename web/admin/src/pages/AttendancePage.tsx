import { AlertTriangle, ClipboardCheck, Search } from "lucide-react"
import { PageHeader, SelectField } from "../components/ui"

export function Attendance() {
  return (
    <>
      <PageHeader eyebrow="VẬN HÀNH ĐIỂM DANH" title="Giám sát điểm danh" description="Tìm phiên và bản ghi cần xử lý; không thay thế báo cáo chuyên cần của giảng viên." />
      <div className="filter-bar operational-filter"><label className="search-box"><Search size={18} /><input placeholder="Tìm mã lớp, mã sinh viên hoặc session ID..." disabled /></label><SelectField value="Tất cả trạng thái" options={["Tất cả trạng thái", "Đang mở", "Đã đóng"]} /><SelectField value="Hôm nay" options={["Hôm nay", "7 ngày gần nhất", "30 ngày gần nhất"]} /></div>
      <section className="monitor-grid">
        <article className="card monitor-card"><span className="monitor-icon warning"><AlertTriangle size={22} /></span><div><small>PHIÊN ĐANG MỞ</small><strong>—</strong><p>Nguồn: sessions.sessionStatus</p></div></article>
        <article className="card monitor-card"><span className="monitor-icon danger"><ClipboardCheck size={22} /></span><div><small>CHƯA ĐỒNG BỘ FAP</small><strong>—</strong><p>Nguồn: attendance_records.syncedToFap</p></div></article>
      </section>
      <article className="card table-card">
        <div className="table-toolbar"><div><b>Phiên điểm danh</b><span className="source-chip">sessions + attendance_records</span></div></div>
        <div className="empty-state compact-empty"><span><ClipboardCheck size={28} /></span><h3>Chưa có dữ liệu được tải</h3><p>Khi repository được nối, bảng sẽ hiển thị lớp, ngày, slot, giảng viên, trạng thái phiên và tổng số bản ghi. QR secret và địa chỉ IP không hiển thị.</p></div>
      </article>
    </>
  )
}
