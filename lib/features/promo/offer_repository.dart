import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_providers.dart';
import 'offer_models.dart';

final offerRepositoryProvider =
    Provider<OfferRepository>((ref) => OfferRepository(ref.watch(apiClientProvider)));

/// Ưu đãi của tôi. CHỈ gọi khi đã đăng nhập (endpoint yêu cầu JWT) — màn khách
/// không watch provider này để tránh 401 vô ích.
final myOffersProvider = FutureProvider<List<Offer>>(
  (ref) => ref.read(offerRepositoryProvider).myOffers(),
);

/// Số ưu đãi còn dùng được — cho banner trang chủ (im lặng nếu lỗi/chưa đăng nhập).
final usableOfferCountProvider = FutureProvider<int>((ref) async {
  try {
    final list = await ref.watch(myOffersProvider.future);
    return list.where((o) => o.usable).length;
  } catch (_) {
    return 0;
  }
});

class OfferRepository {
  final ApiClient _api;
  OfferRepository(this._api);

  Future<List<Offer>> myOffers() => _api.getData(
        '/api/v1/offers',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => Offer.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
