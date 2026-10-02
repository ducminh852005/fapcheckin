[← Mục lục](README.md)

# Hướng dẫn deploy lên Firebase

Script [`scripts/deploy.ps1`](../scripts/deploy.ps1) deploy ba thứ, chạy theo thứ tự:

1. **Backend** (Google Apps Script): chạy test, `clasp push`, cập nhật Web App deployment hiện có (URL không đổi), kiểm tra revision đang chạy.
2. **Hosting**: chỉ trang check-in của Sinh viên.
3. **Firestore**: rules + indexes.

Backend vẫn là Apps Script cho tới khi port xong; xem [db-erd.mermaid](db-erd.mermaid) và [db-erd-notes.md](db-erd-notes.md) cho thiết kế Firestore.

> **App Giảng viên KHÔNG được deploy bằng script này.** Theo kiến trúc ([01](01-kien-truc-tong-the.md), [04](04-kien-truc-app-va-web.md)) app GV là app Flutter cài trên máy giảng viên (Android/iOS/Windows...), không phải web. Chỉ trang web của sinh viên cần một địa chỉ công khai, vì sinh viên mở nó bằng cách quét QR. Trước đây trang này do chính Apps Script phục vụ (`?page=checkin`); Firebase Hosting là chỗ host thay thế.

## 1. Tổng quan

```
apps-script/*.gs ─(test → clasp push → clasp deploy -i)─► Apps Script Web App (URL không đổi)
                                                                 ▲
checkin-web/index.html ─(inject BACKEND_URL)─► build/firebase-hosting ─► Firebase Hosting
                                                                         https://<project-id>.web.app/?token=<qrToken>
firestore.rules + firestore.indexes.json ───────────────────────────────► Firestore (rules + indexes)

Trang SV gọi backend qua BACKEND_URL; app GV gọi qua ApiService.baseUrl (cùng một Web App).
```

| Thành phần | Nguồn trong repo | Đích |
|---|---|---|
| Backend (Apps Script) | `apps-script/*.gs` | Web App deployment hiện có (id lấy từ URL backend) |
| Trang check-in SV | `checkin-web/index.html` | Hosting (gốc `/`) |
| Cấu hình Hosting | `firebase.json` | Hosting |
| Firestore rules | `firestore.rules` (chặn toàn bộ client SDK; backend dùng Admin SDK) | Firestore |
| Firestore indexes | `firestore.indexes.json` (2 composite index từ ERD) | Firestore |
| App Giảng viên | `lib/` (Flutter) | **Không deploy ở đây** — build/phân phối như app Flutter thông thường |

Script **không** sửa source: `BACKEND_URL` của trang SV chỉ được điền vào bản copy trong `build/firebase-hosting/`.

> **Lưu ý:** deploy Hosting chưa đổi link trong mã QR. QR của sinh viên vẫn trỏ về Apps Script (`kCheckinBaseUrl` trong `qr_panel.dart`); trang trên Hosting chạy song song. Cách chuyển nằm ở [mục 6](#6-chuyển-qr-của-sinh-viên-sang-hosting-chưa-làm), hiện **chưa thực hiện**.

## 2. Chuẩn bị (làm một lần)

1. **Tạo project Firebase** tại [console.firebase.google.com](https://console.firebase.google.com) → *Add project*. Ghi lại **Project ID** (vd `fap-checkin-ab12c`).
2. **Bật Firestore**: *Build → Firestore Database → Create database* → chế độ **Native**, chọn region gần Việt Nam (vd `asia-southeast1`). Region không đổi được sau khi tạo. Cần làm trước khi deploy Firestore.
3. **Bật Hosting**: *Build → Hosting → Get started* (chỉ cần bấm qua, script sẽ deploy).
4. **Cài Firebase CLI** (cần Node.js 18+):
   ```powershell
   npm install -g firebase-tools
   ```
   Không cài cũng được: script tự dùng `npx --yes firebase-tools` (chậm hơn lần đầu).
5. **Đăng nhập**:
   ```powershell
   firebase login
   ```
6. *(Tuỳ chọn)* Gắn project mặc định để khỏi gõ `-ProjectId`:
   ```powershell
   firebase use --add   # chọn project, đặt alias "default" -> tạo .firebaserc
   ```

7. **Chỉ cần khi deploy backend** — cài và đăng nhập clasp bằng đúng tài khoản Google sở hữu script:
   ```powershell
   npm install -g @google/clasp@2
   clasp login              # tạo ~/.clasprc.json
   ```
   `apps-script/.clasp.json` (scriptId) đã có trong repo; nếu thiếu, script tự tạo từ `apps-script/clasp.json`. Cần bật *Apps Script API* tại [script.google.com/home/usersettings](https://script.google.com/home/usersettings).

Không cần Flutter SDK để chạy script này.

## 3. Chạy script

Từ thư mục gốc repo, trong PowerShell:

```powershell
./scripts/deploy.ps1 -ProjectId <project-id>
```

Nếu bị chặn bởi Execution Policy: `powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1 -ProjectId <project-id>`.

| Tham số | Mặc định | Ý nghĩa |
|---|---|---|
| `-ProjectId` | project `default` trong `.firebaserc` | Firebase project ID. Bắt buộc khi deploy hosting/firestore mà chưa có `.firebaserc`; không cần với `-Only backend`. |
| `-Only` | `all` | `all` = backend + hosting + firestore; hoặc một trong `backend`, `hosting`, `firestore`. |
| `-Channel` | *(trống)* | Deploy Hosting lên **preview channel** (URL tạm, hết hạn) thay vì live. Chỉ dùng với `-Only hosting`. |
| `-BackendUrl` | `defaultValue` trong `lib/core/network/api_service.dart` | URL Apps Script Web App (`.../macros/s/<DEPLOYMENT_ID>/exec`), điền vào `BACKEND_URL` của trang SV và dùng để suy ra deployment id. |
| `-DeploymentId` | parse từ `-BackendUrl` | Apps Script deployment id cần cập nhật. |
| `-SkipTests` | tắt | Bỏ bước `node --test apps-script/tests` trước khi push backend. |
| `-StageOnly` | tắt | Gom file vào `build/firebase-hosting` rồi dừng, **không deploy gì** (kể cả backend). |
| `-DryRun` | tắt | Chỉ in các bước và lệnh, không ghi/deploy. |

Ví dụ:

```powershell
# Deploy đầy đủ (backend + Hosting + Firestore)
./scripts/deploy.ps1 -ProjectId fap-checkin-ab12c

# Chỉ backend Apps Script (không cần ProjectId)
./scripts/deploy.ps1 -Only backend

# Backend nhưng bỏ test (không khuyến khích)
./scripts/deploy.ps1 -Only backend -SkipTests

# Xem trước sẽ chạy gì
./scripts/deploy.ps1 -ProjectId fap-checkin-ab12c -DryRun

# Thử trên preview channel trước khi lên live
./scripts/deploy.ps1 -ProjectId fap-checkin-ab12c -Only hosting -Channel preview

# Chỉ cập nhật rules + indexes Firestore
./scripts/deploy.ps1 -ProjectId fap-checkin-ab12c -Only firestore

# Dùng backend Apps Script khác (vd bản test)
./scripts/deploy.ps1 -ProjectId fap-checkin-ab12c -BackendUrl "https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec"

# Kiểm tra bước gom file, không deploy
./scripts/deploy.ps1 -ProjectId fap-checkin-ab12c -Only hosting -StageOnly
```

## 4. Script làm gì

1. **Kiểm tra**: file cấu hình Firebase tồn tại và JSON hợp lệ; `checkin-web/index.html`, `apps-script/Router.gs` tồn tại; có Firebase CLI / clasp (hoặc `npx` dự phòng); clasp đã đăng nhập.
2. **Gom file** vào `build/firebase-hosting/` (xoá sạch mỗi lần chạy): copy `checkin-web/*`, rồi thay dòng `var BACKEND_URL = '';` trong `index.html` bản copy bằng `-BackendUrl`. Nếu dòng đó bị đổi trong source, script dừng và báo lỗi thay vì deploy trang không cấu hình.
3. **Backend** (nếu chọn): giống workflow [`apps-script-deploy.yml`](../.github/workflows/apps-script-deploy.yml):
   1. `node --test apps-script/tests/*.test.cjs` (trừ khi `-SkipTests`); test đỏ thì dừng, chưa đẩy gì.
   2. Kiểm tra `ReportService.gs` và action `getReport` còn trong `Router.gs`.
   3. `clasp push -f` (trong `apps-script/`), rồi `clasp deploy -i <deploymentId> -d "..."` → cập nhật **đúng deployment cũ**, URL Web App không đổi nên app GV, QR và trang SV không phải đổi gì.
   4. Gọi `<BackendUrl>?action=getBackendInfo` tối đa 6 lần (cách nhau 10 giây), so `revision` với chuỗi `revision` trong `Router.gs`. Không khớp thì script báo lỗi.
4. **Firebase** (nếu chọn hosting/firestore): `firebase deploy --only hosting,firestore --project <id>` (hoặc `hosting:channel:deploy <channel>` khi có `-Channel`). Nếu có biến môi trường `FIREBASE_TOKEN`, script thêm `--non-interactive`.
5. In URL backend và trang SV: `https://<project-id>.web.app/?token=<qrToken>`.

Backend chạy **trước** Hosting để trang SV vừa lên đã gọi được API mới.

> **Đổi `revision` khi sửa backend:** bước 4 chỉ phát hiện được deploy thất bại nếu chuỗi `revision` trong `apps-script/Router.gs` (action `getBackendInfo`) thay đổi mỗi lần bạn muốn xác nhận bản mới. Nhớ đổi chuỗi này khi sửa backend.

> **Cảnh báo:** `-Only all` (mặc định) đẩy backend **đang chạy thật**. Muốn chỉ cập nhật Firebase, dùng `-Only hosting` hoặc `-Only firestore`.

`firebase.json`: mọi đường dẫn trả về `index.html`; header `no-cache` để sinh viên luôn nhận bản mới nhất.

## 5. Sau khi deploy — checklist

- [ ] Mở `https://<project-id>.web.app/?token=test` → trang SV hiện (báo mã QR không hợp lệ hoặc yêu cầu đăng nhập là bình thường).
- [ ] **Google OAuth**: thêm `https://<project-id>.web.app` vào **Authorized JavaScript origins** của OAuth Web client (Google Cloud Console → APIs & Services → Credentials). Thiếu bước này, nút đăng nhập Google trên trang SV sẽ lỗi. Chi tiết: [google-oauth-setup.md](google-oauth-setup.md).
- [ ] Firebase Console → Firestore → *Rules*: thấy rule `allow read, write: if false`; tab *Indexes*: có `attendanceSessions` và `classSchedules`.
- [ ] Điểm danh thử một lần bằng token phiên thật để chắc trang gọi được API Apps Script từ origin mới. Apps Script mở `ANYONE_ANONYMOUS` và trang dùng `text/plain` để tránh preflight CORS.

## 6. Chuyển QR của sinh viên sang Hosting (CHƯA LÀM)

> **Trạng thái hiện tại: mã QR vẫn trỏ về Apps Script.** Deploy Hosting **không** tự đổi link trong QR. Sinh viên quét QR vẫn vào trang check-in do Apps Script phục vụ; trang trên Hosting đã deploy và chạy song song nhưng **chưa có ai được dẫn tới đó**. Việc chuyển QR chưa được thực hiện trong repo; làm theo các bước dưới đây khi sẵn sàng.

### Hiện trạng trong code

| Vị trí | Nội dung hiện tại |
|---|---|
| `lib/views/teacher/live_session/components/qr_panel.dart` dòng 13 | `const String kCheckinBaseUrl = 'https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec';` |
| `lib/viewmodels/live_session_viewmodel.dart` dòng 102-103 | `checkinUrl` = `'$kCheckinBaseUrl?page=checkin&token=$qrToken'` (chuỗi này được vẽ thành QR và nút *Sao chép link*) |
| `apps-script/Code.gs` | `doGet` chỉ trả trang check-in khi `?page=checkin`; `CHECKIN_WEB_APP_URL` chỉ dùng cho luồng đăng nhập của trang do Apps Script phục vụ |

`kCheckinBaseUrl` chỉ dùng để dựng `checkinUrl`; API backend của app lấy từ `ApiService.baseUrl`, nên đổi `kCheckinBaseUrl` **không** ảnh hưởng gọi API.

### Các bước chuyển

1. **Thử trước**: mở `https://<project-id>.web.app/?token=<qrToken thật>` (lấy token từ một phiên đang mở) trên điện thoại, đăng nhập Google và điểm danh thử một lần. Đảm bảo đã thêm origin Hosting vào OAuth (mục 5).
2. **Sửa `qr_panel.dart`**: tách URL trang check-in khỏi URL Apps Script, cho phép ghi đè lúc build:
   ```dart
   const String kCheckinBaseUrl = String.fromEnvironment(
     'CHECKIN_BASE_URL',
     defaultValue: 'https://<project-id>.web.app/',
   );
   ```
3. **Sửa `live_session_viewmodel.dart`**: trang Hosting chỉ cần `token`, không có `page=checkin`:
   ```dart
   String get checkinUrl =>
       qrToken.isEmpty ? '' : '$kCheckinBaseUrl?token=$qrToken';
   ```
4. **Không cần sửa `apps-script/Code.gs`**: `CHECKIN_WEB_APP_URL` chỉ phục vụ trang check-in cũ trên Apps Script, giữ nguyên làm đường lui.
5. **Build lại app Giảng viên** (Android/iOS/Windows... đang dùng) và phân phối lại, vì `kCheckinBaseUrl` được biên dịch vào app. QR của các phiên đã mở trước đó vẫn là link Apps Script cho tới khi mở phiên mới.
6. **Kiểm tra**: mở phiên điểm danh mới, quét QR bằng điện thoại, URL phải bắt đầu bằng `https://<project-id>.web.app/?token=`; điểm danh xong kiểm tra bản ghi trong Google Sheet.

### Đường lui

Đặt lại `kCheckinBaseUrl` về URL Apps Script và `checkinUrl` về dạng `'$kCheckinBaseUrl?page=checkin&token=$qrToken'`, build lại app. Trang Apps Script vẫn nguyên vẹn nên không cần deploy backend.

## 7. Rollback

- **Hosting**: Firebase Console → *Hosting → Release history* → chọn bản cũ → *Rollback*. Hoặc deploy lại commit cũ bằng script.
- **Firestore rules/indexes**: checkout commit cũ của `firestore.rules` / `firestore.indexes.json` rồi `./scripts/deploy.ps1 -ProjectId <id> -Only firestore`. Xoá index thừa thủ công trong Console (deploy không tự xoá index).
- **Preview channel** tự hết hạn; xoá sớm: `firebase hosting:channel:delete <channel> --project <id>`.

## 8. Xử lý sự cố

| Triệu chứng | Nguyên nhân / cách xử lý |
|---|---|
| `Missing Firebase project...` | Chưa truyền `-ProjectId` và chưa có `.firebaserc`. Truyền `-ProjectId` hoặc chạy `firebase use --add`. |
| `firebase CLI not found` | Không có `firebase` lẫn `npx`. Cài Node.js rồi `npm install -g firebase-tools`. |
| `Error: Failed to authenticate` / `Not logged in` | Chạy `firebase login` (hoặc `firebase login --reauth`). CI: đặt `FIREBASE_TOKEN`. |
| `HTTP Error: 403` / `does not exist or you do not have permission` | Sai project ID hoặc tài khoản không có quyền Editor/Owner trên project. Kiểm tra `firebase projects:list`. |
| `clasp is not logged in` / `Could not read API credentials` | Chạy `clasp login` bằng tài khoản sở hữu script. |
| `User has not enabled the Apps Script API` | Bật tại [script.google.com/home/usersettings](https://script.google.com/home/usersettings). |
| `Cannot derive the Apps Script deployment id` | `-BackendUrl` không có dạng `.../macros/s/<id>/exec`. Truyền `-DeploymentId`. |
| Test lỗi, script dừng ở bước backend | Sửa test/code; chưa có gì được đẩy lên. Chỉ dùng `-SkipTests` khi hiểu rõ rủi ro. |
| `still not serving revision '...'` | Deployment chưa cập nhật kịp hoặc `clasp deploy` trỏ nhầm deployment. Kiểm tra Apps Script → *Deploy → Manage deployments*, chạy lại. |
| `Firestore ... database (default) does not exist` | Chưa tạo database. Làm bước 2 mục *Chuẩn bị*. |
| `checkin-web/index.html no longer contains "var BACKEND_URL = '';"` | Ai đó sửa dòng cấu hình trong `checkin-web/index.html`. Khôi phục dòng đó hoặc sửa chuỗi tìm kiếm trong `scripts/deploy.ps1`. |
| Trang SV báo `Chưa cấu hình BACKEND_URL` | Bản deploy cũ hoặc bị cache. Chạy lại script, mở bằng cửa sổ ẩn danh. |
| Nút đăng nhập Google lỗi `origin_mismatch` | Chưa thêm origin Hosting vào OAuth client (mục 5). |
| Script bị chặn: `running scripts is disabled` | `powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1 ...` |

## 9. Định hướng

- **Port backend**: khi chuyển 30 action của `Router.gs` sang Cloud Functions/Firestore, thêm `functions/` vào `firebase.json` và mở rộng `-Only` (vd `functions`). Rules hiện chặn hết client; backend dùng Admin SDK. Khi app đọc Firestore trực tiếp, viết lại rules theo `request.auth` và role.
- **CI**: backend đã có workflow tự deploy [`.github/workflows/apps-script-deploy.yml`](../.github/workflows/apps-script-deploy.yml) (chạy khi push `main` sửa `apps-script/**`), dùng chung cách làm với script này. Để tự deploy Firebase, có thể thêm workflow tương tự chạy `firebase deploy --only hosting,firestore` với secret `FIREBASE_TOKEN` (`firebase login:ci`) hoặc service account. Chưa tạo workflow đó trong repo. Tránh để script local và workflow cùng đẩy backend một lúc.

## 10. Chuyển DB sang Firestore

Mặc định backend vẫn đọc/ghi Google Sheet (`DB_BACKEND=sheet`). Các bước dưới đây chuyển sang Firestore; thiết kế ở [03](03-du-lieu-firestore.md), kiến trúc ở [01](01-kien-truc-tong-the.md). Tất cả hàm chạy tay trong **Apps Script editor** (chọn hàm → *Run*), không có action nào lộ ra API.

### 10.1 Điều kiện

- Firestore `(default)` đã tạo trong project (đã có ở `fapcheckin-30e86`, Native mode).
- Tài khoản **chủ script** (người deploy Web App, `executeAs USER_DEPLOYING`) có vai trò **Cloud Datastore User** (hoặc Owner/Editor) trên project Firebase.
- Đã deploy code mới: `./scripts/deploy.ps1 -Only backend` (kèm `-ProjectId` nếu cần deploy Firebase). Manifest `appsscript.json` thêm scope `https://www.googleapis.com/auth/datastore`.
- Script Property tùy chọn `FIREBASE_PROJECT_ID` (mặc định `fapcheckin-30e86`). `DB_BACKEND` chưa đặt = `sheet`.

> **Quan trọng:** thêm scope mới nghĩa là chủ script phải **cấp quyền lại** (bước 1 bên dưới) ngay sau khi deploy. Trước khi cấp quyền, Web App có thể báo lỗi ủy quyền dù vẫn ở chế độ `sheet`. Làm bước 1 ngay sau khi `clasp deploy`, rồi mở `<BackendUrl>?action=getBackendInfo` kiểm tra `success: true`.

### 10.2 Quy trình

| # | Hàm (Apps Script editor) | Việc làm | Kỳ vọng |
|---|---|---|---|
| 1 | `authorizeFirestore()` | Xin quyền scope `datastore`, gọi thử Firestore. | Hộp thoại cấp quyền → log `Firestore OK, project: …`. Lỗi `DB_PERMISSION` = thiếu IAM. |
| 2 | `seedSlots()` | Ghi 4 `timeSlots` + 12 `slots` (quy tắc A/P, [03 §3](03-du-lieu-firestore.md#3-quy-tắc-lịch-slot-ap)). | Log `Seeded 4 timeSlots, 12 slots.` Chạy lại an toàn. |
| 3 | `migrateSheetsToFirestoreDryRun()` | Đọc Sheet, chuẩn hóa, **không ghi**; in số doc từng collection + cảnh báo. | Đọc kỹ cảnh báo (ngày số serial, `slotCode` lạ, ghi danh thiếu user…). |
| 4 | `migrateSheetsToFirestore()` | Import thật (upsert, chạy lại được). Vượt 6 phút: chạy lại từng phần, ví dụ `migrateSheetsToFirestore(false, ['attendanceRecords'])`. | Log số doc từng collection. |
| 5 | `verifyMigration()` | So id trong Firestore với những gì Sheet phải tạo ra; kiểm tra 12 slots/4 timeSlots. | `VERIFY OK`. |
| 6 | `useFirestore()` | Đặt `DB_BACKEND=firestore` (cutover). | `getBackendInfo` trả `dbBackend: "firestore"`. |

Nên cutover ngoài giờ có phiên điểm danh đang mở: phiên mở trên Sheet trước cutover sẽ không thấy trên Firestore. Nếu cần, import lại (bước 4) ngay trước bước 6 để lấy dữ liệu mới nhất.

### 10.3 Kiểm tra sau cutover (smoke test)

1. `getBackendInfo` → `dbBackend: "firestore"`.
2. App GV: đăng nhập, mở danh sách lớp (giờ lấy từ slot: A1 = 07:00–09:15…), mở một phiên **không tích** "Kiểm tra IP mạng", quét QR bằng điện thoại → điểm danh thành công; quét lần hai → `ALREADY_CHECKED_IN`.
3. Mở phiên **có tích** kiểm tra IP: SV khác mạng bị `IP_MISMATCH`, cùng mạng thì qua.
4. Đóng phiên → SV chưa điểm danh thành `Absent`; xem Lịch sử điểm danh và Báo cáo.
5. Firebase Console → Firestore: thấy `attendanceSessions`, `attendanceRecords/{sessionId}_{rollNumber}`.

### 10.4 Rollback

`useSheet()` đặt lại `DB_BACKEND=sheet` — hiệu lực ngay, không cần deploy. **Dữ liệu ghi từ lúc cutover không được chép ngược về Sheet**, nên sau khi quay lại các phiên/điểm danh mới nhất sẽ không có trong Sheet. Vì vậy chỉ rollback sớm sau cutover, hoặc xuất tay dữ liệu cần giữ từ Firebase Console trước khi quay lại.

### 10.5 Lưu ý vận hành

- **Quota:** mỗi thao tác Firestore là một `UrlFetchApp`; tài khoản thường ~20.000 lượt/ngày ([09](09-rui-ro-va-gioi-han.md)). Đường nóng (check-in, mở/đóng phiên, roster) đã đọc có lọc; các màn tổng hợp đọc nhiều hơn.
- **Slot chỉ đọc:** ghi vào `Slot` bị bỏ qua khi dùng Firestore (giờ cố định theo quy tắc A/P); OCR thời khóa biểu chỉ tạo lớp.
- **Lỗi thường gặp:** `DB_PERMISSION` (thiếu IAM hoặc chưa cấp quyền lại scope), `DB_UNAVAILABLE` (Firestore/mạng tạm lỗi, đã tự thử lại 3 lần), `DB_CONFLICT` (ghi trùng document id — API đổi thành `ALREADY_CHECKED_IN` với điểm danh).
- **Phương án dự phòng nếu không dùng được token của chủ script:** service account + ký JWT trong Apps Script (khóa lưu ở Script Properties). Chưa triển khai.
