// Cập nhật "Thông tin công tác" của giảng viên trên users/{uid}: khoa, bộ môn, chức vụ,
// ngày vào làm, loại hợp đồng. Các trường này do nhà trường quản lý — người dùng KHÔNG tự sửa
// được (firestore.rules chỉ cho tự sửa fullName/phone/birthDate/avatarPath).
//
//   node scripts/set-work-info.mjs --email gv001@fpt.edu.vn --department "Kỹ thuật phần mềm" \
//        --division "SE" --jobTitle "Giảng viên" --employmentDate 2020-09-01 --contractType "Cơ hữu" \
//        [--emulator] [--project <id>] [--dry-run]
//   (--uid <uid> thay cho --email nếu đã biết uid)
import { pathToFileURL } from 'node:url';
import { connect, parseArgs } from './lib.mjs';

export const WORK_FIELDS = ['department', 'division', 'jobTitle', 'employmentDate', 'contractType'];

export function validateWorkInfo(input) {
  const out = {};
  for (const key of WORK_FIELDS) {
    const raw = input[key];
    if (raw === undefined || raw === true) continue;
    const value = String(raw).trim();
    if (value.length > 200) throw new Error(`${key} quá dài (tối đa 200 ký tự).`);
    out[key] = value;
  }
  if (Object.keys(out).length === 0) throw new Error(`Cần ít nhất một trường: ${WORK_FIELDS.map((f) => `--${f}`).join(', ')}.`);
  if (out.employmentDate) {
    const d = new Date(`${out.employmentDate}T00:00:00Z`);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(out.employmentDate) || Number.isNaN(d.getTime())
      || d.toISOString().slice(0, 10) !== out.employmentDate) {
      throw new Error('employmentDate phải có dạng YYYY-MM-DD.');
    }
  }
  return out;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = parseArgs();
  let data;
  try {
    data = validateWorkInfo(args);
    if (!args.uid && !args.email) throw new Error('Cần --email hoặc --uid.');
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
  const { db, projectId } = connect(args);
  let ref;
  if (args.uid) {
    ref = db.doc(`users/${args.uid}`);
  } else {
    const hit = await db.collection('users').where('email', '==', String(args.email).toLowerCase()).limit(1).get();
    if (hit.empty) { console.error(`Không tìm thấy users với email ${args.email}`); process.exit(1); }
    ref = hit.docs[0].ref;
  }
  const snap = await ref.get();
  if (!snap.exists) { console.error(`Không tồn tại ${ref.path}`); process.exit(1); }
  if (snap.data().role !== 'staff') console.warn(`Cảnh báo: ${ref.path} có role=${snap.data().role}, không phải staff.`);
  if (args['dry-run']) console.log(`[${projectId}] (dry-run) ${ref.path} <-`, data);
  else { await ref.update(data); console.log(`[${projectId}] Đã cập nhật ${ref.path}:`, data); }
}
