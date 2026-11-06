const DATASET_ID = 'firebase_crashlytics';
const TABLE_IDS = ['com_example_fapcheckin_ANDROID', 'com_example_fapcheckin_ANDROID_REALTIME'];
const ALLOWED_DAYS = new Set([1, 7, 30, 90]);

export class CrashlyticsError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

async function requireAdmin(db, uid) {
  if (!uid) {
    throw new CrashlyticsError('unauthenticated', 'UNAUTHORIZED', 'Cần đăng nhập để xem Crashlytics.');
  }
  const user = await db.doc(`users/${uid}`).get();
  if (!user.exists || user.data()?.role !== 'admin' || user.data()?.active === false) {
    throw new CrashlyticsError(
      'permission-denied',
      'FORBIDDEN',
      'Chỉ quản trị viên đang hoạt động được xem Crashlytics.',
    );
  }
}

function quoteTable(projectId, tableId) {
  return `\`${projectId}.${DATASET_ID}.${tableId}\``;
}

function buildQuery(projectId, tableIds) {
  const sources = tableIds.map((tableId) => `SELECT * FROM ${quoteTable(projectId, tableId)}`).join('\nUNION ALL\n');
  return `
    WITH combined AS (
      ${sources}
    ), recent_fatal_events AS (
      SELECT * EXCEPT(row_number)
      FROM (
        SELECT
          *,
          ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY event_timestamp DESC) AS row_number
        FROM combined
        WHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL @days DAY)
          AND error_type = 'FATAL'
      )
      WHERE row_number = 1
    )
    SELECT
      issue_id AS issueId,
      COUNT(DISTINCT event_id) AS eventCount,
      COUNT(DISTINCT NULLIF(installation_uuid, '')) AS userCount,
      MIN(event_timestamp) AS firstSeen,
      MAX(event_timestamp) AS lastSeen,
      ARRAY_AGG(
        STRUCT(
          COALESCE(
            (SELECT exception.type FROM UNNEST(exceptions) AS exception WHERE exception.blamed LIMIT 1),
            (SELECT exception.type FROM UNNEST(exceptions) AS exception LIMIT 1),
            NULLIF(blame_frame.symbol, ''),
            'Fatal crash'
          ) AS title,
          COALESCE(
            (SELECT exception.exception_message FROM UNNEST(exceptions) AS exception WHERE exception.blamed LIMIT 1),
            (SELECT exception.exception_message FROM UNNEST(exceptions) AS exception LIMIT 1),
            NULLIF(blame_frame.file, ''),
            ''
          ) AS subtitle,
          application.display_version AS version
        )
        ORDER BY event_timestamp DESC
        LIMIT 1
      )[OFFSET(0)] AS latest,
      (SELECT COUNT(DISTINCT event_id) FROM recent_fatal_events) AS totalEvents,
      (SELECT COUNT(DISTINCT NULLIF(installation_uuid, '')) FROM recent_fatal_events) AS totalUsers,
      (SELECT COUNT(DISTINCT issue_id) FROM recent_fatal_events) AS totalIssues
    FROM recent_fatal_events
    WHERE issue_id IS NOT NULL AND issue_id != ''
    GROUP BY issue_id
    ORDER BY eventCount DESC, lastSeen DESC
    LIMIT 50
  `;
}

function numberValue(value) {
  if (typeof value === 'number') return value;
  if (value && typeof value === 'object' && 'value' in value) return Number(value.value) || 0;
  return Number(value) || 0;
}

function isoValue(value) {
  if (!value) return null;
  const raw = typeof value === 'object' && 'value' in value ? value.value : value;
  const date = raw instanceof Date ? raw : new Date(raw);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

/** Returns fatal Crashlytics events exported to BigQuery for the Android app. */
export async function loadCrashlyticsDashboard(deps, { uid, days = 7 }) {
  await requireAdmin(deps.db, uid);
  if (!ALLOWED_DAYS.has(days)) {
    throw new CrashlyticsError('invalid-argument', 'INVALID_DAYS', 'Khoảng thời gian không hợp lệ.');
  }

  let tables;
  try {
    [tables] = await deps.bigquery.dataset(DATASET_ID).getTables();
  } catch (error) {
    if (error?.code === 404) {
      throw new CrashlyticsError(
        'failed-precondition',
        'EXPORT_NOT_CONFIGURED',
        'Chưa tìm thấy dữ liệu Crashlytics trong BigQuery. Hãy bật liên kết Crashlytics → BigQuery.',
      );
    }
    throw error;
  }

  const existingIds = new Set(tables.map((table) => table.id));
  const selectedIds = TABLE_IDS.filter((id) => existingIds.has(id));
  if (selectedIds.length === 0) {
    throw new CrashlyticsError(
      'failed-precondition',
      'EXPORT_NOT_READY',
      'BigQuery chưa có bảng Crashlytics của com.example.fapcheckin. Hãy bật export và chờ lần đồng bộ đầu tiên.',
    );
  }

  const [rows] = await deps.bigquery.query({
    query: buildQuery(deps.projectId, selectedIds),
    params: { days },
    types: { days: 'INT64' },
  });
  const issues = rows.map((row) => ({
    id: String(row.issueId),
    title: String(row.latest?.title || 'Fatal crash'),
    subtitle: String(row.latest?.subtitle || ''),
    version: String(row.latest?.version || '—'),
    eventCount: numberValue(row.eventCount),
    userCount: numberValue(row.userCount),
    firstSeen: isoValue(row.firstSeen),
    lastSeen: isoValue(row.lastSeen),
  }));
  const first = rows[0];
  return {
    days,
    source: selectedIds.some((id) => id.endsWith('_REALTIME')) ? 'bigquery-realtime' : 'bigquery-daily',
    updatedAt: new Date().toISOString(),
    totals: {
      events: first ? numberValue(first.totalEvents) : 0,
      users: first ? numberValue(first.totalUsers) : 0,
      issues: first ? numberValue(first.totalIssues) : 0,
    },
    issues,
  };
}

