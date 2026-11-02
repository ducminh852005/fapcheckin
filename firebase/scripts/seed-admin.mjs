// Tạo tài khoản Admin đầu tiên (bootstrap). Rules không cho client tự đặt role,
// nên bước này dùng Admin SDK (hoặc làm tay trong Console — xem README.md).
//
//   node scripts/seed-admin.mjs --email admin@fpt.edu.vn [--name "Quản trị"] \
//        [--member-code AD001] [--password <chỉ dùng với --emulator>] [--emulator] [--project <id>]
//
// Việc làm: tìm/tạo user trong Firebase Auth theo email, rồi ghi users/{uid} với role "admin".
// Sau đó đăng nhập bằng Google với đúng email này.
import { connect, parseArgs } from './lib.mjs';
import { FieldValue } from 'firebase-admin/firestore';

const args = parseArgs();
if (typeof args.email !== 'string') {
  console.error('Thiếu --email. Ví dụ: node scripts/seed-admin.mjs --email admin@fpt.edu.vn');
  process.exit(1);
}
const email = args.email.trim().toLowerCase();
const { db, auth, projectId, emulator } = connect(args);

let user;
try {
  user = await auth.getUserByEmail(email);
} catch (e) {
  if (e.code !== 'auth/user-not-found') throw e;
  user = await auth.createUser({
    email,
    emailVerified: true,
    displayName: typeof args.name === 'string' ? args.name : undefined,
    ...(emulator && typeof args.password === 'string' ? { password: args.password } : {}),
  });
  console.log(`Đã tạo user Auth ${user.uid} (${email})`);
}

await db.doc(`users/${user.uid}`).set({
  memberCode: typeof args['member-code'] === 'string' ? args['member-code'] : 'AD001',
  fullName: typeof args.name === 'string' ? args.name : (user.displayName ?? 'Quản trị viên'),
  email,
  role: 'admin',
  active: true,
  createdAt: FieldValue.serverTimestamp(),
});
console.log(`[${projectId}] users/${user.uid} = admin (${email})`);
