import { describe, it, before, after, beforeEach } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { ACCOUNTS, createEnv, seed } from './helpers.mjs';

let env;
before(async () => { env = await createEnv(); });
after(async () => { await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await seed(env);
});

const storageOf = (key) => {
  const a = ACCOUNTS[key];
  return env.authenticatedContext(a.uid, { email: a.email, email_verified: true }).storage();
};
const png = new Uint8Array([137, 80, 78, 71]);
const image = { contentType: 'image/png' };

describe('storage: timetable_scans', () => {
  it('GV tải ảnh lên thư mục của chính mình', async () => {
    await assertSucceeds(uploadBytes(ref(storageOf('t1'), 'timetable_scans/u-t1/a.png'), png, image));
  });
  it('GV không ghi vào thư mục của người khác', async () => {
    await assertFails(uploadBytes(ref(storageOf('t1'), 'timetable_scans/u-t2/a.png'), png, image));
  });
  it('SV không tải ảnh lên', async () => {
    await assertFails(uploadBytes(ref(storageOf('s1'), 'timetable_scans/u-s1/a.png'), png, image));
  });
  it('từ chối file không phải ảnh', async () => {
    await assertFails(uploadBytes(ref(storageOf('t1'), 'timetable_scans/u-t1/a.pdf'), png, { contentType: 'application/pdf' }));
  });
  it('chủ file và admin đọc được; GV khác thì không', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), 'timetable_scans/u-t1/b.png'), png, image);
    });
    await assertSucceeds(getBytes(ref(storageOf('t1'), 'timetable_scans/u-t1/b.png')));
    await assertSucceeds(getBytes(ref(storageOf('admin'), 'timetable_scans/u-t1/b.png')));
    await assertFails(getBytes(ref(storageOf('t2'), 'timetable_scans/u-t1/b.png')));
  });
  it('không sửa/xóa từ client', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), 'timetable_scans/u-t1/c.png'), png, image);
    });
    await assertFails(deleteObject(ref(storageOf('t1'), 'timetable_scans/u-t1/c.png')));
    await assertFails(uploadBytes(ref(storageOf('t1'), 'timetable_scans/u-t1/c.png'), png, image));
  });
  it('deny by default: đường dẫn khác bị chặn kể cả admin', async () => {
    await assertFails(uploadBytes(ref(storageOf('admin'), 'misc/file.png'), png, image));
    await assertFails(getBytes(ref(storageOf('admin'), 'misc/file.png')));
  });
});
