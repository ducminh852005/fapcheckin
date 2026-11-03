import {
  collection,
  getDocs,
  limit,
  onSnapshot,
  orderBy,
  query,
  where,
} from "firebase/firestore"
import { firestore } from "../firebase/client"
import type { AdminPage } from "../types/admin-v2"

export interface HeaderNotificationItem {
  id: string
  type: "announcement" | "attendance" | "audit" | "request"
  category: "academic" | "announcement" | "system"
  title: string
  description: string
  time: string
  timestampMs: number
  targetPage: AdminPage
  priority: "normal" | "warning" | "danger" | "info"
  unread: boolean
}

const STORAGE_KEY = "fap_read_notification_ids_v1"

function getReadIds(): Set<string> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return new Set()
    const arr = JSON.parse(raw)
    return new Set(Array.isArray(arr) ? arr : [])
  } catch {
    return new Set()
  }
}

export function saveReadIds(ids: string[]): void {
  try {
    const current = getReadIds()
    ids.forEach((id) => current.add(id))
    localStorage.setItem(STORAGE_KEY, JSON.stringify(Array.from(current).slice(-200)))
  } catch {
    // Ignore storage errors
  }
}

export function markSingleRead(id: string): void {
  saveReadIds([id])
}

function formatRelativeTime(dateVal: unknown): { text: string; ms: number } {
  if (!dateVal) return { text: "Vừa xong", ms: Date.now() }
  let ms = Date.now()

  if (typeof dateVal === "object" && dateVal !== null && "toMillis" in dateVal && typeof (dateVal as { toMillis: () => number }).toMillis === "function") {
    ms = (dateVal as { toMillis: () => number }).toMillis()
  } else if (typeof dateVal === "object" && dateVal !== null && "toDate" in dateVal && typeof (dateVal as { toDate: () => Date }).toDate === "function") {
    ms = (dateVal as { toDate: () => Date }).toDate().getTime()
  } else if (typeof dateVal === "string") {
    const parsed = new Date(dateVal).getTime()
    if (!Number.isNaN(parsed)) ms = parsed
  } else if (typeof dateVal === "number") {
    ms = dateVal
  }

  const diffSec = Math.max(0, Math.floor((Date.now() - ms) / 1000))
  if (diffSec < 60) return { text: "Vừa xong", ms }
  if (diffSec < 3600) return { text: `${Math.floor(diffSec / 60)} phút trước`, ms }
  if (diffSec < 86400) return { text: `${Math.floor(diffSec / 3600)} giờ trước`, ms }
  const d = new Date(ms)
  const pad = (n: number) => n.toString().padStart(2, "0")
  return {
    text: `${pad(d.getDate())}/${pad(d.getMonth() + 1)} ${pad(d.getHours())}:${pad(d.getMinutes())}`,
    ms,
  }
}

export async function fetchHeaderNotifications(): Promise<HeaderNotificationItem[]> {
  const readIds = getReadIds()
  const items: HeaderNotificationItem[] = []

  const [announcementsSnap, auditSnap, sessionsSnap, requestsSnap] = await Promise.all([
    getDocs(query(collection(firestore, "announcements"), orderBy("createdAt", "desc"), limit(6))).catch(() => null),
    getDocs(query(collection(firestore, "audit_logs"), orderBy("createdAt", "desc"), limit(6))).catch(() => null),
    getDocs(query(collection(firestore, "sessions"), where("sessionStatus", "==", "open"), limit(6))).catch(() => null),
    getDocs(query(collection(firestore, "requests"), where("status", "==", "pending"), limit(6))).catch(() => null),
  ])

  // 1. Announcements
  if (announcementsSnap && !announcementsSnap.empty) {
    announcementsSnap.docs.forEach((doc) => {
      const data = doc.data()
      const t = formatRelativeTime(data.createdAt)
      const priorityMap: Record<string, "normal" | "warning" | "danger" | "info"> = {
        urgent: "danger",
        important: "warning",
        normal: "info",
      }
      items.push({
        id: `announcement_${doc.id}`,
        type: "announcement",
        category: "announcement",
        title: String(data.title || "Thông báo mới từ Phòng Đào tạo"),
        description: String(data.content || data.body || "Đã gửi thông báo tới người dùng hệ thống."),
        time: t.text,
        timestampMs: t.ms,
        targetPage: "announcements",
        priority: priorityMap[data.priority as string] || "info",
        unread: !readIds.has(`announcement_${doc.id}`),
      })
    })
  }

  // 2. Audit Logs
  if (auditSnap && !auditSnap.empty) {
    auditSnap.docs.forEach((doc) => {
      const data = doc.data()
      const t = formatRelativeTime(data.createdAt)
      items.push({
        id: `audit_${doc.id}`,
        type: "audit",
        category: "system",
        title: `${String(data.actor || "Admin")}: ${String(data.action || "Thao tác hệ thống")}`,
        description: `Đối tượng: ${String(data.target || "Hệ thống")} · Trạng thái: ${String(data.status || "Thành công")}`,
        time: t.text,
        timestampMs: t.ms,
        targetPage: "accounts",
        priority: data.status === "Cảnh báo" ? "warning" : "normal",
        unread: !readIds.has(`audit_${doc.id}`),
      })
    })
  }

  // 3. Open Attendance Sessions needing review
  if (sessionsSnap && !sessionsSnap.empty) {
    sessionsSnap.docs.forEach((doc) => {
      const data = doc.data()
      const t = formatRelativeTime(data.createdAt || data.sessionDate)
      const isOverdue = Boolean(data.overdue)
      items.push({
        id: `session_${doc.id}`,
        type: "attendance",
        category: "academic",
        title: `Phiên điểm danh đang mở: ${String(data.classCode || "Lớp học")}`,
        description: `Slot: ${String(data.slotCode || "—")} · Giảng viên: ${String(data.teacherMemberCode || "Chưa rõ")}${isOverdue ? " (Mở quá giờ)" : ""}`,
        time: t.text,
        timestampMs: t.ms,
        targetPage: "attendance",
        priority: isOverdue ? "danger" : "warning",
        unread: !readIds.has(`session_${doc.id}`),
      })
    })
  }

  // 4. Student Requests
  if (requestsSnap && !requestsSnap.empty) {
    requestsSnap.docs.forEach((doc) => {
      const data = doc.data()
      const t = formatRelativeTime(data.createdAt)
      items.push({
        id: `request_${doc.id}`,
        type: "request",
        category: "academic",
        title: `Đơn xin phép vắng: ${String(data.studentName || data.rollNumber || "Sinh viên")}`,
        description: `Lớp: ${String(data.classCode || "—")} · Lý do: ${String(data.reason || "Xin nghỉ học")}`,
        time: t.text,
        timestampMs: t.ms,
        targetPage: "attendance",
        priority: "info",
        unread: !readIds.has(`request_${doc.id}`),
      })
    })
  }

  // Sort descending by timestamp
  return items.sort((a, b) => b.timestampMs - a.timestampMs)
}

export function subscribeHeaderNotifications(
  onUpdate: (items: HeaderNotificationItem[]) => void
): () => void {
  let unsubAnnouncements: (() => void) | null = null
  let unsubAudit: (() => void) | null = null

  // Fallback initial load
  void fetchHeaderNotifications().then(onUpdate)

  try {
    const qAnnouncements = query(collection(firestore, "announcements"), orderBy("createdAt", "desc"), limit(6))
    unsubAnnouncements = onSnapshot(
      qAnnouncements,
      () => {
        void fetchHeaderNotifications().then(onUpdate)
      },
      () => {
        // Silently handle error
      }
    )
  } catch {
    // Ignore setup error
  }

  try {
    const qAudit = query(collection(firestore, "audit_logs"), orderBy("createdAt", "desc"), limit(6))
    unsubAudit = onSnapshot(
      qAudit,
      () => {
        void fetchHeaderNotifications().then(onUpdate)
      },
      () => {
        // Silently handle error
      }
    )
  } catch {
    // Ignore setup error
  }

  return () => {
    if (unsubAnnouncements) unsubAnnouncements()
    if (unsubAudit) unsubAudit()
  }
}

