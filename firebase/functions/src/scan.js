// Luồng quét thời khóa biểu: kiểm tra quyền -> OCR ảnh trong Storage -> phân tích -> đối chiếu lớp.
// Phụ thuộc (Firestore, Storage, Vision) được tiêm vào để test không cần Firebase thật.
import { matchEntries, parseText } from './timetable.js';

export const MAX_FILE_BYTES = 10 * 1024 * 1024;
const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/gif', 'image/bmp'];

/** Lỗi nghiệp vụ; `index.js` đổi thành HttpsError với `details.code` cho app. */
export class ScanError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status; // mã HttpsError: invalid-argument, permission-denied, ...
    this.code = code; // mã nghiệp vụ giữ nguyên như API cũ
  }
}

function ocrFailure(error) {
  const message = String(error?.message ?? error ?? '');
  if (/quota|rate.?limit|too many|resource.?exhausted/i.test(message)) {
    return new ScanError('resource-exhausted', 'OCR_BUSY',
      'Dịch vụ nhận dạng đang quá tải hoặc đã đạt giới hạn tạm thời. Vui lòng thử lại sau ít phút.');
  }
  if (/permission|not enabled|has not been used|disabled|billing/i.test(message)) {
    return new ScanError('failed-precondition', 'OCR_NOT_CONFIGURED',
      'Dịch vụ quét thời khóa biểu chưa được bật (Cloud Vision API / gói Blaze). Quản trị viên cần cấu hình rồi thử lại.');
  }
  return new ScanError('unavailable', 'OCR_UNAVAILABLE',
    'Dịch vụ OCR chưa xử lý được ảnh lúc này. Vui lòng thử lại; nếu lỗi tiếp diễn, liên hệ quản trị viên.');
}

/**
 * @param deps {db, bucket, vision, newId}
 *   db     : Firestore Admin
 *   bucket : Storage bucket Admin
 *   vision : { documentTextDetection({image:{content}}) -> [{fullTextAnnotation:{text}}] }
 */
export async function runScan(deps, { uid, storagePath }) {
  const { db, bucket, vision, newId } = deps;
  if (!uid) throw new ScanError('unauthenticated', 'UNAUTHORIZED', 'Cần đăng nhập.');

  const profileSnap = await db.doc(`users/${uid}`).get();
  const profile = profileSnap.exists ? profileSnap.data() : null;
  if (!profile || profile.role !== 'staff' || profile.active === false) {
    throw new ScanError('permission-denied', 'FORBIDDEN', 'Tài khoản không có quyền giảng viên.');
  }

  // Chỉ đọc ảnh nằm trong thư mục riêng của chính người gọi (khớp storage.rules).
  const prefix = `timetable_scans/${uid}/`;
  if (typeof storagePath !== 'string' || !storagePath.startsWith(prefix) || storagePath.includes('..')) {
    throw new ScanError('invalid-argument', 'INVALID_IMAGE', 'Đường dẫn ảnh không hợp lệ.');
  }

  const file = bucket.file(storagePath);
  try {
    const [meta] = await file.getMetadata();
    if (!ALLOWED_MIME.includes(String(meta.contentType).toLowerCase())) {
      throw new ScanError('invalid-argument', 'INVALID_IMAGE', 'Chỉ hỗ trợ ảnh JPG, PNG, GIF hoặc BMP.');
    }
    if (Number(meta.size) > MAX_FILE_BYTES) {
      throw new ScanError('invalid-argument', 'IMAGE_TOO_LARGE', 'Ảnh vượt quá 10 MB. Vui lòng cắt gọn hoặc nén ảnh rồi thử lại.');
    }
    const [bytes] = await file.download();
    if (!bytes?.length) throw new ScanError('invalid-argument', 'INVALID_IMAGE', 'Ảnh thời khóa biểu đang trống.');

    let extracted = '';
    try {
      const [result] = await vision.documentTextDetection({ image: { content: bytes } });
      extracted = String(result?.fullTextAnnotation?.text ?? '').trim();
    } catch (error) {
      throw ocrFailure(error);
    }
    if (!extracted) {
      throw new ScanError('not-found', 'OCR_EMPTY',
        'OCR không tìm thấy chữ trong ảnh. Hãy bảo đảm ảnh có đầy đủ bảng thời khóa biểu và thử lại.');
    }

    const parsed = parseText(extracted);
    const classes = (await db.collection('classes').get()).docs.map((d) => d.data());
    const entries = matchEntries(parsed, classes, profile.memberCode);
    if (entries.length === 0) {
      throw new ScanError('not-found', 'NO_TIMETABLE_ENTRIES',
        'Không nhận ra cặp mã lớp–môn (ví dụ SE1917-PRN232). Hãy dùng ảnh thời khóa biểu dành cho giáo viên.');
    }
    return { scanToken: newId(), entries, detectedDates: parsed.detectedDates };
  } finally {
    // Ảnh chỉ là dữ liệu tạm cho OCR.
    await file.delete({ ignoreNotFound: true }).catch(() => {});
  }
}
