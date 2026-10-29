import { AlertTriangle, BookOpen, ClipboardCheck, RotateCw, Users } from "lucide-react"
import { useCallback } from "react"
import { Button, PageHeader } from "../components/ui"
import { useAsyncData } from "../hooks/useAsyncData"
import { getDashboardStats } from "../repositories/dashboardRepository"
import type { AdminPage } from "../types/admin-v2"

export function LiveDashboard({ onNavigate }: { onNavigate: (page: AdminPage) => void }) {
  const loader = useCallback(getDashboardStats, [])
  const { data, loading, error, reload } = useAsyncData(loader)
  const metrics = [
    { label: "Tài khoản hoạt động", value: data?.activeUsers, source: "users.active", icon: <Users size={20} />, tone: "blue" },
    { label: "Lớp đang quản lý", value: data?.classes, source: "classes", icon: <BookOpen size={20} />, tone: "green" },
    { label: "Phiên đang mở", value: data?.openSessions, source: "sessions", icon: <ClipboardCheck size={20} />, tone: "orange" },
    { label: "Tài khoản chưa liên kết", value: data?.legacyAccounts, source: "users.role SV/GV", icon: <AlertTriangle size={20} />, tone: "red" },
  ]
  return (
    <>
      <PageHeader eyebrow="VẬN HÀNH HỆ THỐNG" title="Tổng quan quản trị" description="Các chỉ số hành động được đọc trực tiếp từ Firestore." actions={<Button variant="secondary" icon={<RotateCw size={16} />} onClick={reload} disabled={loading}>Làm mới</Button>} />
      {error && <section className="data-error"><b>Không thể tải tổng quan</b><span>{error}</span></section>}
      <section className="kpi-grid operational-kpis">
        {metrics.map((metric) => <article className="kpi-card" key={metric.label}><div className={`kpi-icon kpi-${metric.tone}`}>{metric.icon}</div><span>{metric.label}</span><strong>{loading ? "…" : metric.value ?? 0}</strong><p>Nguồn: <b>{metric.source}</b></p></article>)}
      </section>
      <section className="operations-grid single-operations">
        <article className="card action-panel">
          <div className="card-head"><div><h3>Công việc quản trị</h3><p>Đi nhanh tới khu vực cần kiểm tra</p></div></div>
          <button onClick={() => onNavigate("accounts")}><span className="action-icon blue"><Users size={18} /></span><span><b>Tài khoản và quyền truy cập</b><small>Cấp quyền, khóa tài khoản và liên kết dữ liệu cũ</small></span><strong>Đi tới</strong></button>
          <button onClick={() => onNavigate("attendance")}><span className="action-icon orange"><ClipboardCheck size={18} /></span><span><b>Phiên và bản ghi điểm danh</b><small>Tìm phiên mở và bản ghi chưa đồng bộ</small></span><strong>Đi tới</strong></button>
          <button onClick={() => onNavigate("academic")}><span className="action-icon green"><BookOpen size={18} /></span><span><b>Dữ liệu học vụ</b><small>Xem lớp, môn và khung giờ đang sử dụng</small></span><strong>Đi tới</strong></button>
        </article>
      </section>
    </>
  )
}
