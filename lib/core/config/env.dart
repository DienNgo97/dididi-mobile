import 'package:flutter/foundation.dart';

/// Cấu hình môi trường.
///
/// NGUYÊN TẮC: TỰ THÍCH ỨNG — chạy local không phải khai gì, ra mạng chỉ truyền 1 tham số
/// lúc chạy/build, KHÔNG sửa code (tránh cảnh sửa qua sửa lại rồi quên đổi ngược).
class Env {
  /// Địa chỉ backend truyền lúc chạy/build, để trống thì dùng mặc định local bên dưới.
  ///
  /// Máy thật cùng wifi:
  ///   flutter run --dart-define=API_BASE=http://192.168.1.10:8080
  /// Qua Internet (Cloudflare Tunnel — xem HUONG-DAN-DUA-LEN-INTERNET-DE-KIEM-THU.md):
  ///   flutter run --dart-define=API_BASE=https://backend-abc.trycloudflare.com
  /// Build APK gửi người khác cài:
  ///   flutter build apk --dart-define=API_BASE=https://backend-abc.trycloudflare.com
  static const String _override = String.fromEnvironment('API_BASE');

  /// URL backend Spring Boot.
  /// - Có `--dart-define=API_BASE` -> dùng đúng giá trị đó (máy thật / LAN / tunnel).
  /// - Không có -> mặc định chạy máy ảo trên cùng máy dev:
  ///     Android emulator dùng 10.0.2.2 (bí danh trỏ về localhost của máy tính),
  ///     iOS simulator / web dùng localhost.
  static String get baseUrl {
    if (_override.isNotEmpty) {
      return _override.endsWith('/')
          ? _override.substring(0, _override.length - 1)
          : _override;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// true khi đang trỏ ra ngoài (LAN/Internet) — tiện để hiện cảnh báo hoặc bật log gọn hơn.
  static bool get isRemote => _override.isNotEmpty;

  /// OAuth Web Client ID của Google (dùng làm `serverClientId` cho google_sign_in
  /// để nhận được ID token có `aud` khớp backend). Lấy từ Google Cloud Console
  /// (OAuth 2.0 Client IDs → loại "Web application"). Để trống nếu chưa cấu hình.
  static const String googleServerClientId =
      '349258992830-9ud6atbahsfng57jkqrt98cv6jgldq80.apps.googleusercontent.com';
}
