import 'package:dio/dio.dart';

import '../i18n/l10n.dart';
import '../network/api_exception.dart';

/// Đổi một lỗi bất kỳ thành câu tiếng người, đúng ngôn ngữ đang chọn.
///
/// Vì sao cần: trước đây 44 màn hình đều truyền thẳng `e.toString()` vào
/// [ErrorView]. Khi mất mạng, người dùng Việt nhận nguyên văn tiếng Anh của
/// thư viện Dio: "The connection errored: Connection failed This indicates an
/// error which most likely cannot be solved by the library." — vô nghĩa với
/// người dùng, và cũng chẳng giúp gì cho lập trình viên.
/// Phát hiện khi chạy TC-M-13 (mạng yếu) trên máy ảo Android ngày 24/08/2026.
///
/// [ApiException] thì giữ nguyên `message`, vì đó là câu do CHÍNH backend soạn
/// và đã được dịch sẵn — ví dụ "Phòng vừa hết chỗ". Đừng nuốt mất nó.
String thongDiepLoi(Object? e) {
  if (e is ApiException) {
    // Mã do api_client gắn cho lỗi tầng mạng (không có câu chữ đi kèm).
    switch (e.code) {
      case 'OFFLINE':
        return trg('err.offline');
      case 'TIMEOUT':
        return trg('err.timeout');
      case 'NETWORK':
        return trg('err.offline');
    }
    if (e.status == 401 || e.status == 403) return trg('err.session');
    if (e.status != null && e.status! >= 500) return trg('err.server');
    // Còn lại là lỗi NGHIỆP VỤ do backend soạn (vd "Phòng vừa hết chỗ") —
    // đã đúng ngôn ngữ người dùng, giữ nguyên văn, đừng nuốt mất.
    if (e.message.trim().isNotEmpty) return e.message;
    return trg('common.error');
  }

  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return trg('err.offline');
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return trg('err.timeout');
      case DioExceptionType.badResponse:
        final sc = e.response?.statusCode ?? 0;
        if (sc == 401 || sc == 403) return trg('err.session');
        if (sc >= 500) return trg('err.server');
        return trg('common.error');
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        // unknown thường bọc SocketException khi máy không có mạng.
        // KHÔNG dùng `is SocketException` vì phải import dart:io, mà dart:io
        // không tồn tại trên Flutter web -> hỏng bản chạy -d web-server.
        // So khớp theo TÊN kiểu nên chạy được trên mọi nền tảng.
        if (_laLoiMang(e.error)) return trg('err.offline');
        return trg('common.error');
    }
  }

  if (_laLoiMang(e)) return trg('err.offline');

  return trg('common.error');
}

/// Nhận diện lỗi tầng mạng mà không cần import dart:io (xem giải thích ở trên).
bool _laLoiMang(Object? e) {
  if (e == null) return false;
  final ten = e.runtimeType.toString();
  return ten.contains('SocketException') ||
      ten.contains('HandshakeException') ||
      ten.contains('HttpException');
}
