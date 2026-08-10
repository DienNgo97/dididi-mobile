# Thiết lập Đăng nhập Google (Dididi mobile)

Code đã xong sẵn. Bạn chỉ cần lấy **SHA-1**, bật Google trong **Firebase**, rồi dán **Web Client ID** vào app + backend. ~10 phút.

Giá trị dự án của bạn (điền sẵn):

| Mục | Giá trị |
|-----|---------|
| Firebase project | `dididi-791b9` (project number `349258992830`) |
| Android package | `com.dididi.dididi_mobile` |
| File cần sửa (app) | `lib/core/config/env.dart` → `Env.googleServerClientId` |
| File cần sửa (backend) | `application-local.yml` → `app.google.client-ids` (tuỳ chọn) |

---

## Bước 1 — Lấy SHA-1 (bản debug)

Mở terminal trên máy bạn:

```bash
cd "/Users/jay/Studying/Spring tools/dididi_mobile/android"
./gradlew signingReport
```

Tìm khối có **`Variant: debug`** → dòng **`SHA1:`**. Copy chuỗi kiểu `AA:BB:CC:...` (40 ký tự hex, có dấu hai chấm).

> Nếu `./gradlew` lỗi, dùng cách thay thế:
> ```bash
> keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
> ```

---

## Bước 2 — Bật Google trong Firebase (tạo Web Client ID)

1. Vào https://console.firebase.google.com → chọn project **dididi-791b9**.
2. Menu trái: **Build → Authentication**. Lần đầu thì bấm **Get started**.
3. Tab **Sign-in method** → **Add new provider** → chọn **Google** → gạt **Enable**.
4. Chọn **Project support email** (email của bạn) → **Save**.
5. Vẫn ở Google provider, mở rộng mục **Web SDK configuration** → copy **Web client ID** (dạng `xxxxx.apps.googleusercontent.com`).
   👉 **Đây chính là `serverClientId` bạn cần.** Lưu lại.

---

## Bước 3 — Đăng ký SHA-1 cho app Android

1. Firebase Console → biểu tượng ⚙️ **Project settings** → tab **General**.
2. Kéo xuống **Your apps** → app Android **com.dididi.dididi_mobile**.
3. Bấm **Add fingerprint** → dán **SHA-1** ở Bước 1 → **Save**.
4. Bấm **Download google-services.json** (nút ở thẻ app đó) → thay thế file cũ tại:
   `/Users/jay/Studying/Spring tools/dididi_mobile/android/app/google-services.json`
   (File mới sẽ có `oauth_client` không còn rỗng.)

---

## Bước 4 — Dán Web Client ID vào app + backend

**App** — sửa `lib/core/config/env.dart`:

```dart
static const String googleServerClientId = 'xxxxx.apps.googleusercontent.com';
```

**Backend (tuỳ chọn nhưng nên làm)** — trong `application-local.yml`, để backend chỉ chấp nhận token của đúng app này:

```yaml
app:
  google:
    client-ids: "xxxxx.apps.googleusercontent.com"
```

> Bỏ trống `client-ids` thì backend vẫn xác thực chữ ký + email của Google, chỉ là không ràng buộc token phải của riêng app Dididi. Với đồ án thì để trống cũng chạy được.

---

## Bước 5 — Chạy lại

```bash
# Backend
cd "/Users/jay/Studying/Spring tools/dididi-booking-platform"
./mvnw spring-boot:run

# App (chạy trên MÁY ẢO ANDROID hoặc máy thật — KHÔNG phải web)
cd "/Users/jay/Studying/Spring tools/dididi_mobile"
flutter pub get
flutter run
```

Mở màn Đăng nhập → bấm **"Đăng nhập với Google"** → chọn tài khoản → vào thẳng app.

---

## Lưu ý

- **Chạy trên Android/iOS, không phải Flutter Web.** `google_sign_in` v6 trên web không trả `idToken`, nên nút chỉ hoạt động thật trên máy ảo/điện thoại. (Login email/mật khẩu vẫn chạy mọi nền tảng.)
- **Nếu bị chặn "app chưa xác minh" hoặc không đăng nhập được:** vào https://console.cloud.google.com → project `dididi-791b9` → **APIs & Services → OAuth consent screen → Test users → Add users** → thêm chính email Google bạn dùng để test.
- **iOS (tuỳ chọn):** thêm app iOS trong Firebase, tải `GoogleService-Info.plist`, và thêm **reversed client ID** vào `ios/Runner/Info.plist` (URL scheme). Chỉ cần khi demo trên iOS; Android thì bỏ qua phần này.
- Backend `POST /api/auth/google` nhận `{ "idToken": "..." }`, xác thực qua `https://oauth2.googleapis.com/tokeninfo`, tìm-hoặc-tạo user CUSTOMER rồi cấp JWT (giống hệt luồng Google trên web).
