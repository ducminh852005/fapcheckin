import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Readable } from 'node:stream';
import { parseText, matchEntries } from '../src/timetable.js';
import { runScan, ScanError, MAX_FILE_BYTES } from '../src/scan.js';

const classes = () => [
  { classCode: 'PRN232_SE1917', teacherMemberCode: '' },
  { classCode: 'SWD392_SE1927', teacherMemberCode: 'OTHER' },
  { classCode: 'PRM393_SE1922', teacherMemberCode: 'T1' },
];

test('parses class-subject pairs, rooms and timetable dates from noisy OCR', () => {
  const parsed = parseText(`WEEK 07/09 To 13/09
    SE1917-PRN232 at NVH
    602 (Not yet)
    SE1927–SWD392 at NVH 611
    SE1917-PRN232 at NVH 602`);
  assert.deepEqual(parsed.entries, [
    { key: 'SE1917|PRN232', classCode: 'SE1917', subjectCode: 'PRN232', room: '602' },
    { key: 'SE1927|SWD392', classCode: 'SE1927', subjectCode: 'SWD392', room: '611' },
  ]);
  assert.deepEqual(parsed.detectedDates, ['07/09', '13/09']);
});

test('parses pairs when OCR drops the location label or inserts spaces', () => {
  const parsed = parseText('SE 1917 - PRN 232\nSE1927_PRM393\nSE1917 PRN232');
  assert.deepEqual(parsed.entries, [
    { key: 'SE1917|PRN232', classCode: 'SE1917', subjectCode: 'PRN232', room: '' },
    { key: 'SE1927|PRM393', classCode: 'SE1927', subjectCode: 'PRM393', room: '' },
  ]);
});

test('matches available, conflicting and already assigned classes', () => {
  const parsed = parseText('SE1917-PRN232 at NVH 602\nSE1927-SWD392 at NVH 611\nSE1922-PRM393 at NVH 604');
  const entries = matchEntries(parsed, classes(), 'T1');
  assert.deepEqual(entries.map((e) => e.status), ['available', 'conflict', 'alreadyAssigned']);
  assert.equal(entries[0].matchedClassCode, 'PRN232_SE1917');
  assert.equal(entries[1].matchedClassCode, 'SWD392_SE1927');
});

test('reports notFound and ambiguous matches', () => {
  const dup = [...classes(), { classCode: 'PRN232_SE1917', teacherMemberCode: '' }];
  const parsed = parseText('SE1917-PRN232\nSE9999-ABC123');
  const entries = matchEntries(parsed, dup, 'T1');
  assert.deepEqual(entries.map((e) => e.status), ['ambiguous', 'notFound']);
});

test('matches every class restored from the ten-entry timetable', () => {
  const rows = [
    'PRN232_SE1917', 'PRM393_SE1913', 'PRM393_SE1917', 'SWD392_SE1927', 'PRN232_SE1920',
    'PRM393_SE1922', 'PRN232_SE1919', 'PRM393_SE1920', 'PRM393_SE1928', 'PRM393_SE1919',
  ].map((classCode) => ({ classCode, teacherMemberCode: '' }));
  const parsed = parseText([
    'SE1917-PRN232', 'SE1913-PRM393', 'SE1917-PRM393', 'SE1927-SWD392',
    'SE1920-PRN232', 'SE1922-PRM393', 'SE1919-PRN232', 'SE1920-PRM393',
    'SE1928-PRM393', 'SE1919-PRM393',
  ].join('\n'));
  const entries = matchEntries(parsed, rows, 'T1');
  assert.equal(entries.length, 10);
  assert.ok(entries.every((e) => e.status === 'available'));
});

// ---------------------------------------------------------------- runScan
function fakeDeps({ role = 'staff', contentType = 'image/png', size = 1000, ocrText = 'SE1917-PRN232 at NVH 602', visionError } = {}) {
  const deleted = [];
  const db = {
    doc: (path) => ({
      get: async () => (path === 'users/u1'
        ? { exists: true, data: () => ({ role, memberCode: 'T1', active: true }) }
        : { exists: false }),
    }),
    collection: (name) => ({
      get: async () => ({ docs: name === 'classes' ? classes().map((c) => ({ data: () => c })) : [] }),
    }),
  };
  const bucket = {
    file: (path) => ({
      getMetadata: async () => [{ contentType, size, generation: '123' }],
      createReadStream: () => Readable.from([Buffer.from('img')]),
      delete: async () => { deleted.push(path); },
    }),
  };
  const vision = {
    documentTextDetection: async () => {
      if (visionError) throw new Error(visionError);
      return [{ fullTextAnnotation: { text: ocrText } }];
    },
  };
  return { deps: { db, bucket, vision, newId: () => 'scan-1' }, deleted };
}
const ok = { uid: 'u1', storagePath: 'timetable_scans/u1/a.png' };

test('runScan returns matched entries and deletes the temp image', async () => {
  const { deps, deleted } = fakeDeps();
  const result = await runScan(deps, ok);
  assert.equal(result.scanToken, 'scan-1');
  assert.equal(result.entries[0].status, 'available');
  assert.deepEqual(deleted, [ok.storagePath]);
});

test('runScan rejects non-staff, foreign paths, bad images', async () => {
  await assert.rejects(runScan(fakeDeps({ role: 'user' }).deps, ok), { code: 'FORBIDDEN' });
  await assert.rejects(runScan(fakeDeps().deps, { ...ok, uid: undefined }), { code: 'UNAUTHORIZED' });
  await assert.rejects(runScan(fakeDeps().deps, { ...ok, storagePath: 'timetable_scans/other/a.png' }), { code: 'INVALID_IMAGE' });
  await assert.rejects(runScan(fakeDeps({ contentType: 'application/pdf' }).deps, ok), { code: 'INVALID_IMAGE' });
  await assert.rejects(runScan(fakeDeps({ size: 11 * 1024 * 1024 }).deps, ok), { code: 'IMAGE_TOO_LARGE' });
});

test('runScan maps OCR failures to business error codes', async () => {
  await assert.rejects(runScan(fakeDeps({ ocrText: '   ' }).deps, ok), { code: 'OCR_EMPTY' });
  await assert.rejects(runScan(fakeDeps({ ocrText: 'không có mã lớp' }).deps, ok), { code: 'NO_TIMETABLE_ENTRIES' });
  await assert.rejects(runScan(fakeDeps({ visionError: 'Quota exceeded' }).deps, ok), { code: 'OCR_BUSY' });
  await assert.rejects(runScan(fakeDeps({ visionError: 'Cloud Vision API has not been used' }).deps, ok), { code: 'OCR_NOT_CONFIGURED' });
  await assert.rejects(runScan(fakeDeps({ visionError: 'boom' }).deps, ok), (e) => e instanceof ScanError && e.code === 'OCR_UNAVAILABLE');
});

test('CR-03: rejects malformed size metadata and oversized downloaded image before OCR', async () => {
 for (const size of ['invalid', null, -1, 0, Infinity, true, 1.5, ' ']) {
  await assert.rejects(runScan(fakeDeps({size}).deps, ok), {code:'IMAGE_TOO_LARGE'});
 }
 const {deps,deleted}=fakeDeps(); let ocrCalled=false;
 deps.bucket.file=()=>({getMetadata:async()=>[{contentType:'image/png',size:100,generation:'123'}], createReadStream:()=>Readable.from([Buffer.alloc(MAX_FILE_BYTES+1)]),delete:async()=>deleted.push(ok.storagePath)});
 deps.vision.documentTextDetection=async()=>{ocrCalled=true;return [];};
 await assert.rejects(runScan(deps,ok),{code:'IMAGE_TOO_LARGE'});
 assert.equal(ocrCalled,false); assert.deepEqual(deleted,[ok.storagePath]);
});

test('CR-03: stops an oversized stream early and never calls OCR', async () => {
  const { deps, deleted } = fakeDeps();
  let produced = 0;
  const stream = Readable.from((function* () {
    for (let i = 0; i < 100; i++) {
      produced++;
      yield Buffer.alloc(1024 * 1024);
    }
  })(), { highWaterMark: 1 });
  const file = deps.bucket.file(ok.storagePath);
  deps.bucket.file = () => ({ ...file, createReadStream: () => stream });
  deps.vision.documentTextDetection = async () => assert.fail('must not call OCR');
  await assert.rejects(runScan(deps, ok), { code: 'IMAGE_TOO_LARGE' });
  assert.equal(stream.destroyed, true);
  assert.ok(produced <= 12, 'at most one chunk is prefetched beyond the overflow');
  assert.deepEqual(deleted, [ok.storagePath]);
});

test('CR-03: accepts exactly 10 MB and rejects empty or failed streams', async () => {
  for (const scenario of ['limit', 'empty', 'error']) {
    const { deps, deleted } = fakeDeps({ size: MAX_FILE_BYTES });
    const file = deps.bucket.file(ok.storagePath);
    const failure = new Error('storage connection failed');
    const stream = scenario === 'error'
      ? Readable.from((async function* () { yield Buffer.from('partial'); throw failure; })())
      : Readable.from(scenario === 'empty' ? [] : [Buffer.alloc(MAX_FILE_BYTES)]);
    deps.bucket.file = () => ({ ...file, createReadStream: () => stream });
    if (scenario === 'limit') {
      const detect = deps.vision.documentTextDetection;
      deps.vision.documentTextDetection = async ({ image }) => {
        assert.equal(image.content.length, MAX_FILE_BYTES);
        return detect();
      };
      await runScan(deps, ok);
    } else {
      deps.vision.documentTextDetection = async () => assert.fail('must not call OCR');
      await assert.rejects(runScan(deps, ok), scenario === 'empty' ? { code: 'INVALID_IMAGE' } : failure);
    }
    assert.equal(stream.destroyed, true);
    assert.deepEqual(deleted, [ok.storagePath]);
  }
});

test('CR-03: reads and deletes only the inspected generation when the image is replaced', async () => {
  const { deps } = fakeDeps();
  const versions = new Map([['123', Buffer.from('original')], ['124', Buffer.from('replacement')]]);
  deps.bucket.file = (_path, options = {}) => ({
    getMetadata: async () => [{ contentType: 'image/png', size: 8, generation: '123' }],
    createReadStream: () => {
      assert.equal(options.generation, '123');
      return Readable.from([versions.get(options.generation)]);
    },
    delete: async () => {
      assert.equal(options.generation, '123');
      versions.delete(options.generation);
    },
  });
  const detect = deps.vision.documentTextDetection;
  deps.vision.documentTextDetection = async ({ image }) => {
    assert.equal(image.content.toString(), 'original');
    return detect();
  };
  await runScan(deps, ok);
  assert.equal(versions.has('123'), false);
  assert.equal(versions.get('124').toString(), 'replacement');
});

test('CR-03: fails closed when metadata has no usable generation', async () => {
  for (const generation of [undefined, '', 'invalid', '0', '9007199254740993']) {
    const { deps } = fakeDeps();
    deps.bucket.file = () => ({
      getMetadata: async () => [{ contentType: 'image/png', size: 100, generation }],
      createReadStream: () => assert.fail('must not read an unpinned image'),
      delete: async () => assert.fail('must not delete an unpinned image'),
    });
    await assert.rejects(runScan(deps, ok), { code: 'INVALID_IMAGE' });
  }
});
