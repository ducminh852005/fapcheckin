// Thông báo trong app (`user_notifications/{uid}/items/{id}`) + push FCM tới `device_tokens/{uid}/tokens`.
// Client chỉ được đánh dấu `read` (firestore.rules); mọi thông báo do Functions tạo bằng Admin SDK.

/** Mã lỗi FCM nghĩa là token không còn dùng được -> xóa khỏi Firestore. */
export const STALE_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/** Id tài liệu an toàn (Firestore cấm '/', giới hạn độ dài). */
export function safeId(raw) {
  return String(raw).replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 300);
}

function alreadyExists(error) {
  return error?.code === 6 || error?.code === 'already-exists' || /already exists/i.test(String(error?.message));
}

/**
 * Tạo thông báo một lần (id xác định => trigger/cron chạy lại không tạo trùng).
 * @returns true nếu vừa tạo, false nếu đã tồn tại.
 */
export async function createNotification(deps, uid, id, { type, title, body, data = {} }) {
  const ref = deps.db.doc(`user_notifications/${uid}/items/${safeId(id)}`);
  try {
    await ref.create({ type, title, body, ...data, read: false, createdAt: deps.serverTimestamp() });
    return true;
  } catch (error) {
    if (alreadyExists(error)) return false;
    throw error;
  }
}

/**
 * Gửi push tới mọi thiết bị của uid; xóa token hỏng. Không có `messaging` (vd emulator) thì bỏ qua.
 * `data` của FCM chỉ nhận chuỗi.
 */
export async function pushToUser(deps, uid, { title, body, data = {} }) {
  const result = { sent: 0, failed: 0, removed: 0 };
  if (!deps.messaging) return result;
  const snap = await deps.db.collection(`device_tokens/${uid}/tokens`).get();
  const tokens = snap.docs
    .map((d) => ({ ref: d.ref, token: d.data()?.token }))
    .filter((t) => typeof t.token === 'string' && t.token.length > 0);
  if (tokens.length === 0) return result;

  const stringData = Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v ?? '')]));
  const response = await deps.messaging.sendEachForMulticast({
    tokens: tokens.map((t) => t.token),
    notification: { title, body },
    data: stringData,
    android: { priority: 'high' },
  });
  await Promise.all(response.responses.map(async (r, i) => {
    if (r.success) { result.sent++; return; }
    result.failed++;
    if (STALE_TOKEN_CODES.has(r.error?.code)) {
      await tokens[i].ref.delete().catch(() => {});
      result.removed++;
    }
  }));
  return result;
}
