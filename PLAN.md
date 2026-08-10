# Dididi Mobile — Kế hoạch (Flutter, Android + iOS)

App di động dùng chung backend Spring Boot qua REST `/api/**` (JWT stateless). Mục tiêu: **full parity với web**.

## Tech stack
- **Flutter** (Dart) — 1 codebase Android + iOS.
- **Riverpod** — quản lý state (auth, data).
- **Dio** — HTTP client + interceptor gắn JWT + **tự refresh token** khi 401.
- **go_router** — điều hướng + guard đăng nhập.
- **flutter_secure_storage** — lưu access/refresh token an toàn.
- **intl** — định dạng tiền/ngày (vi_VN).

## Kiến trúc (feature-first)
```
lib/
  core/        config (base URL), network (Dio+JWT), storage, router, theme
  features/
    auth/      models · repository · controller (Riverpod) · ui (login/register)
    hotels/    ...
    bookings/  ...
    flights/ loyalty/ community/ notifications/ ...  (thêm dần)
  shared/      widgets dùng chung
```
Mỗi feature tách 3 lớp: **data** (model + repository gọi API) · **state** (Riverpod controller) · **ui** (màn hình).

## API sẵn có vs còn thiếu (quan trọng)
| Mảng | API JSON sẵn có | Ghi chú |
|---|---|---|
| Đăng nhập/đăng ký | ✅ `/api/auth/*` (login, refresh, logout, register, me) | Dùng ngay |
| Khách sạn | ✅ `/api/v1/hotels` (list theo city, map, nearby, detail) | **Thiếu bộ lọc nâng cao** (sao/giá/tiện nghi) — lọc client hoặc thêm param |
| Đặt phòng/vé | ✅ `/api/v1/bookings` (create, me, detail, cancel, pay) | `pay` hiện là **MOCK**, chưa có VNPay |
| Vé máy bay | ✅ `/api/v1/flights` | |
| Đánh giá | ✅ `/api/v1/reviews` (+ ảnh) | |
| Cộng đồng + DM | ✅ `/api/v1/social` | |
| Trip Planner | ✅ `/api/v1/trip-planner` | |
| **Thanh toán VNPay** | ❌ web-only | **Cần API**: tạo URL + xử lý return qua deep link |
| **Điểm/Voucher** | ❌ web-only | **Cần API** khách: xem điểm, đổi voucher, danh sách |
| **Thông báo** | ❌ web-only (session) | **Cần API JWT** + push (FCM/APNs) |
| **Wishlist** | ❌ web-only | **Cần API** |
| **Hỗ trợ (chatbot)** | ❌ web-only | **Cần API** |

## Giai đoạn
- **GĐ1 (đang code):** Auth + Khách sạn (list/tìm/chi tiết) + Đơn của tôi — *chỉ dùng API sẵn có*.
- **GĐ2:** Đặt phòng end-to-end + **Thanh toán VNPay** (thêm API backend + deep-link return) + Vé máy bay.
- **GĐ3:** Điểm/Voucher + Wishlist + **Thông báo đẩy** (thêm API + FCM/APNs).
- **GĐ4:** Cộng đồng + Tin nhắn (API đã có) + Trip Planner + Đánh giá.
- **GĐ5:** Đa ngôn ngữ (vi/en), hoàn thiện UX, chuẩn bị phát hành (icon, splash, store).

## Màn hình GĐ1
Đăng nhập · Đăng ký · Home (bottom nav: Khách sạn / Đơn / Tài khoản) · Danh sách + tìm khách sạn · Chi tiết khách sạn · Đơn của tôi · Tài khoản.

> Backend cần bổ sung các API "❌" ở trên khi tới GĐ tương ứng — sẽ làm song song bên `dididi-booking-platform`.
