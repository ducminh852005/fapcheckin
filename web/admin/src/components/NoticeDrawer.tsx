import { useMemo, useState, type ReactNode } from "react"
import {
  Archive,
  Bell,
  BookOpen,
  CalendarDays,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  CircleAlert,
  Clock3,
  FileCheck2,
  GraduationCap,
  Inbox,
  LayoutDashboard,
  LoaderCircle,
  LogOut,
  Menu,
  MessageSquareText,
  MoreHorizontal,
  Pencil,
  Plus,
  Search,
  Send,
  ShieldCheck,
  SlidersHorizontal,
  Sparkles,
  Users,
  WifiOff,
  X,
  XCircle,
} from "lucide-react"
import { Button, Field, SelectField } from "./ui"
export function NoticeDrawer({
  close,
  send,
}: {
  close: () => void
  send: () => void
}) {
  const [recipient, setRecipient] = useState("Tất cả")
  const [schedule, setSchedule] = useState("Gửi ngay")
  return (
    <div className="drawer-layer">
      <div className="scrim" onClick={close} />
      <aside className="drawer notice-drawer">
        <div className="drawer-head">
          <div>
            <span className="eyebrow">TRUYỀN THÔNG</span>
            <h2>Tạo thông báo</h2>
            <p>Gửi thông tin tới đúng người, đúng thời điểm.</p>
          </div>
          <Button variant="icon" onClick={close}>
            <X size={21} />
          </Button>
        </div>
        <div className="drawer-body">
          <Field
            label="Tiêu đề *"
            placeholder="VD: Thay đổi phòng học ngày 20/05"
          />
          <label className="field">
            <span>Nội dung *</span>
            <textarea placeholder="Nhập nội dung thông báo..." rows={5} />
            <small>0 / 500 ký tự</small>
          </label>
          <div className="field">
            <span>Người nhận</span>
            <div className="segment-grid">
              {["Tất cả", "Giảng viên", "Sinh viên", "Lớp cụ thể"].map(
                (item) => (
                  <button
                    className={recipient === item ? "active" : ""}
                    onClick={() => setRecipient(item)}
                    key={item}
                  >
                    {item === "Tất cả" ? (
                      <Users size={18} />
                    ) : item === "Giảng viên" ? (
                      <GraduationCap size={18} />
                    ) : item === "Sinh viên" ? (
                      <Users size={18} />
                    ) : (
                      <BookOpen size={18} />
                    )}
                    <span>{item}</span>
                  </button>
                ),
              )}
            </div>
          </div>
          {recipient === "Lớp cụ thể" && (
            <SelectField
              label="Chọn lớp"
              value="Chọn một hoặc nhiều lớp"
              options={[
                "Chọn một hoặc nhiều lớp",
                "SE1842",
                "IA1701",
                "GD1830",
              ]}
            />
          )}
          <SelectField
            label="Mức độ"
            value="Thông tin"
            options={["Thông tin", "Quan trọng", "Khẩn cấp"]}
          />
          <div className="field">
            <span>Thời gian gửi</span>
            <div className="radio-row">
              {["Gửi ngay", "Lên lịch"].map((item) => (
                <button
                  className={schedule === item ? "active" : ""}
                  onClick={() => setSchedule(item)}
                  key={item}
                >
                  <i />
                  {item}
                </button>
              ))}
            </div>
          </div>
          {schedule === "Lên lịch" && (
            <div className="form-grid">
              <Field label="Ngày gửi" type="date" />
              <Field label="Giờ gửi" type="time" />
            </div>
          )}
          <label className="switch-row">
            <span>
              <Bell size={19} />
              <span>
                <b>Push notification</b>
                <small>Gửi thông báo đẩy tới thiết bị</small>
              </span>
            </span>
            <input type="checkbox" defaultChecked />
            <i />
          </label>
          <section className="phone-preview">
            <div className="preview-title">
              <span>
                <MessageSquareText size={18} /> Preview Mobile Inbox
              </span>
              <span>Xem trước</span>
            </div>
            <div className="phone-card">
              <span className="app-icon">
                <Check size={15} />
              </span>
              <div>
                <span>FAP CHECK-IN · BÂY GIỜ</span>
                <b>Thông báo từ Phòng Đào tạo</b>
                <p>Nội dung thông báo của bạn sẽ hiển thị tại đây.</p>
              </div>
              <MoreHorizontal size={17} />
            </div>
          </section>
        </div>
        <div className="drawer-actions">
          <Button variant="secondary" onClick={close}>
            Lưu nháp
          </Button>
          <Button
            icon={
              schedule === "Gửi ngay" ? (
                <Send size={17} />
              ) : (
                <Clock3 size={17} />
              )
            }
            onClick={send}
          >
            {schedule}
          </Button>
        </div>
      </aside>
    </div>
  )
}

