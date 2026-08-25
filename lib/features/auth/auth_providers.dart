import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import 'auth_repository.dart';

/// Trạng thái phiên đăng nhập.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? role;
  const AuthState(this.status, {this.email, this.role});
}

/// ApiClient dùng chung (tự refresh JWT; khi hết phiên -> báo AuthController).
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(
    storage,
    onSessionExpired: () => ref.read(authControllerProvider.notifier).sessionExpired(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    _bootstrap();
    return const AuthState(AuthStatus.unknown);
  }

  Future<void> _bootstrap() async {
    if (!await _storage.hasToken) {
      state = const AuthState(AuthStatus.unauthenticated);
      return;
    }
    try {
      final me = await _repo.me();
      state = AuthState(AuthStatus.authenticated, email: me.email, role: me.role);
    } on ApiException catch (e) {
      // PHẢI phân biệt hai chuyện hoàn toàn khác nhau:
      //
      //   1. Máy chủ nói token không còn hợp lệ (401/403)  -> xoá là đúng.
      //   2. Chưa hỏi được máy chủ vì không có mạng        -> xoá là SAI.
      //
      // Trước ngày 24/08/2026 chỗ này dùng `catch (_)` nên gộp cả hai: mở app
      // trong thang máy, trên máy bay hay chỗ sóng yếu là mất phiên đăng nhập
      // VĨNH VIỄN, mạng về cũng phải đăng nhập lại. Phát hiện khi chạy TC-M-13
      // trên máy ảo Android — mỗi lần hot restart lúc tắt mạng đều âm thầm
      // xoá token.
      if (_laLoiMang(e)) {
        // Giữ token lại. Người dùng tạm thấy trạng thái khách, nhưng lần mở
        // sau có mạng là vào thẳng, không phải đăng nhập lại.
        state = const AuthState(AuthStatus.unauthenticated);
      } else {
        await _storage.clear();
        state = const AuthState(AuthStatus.unauthenticated);
      }
    } catch (_) {
      // Lỗi lạ không rõ nguồn gốc: giữ token cho an toàn, thà bắt người dùng
      // bấm đăng nhập một lần còn hơn xoá mất phiên của họ.
      state = const AuthState(AuthStatus.unauthenticated);
    }
  }

  /// Lỗi thuộc tầng mạng chứ không phải máy chủ từ chối.
  /// Mã do ApiClient gắn khi bọc DioException.
  bool _laLoiMang(ApiException e) =>
      e.code == 'OFFLINE' || e.code == 'TIMEOUT' || e.code == 'NETWORK';

  Future<void> login(String email, String password) async {
    final t = await _repo.login(email, password);
    await _storage.save(access: t.accessToken, refresh: t.refreshToken);
    state = AuthState(AuthStatus.authenticated, email: t.email, role: t.role);
  }

  /// Đăng ký -> tài khoản ở trạng thái chờ kích hoạt email (KHÔNG auto-login).
  Future<void> register(String email, String password, String fullName) =>
      _repo.register(email, password, fullName);

  Future<void> logout() async {
    try {
      await _repo.logout(await _storage.refresh);
    } catch (_) {}
    await _storage.clear();
    state = const AuthState(AuthStatus.unauthenticated);
  }

  /// Đăng xuất khỏi TẤT CẢ thiết bị: thu hồi mọi refresh token trên máy chủ,
  /// sau đó xoá phiên cục bộ.
  Future<void> logoutAllDevices() async {
    try {
      await _repo.logoutAll();
    } catch (_) {}
    await _storage.clear();
    state = const AuthState(AuthStatus.unauthenticated);
  }

  /// Đăng nhập bằng Google ID token (đã lấy từ google_sign_in ở màn Login).
  Future<void> loginWithGoogle(String idToken) async {
    final t = await _repo.googleLogin(idToken);
    await _storage.save(access: t.accessToken, refresh: t.refreshToken);
    state = AuthState(AuthStatus.authenticated, email: t.email, role: t.role);
  }

  /// Đăng nhập bằng OTP email: xác thực mã -> lưu token -> authenticated.
  Future<void> loginWithOtp(String email, String code) async {
    final t = await _repo.verifyOtp(email, code);
    await _storage.save(access: t.accessToken, refresh: t.refreshToken);
    state = AuthState(AuthStatus.authenticated, email: t.email, role: t.role);
  }

  void sessionExpired() => state = const AuthState(AuthStatus.unauthenticated);
}
