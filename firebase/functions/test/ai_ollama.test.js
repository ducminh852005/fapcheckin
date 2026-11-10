import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  AiError, OLLAMA_TOOLS, TOOL_DECLARATIONS, buildOllamaRequest, loadProviderConfig, parseOllamaResponse, runAiAssistant,
} from '../src/ai_assistant.js';
import { fakeDb } from './fakes.js';

const OLLAMA = 'http://ollama.test';
const user = (text) => ({ role: 'user', text });
const textBody = (text) => ({ candidates: [{ content: { parts: [{ text }] } }] });

const db = (cfg) => fakeDb({
  'users/gv1': { role: 'staff', active: true, memberCode: 'GV001' },
  ...(cfg ? { 'ai_config/provider': cfg } : {}),
});

const geminiOk = () => ({ ok: true, status: 200, json: async () => textBody('từ gemini') });
const ollamaText = (text) => ({ ok: true, status: 200, json: async () => ({ message: { role: 'assistant', content: text } }) });
const busy = () => ({ ok: false, status: 503, text: async () => 'busy' });

/** fetch giả: URL của Ollama đi nhánh `ollama`, còn lại là Gemini. Ghi lại URL đã gọi. */
const route = ({ gemini, ollama }, calls = []) => async (url) => {
  calls.push(url);
  return url.startsWith(OLLAMA) ? ollama() : gemini();
};
const deps = (database, fetchImpl, extra = {}) => ({ db: database, apiKey: 'k', fetchImpl, sleep: async () => {}, env: {}, ...extra });
const quiet = async (fn) => {
  const orig = console.error;
  console.error = () => {};
  try { return await fn(); } finally { console.error = orig; }
};

async function rejects(promise, status, code) {
  await assert.rejects(promise, (e) => {
    assert.ok(e instanceof AiError, `AiError expected, got ${e}`);
    assert.equal(e.status, status);
    assert.equal(e.code, code);
    return true;
  });
}

describe('Ollama: chuyển đổi định dạng', () => {
  it('tool khai báo kiểu OpenAI (type viết thường) và tin nhắn/tool call/kết quả đúng dạng', () => {
    assert.equal(OLLAMA_TOOLS.length, TOOL_DECLARATIONS.length);
    const mark = OLLAMA_TOOLS.find((t) => t.function.name === 'mark_attendance').function.parameters;
    assert.equal(mark.type, 'object');
    assert.equal(mark.properties.students.type, 'array');
    assert.equal(mark.properties.students.items.properties.status.type, 'string');
    const req = buildOllamaRequest([
      user('điểm danh'),
      { role: 'model', toolCalls: [{ name: 'find_student', args: { query: 'x' } }] },
      { role: 'tool', name: 'find_student', result: { count: 0 } },
    ], 'm1');
    assert.equal(req.model, 'm1');
    assert.equal(req.stream, false);
    assert.equal(req.messages[0].role, 'system');
    assert.deepEqual(req.messages[2].tool_calls, [{ function: { name: 'find_student', arguments: { query: 'x' } } }]);
    assert.deepEqual(req.messages[3], { role: 'tool', tool_name: 'find_student', content: '{"count":0}' });
  });

  it('parseOllamaResponse: text, tool_calls (arguments là chuỗi JSON cũng được), bỏ tool lạ, lỗi khi rỗng', () => {
    assert.deepEqual(parseOllamaResponse({ message: { content: ' chào ' } }), { type: 'text', text: 'chào' });
    const r = parseOllamaResponse({
      message: {
        content: '',
        tool_calls: [
          { function: { name: 'find_student', arguments: '{"query":"he1"}' } },
          { function: { name: 'rm_rf', arguments: {} } },
        ],
      },
    });
    assert.deepEqual(r, { type: 'tool_calls', calls: [{ name: 'find_student', args: { query: 'he1' } }] });
    assert.throws(() => parseOllamaResponse({ message: { content: '' } }), (e) => e.code === 'AI_UNAVAILABLE');
  });
});

describe('loadProviderConfig', () => {
  it('mặc định auto; đọc ai_config/provider; bỏ URL/chế độ sai; env làm mặc định; lỗi đọc -> mặc định', async () => {
    assert.deepEqual(await loadProviderConfig(db(), {}), { mode: 'auto', ollamaUrl: '', ollamaModel: 'qwen2.5:7b' });
    const c = await loadProviderConfig(db({ provider: 'ollama', ollamaUrl: 'https://x.trycloudflare.com/', ollamaModel: 'llama3.1:8b' }), {});
    assert.deepEqual(c, { mode: 'ollama', ollamaUrl: 'https://x.trycloudflare.com', ollamaModel: 'llama3.1:8b' });
    const bad = await loadProviderConfig(db({ provider: 'hack', ollamaUrl: 'javascript:alert(1)' }), {});
    assert.equal(bad.mode, 'auto');
    assert.equal(bad.ollamaUrl, '');
    const viaEnv = await loadProviderConfig(db(), { OLLAMA_BASE_URL: 'http://o:11434', AI_PROVIDER: 'gemini' });
    assert.equal(viaEnv.mode, 'gemini');
    assert.equal(viaEnv.ollamaUrl, 'http://o:11434');
    const broken = { doc: () => ({ get: async () => { throw new Error('boom'); } }) };
    assert.equal((await quiet(() => loadProviderConfig(broken, {}))).mode, 'auto');
  });
});

describe('runAiAssistant: chọn nguồn AI', () => {
  it('auto: Gemini ổn thì dùng Gemini, không đụng Ollama', async () => {
    const calls = [];
    const f = route({ gemini: geminiOk, ollama: () => ollamaText('x') }, calls);
    const r = await runAiAssistant(deps(db({ provider: 'auto', ollamaUrl: OLLAMA }), f), { uid: 'gv1', history: [user('a')] });
    assert.equal(r.provider, 'gemini');
    assert.equal(r.fallback, undefined);
    assert.ok(!calls.some((u) => u.startsWith(OLLAMA)));
  });

  it('auto: Gemini quá tải kéo dài -> tự chuyển Ollama, đánh dấu fallback', async () => {
    const f = route({ gemini: busy, ollama: () => ollamaText('từ ollama') });
    const r = await quiet(() => runAiAssistant(deps(db({ provider: 'auto', ollamaUrl: OLLAMA }), f), { uid: 'gv1', history: [user('a')] }));
    assert.deepEqual(r, { type: 'text', text: 'từ ollama', provider: 'ollama', fallback: true });
  });

  it('chế độ ollama: bỏ qua Gemini hoàn toàn (chuyển nhanh khi biết Gemini đang sập)', async () => {
    const calls = [];
    const f = route({ gemini: busy, ollama: () => ollamaText('ok') }, calls);
    const r = await runAiAssistant(deps(db({ provider: 'ollama', ollamaUrl: OLLAMA }), f), { uid: 'gv1', history: [user('a')] });
    assert.equal(r.provider, 'ollama');
    assert.equal(r.fallback, undefined);
    assert.deepEqual(calls, [`${OLLAMA}/api/chat`]);
  });

  it('chế độ gemini: không bao giờ sang Ollama dù có URL', async () => {
    const calls = [];
    const f = route({ gemini: busy, ollama: () => ollamaText('x') }, calls);
    await quiet(() => rejects(
      runAiAssistant(deps(db({ provider: 'gemini', ollamaUrl: OLLAMA }), f), { uid: 'gv1', history: [user('a')] }),
      'unavailable',
      'AI_UNAVAILABLE',
    ));
    assert.ok(!calls.some((u) => u.startsWith(OLLAMA)));
  });

  it('không có API key Gemini: dùng thẳng Ollama; không nguồn nào -> AI_NOT_CONFIGURED', async () => {
    const f = route({ gemini: busy, ollama: () => ollamaText('ok') });
    const r = await runAiAssistant({ db: db({ ollamaUrl: OLLAMA }), fetchImpl: f, env: {} }, { uid: 'gv1', history: [user('a')] });
    assert.equal(r.provider, 'ollama');
    await rejects(runAiAssistant({ db: db(), fetchImpl: f, env: {} }, { uid: 'gv1', history: [user('a')] }), 'failed-precondition', 'AI_NOT_CONFIGURED');
  });

  it('cả hai nguồn đều lỗi (kể cả Ollama mất kết nối) -> AI_UNAVAILABLE', async () => {
    const f = async (url) => {
      if (url.startsWith(OLLAMA)) throw new Error('ECONNREFUSED');
      return busy();
    };
    await quiet(() => rejects(
      runAiAssistant(deps(db({ ollamaUrl: OLLAMA }), f), { uid: 'gv1', history: [user('a')] }),
      'unavailable',
      'AI_UNAVAILABLE',
    ));
  });

  it('AI_BLOCKED (bộ lọc an toàn) không bị "chữa" bằng cách sang Ollama', async () => {
    const calls = [];
    const blocked = () => ({ ok: true, status: 200, json: async () => ({ promptFeedback: { blockReason: 'SAFETY' } }) });
    await rejects(
      runAiAssistant(deps(db({ ollamaUrl: OLLAMA }), route({ gemini: blocked, ollama: () => ollamaText('x') }, calls)), { uid: 'gv1', history: [user('a')] }),
      'failed-precondition',
      'AI_BLOCKED',
    );
    assert.ok(!calls.some((u) => u.startsWith(OLLAMA)));
  });
});
