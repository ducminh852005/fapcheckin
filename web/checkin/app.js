// Trang điểm danh của sinh viên — chạy hoàn toàn trên Firebase (Auth + Firestore), không có backend riêng.
//
// QR do app giảng viên sinh có dạng:  /?s=<sessionId>&t=<qrSecret>&ic=<0|1>
//   s  : id phiên điểm danh (sessions/{s})
//   t  : mã bí mật hiện tại của phiên (xoay định kỳ) — Security Rules đối chiếu với sessions/{s}.qrSecret
//   ic : 1 nếu phiên bật kiểm tra IP (trang cần gửi kèm IP công khai); rules vẫn tự kiểm tra thật
//
// Điểm danh = tạo attendance_records/{s}_{rollNumber}. firebase/firestore.rules quyết định mọi thứ:
// đúng QR, phiên đang mở, SV có ghi danh, IP khớp (nếu bật) và không điểm danh trùng.
import { initializeApp } from 'https://www.gstatic.com/firebasejs/12.19.0/firebase-app.js';
import {
  GoogleAuthProvider, connectAuthEmulator, getAuth, onAuthStateChanged, signInWithPopup, signInWithRedirect, signOut,
} from 'https://www.gstatic.com/firebasejs/12.19.0/firebase-auth.js';
import {
  collection, connectFirestoreEmulator, doc, getDoc, getDocs, getFirestore, query, serverTimestamp, setDoc, where,
} from 'https://www.gstatic.com/firebasejs/12.19.0/firebase-firestore.js';
import { isStudentProfile } from './profile.js';

const params = new URLSearchParams(location.search);
const sessionId = params.get('s') || '';
const qrToken = params.get('t') || '';
const ipCheck = params.get('ic') === '1';

// Mã lỗi nghiệp vụ -> nội dung hiển thị.
const ERROR_MAP = {
  IP_MISMATCH: {
    title: 'Không xác minh được mạng',
    message: 'IP công khai của thiết bị không trùng với IP của phiên điểm danh, hoặc mã QR đã hết hạn.',
    hint: 'Hãy tắt VPN/proxy, kết nối đúng Wi-Fi lớp học, quét lại mã QR mới nhất rồi bấm "Thử lại".',
    canRetry: true, canLogout: false,
  },
  SESSION_NOT_FOUND: {
    title: 'Mã QR đã hết hạn',
    message: 'Mã QR đã hết hạn hoặc phiên điểm danh đã kết thúc.',
    hint: 'Vui lòng hướng camera quét lại mã QR mới nhất trên màn hình của giảng viên.',
    canRetry: false, canLogout: false,
  },
  NOT_ENROLLED: {
    title: 'Không thuộc lớp học này',
    message: 'Bạn không có tên trong danh sách lớp này.',
    hint: 'Nếu bạn nghĩ đây là nhầm lẫn, vui lòng liên hệ giảng viên. Nếu bạn đăng nhập nhầm tài khoản, hãy đổi tài khoản.',
    canRetry: false, canLogout: true,
  },
  VALIDATION_ERROR: {
    title: 'Thiếu mã điểm danh',
    message: 'Không tìm thấy mã điểm danh trong đường dẫn.',
    hint: 'Vui lòng quay lại và quét mã QR hiển thị trên màn hình của giảng viên.',
    canRetry: false, canLogout: false,
  },
  DOMAIN_NOT_ALLOWED: {
    title: 'Tài khoản chưa được cấp quyền',
    message: 'Email này không có trong danh sách sinh viên của hệ thống.',
    hint: 'Vui lòng đăng nhập bằng email nhà trường hoặc liên hệ quản trị viên.',
    canRetry: false, canLogout: true,
  },
  WRONG_ROLE: {
    title: 'Sai loại tài khoản',
    message: 'Tài khoản này không phải tài khoản sinh viên.',
    hint: 'Giảng viên mở phiên điểm danh trong app FAP Check-in, không điểm danh ở trang này.',
    canRetry: false, canLogout: true,
  },
  ACCOUNT_DISABLED: {
    title: 'Tài khoản bị khóa',
    message: 'Tài khoản của bạn đã bị khóa.',
    hint: 'Vui lòng liên hệ quản trị viên.',
    canRetry: false, canLogout: true,
  },
  NETWORK_ERROR: {
    title: 'Lỗi kết nối mạng',
    message: 'Không thể kết nối tới máy chủ hoặc lấy địa chỉ IP.',
    hint: 'Kiểm tra lại kết nối Internet (tắt VPN/4G nếu có) rồi bấm "Thử lại".',
    canRetry: true, canLogout: false,
  },
};

class CheckinError extends Error {
  constructor(code, message) {
    super(message || code);
    this.code = code;
  }
}

const $ = (id) => document.getElementById(id);

function showView(id) {
  document.querySelectorAll('.view').forEach((el) => el.classList.remove('active'));
  $(`view-${id}`)?.classList.add('active');
}

function setLoadingStep(text) {
  const el = $('loading-step');
  if (!el) return;
  el.classList.add('fade-out');
  setTimeout(() => { el.innerText = text; el.classList.remove('fade-out'); }, 150);
}

function formatTime(date) {
  return date.toLocaleString('vi-VN', {
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    day: '2-digit', month: '2-digit', year: 'numeric',
  });
}

function showError(code, fallback) {
  const info = ERROR_MAP[code] || {
    title: 'Thất bại', message: fallback || 'Đã xảy ra lỗi không xác định.', hint: '', canRetry: true, canLogout: false,
  };
  if (code === 'ALREADY_CHECKED_IN') {
    $('already-msg').innerText = 'Bạn đã điểm danh trong phiên này rồi.';
    showView('already');
    return;
  }
  $('error-title').innerText = info.title;
  $('error-msg').innerText = info.message || fallback;
  const hint = $('error-hint');
  hint.innerText = info.hint || '';
  hint.style.display = info.hint ? 'block' : 'none';
  $('btn-retry').style.display = info.canRetry ? 'block' : 'none';
  $('btn-logout').style.display = info.canLogout ? 'block' : 'none';
  showView('error');
}

// ------------------------------------------------------------------ Firebase
async function initFirebase() {
  // Firebase Hosting (và Hosting Emulator) tự phục vụ cấu hình của project: không phải commit apiKey vào repo.
  const config = await (await fetch('/__/firebase/init.json')).json();
  const app = initializeApp(config);
  const auth = getAuth(app);
  const db = getFirestore(app);
  // Chạy với Emulator: mở trang với ?emulator=1 (chỉ hoạt động trên localhost).
  if (params.get('emulator') === '1' && ['localhost', '127.0.0.1'].includes(location.hostname)) {
    connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
    connectFirestoreEmulator(db, '127.0.0.1', 8085);
  }
  return { auth, db };
}

/** Hồ sơ users/{uid}; lần đăng nhập đầu tạo từ user_invites/{email} (rules chặn tự đặt role). */
async function loadProfile(db, user) {
  const ref = doc(db, 'users', user.uid);
  let snap = await getDoc(ref);
  if (!snap.exists()) {
    const email = (user.email || '').toLowerCase();
    const invite = await getDoc(doc(db, 'user_invites', email)).catch(() => null);
    if (!invite || !invite.exists()) throw new CheckinError('DOMAIN_NOT_ALLOWED');
    const data = invite.data();
    await setDoc(ref, {
      memberCode: data.memberCode,
      fullName: data.fullName || user.displayName || '',
      email,
      role: data.role,
      ...(data.rollNumber ? { rollNumber: data.rollNumber } : {}),
      active: true,
      createdAt: serverTimestamp(),
    });
    snap = await getDoc(ref);
  }
  const profile = snap.data();
  if (profile.active === false) throw new CheckinError('ACCOUNT_DISABLED');
  if (!isStudentProfile(profile)) throw new CheckinError('WRONG_ROLE');
  return profile;
}

/** Lấy IP công khai (có timeout + nguồn dự phòng). Chỉ gọi khi phiên bật kiểm tra IP. */
async function fetchPublicIp() {
  const get = async (url) => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 6000);
    try { return (await (await fetch(url, { signal: controller.signal })).json()).ip; } finally { clearTimeout(timer); }
  };
  try { return await get('https://api.ipify.org?format=json'); } catch { return get('https://api64.ipify.org?format=json'); }
}

/**
 * Rules chỉ trả "permission-denied" nên không biết lý do. Đọc thêm những gì sinh viên được phép đọc
 * (bản ghi của chính mình) để chọn thông báo phù hợp nhất.
 */
async function diagnoseDenied(db, profile) {
  const own = await getDoc(doc(db, 'attendance_records', `${sessionId}_${profile.rollNumber}`)).catch(() => null);
  if (own?.exists()) return 'ALREADY_CHECKED_IN';
  return ipCheck ? 'IP_MISMATCH' : 'SESSION_NOT_FOUND';
}

/**
 * Tạo attendance_records/{s}_{roll}. Các trường khớp đúng điều kiện studentCheckin() trong firestore.rules.
 * SV không đọc được `sessions` (tránh lộ qrSecret) nên classCode/teacherMemberCode lấy từ ghi danh của
 * chính mình (enrollments có denormalize teacherMemberCode); SV học nhiều lớp thì thử lần lượt từng lớp
 * cho tới khi rules chấp nhận.
 */
async function checkin(db, profile) {
  if (!sessionId || !qrToken) throw new CheckinError('VALIDATION_ERROR');

  const enrolled = (await getDocs(
    query(collection(db, 'enrollments'), where('rollNumber', '==', profile.rollNumber)),
  ).catch(() => null))?.docs.map((d) => d.data()) ?? [];
  if (enrolled.length === 0) throw new CheckinError('NOT_ENROLLED');

  let ipAddress = '';
  if (ipCheck) {
    setLoadingStep('Phiên này yêu cầu kiểm tra mạng. Đang xác định IP...');
    try { ipAddress = (await fetchPublicIp()) || ''; } catch { throw new CheckinError('NETWORK_ERROR'); }
    if (!ipAddress) throw new CheckinError('NETWORK_ERROR');
  }

  setLoadingStep('Đang gửi thông tin điểm danh...');
  const ref = doc(db, 'attendance_records', `${sessionId}_${profile.rollNumber}`);
  for (const enrollment of enrolled) {
    try {
      await setDoc(ref, {
        sessionId,
        rollNumber: profile.rollNumber,
        classCode: enrollment.classCode,
        teacherMemberCode: enrollment.teacherMemberCode,
        qrToken,
        status: 'Present',
        checkinTime: serverTimestamp(),
        networkVerificationResult: ipCheck ? 'Match' : 'Skipped',
        ipAddress,
        syncedToFap: false,
      });
      return;
    } catch (error) {
      if (error.code !== 'permission-denied') throw new CheckinError('NETWORK_ERROR', error.message);
    }
  }
  throw new CheckinError(await diagnoseDenied(db, profile));
}

// ---------------------------------------------------------------------- luồng
const { auth, db } = await initFirebase().catch(() => ({}));
let running = false;

async function run(user) {
  if (running) return;
  running = true;
  showView('loading');
  setLoadingStep('Đang xác thực tài khoản...');
  try {
    const profile = await loadProfile(db, user);
    await checkin(db, profile);
    $('info-name').innerText = profile.fullName || '—';
    $('info-roll').innerText = profile.rollNumber;
    $('info-time').innerText = formatTime(new Date());
    showView('success');
  } catch (error) {
    showError(error instanceof CheckinError ? error.code : 'NETWORK_ERROR', error.message);
  } finally {
    running = false;
  }
}

$('btn-google').addEventListener('click', async () => {
  showView('loading');
  setLoadingStep('Đang mở cửa sổ đăng nhập Google...');
  const provider = new GoogleAuthProvider();
  provider.setCustomParameters({ prompt: 'select_account' });
  try {
    await signInWithPopup(auth, provider); // onAuthStateChanged sẽ chạy điểm danh
  } catch (error) {
    if (error.code === 'auth/popup-blocked') return signInWithRedirect(auth, provider);
    if (error.code === 'auth/popup-closed-by-user' || error.code === 'auth/cancelled-popup-request') return showView('login');
    showError('NETWORK_ERROR', error.message);
  }
});
$('btn-retry').addEventListener('click', () => auth.currentUser ? run(auth.currentUser) : location.reload());
$('btn-logout').addEventListener('click', async () => { await signOut(auth); location.reload(); });
document.querySelectorAll('[data-close]').forEach((b) => b.addEventListener('click', () => window.close()));

if (!auth) {
  showError('NETWORK_ERROR', 'Không tải được cấu hình Firebase.');
} else if (!sessionId || !qrToken) {
  showError('VALIDATION_ERROR');
} else {
  // Đã đăng nhập từ lần trước (Firebase Auth lưu phiên trong trình duyệt) -> tự điểm danh ngay.
  onAuthStateChanged(auth, (user) => (user ? run(user) : showView('login')));
}
