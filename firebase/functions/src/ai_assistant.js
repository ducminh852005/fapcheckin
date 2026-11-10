// Trợ lý AI cho giảng viên (`aiAssistant`): proxy mỏng tới Gemini (function-calling).
//  - Xác thực GV (role staff), giới hạn kích thước + tần suất gọi.
//  - KHÔNG chạm dữ liệu điểm danh: model chỉ "đề xuất" tool call; app thực thi tool bằng repository
//    với quyền của chính GV (Security Rules vẫn là lớp bảo vệ thật). Tool ghi cần GV xác nhận ở app.
//  - Stateless: client gửi lại toàn bộ history mỗi lượt.
//
// Định dạng history (client <-> function):
//   { role: 'user',  text }
//   { role: 'model', text?, toolCalls?: [{ name, args, thoughtSignature? }] }
//   { role: 'tool',  name, result }                  // kết quả một tool call
// Trả về: { type: 'text', text } | { type: 'tool_calls', calls: [{ name, args, thoughtSignature? }], text? }

export const MAX_HISTORY = 30;
export const MAX_TEXT_LENGTH = 1000;
export const MAX_TOOL_RESULT_CHARS = 24_000;
export const RATE_LIMIT_MAX = 60;
export const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000;
export const GEMINI_TIMEOUT_MS = 40_000;
export const OLLAMA_TIMEOUT_MS = 80_000;
export const DEFAULT_OLLAMA_MODEL = 'qwen2.5:7b';
/** Nguồn AI: auto = Gemini trước, lỗi/quá tải thì sang Ollama (nếu có URL); gemini | ollama = chỉ dùng một nguồn. */
export const PROVIDER_MODES = ['auto', 'gemini', 'ollama'];
export const CONFIG_DOC = 'ai_config/provider';
export const DEFAULT_MODEL = 'gemini-3.5-flash';
/** Dự phòng khi model chính vẫn quá tải/hỏng sau các lần thử lại. */
export const DEFAULT_FALLBACK_MODEL = 'gemini-flash-lite-latest';
/** Gemini báo bận/quá tải tạm thời -> thử lại vài lần với khoảng chờ tăng dần. */
export const RETRY_STATUSES = [429, 500, 502, 503, 504];
export const MAX_ATTEMPTS = 3;
const RETRY_DELAYS_MS = [700, 1500];
export const DEFAULT_API_BASE = 'https://generativelanguage.googleapis.com/v1beta';

/** Trạng thái điểm danh mà app/Security Rules chấp nhận. */
export const ATTENDANCE_STATUSES = ['Present', 'Late', 'Absent', 'ManualByGV', 'Unchecked'];

export class AiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const str = (description) => ({ type: 'STRING', description });

/** Khai báo tool gửi cho Gemini. Tên phải khớp `AiToolExecutor` ở app. */
export const TOOL_DECLARATIONS = [
  {
    name: 'list_my_classes',
    description:
      'Liệt kê các lớp giảng viên đang phụ trách (mã lớp, môn, slot, giờ học, sĩ số, phiên đang mở nếu có). ' +
      'Gọi trước khi điểm danh nếu chưa chắc mã lớp / slot.',
    parameters: { type: 'OBJECT', properties: {} },
  },
  {
    name: 'find_student',
    description:
      'Tra sinh viên theo MSSV hoặc theo tên (gần đúng, không dấu cũng được) trong các lớp của giảng viên. ' +
      'Trả về MSSV, họ tên, lớp. Dùng để xác minh MSSV người dùng nói trước khi điểm danh.',
    parameters: {
      type: 'OBJECT',
      properties: {
        query: str('MSSV hoặc một phần họ tên sinh viên'),
        classCode: str('Mã lớp để giới hạn tìm kiếm (không bắt buộc)'),
      },
      required: ['query'],
    },
  },
  {
    name: 'get_session_attendance',
    description:
      'Xem trạng thái điểm danh từng sinh viên của một buổi học (mặc định buổi hôm nay hoặc buổi gần nhất của lớp).',
    parameters: {
      type: 'OBJECT',
      properties: {
        classCode: str('Mã lớp'),
        date: str('Ngày buổi học, định dạng yyyy-MM-dd (không bắt buộc)'),
        slotCode: str('Mã slot (không bắt buộc)'),
      },
      required: ['classCode'],
    },
  },
  {
    name: 'get_attendance_stats',
    description: 'Tỷ lệ chuyên cần (%) của từng sinh viên trong một lớp, qua tất cả các buổi đã diễn ra.',
    parameters: {
      type: 'OBJECT',
      properties: { classCode: str('Mã lớp') },
      required: ['classCode'],
    },
  },
  {
    name: 'get_attendance_report',
    description:
      'Báo cáo chuyên cần tổng hợp: tỷ lệ có mặt/vắng, theo môn, theo tuần và danh sách sinh viên có nguy cơ (vắng nhiều).',
    parameters: {
      type: 'OBJECT',
      properties: {
        from: str('Từ ngày yyyy-MM-dd (không bắt buộc)'),
        to: str('Đến ngày yyyy-MM-dd (không bắt buộc)'),
      },
    },
  },
  {
    name: 'mark_attendance',
    description:
      'Điểm danh tay cho một hoặc nhiều sinh viên của buổi học HÔM NAY (phiên phải đang mở). ' +
      'App sẽ hiện thẻ xác nhận cho giảng viên trước khi ghi — không cần tự hỏi xác nhận lần nữa. ' +
      'Chỉ gọi khi đã biết chắc mã lớp và MSSV (dùng find_student nếu chưa chắc).',
    parameters: {
      type: 'OBJECT',
      properties: {
        classCode: str('Mã lớp'),
        slotCode: str('Mã slot của buổi học (không bắt buộc nếu lớp chỉ có một buổi hôm nay)'),
        students: {
          type: 'ARRAY',
          description: 'Danh sách sinh viên cần điểm danh',
          items: {
            type: 'OBJECT',
            properties: {
              rollNumber: str('MSSV'),
              status: {
                type: 'STRING',
                description: 'Có mặt = ManualByGV, đi muộn = Late, vắng = Absent, bỏ trạng thái = Unchecked',
                enum: ATTENDANCE_STATUSES,
              },
            },
            required: ['rollNumber', 'status'],
          },
        },
        note: str('Ghi chú (không bắt buộc)'),
      },
      required: ['classCode', 'students'],
    },
  },
];

export const TOOL_NAMES = new Set(TOOL_DECLARATIONS.map((t) => t.name));

const WEEKDAYS = ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy'];

/** Ngày giờ hiện tại theo giờ Việt Nam (UTC+7). */
export function vnNow(now = new Date()) {
  const vn = new Date(now.getTime() + 7 * 3600_000);
  const date = vn.toISOString().slice(0, 10);
  return { date, weekday: WEEKDAYS[vn.getUTCDay()], time: vn.toISOString().slice(11, 16) };
}

export function systemPrompt(now = new Date()) {
  const { date, weekday, time } = vnNow(now);
  return [
    'Bạn là trợ lý AI trong ứng dụng FAP Check-in dành cho GIẢNG VIÊN. Luôn trả lời bằng tiếng Việt, ngắn gọn, lịch sự.',
    `Hôm nay là ${weekday}, ${date}, ${time} (giờ Việt Nam).`,
    'Bạn làm được: (1) điểm danh tay cho sinh viên, (2) tra cứu thông tin lớp/sinh viên/buổi học, (3) thống kê và báo cáo chuyên cần.',
    'Quy tắc:',
    '- Chỉ dùng dữ liệu lấy được từ các tool; KHÔNG bịa số liệu, MSSV, họ tên hay mã lớp.',
    '- Tin nhắn có thể đến từ nhận dạng giọng nói nên MSSV/tên có thể sai chính tả: hãy xác minh bằng find_student trước khi điểm danh; nếu có nhiều kết quả hoặc không khớp, hỏi lại giảng viên.',
    '- Thiếu thông tin cần thiết (lớp, slot, MSSV, trạng thái) hoặc còn mơ hồ → hỏi lại, không đoán. Nếu giảng viên chỉ nói số như "slot 3", đối chiếu bằng list_my_classes.',
    '- Điểm danh chỉ áp dụng cho buổi học hôm nay có phiên đang mở. Không thể mở/đóng phiên: nếu chưa có phiên, hướng dẫn giảng viên mở ở mục Quản lý lớp.',
    '- Khi gọi mark_attendance, app sẽ tự hiện thẻ xác nhận; sau khi nhận kết quả, tóm tắt lại những gì đã ghi (hoặc lý do thất bại).',
    '- Câu trả lời cuối luôn MỞ ĐẦU bằng 1–2 câu tóm tắt ngắn có thể đọc thành lời (không gạch đầu dòng, không ký hiệu, không emoji); nếu có nhiều số liệu thì xuống một dòng trống rồi mới liệt kê chi tiết đầy đủ. Ứng dụng sẽ đọc to phần tóm tắt và hiển thị đủ phần chi tiết.',
    '- Khi báo cáo, nêu số liệu chính (tỷ lệ %, số lượt, sinh viên cần lưu ý) dạng ngắn gọn, có thể dùng gạch đầu dòng.',
    '- Từ chối lịch sự các yêu cầu ngoài phạm vi (không liên quan điểm danh/lớp học).',
  ].join('\n');
}

const isPlainObject = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);

/** Kiểm tra + chuẩn hoá history. Ném AiError(invalid-argument) nếu sai. */
export function validateHistory(history) {
  const bad = (msg) => new AiError('invalid-argument', 'VALIDATION_ERROR', msg);
  if (!Array.isArray(history) || history.length === 0) throw bad('Thiếu nội dung hội thoại.');
  if (history.length > MAX_HISTORY) throw bad(`Hội thoại quá dài (tối đa ${MAX_HISTORY} tin).`);
  const clean = [];
  for (const m of history) {
    if (!isPlainObject(m)) throw bad('Tin nhắn không hợp lệ.');
    if (m.role === 'user') {
      const text = typeof m.text === 'string' ? m.text.trim() : '';
      if (!text) throw bad('Tin nhắn trống.');
      if (text.length > MAX_TEXT_LENGTH) throw bad(`Tin nhắn quá dài (tối đa ${MAX_TEXT_LENGTH} ký tự).`);
      clean.push({ role: 'user', text });
    } else if (m.role === 'model') {
      const text = typeof m.text === 'string' ? m.text : '';
      const toolCalls = [];
      for (const c of Array.isArray(m.toolCalls) ? m.toolCalls : []) {
        if (!isPlainObject(c) || !TOOL_NAMES.has(c.name)) throw bad('Tool không hợp lệ.');
        toolCalls.push({
          name: c.name,
          args: isPlainObject(c.args) ? c.args : {},
          ...(typeof c.thoughtSignature === 'string' ? { thoughtSignature: c.thoughtSignature } : {}),
        });
      }
      if (!text && toolCalls.length === 0) throw bad('Tin nhắn model trống.');
      clean.push({ role: 'model', text: text.slice(0, 8000), toolCalls });
    } else if (m.role === 'tool') {
      if (!TOOL_NAMES.has(m.name)) throw bad('Tool không hợp lệ.');
      let serialized;
      try {
        serialized = JSON.stringify(m.result ?? null);
      } catch {
        throw bad('Kết quả tool không hợp lệ.');
      }
      if (serialized.length > MAX_TOOL_RESULT_CHARS) throw bad('Kết quả tool quá lớn.');
      clean.push({ role: 'tool', name: m.name, result: m.result ?? null });
    } else {
      throw bad('Vai trò tin nhắn không hợp lệ.');
    }
  }
  if (clean[0].role !== 'user') throw bad('Hội thoại phải bắt đầu bằng tin nhắn của giảng viên.');
  const last = clean[clean.length - 1];
  if (last.role === 'model') throw bad('Tin nhắn cuối phải từ giảng viên hoặc kết quả tool.');
  return clean;
}

/** history đã chuẩn hoá -> `contents` của Gemini. Các kết quả tool liên tiếp gộp thành một lượt. */
export function toGeminiContents(history) {
  const contents = [];
  for (const m of history) {
    if (m.role === 'user') {
      contents.push({ role: 'user', parts: [{ text: m.text }] });
    } else if (m.role === 'model') {
      const parts = [];
      if (m.text) parts.push({ text: m.text });
      for (const c of m.toolCalls ?? []) {
        parts.push({
          functionCall: { name: c.name, args: c.args },
          ...(c.thoughtSignature ? { thoughtSignature: c.thoughtSignature } : {}),
        });
      }
      contents.push({ role: 'model', parts });
    } else {
      const part = { functionResponse: { name: m.name, response: { result: m.result } } };
      const prev = contents[contents.length - 1];
      if (prev && prev.role === 'user' && prev.parts.every((p) => p.functionResponse)) prev.parts.push(part);
      else contents.push({ role: 'user', parts: [part] });
    }
  }
  return contents;
}

export function buildGeminiRequest(history, now = new Date()) {
  return {
    systemInstruction: { parts: [{ text: systemPrompt(now) }] },
    contents: toGeminiContents(history),
    tools: [{ functionDeclarations: TOOL_DECLARATIONS }],
    toolConfig: { functionCallingConfig: { mode: 'AUTO' } },
    generationConfig: { temperature: 0.2, maxOutputTokens: 1024 },
  };
}

/** Phản hồi Gemini -> { type:'text'|'tool_calls', ... }. */
export function parseGeminiResponse(body) {
  const candidate = body?.candidates?.[0];
  const parts = candidate?.content?.parts;
  if (!Array.isArray(parts) || parts.length === 0) {
    const blocked = body?.promptFeedback?.blockReason;
    throw new AiError(
      'failed-precondition',
      blocked ? 'AI_BLOCKED' : 'AI_EMPTY',
      blocked ? 'Yêu cầu bị từ chối bởi bộ lọc an toàn.' : 'AI chưa trả lời được, vui lòng thử lại.',
    );
  }
  const text = parts.filter((p) => typeof p.text === 'string' && !p.thought).map((p) => p.text).join('').trim();
  const calls = parts
    .filter((p) => p.functionCall && TOOL_NAMES.has(p.functionCall.name))
    .map((p) => ({
      name: p.functionCall.name,
      args: isPlainObject(p.functionCall.args) ? p.functionCall.args : {},
      ...(typeof p.thoughtSignature === 'string' ? { thoughtSignature: p.thoughtSignature } : {}),
    }));
  if (calls.length > 0) return { type: 'tool_calls', calls, ...(text ? { text } : {}) };
  if (!text) throw new AiError('failed-precondition', 'AI_EMPTY', 'AI chưa trả lời được, vui lòng thử lại.');
  return { type: 'text', text };
}

async function checkRateLimit(db, uid, nowMs) {
  const ref = db.doc(`ai_usage/${uid}`);
  const snap = await ref.get();
  const cur = snap.exists ? snap.data() : null;
  const inWindow = cur && nowMs - cur.windowStart < RATE_LIMIT_WINDOW_MS;
  const count = inWindow ? cur.count : 0;
  if (count >= RATE_LIMIT_MAX) {
    throw new AiError('resource-exhausted', 'RATE_LIMITED', 'Bạn gọi trợ lý AI quá nhiều, vui lòng thử lại sau ít phút.');
  }
  await ref.set({ windowStart: inWindow ? cur.windowStart : nowMs, count: count + 1 });
}

/** Gọi generateContent, tự thử lại khi bận (429/5xx) hoặc mất kết nối. Trả response cuối (hoặc null nếu không kết nối được). */
async function callGemini({ fetchImpl, sleep, apiBase, apiKey, model, request }) {
  let response = null;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    try {
      response = await fetchImpl(`${apiBase}/models/${encodeURIComponent(model)}:generateContent`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
        body: JSON.stringify(request),
        signal: AbortSignal.timeout(GEMINI_TIMEOUT_MS),
      });
    } catch (error) {
      console.error('aiAssistant: không kết nối được Gemini', error?.message ?? error);
      response = null;
    }
    const retryable = !response || RETRY_STATUSES.includes(response.status);
    if (response?.ok || !retryable || attempt === MAX_ATTEMPTS) break;
    await sleep(RETRY_DELAYS_MS[attempt - 1] ?? 1500);
  }
  return response;
}

// ── Ollama (dự phòng khi Gemini quá tải; chạy trong container ở máy demo, lộ ra qua tunnel) ─────────

const lowerTypes = (schema) => {
  if (Array.isArray(schema)) return schema.map(lowerTypes);
  if (!isPlainObject(schema)) return schema;
  return Object.fromEntries(
    Object.entries(schema).map(([k, v]) => [k, k === 'type' && typeof v === 'string' ? v.toLowerCase() : lowerTypes(v)]),
  );
};

/** Khai báo tool dạng OpenAI/Ollama (`type` viết thường). */
export const OLLAMA_TOOLS = TOOL_DECLARATIONS.map((t) => ({
  type: 'function',
  function: { name: t.name, description: t.description, parameters: lowerTypes(t.parameters) },
}));

/** history đã chuẩn hoá -> `messages` của Ollama `/api/chat`. */
export function toOllamaMessages(history, now = new Date()) {
  const messages = [{ role: 'system', content: systemPrompt(now) }];
  for (const m of history) {
    if (m.role === 'user') messages.push({ role: 'user', content: m.text });
    else if (m.role === 'model') {
      messages.push({
        role: 'assistant',
        content: m.text ?? '',
        ...(m.toolCalls?.length
          ? { tool_calls: m.toolCalls.map((c) => ({ function: { name: c.name, arguments: c.args } })) }
          : {}),
      });
    } else messages.push({ role: 'tool', tool_name: m.name, content: JSON.stringify(m.result ?? null) });
  }
  return messages;
}

export function buildOllamaRequest(history, model, now = new Date()) {
  return { model, messages: toOllamaMessages(history, now), tools: OLLAMA_TOOLS, stream: false, options: { temperature: 0.2 } };
}

/** Phản hồi Ollama -> { type:'text'|'tool_calls', ... } (cùng định dạng với Gemini). */
export function parseOllamaResponse(body) {
  const message = body?.message;
  const text = typeof message?.content === 'string' ? message.content.trim() : '';
  const calls = (Array.isArray(message?.tool_calls) ? message.tool_calls : [])
    .map((c) => c?.function)
    .filter((f) => f && TOOL_NAMES.has(f.name))
    .map((f) => {
      let args = f.arguments;
      if (typeof args === 'string') {
        try { args = JSON.parse(args); } catch { args = {}; }
      }
      return { name: f.name, args: isPlainObject(args) ? args : {} };
    });
  if (calls.length > 0) return { type: 'tool_calls', calls, ...(text ? { text } : {}) };
  if (!text) throw new AiError('unavailable', 'AI_UNAVAILABLE', 'AI chưa trả lời được, vui lòng thử lại.');
  return { type: 'text', text };
}

const cleanUrl = (u) => (typeof u === 'string' && /^https?:\/\//.test(u.trim()) ? u.trim().replace(/\/+$/, '') : '');

/** Đọc cấu hình nguồn AI từ `ai_config/provider` (chỉ Admin SDK đọc/ghi) + biến môi trường. Lỗi đọc -> mặc định. */
export async function loadProviderConfig(db, env = process.env) {
  let doc = {};
  try {
    const snap = await db.doc(CONFIG_DOC).get();
    if (snap.exists) doc = snap.data() ?? {};
  } catch (error) {
    console.error('aiAssistant: không đọc được ai_config/provider', error?.message ?? error);
  }
  const mode = PROVIDER_MODES.includes(doc.provider) ? doc.provider : PROVIDER_MODES.includes(env.AI_PROVIDER) ? env.AI_PROVIDER : 'auto';
  return {
    mode,
    ollamaUrl: cleanUrl(doc.ollamaUrl) || cleanUrl(env.OLLAMA_BASE_URL),
    ollamaModel: (typeof doc.ollamaModel === 'string' && doc.ollamaModel.trim()) || env.OLLAMA_MODEL || DEFAULT_OLLAMA_MODEL,
  };
}

async function viaOllama({ fetchImpl, url, model, history, now }) {
  let response;
  try {
    response = await fetchImpl(`${url}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(buildOllamaRequest(history, model, now)),
      signal: AbortSignal.timeout(OLLAMA_TIMEOUT_MS),
    });
  } catch (error) {
    console.error('aiAssistant: không kết nối được Ollama', error?.message ?? error);
    throw new AiError('unavailable', 'AI_UNAVAILABLE', 'Không kết nối được trợ lý AI dự phòng.');
  }
  if (!response.ok) {
    const detail = await response.text?.().catch(() => '') ?? '';
    console.error(`aiAssistant: Ollama trả HTTP ${response.status} (model ${model})`, String(detail).slice(0, 300));
    throw new AiError('unavailable', 'AI_UNAVAILABLE', 'Trợ lý AI dự phòng đang bận, vui lòng thử lại sau.');
  }
  let body;
  try {
    body = await response.json();
  } catch {
    throw new AiError('unavailable', 'AI_UNAVAILABLE', 'Trợ lý AI dự phòng trả về dữ liệu không hợp lệ.');
  }
  return parseOllamaResponse(body);
}

async function viaGemini({ fetchImpl, sleep, apiBase, apiKey, model, fallbackModel, history, now }) {
  let response = null;
  let usedModel = model;
  const models = fallbackModel && fallbackModel !== model ? [model, fallbackModel] : [model];
  for (const candidate of models) {
    usedModel = candidate;
    response = await callGemini({ fetchImpl, sleep, apiBase, apiKey, model: candidate, request: buildGeminiRequest(history, now) });
    if (response?.ok) break;
    console.error(`aiAssistant: model ${candidate} không dùng được (${response ? `HTTP ${response.status}` : 'mất kết nối'})`);
  }
  if (!response) {
    throw new AiError('unavailable', 'AI_UNAVAILABLE', 'Không kết nối được trợ lý AI, vui lòng thử lại.');
  }
  if (!response.ok) {
    // Ghi mã + phần đầu nội dung lỗi (không chứa key) để chẩn đoán: key sai, hết quota, model không tồn tại...
    const detail = await response.text?.().catch(() => '') ?? '';
    console.error(`aiAssistant: Gemini trả HTTP ${response.status} (model ${usedModel})`, String(detail).slice(0, 500));
    throw new AiError('unavailable', 'AI_UNAVAILABLE', 'Trợ lý AI đang bận, vui lòng thử lại sau.');
  }
  let body;
  try {
    body = await response.json();
  } catch {
    throw new AiError('unavailable', 'AI_UNAVAILABLE', 'Trợ lý AI trả về dữ liệu không hợp lệ.');
  }
  return parseGeminiResponse(body);
}

/** Lỗi nên chuyển sang nguồn dự phòng (không phải lỗi người dùng/quyền). */
const isFallbackWorthy = (e) => e instanceof AiError && (e.code === 'AI_UNAVAILABLE' || e.code === 'AI_EMPTY');

/**
 * @param deps {db, apiKey, fetchImpl?, model?, fallbackModel?, apiBase?, now?, sleep?, env?}
 * @param input {uid, history}
 * @returns {type, text|calls, provider:'gemini'|'ollama', fallback?:true}
 */
export async function runAiAssistant(deps, { uid, history } = {}) {
  const {
    db,
    apiKey,
    fetchImpl = globalThis.fetch,
    model = process.env.GEMINI_MODEL || DEFAULT_MODEL,
    fallbackModel = process.env.GEMINI_FALLBACK_MODEL || DEFAULT_FALLBACK_MODEL,
    apiBase = process.env.GEMINI_API_BASE || DEFAULT_API_BASE,
    now = () => new Date(),
    sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms)),
    env = process.env,
  } = deps;

  if (!uid) throw new AiError('unauthenticated', 'UNAUTHORIZED', 'Vui lòng đăng nhập lại.');
  const userSnap = await db.doc(`users/${uid}`).get();
  const profile = userSnap.exists ? userSnap.data() : null;
  if (!profile || profile.active === false || !['staff', 'admin'].includes(profile.role)) {
    throw new AiError('permission-denied', 'FORBIDDEN', 'Chỉ giảng viên mới dùng được trợ lý AI.');
  }

  const clean = validateHistory(history);
  const cfg = await loadProviderConfig(db, env);

  // Thứ tự thử các nguồn. Thiếu cấu hình của một nguồn thì bỏ qua nguồn đó.
  const order = [];
  if (cfg.mode !== 'ollama' && apiKey) order.push('gemini');
  if (cfg.mode !== 'gemini' && cfg.ollamaUrl) order.push('ollama');
  if (order.length === 0) throw new AiError('failed-precondition', 'AI_NOT_CONFIGURED', 'Trợ lý AI chưa được cấu hình.');

  try {
    await checkRateLimit(db, uid, now().getTime());
  } catch (error) {
    if (error instanceof AiError) throw error;
    // Bộ đếm lỗi (vd. tài khoản chạy hàm thiếu quyền ghi Firestore) không được làm hỏng cả tính năng:
    // vẫn đã xác thực + kiểm quyền GV ở trên, chỉ mất lớp giới hạn tần suất cho tới khi sửa quyền.
    console.error('aiAssistant: rate-limit unavailable', error);
  }

  let lastError;
  for (const provider of order) {
    try {
      const result = provider === 'gemini'
        ? await viaGemini({ fetchImpl, sleep, apiBase, apiKey, model, fallbackModel, history: clean, now: now() })
        : await viaOllama({ fetchImpl, url: cfg.ollamaUrl, model: cfg.ollamaModel, history: clean, now: now() });
      return { ...result, provider, ...(provider !== order[0] ? { fallback: true } : {}) };
    } catch (error) {
      if (!isFallbackWorthy(error)) throw error;
      lastError = error;
      if (provider !== order.at(-1)) console.error(`aiAssistant: ${provider} lỗi, chuyển sang nguồn dự phòng`);
    }
  }
  throw lastError;
}
