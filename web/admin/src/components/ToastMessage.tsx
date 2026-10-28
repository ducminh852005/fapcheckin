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
      <span>
        {toast.tone === "error" ? (
          <XCircle size={20} />
        ) : (
          <CheckCircle2 size={20} />
        )}
      </span>
      <div>
        <b>{toast.title}</b>
        <p>{toast.detail}</p>
      </div>
      <Button variant="icon" onClick={close}>
        <X size={17} />
      </Button>
    </div>
  )
}



