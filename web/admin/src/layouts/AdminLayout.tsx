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
import type { Page } from "../types/admin"
import { Button, Logo } from "../components/ui"
export function AdminLayout({
  page,
  setPage,
  children,
  openNotice,
  logout,
}: {
  page: Page
  setPage: (page: Page) => void
  children: ReactNode
  openNotice: () => void
  logout: () => void
}) {
  const [mobileNav, setMobileNav] = useState(false)
  const nav = [
    {
      id: "dashboard" as Page,
      label: "Tổng quan",
      icon: <LayoutDashboard size={20} />,
    },
    {
      id: "catalog" as Page,
      label: "Quản lý danh mục",
      icon: <BookOpen size={20} />,
    },
    {
      id: "requests" as Page,
      label: "Yêu cầu duyệt",
      icon: <FileCheck2 size={20} />,
      badge: "3",
    },
  ]
  const go = (id: Page) => {
    setPage(id)
    setMobileNav(false)
  }
  return (
    <div className="app-shell">
      {mobileNav && (
        <div
          className="scrim mobile-scrim"
          onClick={() => setMobileNav(false)}
        />
      )}
      <aside className={`sidebar ${mobileNav ? "sidebar-open" : ""}`}>
        <div className="sidebar-head">
          <Logo inverse />
          <Button variant="icon" onClick={() => setMobileNav(false)}>
            <X size={20} />
          </Button>
        </div>
        <nav>
          <span className="nav-label">KHÔNG GIAN LÀM VIỆC</span>
          {nav.map((item) => (
            <button
              key={item.id}
              className={page === item.id ? "active" : ""}
              onClick={() => go(item.id)}
            >
              {item.icon}
              <span>{item.label}</span>
              {item.badge && <b>{item.badge}</b>}
            </button>
          ))}
        </nav>
        <div className="sidebar-support">
          <span>
            <Sparkles size={16} /> Hỗ trợ vận hành
          </span>
          <p>Cần trợ giúp về dữ liệu?</p>
          <button>Liên hệ IT Helpdesk</button>
        </div>
        <button className="sidebar-profile" onClick={logout}>
          <span className="avatar">AN</span>
          <span>
            <b>Admin Nguyễn</b>
            <small>Phòng Đào tạo</small>
          </span>
          <LogOut size={17} />
        </button>
      </aside>
      <div className="app-main">
        <header className="topbar">
          <div className="topbar-left">
            <Button
              variant="icon"
              className="menu-button"
              onClick={() => setMobileNav(true)}
            >
              <Menu size={21} />
            </Button>
            <div className="breadcrumb">
              <span>FAP Check-in</span>
              <ChevronRight size={14} />
              <b>
                {page === "dashboard"
                  ? "Tổng quan"
                  : page === "catalog"
                    ? "Quản lý danh mục"
                    : "Yêu cầu duyệt"}
              </b>
            </div>
          </div>
          <div className="topbar-actions">
            <Button icon={<Send size={17} />} onClick={openNotice}>
              <span className="desktop-label">Tạo thông báo</span>
              <span className="mobile-label">Thông báo</span>
            </Button>
            <Button variant="icon" className="notification-button">
              <Bell size={20} />
              <i />
            </Button>
            <div className="top-avatar">
              <span className="avatar">AN</span>
              <span>
                <b>Admin Nguyễn</b>
                <small>Quản trị viên</small>
              </span>
              <ChevronDown size={16} />
            </div>
          </div>
        </header>
        <div className="content">{children}</div>
      </div>
    </div>
  )
}


