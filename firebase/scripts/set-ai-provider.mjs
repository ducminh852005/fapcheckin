// Đổi nguồn AI của tab AI ngay lập tức, KHÔNG cần deploy: ghi tài liệu `ai_config/provider`
// (chỉ Admin SDK đọc/ghi; client không truy cập được — rules mặc định chặn). Cloud Function `aiAssistant`
// đọc tài liệu này ở mỗi lượt.
//
//   node scripts/set-ai-provider.mjs --provider auto|gemini|ollama [--url https://xxx.trycloudflare.com]
//        [--model qwen2.5:7b] [--emulator] [--project <id>]
//   node scripts/set-ai-provider.mjs --show
//
//   auto    Gemini trước; Gemini quá tải/lỗi thì tự sang Ollama (cần URL)   ← mặc định
//   gemini  chỉ Gemini
//   ollama  chỉ Ollama (dùng khi biết Gemini đang quá tải: khỏi chờ thử lại)
import { connect, parseArgs } from './lib.mjs';
import { FieldValue } from 'firebase-admin/firestore';

const MODES = ['auto', 'gemini', 'ollama'];
const args = parseArgs();
const { db, projectId } = connect(args);
const ref = db.doc('ai_config/provider');

if (args.show) {
  const snap = await ref.get();
  console.log(`[${projectId}]`, snap.exists ? JSON.stringify(snap.data(), (k, v) => (v?._seconds ? undefined : v)) : '(chưa cấu hình: dùng mặc định auto, không có Ollama)');
  process.exit(0);
}

const update = {};
if (typeof args.provider === 'string') {
  if (!MODES.includes(args.provider)) {
    console.error(`--provider phải là một trong: ${MODES.join(', ')}`);
    process.exit(1);
  }
  update.provider = args.provider;
}
if (typeof args.url === 'string') {
  if (!/^https?:\/\//.test(args.url)) {
    console.error('--url phải bắt đầu bằng http:// hoặc https://');
    process.exit(1);
  }
  update.ollamaUrl = args.url.replace(/\/+$/, '');
}
if (typeof args.model === 'string') update.ollamaModel = args.model;

if (Object.keys(update).length === 0) {
  console.error('Không có gì để đổi. Ví dụ: node scripts/set-ai-provider.mjs --provider ollama --url https://xxx.trycloudflare.com');
  process.exit(1);
}
if (update.provider === 'ollama') {
  const current = (await ref.get()).data() ?? {};
  if (!update.ollamaUrl && !current.ollamaUrl) {
    console.error('Chế độ ollama cần URL: thêm --url https://<tunnel> (hoặc chạy scripts/ai-fallback.ps1 up).');
    process.exit(1);
  }
}

await ref.set({ ...update, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
const now = (await ref.get()).data();
console.log(`[${projectId}] ai_config/provider → provider=${now.provider ?? 'auto'} ollamaUrl=${now.ollamaUrl ?? '-'} ollamaModel=${now.ollamaModel ?? '(mặc định)'}`);
