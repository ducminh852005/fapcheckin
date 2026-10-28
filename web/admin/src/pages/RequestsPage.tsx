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
import { requestRows } from "../data/mock-data"
import type { Toast } from "../types/admin"
import { Button, Field, PageHeader, SelectField, Status } from "../components/ui"
export function Requests({
  showToast,
}: {
  showToast: (toast: NonNullable<Toast>) => void
}) {
  const [tab, setTab] = useState("Tất cả")
  const [selected, setSelected] = useState<typeof requestRows[number] | null>(
    null,
  )
  const rows =
    tab === "Tất cả"
      ? requestRows
      : requestRows.filter((row) => row.status === tab)
  return (
    <>
      <PageHeader
        eyebrow="KIỂM SOÁT THAY ĐỔI"
        title="Yêu cầu duyệt"
        description="Xác minh yêu cầu điều chỉnh dữ liệu chuyên cần của sinh viên."
        actions={
          <div className="realtime-pill">
            <i /> Cập nhật realtime
          </div>
        }
      />
      <div className="tabs request-tabs">
        {["Tất cả", "Chờ duyệt", "Đã duyệt", "Đã từ chối"].map((item) => (
          <button
            className={tab === item ? "active" : ""}
            onClick={() => setTab(item)}
            key={item}
          >
            {item}
            <span>
              {item === "Tất cả"
                ? 42
                : item === "Chờ duyệt"
                  ? 18
                  : item === "Đã duyệt"
                    ? 20
                    : 4}
            </span>
          </button>
        ))}
      </div>
      <article className="card table-card">
        <div className="table-toolbar">
          <label className="search-box">
            <Search size={18} />
            <input placeholder="Tìm mã yêu cầu, tên hoặc mã SV..." />
          </label>
          <div>
            <SelectField
              value="7 ngày gần nhất"
              options={["7 ngày gần nhất", "30 ngày gần nhất"]}
            />
            <Button variant="secondary" icon={<SlidersHorizontal size={17} />}>
              Bộ lọc
            </Button>
          </div>
        </div>
        <div className="table-scroll">
          <table className="request-table">
            <thead>
              <tr>
                <th>Mã yêu cầu</th>
                <th>Người gửi</th>
                <th>Lớp</th>
                <th>Buổi học</th>
                <th>Nội dung thay đổi</th>
                <th>Thời gian</th>
                <th>Trạng thái</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id} onClick={() => setSelected(row)}>
                  <td>
                    <b className="code-link">{row.id}</b>
                  </td>
                  <td>
                    <div className="person-cell">
                      <span className="mini-avatar">
                        {row.name
                          .split(" ")
                          .slice(-2)
                          .map((x) => x[0])
                          .join("")}
                      </span>
                      <span>
                        <b>{row.name}</b>
                        <small>{row.student}</small>
                      </span>
                    </div>
                  </td>
                  <td>
                    <b>{row.className}</b>
                  </td>
                  <td>{row.session}</td>
                  <td>{row.change}</td>
                  <td>{row.time}</td>
                  <td>
                    <Status>{row.status}</Status>
                  </td>
                  <td>
                    <Button variant="icon">
                      <ChevronRight size={17} />
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {rows.length === 0 && (
          <div className="empty-state">
            <span>
              <Inbox size={30} />
            </span>
            <h3>Không có yêu cầu</h3>
            <p>Chưa có yêu cầu nào trong trạng thái này.</p>
          </div>
        )}
        <div className="pagination">
          <span>
            Hiển thị 1–{rows.length} trong {rows.length} yêu cầu
          </span>
          <div>
            <Button variant="icon" disabled>
              <ChevronLeft size={17} />
            </Button>
            <button className="active">1</button>
            <Button variant="icon" disabled>
              <ChevronRight size={17} />
            </Button>
          </div>
        </div>
      </article>
      {selected && (
        <RequestDrawer
          request={selected}
          close={() => setSelected(null)}
          action={(type) => {
            setSelected(null)
            showToast({
              title:
                type === "approve"
                  ? "Đã phê duyệt yêu cầu"
                  : "Đã từ chối yêu cầu",
              detail: `${selected.id} đã được cập nhật và đồng bộ realtime.`,
              tone: type === "approve" ? "success" : "error",
            })
          }}
        />
      )}
    </>
  )
}

function RequestDrawer({
  request,
  close,
  action,
}: {
  request: typeof requestRows[number]
  close: () => void
  action: (type: "approve" | "reject") => void
}) {
  const [rejecting, setRejecting] = useState(false)
  const [reason, setReason] = useState("")
  return (
    <div className="drawer-layer">
      <div className="scrim" onClick={close} />
      <aside className="drawer">
        <div className="drawer-head">
          <div>
            <span className="eyebrow">CHI TIẾT YÊU CẦU</span>
            <h2>{request.id}</h2>
          </div>
          <Button variant="icon" onClick={close}>
            <X size={21} />
          </Button>
        </div>
        <div className="drawer-body">
          <div className="request-person">
            <span className="large-avatar">
              {request.name
                .split(" ")
                .slice(-2)
                .map((x) => x[0])
                .join("")}
            </span>
            <div>
              <h3>{request.name}</h3>
              <p>
                {request.student} · {request.className}
              </p>
            </div>
            <Status>{request.status}</Status>
          </div>
          <section className="detail-section">
            <h4>Thay đổi được đề xuất</h4>
            <div className="change-box">
              <div>
                <span>Trạng thái hiện tại</span>
                <b className="old-value">Vắng mặt</b>
              </div>
              <ChevronRight size={20} />
              <div>
                <span>Thay đổi thành</span>
                <b className="new-value">Có mặt</b>
              </div>
            </div>
          </section>
          <section className="detail-section">
            <h4>Lý do</h4>
            <p>
              Sinh viên gặp lỗi kết nối Wi-Fi tại tòa Alpha nên không thể
              check-in đúng giờ. Giảng viên đã xác nhận sinh viên có mặt trong
              suốt buổi học.
            </p>
          </section>
          <section className="detail-section">
            <h4>Minh chứng đính kèm</h4>
            <div className="evidence">
              <span>
                <FileCheck2 size={22} />
              </span>
              <div>
                <b>xac-nhan-giang-vien.pdf</b>
                <small>PDF · 824 KB</small>
              </div>
              <Button variant="ghost">Xem</Button>
            </div>
          </section>
          <section className="detail-section">
            <h4>Lịch sử</h4>
            <div className="timeline">
              <div>
                <i />
                <p>
                  <b>Yêu cầu được tạo</b>
                  <span>
                    {request.name} · {request.time}
                  </span>
                </p>
              </div>
              <div>
                <i />
                <p>
                  <b>Hệ thống đã tiếp nhận</b>
                  <span>Tự động · 1 phút sau</span>
                </p>
              </div>
            </div>
          </section>
          {rejecting && (
            <section className="reject-box">
              <Field
                label="Lý do từ chối *"
                placeholder="Nhập lý do để sinh viên có thể điều chỉnh..."
                value={reason}
                onChange={setReason}
              />
              <small>Lý do sẽ được gửi tới sinh viên.</small>
            </section>
          )}
        </div>
        {request.status === "Chờ duyệt" && (
          <div className="drawer-actions">
            {rejecting ? (
              <>
                <Button variant="secondary" onClick={() => setRejecting(false)}>
                  Quay lại
                </Button>
                <Button
                  variant="danger"
                  disabled={!reason.trim()}
                  onClick={() => action("reject")}
                >
                  Xác nhận từ chối
                </Button>
              </>
            ) : (
              <>
                <Button
                  variant="secondary"
                  icon={<XCircle size={18} />}
                  onClick={() => setRejecting(true)}
                >
                  Từ chối
                </Button>
                <Button
                  icon={<CheckCircle2 size={18} />}
                  onClick={() => action("approve")}
                >
                  Phê duyệt
                </Button>
              </>
            )}
          </div>
        )}
      </aside>
    </div>
  )
}


