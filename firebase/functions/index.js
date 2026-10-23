// Cloud Functions của FAP Check-in. Backend chủ yếu là Firestore + Security Rules;
// Functions chỉ có phần OCR thời khóa biểu (cần Cloud Vision, nên không làm được ở client).
import { randomUUID } from 'node:crypto';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import vision from '@google-cloud/vision';
import { runScan, ScanError } from './src/scan.js';

initializeApp();

let visionClient;

/**
 * Callable: GV tải ảnh lên Storage `timetable_scans/{uid}/...` rồi gọi hàm này với
 * { storagePath }. Trả { scanToken, entries[], detectedDates[] } như API cũ.
 */
export const scanTimetable = onCall(
  { region: 'asia-southeast1', memory: '512MiB', timeoutSeconds: 60, maxInstances: 5 },
  async (request) => {
    try {
      visionClient ??= new vision.ImageAnnotatorClient();
      return await runScan(
        { db: getFirestore(), bucket: getStorage().bucket(), vision: visionClient, newId: randomUUID },
        { uid: request.auth?.uid, storagePath: request.data?.storagePath },
      );
    } catch (error) {
      if (error instanceof ScanError) {
        throw new HttpsError(error.status, error.message, { code: error.code });
      }
      console.error('scanTimetable failed', error);
      throw new HttpsError('internal', 'Không thể quét thời khóa biểu lúc này.', { code: 'OCR_UNAVAILABLE' });
    }
  },
);
