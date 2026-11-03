import {
  collection,
  doc,
  documentId,
  getDocs,
  limit,
  query,
  serverTimestamp,
  updateDoc,
  where,
  type Timestamp,
} from "firebase/firestore"
import { getDownloadURL, getStorage, ref } from "firebase/storage"
import { app, firestore } from "../firebase/client"

export type FeedbackStatus = "pending" | "resolved"
export type FeedbackCategory = "bug" | "suggestion" | "other"

export interface AdminFeedback {
  id: string
  authorUid: string
  authorName: string
  authorEmail: string
  memberCode: string
  category: FeedbackCategory
  message: string
  attachments: string[]
  status: FeedbackStatus
  reply: string
  createdAt: Date | null
  resolvedAt: Date | null
}

type UserSummary = { fullName?: unknown; displayName?: unknown; email?: unknown; memberCode?: unknown }

function asDate(value: unknown): Date | null {
  if (value && typeof value === "object" && "toDate" in value) {
    return (value as Timestamp).toDate()
  }
  if (typeof value === "string" || typeof value === "number") {
    const date = new Date(value)
    return Number.isNaN(date.getTime()) ? null : date
  }
  return null
}

export async function listFeedback(status: FeedbackStatus): Promise<AdminFeedback[]> {
  const feedbackSnap = await getDocs(
    query(collection(firestore, "feedback"), where("status", "==", status), limit(300)),
  )
  const authorIds = [...new Set(feedbackSnap.docs.map((item) => String(item.data().authorUid || "")).filter(Boolean))]
  const users = new Map<string, UserSummary>()

  for (let index = 0; index < authorIds.length; index += 30) {
    const chunk = authorIds.slice(index, index + 30)
    const usersSnap = await getDocs(
      query(collection(firestore, "users"), where(documentId(), "in", chunk)),
    )
    usersSnap.docs.forEach((item) => users.set(item.id, item.data()))
  }

  return feedbackSnap.docs
    .map((item): AdminFeedback => {
      const data = item.data()
      const authorUid = String(data.authorUid || "")
      const user = users.get(authorUid)
      return {
        id: item.id,
        authorUid,
        authorName: String(user?.fullName || user?.displayName || "Người dùng"),
        authorEmail: String(user?.email || ""),
        memberCode: String(user?.memberCode || ""),
        category: ["bug", "suggestion"].includes(String(data.category))
          ? (data.category as FeedbackCategory)
          : "other",
        message: String(data.message || ""),
        attachments: Array.isArray(data.attachments)
          ? data.attachments.filter((path): path is string => typeof path === "string")
          : [],
        status,
        reply: String(data.reply || ""),
        createdAt: asDate(data.createdAt),
        resolvedAt: asDate(data.resolvedAt),
      }
    })
    .sort((a, b) => (b.createdAt?.getTime() || 0) - (a.createdAt?.getTime() || 0))
}

export async function resolveAdminFeedback(feedbackId: string, reply: string): Promise<void> {
  await updateDoc(doc(firestore, "feedback", feedbackId), {
    status: "resolved",
    reply: reply.trim(),
    resolvedAt: serverTimestamp(),
  })
}

export async function reopenAdminFeedback(feedbackId: string): Promise<void> {
  await updateDoc(doc(firestore, "feedback", feedbackId), {
    status: "pending",
    reply: "",
    resolvedAt: null,
  })
}

export async function getFeedbackAttachmentUrl(path: string): Promise<string> {
  return getDownloadURL(ref(getStorage(app), path))
}
