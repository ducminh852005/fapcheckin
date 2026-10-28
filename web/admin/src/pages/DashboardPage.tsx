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
import { Button, PageHeader, SelectField } from "../components/ui"
export function Dashboard() {
  const kpis = [
    {
      label: "Tổng ca học",
      value: "248",
      delta: "+12,4%",
      note: "so với tuần trước",
      icon: <CalendarDays size={20} />,
      tone: "blue",
    },
    {
      label: "Tỷ lệ đi học",
      value: "93,6%",
      delta: "+2,1%",
      note: "so với tuần trước",
      icon: <CheckCircle2 size={20} />,
      tone: "green",
    },
    {
      label: "Ca vắng bất thường",
      value: "12",
      delta: "Cần xử lý",
      note: "tại 8 lớp học",
      icon: <CircleAlert size={20} />,
      tone: "red",
    },
    {
      label: "Yêu cầu chờ duyệt",
      value: "18",
      delta: "5 mới",
      note: "trong hôm nay",
      icon: <FileCheck2 size={20} />,
      tone: "orange",
    },
  ]
  const chart = [64, 78, 70, 86, 82, 92, 75]
  return (
    <>
      <PageHeader
        eyebrow="THỨ HAI, 19 THÁNG 5"
        title="Chào buổi sáng, Admin"
        description="Đây là tổng quan hoạt động chuyên cần tại FPT Education hôm nay."
      />
      <div className="filter-bar">
        <div>
          <SlidersHorizontal size={18} />
          <b>Bộ lọc</b>
        </div>
        <SelectField
          value="7 ngày gần nhất"
          options={["7 ngày gần nhất", "30 ngày gần nhất", "Học kỳ hiện tại"]}
        />
        <SelectField
          value="Summer 2025"
          options={["Summer 2025", "Spring 2025", "Fall 2024"]}
        />
        <SelectField
          value="Tất cả môn học"
          options={[
            "Tất cả môn học",
            "Phát triển ứng dụng Web",
            "An toàn thông tin",
          ]}
        />
        <Button variant="ghost">Đặt lại</Button>
      </div>
      <section className="kpi-grid">
        {kpis.map((kpi) => (
          <article className="kpi-card" key={kpi.label}>
            <div className={`kpi-icon kpi-${kpi.tone}`}>{kpi.icon}</div>
            <span>{kpi.label}</span>
            <strong>{kpi.value}</strong>
            <p>
              <b className={kpi.tone === "red" ? "text-error" : ""}>
                {kpi.delta}
              </b>{" "}
              {kpi.note}
            </p>
          </article>
        ))}
      </section>
      <section className="dashboard-grid">
        <article className="card chart-card">
          <div className="card-head">
            <div>
              <h3>Chuyên cần 7 ngày qua</h3>
              <p>Tỷ lệ sinh viên có mặt theo ngày</p>
            </div>
            <div className="legend">
              <i /> Có mặt <i /> Đi muộn
            </div>
          </div>
          <div className="chart-area">
            <div className="y-axis">
              <span>100%</span>
              <span>75%</span>
              <span>50%</span>
              <span>25%</span>
              <span>0%</span>
            </div>
            <div className="bars">
              {chart.map((height, index) => (
                <div className="bar-column" key={index}>
                  <div className="bar-stack">
                    <div
                      className="bar-primary"
                      style={{ height: `${height}%` }}
                    />
                    <div
                      className="bar-late"
                      style={{ height: `${Math.max(7, 19 - index * 2)}%` }}
                    />
                  </div>
                  <span>
                    {["T2", "T3", "T4", "T5", "T6", "T7", "CN"][index]}
                  </span>
                </div>
              ))}
            </div>
          </div>
          <div className="chart-summary">
            <span>
              <b>93,6%</b> Trung bình
            </span>
            <span>
              <b>2.841</b> Lượt check-in
            </span>
            <span>
              <b>164</b> Đi muộn
            </span>
          </div>
        </article>
        <article className="card absence-card">
          <div className="card-head">
            <div>
              <h3>Top môn vắng nhiều</h3>
              <p>Trong 7 ngày gần nhất</p>
            </div>
            <Button variant="ghost">Xem tất cả</Button>
          </div>
          {[
            ["PRN212", "Lập trình C#", 18, 72],
            ["IOT102", "Internet vạn vật", 14, 57],
            ["MAS291", "Xác suất thống kê", 11, 45],
            ["JPD113", "Tiếng Nhật sơ cấp", 9, 36],
          ].map(([code, name, count, width]) => (
            <div className="absence-row" key={code}>
              <span className="subject-code">{code}</span>
              <div>
                <b>{name}</b>
                <div className="progress">
                  <i style={{ width: `${width}%` }} />
                </div>
              </div>
              <strong>
                {count}
                <small> lượt</small>
              </strong>
            </div>
          ))}
        </article>
        <article className="card requests-widget">
          <div className="card-head">
            <div>
              <h3>Yêu cầu mới</h3>
              <p>Cần được xem xét</p>
            </div>
            <span className="count-chip">18 chờ duyệt</span>
          </div>
          {requestRows.slice(0, 3).map((row) => (
            <div className="mini-request" key={row.id}>
              <span className="mini-avatar">
                {row.name
                  .split(" ")
                  .slice(-2)
                  .map((x) => x[0])
                  .join("")}
              </span>
              <div>
                <b>{row.name}</b>
                <p>
                  {row.change} · {row.className}
                </p>
              </div>
              <span>{row.time}</span>
            </div>
          ))}
        </article>
        <article className="card activity-widget">
          <div className="card-head">
            <div>
              <h3>Hoạt động gần đây</h3>
              <p>Cập nhật trực tiếp</p>
            </div>
            <span className="live">
              <i /> REALTIME
            </span>
          </div>
          {[
            ["check", "Đã duyệt YC-240516", "Lê Hoàng Phúc · 4 phút trước"],
            ["class", "Cập nhật lớp SE1842", "Nguyễn Văn Minh · 18 phút trước"],
            [
              "notice",
              "Đã gửi thông báo lịch thi",
              "Tới 246 sinh viên · 32 phút trước",
            ],
          ].map(([type, title, meta]) => (
            <div className="activity-row" key={title}>
              <span className={`activity-icon ${type}`}>
                {type === "check" ? (
                  <Check size={16} />
                ) : type === "class" ? (
                  <BookOpen size={16} />
                ) : (
                  <Bell size={16} />
                )}
              </span>
              <div>
                <b>{title}</b>
                <p>{meta}</p>
              </div>
            </div>
          ))}
        </article>
      </section>
    </>
  )
}



