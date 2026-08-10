import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_providers.dart';

final vendorRepositoryProvider =
    Provider<VendorRepository>((ref) => VendorRepository(ref.watch(apiClientProvider)));

/// Đăng ký làm nhà cung cấp (bán phòng). Tạo tài khoản VENDOR + khách sạn DIRECT ở
/// trạng thái CHỜ ADMIN DUYỆT — dùng chung REST public POST /api/auth/vendor-register với web.
class VendorRepository {
  final ApiClient _api;
  VendorRepository(this._api);

  Future<void> register({
    required String email,
    required String password,
    String? fullName,
    String? phone,
    required String hotelName,
    String? city,
    String? address,
    int? starRating,
  }) =>
      _api.postData<void>(
        '/api/auth/vendor-register',
        body: {
          'email': email,
          'password': password,
          if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'hotelName': hotelName,
          if (city != null && city.isNotEmpty) 'city': city,
          if (address != null && address.isNotEmpty) 'address': address,
          if (starRating != null) 'starRating': starRating,
        },
        parse: (_) {},
      );
}
