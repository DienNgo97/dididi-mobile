import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
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
    if (await _storage.hasToken) {
      try {
        final me = await _repo.me();
        state = AuthState(AuthStatus.authenticated, email: me.email, role: me.role);
      } catch (_) {
        await _storage.clear();
        state = const AuthState(AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(AuthStatus.unauthenticated);
    }
  }

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
