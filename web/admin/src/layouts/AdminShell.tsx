import { useState, type ReactNode } from "react"
import {
  BookOpen,
  ChevronRight,
  ClipboardCheck,
  LayoutDashboard,
  LogOut,
  Menu,
  ShieldCheck,
  Users,
  X,
} from "lucide-react"
import { Button, Logo } from "../components/ui"
import type { AdminProfile } from "../firebase/admin-auth"
import type { AdminPage } from "../types/admin-v2"

const navigation: Array<{ id: AdminPage; label: string; icon: ReactNode }> = [
  { id: "dashboard", label: "Tổng quan", icon: <LayoutDashboard size={19} /> },
  { id: "accounts", label: "Tài khoản", icon: <Users size={19} /> },
  { id: "academic", label: "Dữ liệu học vụ", icon: <BookOpen size={19} /> },
  { id: "attendance", label: "Giám sát điểm danh", icon: <ClipboardCheck size={19} /> },
]

const titles: Record<AdminPage, string> = {
  dashboard: "Tổng quan",
  accounts: "Tài khoản",
  academic: "Dữ liệu học vụ",
  attendance: "Giám sát điểm danh",
}

export function AdminShell({ page, setPage, children, profile, logout }: {
  page: AdminPage
  setPage: (page: AdminPage) => void
  children: ReactNode
  profile: AdminProfile
  logout: () => Promise<void>
}) {
  const [mobileNav, setMobileNav] = useState(false)
  const go = (id: AdminPage) => {
    setPage(id)
    setMobileNav(false)
  }

  return (
    <div className="app-shell admin-v2">
      {mobileNav && <div className="scrim mobile-scrim" onClick={() => setMobileNav(false)} />}
      <aside className={`sidebar ${mobileNav ? "sidebar-open" : ""}`}>
        <div className="sidebar-head">
          <Logo inverse />
          <Button variant="icon" onClick={() => setMobileNav(false)}><X size={20} /></Button>
        </div>
        <nav>
          <span className="nav-label">QUẢN TRỊ HỆ THỐNG</span>
          {navigation.map((item) => (
            <button key={item.id} className={page === item.id ? "active" : ""} onClick={() => go(item.id)}>
              {item.icon}<span>{item.label}</span>
            </button>
          ))}
        </nav>
        <div className="sidebar-support admin-scope">
          <span><ShieldCheck size={16} /> Phạm vi quản trị</span>
          <p>Tài khoản, dữ liệu học vụ và vận hành điểm danh.</p>
        </div>
        <button className="sidebar-profile" onClick={() => void logout()}>
          <span className="avatar">{initials(profile.fullName)}</span>
          <span><b>{profile.fullName}</b><small>{profile.email}</small></span>
          <LogOut size={17} />
        </button>
      </aside>
      <div className="app-main">
        <header className="topbar">
          <div className="topbar-left">
            <Button variant="icon" className="menu-button" onClick={() => setMobileNav(true)}><Menu size={21} /></Button>
            <div className="breadcrumb"><span>FAP Check-in</span><ChevronRight size={14} /><b>{titles[page]}</b></div>
          </div>
        </header>
        <div className="content">{children}</div>
      </div>
    </div>
  )
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  return parts.slice(-2).map((part) => part[0]?.toUpperCase()).join("") || "AD"
}
