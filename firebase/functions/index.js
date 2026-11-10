// Cloud Functions của FAP Check-in. Backend chủ yếu là Firestore + Security Rules;
// Functions chỉ làm phần client không làm được: OCR thời khóa biểu (Cloud Vision),
// nhắc lịch dạy theo lịch hẹn (Cloud Scheduler + FCM) và xử lý góp ý (thông báo admin/người gửi).
import { randomUUID } from 'node:crypto';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';
import vision from '@google-cloud/vision';
import { BigQuery } from '@google-cloud/bigquery';
import { runScan, ScanError } from './src/scan.js';
import { runReminders } from './src/reminders.js';
import {
  FeedbackError, notifyAdminsOfFeedback, notifyAuthorOfResolution, resolveFeedback as resolveFeedbackImpl,
} from './src/feedback.js';
import { FapSyncError, runFapSync } from './src/fap_sync.js';
import { AiError, runAiAssistant } from './src/ai_assistant.js';
import { SpeakError, runSpeak } from './src/ai_speak.js';
import { TextToSpeechClient } from '@google-cloud/text-to-speech';
import { CrashlyticsError, loadCrashlyticsDashboard } from './src/crashlytics.js';

initializeApp();

const REGION = 'asia-southeast1';
let visionClient;
let bigQueryClient;

/** Phụ thuộc chung cho thông báo; emulator không có FCM thật nên bỏ push. */
function notifyDeps() {
  return {
    db: getFirestore(),
    messaging: process.env.FUNCTIONS_EMULATOR === 'true' ? null : getMessaging(),
    serverTimestamp: () => FieldValue.serverTimestamp(),
    toTimestamp: (date) => Timestamp.fromDate(date),
    log: (...args) => console.error(...args),
  };
}

/**
 * Callable: GV tải ảnh lên Storage `timetable_scans/{uid}/...` rồi gọi hàm này với
 * { storagePath }. Trả { scanToken, entries[], detectedDates[] } như API cũ.
 */
export const scanTimetable = onCall(
  { region: REGION, memory: '512MiB', timeoutSeconds: 60, maxInstances: 5 },
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

/** Mỗi 5 phút: nhắc GV đã bật `reminders` về buổi dạy bắt đầu trong 15 phút tới. */
export const sendTeachingReminders = onSchedule(
  { region: REGION, schedule: 'every 5 minutes', timeZone: 'Asia/Ho_Chi_Minh', timeoutSeconds: 120, maxInstances: 1 },
  async () => {
    const summary = await runReminders(notifyDeps(), { now: new Date() });
    console.log('sendTeachingReminders', JSON.stringify(summary));
  },
);

/** Góp ý mới -> thông báo cho admin. */
export const onFeedbackCreated = onDocumentCreated(
  { region: REGION, document: 'feedback/{feedbackId}' },
  async (event) => {
    if (!event.data) return;
    await notifyAdminsOfFeedback(notifyDeps(), { id: event.params.feedbackId, data: event.data.data() });
  },
);

/** Admin đóng góp ý -> thông báo cho người gửi. */
export const onFeedbackUpdated = onDocumentUpdated(
  { region: REGION, document: 'feedback/{feedbackId}' },
  async (event) => {
    if (!event.data) return;
    await notifyAuthorOfResolution(notifyDeps(), {
      id: event.params.feedbackId, before: event.data.before.data(), after: event.data.after.data(),
    });
  },
);

/** Callable cho admin: { feedbackId, reply, status? } -> trả lời và đóng góp ý. */
export const resolveFeedback = onCall({ region: REGION, maxInstances: 5 }, async (request) => {
  try {
    return await resolveFeedbackImpl(notifyDeps(), {
      uid: request.auth?.uid,
      feedbackId: request.data?.feedbackId,
      reply: request.data?.reply ?? '',
      status: request.data?.status ?? 'resolved',
    });
  } catch (error) {
    if (error instanceof FeedbackError) {
      throw new HttpsError(error.status, error.message, { code: error.code });
    }
    console.error('resolveFeedback failed', error);
    throw new HttpsError('internal', 'Không thể xử lý góp ý lúc này.', { code: 'INTERNAL' });
  }
});

/** Callable cho giảng viên/admin: đồng bộ điểm danh chưa đẩy lên FAP ({ classCode?, sessionId? }). */
export const syncToFap = onCall({ region: REGION, maxInstances: 5 }, async (request) => {
  try {
    return await runFapSync(notifyDeps(), {
      uid: request.auth?.uid,
      classCode: request.data?.classCode ?? '',
      sessionId: request.data?.sessionId ?? '',
    });
  } catch (error) {
    if (error instanceof FapSyncError) {
      throw new HttpsError(error.status, error.message, { code: error.code });
    }
    console.error('syncToFap failed', error);
    throw new HttpsError('internal', 'Không thể đồng bộ FAP lúc này.', { code: 'INTERNAL' });
  }
});

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

/**
 * Callable cho giảng viên: trợ lý AI (Gemini function-calling). Body { history } — xem src/ai_assistant.js.
 * Function chỉ proxy LLM; việc đọc/ghi điểm danh do app thực thi với quyền của GV.
 * Emulator/e2e: đặt GEMINI_API_BASE trỏ về stub và GEMINI_API_KEY bất kỳ (env hoặc .secret.local).
 */
export const aiAssistant = onCall(
  { region: REGION, secrets: [GEMINI_API_KEY], timeoutSeconds: 90, memory: '256MiB', maxInstances: 5 },
  async (request) => {
    try {
      return await runAiAssistant(
        { db: getFirestore(), apiKey: process.env.GEMINI_API_KEY },
        { uid: request.auth?.uid, history: request.data?.history },
      );
    } catch (error) {
      if (error instanceof AiError) {
        throw new HttpsError(error.status, error.message, { code: error.code });
      }
      console.error('aiAssistant failed', error);
      throw new HttpsError('internal', 'Trợ lý AI gặp lỗi, vui lòng thử lại.', { code: 'INTERNAL' });
    }
  },
);

let ttsClient;

/**
 * Callable cho giảng viên: giọng đọc tiếng Việt của Google Cloud Text-to-Speech cho Trợ lý AI. Body { text }.
 * Trả { audioBase64, mimeType, voice }. Cần bật "Cloud Text-to-Speech API"; app tự dùng giọng của máy khi lỗi.
 */
export const aiSpeak = onCall(
  { region: REGION, timeoutSeconds: 30, memory: '256MiB', maxInstances: 5 },
  async (request) => {
    try {
      ttsClient ??= new TextToSpeechClient();
      return await runSpeak(
        { db: getFirestore(), synthesize: (req) => ttsClient.synthesizeSpeech(req) },
        { uid: request.auth?.uid, text: request.data?.text },
      );
    } catch (error) {
      if (error instanceof SpeakError) {
        throw new HttpsError(error.status, error.message, { code: error.code });
      }
      console.error('aiSpeak failed', error);
      throw new HttpsError('internal', 'Giọng đọc gặp lỗi.', { code: 'INTERNAL' });
    }
  },
);

/** Callable cho admin: trả dashboard fatal crashes từ Crashlytics BigQuery export. */
export const getCrashlyticsDashboard = onCall(
  { region: REGION, memory: '512MiB', timeoutSeconds: 60, maxInstances: 5, invoker: 'public' },
  async (request) => {
    try {
      bigQueryClient ??= new BigQuery();
      return await loadCrashlyticsDashboard(
        { db: getFirestore(), bigquery: bigQueryClient, projectId: process.env.GCLOUD_PROJECT || 'ducminh-41459' },
        { uid: request.auth?.uid, days: request.data?.days ?? 7 },
      );
    } catch (error) {
      if (error instanceof CrashlyticsError) {
        throw new HttpsError(error.status, error.message, { code: error.code });
      }
      console.error('getCrashlyticsDashboard failed', error);
      throw new HttpsError('internal', 'Không thể tải dữ liệu Crashlytics lúc này.', { code: 'INTERNAL' });
    }
  },
);
