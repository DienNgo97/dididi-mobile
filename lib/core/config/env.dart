import 'package:flutter/foundation.dart';

/// Cấu hình môi trường. Đổi [baseUrl] khi deploy backend thật.
class Env {
  /// URL backend Spring Boot.
  /// - Android emulator: dùng 10.0.2.2 để trỏ về localhost của máy tính.
  /// - iOS simulator / web: localhost.
  /// - Máy thật: đổi thành IP LAN của máy chạy backend (vd http://192.168.1.x:8080).
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// OAuth Web Client ID của Google (dùng làm `serverClientId` cho google_sign_in
  /// để nhận được ID token có `aud` khớp backend). Lấy từ Google Cloud Console
  /// (OAuth 2.0 Client IDs → loại "Web application"). Để trống nếu chưa cấu hình.
  static const String googleServerClientId =
      '349258992830-9ud6atbahsfng57jkqrt98cv6jgldq80.apps.googleusercontent.com';
}
