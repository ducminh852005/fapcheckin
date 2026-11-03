// Rules cho các chức năng tài khoản: hồ sơ mở rộng, tùy chọn, liên hệ hỗ trợ, góp ý,
// thông báo trong app và token thiết bị (push nhắc lịch).
import { describe, it, before, after, beforeEach } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc, updateDoc, where,
} from 'firebase/firestore';
import { as, createEnv, seed } from './helpers.mjs';

let env;
before(async () => { env = await createEnv(); });
after(async () => { await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'support_config/public'), { phone: '0123', email: 'support@example.edu' });
    await setDoc(doc(db, 'feedback/u-t1_req-existing'), { authorUid: 'u-t1', category: 'bug', message: 'Lỗi', status: 'pending' });
    await setDoc(doc(db, 'feedback/u-t2_req-other'), { authorUid: 'u-t2', category: 'other', message: 'Khác', status: 'pending' });
    await setDoc(doc(db, 'user_notifications/u-t1/items/n1'), { type: 'teaching_reminder', title: 'T', body: 'B', read: false });
    await setDoc(doc(db, 'device_tokens/u-t1/tokens/d1'), { token: 'tok' });
  });
});

describe('users — hồ sơ mở rộng', () => {
  it('tự sửa họ tên, số điện thoại, ngày sinh, avatar của mình', async () => {
    const db = as(env, 't1');
    await assertSucceeds(updateDoc(doc(db, 'users/u-t1'), {
      fullName: 'GV Một', phone: '+84 912-345-678', birthDate: '1990-05-01', avatarPath: 'avatars/u-t1/profile.jpg',
    }));
    await assertSucceeds(updateDoc(doc(db, 'users/u-t1'), { phone: '', birthDate: '', avatarPath: '' }));
  });
  it('từ chối số điện thoại / ngày sinh / họ tên sai định dạng', async () => {
    const db = as(env, 't1');
    await assertFails(updateDoc(doc(db, 'users/u-t1'), { phone: 'gọi tôi' }));
    await assertFails(updateDoc(doc(db, 'users/u-t1'), { phone: '1'.repeat(26) }));
    await assertFails(updateDoc(doc(db, 'users/u-t1'), { birthDate: '01/05/1990' }));
    await assertFails(updateDoc(doc(db, 'users/u-t1'), { fullName: '' }));
    await assertFails(updateDoc(doc(db, 'users/u-t1'), { fullName: 'x'.repeat(201) }));
  });
  it('avatarPath chỉ trỏ tới thư mục của chính mình', async () => {
    const db = as(env, 't1');
    await assertFails(updateDoc(doc(db, 'users/u-t1'), { avatarPath: 'avatars/u-t2/profile.jpg' }));
    await assertFails(updateDoc(doc(db, 'users/u-t1'), { avatarPath: 'timetable_scans/u-t1/a.png' }));
  });
  it('không tự sửa thông tin công tác; admin thì được', async () => {
    await assertFails(updateDoc(doc(as(env, 't1'), 'users/u-t1'), { department: 'SE' }));
    await assertFails(updateDoc(doc(as(env, 't1'), 'users/u-t1'), { contractType: 'Cơ hữu' }));
    await assertSucceeds(updateDoc(doc(as(env, 'admin'), 'users/u-t1'), {
      department: 'Kỹ thuật phần mềm', division: 'SE', jobTitle: 'Giảng viên',
      employmentDate: '2020-09-01', contractType: 'Cơ hữu',
    }));
  });
  it('không sửa hồ sơ người khác; tài khoản bị khóa không tự sửa', async () => {
    await assertFails(updateDoc(doc(as(env, 't1'), 'users/u-t2'), { phone: '0123' }));
    await assertFails(updateDoc(doc(as(env, 's3'), 'users/u-s3'), { phone: '0123' }));
  });
});

describe('user_preferences', () => {
  const pref = (over = {}) => ({ theme: 'dark', language: 'en', reminders: true, updatedAt: serverTimestamp(), ...over });
  it('tự lưu và đọc tùy chọn của mình', async () => {
    const db = as(env, 't1');
    await assertSucceeds(setDoc(doc(db, 'user_preferences/u-t1'), pref()));
    await assertSucceeds(getDoc(doc(db, 'user_preferences/u-t1')));
  });
  it('từ chối giá trị lạ, trường thừa, timestamp do client tự đặt', async () => {
    const db = as(env, 't1');
    await assertFails(setDoc(doc(db, 'user_preferences/u-t1'), pref({ theme: 'neon' })));
    await assertFails(setDoc(doc(db, 'user_preferences/u-t1'), pref({ language: 'fr' })));
    await assertFails(setDoc(doc(db, 'user_preferences/u-t1'), pref({ reminders: 'yes' })));
    await assertFails(setDoc(doc(db, 'user_preferences/u-t1'), pref({ role: 'admin' })));
    await assertFails(setDoc(doc(db, 'user_preferences/u-t1'), pref({ updatedAt: new Date('2020-01-01') })));
  });
  it('không đọc/ghi tùy chọn của người khác; tài khoản khóa không ghi', async () => {
    await assertFails(setDoc(doc(as(env, 't2'), 'user_preferences/u-t1'), pref()));
    await assertFails(getDoc(doc(as(env, 't2'), 'user_preferences/u-t1')));
    await assertFails(setDoc(doc(as(env, 's3'), 'user_preferences/u-s3'), pref()));
  });
});

describe('support_config', () => {
  it('mọi tài khoản có hồ sơ đọc được; người lạ thì không', async () => {
    await assertSucceeds(getDoc(doc(as(env, 't1'), 'support_config/public')));
    await assertSucceeds(getDoc(doc(as(env, 's1'), 'support_config/public')));
    await assertFails(getDoc(doc(as(env, 'stranger'), 'support_config/public')));
  });
  it('chỉ admin ghi, đúng định dạng', async () => {
    const ok = { phone: '(028) 7300 5588', email: 'hotro@fpt.edu.vn', hours: '8:00–17:00', updatedAt: serverTimestamp() };
    await assertFails(setDoc(doc(as(env, 't1'), 'support_config/public'), ok));
    await assertSucceeds(setDoc(doc(as(env, 'admin'), 'support_config/public'), ok));
    await assertFails(setDoc(doc(as(env, 'admin'), 'support_config/public'), { ...ok, phone: 'abc' }));
    await assertFails(setDoc(doc(as(env, 'admin'), 'support_config/public'), { ...ok, script: '<x>' }));
  });
});

describe('feedback', () => {
  const fb = (over = {}) => ({ authorUid: 'u-t1', category: 'bug', message: 'Không quét được QR', status: 'pending', createdAt: serverTimestamp(), ...over });
  it('gửi góp ý của mình với id {uid}_{requestId}', async () => {
    await assertSucceeds(setDoc(doc(as(env, 't1'), 'feedback/u-t1_req-00000001'), fb()));
    await assertSucceeds(setDoc(doc(as(env, 's1'), 'feedback/u-s1_req-00000001'), fb({ authorUid: 'u-s1', category: 'suggestion' })));
    await assertSucceeds(setDoc(doc(as(env, 't1'), 'feedback/u-t1_req-00000008'), fb({ attachments: ['feedback_attachments/u-t1/req-00000008_0.jpg'] })));
  });
  it('chặn mạo danh, id sai, trạng thái sai, nội dung rỗng/quá dài, trường thừa', async () => {
    const db = as(env, 't1');
    await assertFails(setDoc(doc(db, 'feedback/u-t2_req-00000001'), fb()));
    await assertFails(setDoc(doc(db, 'feedback/u-t1_req-00000002'), fb({ authorUid: 'u-t2' })));
    await assertFails(setDoc(doc(db, 'feedback/u-t1_req-00000003'), fb({ status: 'resolved' })));
    await assertFails(setDoc(doc(db, 'feedback/u-t1_req-00000004'), fb({ message: '' })));
    await assertFails(setDoc(doc(db, 'feedback/u-t1_req-00000005'), fb({ message: 'x'.repeat(2001) })));
    await assertFails(setDoc(doc(db, 'feedback/u-t1_req-00000006'), fb({ category: 'spam' })));
    await assertFails(setDoc(doc(db, 'feedback/u-t1_req-00000007'), fb({ reply: 'tự trả lời' })));
    await assertFails(setDoc(doc(db, 'feedback/u-t1_req-00000009'), fb({ attachments: ['1', '2', '3', '4'] })));
    await assertFails(setDoc(doc(as(env, 's3'), 'feedback/u-s3_req-00000001'), fb({ authorUid: 'u-s3' })));
  });
  it('người gửi đọc/list góp ý của mình, không đọc của người khác', async () => {
    const db = as(env, 't1');
    await assertSucceeds(getDoc(doc(db, 'feedback/u-t1_req-existing')));
    await assertFails(getDoc(doc(db, 'feedback/u-t2_req-other')));
    await assertSucceeds(getDocs(query(collection(db, 'feedback'), where('authorUid', '==', 'u-t1'))));
    await assertFails(getDocs(collection(db, 'feedback')));
  });
  it('người gửi không tự đóng/sửa/xóa; admin trả lời và đóng', async () => {
    await assertFails(updateDoc(doc(as(env, 't1'), 'feedback/u-t1_req-existing'), { status: 'resolved' }));
    await assertFails(deleteDoc(doc(as(env, 't1'), 'feedback/u-t1_req-existing')));
    const adm = as(env, 'admin');
    await assertSucceeds(getDocs(collection(adm, 'feedback')));
    await assertFails(updateDoc(doc(adm, 'feedback/u-t1_req-existing'), { message: 'sửa nội dung' }));
    await assertFails(updateDoc(doc(adm, 'feedback/u-t1_req-existing'), { status: 'deleted' }));
    await assertSucceeds(updateDoc(doc(adm, 'feedback/u-t1_req-existing'), { status: 'resolved', reply: 'Đã sửa', resolvedAt: serverTimestamp() }));
  });
});

describe('user_notifications', () => {
  it('chủ sở hữu đọc và đánh dấu đã đọc', async () => {
    const db = as(env, 't1');
    await assertSucceeds(getDoc(doc(db, 'user_notifications/u-t1/items/n1')));
    await assertSucceeds(getDocs(collection(db, 'user_notifications/u-t1/items')));
    await assertSucceeds(updateDoc(doc(db, 'user_notifications/u-t1/items/n1'), { read: true }));
  });
  it('không sửa nội dung, không tự tạo/xóa; người khác không đọc', async () => {
    const db = as(env, 't1');
    await assertFails(updateDoc(doc(db, 'user_notifications/u-t1/items/n1'), { title: 'giả' }));
    await assertFails(updateDoc(doc(db, 'user_notifications/u-t1/items/n1'), { read: 'yes' }));
    await assertFails(setDoc(doc(db, 'user_notifications/u-t1/items/n2'), { title: 'x', read: false }));
    await assertFails(deleteDoc(doc(db, 'user_notifications/u-t1/items/n1')));
    await assertFails(getDoc(doc(as(env, 't2'), 'user_notifications/u-t1/items/n1')));
    await assertFails(setDoc(doc(as(env, 'admin'), 'user_notifications/u-t1/items/n3'), { title: 'x', read: false }));
  });
});

describe('device_tokens', () => {
  it('đăng ký, đọc và gỡ token thiết bị của mình', async () => {
    const db = as(env, 't1');
    await assertSucceeds(setDoc(doc(db, 'device_tokens/u-t1/tokens/d2'), { token: 'fcm-token', updatedAt: serverTimestamp() }));
    await assertSucceeds(getDoc(doc(db, 'device_tokens/u-t1/tokens/d1')));
    await assertSucceeds(deleteDoc(doc(db, 'device_tokens/u-t1/tokens/d1')));
  });
  it('không ghi token cho người khác, token rỗng, trường thừa', async () => {
    const db = as(env, 't1');
    await assertFails(setDoc(doc(db, 'device_tokens/u-t2/tokens/d2'), { token: 'x', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'device_tokens/u-t1/tokens/d3'), { token: '', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'device_tokens/u-t1/tokens/d4'), { token: 'x', uid: 'u-t2', updatedAt: serverTimestamp() }));
    await assertFails(getDoc(doc(as(env, 't2'), 'device_tokens/u-t1/tokens/d1')));
  });
});
