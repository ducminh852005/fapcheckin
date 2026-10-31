// Đồng bộ điểm danh với hệ thống FAP Portal (`syncToFap`):
//  - Xác thực quyền giảng viên (staff) hoặc admin
//  - Tìm các bản ghi điểm danh chưa đồng bộ (`syncedToFap != true`) của giảng viên (lọc theo classCode / sessionId nếu có)
//  - Nếu có cấu hình endpoint FAP bên ngoài (`FAP_SYNC_URL`), đẩy payload qua HTTP POST;
//    sau đó đánh dấu `syncedToFap = true`, `syncedAt`, `updatedAt`, `updatedBy` trên Firestore.

export class FapSyncError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

/**
 * @param deps {db, serverTimestamp, fetchImpl?, fapUrl?, fapToken?}
 * @param input {uid, classCode?, sessionId?}
 */
export async function runFapSync(deps, { uid, classCode = '', sessionId = '' } = {}) {
  const { db, serverTimestamp, fetchImpl = globalThis.fetch, fapUrl = process.env.FAP_SYNC_URL, fapToken = process.env.FAP_SYNC_TOKEN } = deps;
  if (!uid) {
    throw new FapSyncError('unauthenticated', 'UNAUTHORIZED', 'Vui lòng đăng nhập lại.');
  }

  const userSnap = await db.doc(`users/${uid}`).get();
  const profile = userSnap.exists ? userSnap.data() : null;
  if (!profile || profile.active === false || !['staff', 'admin'].includes(profile.role)) {
    throw new FapSyncError('permission-denied', 'FORBIDDEN', 'Tài khoản không có quyền đồng bộ điểm danh FAP.');
  }

  const memberCode = String(profile.memberCode ?? '').trim();
  if (!memberCode && profile.role !== 'admin') {
    throw new FapSyncError('failed-precondition', 'VALIDATION_ERROR', 'Hồ sơ giảng viên thiếu memberCode.');
  }

  const cleanClass = String(classCode ?? '').trim();
  const cleanSession = String(sessionId ?? '').trim();

  if (cleanClass) {
    const classSnap = await db.doc(`classes/${cleanClass}`).get();
    if (!classSnap.exists) {
      throw new FapSyncError('not-found', 'NOT_FOUND', 'Không tìm thấy lớp học.');
    }
    if (profile.role !== 'admin' && classSnap.data()?.teacherMemberCode !== memberCode) {
      throw new FapSyncError('permission-denied', 'FORBIDDEN', 'Lớp không thuộc giảng viên đang đăng nhập.');
    }
  }

  let query = db.collection('attendance_records');
  if (profile.role !== 'admin') {
    query = query.where('teacherMemberCode', '==', memberCode);
  }
  if (cleanClass) {
    query = query.where('classCode', '==', cleanClass);
  }
  if (cleanSession) {
    query = query.where('sessionId', '==', cleanSession);
  }

  const snap = await query.get();
  const unsynced = snap.docs.filter((d) => d.data()?.syncedToFap !== true);

  if (unsynced.length === 0) {
    return {
      syncedCount: 0,
      message: 'Tất cả bản ghi điểm danh đã được đồng bộ với FAP.',
    };
  }

  if (!fapUrl || typeof fetchImpl !== 'function') {
    throw new FapSyncError(
      'failed-precondition',
      'FAP_NOT_CONFIGURED',
      'Máy chủ chưa được cấu hình cổng đồng bộ FAP.',
    );
  }

  {
    const records = unsynced.map((d) => {
      const data = d.data();
      return {
        recordId: d.id,
        sessionId: data.sessionId ?? '',
        classCode: data.classCode ?? '',
        rollNumber: data.rollNumber ?? '',
        status: data.status ?? '',
        note: data.note ?? '',
      };
    });
    const res = await fetchImpl(fapUrl, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        ...(fapToken ? { authorization: `Bearer ${fapToken}` } : {}),
      },
      body: JSON.stringify({ teacherMemberCode: memberCode, records }),
    });
    if (!res.ok) {
      throw new FapSyncError('unavailable', 'UPSTREAM_ERROR', `Cổng FAP phản hồi mã lỗi ${res.status}.`);
    }
  }

  await Promise.all(
    unsynced.map((d) =>
      d.ref.update({
        syncedToFap: true,
        updatedAt: serverTimestamp(),
        updatedBy: memberCode || uid,
      }),
    ),
  );

  return {
    syncedCount: unsynced.length,
    message: `Đã đồng bộ ${unsynced.length} bản ghi điểm danh lên hệ thống FAP.`,
  };
}

