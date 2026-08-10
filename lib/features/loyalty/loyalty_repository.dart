import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../core/network/api_client.dart';
import 'loyalty_models.dart';

final loyaltyRepositoryProvider =
    Provider<LoyaltyRepository>((ref) => LoyaltyRepository(ref.watch(apiClientProvider)));

class LoyaltyRepository {
  final ApiClient _api;
  LoyaltyRepository(this._api);

  Future<LoyaltyAccount> me() => _api.getData(
        '/api/v1/loyalty/me',
        parse: (d) => LoyaltyAccount.fromJson(d as Map<String, dynamic>),
      );

  Future<List<RedeemedVoucher>> vouchers() => _api.getData(
        '/api/v1/loyalty/vouchers',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => RedeemedVoucher.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Đổi điểm lấy voucher; trả về mã voucher.
  Future<String> redeem(int points) => _api.postData(
        '/api/v1/loyalty/redeem',
        query: {'points': points},
        parse: (d) => ((d as Map)['code'] ?? '').toString(),
      );
}

final loyaltyAccountProvider = FutureProvider<LoyaltyAccount>((ref) => ref.read(loyaltyRepositoryProvider).me());
final loyaltyVouchersProvider =
    FutureProvider<List<RedeemedVoucher>>((ref) => ref.read(loyaltyRepositoryProvider).vouchers());
