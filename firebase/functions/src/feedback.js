// Xử lý góp ý (`feedback/{uid}_{requestId}`):
//  - tạo mới  -> báo cho mọi admin đang hoạt động (thông báo trong app + push)
//  - admin trả lời/đóng (status pending -> resolved) -> báo cho người gửi
//  - callable `resolveFeedback` cho trang admin: kiểm tra quyền + dữ liệu phía server.
import { createNotification, pushToUser } from './notify.js';

export const CATEGORY_LABEL = { bug: 'Báo lỗi', suggestion: 'Đề xuất', other: 'Khác' };
export const MAX_REPLY = 4000;

export class FeedbackError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function preview(text, max = 120) {
  const s = String(text ?? '').replace(/\s+/g, ' ').trim();
  return s.length > max ? `${s.slice(0, max - 1)}…` : s;
}

/** Góp ý mới -> mọi admin active. */
export async function notifyAdminsOfFeedback(deps, { id, data }) {
  if (!data?.authorUid) return { notified: 0 };
  const admins = await deps.db.collection('users').where('role', '==', 'admin').get();
  const label = CATEGORY_LABEL[data.category] ?? 'Góp ý';
  const message = { title: `Góp ý mới: ${label}`, body: preview(data.message) };
  let notified = 0;
  for (const admin of admins.docs) {
    if (admin.data()?.active === false || admin.id === data.authorUid) continue;
    const created = await createNotification(deps, admin.id, `feedback_new_${id}`, {
      type: 'feedback_new', ...message, data: { feedbackId: id, category: data.category ?? 'other' },
    });
    if (!created) continue;
    notified++;
    await pushToUser(deps, admin.id, { ...message, data: { type: 'feedback_new', feedbackId: id } })
      .catch((e) => deps.log?.('push failed', admin.id, e));
  }
  return { notified };
}

/** Chỉ khi chuyển sang resolved mới báo cho người gửi. */
export function isNewlyResolved(before, after) {
  return before?.status !== 'resolved' && after?.status === 'resolved' && !!after?.authorUid;
}

export async function notifyAuthorOfResolution(deps, { id, before, after }) {
  if (!isNewlyResolved(before, after)) return { notified: false };
  const reply = preview(after.reply, 300);
  const message = {
    title: 'Góp ý của bạn đã được xử lý',
    body: reply || `Nhà trường đã xử lý góp ý: “${preview(after.message, 80)}”.`,
  };
  const created = await createNotification(deps, after.authorUid, `feedback_resolved_${id}`, {
    type: 'feedback_resolved', ...message, data: { feedbackId: id },
  });
  if (created) {
    await pushToUser(deps, after.authorUid, { ...message, data: { type: 'feedback_resolved', feedbackId: id } })
      .catch((e) => deps.log?.('push failed', after.authorUid, e));
  }
  return { notified: created };
}

/** Callable cho admin: { feedbackId, reply?, status? = 'resolved' | 'pending' }. */
export async function resolveFeedback(deps, { uid, feedbackId, reply = '', status = 'resolved' }) {
  const { db, serverTimestamp } = deps;
  if (!uid) throw new FeedbackError('unauthenticated', 'UNAUTHORIZED', 'Cần đăng nhập.');
  const me = await db.doc(`users/${uid}`).get();
  if (!me.exists || me.data()?.role !== 'admin' || me.data()?.active === false) {
    throw new FeedbackError('permission-denied', 'FORBIDDEN', 'Chỉ quản trị viên được xử lý góp ý.');
  }
  if (typeof feedbackId !== 'string' || !/^[A-Za-z0-9_-]{1,300}$/.test(feedbackId)) {
    throw new FeedbackError('invalid-argument', 'VALIDATION_ERROR', 'feedbackId không hợp lệ.');
  }
  if (!['resolved', 'pending'].includes(status) || typeof reply !== 'string' || reply.trim().length > MAX_REPLY) {
    throw new FeedbackError('invalid-argument', 'VALIDATION_ERROR', `Trạng thái hoặc phản hồi không hợp lệ (tối đa ${MAX_REPLY} ký tự).`);
  }
  if (status === 'resolved' && reply.trim().length === 0) {
    throw new FeedbackError('invalid-argument', 'VALIDATION_ERROR', 'Nhập nội dung phản hồi trước khi đóng góp ý.');
  }
  const ref = db.doc(`feedback/${feedbackId}`);
  const snap = await ref.get();
  if (!snap.exists) throw new FeedbackError('not-found', 'NOT_FOUND', 'Không tìm thấy góp ý.');
  await ref.update({
    status,
    reply: reply.trim(),
    resolvedAt: status === 'resolved' ? serverTimestamp() : null,
  });
  return { feedbackId, status };
}
