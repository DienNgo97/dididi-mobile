import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../core/network/api_client.dart';
import '../hotels/hotel_models.dart';

final wishlistRepositoryProvider =
    Provider<WishlistRepository>((ref) => WishlistRepository(ref.watch(apiClientProvider)));

class WishlistRepository {
  final ApiClient _api;
  WishlistRepository(this._api);

  Future<List<Hotel>> list() => _api.getData(
        '/api/v1/wishlist',
        parse: (d) =>
            ((d as List?) ?? const []).map((e) => Hotel.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<bool> toggle(int hotelId) => _api.postData(
        '/api/v1/wishlist/$hotelId/toggle',
        parse: (d) => (d as Map)['wishlisted'] == true,
      );

  Future<bool> check(int hotelId) => _api.getData(
        '/api/v1/wishlist/$hotelId',
        parse: (d) => (d as Map)['wishlisted'] == true,
      );
}

/// Danh sách khách sạn đã lưu.
final wishlistProvider = FutureProvider<List<Hotel>>((ref) => ref.read(wishlistRepositoryProvider).list());

/// Trạng thái wishlist của 1 khách sạn.
final wishlistCheckProvider =
    FutureProvider.family<bool, int>((ref, id) => ref.read(wishlistRepositoryProvider).check(id));

/// Tập id khách sạn đã lưu (1 lần gọi) — để đánh dấu ♥ trên list mà không gọi từng cái.
final wishlistedIdsProvider = FutureProvider<Set<int>>((ref) async {
  final hotels = await ref.read(wishlistRepositoryProvider).list();
  return hotels.map((h) => h.id).toSet();
});
