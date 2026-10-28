# Trang đăng nhập

- `login_screen.dart`: lifecycle Google Sign-In, trạng thái chờ, lỗi và chuyển màn hình; gọi `AuthViewModel` hiện có.
- `layouts/login_mobile_layout.dart`: bố cục dưới 768 logical pixels, SafeArea và cuộn trên màn hình thấp.
- `layouts/login_desktop_layout.dart`: giao diện hai cột hiện có ở kích thước từ 768 trở lên.
- `styles/login_styles.dart`: màu, kích thước và typography riêng của login.
- `widgets/login_background.dart`: nền sáng với hai vùng chuyển sắc.
- `widgets/login_brand.dart`: logo FPT và thẻ thương hiệu FAP Check-in.
- `widgets/login_sign_in_card.dart`: lời chào và ghi chú tài khoản trường.
- `widgets/login_google_button.dart`: nút native có loading/disabled; web dùng nút Google SDK hiện có.
- `widgets/login_footer.dart`: nội dung điều khoản và phiên bản.

Sửa bố cục trong layout, sửa từng thành phần trong widgets, sửa màu/font trong styles.
Logic xác thực nằm ở `../../viewmodels/auth_viewmodel.dart` và service/repository hiện có.
Không thêm Firebase call vào widget. Ghi chú miền email chỉ là nội dung UI; quyền truy cập vẫn do luồng xác thực quyết định.
Logo dùng asset hiện có `assets/images/Logo_FPT_Education-Photoroom.png`.
Status bar và thanh cử chỉ do hệ điều hành hiển thị, không vẽ giả trong UI.

Kiểm tra: `flutter analyze lib/views/auth`, `flutter test test/login_mobile_layout_test.dart` từ `mobile/`.
