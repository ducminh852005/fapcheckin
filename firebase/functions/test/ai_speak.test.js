import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { MAX_TEXT_LENGTH, RATE_LIMIT_MAX, SpeakError, cleanSpeechText, runSpeak } from '../src/ai_speak.js';
import { fakeDb } from './fakes.js';

const db = (extra = {}) => fakeDb({
  'users/gv1': { role: 'staff', active: true, memberCode: 'GV001' },
  'users/sv1': { role: 'user', active: true },
  'users/off': { role: 'staff', active: false },
  ...extra,
});

const okSynth = (calls = []) => async (request) => {
  calls.push(request);
  return [{ audioContent: Buffer.from('MP3-DATA') }];
};

async function rejects(promise, status, code) {
  await assert.rejects(promise, (e) => {
    assert.ok(e instanceof SpeakError, `SpeakError expected, got ${e}`);
    assert.equal(e.status, status);
    assert.equal(e.code, code);
    return true;
  });
}

const quiet = async (fn) => {
  const orig = console.error;
  console.error = () => {};
  try { return await fn(); } finally { console.error = orig; }
};

describe('cleanSpeechText', () => {
  it('bỏ markdown/emoji và gộp khoảng trắng', () => {
    assert.equal(cleanSpeechText('Có **3**  sinh viên 🚨\n\n`HE1`_x_'), 'Có 3 sinh viên HE1x');
    assert.equal(cleanSpeechText(null), '');
  });
});

describe('runSpeak', () => {
  it('chưa đăng nhập / sinh viên / tài khoản khoá -> từ chối, không gọi Cloud TTS', async () => {
    const calls = [];
    await rejects(runSpeak({ db: db(), synthesize: okSynth(calls) }, { text: 'a' }), 'unauthenticated', 'UNAUTHORIZED');
    for (const uid of ['sv1', 'off', 'ghost']) {
      await rejects(runSpeak({ db: db(), synthesize: okSynth(calls) }, { uid, text: 'a' }), 'permission-denied', 'FORBIDDEN');
    }
    assert.equal(calls.length, 0);
  });

  it('kiểm tra nội dung: rỗng, chỉ ký hiệu, quá dài', async () => {
    const calls = [];
    for (const text of ['', '   ', '**', '🚨', undefined]) {
      await rejects(runSpeak({ db: db(), synthesize: okSynth(calls) }, { uid: 'gv1', text }), 'invalid-argument', 'VALIDATION_ERROR');
    }
    await rejects(runSpeak({ db: db(), synthesize: okSynth(calls) }, { uid: 'gv1', text: 'a'.repeat(MAX_TEXT_LENGTH + 1) }), 'invalid-argument', 'VALIDATION_ERROR');
    assert.equal(calls.length, 0);
  });

  it('thành công: gọi đúng giọng vi-VN, MP3, trả base64', async () => {
    const calls = [];
    const r = await runSpeak({ db: db(), synthesize: okSynth(calls) }, { uid: 'gv1', text: 'Xin chào **thầy** cô' });
    assert.deepEqual(r, { audioBase64: Buffer.from('MP3-DATA').toString('base64'), mimeType: 'audio/mpeg', voice: 'vi-VN-Neural2-A' });
    assert.equal(calls[0].input.text, 'Xin chào thầy cô');
    assert.equal(calls[0].voice.languageCode, 'vi-VN');
    assert.equal(calls[0].audioConfig.audioEncoding, 'MP3');
  });

  it('đổi giọng bằng deps.voice (TTS_VOICE)', async () => {
    const calls = [];
    const r = await runSpeak({ db: db(), synthesize: okSynth(calls), voice: 'vi-VN-Wavenet-D' }, { uid: 'gv1', text: 'a' });
    assert.equal(r.voice, 'vi-VN-Wavenet-D');
    assert.equal(calls[0].voice.name, 'vi-VN-Wavenet-D');
  });

  it('audioContent dạng chuỗi base64 cũng được chấp nhận', async () => {
    const r = await runSpeak({ db: db(), synthesize: async () => [{ audioContent: 'QUJD' }] }, { uid: 'gv1', text: 'a' });
    assert.equal(r.audioBase64, 'QUJD');
  });

  it('Cloud TTS lỗi (API chưa bật/thiếu quyền) hoặc trả rỗng -> TTS_UNAVAILABLE để app dùng giọng của máy', async () => {
    const boom = async () => { throw Object.assign(new Error('7 PERMISSION_DENIED: API has not been used'), { code: 7 }); };
    await quiet(() => rejects(runSpeak({ db: db(), synthesize: boom }, { uid: 'gv1', text: 'a' }), 'unavailable', 'TTS_UNAVAILABLE'));
    await quiet(() => rejects(runSpeak({ db: db(), synthesize: async () => [{ audioContent: Buffer.alloc(0) }] }, { uid: 'gv1', text: 'a' }), 'unavailable', 'TTS_UNAVAILABLE'));
    await quiet(() => rejects(runSpeak({ db: db(), synthesize: async () => [{}] }, { uid: 'gv1', text: 'a' }), 'unavailable', 'TTS_UNAVAILABLE'));
  });

  it('giới hạn tần suất theo cửa sổ 10 phút; bộ đếm lỗi không làm hỏng giọng đọc', async () => {
    const t0 = new Date('2026-11-10T01:00:00Z');
    const limited = db({ 'ai_usage/gv1_tts': { windowStart: t0.getTime(), count: RATE_LIMIT_MAX } });
    await rejects(
      runSpeak({ db: limited, synthesize: okSynth(), now: () => new Date(t0.getTime() + 60_000) }, { uid: 'gv1', text: 'a' }),
      'resource-exhausted',
      'RATE_LIMITED',
    );
    const r = await runSpeak({ db: limited, synthesize: okSynth(), now: () => new Date(t0.getTime() + 11 * 60_000) }, { uid: 'gv1', text: 'a' });
    assert.ok(r.audioBase64);

    const broken = db();
    const realDoc = broken.doc;
    broken.doc = (path) => {
      const ref = realDoc(path);
      if (path.startsWith('ai_usage/')) ref.set = async () => { throw new Error('7 PERMISSION_DENIED'); };
      return ref;
    };
    const ok = await quiet(() => runSpeak({ db: broken, synthesize: okSynth() }, { uid: 'gv1', text: 'a' }));
    assert.ok(ok.audioBase64);
  });
});
