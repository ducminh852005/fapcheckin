import { useCallback, useEffect, useState } from "react"

export function useAsyncData<T>(loader: () => Promise<T>) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [revision, setRevision] = useState(0)

  const reload = useCallback(() => setRevision((value) => value + 1), [])

  useEffect(() => {
    let active = true
    setLoading(true)
    setError(null)
    loader()
      .then((value) => { if (active) setData(value) })
      .catch((reason: unknown) => { if (active) setError(readError(reason)) })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [loader, revision])

  return { data, loading, error, reload }
}

export function readError(reason: unknown) {
  if (typeof reason === "object" && reason && "code" in reason && reason.code === "permission-denied") {
    return "Firebase từ chối quyền truy cập. Hãy kiểm tra role admin và Security Rules."
  }
  return reason instanceof Error ? reason.message : "Không thể tải dữ liệu Firestore."
}
