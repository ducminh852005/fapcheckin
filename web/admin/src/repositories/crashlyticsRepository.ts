import { httpsCallable } from "firebase/functions"
import { functions } from "../firebase/client"

export type CrashlyticsIssue = {
  id: string
  title: string
  subtitle: string
  version: string
  eventCount: number
  userCount: number
  firstSeen: string | null
  lastSeen: string | null
}

export type CrashlyticsDashboard = {
  days: number
  source: "bigquery-daily" | "bigquery-realtime"
  updatedAt: string
  totals: { events: number; users: number; issues: number }
  issues: CrashlyticsIssue[]
}

const getDashboard = httpsCallable<{ days: number }, CrashlyticsDashboard>(
  functions,
  "getCrashlyticsDashboard",
)

export async function getCrashlyticsData(days: number) {
  const response = await getDashboard({ days })
  return response.data
}
