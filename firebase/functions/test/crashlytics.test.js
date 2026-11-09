import test from 'node:test';
import assert from 'node:assert/strict';
import { fakeDb } from './fakes.js';
import { CrashlyticsError, loadCrashlyticsDashboard } from '../src/crashlytics.js';

function fakeBigQuery(tableIds, rows = []) {
  const calls = [];
  return {
    calls,
    dataset: (id) => ({
      getTables: async () => {
        calls.push({ dataset: id });
        return [tableIds.map((tableId) => ({ id: tableId }))];
      },
    }),
    query: async (options) => {
      calls.push(options);
      return [rows];
    },
  };
}

test('returns Crashlytics aggregates for an active admin', async () => {
  const db = fakeDb({ 'users/admin-1': { role: 'admin', active: true } });
  const bigquery = fakeBigQuery(
    ['com_example_fapcheckin_ANDROID', 'com_example_fapcheckin_ANDROID_REALTIME'],
    [{
      issueId: 'issue-1', eventCount: 47, userCount: 1, totalEvents: 52, totalUsers: 4, totalIssues: 3,
      firstSeen: { value: '2026-11-05T01:00:00Z' }, lastSeen: { value: '2026-11-06T01:00:00Z' },
      latest: { title: 'FlutterError', subtitle: 'ListTile background color', version: '1.0.0' },
    }],
  );

  const result = await loadCrashlyticsDashboard(
    { db, bigquery, projectId: 'ducminh-41459' },
    { uid: 'admin-1', days: 7 },
  );

  assert.deepEqual(result.totals, { events: 52, users: 4, issues: 3 });
  assert.equal(result.issues[0].eventCount, 47);
  assert.equal(result.source, 'bigquery-realtime');
  assert.match(bigquery.calls[1].query, /ROW_NUMBER\(\) OVER \(PARTITION BY event_id/);
  assert.deepEqual(bigquery.calls[1].params, { days: 7 });
});

test('rejects non-admin users before querying BigQuery', async () => {
  const db = fakeDb({ 'users/user-1': { role: 'user', active: true } });
  const bigquery = fakeBigQuery([]);
  await assert.rejects(
    loadCrashlyticsDashboard({ db, bigquery, projectId: 'demo' }, { uid: 'user-1', days: 7 }),
    (error) => error instanceof CrashlyticsError && error.code === 'FORBIDDEN',
  );
  assert.equal(bigquery.calls.length, 0);
});

test('returns a setup error when the Crashlytics table is missing', async () => {
  const db = fakeDb({ 'users/admin-1': { role: 'admin', active: true } });
  const bigquery = fakeBigQuery([]);
  await assert.rejects(
    loadCrashlyticsDashboard({ db, bigquery, projectId: 'demo' }, { uid: 'admin-1', days: 7 }),
    (error) => error instanceof CrashlyticsError && error.code === 'EXPORT_NOT_READY',
  );
});
