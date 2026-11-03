// Cấu hình thông tin "Liên hệ hỗ trợ" hiển thị trong app: support_config/public.
// Chỉ admin/Admin SDK ghi được (firestore.rules). Không có giá trị mặc định: nhà trường
// phải cung cấp hotline/email chính thức.
//
//   node scripts/seed-support.mjs --phone "<hotline>" --email "<email>" [--address "..."] [--hours "..."]
//                                 [--emulator] [--project <id>] [--dry-run]
import { pathToFileURL } from 'node:url';
import { connect, parseArgs } from './lib.mjs';

export const SUPPORT_FIELDS = ['phone', 'email', 'address', 'hours'];

/** Kiểm tra và chuẩn hóa; ném Error với thông báo tiếng Việt nếu sai. */
export function validateSupport(input) {
  const out = {};
  for (const key of SUPPORT_FIELDS) {
    const raw = input[key];
    if (raw === undefined || raw === true) continue;
    out[key] = String(raw).trim();
  }
  if (!out.phone && !out.email) throw new Error('Cần ít nhất --phone hoặc --email.');
  if (out.phone !== undefined && !/^[+0-9 ()-]{3,25}$/.test(out.phone)) throw new Error('Số hotline không hợp lệ.');
  if (out.email !== undefined && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(out.email)) throw new Error('Email hỗ trợ không hợp lệ.');
  if ((out.address ?? '').length > 300 || (out.hours ?? '').length > 200) throw new Error('Địa chỉ/giờ làm việc quá dài.');
  return out;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = parseArgs();
  let data;
  try {
    data = validateSupport(args);
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
  const { db, projectId } = connect(args);
  if (args['dry-run']) {
    console.log(`[${projectId}] (dry-run) support_config/public =`, data);
  } else {
    const { FieldValue } = await import('firebase-admin/firestore');
    await db.doc('support_config/public').set({ ...data, updatedAt: FieldValue.serverTimestamp() });
    console.log(`[${projectId}] Đã ghi support_config/public:`, data);
  }
}
