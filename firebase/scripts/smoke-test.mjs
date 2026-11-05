// Smoke test sau khi deploy: kiểm tra trang check-in và cấu hình bảo mật đang chạy thật.
// Chỉ gọi HTTP công khai (không cần khóa/đăng nhập), nên chạy được cả trên preview channel lẫn live.
//
//   node scripts/smoke-test.mjs <baseUrl> [projectId]
//   vd: node scripts/smoke-test.mjs https://ducminh-41459.web.app
//
// Kiểm tra:
//   1. Trang SV là bản Firebase (nạp app.js, không còn Apps Script / BACKEND_URL)
//   2. app.js tải được và ghi đúng collection attendance_records
//   3. /__/firebase/init.json trả cấu hình của đúng project
//   4. Firestore Rules đang chạy: đọc không đăng nhập bị từ chối (403)
//   5. Auth không cho đăng ký ẩn danh (mọi tài khoản phải do admin cấp)
import { defaultProjectId } from './lib.mjs';

const base = (process.argv[2] || '').replace(/\/$/, '');
if (!base) {
  console.error('Usage: node scripts/smoke-test.mjs <baseUrl> [projectId]');
  process.exit(2);
}
const expectedProject = process.argv[3] || defaultProjectId();

const failures = [];
const check = async (name, fn) => {
  try {
    const detail = await fn();
    console.log(`ok   ${name}${detail ? ` — ${detail}` : ''}`);
  } catch (error) {
    failures.push(name);
    console.log(`FAIL ${name} — ${error.message}`);
  }
};
const assert = (cond, message) => { if (!cond) throw new Error(message); };
const get = (path, init) => fetch(`${base}${path}`, { redirect: 'follow', ...init });

let config;

await check('trang SV trả 200 và là bản Firebase', async () => {
  const res = await get('/');
  assert(res.status === 200, `HTTP ${res.status}`);
  const html = await res.text();
  assert(html.includes('src="./app.js"'), 'không nạp app.js (có thể vẫn là trang Apps Script cũ)');
  assert(!/script\.google\.com|BACKEND_URL/.test(html), 'còn tham chiếu Apps Script / BACKEND_URL');
});

await check('app.js tải được và ghi attendance_records', async () => {
  const res = await get('/app.js');
  assert(res.status === 200, `HTTP ${res.status}`);
  const js = await res.text();
  assert(js.includes('attendance_records'), 'thiếu logic điểm danh');
});

await check('init.json đúng project', async () => {
  const res = await get('/__/firebase/init.json');
  assert(res.status === 200, `HTTP ${res.status}`);
  config = await res.json();
  assert(config.apiKey && config.projectId, 'thiếu apiKey/projectId');
  if (expectedProject) assert(config.projectId === expectedProject, `projectId=${config.projectId}, mong đợi ${expectedProject}`);
  return config.projectId;
});

await check('Firestore Rules chặn đọc không đăng nhập', async () => {
  assert(config, 'bỏ qua do thiếu cấu hình');
  const url = `https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/(default)/documents/users/smoke?key=${config.apiKey}`;
  const res = await fetch(url);
  assert(res.status === 403, `HTTP ${res.status} (mong đợi 403)`);
});

await check('Auth không cho đăng ký ẩn danh', async () => {
  assert(config, 'bỏ qua do thiếu cấu hình');
  const res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${config.apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ returnSecureToken: true }),
  });
  const body = await res.json();
  assert(!body.idToken, 'đăng ký ẩn danh đang được bật');
});

if (failures.length) {
  console.error(`\n${failures.length} kiểm tra thất bại: ${failures.join('; ')}`);
  process.exit(1);
}
console.log('\nSmoke test đạt.');
