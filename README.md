# Dididi Mobile (Flutter)

App Android + iOS cho Dididi, dùng chung backend Spring Boot qua REST `/api/**` (JWT).
Xem kế hoạch tổng thể ở [PLAN.md](PLAN.md).

## Cài đặt & chạy

Thư mục này hiện chỉ có **mã Dart** (`lib/`) + `pubspec.yaml`. Cần sinh khung native (android/ios) một lần:

```bash
cd "/Users/jay/Studying/Spring tools"

# 1) Sinh khung native ở thư mục TẠM (không đè code của mình):
flutter create --org com.dididi --project-name dididi_mobile _shell_tmp

# 2) Copy android/ ios/ (+ file cấu hình) sang project:
cp -R _shell_tmp/android _shell_tmp/ios dididi_mobile/
cp _shell_tmp/.metadata dididi_mobile/ 2>/dev/null
cp _shell_tmp/analysis_options.yaml dididi_mobile/ 2>/dev/null
rm -rf _shell_tmp

# 3) Cài dependency + chạy:
cd dididi_mobile
flutter pub get
flutter run
```

> Nếu `flutter run` báo thiếu file gen (vd `google-services`), bỏ qua — GĐ1 chưa cần Firebase.

## Cấu hình URL backend
`lib/core/config/env.dart`:
- **Android emulator**: tự dùng `http://10.0.2.2:8080` (trỏ localhost máy tính).
- **iOS simulator**: `http://localhost:8080`.
- **Máy thật**: đổi thành IP LAN của máy chạy backend, vd `http://192.168.1.10:8080`.

Nhớ chạy backend `dididi-booking-platform` trước (port 8080).

## Đã có (GĐ1)
- Đăng nhập / đăng ký (JWT + tự refresh token).
- Home 3 tab: **Khách sạn** (tìm theo thành phố, danh sách, chi tiết) · **Đơn của tôi** · **Tài khoản** (đăng xuất).

## Kiến trúc
`lib/core` (config, network Dio+JWT, storage, router, theme) · `lib/features/<tên>` (data + state Riverpod + ui) · `lib/shared` (widget/format dùng chung).

## Việc tiếp theo (tóm tắt)
- **GĐ2**: đặt phòng end-to-end + **thanh toán VNPay** — cần thêm API backend (tạo URL VNPay + xử lý return qua deep link) + API loại phòng theo khách sạn; vé máy bay.
- **GĐ3**: điểm/voucher, wishlist, thông báo đẩy (thêm API + FCM/APNs).
- **GĐ4**: cộng đồng + tin nhắn (API đã có) + trip planner + đánh giá.

Chi tiết & bảng "API còn thiếu" ở [PLAN.md](PLAN.md).
