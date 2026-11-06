// Sao chép toàn bộ Firestore từ project nguồn sang project đích (kể cả subcollection,
// document "ma" chỉ có subcollection, và các collection legacy).
//
//   node scripts/copy-firestore.mjs --from <srcProject> --to <dstProject>            # xem trước (chỉ đọc nguồn)
//   node scripts/copy-firestore.mjs --from <src> --to <dst> --apply                  # ghi thật, có checkpoint
//   node scripts/copy-firestore.mjs --from <src> --to <dst> --verify                 # so sánh số lượng document
//   thêm --checkpoint <file>  (mặc định: scripts/.copy-firestore.checkpoint.json, đã gitignore qua *.checkpoint.json)
//   thêm --skip <id,id>       bỏ qua các collection id (vd. device_tokens: FCM token gắn project cũ)
//
// Resumable: khi nguồn hết quota đọc (RESOURCE_EXHAUSTED) script dừng, lưu tiến độ; chạy lại sau khi
// quota reset sẽ bỏ qua những document đã sao chép. Ghi bằng set() nên idempotent.
// Giữ nguyên document ID, Timestamp, GeoPoint; DocumentReference được trỏ lại sang project đích.
//
// Cần Application Default Credentials: gcloud auth application-default login
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, DocumentReference } from 'firebase-admin/firestore';
import { parseArgs } from './lib.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const args = parseArgs();
const { from, to } = args;
if (!from || !to || from === to) {
  console.error('Cần --from <project nguồn> và --to <project đích> khác nhau.');
  process.exit(1);
}
const apply = !!args.apply;
const verify = !!args.verify;
const skip = new Set(String(args.skip || '').split(',').filter(Boolean));
const checkpointFile = args.checkpoint || join(here, '.copy-firestore.checkpoint.json');

const srcApp = initializeApp({ projectId: from, credential: applicationDefault() }, 'src');
const dstApp = initializeApp({ projectId: to, credential: applicationDefault() }, 'dst');
const src = getFirestore(srcApp);
const dst = getFirestore(dstApp);

const state = existsSync(checkpointFile)
  ? JSON.parse(readFileSync(checkpointFile, 'utf8'))
  : { done: [], collectionIds: [] };
const done = new Set(state.done);
const collectionIds = new Set(state.collectionIds);
let copied = 0;
let sinceSave = 0;

function save() {
  state.done = [...done];
  state.collectionIds = [...collectionIds];
  writeFileSync(checkpointFile, JSON.stringify(state));
  sinceSave = 0;
}

function isQuotaError(e) {
  return e?.code === 8 || /RESOURCE_EXHAUSTED|quota/i.test(e?.message || '');
}

// Đổi DocumentReference (trỏ project nguồn) thành tham chiếu trong project đích.
function remap(value) {
  if (value instanceof DocumentReference) return dst.doc(value.path);
  if (Array.isArray(value)) return value.map(remap);
  if (value && typeof value === 'object' && Object.getPrototypeOf(value) === Object.prototype) {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, remap(v)]));
  }
  return value;
}

const writer = dst.bulkWriter();
writer.onWriteError((err) => {
  console.error(`Ghi lỗi ${err.documentRef.path}: ${err.message}`);
  return err.failedAttempts < 5;
});

async function copyCollection(colRef) {
  if (skip.has(colRef.id)) {
    console.log(`  bỏ qua ${colRef.path}`);
    return;
  }
  collectionIds.add(colRef.id);
  const refs = await colRef.listDocuments(); // gồm cả doc không tồn tại nhưng có subcollection
  for (let i = 0; i < refs.length; i += 300) {
    const chunk = refs.slice(i, i + 300).filter((r) => !done.has(r.path));
    if (!chunk.length) continue;
    const snaps = await src.getAll(...chunk);
    for (const snap of snaps) {
      if (snap.exists && apply) writer.set(dst.doc(snap.ref.path), remap(snap.data()));
      if (snap.exists) copied++;
      for (const sub of await snap.ref.listCollections()) await copyCollection(sub);
      if (apply) {
        done.add(snap.ref.path);
        if (++sinceSave >= 200) { await writer.flush(); save(); }
      }
    }
  }
  console.log(`  ${colRef.path}: ${refs.length} document`);
}

async function runCopy() {
  console.log(`${apply ? 'COPY' : 'XEM TRƯỚC'} Firestore: ${from} -> ${to}`);
  try {
    for (const col of await src.listCollections()) await copyCollection(col);
  } catch (e) {
    await writer.flush();
    if (apply) save();
    if (isQuotaError(e)) {
      console.error(`Lỗi nguồn: ${e.message}`);
      console.error(`\nNguồn hết quota đọc. Đã sao chép ${copied} document trong lần chạy này; chạy lại sau khi quota reset.`);
      process.exit(2);
    }
    throw e;
  }
  await writer.close();
  if (apply) save();
  console.log(`\nXong: ${copied} document ${apply ? 'đã ghi' : 'sẽ ghi (chưa ghi, thêm --apply)'}.`);
}

async function runVerify() {
  if (!collectionIds.size) {
    for (const col of await src.listCollections()) collectionIds.add(col.id);
  }
  let ok = true;
  for (const id of [...collectionIds].sort()) {
    const [a, b] = await Promise.all([
      src.collectionGroup(id).count().get(),
      dst.collectionGroup(id).count().get(),
    ]);
    const same = a.data().count === b.data().count;
    if (!same) ok = false;
    console.log(`${same ? 'OK  ' : 'LỆCH'} ${id}: nguồn=${a.data().count} đích=${b.data().count}`);
  }
  process.exit(ok ? 0 : 3);
}

(verify ? runVerify() : runCopy()).catch((e) => {
  console.error(e);
  process.exit(1);
});
