export type Page = "dashboard" | "catalog" | "requests"
export type LoginState = "idle" | "loading" | "wrong" | "denied" | "network"
export type Toast = { title: string; detail: string; tone?: "success" | "error" } | null

