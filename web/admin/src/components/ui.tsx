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
export function Button({
  children,
  variant = "primary",
  icon,
  onClick,
  disabled,
  type = "button",
  className = "",
}: {
  children?: ReactNode
  variant?: "primary" | "secondary" | "ghost" | "danger" | "icon"
  icon?: ReactNode
  onClick?: () => void
  disabled?: boolean
  type?: "button" | "submit"
  className?: string
}) {
  return (
    <button
      type={type}
      className={`btn btn-${variant} ${className}`}
      onClick={onClick}
      disabled={disabled}
    >
      {icon}
      {children}
    </button>
  )
}

export function Field({
  label,
  placeholder,
  type = "text",
  value,
  onChange,
  disabled,
}: {
  label: string
  placeholder?: string
  type?: string
  value?: string
  onChange?: (value: string) => void
  disabled?: boolean
}) {
  return (
    <label className="field">
      <span>{label}</span>
      <input
        type={type}
        placeholder={placeholder}
        value={value}
        disabled={disabled}
        onChange={(event) => onChange?.(event.target.value)}
      />
    </label>
  )
}

export function SelectField({
  label,
  value,
  options,
}: {
  label?: string
  value: string
  options?: string[]
}) {
  return (
    <label className="select-wrap">
      {label && <span>{label}</span>}
      <select defaultValue={value}>
        {(options ?? [value]).map((option) => (
          <option key={option}>{option}</option>
        ))}
      </select>
      <ChevronDown size={16} />
    </label>
  )
}

export function Status({ children }: { children: string }) {
  const tone =
    children === "Đã duyệt" || children === "Đang học"
      ? "success"
      : children.includes("Chờ") || children === "Sắp mở"
        ? "warning"
        : children.includes("từ chối")
          ? "error"
          : "neutral"
  return (
    <span className={`status status-${tone}`}>
      <i />
      {children}
    </span>
  )
}

export function Logo({ inverse = false }: { inverse?: boolean }) {
  return (
    <div className={`logo ${inverse ? "logo-inverse" : ""}`}>
      <span className="logo-mark">
        <Check size={21} strokeWidth={3} />
      </span>
      <span>
        <b>FAP</b> Check-in<small>FPT EDUCATION</small>
      </span>
    </div>
  )
}


export function PageHeader({
  eyebrow,
  title,
  description,
  actions,
}: {
  eyebrow?: string
  title: string
  description: string
  actions?: ReactNode
}) {
  return (
    <div className="page-header">
      <div>
        {eyebrow ? <span className="eyebrow">{eyebrow}</span> : null}
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">{title}</h1>
        <p className="text-xs text-slate-500 mt-1">{description}</p>
      </div>
      {actions && <div className="page-actions">{actions}</div>}
    </div>
  )
}


