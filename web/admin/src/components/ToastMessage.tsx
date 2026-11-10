import { useMemo, useState, type ReactNode } from "react"
import {
  Archive,
  Bell,
  BookOpen,
  CalendarDays,
  Check,
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
import type { Toast } from "../types/admin"
import { Button } from "./ui"
export function ToastMessage({
  toast,
  close,
}: {
  toast: NonNullable<Toast>
  close: () => void
}) {
  return (
    <div className={`toast toast-${toast.tone ?? "success"}`}>
      <span className="toast-icon" aria-hidden="true">
        {toast.tone === "error" ? <X size={22} /> : <Check size={24} />}
      </span>
      <div>
        <b>{toast.title}</b>
        <p>{toast.detail}</p>
      </div>
      <Button
        variant="icon"
        className="toast-close"
        onClick={close}
        aria-label="Đóng thông báo"
      >
        <X size={17} />
      </Button>
    </div>
  )
}
