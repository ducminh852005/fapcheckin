# Báo cáo kiểm thử ARTEMIS — TC03, TC05–TC10

Ngày tổng hợp: **10/11/2026**  
Ứng dụng: **FAP Check-in**  
Package: `com.example.fapcheckin`  
Thiết bị: `emulator-5554`, Android 16  
Nguồn test case: `D:/ki8/PRM/Lab1/fapcheckin/docs/test-cases.md`

## Phạm vi và cách kết luận

Báo cáo được tổng hợp từ `stdout.log`, `run_outcome.json`, Checker ledger, ghi chú của ARTEMIS và video tự động trong `D:/tools/artemis/traces`. Kết quả được hạ xuống **Partial**, **Blocked** hoặc **Inconclusive** nếu ghi chú của agent không có assertion cuối tương ứng, mâu thuẫn với Checker, hoặc chưa kiểm đủ Expected Result.

Repository được ghi nhận trước các lượt chạy là `feature/qa-testing` tại `41d7413`, với working tree có thay đổi local. Trace không chứng minh APK đang cài trên giả lập được build từ đúng commit này.

## Tổng hợp

| Case | Kết quả tổng hợp | Kết quả chính |
|---|---|---|
| TC03 | **PASS — 1 lượt** | Tạo một phiên, hiển thị QR, đóng phiên qua UI, trạng thái Closed đồng bộ và bản ghi Absent được tạo. Checker đạt 9/9 assertion. |
| TC05 | **PARTIAL PASS — 1 lượt** | Mở được lịch sử, thấy Có mặt/Vắng và dữ liệu phiên. Chưa kiểm cách ly dữ liệu giữa hai giảng viên. |
| TC06 | **BLOCKED — 1 lượt** | Không tìm thấy bộ lọc môn có thể tương tác trên Lịch sử/Báo cáo. |
| TC07 | **PARTIAL PASS — 1 lượt có kết quả** | Bấm được xuất Excel và thấy hộp lưu Downloads với tên file XLSX. Chưa mở file và chưa đối chiếu nội dung workbook. |
| TC08 | **BLOCKED — 3 lượt không hoàn thành** | Mobile request UI được quan sát, nhưng Web Admin Review Queue/credentials không có trong môi trường. Không có E2E approve và mobile realtime update. |
| TC09 | **PASS theo Checker — cần xem lại video** | Checker đạt 6/6 assertion cho empty, offline và recovery. Ghi chú/ledger mô tả nhãn empty/offline chưa hoàn toàn nhất quán. |
| TC10 | **INCONCLUSIVE** | Ghi chú agent tự báo ba nhánh Pass, nhưng Checker cuối kết luận không có execution history/evidence cho cả ba nhánh. |

## TC03 — Tạo, hiển thị và đóng phiên điểm danh

- Trace: `8edeff7f-46d7-4082-97ec-04927d910581`
- Profile/model: Pro, `gemini-3.5-flash-lite`
- Trạng thái task: `completed`
- Run outcome: 9 passed, 0 failed, 0 inconclusive.
- Kết quả: **PASS cho lượt đã chạy**.

Evidence của Checker:

- Chỉ một phiên được tạo.
- Phiên chuyển sang trạng thái Open.
- QR hiển thị và app ổn định qua chu kỳ refresh.
- Đóng phiên thành công bằng UI.
- Phiên chuyển sang Closed mà không restart app.
- UI không giữ trạng thái Open cũ.
- Lịch sử hiển thị các bản ghi Absent cho những sinh viên không check-in.
- Không ghi nhận thay đổi ở lớp hoặc phiên ngoài phạm vi.

Giới hạn:

- Đây là một lượt. Test case yêu cầu ba lượt độc lập nếu dùng để đóng regression.
- Báo cáo đã lược bỏ mã lớp và dữ liệu nhận diện xuất hiện trong raw Checker ledger.


## TC05 — Lịch sử điểm danh

- Trace: `a9199952-2ccd-415e-a72f-085d968b7b5f`
- Profile/model: Flash, `gemini-3.5-flash`; visual summarizer dùng `gemini-3.5-flash-lite`.
- Trạng thái task: `completed`
- Kết quả: **PARTIAL PASS**.

Evidence:

- Từ Trang chủ, ARTEMIS mở shortcut Lịch sử.
- Màn `Điểm danh sinh viên` mở thành công.
- Có thể truy cập lịch sử phiên.
- Nhãn `Có mặt` và `Vắng` được quan sát.
- Không ghi nhận crash hoặc thao tác ghi dữ liệu.

Chưa kiểm:

- Dữ liệu có đúng hoàn toàn với fixture hay không.
- Cách ly dữ liệu giữa hai giảng viên.


## TC06 — Lọc lịch sử theo môn

- Trace: `f7ad0659-02c8-4d19-84fd-e87a2d7f21e3`
- Profile/model: Flash, `gemini-3.5-flash`; visual summarizer dùng `gemini-3.5-flash-lite`.
- Trạng thái task: `failed`
- Kết quả nghiệp vụ: **BLOCKED**.

Quan sát:

- Dropdown ở Báo cáo chỉ cung cấp phạm vi thời gian.
- Phần tổng hợp theo môn hiển thị số liệu nhưng ARTEMIS nhận diện các mục là summary không tương tác.
- Màn lịch sử sinh viên có tab buổi học và bộ lọc Tất cả/Có mặt/Vắng.
- Không tìm thấy điều khiển chọn môn để thực hiện hai lần lọc theo Expected Result.

Giới hạn:

- Cần người kiểm thử xem video để xác nhận bộ lọc không nằm ngoài vùng đã khám phá hoặc có gesture chưa được thử.
- Chưa đủ bằng chứng để phân loại đây là defect hay khác biệt thiết kế.

## TC07 — Xuất báo cáo XLSX

- Trace kết quả: `370afcca-4250-4f5f-a434-1301d0735e09`
- Profile/model: Pro, `gemini-3.5-flash-lite`
- Trạng thái task: `completed`
- Kết quả: **PARTIAL PASS**.

Evidence:

- Nút xuất Excel được tìm thấy.
- Thao tác xuất được kích hoạt.
- Hộp lưu Android Downloads xuất hiện với file `Attendance_report.xlsx`.
- Điều này chứng minh UI đã cung cấp đường lưu file cho người dùng trong lượt này.

Chưa kiểm:

- File đã được lưu thành công sau bước xác nhận.
- File có mở được bằng ứng dụng ngoài hay không.
- Workbook có đúng dữ liệu, cột và số dòng theo fixture hay không.

Các lượt Pro trước đó `de5bccc9-1f53-46a9-8c05-190728498f08` và `381d6fa5-020a-4a4f-a705-d6eb06be4e0f` bị dừng do lỗi quota, không dùng làm kết quả nghiệp vụ.

## TC08 — Yêu cầu sửa điểm danh

- Trace: `4db2a4d1-289b-459e-96cf-285631f50a3b`
- Trace: `0f5adb2b-3f07-46cf-8732-768da8853ec3`
- Trace: `0be631ee-e52c-4670-884e-1de9d0e2eaa8`
- Profile/model: Pro, `gemini-3.5-flash-lite`
- Kết quả: **BLOCKED**.

Quan sát:

- Một lượt dừng do `429 RESOURCE_EXHAUSTED`.
- Các lượt sau nhận diện Mobile request UI, nhưng không có Web Admin Review Queue hoặc credentials/browser flow đã cấu hình trên môi trường chạy.
- Có ghi chú của Planner nói đã submit một request Pending, nhưng các task đều bị cancel và không có Checker/run outcome xác nhận bước submit. Báo cáo không coi ghi chú này là bằng chứng Pass.
- Không có bằng chứng request xuất hiện trong hàng đợi admin, được approve/reject, hoặc mobile nhận cập nhật realtime.

Dependency còn thiếu:

- Web Admin Review Queue truy cập được bằng tài khoản admin test.
- Cùng Firebase test environment giữa Mobile và Web Admin.
- Evidence có assertion cho một request duy nhất, trạng thái Pending, admin action và trạng thái cuối trên Mobile.


## TC09 — Empty, offline và recovery

- Trace: `4860c85f-0ec0-4014-b5c9-ec11e78c4a9f`
- Profile/model: Pro, `gemini-3.5-flash-lite`
- Trạng thái task: `completed`
- Run outcome: 6 passed, 0 failed, 0 inconclusive.
- Kết quả theo ARTEMIS Checker: **PASS**.

Checker ghi nhận:

- Empty dataset tạo empty state.
- Offline có phản hồi và được phân biệt với empty state.
- Bật mạng rồi refresh khôi phục dữ liệu.
- Không cần force-stop và app không crash.
- Wi-Fi được bật lại khi kết thúc.

Điểm cần review:

- Scratchpad mô tả empty state là `Không tìm thấy sinh viên phù hợp`/0 sinh viên và offline là `Chưa có lớp học được phân công`.
- Checker ledger ở một assertion lại dẫn `Chưa có lớp học được phân công` làm empty state.
- Cần xem video để xác nhận hai trạng thái thực sự khác nhau và thông báo offline có đúng nghĩa hay chỉ là một empty state khác.

## TC10 — Popup native

- Trace: `ed7fa688-e338-415d-8429-7a064c1d212d`
- Profile/model: Pro, `gemini-3.5-flash-lite`
- Trạng thái task: `completed`
- Kết quả tổng hợp: **INCONCLUSIVE**.

Mâu thuẫn evidence:

- Note `tc10_results.md` tự báo Pass cho hủy account chooser, Deny notification và Allow notification, kể cả backend registration.
- Checker cuối trả JSON cho biết không có execution history/evidence cho cả ba scenario và kết luận `INCONCLUSIVE`.
- Trace không có `run_outcome.json` hay Checker ledger chứng minh các assertion.
- Tên thư mục video có hậu tố `PASS` chỉ phản ánh task graph kết thúc thành công, không đủ để kết luận nghiệp vụ Pass.

Để TC10 được công nhận:

- Chạy ba scenario độc lập với evidence popup thực.
- Xác nhận quyền bằng `dumpsys package` sau Deny và Allow.
- Có log backend registration sau Allow.
- Checker cuối phải dẫn được step/screenshot cho từng assertion.


## Kết luận định lượng của đợt này

- Pass đầy đủ theo evidence hiện có: **TC03**.
- Partial Pass: **TC05, TC07**.
- Blocked: **TC06, TC08**.
- Pass theo Checker nhưng cần review mâu thuẫn nhãn: **TC09**.
- Inconclusive do thiếu evidence: **TC10**.

Không quy đổi tên thư mục `PASS` hoặc trạng thái graph `completed` thành Pass nghiệp vụ nếu assertion cuối không đủ bằng chứng.
