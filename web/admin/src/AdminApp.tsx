import { lazy, Suspense, useEffect, useState } from "react"
import { observeAdminSession, signInAdmin, signOutAdmin, type AdminProfile } from "./firebase/admin-auth"
import { AdminShell } from "./layouts/AdminShell"
import { AdminLogin } from "./pages/AdminLoginPage"
import type { AdminPage } from "./types/admin-v2"

const AccountControl = lazy(() =>
  import("./pages/AccountControlPage").then((module) => ({ default: module.AccountControl })),
)
const AttendanceOperations = lazy(() =>
  import("./pages/AttendanceOperationsPage").then((module) => ({
    default: module.AttendanceOperations,
  })),
)
const AttendanceReport = lazy(() =>
  import("./pages/AttendanceReportPage").then((module) => ({ default: module.AttendanceReport })),
)
const SystemSettingsPage = lazy(() =>
  import("./pages/SystemSettingsPage").then((module) => ({ default: module.SystemSettingsPage })),
)
const AcademicEnrollmentManagement = lazy(() =>
  import("./pages/AcademicEnrollmentPage").then((module) => ({
    default: module.AcademicEnrollmentManagement,
  })),
)
const LiveDashboard = lazy(() =>
  import("./pages/LiveDashboardPage").then((module) => ({ default: module.LiveDashboard })),
)
const AnnouncementPage = lazy(() =>
  import("./pages/AnnouncementPage").then((module) => ({ default: module.AnnouncementPage })),
)
const FeedbackInboxPage = lazy(() =>
  import("./pages/AdminFeedbackPage").then((module) => ({ default: module.FeedbackInboxPage })),
)
const FeedbackHistoryPage = lazy(() =>
  import("./pages/AdminFeedbackPage").then((module) => ({ default: module.FeedbackHistoryPage })),
)
const CrashlyticsPage = lazy(() =>
  import("./pages/CrashlyticsPage").then((module) => ({ default: module.CrashlyticsPage })),
)

export default function AdminApp() {
  const [authReady, setAuthReady] = useState(false)
  const [signingIn, setSigningIn] = useState(false)
  const [profile, setProfile] = useState<AdminProfile | null>(null)
  const [authError, setAuthError] = useState<string | null>(null)
  const [page, setPage] = useState<AdminPage>("dashboard")

  useEffect(() => observeAdminSession((nextProfile, error) => {
    setProfile(nextProfile)
    if (error) setAuthError(error.message)
    setAuthReady(true)
  }), [])

  const login = async () => {
    setSigningIn(true)
    setAuthError(null)
    try {
      setProfile(await signInAdmin())
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : "Không thể đăng nhập.")
    } finally {
      setAuthReady(true)
      setSigningIn(false)
    }
  }

  if (!authReady || !profile) {
    return <AdminLogin loading={!authReady || signingIn} error={authError} onLogin={login} />
  }

  const content = {
    dashboard: <LiveDashboard onNavigate={setPage} />,
    accounts: <AccountControl currentAdmin={profile} />,
    academic: <AcademicEnrollmentManagement />,
    attendance: <AttendanceOperations />,
    announcements: (
      <AnnouncementPage onNavigate={setPage} adminEmail={profile.email} />
    ),
    feedback: <FeedbackInboxPage />,
    "feedback-history": <FeedbackHistoryPage />,
    reports: <AttendanceReport />,
    crashlytics: <CrashlyticsPage />,
    settings: <SystemSettingsPage adminEmail={profile.email} />,
  }[page]

  return (
    <AdminShell page={page} setPage={setPage} profile={profile} logout={signOutAdmin}>
      <Suspense fallback={<PageLoading />}>{content}</Suspense>
    </AdminShell>
  )
}

function PageLoading() {
  return (
    <div className="flex min-h-[320px] items-center justify-center" role="status" aria-live="polite">
      <div className="flex items-center gap-3 text-sm font-medium text-slate-500">
        <span className="h-5 w-5 animate-spin rounded-full border-2 border-slate-200 border-t-[#EA580C]" />
        Đang tải trang…
      </div>
    </div>
  )
}
