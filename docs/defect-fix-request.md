# Yêu cầu sửa lỗi sau regression QA

Ngày tổng hợp: **02/11/2026**
Branch kiểm tra: **`feature/qa-testing`**
Commit sau merge được kiểm tra: **`e74c593`**
Người nhận: **Thành viên phụ trách Mobile/Firebase/Web Admin**

## 1. Kết quả kiểm tra bản merge

QA đã so sánh source từ QA HEAD `f1355e8` đến bản merge `e74c593`.

- Firebase Functions: **32/32 pass × 3 lượt = 96/96 pass**.
- Toàn bộ Flutter test: **89/89 pass**.
- Các test tự động xác nhận source biên dịch và unit/widget regression đang ổn.
- Tuy nhiên, **Test Case 03, Test Case 07, Test Case 08 và Test Case 09 chưa được sửa đầy đủ trong source**.

Sau khi sửa, vui lòng gửi hash commit cho TV5 để build APK mới và chạy Android regression ba lượt cho từng Test Case.

## 2. Test Case 03 (TC03) – Không đóng được phiên điểm danh

**Mức độ:** High
**Trạng thái:** Chưa sửa

### Hiện tượng

- Giảng viên tạo phiên và hiển thị QR thành công.
- Khi đóng phiên, Firestore trả `PERMISSION_DENIED`.
- Batch đóng session và tạo bản ghi `Absent` bị rollback nên session vẫn `open`.
- Nếu session được sửa trực tiếp trên Firebase, ứng dụng vẫn có thể giữ trạng thái phiên cũ cho đến khi restart.

### Vị trí cần kiểm tra

- `packages/core/lib/repositories/teacher_repository.dart:278`
  Logic `closeSession`, đóng phiên và tạo các bản ghi Absent.

- `firebase/firestore.rules:230`
  Hàm `teacherCreatesRecord`.

- `firebase/firestore.rules:242`
  Điều kiện yêu cầu enrollment có document ID:

  ```text
  enrollments/{classCode}_{rollNumber}
  ```

- `mobile/lib/viewmodels/live_session_viewmodel.dart:641`
  ViewModel gọi repository đóng phiên.

- `mobile/lib/views/teacher/attendance_history/history_actions.dart:531`
  Chặn mở phiên mới theo trạng thái session đang giữ trong bộ nhớ.

### Yêu cầu sửa

1. Kiểm tra dữ liệu enrollment có đúng ID `{classCode}_{rollNumber}`.
2. Kiểm tra Firestore Rules đang deploy có khớp source không.
3. Cho phép giảng viên phụ trách lớp tạo bản ghi Absent khi đóng phiên.
4. Reload/reset `LiveSessionViewModel` khi document session thay đổi.
5. Sau khi đóng, Dashboard, Lịch sử và Quản lý lớp phải cập nhật mà không restart.

### Tiêu chí nghiệm thu

- Tạo phiên thành công.
- Live QR hiển thị.
- Đóng phiên không có `PERMISSION_DENIED`.
- Session chuyển sang `closed` và Absent records được tạo đúng.
- Có thể mở phiên mới mà không force-stop ứng dụng.
- Đạt ba lượt Android regression liên tiếp.

Chi tiết QA: `docs/test-report.md`, mục `DEF-TC03-01` và `DEF-TC03-02`.

## 3. Test Case 07 (TC07) – File XLSX xuất ra nhưng không mở được

**Mức độ:** Medium
**Trạng thái:** Chưa sửa

### Hiện tượng

Ứng dụng báo file đã được lưu tại đường dẫn dạng:

```text
/data/user/0/com.example.fapcheckin/code_cache/...
```

Đây là vùng private của ứng dụng nên người dùng không thể mở hoặc chia sẻ file bằng ứng dụng khác.

### Vị trí cần kiểm tra

- `mobile/lib/core/services/history_download_io.dart:10`

Code hiện tại sử dụng:

```dart
Directory.systemTemp.createTemp(...)
```

sau đó ghi bytes và chỉ trả về chuỗi đường dẫn.

### Yêu cầu sửa

1. Dùng Android Share Sheet, Storage Access Framework hoặc MediaStore.
2. Trả URI mà ứng dụng khác có quyền đọc.
3. Chỉ thông báo thành công khi người dùng có thể mở hoặc chia sẻ XLSX.
4. Không lưu kết quả cuối chỉ trong `code_cache`.

### Tiêu chí nghiệm thu

- Export tạo workbook XLSX hợp lệ.
- Người dùng mở hoặc chia sẻ được file từ Android.
- File không chỉ tồn tại trong app-private storage.
- Đạt ba lượt Android regression liên tiếp.

Chi tiết QA: `docs/test-report.md`, mục `DEF-TC07-01`.

## 4. Test Case 08 (TC08) – Chưa có luồng yêu cầu sửa điểm danh end-to-end

**Mức độ:** High / Blocked feature
**Trạng thái:** Chưa triển khai đầy đủ

### Hiện tượng

- Mobile chưa có form gửi `attendance_fix` hoặc `leave`.
- Mobile chưa có màn hình theo dõi `pending`, `approved`, `rejected`.
- Web Admin có trang Request nhưng vẫn sử dụng mock data.
- Nút Approve/Reject hiện chỉ đóng drawer và hiện toast, không cập nhật request trên Firestore.

### Vị trí cần kiểm tra

- `firebase/firestore.rules:248`
  Schema và quyền cho collection `requests` đã tồn tại.

- `web/admin/src/pages/RequestsPage.tsx:31`
  Đang import `requestRows` từ mock data.

- `web/admin/src/pages/RequestsPage.tsx` khoảng dòng 180
  Approve/Reject hiện chỉ gọi `showToast`.

- Mobile và `packages/core` chưa có repository/UI thực tế cho collection `requests`.

### Yêu cầu triển khai

1. Mobile tạo request gồm tối thiểu:

   ```text
   type: attendance_fix | leave
   authorUid
   reason
   status: pending
   createdAt
   ```

2. Mobile listen trạng thái request realtime.
3. Web Admin đọc request thật từ Firestore thay cho mock data.
4. Approve/Reject cập nhật:

   ```text
   status
   resolvedBy
   resolvedAt
   adminNote
   ```

5. Mobile nhận trạng thái mới mà không cần sửa trực tiếp bằng Firebase Console.

### Tiêu chí nghiệm thu

- Tạo request từ UI Mobile thành công.
- Request xuất hiện trên Web Admin với `pending`.
- Admin Approve/Reject ghi đúng Firestore và đúng quyền.
- Mobile nhận trạng thái mới realtime.
- Đạt ba lượt Android/Web regression độc lập.

Chi tiết QA: `docs/qa-handoff.md`, phần Test Case 08.

## 5. Test Case 09 (TC09) – Offline bị hiển thị nhầm thành không có lớp

**Mức độ:** Medium
**Trạng thái:** Chưa sửa

### Hiện tượng

- Khi mất mạng, ứng dụng không crash nhưng không có thông báo offline hoặc nút retry.
- Dashboard có thể hiện `Chưa có lớp được phân công`, khiến người dùng hiểu nhầm lỗi mạng thành dữ liệu rỗng.
- ViewModel có lưu lỗi nhưng UI không hiển thị trạng thái lỗi tương ứng.

### Vị trí cần kiểm tra

- `mobile/lib/views/teacher/dashboard/dashboard_body.dart:37`
  Hiển thị toast `Chưa có lớp được phân công.`

- `mobile/lib/views/teacher/dashboard/dashboard_body.dart:63`
  Pull-to-refresh dùng cùng thông báo.

- `mobile/lib/viewmodels/dashboard_viewmodel.dart:212`
  ViewModel lưu `errorMessage`, nhưng Dashboard không dùng để hiển thị lỗi mạng.

### Yêu cầu sửa

1. Phân biệt rõ ba trạng thái: loading, empty data thật và network/error.
2. Khi offline, hiển thị thông báo phù hợp thay vì thông báo không có lớp.
3. Cung cấp nút `Thử lại`.
4. Khi bật mạng và retry, dashboard phải tải lại thành công.
5. Không che mất `errorMessage` từ ViewModel.

### Tiêu chí nghiệm thu

- Empty data thật hiển thị empty-state đúng.
- Mất mạng hiển thị offline/error state riêng.
- Có nút retry.
- Bật lại mạng và retry khôi phục dashboard.
- Không crash qua ba lượt Android regression.

Chi tiết QA: `docs/test-report.md`, mục `DEF-TC09-01`.

## 6. Thứ tự ưu tiên

1. **Test Case 03:** lỗi High, chặn nghiệp vụ đóng phiên.
2. **Test Case 08:** thiếu luồng cross-role bắt buộc của đề bài.
3. **Test Case 07:** chức năng export hiện không sử dụng được trên Android.
4. **Test Case 09:** cần phân biệt lỗi mạng với dữ liệu rỗng.

## 7. Minh chứng QA

Tài liệu trong repository:

- `docs/test-report.md`
- `docs/qa-handoff.md`
- `e2e_test/results/android-summary.json`

Raw evidence được giữ local và Git-ignore vì có thể chứa thông tin tài khoản:

```text
results/tc03-repro-2026-11-01/
results/tc07-export-2026-11-01/
results/tc09-empty-offline-2026-11-01/
```

Sau khi sửa, vui lòng cung cấp hash commit và xác nhận nếu có thay đổi/deploy Firestore Rules hoặc dữ liệu migration để TV5 chuẩn bị đúng precondition khi regression.
