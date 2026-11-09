import { collection, getCountFromServer, query, where } from "firebase/firestore"
import { useEffect, useRef, useState, type ReactNode } from "react"
import {
  Bell,
  Activity,
  CheckCheck,
  ClipboardCheck,
  Bug,
  FileText,
  FolderKanban,
  HelpCircle,
  History,
  KeyRound,
  LayoutDashboard,
  LineChart,
  LogOut,
  Megaphone,
  Menu,
  Radio,
  Settings,
  ShieldCheck,
  X,
} from "lucide-react"
import type { AdminProfile } from "../firebase/admin-auth"
import { firestore } from "../firebase/client"
import {
  markSingleRead,
  saveReadIds,
  subscribeHeaderNotifications,
  type HeaderNotificationItem,
} from "../repositories/notificationRepository"
import type { AdminPage } from "../types/admin-v2"

export function AdminShell({
  page,
  setPage,
  children,
  profile,
  logout,
}: {
  page: AdminPage
  setPage: (page: AdminPage) => void
  children: ReactNode
  profile: AdminProfile
  logout: () => Promise<void>
}) {
  const [mobileNav, setMobileNav] = useState(false)
  const [showUserMenu, setShowUserMenu] = useState(false)
  const [classesCount, setClassesCount] = useState<number | null>(null)
  const [openSessionsCount, setOpenSessionsCount] = useState<number | null>(null)
  const [pendingFeedbackCount, setPendingFeedbackCount] = useState<number | null>(null)
  const [notifications, setNotifications] = useState<HeaderNotificationItem[]>([])
  const [showNotifications, setShowNotifications] = useState(false)
  const [selectedNotification, setSelectedNotification] = useState<HeaderNotificationItem | null>(null)
  const [notifFilter, setNotifFilter] = useState<"all" | "academic" | "announcement" | "system">("all")
  const userMenuRef = useRef<HTMLDivElement>(null)
  const notifRef = useRef<HTMLDivElement>(null)
  const closeTimerRef = useRef<number | null>(null)

  useEffect(() => {
    const unsub = subscribeHeaderNotifications((items) => {
      setNotifications(items)
    })
    return () => unsub()
  }, [])

  useEffect(() => {
    void (async () => {
      const [classesSnap, openSnap, feedbackSnap] = await Promise.all([
        getCountFromServer(collection(firestore, "classes")).catch(() => null),
        getCountFromServer(
          query(collection(firestore, "sessions"), where("sessionStatus", "==", "open"))
        ).catch(() => null),
        getCountFromServer(
          query(collection(firestore, "feedback"), where("status", "==", "pending"))
        ).catch(() => null),
      ])
      if (classesSnap) setClassesCount(classesSnap.data().count)
      if (openSnap) setOpenSessionsCount(openSnap.data().count)
      if (feedbackSnap) setPendingFeedbackCount(feedbackSnap.data().count)
    })()
  }, [page])

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setShowUserMenu(false)
      }
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
        setShowNotifications(false)
      }
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => {
      document.removeEventListener("mousedown", handleClickOutside)
      if (closeTimerRef.current) clearTimeout(closeTimerRef.current)
    }
  }, [])

  const unreadCount = notifications.filter((n) => n.unread).length

  const handleMarkAllRead = () => {
    saveReadIds(notifications.map((n) => n.id))
    setNotifications((prev) => prev.map((n) => ({ ...n, unread: false })))
  }

  const handleItemClick = (item: HeaderNotificationItem) => {
    markSingleRead(item.id)
    setNotifications((prev) =>
      prev.map((n) => (n.id === item.id ? { ...n, unread: false } : n))
    )
    setShowNotifications(false)
    setSelectedNotification(item)
  }

  useEffect(() => {
    if (!selectedNotification) return

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setSelectedNotification(null)
    }

    document.addEventListener("keydown", handleKeyDown)
    return () => document.removeEventListener("keydown", handleKeyDown)
  }, [selectedNotification])

  useEffect(() => {
    if (!mobileNav) return
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setMobileNav(false)
    }
    document.addEventListener("keydown", handleKeyDown)
    return () => document.removeEventListener("keydown", handleKeyDown)
  }, [mobileNav])

  const handleMouseEnter = () => {
    if (closeTimerRef.current) {
      clearTimeout(closeTimerRef.current)
      closeTimerRef.current = null
    }
    setShowUserMenu(true)
  }

  const handleMouseLeave = () => {
    closeTimerRef.current = window.setTimeout(() => {
      setShowUserMenu(false)
    }, 250)
  }

  const go = (id: AdminPage) => {
    setPage(id)
    setMobileNav(false)
  }

  const navGroups: Array<{
    title: string
    items: Array<{
      id: AdminPage
      label: string
      icon: ReactNode
      badge: ReactNode
    }>
  }> = [
      {
        title: "DANH MỤC NGHIỆP VỤ",
        items: [
          {
            id: "dashboard",
            label: "Tổng quan",
            icon: <LayoutDashboard size={18} />,
            badge: null,
          },
          {
            id: "attendance",
            label: "Xét duyệt điểm danh",
            icon: <ClipboardCheck size={18} />,
            badge:
              openSessionsCount !== null && openSessionsCount > 0 ? (
                <span className="text-[11px] font-bold text-white bg-[#EA580C] px-1.5 py-0.2 rounded-full min-w-[20px] text-center">
                  {openSessionsCount}
                </span>
              ) : null,
          },
          {
            id: "announcements",
            label: "Thông báo",
            icon: <Megaphone size={18} />,
            badge: (
              <span className="text-[10px] font-bold text-white bg-[#9A3412] px-2 py-0.5 rounded-full">
                New
              </span>
            ),
          },
          {
            id: "reports",
            label: "Báo cáo chuyên cần",
            icon: <LineChart size={18} />,
            badge: null,
          },
          {
            id: "feedback",
            label: "Báo cáo lỗi",
            icon: <Bug size={18} />,
            badge:
              pendingFeedbackCount !== null && pendingFeedbackCount > 0 ? (
                <span className="min-w-[20px] rounded-full bg-rose-500 px-1.5 py-0.5 text-center text-[11px] font-bold text-white">
                  {pendingFeedbackCount > 99 ? "99+" : pendingFeedbackCount}
                </span>
              ) : null,
          },
          {
            id: "feedback-history",
            label: "Lịch sử góp ý",
            icon: <History size={18} />,
            badge: null,
          },
          {
            id: "academic",
            label: "Danh mục học vụ",
            icon: <FolderKanban size={18} />,
            badge:
              classesCount !== null ? (
                <span className="text-[11px] font-semibold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-full">
                  {classesCount}
                </span>
              ) : null,
          },
        ],
      },
      {
        title: "HỆ THỐNG",
        items: [
          {
            id: "accounts",
            label: "Quyền truy cập",
            icon: <KeyRound size={18} />,
            badge: null,
          },
          {
            id: "crashlytics",
            label: "Firebase Crashlytics",
            icon: <Activity size={18} />,
            badge: null,
          },
          {
            id: "settings",
            label: "Cài đặt hệ thống",
            icon: <Settings size={18} />,
            badge: null,
          },
        ],
      },
    ]

  const userInitials = initials(profile.fullName || "HAC")

  return (
    <div className="admin-shell min-h-screen bg-[#F8FAFC] flex flex-col font-sans text-slate-800">
      {/* Mobile Drawer Backdrop */}
      {mobileNav && (
        <div
          className="fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-xs lg:hidden"
          onClick={() => setMobileNav(false)}
        />
      )}

      <div className="flex flex-1">
        {/* Left Sidebar */}
        <aside
          id="admin-navigation"
          className={`admin-sidebar fixed top-0 bottom-0 left-0 z-50 w-[272px] bg-white border-r border-slate-200/90 flex flex-col justify-between transition-transform duration-200 lg:translate-x-0 ${mobileNav ? "tablet-nav-open" : ""
            } ${mobileNav ? "translate-x-0" : "-translate-x-full"
            }`}
        >
          {/* Top & Nav of Sidebar (scrollable if screen height is small) */}
          <div className="flex-1 min-h-0 flex flex-col">
            {/* Logo & Campus header */}
            <div className="h-16 px-[18px] border-b border-slate-200/90 flex items-center justify-between shrink-0 overflow-hidden">
              <div className="flex items-center gap-3 shrink-0">
                <div className="w-9 h-9 rounded-xl bg-white border border-slate-200/90 p-1 flex items-center justify-center shadow-xs shrink-0 overflow-hidden">
                  <img
                    src="/logo_fapcheckin_icon.png"
                    alt="FAP Check-in Logo"
                    className="w-full h-full object-contain"
                  />
                </div>
                <div className="sidebar-text">
                  <div className="flex items-center gap-1.5 leading-none">
                    <span className="font-bold text-sm text-slate-900 whitespace-nowrap">FAP Admin</span>
                    <span className="bg-orange-100 text-[#C2410C] text-[10px] font-bold px-1.5 py-0.5 rounded leading-none">
                      HL
                    </span>
                  </div>
                  <span className="text-[11px] text-slate-400 font-medium block mt-1 leading-none whitespace-nowrap">
                    Phòng Quản lý Đào tạo
                  </span>
                </div>
              </div>
              <button
                type="button"
                className="lg:hidden text-slate-400 hover:text-slate-600 p-1"
                onClick={() => setMobileNav(false)}
                aria-label="Đóng điều hướng"
              >
                <X size={18} />
              </button>
            </div>

            {/* Navigation links */}
            <nav className="flex-1 min-h-0 overflow-y-auto overflow-x-hidden p-3 space-y-2">
              {navGroups.map((group, groupIdx) => (
                <div key={group.title} className="space-y-1">
                  {groupIdx > 0 && (
                    <div className="pt-2 pb-1.5 px-1">
                      <div className="border-t border-slate-100" />
                    </div>
                  )}
                  <div className="sidebar-section-header px-3.5 pt-2 pb-1 overflow-hidden">
                    <span className="sidebar-text text-[11px] font-bold text-slate-400 tracking-wider uppercase whitespace-nowrap block">
                      {group.title}
                    </span>
                  </div>
                  {group.items.map((item) => {
                    const isActive = page === item.id
                    return (
                      <button
                        key={item.id}
                        onClick={() => go(item.id)}
                        title={item.label}
                        className={`sidebar-nav-btn w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-colors cursor-pointer overflow-hidden ${isActive
                            ? "bg-[#FFF0E6] text-[#C2410C]"
                            : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
                          }`}
                      >
                        <div className="flex items-center gap-3 shrink-0">
                          {isActive && (
                            <span className="sidebar-active-indicator w-1.5 h-4 bg-[#EA580C] rounded-full shrink-0 -ml-1 mr-0" />
                          )}
                          <span
                            className={`w-6 h-6 flex items-center justify-center shrink-0 ${isActive ? "text-[#C2410C]" : "text-slate-400"
                              }`}
                          >
                            {item.icon}
                          </span>
                          <span className="sidebar-text whitespace-nowrap">{item.label}</span>
                        </div>
                        <div className="sidebar-badge flex items-center gap-1.5 shrink-0 ml-2">
                          {item.badge}
                          {isActive && <i className="w-1.5 h-1.5 rounded-full bg-[#EA580C] shrink-0" />}
                        </div>
                      </button>
                    )
                  })}
                </div>
              ))}
            </nav>
          </div>

          {/* Footer */}
          <div className="p-3 border-t border-slate-100 overflow-hidden">
            <div className="flex items-center justify-between text-[11px] text-slate-400 font-medium px-1">
              <span className="flex items-center gap-3 hover:text-slate-600 cursor-pointer shrink-0">
                <span className="w-6 h-6 flex items-center justify-center shrink-0">
                  <HelpCircle size={16} />
                </span>
                <span className="sidebar-text whitespace-nowrap">Hỗ trợ kỹ thuật</span>
              </span>
              <span className="sidebar-text whitespace-nowrap">v4.2</span>
            </div>
          </div>
        </aside>

        {/* Right Main Content */}
        <div className="flex-1 flex flex-col min-w-0 md:pl-[72px] transition-[padding] duration-200">
          {/* Top Bar */}
          <header className="sticky top-0 z-30 h-16 bg-white/95 backdrop-blur-xs border-b border-slate-200/90 px-4 sm:px-6 lg:px-8 flex items-center justify-between gap-4">
            {/* Left: Mobile hamburger */}
            <div className="flex items-center gap-3">
              <button
                type="button"
                className="lg:hidden p-2 text-slate-500 hover:text-slate-700 cursor-pointer"
                onClick={() => setMobileNav(true)}
                aria-label="Mở điều hướng"
                aria-expanded={mobileNav}
                aria-controls="admin-navigation"
              >
                <Menu size={20} />
              </button>
            </div>

            {/* Right: Notification Bell with live data, User profile */}
            <div className="flex items-center gap-3">
              {/* Real-time Notifications Bell */}
              <div ref={notifRef} className="relative">
                <button
                  type="button"
                  onClick={() => setShowNotifications(!showNotifications)}
                  className={`relative p-2 rounded-full cursor-pointer transition-colors ${showNotifications
                      ? "bg-orange-50 text-[#C2410C]"
                      : "text-slate-500 hover:text-slate-700 hover:bg-slate-50"
                    }`}
                  title="Thông báo hệ thống"
                  aria-label="Thông báo"
                >
                  <Bell size={18} />
                  {unreadCount > 0 && (
                    <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] px-1 bg-[#EA580C] text-white text-[10px] font-bold rounded-full flex items-center justify-center ring-2 ring-white">
                      {unreadCount > 9 ? "9+" : unreadCount}
                    </span>
                  )}
                </button>

                {/* Notifications Dropdown Panel */}
                {showNotifications && (
                  <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-white border border-slate-200/90 rounded-2xl shadow-xl z-50 overflow-hidden animate-in fade-in zoom-in-95 duration-150">
                    {/* Header */}
                    <div className="p-3.5 px-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-sm text-slate-900">Thông báo hệ thống</span>
                        {unreadCount > 0 ? (
                          <span className="bg-[#EA580C] text-white text-[10px] font-bold px-2 py-0.5 rounded-full">
                            {unreadCount} mới
                          </span>
                        ) : (
                          <span className="bg-slate-200 text-slate-600 text-[10px] font-bold px-1.5 py-0.5 rounded-full">
                            Đã đọc hết
                          </span>
                        )}
                      </div>
                      {unreadCount > 0 && (
                        <button
                          type="button"
                          onClick={handleMarkAllRead}
                          className="text-[11px] font-semibold text-[#EA580C] hover:text-[#C2410C] flex items-center gap-1 cursor-pointer transition"
                        >
                          <CheckCheck size={13} />
                          <span>Đã đọc</span>
                        </button>
                      )}
                    </div>

                    {/* Filter categories */}
                    <div className="flex items-center gap-1 p-2 px-3 border-b border-slate-100 overflow-x-auto text-[11px]">
                      {(
                        [
                          { id: "all", label: "Tất cả" },
                          { id: "academic", label: "Điểm danh" },
                          { id: "announcement", label: "Truyền thông" },
                          { id: "system", label: "Hệ thống" },
                        ] as const
                      ).map((tab) => (
                        <button
                          key={tab.id}
                          type="button"
                          onClick={() => setNotifFilter(tab.id)}
                          className={`px-2.5 py-1 rounded-lg font-medium whitespace-nowrap transition cursor-pointer ${notifFilter === tab.id
                              ? "bg-slate-900 text-white font-semibold"
                              : "text-slate-600 hover:bg-slate-100"
                            }`}
                        >
                          {tab.label}
                        </button>
                      ))}
                    </div>

                    {/* Notification List */}
                    <div className="max-h-[380px] overflow-y-auto divide-y divide-slate-100">
                      {notifications.filter((n) =>
                        notifFilter === "all" ? true : n.category === notifFilter
                      ).length === 0 ? (
                        <div className="py-10 px-4 text-center text-slate-400 text-xs">
                          <Bell size={24} className="mx-auto text-slate-300 mb-2 opacity-60" />
                          <p className="font-medium text-slate-500">Chưa có thông báo nào</p>
                          <p className="text-[11px] text-slate-400 mt-1">Các sự kiện và cảnh báo mới từ Firestore sẽ hiển thị tại đây.</p>
                        </div>
                      ) : (
                        notifications
                          .filter((n) =>
                            notifFilter === "all" ? true : n.category === notifFilter
                          )
                          .map((item) => (
                            <button
                              type="button"
                              key={item.id}
                              onClick={() => handleItemClick(item)}
                              className={`w-full text-left p-3.5 px-4 hover:bg-slate-50 transition cursor-pointer flex gap-3 items-start ${item.unread ? "bg-orange-50/25" : ""
                                }`}
                            >
                              <div
                                className={`w-8 h-8 rounded-xl flex items-center justify-center shrink-0 mt-0.5 ${item.type === "announcement"
                                    ? "bg-blue-50 text-blue-600"
                                    : item.type === "attendance"
                                      ? "bg-orange-50 text-[#EA580C]"
                                      : item.type === "request"
                                        ? "bg-amber-50 text-amber-600"
                                        : "bg-purple-50 text-purple-600"
                                  }`}
                              >
                                {item.type === "announcement" ? (
                                  <Megaphone size={15} />
                                ) : item.type === "attendance" ? (
                                  <ClipboardCheck size={15} />
                                ) : item.type === "request" ? (
                                  <Bell size={15} />
                                ) : (
                                  <ShieldCheck size={15} />
                                )}
                              </div>
                              <div className="flex-1 min-w-0">
                                <div className="flex items-center justify-between gap-2">
                                  <h4
                                    className={`text-xs truncate ${item.unread
                                        ? "font-bold text-slate-900"
                                        : "font-semibold text-slate-700"
                                      }`}
                                  >
                                    {item.title}
                                  </h4>
                                  <span className="text-[10px] text-slate-400 whitespace-nowrap font-mono shrink-0">
                                    {item.time}
                                  </span>
                                </div>
                                <p className="text-[11px] text-slate-500 line-clamp-2 mt-0.5 leading-relaxed">
                                  {item.description}
                                </p>
                              </div>
                              {item.unread && (
                                <span className="w-1.5 h-1.5 rounded-full bg-[#EA580C] shrink-0 mt-2" />
                              )}
                            </button>
                          ))
                      )}
                    </div>

                    {/* Footer */}
                    <div className="p-2.5 px-4 bg-slate-50/80 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-500">
                      <div className="flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                        <span className="text-[10px] font-medium text-slate-500">
                          Cloud Firestore Live
                        </span>
                      </div>
                      <button
                        type="button"
                        onClick={() => {
                          setShowNotifications(false)
                          go("announcements")
                        }}
                        className="text-[11px] font-semibold text-[#EA580C] hover:underline cursor-pointer"
                      >
                        Quản lý thông báo →
                      </button>
                    </div>
                  </div>
                )}
              </div>

              {/* User Profile */}
              <div
                ref={userMenuRef}
                className="relative"
                onMouseEnter={handleMouseEnter}
                onMouseLeave={handleMouseLeave}
              >
                <button
                  onClick={() => setShowUserMenu(!showUserMenu)}
                  className="flex items-center gap-2 p-1 pl-2 hover:bg-slate-50 rounded-full border border-slate-200/80 transition-colors cursor-pointer"
                >
                  <div className="w-7 h-7 rounded-full bg-orange-100 text-[#C2410C] font-bold text-xs flex items-center justify-center">
                    {userInitials}
                  </div>
                  <div className="text-left hidden md:block pr-1 leading-tight">
                    <b className="block text-xs text-slate-800">{profile.fullName || "Ban Đào Tạo (HAC)"}</b>
                    <small className="block text-[10px] text-slate-400">{profile.email || "admin.hac@fpt.edu.vn"}</small>
                  </div>
                </button>

                {/* Dropdown Menu */}
                {showUserMenu && (
                  <div className="absolute right-0 mt-2 w-48 bg-white border border-slate-200 rounded-xl shadow-lg py-1 z-50 animate-in fade-in zoom-in-95 duration-100">
                    <div className="px-3 py-2 border-b border-slate-100">
                      <p className="text-xs font-semibold text-slate-800">{profile.fullName}</p>
                      <p className="text-[10px] text-slate-400 truncate">{profile.email}</p>
                    </div>
                    <button
                      onClick={() => {
                        setShowUserMenu(false)
                        void logout()
                      }}
                      className="w-full text-left px-3 py-2 text-xs text-rose-600 hover:bg-rose-50 flex items-center gap-2 cursor-pointer font-medium"
                    >
                      <LogOut size={14} />
                      <span>Đăng xuất</span>
                    </button>
                  </div>
                )}
              </div>
            </div>
          </header>

          {/* Page Content */}
          <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-[1600px] w-full mx-auto">
            {children}
          </main>
        </div>
      </div>

      {selectedNotification && (
        <div
          className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/45 p-4 backdrop-blur-[2px]"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) setSelectedNotification(null)
          }}
        >
          <section
            role="dialog"
            aria-modal="true"
            aria-labelledby="notification-detail-title"
            className="w-full max-w-lg overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl"
          >
            <div className="flex items-start justify-between gap-4 border-b border-slate-100 bg-slate-50/70 px-5 py-4">
              <div className="flex min-w-0 items-center gap-3">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-orange-50 text-[#EA580C]">
                  {selectedNotification.type === "announcement" ? (
                    <Megaphone size={19} />
                  ) : selectedNotification.type === "attendance" ? (
                    <ClipboardCheck size={19} />
                  ) : selectedNotification.type === "audit" ? (
                    <ShieldCheck size={19} />
                  ) : (
                    <Bell size={19} />
                  )}
                </div>
                <div className="min-w-0">
                  <p className="text-[11px] font-semibold uppercase tracking-wide text-[#C2410C]">
                    Chi tiết thông báo
                  </p>
                  <p className="mt-0.5 text-xs text-slate-500">{selectedNotification.time}</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedNotification(null)}
                className="rounded-lg p-2 text-slate-400 transition hover:bg-slate-200/70 hover:text-slate-700"
                aria-label="Đóng thông báo"
              >
                <X size={18} />
              </button>
            </div>

            <div className="px-5 py-5 sm:px-6">
              <h2 id="notification-detail-title" className="text-base font-bold leading-6 text-slate-900 sm:text-lg">
                {selectedNotification.title}
              </h2>
              <p className="mt-3 whitespace-pre-wrap break-words text-sm leading-6 text-slate-600">
                {selectedNotification.description}
              </p>
            </div>

            <div className="flex justify-end border-t border-slate-100 bg-slate-50/60 px-5 py-3.5">
              <button
                type="button"
                onClick={() => setSelectedNotification(null)}
                className="rounded-lg bg-[#EA580C] px-4 py-2 text-xs font-semibold text-white transition hover:bg-[#C2410C]"
              >
                Đóng
              </button>
            </div>
          </section>
        </div>
      )}
    </div>
  )
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  return parts.slice(-2).map((part) => part[0]?.toUpperCase()).join("") || "AD"
}
