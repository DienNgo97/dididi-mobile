# Cài môi trường & chạy Dididi Mobile — hướng dẫn chi tiết (MacBook M-series)

Dành cho MacBook chip Apple (M1…M5). Làm **theo đúng thứ tự A → G**. Mỗi bước có lệnh + **kết quả mong đợi** để biết đã đúng chưa.
Bản mới nhất hiện tại: **Flutter 3.44.x / Dart 3.12.x**.

> Bạn có thể chỉ cần **1 nền** để chạy app: **Android (Phần C)** *hoặc* **iOS (Phần D)**. Muốn nhanh & nhẹ → làm iOS Simulator trước. Cả hai thì làm cả C và D.

---

## PHẦN A — Công cụ nền (bắt buộc)

### A1. Xcode Command Line Tools
```bash
xcode-select --install
```
→ Hiện hộp thoại → bấm **Install** → chờ vài phút. Kiểm tra:
```bash
xcode-select -p
# Mong đợi in ra: /Library/Developer/CommandLineTools  (hoặc .../Xcode.app/... nếu đã cài Xcode)
git --version   # có sẵn sau bước trên
```

### A2. Homebrew (trình quản lý gói)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Trên máy Apple Silicon, Homebrew nằm ở **`/opt/homebrew`**. Sau khi cài xong, thêm vào shell:
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
brew --version   # Mong đợi: Homebrew 4.x
```

### A3. Rosetta 2 (Apple Silicon cần cho vài công cụ phụ)
```bash
sudo softwareupdate --install-rosetta --agree-to-license
```
→ Nhập mật khẩu máy, chờ ~1 phút.

---

## PHẦN B — Cài Flutter SDK

### B1. Tải SDK
```bash
mkdir -p ~/development && cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
```
(~1–3 phút tuỳ mạng.)

### B2. Thêm Flutter vào PATH
macOS dùng shell **Zsh**. Mở file `~/.zshrc` và thêm dòng PATH:
```bash
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```
Kiểm tra:
```bash
flutter --version
# Mong đợi: Flutter 3.44.x • ... • Dart 3.12.x
```
> Nếu báo `flutter: command not found` → xem Phần H1.

### B3. Tải trước công cụ build
```bash
flutter precache
```

---

## PHẦN C — Android (Android Studio + Emulator)

### C1. Cài Android Studio
```bash
brew install --cask android-studio
```
(~1 GB tải.) Mở app: `open -a "Android Studio"`.

### C2. Setup Wizard (lần đầu mở)
- Chọn **Standard** → **Next** → **Finish**. Nó tải Android SDK + emulator + platform (~vài GB, chờ).

### C3. Cài thêm phần bắt buộc cho Flutter
Ở màn hình chào Android Studio → **More Actions** (hoặc ⚙️) → **SDK Manager**:
- Tab **SDK Platforms**: tick **Android 15 (API 35)** (hoặc bản mới nhất) → có thể tick ô "Show Package Details" để chọn *system image*.
- Tab **SDK Tools**: **BẮT BUỘC tick 3 mục** rồi **Apply**:
  - ✅ **Android SDK Command-line Tools (latest)**  ← thiếu cái này `flutter doctor` sẽ báo lỗi
  - ✅ **Android SDK Build-Tools**
  - ✅ **Android Emulator**

### C4. Tạo máy ảo (chọn ảnh ARM cho M-series → nhanh)
**More Actions → Virtual Device Manager → Create Device**:
- Chọn **Pixel 7** (hoặc Pixel bất kỳ) → **Next**.
- Chọn **system image**: **API 35**, cột ABI ưu tiên **`arm64-v8a`** (chạy native trên chip Apple, mượt hơn x86). Nếu chưa tải, bấm ⬇ tải rồi **Next → Finish**.
- Bấm nút ▶ để khởi động máy ảo (mở lên như 1 điện thoại).

### C5. Chấp nhận license
```bash
flutter doctor --android-licenses
# Gõ y + Enter cho tới hết (nhiều lần)
```

---

## PHẦN D — iOS (Xcode + Simulator + CocoaPods)

### D1. Cài Xcode
Cài **Xcode** từ **App Store** (rất nặng ~10 GB, để chạy nền). Sau khi cài xong:
```bash
sudo xcodebuild -license accept
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcodebuild -runFirstLaunch
```
> Chỉ cần Xcode để chạy trên **Simulator**. (Muốn nộp App Store sau này thì cần **Xcode 26+**, nhưng để code/test thì bản mới nhất App Store là đủ.)

### D2. Mở iOS Simulator
```bash
open -a Simulator
```
→ Hiện 1 iPhone giả lập. (Đổi máy: menu **File → Open Simulator → iOS 18 → iPhone 15**.)

### D3. CocoaPods (⚠ nguồn lỗi phổ biến nhất trên Apple Silicon)
Cài **qua Homebrew** (đừng dùng `sudo gem install` — hay lỗi Ruby hệ thống):
```bash
brew install cocoapods
which ruby     # Mong đợi: /opt/homebrew/opt/ruby/bin/ruby (Ruby của Homebrew)
pod --version  # Mong đợi in ra số phiên bản, vd 1.15.x
```

---

## PHẦN E — Kiểm tra tổng thể
```bash
flutter doctor -v
```
Đọc từng dòng, sửa dòng có **✗** (dấu ✓ là ổn, dấu **!** là cảnh báo có thể bỏ qua):
- `[✓] Flutter` — OK nếu Phần B đúng.
- `[✓] Android toolchain` — cần Phần C (nếu ✗ "cmdline-tools component is missing" → cài lại C3; nếu "licenses not accepted" → chạy lại C5).
- `[✓] Xcode` — cần Phần D (nếu báo CocoaPods → làm D3).
- `[✓] VS Code` / `[✓] Android Studio` — có 1 trong 2 là được.
- `[!] Chrome`, `[!] Connected device` — **bỏ qua** (không cần cho app này).

Khi Flutter + (Android **hoặc** Xcode) đều ✓ là chạy được.

---

## PHẦN F — IDE (VS Code — bạn đang dùng cho Angular)
- Mở VS Code → tab Extensions (Cmd+Shift+X) → gõ **Flutter** → **Install** (nó tự cài luôn **Dart**).
- Chọn thiết bị: góc dưới phải VS Code bấm vào tên device, hoặc `Cmd+Shift+P → Flutter: Select Device`.
- **F5** để chạy/debug; lưu file là **hot reload** tức thì.

---

## PHẦN G — Chạy app Dididi Mobile

### G1. Sinh khung native (chỉ làm 1 lần)
Project này hiện **chỉ có mã Dart** (`lib/`), chưa có thư mục `android/ ios/`. Sinh ở thư mục tạm để **không đè code**:
```bash
cd "/Users/jay/Studying/Spring tools"
flutter create --org com.dididi --project-name dididi_mobile _shell_tmp
cp -R _shell_tmp/android _shell_tmp/ios dididi_mobile/
cp _shell_tmp/.metadata _shell_tmp/analysis_options.yaml dididi_mobile/ 2>/dev/null
rm -rf _shell_tmp
```

### G2. Cài dependency + kiểm tra biên dịch
```bash
cd dididi_mobile
flutter pub get        # tải các package (riverpod, dio, go_router...)
flutter analyze        # Mong đợi: "No issues found!" (nếu có lỗi -> gửi mình log)
```

### G3. Bật backend rồi chạy app
1. Mở **STS**, chạy `dididi-booking-platform` (port **8080**). Kiểm tra: mở `http://localhost:8080` trên trình duyệt thấy trang Dididi.
2. Mở sẵn 1 thiết bị (iOS Simulator ở D2 **hoặc** Android emulator ở C4), rồi:
```bash
flutter devices        # liệt kê thiết bị đang mở
flutter run            # chạy lên thiết bị đó
```
Khi app chạy, tại terminal gõ **`r`** = hot reload, **`R`** = hot restart, **`q`** = thoát.

### G4. Địa chỉ backend (`lib/core/config/env.dart`)
- **Android emulator** → app tự dùng `http://10.0.2.2:8080` (alias trỏ localhost của máy Mac). *KHÔNG* dùng `localhost` trên Android emulator.
- **iOS Simulator** → `http://localhost:8080` (dùng được luôn).
- **Điện thoại thật** → sửa `env.dart` thành IP LAN của Mac (xem bằng `ipconfig getifaddr en0`, vd `http://192.168.1.10:8080`); Mac và điện thoại **cùng Wi-Fi**.

---

## PHẦN H — Lỗi hay gặp & cách sửa

**H1. `flutter: command not found`**
PATH chưa nạp. Chạy `source ~/.zshrc`. Nếu vẫn lỗi, kiểm tra dòng export có đúng đường dẫn `~/development/flutter/bin` không: `cat ~/.zshrc | grep flutter`.

**H2. iOS build lỗi Pods / "CocoaPods not installed"**
```bash
which ruby     # phải là /opt/homebrew/opt/ruby/bin/ruby; nếu không -> brew install ruby, thêm PATH
brew install cocoapods
cd dididi_mobile/ios && pod install && cd ..
flutter run
```

**H3. Android: "cmdline-tools component is missing"**
Mở Android Studio → SDK Manager → SDK Tools → tick **Android SDK Command-line Tools (latest)** → Apply. Rồi `flutter doctor` lại.

**H4. Android: "Android license status unknown"**
```bash
flutter doctor --android-licenses   # gõ y hết
```

**H5. Emulator Android chậm / không mở**
Dùng **system image arm64-v8a** (Phần C4) thay vì x86 trên máy Apple Silicon.

**H6. App mở được nhưng gọi API lỗi mạng / trắng danh sách**
- Backend chưa chạy (mở `http://localhost:8080` kiểm tra).
- Android emulator đang trỏ `localhost` → phải là `10.0.2.2` (đã cấu hình sẵn, đừng sửa lại thành localhost).
- Máy thật khác Wi-Fi với Mac, hoặc IP LAN sai.

**H7. iOS máy thật báo lỗi ký (signing)**
Mở `dididi_mobile/ios/Runner.xcworkspace` bằng Xcode → chọn target **Runner** → tab **Signing & Capabilities** → tick **Automatically manage signing** → chọn **Team** (đăng nhập Apple ID free) → chạy lại.

**H8. `flutter run` không thấy thiết bị**
Phải mở simulator/emulator **trước**, rồi `flutter devices` để chắc chắn nó xuất hiện.

---

### Thời gian & dung lượng ước tính
- Xcode ~10 GB (App Store), Android Studio + SDK ~6–8 GB, Flutter ~2 GB. Tổng ~1 giờ (chủ yếu chờ tải).
- Muốn nhanh nhất để thấy app: **Phần A → B → D (iOS) → E → F → G**. Android cài sau cũng được.
