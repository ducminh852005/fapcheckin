import assert from 'node:assert/strict';
import test from 'node:test';

import { isStudentProfile } from './profile.js';

test('accepts every student role supported by Firestore Rules', () => {
  for (const role of ['user', 'SV', 'student', ' sv ']) {
    assert.equal(isStudentProfile({ role, rollNumber: 'SE123456' }), true);
  }
});

test('rejects staff/admin roles and profiles without a student number', () => {
  for (const role of ['staff', 'GV', 'teacher', 'admin', '']) {
    assert.equal(isStudentProfile({ role, rollNumber: 'SE123456' }), false);
  }
  assert.equal(isStudentProfile({ role: 'user', rollNumber: '' }), false);
  assert.equal(isStudentProfile(null), false);
});
