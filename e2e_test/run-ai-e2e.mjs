// Chạy e2e Trợ lý AI: dựng env cho Functions emulator (Gemini giả + key giả) rồi bọc trong `firebase emulators:exec`.
//   node run-ai-e2e.mjs            (hoặc: npm run test:ai)
import { spawnSync } from 'node:child_process';
import path from 'node:path';

const PORT = process.env.FAKE_GEMINI_PORT ?? '5599';
const env = {
  ...process.env,
  FAKE_GEMINI_PORT: PORT,
  // Functions emulator kế thừa env này: aiAssistant gọi Gemini giả thay vì Google.
  GEMINI_API_BASE: `http://127.0.0.1:${PORT}/v1beta`,
  GEMINI_API_KEY: process.env.GEMINI_API_KEY ?? 'e2e-test-key',
  GEMINI_MODEL: 'gemini-e2e',
};

const root = path.resolve(import.meta.dirname, '..');
// Một chuỗi lệnh duy nhất (shell) để lệnh con có dấu cách không bị tách đối số trên Windows.
const inner = 'node --test --test-concurrency=1 e2e_test/ai_assistant.e2e.test.mjs';
const command =
  `firebase emulators:exec --project demo-fapcheckin --only auth,firestore,functions "${inner}"`;
const r = spawnSync(command, { cwd: root, env, stdio: 'inherit', shell: true });
process.exit(r.status ?? 1);
