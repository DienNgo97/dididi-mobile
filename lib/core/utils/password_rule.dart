/// Quy tắc mật khẩu dùng chung cho toàn app.
///
/// PHẢI khớp từng chữ với quy tắc máy chủ ở
/// `dididi-booking-platform/.../identity/service/AccountService.java` (hằng `STRONG`),
/// nơi nó được áp cho cả ba luồng: đăng ký, đặt lại mật khẩu, đổi mật khẩu.
///
/// Trước đây mỗi màn tự kiểm `length < 8` và tự ghi một câu hướng dẫn khác nhau,
/// nhẹ hơn thực tế — người dùng làm đúng theo app vẫn bị máy chủ từ chối
/// (phát hiện khi chạy bộ test mobile ngày 24/08/2026). Gom về một chỗ để
/// nếu máy chủ đổi luật thì chỉ phải sửa đúng một dòng.
library;

final RegExp _matKhauManh = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');

/// Trả về true nếu mật khẩu đủ mạnh theo đúng chuẩn máy chủ.
bool matKhauDuManh(String? pw) => pw != null && _matKhauManh.hasMatch(pw);
