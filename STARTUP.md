# Khởi động Dididi từ đầu (sau khi tắt máy)

Chạy lần lượt 4 lớp. Mỗi lệnh mở trong 1 cửa sổ Terminal riêng (trừ MySQL/Redis chạy nền).

## 1. Hạ tầng: MySQL + Redis (backend bắt buộc cần)
```bash
brew services start mysql
brew services start redis
redis-cli ping     # kỳ vọng: PONG
```
> Nếu cài MySQL/Redis kiểu khác (Docker, app riêng) thì bật theo cách đó. Backend KHÔNG khởi động được nếu thiếu 2 cái này.

## 2. Backend (Spring Boot, cổng 8080)
```bash
cd "/Users/jay/Studying/Spring tools/dididi-booking-platform"
./mvnw spring-boot:run
```
- Chờ dòng: `Started DididiBookingPlatformApplication ...`
- Kiểm tra: mở http://localhost:8080 → thấy trang Dididi.
- Nếu lỗi liên quan MinIO/S3 (lưu ảnh) thì bật MinIO; các tính năng đang test không bắt buộc ảnh.

## 3. Emulator Android (chỉ khi test app mobile / push)
```bash
flutter emulators                       # xem id
flutter emulators --launch Pixel_7      # bỏ qua nếu emulator đã mở sẵn
```
Chờ tới khi hiện màn hình chính Android.
> Push (FCM) cần emulator **có Google Play** (thấy icon Play Store).

## 4. App Flutter (Terminal mới)
```bash
cd "/Users/jay/Studying/Spring tools/dididi_mobile"
flutter run                             # chọn emulator nếu được hỏi
```
- Trên emulator, app tự trỏ backend qua `10.0.2.2:8080`.
- Trong khi chạy: gõ `r` = hot reload, `R` = hot restart, `q` = thoát.

### Biến thể: chạy web (để test nhanh trên trình duyệt)
```bash
cd "/Users/jay/Studying/Spring tools/dididi_mobile"
flutter run -d web-server --web-port=4300
```
Rồi mở `http://localhost:4300`. (Cổng 4300 đã được thêm vào CORS của backend.)

## Tài khoản test
- Khách: `customer0001@dididi.local` / `Customer@123`
- Admin: `admin@dididi.local` / `Admin@123`

## Ghi chú
- Admin Angular (nếu cần) chạy riêng ở cổng 4200.
- Thanh toán VNPay: thẻ test NCB `9704198526191432198`, `NGUYEN VAN A`, `07/15`, OTP `123456` (xem `PUSH_VA_VNPAY_GUIDE.md`).
