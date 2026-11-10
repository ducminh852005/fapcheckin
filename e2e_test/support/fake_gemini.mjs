// Gemini giả cho e2e: HTTP server cục bộ nhận `POST /v1beta/models/<model>:generateContent`
// (đúng endpoint mà firebase/functions/src/ai_assistant.js gọi) và trả phản hồi theo kịch bản tất định.
// Cloud Function dùng GEMINI_API_BASE trỏ về server này, nên không cần API key thật hay mạng.
import http from 'node:http';

export async function startFakeGemini({ port = 0 } = {}) {
  const requests = []; // { url, headers, body } theo thứ tự nhận
  let responder = defaultResponder;

  const server = http.createServer((req, res) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => {
      let body = {};
      try {
        body = JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}');
      } catch {
        /* để body rỗng */
      }
      requests.push({ method: req.method, url: req.url, headers: req.headers, body });
      const out = responder(body, requests.length);
      res.writeHead(out.status ?? 200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(out.json ?? {}));
    });
  });
  await new Promise((resolve) => server.listen(port, '127.0.0.1', resolve));

  return {
    port: server.address().port,
    requests,
    setResponder: (fn) => { responder = fn ?? defaultResponder; },
    close: () => new Promise((resolve) => server.close(resolve)),
  };
}

export const textReply = (text) => ({ json: { candidates: [{ content: { role: 'model', parts: [{ text }] } }] } });

export const callReply = (name, args, thoughtSignature) => ({
  json: {
    candidates: [{
      content: {
        role: 'model',
        parts: [{ functionCall: { name, args }, ...(thoughtSignature ? { thoughtSignature } : {}) }],
      },
    }],
  },
});

/** Văn bản của lượt `user` gần nhất (bỏ qua functionResponse). */
export function lastUserText(body) {
  const contents = body?.contents ?? [];
  for (let i = contents.length - 1; i >= 0; i--) {
    const t = contents[i].parts?.find((p) => typeof p.text === 'string')?.text;
    if (contents[i].role === 'user' && t) return t;
  }
  return '';
}

/** Có functionResponse ở cuối hội thoại không (tức model đang được yêu cầu tóm tắt kết quả tool). */
export function endsWithToolResult(body) {
  const last = (body?.contents ?? []).at(-1);
  return Boolean(last?.parts?.some((p) => p.functionResponse));
}

function defaultResponder(body) {
  const text = lastUserText(body).toLowerCase();
  if (endsWithToolResult(body)) return textReply('Đã xử lý xong.');
  if (text.includes('fail500')) return { status: 500, json: { error: { message: 'boom' } } };
  if (text.includes('điểm danh')) {
    return callReply('mark_attendance', {
      classCode: 'PRN232_SE1917',
      students: [{ rollNumber: 'SE1001', status: 'ManualByGV' }],
    }, 'sig-1');
  }
  return textReply('Xin chào thầy/cô, em có thể giúp gì ạ?');
}
