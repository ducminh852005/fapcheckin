// Chuẩn hoá users/{id}.role về bộ giá trị chuẩn của firestore.rules: user | staff | admin.
//
//   GV -> staff        SV -> user
//
// Giá trị gốc được giữ lại ở trường `legacyRole` ("SV" | "GV") để vẫn nhận diện được
// bản ghi legacy và có thể hoàn tác. Không đụng tới trường nào khác (đặc biệt là `active`).
// Mặc định chỉ xem trước; --apply mới ghi, trong MỘT batch nguyên tử (≤ 500 tài liệu).
//
//   node scripts/normalize-roles.mjs                 # xem trước
//   node scripts/normalize-roles.mjs --apply         # ghi thật
//   node scripts/normalize-roles.mjs --revert --apply  # trả role về legacyRole
//   thêm --emulator / --project <id> như các script khác
import { FieldValue } from 'firebase-admin/firestore';
import { connect, parseArgs } from './lib.mjs';

const args = parseArgs();
const { db, projectId } = connect(args);
const apply = args.apply === true;
const revert = args.revert === true;
const MAP = { GV: 'staff', SV: 'user' };

const snap = await db.collection('users').get();
const counts = {};
const targets = [];
const unknown = {};
for (const doc of snap.docs) {
  const role = doc.get('role');
  counts[role] = (counts[role] ?? 0) + 1;
  if (revert) {
    const legacy = doc.get('legacyRole');
    if (legacy in MAP && doc.get('role') === MAP[legacy]) {
      targets.push({ doc, update: { role: legacy, legacyRole: FieldValue.delete() } });
    }
  } else if (role in MAP) {
    targets.push({ doc, update: { role: MAP[role], legacyRole: role } });
  } else if (!['user', 'staff', 'admin'].includes(role)) {
    unknown[role] = (unknown[role] ?? 0) + 1;
  }
}

console.log(JSON.stringify({ projectId, mode: revert ? 'revert' : 'normalize', apply, usersTotal: snap.size,
  roleCounts: counts, toChange: targets.length, unknownRoles: unknown }, null, 2));

if (!apply) {
  console.log('Preview only. Add --apply to write.');
} else if (targets.length > 500) {
  throw new Error('More than 500 documents; no changes made. Requires a planned multi-batch run.');
} else if (targets.length) {
  const batch = db.batch();
  for (const { doc, update } of targets) {
    batch.update(doc.ref, update, { lastUpdateTime: doc.updateTime });
  }
  await batch.commit();
  console.log(`Updated ${targets.length} documents.`);
} else {
  console.log('Nothing to change.');
}
