// Giọng đọc cho Trợ lý AI (`aiSpeak`): Google Cloud Text-to-Speech, giọng tiếng Việt (vi-VN Neural2/Wavenet).
//  - Chỉ GV (staff/admin đang hoạt động) được gọi; giới hạn độ dài chữ và tần suất.
//  - Trả âm thanh MP3 dạng base64 để app phát; app có giọng của máy làm dự phòng khi hàm lỗi.
//  - Xác thực với Google Cloud bằng tài khoản dịch vụ của hàm (ADC) — KHÔNG cần API key; chỉ cần bật
//    "Cloud Text-to-Speech API" cho project.

export const MAX_TEXT_LENGTH = 600;
export const RATE_LIMIT_MAX = 120;
export const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000;
export const DEFAULT_VOICE = 'vi-VN-Neural2-A';
export const LANGUAGE_CODE = 'vi-VN';

export class SpeakError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

/** Bỏ ký hiệu markdown/emoji còn sót để giọng đọc không đọc "sao sao". */
export function cleanSpeechText(text) {
  return String(text ?? '')
    .replace(/\*\*/g, '')
    .replace(/[`#_]/g, '')
    .replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/gu, '')
    .replace(/\s+/g, ' ')
    .trim();
}

async function checkRateLimit(db, uid, nowMs) {
  const ref = db.doc(`ai_usage/${uid}_tts`);
  const snap = await ref.get();
  const cur = snap.exists ? snap.data() : null;
  const inWindow = cur && nowMs - cur.windowStart < RATE_LIMIT_WINDOW_MS;
  const count = inWindow ? cur.count : 0;
  if (count >= RATE_LIMIT_MAX) {
    throw new SpeakError('resource-exhausted', 'RATE_LIMITED', 'Đọc to quá nhiều lần, vui lòng thử lại sau ít phút.');
  }
  await ref.set({ windowStart: inWindow ? cur.windowStart : nowMs, count: count + 1 });
}

/**
 * @param deps {db, synthesize: (request) => Promise<[{audioContent}]>, voice?, now?: () => Date}
 * @param input {uid, text}
 * @returns {audioBase64, mimeType:'audio/mpeg', voice}
 */
export async function runSpeak(deps, { uid, text } = {}) {
  const { db, synthesize, voice = process.env.TTS_VOICE || DEFAULT_VOICE, now = () => new Date() } = deps;

  if (!uid) throw new SpeakError('unauthenticated', 'UNAUTHORIZED', 'Vui lòng đăng nhập lại.');
  const snap = await db.doc(`users/${uid}`).get();
  const profile = snap.exists ? snap.data() : null;
  if (!profile || profile.active === false || !['staff', 'admin'].includes(profile.role)) {
    throw new SpeakError('permission-denied', 'FORBIDDEN', 'Chỉ giảng viên mới dùng được giọng đọc.');
  }

  const clean = cleanSpeechText(text);
  if (!clean) throw new SpeakError('invalid-argument', 'VALIDATION_ERROR', 'Thiếu nội dung cần đọc.');
  if (clean.length > MAX_TEXT_LENGTH) {
    throw new SpeakError('invalid-argument', 'VALIDATION_ERROR', `Nội dung đọc quá dài (tối đa ${MAX_TEXT_LENGTH} ký tự).`);
  }

  try {
    await checkRateLimit(db, uid, now().getTime());
  } catch (error) {
    if (error instanceof SpeakError) throw error;
    // Bộ đếm lỗi (vd. thiếu quyền ghi Firestore) không được làm hỏng giọng đọc.
    console.error('aiSpeak: rate-limit unavailable', error);
  }

  let response;
  try {
    [response] = await synthesize({
      input: { text: clean },
      voice: { languageCode: LANGUAGE_CODE, name: voice },
      audioConfig: { audioEncoding: 'MP3', speakingRate: 1.0, pitch: 0 },
    });
  } catch (error) {
    // Thường gặp: API chưa bật, tài khoản dịch vụ thiếu quyền, hết hạn mức, tên giọng sai.
    console.error('aiSpeak: Cloud Text-to-Speech lỗi', error?.code ?? '', String(error?.message ?? error).slice(0, 400));
    throw new SpeakError('unavailable', 'TTS_UNAVAILABLE', 'Giọng đọc đám mây chưa dùng được, đang dùng giọng của máy.');
  }
  const audio = response?.audioContent;
  if (!audio || audio.length === 0) {
    throw new SpeakError('unavailable', 'TTS_UNAVAILABLE', 'Giọng đọc đám mây trả về dữ liệu rỗng.');
  }
  const audioBase64 = typeof audio === 'string' ? audio : Buffer.from(audio).toString('base64');
  return { audioBase64, mimeType: 'audio/mpeg', voice };
}
