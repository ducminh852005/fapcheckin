// Kiểm tra dữ liệu đầu vào của script vận hành (không cần emulator).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateSupport } from '../scripts/seed-support.mjs';
import { validateWorkInfo } from '../scripts/set-work-info.mjs';

test('validateSupport: cần hotline hoặc email hợp lệ, không có giá trị mặc định', () => {
  assert.throws(() => validateSupport({}), /--phone hoặc --email/);
  assert.throws(() => validateSupport({ phone: 'abc' }), /hotline/);
  assert.throws(() => validateSupport({ email: 'not-an-email' }), /Email/);
  assert.deepEqual(validateSupport({ phone: ' (028) 7300 5588 ', email: 'hotro@fpt.edu.vn', emulator: true }),
    { phone: '(028) 7300 5588', email: 'hotro@fpt.edu.vn' });
});

test('validateWorkInfo: chỉ nhận trường công tác, ngày YYYY-MM-DD', () => {
  assert.throws(() => validateWorkInfo({ email: 'a@b.c' }), /ít nhất một trường/);
  assert.throws(() => validateWorkInfo({ employmentDate: '2020-02-30' }), /YYYY-MM-DD/);
  assert.throws(() => validateWorkInfo({ department: 'x'.repeat(201) }), /quá dài/);
  assert.deepEqual(
    validateWorkInfo({ email: 'gv@fpt.edu.vn', department: ' SE ', employmentDate: '2020-09-01', role: 'admin' }),
    { department: 'SE', employmentDate: '2020-09-01' },
  );
});
