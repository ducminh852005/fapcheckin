import { useMemo, useState } from "react"
import { NoticeDrawer } from "./components/NoticeDrawer"
import { ToastMessage } from "./components/ToastMessage"
import { AdminLayout } from "./layouts/AdminLayout"
import { Catalog } from "./pages/CatalogPage"
import { Dashboard } from "./pages/DashboardPage"
import { Login } from "./pages/LoginPage"
import { Requests } from "./pages/RequestsPage"
import type { Page, Toast } from "./types/admin"

export default function App() {
  const [loggedIn, setLoggedIn] = useState(false)
  const [page, setPage] = useState<Page>("dashboard")
  const [notice, setNotice] = useState(false)
  const [toast, setToast] = useState<Toast>(null)
  const showToast = (next: NonNullable<Toast>) => {
    setToast(next)
    window.setTimeout(() => setToast(null), 4200)
  }
  const content = useMemo(
    () =>
      page === "dashboard" ? (
        <Dashboard />
      ) : page === "catalog" ? (
        <Catalog showToast={showToast} />
      ) : (
        <Requests showToast={showToast} />
      ),
    [page],
  )
  if (!loggedIn) return <Login onLogin={() => setLoggedIn(true)} />
  return (
    <AdminLayout
      page={page}
      setPage={setPage}
      openNotice={() => setNotice(true)}
      logout={() => setLoggedIn(false)}
    >
      {content}
      {notice && (
        <NoticeDrawer
          close={() => setNotice(false)}
          send={() => {
            setNotice(false)
            showToast({
              title: "Đã gửi thông báo",
              detail: "Thông báo đã được gửi tới 3.284 người nhận.",
            })
          }}
        />
      )}
      {toast && <ToastMessage toast={toast} close={() => setToast(null)} />}
    </AdminLayout>
  )
}
 
