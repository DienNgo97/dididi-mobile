import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Tên máy để gửi kèm mỗi yêu cầu, phục vụ màn "Thiết bị đăng nhập".
///
/// Vì sao cần: máy chủ suy nhãn thiết bị từ `User-Agent`, mà Dio gửi chuỗi mặc
/// định kiểu "Dart/3.9 (dart:io)" — không có tên máy, không có cả hệ điều hành.
/// Hậu quả là mọi phiên đăng nhập từ ứng dụng đều mang đúng một nhãn giống hệt
/// nhau, khiến danh sách phiên mất tác dụng: người dùng không thể nhận ra phiên
/// lạ để thu hồi. Phát hiện khi chạy TC-M-27 ngày 25/08/2026.
///
/// Đọc MỘT LẦN rồi giữ lại, vì thông tin máy không đổi trong một phiên chạy và
/// truy vấn nền tảng tốn hơn nhiều so với đọc một biến.
class DeviceName {
  DeviceName._();

  static String? _daDoc;

  /// Nhãn dạng "Pixel 7 - Android 14" / "iPhone16,1 - iOS 18.2" / "Chrome - Web".
  /// CHỈ dùng ASCII — xem giải thích ở _gon().
  /// Không bao giờ ném lỗi: hỏng thì trả chuỗi rỗng để nơi gọi bỏ qua header.
  static Future<String> lay() async {
    if (_daDoc != null) return _daDoc!;
    // Hạn chờ 2 giây: hàm này nằm trên đường đi của MỌI yêu cầu mạng, nên nếu
    // kênh giao tiếp với nền tảng treo thì nó sẽ chặn cả việc đăng nhập.
    // Không có tên máy chỉ làm nhãn phiên kém đẹp; không đăng nhập được mới là
    // hỏng thật. Nhớ luôn kết quả để không phải chờ lại lần sau.
    _daDoc = await _doc().timeout(const Duration(seconds: 2), onTimeout: () => '');
    return _daDoc!;
  }

  static Future<String> _doc() async {
    try {
      final info = DeviceInfoPlugin();

      if (kIsWeb) {
        final w = await info.webBrowserInfo;
        return _gon('${w.browserName.name} - Web');
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final a = await info.androidInfo;
          // a.model là tên thương mại (vd "Pixel 7"); version.release là "14".
          return _gon('${a.model} - Android ${a.version.release}');
        case TargetPlatform.iOS:
          final i = await info.iosInfo;
          // utsname.machine là mã máy (vd "iPhone16,1"); i.name thân thiện hơn.
          return _gon('${i.utsname.machine} - iOS ${i.systemVersion}');
        case TargetPlatform.macOS:
          final m = await info.macOsInfo;
          return _gon('${m.model} - macOS ${m.osRelease}');
        case TargetPlatform.windows:
          final w = await info.windowsInfo;
          return _gon('${w.computerName} - Windows');
        case TargetPlatform.linux:
          final l = await info.linuxInfo;
          return _gon('${l.prettyName} - Linux');
        case TargetPlatform.fuchsia:
          return '';
      }
    } catch (_) {
      // Thiếu quyền, nền tảng lạ, gói chưa nạp… — không có tên máy vẫn phải
      // đăng nhập được. Máy chủ sẽ tự suy từ User-Agent như trước.
      return '';
    }
  }

  /// Gọn lại và ép về ASCII thuần.
  ///
  /// BẮT BUỘC phải ASCII: giá trị này đi vào header HTTP, mà thư viện HTTP của
  /// Dart từ chối ký tự ngoài bảng ASCII và ném lỗi NGAY KHI dựng yêu cầu.
  /// Dio bọc lỗi đó thành lỗi kết nối, nên triệu chứng nhìn giống hệt mất mạng —
  /// rất dễ truy nhầm hướng. Bản đầu tôi dùng dấu "·" làm dấu phân cách và
  /// làm hỏng MỌI yêu cầu mạng (26/08/2026).
  ///
  /// Máy chủ cũng cắt ở 60 ký tự nên cắt sẵn ở đây cho khớp.
  static String _gon(String s) {
    final t = s
        .replaceAll('·', '-')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '') // bỏ mọi ký tự ngoài ASCII in được
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return t.length <= 60 ? t : t.substring(0, 60).trim();
  }
}
