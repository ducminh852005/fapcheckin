import { AlertTriangle, BookOpen, ClipboardCheck, Database, RefreshCw, Users } from "lucide-react"
import { Button, PageHeader } from "../components/ui"
import type { AdminPage } from "../types/admin-v2"

const metrics = [
  { label: "Tài khoản hoạt động", icon: <Users size={20} />, tone: "blue" },
  { label: "Lớp đang quản lý", icon: <BookOpen size={20} />, tone: "green" },
  { label: "Phiên đang mở", icon: <ClipboardCheck size={20} />, tone: "orange" },
  { label: "Chưa đồng bộ FAP", icon: <RefreshCw size={20} />, tone: "red" },
]

export function OperationsDashboard({ onNavigate }: { onNavigate: (page: AdminPage) => void }) {
  return (
    <>
      <PageHeader eyebrow="VẬN HÀNH HỆ THỐNG" title="Tổng quan quản trị" description="Theo dõi những dữ liệu cần hành động, không hiển thị báo cáo học vụ chưa có nguồn xác thực." />
      <section className="connection-banner">
        <span><Database size={20} /></span>
        <div><b>Chưa kết nối Firebase trên Admin Web</b><p>Các chỉ số sẽ hiển thị sau khi chuẩn hóa users/&#123;authUid&#125; và nối repository. Giao diện không dùng số liệu mẫu.</p></div>
        <span className="status status-warning"><i /> Chờ tích hợp</span>
      </section>
      <section className="kpi-grid operational-kpis">
        {metrics.map((metric) => (
          <article className="kpi-card" key={metric.label}>
            <div className={`kpi-icon kpi-${metric.tone}`}>{metric.icon}</div>
            <span>{metric.label}</span><strong>—</strong>
          </article>
        ))}
      </section>
      <section className="operations-grid">
        <article className="card action-panel">
          <div className="card-head"><div><h3>Công việc quản trị</h3><p>Các khu vực admin cần kiểm tra thường xuyên</p></div></div>
          <button onClick={() => onNavigate("accounts")}><span className="action-icon blue"><Users size={18} /></span><span><b>Tài khoản và quyền truy cập</b><small>Cấp invite, khóa tài khoản và kiểm tra vai trò</small></span><strong>Đi tới</strong></button>
          <button onClick={() => onNavigate("attendance")}><span className="action-icon orange"><ClipboardCheck size={18} /></span><span><b>Phiên và bản ghi điểm danh</b><small>Tìm phiên mở, bản ghi chưa đồng bộ hoặc dữ liệu lỗi</small></span><strong>Đi tới</strong></button>
          <button onClick={() => onNavigate("academic")}><span className="action-icon green"><BookOpen size={18} /></span><span><b>Dữ liệu học vụ</b><small>Quản lý lớp, môn, phân công và khung giờ</small></span><strong>Đi tới</strong></button>
        </article>
        <article className="card attention-panel">
          <div className="card-head"><div><h3>Cần hoàn tất trước khi vận hành</h3><p>Các ràng buộc phát hiện từ Firestore</p></div></div>
          <div className="attention-item"><AlertTriangle size={18} /><div><b>Chuẩn hóa hồ sơ người dùng</b><p>Document ID phải là Auth UID; role dùng user, staff hoặc admin.</p></div></div>
          <div className="attention-item"><Database size={18} /><div><b>Chọn schema canonical</b><p>Dùng classes, sessions, attendance_records và class_schedules; ngừng ghi collection legacy.</p></div></div>
          <Button variant="secondary" onClick={() => onNavigate("accounts")}>Xem khu vực tài khoản</Button>
        </article>
      </section>
    </>
  )
}
