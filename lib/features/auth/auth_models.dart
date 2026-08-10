/// Kết quả đăng nhập (LoginResponse của backend).
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String email;
  final String role;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    required this.role,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        email: (j['email'] ?? '') as String,
        role: (j['role'] ?? 'CUSTOMER') as String,
      );
}

/// Tài khoản đang đăng nhập (UserDto: /api/auth/me).
class AppUser {
  final int id;
  final String email;
  final String? fullName;
  final String role;

  AppUser({required this.id, required this.email, this.fullName, required this.role});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] as num).toInt(),
        email: (j['email'] ?? '') as String,
        fullName: j['fullName'] as String?,
        role: (j['role'] ?? 'CUSTOMER') as String,
      );
}
