// Ollama giả cho e2e: nhận `POST /api/chat` (đúng endpoint mà aiAssistant gọi) và `GET /api/tags`.
import http from 'node:http';

export async function startFakeOllama({ port = 0 } = {}) {
  const requests = [];
  let responder = defaultResponder;

  const server = http.createServer((req, res) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => {
      let body = {};
      try {
        body = JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}');
      } catch {
        /* body rỗng */
      }
      requests.push({ method: req.method, url: req.url, body });
      if (req.url === '/api/tags') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ models: [{ name: 'qwen2.5:7b' }] }));
        return;
      }
      const out = responder(body);
      res.writeHead(out.status ?? 200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(out.json ?? {}));
    });
  });
  await new Promise((resolve) => server.listen(port, '127.0.0.1', resolve));

  return {
    port: server.address().port,
    url: `http://127.0.0.1:${server.address().port}`,
    requests,
    setResponder: (fn) => { responder = fn ?? defaultResponder; },
    close: () => new Promise((resolve) => server.close(resolve)),
  };
}

export const ollamaText = (content) => ({ json: { model: 'qwen2.5:7b', message: { role: 'assistant', content }, done: true } });

export const ollamaCall = (name, args) => ({
  json: { model: 'qwen2.5:7b', message: { role: 'assistant', content: '', tool_calls: [{ function: { name, arguments: args } }] }, done: true },
});

function defaultResponder(body) {
  const last = body?.messages?.at(-1);
  if (last?.role === 'tool') return ollamaText('Đã xử lý xong (Ollama).');
  if (String(last?.content ?? '').toLowerCase().includes('điểm danh')) {
    return ollamaCall('mark_attendance', {
      classCode: 'PRN232_SE1917',
      students: [{ rollNumber: 'SE1001', status: 'ManualByGV' }],
    });
  }
  return ollamaText('Xin chào, em là trợ lý dự phòng chạy local ạ.');
}
