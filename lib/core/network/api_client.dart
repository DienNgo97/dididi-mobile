import 'package:dio/dio.dart';

import '../config/env.dart';
import '../device/device_name.dart';
import '../i18n/l10n.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Dio client: tự gắn Bearer token, tự refresh khi 401, và bóc envelope
/// ApiResponse {success, data, message} của backend.
class ApiClient {
  final TokenStorage _storage;
  final void Function()? onSessionExpired;
  late final Dio dio;

  // Gộp nhiều lần refresh 401 xảy ra song song thành MỘT (tránh xoay vòng refresh
  // token khiến các request khác dùng token cũ → bị đăng xuất oan).
  Future<bool>? _refreshing;

  ApiClient(this._storage, {this.onSessionExpired}) {
    dio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.access;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Tên máy để máy chủ ghi vào nhãn phiên đăng nhập (xem device_name.dart).
        // Gắn cho MỌI yêu cầu chứ không riêng lúc đăng nhập, vì token còn được
        // phát lại khi làm mới phiên — lúc đó cũng cần đúng nhãn.
        final ten = await DeviceName.lay();
        if (ten.isNotEmpty) {
          options.headers['X-Device-Name'] = ten;
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final code = e.response?.statusCode;
        final isRefresh = e.requestOptions.path.contains('/api/auth/refresh');
        final alreadyRetried = e.requestOptions.extra['retried'] == true;
        if (code == 401 && !isRefresh && !alreadyRetried) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            // Body multipart (FormData) đã bị tiêu thụ stream → KHÔNG thể phát lại.
            // Token đã mới, để request này thất bại êm; người dùng thử lại là được.
            if (e.requestOptions.data is FormData) {
              return handler.next(e);
            }
            final req = e.requestOptions..extra['retried'] = true;
            final newToken = await _storage.access;
            req.headers['Authorization'] = 'Bearer $newToken';
            try {
              final resp = await dio.fetch(req);
              return handler.resolve(resp);
            } on DioException catch (err) {
              return handler.next(err);
            }
          } else {
            await _storage.clear();
            onSessionExpired?.call();
          }
        }
        handler.next(e);
      },
    ));
  }

  /// Refresh gộp: nếu đang refresh thì các request 401 khác cùng chờ 1 future,
  /// tránh nhiều lần POST /refresh làm xoay token và huỷ phiên hợp lệ.
  Future<bool> _tryRefresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final refresh = await _storage.refresh;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final bare = Dio(BaseOptions(baseUrl: Env.baseUrl));
      final r = await bare.post('/api/auth/refresh', data: {'refreshToken': refresh});
      final data = r.data['data'];
      await _storage.save(
        access: data['accessToken'] as String,
        refresh: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<T> getData<T>(String path,
      {Map<String, dynamic>? query, Map<String, String>? headers, required T Function(dynamic data) parse}) {
    return _send(
        () => dio.get(path,
            queryParameters: query, options: headers == null ? null : Options(headers: headers)),
        parse);
  }

  Future<T> postData<T>(String path,
      {dynamic body, Map<String, dynamic>? query, required T Function(dynamic data) parse}) {
    return _send(() => dio.post(path, data: body, queryParameters: query), parse);
  }

  Future<T> deleteData<T>(String path,
      {Map<String, dynamic>? query, required T Function(dynamic data) parse}) {
    return _send(() => dio.delete(path, queryParameters: query), parse);
  }

  /// POST multipart (đăng bài, gửi ảnh...). Dio tự set boundary khi data là FormData.
  Future<T> postMultipart<T>(String path, FormData form,
      {required T Function(dynamic data) parse}) {
    return _send(() => dio.post(path, data: form), parse);
  }

  /// Tải bytes (ảnh cần JWT) qua Dio đã gắn token + tự refresh.
  Future<List<int>> getBytes(String path) async {
    final res =
        await dio.get<List<int>>(path, options: Options(responseType: ResponseType.bytes));
    return res.data ?? const [];
  }

  Future<T> _send<T>(Future<Response> Function() call, T Function(dynamic) parse) async {
    try {
      final res = await call();
      final body = res.data;
      final data = (body is Map && body.containsKey('data')) ? body['data'] : body;
      return parse(data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final code = (data['code'] ?? data['error'] ?? 'ERROR').toString();
      final msg = (data['message'] ?? 'Đã xảy ra lỗi, vui lòng thử lại').toString();
      return ApiException(code, msg, e.response?.statusCode);
    }
    // KHÔNG dùng e.message của Dio: đó là câu tiếng Anh dành cho lập trình viên
    // ("The connection errored: Connection failed This indicates an error which
    // most likely cannot be solved by the library."). Trước ngày 24/08/2026 nó
    // được nhét thẳng vào đây rồi hiện nguyên văn lên mặt người dùng ở cả 44
    // màn hình.
    //
    // Gắn CẢ mã phân loại lẫn câu đã dịch: mã để tầng trên xử lý theo loại,
    // còn câu để những chỗ hiển thị thẳng `e.message` (các snackbar) không bị
    // trống trơn.
    final ma = _maLoiMang(e);
    return ApiException(ma, trg(ma == 'TIMEOUT' ? 'err.timeout' : 'err.offline'), e.response?.statusCode);
  }

  /// Phân loại lỗi tầng mạng thành mã ổn định, không phụ thuộc ngôn ngữ.
  String _maLoiMang(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'TIMEOUT';
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return 'OFFLINE';
      default:
        return 'NETWORK';
    }
  }
}
