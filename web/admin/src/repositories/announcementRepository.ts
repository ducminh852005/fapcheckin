import {
  addDoc,
  collection,
  getCountFromServer,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  Timestamp,
  where,
} from "firebase/firestore"
import { firestore } from "../firebase/client"

export type AnnouncementPayload = {
  title: string
  content: string
  richContent?: string
  targetAudience: "teachers"
  priority: "normal" | "important" | "urgent"
  pinToTop: boolean
  recipientCount?: number
  createdBy?: string
  createdAt?: string
}

export type AnnouncementHistoryItem = {
  id: string
  title: string
  body: string
  targetAudience: string
  priority: string
  status: string
  sentAt: string
  recipientCount: number
}

export type AnnouncementTargetsData = {
  teacherCount: number
  linkedTeachers: number
}

function formatFirestoreDate(val: unknown): string {
  if (!val) return "Vừa xong"
  if (typeof val === "object" && val !== null && "toDate" in val && typeof (val as { toDate: () => Date }).toDate === "function") {
    return (val as { toDate: () => Date }).toDate().toLocaleString("vi-VN")
  }
  if (typeof val === "string") {
    const parsed = new Date(val)
    if (!Number.isNaN(parsed.getTime())) {
      return parsed.toLocaleString("vi-VN")
    }
    return val
  }
  return "Vừa xong"
}

function formatTargetAudienceLabel(targetAudience: string, audience?: string, selectedClasses?: unknown): string {
  if (targetAudience === "specific_class" && Array.isArray(selectedClasses) && selectedClasses.length > 0) {
    return `Lớp: ${selectedClasses.join(", ")}`
  }
  if (targetAudience === "teachers" || audience === "staff") return "Giảng viên"
  if (targetAudience === "students" || audience === "user") return "Sinh viên"
  if (audience === "admin") return "Bản nháp (Nội bộ Admin)"
  return "Toàn Campus"
}

export async function getAnnouncementTargets(): Promise<AnnouncementTargetsData> {
  const [staffSnap, staffUsersSnap] = await Promise.all([
    getCountFromServer(query(collection(firestore, "users"), where("role", "in", ["staff", "GV"]))).catch(() => null),
    getDocs(query(collection(firestore, "users"), where("role", "in", ["staff", "GV"]), limit(500))).catch(() => null),
  ])

  const teacherCount = staffSnap ? staffSnap.data().count : staffUsersSnap?.size ?? 0
  let linkedTeachers = teacherCount
  if (staffUsersSnap && !staffUsersSnap.empty) {
    linkedTeachers = staffUsersSnap.docs.filter((docSnap) => {
      const d = docSnap.data()
      return !docSnap.id.startsWith("legacy_") || Boolean(d.authUid ?? d.uid)
    }).length
  }

  return {
    teacherCount,
    linkedTeachers,
  }
}

export async function sendAnnouncement(payload: AnnouncementPayload): Promise<string> {
  const audience = "staff"
  const docRef = await addDoc(collection(firestore, "announcements"), {
    title: payload.title.trim(),
    body: payload.content.trim(),
    content: payload.content.trim(),
    richContent: payload.richContent ?? null,
    audience,
    targetAudience: payload.targetAudience,
    priority: payload.priority,
    deliveryChannel: "teacher_app",
    pinToTop: payload.pinToTop,
    pinnedUntil: payload.pinToTop ? Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000) : null,
    recipientCount: payload.recipientCount ?? 0,
    createdBy: payload.createdBy ?? "admin",
    status: "sent",
    createdAt: serverTimestamp(),
  })

  await addDoc(collection(firestore, "audit_logs"), {
    actionType: "create",
    actionLabel: "Đăng thông báo cho giảng viên",
    actor: payload.createdBy ?? "admin",
    targetEmail: formatTargetAudienceLabel(payload.targetAudience, audience),
    detail: `Đã đăng thông báo "${payload.title.trim()}" cho giảng viên (Mức độ: ${payload.priority}).`,
    createdAt: serverTimestamp(),
  }).catch(() => {})

  return docRef.id
}

export async function saveAnnouncementDraft(payload: AnnouncementPayload): Promise<string> {
  const docRef = await addDoc(collection(firestore, "announcements"), {
    title: payload.title.trim() || "(Bản nháp chưa đặt tiêu đề)",
    body: payload.content.trim(),
    content: payload.content.trim(),
    richContent: payload.richContent ?? null,
    audience: "admin",
    targetAudience: payload.targetAudience,
    priority: payload.priority,
    deliveryChannel: "teacher_app",
    pinToTop: payload.pinToTop,
    pinnedUntil: null,
    recipientCount: payload.recipientCount ?? 0,
    createdBy: payload.createdBy ?? "admin",
    status: "draft",
    createdAt: serverTimestamp(),
  })
  return docRef.id
}

export async function getAnnouncementHistory(options?: {
  page?: number
  pageSize?: number
}): Promise<AnnouncementHistoryItem[]> {
  const page = Math.max(1, options?.page ?? 1)
  const pageSize = options?.pageSize ?? 50
  const fetchLimit = Math.min(page * pageSize, 100)

  const [snap, usersCountSnap] = await Promise.all([
    getDocs(
      query(collection(firestore, "announcements"), orderBy("createdAt", "desc"), limit(fetchLimit))
    ).catch(async () => getDocs(query(collection(firestore, "announcements"), limit(fetchLimit)))),
    getCountFromServer(query(collection(firestore, "users"), where("role", "in", ["staff", "GV"]))).catch(() => null),
  ])

  const defaultRecipientCount = usersCountSnap ? usersCountSnap.data().count : 0

  return snap.docs.map((d) => {
    const data = d.data()
    const targetAudienceRaw = String(data.targetAudience ?? "")
    const audienceRaw = String(data.audience ?? "all")
    return {
      id: d.id,
      title: String(data.title || "Thông báo học vụ"),
      body: String(data.body ?? data.content ?? ""),
      targetAudience: formatTargetAudienceLabel(targetAudienceRaw, audienceRaw, data.selectedClasses),
      priority: String(data.priority || "normal"),
      status: String(data.status || "sent"),
      sentAt: formatFirestoreDate(data.createdAt ?? data.timestamp),
      recipientCount:
        typeof data.recipientCount === "number" && data.recipientCount > 0
          ? data.recipientCount
          : defaultRecipientCount,
    }
  })
}
