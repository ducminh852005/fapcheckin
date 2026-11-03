import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  isNewlyResolved, notifyAdminsOfFeedback, notifyAuthorOfResolution, resolveFeedback,
} from '../src/feedback.js';
import { deps, fakeDb, fakeMessaging } from './fakes.js';

const fb = { authorUid: 'u-t1', category: 'bug', message: 'Không quét được QR', status: 'pending' };

function seeded() {
  return fakeDb({
    'users/u-admin': { role: 'admin', memberCode: 'AD01', active: true },
    'users/u-admin-off': { role: 'admin', memberCode: 'AD02', active: false },
    'users/u-t1': { role: 'staff', memberCode: 'GV001', active: true },
    'feedback/u-t1_req12345': fb,
    'device_tokens/u-t1/tokens/a': { token: 'tok-t1' },
  });
}

test('góp ý mới -> chỉ admin đang hoạt động được báo, không trùng khi trigger chạy lại', async () => {
  const db = seeded();
  const r1 = await notifyAdminsOfFeedback(deps(db), { id: 'u-t1_req12345', data: fb });
  const r2 = await notifyAdminsOfFeedback(deps(db), { id: 'u-t1_req12345', data: fb });
  assert.equal(r1.notified, 1);
  assert.equal(r2.notified, 0);
  const item = db.store.get('user_notifications/u-admin/items/feedback_new_u-t1_req12345');
  assert.equal(item.type, 'feedback_new');
  assert.match(item.title, /Báo lỗi/);
  assert.equal(item.body, fb.message);
  assert.equal(db.store.has('user_notifications/u-admin-off/items/feedback_new_u-t1_req12345'), false);
});

test('isNewlyResolved chỉ đúng khi chuyển sang resolved', () => {
  assert.equal(isNewlyResolved({ status: 'pending' }, { ...fb, status: 'resolved' }), true);
  assert.equal(isNewlyResolved({ status: 'resolved' }, { ...fb, status: 'resolved' }), false);
  assert.equal(isNewlyResolved({ status: 'pending' }, { ...fb, status: 'pending' }), false);
});

test('đóng góp ý -> người gửi nhận thông báo + push kèm phản hồi', async () => {
  const db = seeded();
  const fcm = fakeMessaging();
  const after = { ...fb, status: 'resolved', reply: 'Đã sửa ở bản 1.2' };
  const r = await notifyAuthorOfResolution(deps(db, fcm), { id: 'u-t1_req12345', before: fb, after });
  assert.equal(r.notified, true);
  const item = db.store.get('user_notifications/u-t1/items/feedback_resolved_u-t1_req12345');
  assert.equal(item.body, 'Đã sửa ở bản 1.2');
  assert.deepEqual(fcm.sent[0].tokens, ['tok-t1']);
  // Trigger lặp lại không push thêm.
  await notifyAuthorOfResolution(deps(db, fcm), { id: 'u-t1_req12345', before: fb, after });
  assert.equal(fcm.sent.length, 1);
});

test('resolveFeedback: chỉ admin, bắt buộc phản hồi, góp ý phải tồn tại', async () => {
  const db = seeded();
  const call = (over) => resolveFeedback(deps(db), { uid: 'u-admin', feedbackId: 'u-t1_req12345', reply: 'OK', ...over });
  await assert.rejects(call({ uid: undefined }), { code: 'UNAUTHORIZED' });
  await assert.rejects(call({ uid: 'u-t1' }), { code: 'FORBIDDEN' });
  await assert.rejects(call({ uid: 'u-admin-off' }), { code: 'FORBIDDEN' });
  await assert.rejects(call({ reply: '   ' }), { code: 'VALIDATION_ERROR' });
  await assert.rejects(call({ reply: 'x'.repeat(4001) }), { code: 'VALIDATION_ERROR' });
  await assert.rejects(call({ status: 'deleted' }), { code: 'VALIDATION_ERROR' });
  await assert.rejects(call({ feedbackId: '../users/u-admin' }), { code: 'VALIDATION_ERROR' });
  await assert.rejects(call({ feedbackId: 'missing' }), { code: 'NOT_FOUND' });

  assert.deepEqual(await call({ reply: '  Đã xử lý  ' }), { feedbackId: 'u-t1_req12345', status: 'resolved' });
  const saved = db.store.get('feedback/u-t1_req12345');
  assert.equal(saved.status, 'resolved');
  assert.equal(saved.reply, 'Đã xử lý');
  assert.equal(saved.resolvedAt, 'SERVER_TS');
  assert.equal(saved.message, fb.message, 'không đổi nội dung gốc');
});
