import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_providers.dart';
import 'profile_models.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(apiClientProvider)));

/// Hồ sơ của tôi (tự tải lại khi invalidate).
final profileProvider = FutureProvider<Profile>((ref) => ref.read(profileRepositoryProvider).me());

class ProfileRepository {
  final ApiClient _api;
  ProfileRepository(this._api);

  Future<Profile> me() => _api.getData(
        '/api/v1/profile/me',
        parse: (d) => Profile.fromJson(d as Map<String, dynamic>),
      );

  Future<void> updateName(String fullName) => _api.postData<void>(
        '/api/v1/profile/name',
        body: {'fullName': fullName},
        parse: (_) {},
      );

  /// Cập nhật ngày sinh (yyyy-MM-dd) — để chương trình khuyến mãi sinh nhật tặng voucher.
  /// Gửi chuỗi rỗng = xoá ngày sinh.
  Future<void> updateBirthDate(String yyyyMmDd) => _api.postData<void>(
        '/api/v1/profile/birthday',
        body: {'birthDate': yyyyMmDd},
        parse: (_) {},
      );

  /// Đổi ảnh đại diện. Backend ghi vào ĐÚNG chỗ hồ sơ Cộng đồng đang dùng nên hai bên
  /// không bao giờ lệch nhau. Trả về URL mới (đã kèm ?v= để phá cache).
  Future<String?> uploadAvatar(MultipartFile image) => _api.postMultipart(
        '/api/v1/profile/avatar',
        FormData.fromMap({'image': image}),
        parse: (d) => (d is Map) ? d['avatarUrl'] as String? : null,
      );

  Future<void> removeAvatar() =>
      _api.deleteData<void>('/api/v1/profile/avatar', parse: (_) {});

  Future<void> changePassword(String currentPassword, String newPassword) => _api.postData<void>(
        '/api/v1/profile/password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
        parse: (_) {},
      );

  Future<void> sendPhoneOtp(String phone) => _api.postData<void>(
        '/api/v1/profile/phone/send',
        body: {'phone': phone},
        parse: (_) {},
      );

  Future<void> confirmPhone(String code) => _api.postData<void>(
        '/api/v1/profile/phone/confirm',
        body: {'code': code},
        parse: (_) {},
      );

  Future<void> unlinkGoogle() =>
      _api.postData<void>('/api/v1/profile/google/unlink', parse: (_) {});

  Future<void> resendActivation() =>
      _api.postData<void>('/api/v1/profile/email/resend', parse: (_) {});

  Future<void> closeAccount(String password) => _api.postData<void>(
        '/api/v1/profile/close',
        body: {'password': password},
        parse: (_) {},
      );
}
