import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  AiError, MAX_HISTORY, MAX_TEXT_LENGTH, RATE_LIMIT_MAX, TOOL_DECLARATIONS,
  buildGeminiRequest, parseGeminiResponse, runAiAssistant, toGeminiContents, validateHistory, vnNow,
} from '../src/ai_assistant.js';
import { fakeDb } from './fakes.js';

const teacherDb = (extra = {}) => fakeDb({
  'users/gv1': { role: 'staff', active: true, memberCode: 'GV001' },
  'users/sv1': { role: 'user', active: true, memberCode: 'SE1001' },
  'users/off': { role: 'staff', active: false, memberCode: 'GV002' },
  ...extra,
});

const okFetch = (body, calls = []) => async (url, init) => {
  calls.push({ url, init });
  return { ok: true, json: async () => body };
};

const textBody = (text) => ({ candidates: [{ content: { parts: [{ text }] } }] });
const user = (text) => ({ role: 'user', text });

async function rejects(promise, status, code) {
  await assert.rejects(promise, (e) => {
    assert.ok(e instanceof AiError, `AiError expected, got ${e}`);
    assert.equal(e.status, status);
    assert.equal(e.code, code);
    return true;
  });
}

describe('validateHistory', () => {
  it('chấp nhận hội thoại hợp lệ có tool call + kết quả', () => {
    const clean = validateHistory([
      user('điểm danh HE1'),
      { role: 'model', toolCalls: [{ name: 'find_student', args: { query: 'HE1' } }] },
      { role: 'tool', name: 'find_student', result: { students: [] } },
    ]);
    assert.equal(clean.length, 3);
  });

  it('từ chối rỗng, quá dài, quá nhiều tin, tool lạ, vai trò lạ', () => {
    assert.throws(() => validateHistory([]), AiError);
    assert.throws(() => validateHistory('x'), AiError);
    assert.throws(() => validateHistory([user('a'.repeat(MAX_TEXT_LENGTH + 1))]), AiError);
    assert.throws(() => validateHistory(Array.from({ length: MAX_HISTORY + 1 }, () => user('a'))), AiError);
    assert.throws(() => validateHistory([user('a'), { role: 'model', toolCalls: [{ name: 'drop_db', args: {} }] }]), AiError);
    assert.throws(() => validateHistory([{ role: 'system', text: 'hi' }]), AiError);
    assert.throws(() => validateHistory([user('   ')]), AiError);
  });

  it('phải bắt đầu bằng user và kết thúc bằng user/tool', () => {
    assert.throws(() => validateHistory([{ role: 'model', text: 'hi' }]), AiError);
    assert.throws(() => validateHistory([user('a'), { role: 'model', text: 'b' }]), AiError);
  });

  it('từ chối kết quả tool quá lớn', () => {
    assert.throws(
      () => validateHistory([user('a'), { role: 'tool', name: 'list_my_classes', result: 'x'.repeat(30_000) }]),
      AiError,
    );
  });
});

describe('toGeminiContents / buildGeminiRequest', () => {
  it('map user, functionCall, functionResponse và gộp kết quả tool liên tiếp', () => {
    const contents = toGeminiContents([
      user('xin chào'),
      {
        role: 'model',
        toolCalls: [
          { name: 'list_my_classes', args: {}, thoughtSignature: 'sig' },
          { name: 'get_attendance_report', args: {} },
        ],
      },
      { role: 'tool', name: 'list_my_classes', result: { a: 1 } },
      { role: 'tool', name: 'get_attendance_report', result: { b: 2 } },
    ]);
    assert.equal(contents.length, 3);
    assert.equal(contents[1].parts[0].thoughtSignature, 'sig');
    assert.deepEqual(contents[1].parts[0].functionCall, { name: 'list_my_classes', args: {} });
    assert.equal(contents[2].role, 'user');
    assert.equal(contents[2].parts.length, 2);
    assert.deepEqual(contents[2].parts[1].functionResponse.response, { result: { b: 2 } });
  });

  it('request có system prompt (kèm ngày VN), tools và đủ 6 tool', () => {
    const req = buildGeminiRequest([user('hi')], new Date('2026-11-09T18:30:00Z'));
    assert.match(req.systemInstruction.parts[0].text, /2026-11-10/); // 18:30Z = 01:30 ngày hôm sau ở VN
    assert.equal(req.tools[0].functionDeclarations.length, TOOL_DECLARATIONS.length);
    assert.deepEqual(
      TOOL_DECLARATIONS.map((t) => t.name),
      ['list_my_classes', 'find_student', 'get_session_attendance', 'get_attendance_stats', 'get_attendance_report', 'mark_attendance'],
    );
  });

  it('vnNow tính theo UTC+7', () => {
    assert.deepEqual(vnNow(new Date('2026-11-09T18:30:00Z')), { date: '2026-11-10', weekday: 'Thứ ba', time: '01:30' });
  });
});

describe('parseGeminiResponse', () => {
  it('trả text', () => {
    assert.deepEqual(parseGeminiResponse(textBody('Chào thầy')), { type: 'text', text: 'Chào thầy' });
  });

  it('trả tool_calls, giữ thoughtSignature, bỏ tool lạ', () => {
    const r = parseGeminiResponse({
      candidates: [{
        content: {
          parts: [
            { functionCall: { name: 'find_student', args: { query: 'HE1' } }, thoughtSignature: 'sig' },
            { functionCall: { name: 'rm_rf', args: {} } },
          ],
        },
      }],
    });
    assert.equal(r.type, 'tool_calls');
    assert.deepEqual(r.calls, [{ name: 'find_student', args: { query: 'HE1' }, thoughtSignature: 'sig' }]);
  });

  it('lỗi khi rỗng / bị chặn', () => {
    assert.throws(() => parseGeminiResponse({}), (e) => e.code === 'AI_EMPTY');
    assert.throws(() => parseGeminiResponse({ promptFeedback: { blockReason: 'SAFETY' } }), (e) => e.code === 'AI_BLOCKED');
  });
});

describe('runAiAssistant', () => {
  it('chưa đăng nhập -> unauthenticated', async () => {
    await rejects(runAiAssistant({ db: teacherDb(), apiKey: 'k' }, { history: [user('a')] }), 'unauthenticated', 'UNAUTHORIZED');
  });

  it('sinh viên / tài khoản khoá / không có hồ sơ -> permission-denied', async () => {
    for (const uid of ['sv1', 'off', 'ghost']) {
      await rejects(runAiAssistant({ db: teacherDb(), apiKey: 'k' }, { uid, history: [user('a')] }), 'permission-denied', 'FORBIDDEN');
    }
  });

  it('GV hợp lệ: gọi Gemini đúng endpoint/header và trả text', async () => {
    const calls = [];
    const r = await runAiAssistant(
      { db: teacherDb(), apiKey: 'secret', apiBase: 'http://stub/v1beta', model: 'm1', fetchImpl: okFetch(textBody('ok'), calls) },
      { uid: 'gv1', history: [user('chào')] },
    );
    assert.deepEqual(r, { type: 'text', text: 'ok' });
    assert.equal(calls[0].url, 'http://stub/v1beta/models/m1:generateContent');
    assert.equal(calls[0].init.headers['x-goog-api-key'], 'secret');
    assert.equal(JSON.parse(calls[0].init.body).contents[0].parts[0].text, 'chào');
  });

  it('lỗi cấu hình khi thiếu API key (không gọi mạng)', async () => {
    let called = false;
    await rejects(
      runAiAssistant({ db: teacherDb(), fetchImpl: async () => { called = true; } }, { uid: 'gv1', history: [user('a')] }),
      'failed-precondition',
      'AI_NOT_CONFIGURED',
    );
    assert.equal(called, false);
  });

  it('Gemini lỗi 500 hoặc mất mạng -> AI_UNAVAILABLE', async () => {
    const down = { ok: false, status: 500, json: async () => ({}) };
    await rejects(
      runAiAssistant({ db: teacherDb(), apiKey: 'k', fetchImpl: async () => down }, { uid: 'gv1', history: [user('a')] }),
      'unavailable',
      'AI_UNAVAILABLE',
    );
    await rejects(
      runAiAssistant({ db: teacherDb(), apiKey: 'k', fetchImpl: async () => { throw new Error('ECONNRESET'); } }, { uid: 'gv1', history: [user('a')] }),
      'unavailable',
      'AI_UNAVAILABLE',
    );
  });

  it('giới hạn tần suất theo cửa sổ 10 phút', async () => {
    const t0 = new Date('2026-11-09T01:00:00Z');
    const db = teacherDb({ 'ai_usage/gv1': { windowStart: t0.getTime(), count: RATE_LIMIT_MAX } });
    const base = { db, apiKey: 'k', fetchImpl: okFetch(textBody('ok')) };
    await rejects(
      runAiAssistant({ ...base, now: () => new Date(t0.getTime() + 60_000) }, { uid: 'gv1', history: [user('a')] }),
      'resource-exhausted',
      'RATE_LIMITED',
    );
    // sang cửa sổ mới -> được phép và đếm lại từ 1
    const r = await runAiAssistant({ ...base, now: () => new Date(t0.getTime() + 11 * 60_000) }, { uid: 'gv1', history: [user('a')] });
    assert.equal(r.type, 'text');
    assert.equal(db.store.get('ai_usage/gv1').count, 1);
  });

  it('input sai không tốn lượt rate-limit', async () => {
    const db = teacherDb();
    await assert.rejects(runAiAssistant({ db, apiKey: 'k', fetchImpl: okFetch(textBody('ok')) }, { uid: 'gv1', history: [] }), AiError);
    assert.equal(db.store.has('ai_usage/gv1'), false);
  });
});
