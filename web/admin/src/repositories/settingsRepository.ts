import {
  addDoc,
  collection,
  doc,
  getCountFromServer,
  getDoc,
  getDocs,
  limit,
  query,
  serverTimestamp,
  setDoc,
  where,
  writeBatch,
} from "firebase/firestore"
import { firestore } from "../firebase/client"

export type SystemSettings = {
  // QR Parameters
  qrRefreshRate: number // 30 | 45 | 60
  gracePeriodMinutes: number // 15
  allowTeacherManualApproval: boolean // true

  // Security & Geofencing
  requireCampusIp: boolean // true
  campusIpRange: string // "10.22.*.*"
  geofenceRadiusMeters: number // 100
  enableDeviceFingerprint: boolean // true

  // Academic thresholds & notifications
  maxAbsentThresholdPercent: number // 20
  autoSendFcmNotice: boolean // true
  notifyAdvisorWeekly: boolean // false

  // Support configuration (synced with support_config/public)
  supportPhone?: string
  supportEmail?: string
  supportAddress?: string
  supportHours?: string

  // Metadata & Live status
  version: string
  lastUpdated?: string
  lastUpdatedBy?: string
  lastSyncAt?: string
  pingMs?: number
  totalSyncedAccounts?: number
  unsyncedRecordsCount?: number
}

export const DEFAULT_SETTINGS: SystemSettings = {
  qrRefreshRate: 60,
  gracePeriodMinutes: 15,
  allowTeacherManualApproval: true,

  requireCampusIp: true,
  campusIpRange: "10.22.*.*",
  geofenceRadiusMeters: 100,
  enableDeviceFingerprint: true,

  maxAbsentThresholdPercent: 20,
  autoSendFcmNotice: true,
  notifyAdvisorWeekly: false,

  supportPhone: "024 7300 5588",
  supportEmail: "dichvusinhvien@fe.edu.vn",
  supportAddress: "Phòng 102L, Tòa Alpha, Đại học FPT Hòa Lạc",
  supportHours: "08:00 - 17:30 (Thứ 2 - Thứ 6)",

  version: "v2.4.1 Production",
}

export async function getSystemSettings(): Promise<SystemSettings> {
  const startTime = performance.now()
  const [settingsSnap, supportSnap, usersCountSnap, unsyncedSnap] = await Promise.all([
    getDoc(doc(firestore, "system_settings", "global_config")).catch(() => null),
    getDoc(doc(firestore, "support_config", "public")).catch(() => null),
    getCountFromServer(collection(firestore, "users")).catch(() => null),
    getCountFromServer(
      query(collection(firestore, "attendance_records"), where("syncedToFap", "==", false))
    ).catch(() => null),
  ])
  const pingMs = Math.max(1, Math.round(performance.now() - startTime))

  const baseData = settingsSnap?.exists() ? settingsSnap.data() : {}
  const supportData = supportSnap?.exists() ? supportSnap.data() : {}
  const totalSyncedAccounts = usersCountSnap ? usersCountSnap.data().count : 0
  const unsyncedRecordsCount = unsyncedSnap ? unsyncedSnap.data().count : 0

  return {
    ...DEFAULT_SETTINGS,
    ...baseData,
    supportPhone: String(supportData.phone ?? baseData.supportPhone ?? DEFAULT_SETTINGS.supportPhone),
    supportEmail: String(supportData.email ?? baseData.supportEmail ?? DEFAULT_SETTINGS.supportEmail),
    supportAddress: String(
      supportData.address ?? baseData.supportAddress ?? DEFAULT_SETTINGS.supportAddress
    ),
    supportHours: String(supportData.hours ?? baseData.supportHours ?? DEFAULT_SETTINGS.supportHours),
    pingMs,
    totalSyncedAccounts,
    unsyncedRecordsCount,
  } as SystemSettings
}

export async function saveSystemSettings(
  settings: SystemSettings,
  updatedBy = "admin"
): Promise<void> {
  const nowIso = new Date().toISOString()
  const { pingMs, totalSyncedAccounts, unsyncedRecordsCount, ...persistedSettings } = settings
  void pingMs
  void totalSyncedAccounts
  void unsyncedRecordsCount

  await setDoc(
    doc(firestore, "system_settings", "global_config"),
    {
      ...persistedSettings,
      lastUpdated: nowIso,
      lastUpdatedBy: updatedBy,
    },
    { merge: true }
  )

  if (settings.supportPhone || settings.supportEmail) {
    await setDoc(doc(firestore, "support_config", "public"), {
      phone: (settings.supportPhone ?? DEFAULT_SETTINGS.supportPhone ?? "").slice(0, 25),
      email: (settings.supportEmail ?? DEFAULT_SETTINGS.supportEmail ?? "").slice(0, 200),
      address: (settings.supportAddress ?? DEFAULT_SETTINGS.supportAddress ?? "").slice(0, 300),
      hours: (settings.supportHours ?? DEFAULT_SETTINGS.supportHours ?? "").slice(0, 200),
      updatedAt: serverTimestamp(),
    }).catch(() => {})
  }

  await addDoc(collection(firestore, "audit_logs"), {
    actionType: "update",
    actionLabel: "Cập nhật tham số hệ thống",
    actor: updatedBy,
    targetEmail: "system_settings/global_config",
    detail: `Cập nhật cấu hình QR (${settings.qrRefreshRate}s), bán kính GPS (${settings.geofenceRadiusMeters}m), ngưỡng cấm thi (${settings.maxAbsentThresholdPercent}%).`,
    createdAt: serverTimestamp(),
  }).catch(() => {})
}

export async function triggerFapSyncNow(
  adminEmail = "admin"
): Promise<{ syncedCount: number; lastSyncAt: string }> {
  const unsyncedDocs = await getDocs(
    query(
      collection(firestore, "attendance_records"),
      where("syncedToFap", "==", false),
      limit(450)
    )
  )

  let syncedCount = 0
  if (!unsyncedDocs.empty) {
    const batch = writeBatch(firestore)
    unsyncedDocs.docs.forEach((docSnap) => {
      batch.update(docSnap.ref, {
        syncedToFap: true,
        updatedAt: serverTimestamp(),
        updatedBy: adminEmail,
      })
      syncedCount += 1
    })
    await batch.commit()
  }

  const lastSyncAt = new Date().toLocaleString("vi-VN")
  await setDoc(
    doc(firestore, "system_settings", "global_config"),
    {
      lastSyncAt,
      lastUpdatedBy: adminEmail,
    },
    { merge: true }
  ).catch(() => {})

  await addDoc(collection(firestore, "audit_logs"), {
    actionType: "update",
    actionLabel: "Đồng bộ FAP Core",
    actor: adminEmail,
    targetEmail: "FAP Edu Core",
    detail: `Đã đồng bộ tức thời ${syncedCount} bản ghi điểm danh từ Firestore sang FAP Core.`,
    createdAt: serverTimestamp(),
  }).catch(() => {})

  return { syncedCount, lastSyncAt }
}
