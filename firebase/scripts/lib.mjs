// Tiện ích dùng chung cho script vận hành (Node + Admin SDK).
//
//   --emulator          dùng Firebase Emulator (Firestore 8085, Auth 9099) thay vì project thật
//   --project <id>      mặc định lấy từ .firebaserc ("default")
//
// Project thật cần Application Default Credentials:
//   gcloud auth application-default login      (hoặc GOOGLE_APPLICATION_CREDENTIALS=<key>.json)
// Khóa service account KHÔNG được commit vào repo.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

const here = dirname(fileURLToPath(import.meta.url));

export function parseArgs(argv = process.argv.slice(2)) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) { out._.push(a); continue; }
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) out[key] = true;
    else { out[key] = next; i++; }
  }
  return out;
}

export function defaultProjectId() {
  try {
    const rc = JSON.parse(readFileSync(join(here, '..', '..', '.firebaserc'), 'utf8'));
    return rc.projects?.default;
  } catch {
    return undefined;
  }
}

export function connect(args) {
  let projectId = args.project || defaultProjectId();
  if (args.emulator) {
    process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8085';
    process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
    projectId = args.project || 'demo-fapcheckin';
    initializeApp({ projectId });
  } else {
    if (!projectId) throw new Error('Thiếu project: truyền --project <id> hoặc tạo .firebaserc');
    initializeApp({ projectId, credential: applicationDefault() });
  }
  return { projectId, db: getFirestore(), auth: getAuth(), emulator: !!args.emulator };
}

/** Ghi nhiều tài liệu bằng batch ≤ 400 thao tác. */
export async function writeAll(db, collection, docs, { dryRun = false } = {}) {
  if (dryRun) return docs.length;
  for (let i = 0; i < docs.length; i += 400) {
    const batch = db.batch();
    for (const { id, data } of docs.slice(i, i + 400)) batch.set(db.collection(collection).doc(id), data);
    await batch.commit();
  }
  return docs.length;
}
