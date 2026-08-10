import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_providers.dart';

/// Xử lý message khi app ở nền/đã tắt (phải là hàm top-level + @pragma).
/// OS tự hiển thị notification nếu payload có phần 'notification'.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

class PushService {
  final Ref _ref;
  PushService(this._ref);
  bool _done = false;

  /// Gọi sau khi đăng nhập (đã có JWT): xin quyền + lấy FCM token + đăng ký lên backend.
  /// Bỏ qua trên web (chỉ Android/iOS dùng FCM ở bản này).
  Future<void> setup() async {
    debugPrint('[push] setup() gọi (kIsWeb=$kIsWeb, done=$_done)');
    if (kIsWeb || _done) return;
    _done = true;
    try {
      final fm = FirebaseMessaging.instance;
      final perm = await fm.requestPermission(alert: true, badge: true, sound: true);
      debugPrint('[push] quyền: ${perm.authorizationStatus}');
      await fm.getAPNSToken(); // iOS cần; Android trả null (vô hại)
      final token = await fm.getToken();
      debugPrint('[push] FCM token: $token');
      if (token != null) await _register(token);
      fm.onTokenRefresh.listen(_register);
      FirebaseMessaging.onMessage.listen((m) {
        // App đang mở: có thể hiện banner/SnackBar tại đây (tuỳ chọn).
      });
    } catch (e, st) {
      debugPrint('[push] setup LỖI: $e');
      debugPrint('$st');
      _done = false; // cho phép thử lại lần sau nếu init lỗi
    }
  }

  Future<void> _register(String token) async {
    try {
      await _ref.read(apiClientProvider).postData<void>(
            '/api/v1/devices/token',
            body: {'token': token, 'platform': 'FCM'},
            parse: (_) {},
          );
      debugPrint('[push] đã gửi token lên backend OK');
    } catch (e) {
      debugPrint('[push] gửi token LỖI: $e');
    }
  }
}
