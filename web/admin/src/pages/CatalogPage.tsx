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
import { classRows } from "../data/mock-data"
import type { Toast } from "../types/admin"
import { Button, Field, PageHeader, SelectField, Status } from "../components/ui"
export function Catalog({
  showToast,
}: {
  showToast: (toast: NonNullable<Toast>) => void
}) {
  const [tab, setTab] = useState("Lớp học")
  const [search, setSearch] = useState("")
  const [editRow, setEditRow] =
    useState<typeof classRows[number] | null | "new">(null)
  const [archive, setArchive] = useState<typeof classRows[number] | null>(null)
  const rows = classRows.filter((row) =>
    `${row.code} ${row.subject} ${row.lecturer}`
      .toLowerCase()
      .includes(search.toLowerCase()),
  )
  return (
    <>
      <PageHeader
        eyebrow="DỮ LIỆU HỌC VỤ"
        title="Quản lý danh mục"
        description="Quản lý lớp học, môn học và ca học trong một không gian thống nhất."
        actions={
          <Button icon={<Plus size={18} />} onClick={() => setEditRow("new")}>
            Thêm {tab.toLowerCase()}
          </Button>
        }
      />
      <div className="tabs">
        {["Lớp học", "Môn học", "Ca học"].map((item) => (
          <button
            className={tab === item ? "active" : ""}
            onClick={() => setTab(item)}
            key={item}
          >
            {item}
            <span>
              {item === "Lớp học" ? 128 : item === "Môn học" ? 42 : 6}
            </span>
          </button>
        ))}
      </div>
      <article className="card table-card">
        <div className="table-toolbar">
          <label className="search-box">
            <Search size={18} />
            <input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder={`Tìm kiếm ${tab.toLowerCase()}...`}
            />
          </label>
          <div>
            <SelectField
              value="Tất cả trạng thái"
              options={["Tất cả trạng thái", "Đang học", "Sắp mở", "Lưu trữ"]}
            />
            <SelectField
              value="Summer 2025"
              options={["Summer 2025", "Spring 2025"]}
            />
            <Button variant="secondary" icon={<SlidersHorizontal size={17} />}>
              Bộ lọc
            </Button>
          </div>
        </div>
        {tab === "Lớp học" ? (
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>Mã lớp</th>
                  <th>Môn học</th>
                  <th>Giảng viên</th>
                  <th>Phòng</th>
                  <th>Ca học</th>
                  <th>Sĩ số</th>
                  <th>Trạng thái</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.code}>
                    <td>
                      <b className="code-link">{row.code}</b>
                    </td>
                    <td>
                      <b>{row.subject}</b>
                    </td>
                    <td>{row.lecturer}</td>
                    <td>{row.room}</td>
                    <td>{row.shift}</td>
                    <td>{row.size} SV</td>
                    <td>
                      <Status>{row.status}</Status>
                    </td>
                    <td>
                      <div className="row-actions">
                        <Button variant="icon" onClick={() => setEditRow(row)}>
                          <Pencil size={17} />
                        </Button>
                        <Button variant="icon" onClick={() => setArchive(row)}>
                          <Archive size={17} />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="empty-state">
            <span>
              <BookOpen size={30} />
            </span>
            <h3>{tab} đang được đồng bộ</h3>
            <p>
              Dữ liệu {tab.toLowerCase()} của học kỳ Summer 2025 đã sẵn sàng để
              quản lý.
            </p>
            <Button icon={<Plus size={17} />} onClick={() => setEditRow("new")}>
              Thêm {tab.toLowerCase()}
            </Button>
          </div>
        )}
        <div className="pagination">
          <span>Hiển thị 1–{rows.length} trong 128 lớp học</span>
          <div>
            <Button variant="icon" disabled>
              <ChevronLeft size={17} />
            </Button>
            <button className="active">1</button>
            <button>2</button>
            <button>3</button>
            <span>…</span>
            <button>26</button>
            <Button variant="icon">
              <ChevronRight size={17} />
            </Button>
          </div>
        </div>
      </article>
      {editRow && (
        <ClassModal
          row={editRow}
          close={() => setEditRow(null)}
          save={() => {
            setEditRow(null)
            showToast({
              title: editRow === "new" ? "Đã thêm lớp học" : "Đã lưu thay đổi",
              detail: "Dữ liệu đã được cập nhật thành công.",
            })
          }}
        />
      )}
      {archive && (
        <ConfirmModal
          title={`Lưu trữ lớp ${archive.code}?`}
          detail="Lớp học sẽ được ẩn khỏi danh sách đang hoạt động. Bạn vẫn có thể khôi phục sau."
          close={() => setArchive(null)}
          confirm={() => {
            setArchive(null)
            showToast({
              title: "Đã lưu trữ lớp học",
              detail: `${archive.code} đã được chuyển vào mục lưu trữ.`,
            })
          }}
        />
      )}
    </>
  )
}

function ClassModal({
  row,
  close,
  save,
}: {
  row: typeof classRows[number] | "new"
  close: () => void
  save: () => void
}) {
  const isNew = row === "new"
  return (
    <div className="modal-layer">
      <div className="scrim" onClick={close} />
      <section className="modal">
        <div className="modal-head">
          <div>
            <span className="eyebrow">THÔNG TIN LỚP HỌC</span>
            <h2>{isNew ? "Thêm lớp học mới" : `Chỉnh sửa ${row.code}`}</h2>
          </div>
          <Button variant="icon" onClick={close}>
            <X size={20} />
          </Button>
        </div>
        <div className="form-grid">
          <Field
            label="Mã lớp"
            placeholder="VD: SE1842"
            value={isNew ? "" : row.code}
          />
          <SelectField
            label="Môn học"
            value={isNew ? "Chọn môn học" : row.subject}
            options={
              isNew
                ? [
                    "Chọn môn học",
                    "Phát triển ứng dụng Web",
                    "An toàn thông tin",
                  ]
                : [row.subject, "An toàn thông tin"]
            }
          />
          <Field
            label="Giảng viên"
            placeholder="Nhập tên giảng viên"
            value={isNew ? "" : row.lecturer}
          />
          <Field
            label="Phòng học"
            placeholder="VD: AL-402"
            value={isNew ? "" : row.room}
          />
          <SelectField
            label="Ca học"
            value={isNew ? "Chọn ca học" : row.shift}
            options={[
              "Chọn ca học",
              "Ca 1 · 07:30",
              "Ca 2 · 09:15",
              "Ca 3 · 12:30",
            ]}
          />
          <Field
            label="Sĩ số dự kiến"
            type="number"
            placeholder="30"
            value={isNew ? "" : String(row.size)}
          />
        </div>
        <div className="modal-actions">
          <Button variant="secondary" onClick={close}>
            Hủy
          </Button>
          <Button icon={<Check size={17} />} onClick={save}>
            {isNew ? "Thêm lớp học" : "Lưu thay đổi"}
          </Button>
        </div>
      </section>
    </div>
  )
}

function ConfirmModal({
  title,
  detail,
  close,
  confirm,
}: {
  title: string
  detail: string
  close: () => void
  confirm: () => void
}) {
  return (
    <div className="modal-layer">
      <div className="scrim" onClick={close} />
      <section className="modal confirm-modal">
        <span className="confirm-icon">
          <Archive size={24} />
        </span>
        <h2>{title}</h2>
        <p>{detail}</p>
        <div className="modal-actions">
          <Button variant="secondary" onClick={close}>
            Hủy
          </Button>
          <Button variant="danger" onClick={confirm}>
            Lưu trữ
          </Button>
        </div>
      </section>
    </div>
  )
}


