/// Hồ sơ người dùng (khớp GET /api/v1/profile/me).
class Profile {
  final int id;
  final String email;
  final String? fullName;
  final String? phone;
  final bool phoneVerified;
  final String role;
  final bool emailVerified;

  /// Ngày sinh — dùng cho chương trình khuyến mãi sinh nhật (null = chưa khai báo).
  final DateTime? birthDate;

  /// Đã nhập ngày sinh rồi thì KHOÁ, chỉ admin sửa hộ được (chống lạm dụng voucher sinh nhật).
  final bool birthDateLocked;

  /// Ảnh đại diện — dùng chung với hồ sơ Cộng đồng, null = hiện chữ cái đầu.
  final String? avatarUrl;

  Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.phoneVerified = false,
    required this.role,
    this.emailVerified = false,
    this.birthDate,
    this.birthDateLocked = false,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: (j['id'] as num).toInt(),
        email: (j['email'] ?? '') as String,
        fullName: j['fullName'] as String?,
        phone: j['phone'] as String?,
        phoneVerified: (j['phoneVerified'] ?? false) as bool,
        role: (j['role'] ?? '') as String,
        emailVerified: (j['emailVerified'] ?? false) as bool,
        birthDate: (j['birthDate'] == null || '${j['birthDate']}'.isEmpty)
            ? null
            : DateTime.tryParse('${j['birthDate']}'),
        // Backend cu (chua merge nhanh birthdate) khong tra co nay -> suy ra tu chinh ngay sinh,
        // vi luat la "co ngay sinh = da khoa". Merge nhanh do xong thi lay thang tu server.
        birthDateLocked: j.containsKey('birthDateLocked')
            ? j['birthDateLocked'] == true
            : j['birthDate'] != null,
        avatarUrl: (j['avatarUrl'] as String?)?.isEmpty == true ? null : j['avatarUrl'] as String?,
      );
}
