import '../../core/network/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<AuthTokens> login(String email, String password) => _api.postData(
        '/api/auth/login',
        body: {'email': email, 'password': password},
        parse: (d) => AuthTokens.fromJson(d as Map<String, dynamic>),
      );

  Future<void> register(String email, String password, String fullName) =>
      _api.postData<void>(
        '/api/auth/register',
        body: {'email': email, 'password': password, 'fullName': fullName},
        parse: (_) {},
      );

  Future<AppUser> me() => _api.getData(
        '/api/auth/me',
        parse: (d) => AppUser.fromJson(d as Map<String, dynamic>),
      );

  Future<void> logout(String? refreshToken) => _api.postData<void>(
        '/api/auth/logout',
        body: {'refreshToken': refreshToken ?? ''},
        parse: (_) {},
      );

  /// Đăng xuất khỏi tất cả thiết bị (thu hồi mọi refresh token).
  Future<void> logoutAll() => _api.postData<void>(
        '/api/auth/logout-all',
        parse: (_) {},
      );

  /// Đăng nhập bằng Google: gửi ID token (lấy từ google_sign_in) -> nhận JWT.
  Future<AuthTokens> googleLogin(String idToken) => _api.postData(
        '/api/auth/google',
        body: {'idToken': idToken},
        parse: (d) => AuthTokens.fromJson(d as Map<String, dynamic>),
      );

  /// Gửi mã OTP đăng nhập tới email.
  Future<void> requestOtp(String email) => _api.postData<void>(
        '/api/auth/otp/request',
        body: {'email': email},
        parse: (_) {},
      );

  /// Xác thực OTP email -> nhận JWT.
  Future<AuthTokens> verifyOtp(String email, String code) => _api.postData(
        '/api/auth/otp/verify',
        body: {'email': email, 'code': code},
        parse: (d) => AuthTokens.fromJson(d as Map<String, dynamic>),
      );

  /// Quên mật khẩu: gửi email chứa token đặt lại.
  Future<void> forgotPassword(String email) => _api.postData<void>(
        '/api/auth/forgot-password',
        body: {'email': email},
        parse: (_) {},
      );

  /// Đặt lại mật khẩu bằng token nhận qua email.
  Future<void> resetPassword(String token, String newPassword) => _api.postData<void>(
        '/api/auth/reset-password',
        body: {'token': token, 'newPassword': newPassword},
        parse: (_) {},
      );
}
