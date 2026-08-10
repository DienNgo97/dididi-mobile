# Hướng dẫn: Push notification (Firebase) + Test thanh toán VNPay

App ID để dùng xuyên suốt:
- **Android** `applicationId`: `com.dididi.dididi_mobile`
- **iOS** bundle id: `com.dididi.dididiMobile`

---

# PHẦN 1 — PUSH NOTIFICATION (FCM cho Android, APNs cho iOS)

> Trạng thái hiện tại: app đã có **trung tâm thông báo in-app** (đọc qua API). Phần còn thiếu là **đẩy (push)** khi app đóng/nền. Push = 3 mảnh: (A) tạo project Firebase + file cấu hình, (B) code Flutter lấy token & nhận message, (C) backend lưu token & gọi FCM gửi.
>
> Việc **chỉ bạn làm được** (cần tài khoản): A + phần iOS (Apple Developer). Việc **mình làm được sau khi có key**: toàn bộ code B + C. Hướng dẫn này đưa luôn code để bạn (hoặc mình) dán vào.

## A. Tạo Firebase project + file cấu hình

### A1. Cài công cụ (một lần)
```bash
# Firebase CLI (cần Node.js)
npm install -g firebase-tools
firebase login          # mở trình duyệt, đăng nhập Google

# FlutterFire CLI
dart pub global activate flutterfire_cli
# đảm bảo PATH có ~/.pub-cache/bin:
echo 'export PATH="$HOME/.pub-cache/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

### A2. Tạo project trên Firebase Console
1. Vào https://console.firebase.google.com → **Add project** → đặt tên (vd `dididi`) → tạo (tắt Analytics cũng được).

### A3. Gắn Firebase vào app bằng FlutterFire (tự động)
Tại thư mục `dididi_mobile`:
```bash
cd "/Users/jay/Studying/Spring tools/dididi_mobile"
flutterfire configure
```
- Chọn project `dididi` vừa tạo.
- Chọn nền tảng: **android, ios** (bỏ web/macos nếu không cần).
- Xác nhận applicationId `com.dididi.dididi_mobile` và bundle iOS `com.dididi.dididiMobile`.

Lệnh này **tự động**:
- Tạo `lib/firebase_options.dart`.
- Tải `android/app/google-services.json`.
- Tải `ios/Runner/GoogleService-Info.plist` (và thêm vào Xcode project).
- Thêm google-services plugin cho Android.

> Nếu `flutterfire configure` không tự thêm plugin Android, kiểm tra `android/settings.gradle` có dòng `id "com.google.gms.google-services" version "4.4.2" apply false` và `android/app/build.gradle` có `id "com.google.gms.google-services"`.

## B. Code Flutter

### B1. Thêm package
```bash
flutter pub add firebase_core firebase_messaging
flutter pub get
```

### B2. Tạo `lib/core/push/push_service.dart`
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../network/api_client.dart';
import '../../firebase_options.dart'; // do flutterfire configure sinh ra

/// Xử lý message khi app ở background/terminated (phải là top-level + @pragma).
@pragma('vm:entry-point')
Future<void> firebaseBgHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Có thể log; hệ điều hành tự hiển thị notification nếu payload có 'notification'.
}

class PushService {
  final ApiClient _api;
  PushService(this._api);

  Future<void> init() async {
    final fm = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(firebaseBgHandler);

    // iOS + Android 13+ phải xin quyền
    await fm.requestPermission(alert: true, badge: true, sound: true);

    // iOS: cần APNs token trước khi lấy FCM token
    await fm.getAPNSToken();
    final token = await fm.getToken();
    if (token != null) await _register(token);
    fm.onTokenRefresh.listen(_register);

    // App đang mở: hiển thị banner in-app (tuỳ bạn) + refresh chuông
    FirebaseMessaging.onMessage.listen((m) {
      // ví dụ: đọc m.notification?.title / m.data['type'] rồi show SnackBar / cập nhật badge
    });
  }

  Future<void> _register(String token) async {
    try {
      await _api.postData<void>('/api/v1/devices/token',
          body: {'token': token, 'platform': _platform()}, parse: (_) {});
    } catch (_) {/* im lặng, sẽ thử lại lần refresh sau */}
  }

  String _platform() {
    // đơn giản; có thể dùng dart:io Platform (không chạy trên web)
    return 'FCM';
  }
}
```

### B3. Khởi tạo trong `lib/main.dart`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: DididiApp()));
}
```
Rồi sau khi đăng nhập xong (trong `AuthController` sau `login()`/bootstrap thành công) gọi `PushService(api).init()` để đăng ký token gắn với user đang đăng nhập. (Mình có thể nối chỗ này giúp bạn.)

### B4. iOS — bật capability trong Xcode
Mở `ios/Runner.xcworkspace` bằng Xcode → target **Runner** → tab **Signing & Capabilities** → **+ Capability**:
- **Push Notifications**
- **Background Modes** → tick **Remote notifications**

> ⚠️ **Push iOS chỉ chạy trên máy thật**, KHÔNG chạy trên Simulator. Android thì emulator có Google Play là được.

## C. iOS — APNs Authentication Key (.p8)
1. Vào https://developer.apple.com/account → **Certificates, Identifiers & Profiles** → **Keys** → **+**.
2. Đặt tên (vd `Dididi APNs`), tick **Apple Push Notifications service (APNs)** → Continue → Register.
3. **Tải file `.p8`** (chỉ tải được 1 lần!). Ghi lại **Key ID**. Lấy **Team ID** ở mục Membership.
4. Firebase Console → ⚙ **Project settings** → tab **Cloud Messaging** → mục **Apple app configuration** → **APNs Authentication Key** → **Upload** file `.p8` + nhập **Key ID** + **Team ID**.

## D. Backend — lưu token & gửi FCM

### D1. Thêm dependency (`dididi-booking-platform/pom.xml`)
```xml
<dependency>
  <groupId>com.google.firebase</groupId>
  <artifactId>firebase-admin</artifactId>
  <version>9.3.0</version>
</dependency>
```

### D2. Service account key
Firebase Console → ⚙ Project settings → **Service accounts** → **Generate new private key** → tải file JSON.
- Lưu vào máy (KHÔNG commit). Trỏ đường dẫn trong `application-local.yml`:
```yaml
app:
  firebase:
    enabled: true
    credentials-path: /Users/jay/secrets/dididi-firebase-adminsdk.json
```

### D3. Khởi tạo FirebaseApp (bean, chỉ khi enabled)
```java
@Configuration
public class FirebaseConfig {
  @Bean
  @ConditionalOnProperty(name = "app.firebase.enabled", havingValue = "true")
  FirebaseApp firebaseApp(@Value("${app.firebase.credentials-path}") String path) throws IOException {
    try (var in = new FileInputStream(path)) {
      var options = FirebaseOptions.builder()
          .setCredentials(GoogleCredentials.fromStream(in)).build();
      return FirebaseApp.getApps().isEmpty() ? FirebaseApp.initializeApp(options) : FirebaseApp.getInstance();
    }
  }
}
```

### D4. Lưu device token
- Entity `DeviceToken {userId, token(unique), platform, createdAt}` + repository.
- Controller:
```java
@RestController @RequestMapping("/api/v1/devices")
class DeviceApiController {
  // POST /token  body {token, platform}  -> upsert theo userId+token
}
```

### D5. Gửi FCM khi có sự kiện
Chỗ nào đang tạo `UserNotification` (đơn xác nhận, DM mới, hoàn tiền…), gọi thêm:
```java
void push(Long userId, String title, String body, Map<String,String> data) {
  for (String tok : deviceTokenRepo.findTokens(userId)) {
    var msg = com.google.firebase.messaging.Message.builder()
        .setToken(tok)
        .setNotification(Notification.builder().setTitle(title).setBody(body).build())
        .putAllData(data)
        .build();
    try { FirebaseMessaging.getInstance().send(msg); }
    catch (Exception e) { /* token hỏng -> xoá */ }
  }
}
```

## E. Test push
1. Chạy app trên **máy Android thật/emulator có Play** (iOS: máy thật). Đăng nhập → token được gửi lên backend.
2. Nhanh nhất: Firebase Console → **Messaging** → **Send test message** → dán FCM token (in ra ở log app) → gửi.
3. Luồng thật: tạo 1 đơn / gửi 1 DM → backend gọi `push(...)` → điện thoại nhận.

> Mình có thể code toàn bộ **B + D** (Flutter service + backend entity/controller/sender + nối vào chỗ tạo notification) sau khi bạn xong bước A + C và đưa file service-account. Bạn chỉ cần cấp key, mình ráp code + test.

---

# PHẦN 2 — TEST THANH TOÁN VNPAY SANDBOX

> Luồng trong app: tạo đơn (PENDING) → bấm **Đặt & thanh toán** → chọn **VNPay** → app mở cổng VNPay trên trình duyệt → bạn nhập thẻ test → VNPay chuyển hướng về `/payment/vnpay-return` (backend tự xác nhận đơn) → quay lại app bấm **"Tôi đã thanh toán"** → app poll và hiện **Đã xác nhận**.

## A. Điều kiện backend (đã có sẵn)
Trong `application-local.yml` đã có:
```yaml
app:
  vnpay:
    tmn-code: DM4DR3V5
    hash-secret: 0QFKNRA45GZVV4MZ673LDH0KXY8GLAZW
```
(Đây là thông tin sandbox. Return URL cấu hình phía server, mặc định về `/payment/vnpay-return`.)

## B. Thẻ test (ngân hàng NCB — giao dịch thành công)
| Trường | Giá trị |
|---|---|
| Ngân hàng | **NCB** |
| Số thẻ | **9704198526191432198** |
| Tên chủ thẻ | **NGUYEN VAN A** |
| Ngày phát hành | **07/15** |
| Mật khẩu OTP | **123456** |

## C. Các bước bấm
1. Trong app: mở 1 **khách sạn** (hoặc **vé máy bay**) → **Đặt phòng/Đặt vé** → điền thông tin → **Đặt & thanh toán**.
2. Hộp thoại thanh toán → chọn **VNPay** (nút xanh). App mở trang cổng VNPay.
3. Chọn **NCB** → nhập thẻ test ở bảng trên → tiếp tục → nhập **OTP 123456** → xác nhận.
4. VNPay báo thành công và chuyển hướng về trang `/payment/vnpay-return` (backend xác nhận đơn → CONFIRMED).
5. Quay lại app, bấm **"Tôi đã thanh toán"** → app kiểm tra và hiện **Đặt phòng/vé thành công**.

## D. Lưu ý quan trọng theo môi trường
- **Test trên Flutter Web (localhost:4300)** — chạy ngon: cổng VNPay mở tab mới, return về `localhost:8080` (máy bạn) OK.
- **Emulator/điện thoại thật**: `localhost` của thiết bị ≠ máy chạy backend. Muốn return chạy được, đặt **return URL = IP LAN** của máy (vd `http://192.168.1.10:8080/payment/vnpay-return`) qua biến `app.vnpay.return-url` (hoặc cấu hình gateway trong admin), và thiết bị cùng Wi-Fi.
- **IPN (server-to-server)**: VNPay gọi trực tiếp `/payment/vnpay-ipn`. Để nhận IPN thật (chắc chắn cập nhật đơn kể cả khi user không quay lại), cần URL công khai — dùng **ngrok**: `ngrok http 8080` rồi khai báo IPN URL = `https://<ngrok>.ngrok.app/payment/vnpay-ipn` trong tài khoản sandbox. Với demo, luồng **return + poll** ở trên là đủ.
- Chỉ dùng **đúng thẻ test** trong danh sách sandbox; thẻ khác sẽ báo lỗi.

---

**Nguồn tham khảo:**
- FlutterFire Messaging: https://firebase.flutter.dev/docs/messaging/overview/
- FCM cho Flutter (get started): https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- APNs key (.p8) cho FCM: https://firebase.google.com/docs/cloud-messaging/ios/get-started
- VNPay sandbox demo + thẻ test: https://sandbox.vnpayment.vn/apis/vnpay-demo/
- Đăng ký merchant sandbox: https://sandbox.vnpayment.vn/devreg/
</content>
