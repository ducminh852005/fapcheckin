import { BookOpen, Clock3, GraduationCap, Search } from "lucide-react"
import { useState } from "react"
import { PageHeader } from "../components/ui"

const tabs = {
  classes: { label: "Lớp học", source: "classes", icon: <GraduationCap size={28} />, description: "Mã lớp, môn học, phòng, slot, sĩ số và giảng viên phụ trách." },
  subjects: { label: "Môn học", source: "subjects", icon: <BookOpen size={28} />, description: "Mã môn, tên môn và số tín chỉ." },
  slots: { label: "Khung giờ", source: "slots + timeSlots", icon: <Clock3 size={28} />, description: "Cấu hình slot A/P và giờ bắt đầu, kết thúc." },
} as const

export function AcademicData() {
  const [tab, setTab] = useState<keyof typeof tabs>("classes")
  const current = tabs[tab]
  return (
    <>
      <PageHeader title="Dữ liệu học vụ" description="Quản lý dữ liệu tham chiếu phục vụ lịch học và điểm danh." />
      <div className="tabs">
        {(Object.entries(tabs) as Array<[keyof typeof tabs, typeof tabs[keyof typeof tabs]]>).map(([id, item]) => <button key={id} className={tab === id ? "active" : ""} onClick={() => setTab(id)}>{item.label}</button>)}
      </div>
      <article className="card table-card">
        <div className="table-toolbar"><label className="search-box"><Search size={18} /><input placeholder={`Tìm ${current.label.toLowerCase()}...`} disabled /></label><span className="source-chip">Nguồn: {current.source}</span></div>
        <div className="empty-state compact-empty"><span>{current.icon}</span><h3>Chưa kết nối {current.label.toLowerCase()}</h3><p>{current.description} Không hiển thị số lượng, học kỳ hoặc trạng thái giả.</p></div>
      </article>
      <section className="policy-grid">
        <article><b>Không sửa mã định danh</b><p>Mã lớp và mã môn là document ID; khóa sau khi tạo.</p></article>
        <article><b>Không xóa dữ liệu đang được dùng</b><p>Kiểm tra lớp và enrollment trước khi xóa môn hoặc slot.</p></article>
        <article><b>Phân công phải đồng bộ</b><p>Đổi giảng viên cần cập nhật cả classes và enrollments bằng batch.</p></article>
      </section>
    </>
  )
}
