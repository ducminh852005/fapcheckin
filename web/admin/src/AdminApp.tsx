import { useEffect, useState } from "react"
import { observeAdminSession, signInAdmin, signOutAdmin, type AdminProfile } from "./firebase/admin-auth"
import { AdminShell } from "./layouts/AdminShell"
import { AccountControl } from "./pages/AccountControlPage"
import { AttendanceOperations } from "./pages/AttendanceOperationsPage"
import { AttendanceMonitoring } from "./pages/AttendanceMonitoringPage"
import { AttendanceReport } from "./pages/AttendanceReportPage"
import { SystemSettingsPage } from "./pages/SystemSettingsPage"
import { AcademicEnrollmentManagement } from "./pages/AcademicEnrollmentPage"
import { LiveDashboard } from "./pages/LiveDashboardPage"
import { AdminLogin } from "./pages/AdminLoginPage"
import { AnnouncementPage } from "./pages/AnnouncementPage"
import type { AdminPage } from "./types/admin-v2"

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
    reports: <AttendanceReport />,
    settings: <SystemSettingsPage adminEmail={profile.email} />,
  }[page]

  return (
    <AdminShell page={page} setPage={setPage} profile={profile} logout={signOutAdmin}>
      {content}
    </AdminShell>
  )
}
