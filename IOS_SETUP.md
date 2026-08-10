# Dididi Mobile — Chạy bản iOS

Ứng dụng Flutter đã cross-platform sẵn (Android + iOS + Web dùng chung 100% code Dart).
Khung native `ios/` đã có và đã được cấu hình. Tài liệu này hướng dẫn chạy trên iOS Simulator
và các bước tuỳ chọn (Firebase/Google Sign-In) khi cần.

## Yêu cầu máy
- macOS + **Xcode** (mở Xcode 1 lần để cài component, chấp nhận license: `sudo xcodebuild -license accept`)
- **CocoaPods**: `sudo gem install cocoapods` (hoặc `brew install cocoapods`)
- `flutter doctor` mục iOS phải xanh.

## Đã cấu hình sẵn (không cần làm gì)
| Hạng mục | Trạng thái |
|---|---|
| Khung `ios/` (Runner, Podfile, xcworkspace) | ✅ |
| Bundle ID `com.dididi.dididiMobile`, tên app "Dididi" | ✅ |
| Google Maps iOS key (`AppDelegate.swift` — GMSServices) | ✅ (tile cần bật billing như Android) |
| Quyền Info.plist: Vị trí, Thư viện ảnh, Camera, Micro (chuỗi tiếng Việt) | ✅ |
| Cho phép HTTP dev (`NSAllowsArbitraryLoads`) — backend localhost:8080 chưa HTTPS | ✅ (gỡ khi deploy HTTPS) |
| Scheme `tel:` (nút gọi tổng đài) | ✅ |
| Podfile `platform :ios, '15.0'` + ép deployment target mọi pod | ✅ |
| Base URL: iOS Simulator tự dùng `http://localhost:8080` (Env.baseUrl) | ✅ |

## Chạy lần đầu trên iOS Simulator
```bash
# 1. Mở simulator (hoặc mở app Simulator từ Xcode)
open -a Simulator

# 2. Chạy app (pod install tự chạy trong lần build đầu — hơi lâu)
cd "/Users/jay/Studying/Spring tools/dididi_mobile"
flutter pub get
flutter run          # chọn iPhone simulator trong danh sách thiết bị
```
- Backend Spring Boot phải đang chạy ở `localhost:8080` (simulator dùng chung localhost với máy Mac).
- Nếu lỗi pod: `cd ios && pod install --repo-update && cd ..` rồi `flutter run` lại.
- Chạy trên **iPhone thật**: cần Apple ID (ký dev) trong Xcode → Signing & Capabilities, và đổi
  `Env.baseUrl` sang IP LAN của máy Mac (vd `http://192.168.1.x:8080`).

## Hoạt động ngay trên iOS (không cần thêm gì)
Đăng nhập/đăng ký, khách sạn (list/chi tiết/hạng phòng/lọc/Top 10), đặt phòng (qua đêm + theo giờ),
vé máy bay (sơ đồ ghế/suất ăn/hành lý/hạng ghế), đơn của tôi (sửa/huỷ/hoá đơn PDF), thanh toán
(giả lập/VNPay/voucher/công ty), nhóm du lịch + QR, đặt hàng loạt, trip planner, cộng đồng đầy đủ
(đăng ảnh/video, like, bình luận, DM…), điểm thưởng, wishlist, chatbot, 3 ngôn ngữ (đã lưu bền),
theme Inter mới. `flutter_secure_storage` dùng Keychain iOS tự động.

## Tuỳ chọn 1 — Firebase iOS (push notification)
Hiện `firebase_options.dart` chưa có phần iOS → app iOS chạy bình thường nhưng **không có push**
(main() đã bọc try/catch). Khi muốn bật:
1. Firebase Console → project `dididi-791b9` → **Add app → iOS**, bundle `com.dididi.dididiMobile`.
2. Tải `GoogleService-Info.plist` → kéo vào `ios/Runner/` **bằng Xcode** (check "Copy items if needed" + target Runner).
3. Chạy `flutterfire configure` (chọn iOS) để sinh lại `lib/firebase_options.dart` có mục `ios`.
4. Push trên iOS thật cần APNs key trong Firebase + capability "Push Notifications" trong Xcode
   (simulator không nhận push — chỉ test trên máy thật).

## Tuỳ chọn 2 — Google Sign-In trên iOS
Cần làm **Tuỳ chọn 1** trước (có `GoogleService-Info.plist`), sau đó:
1. Mở file plist, copy giá trị `REVERSED_CLIENT_ID` (dạng `com.googleusercontent.apps.3492...`).
2. Thêm vào `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>REVERSED_CLIENT_ID_DÁN_VÀO_ĐÂY</string>
    </array>
  </dict>
</array>
```
3. `Env.googleServerClientId` (Web Client ID) đã cấu hình sẵn — backend xác thực `aud` khớp.

## Ghi chú
- Bản đồ (tab Bản đồ + chi tiết KS): key đã gắn ở AppDelegate nhưng tile chỉ hiện khi
  Google Cloud **bật billing** + bật "Maps SDK for iOS" cho key đó (cùng việc còn treo bên Android).
- VNPay mở Safari ngoài app (url_launcher) — hoạt động bình thường trên iOS.
- Khi nộp App Store thật: gỡ `NSAllowsArbitraryLoads`, dùng HTTPS.
