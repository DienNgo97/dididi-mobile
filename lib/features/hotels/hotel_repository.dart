import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import 'hotel_models.dart';
import 'room_models.dart';

final hotelRepositoryProvider =
    Provider<HotelRepository>((ref) => HotelRepository(ref.watch(apiClientProvider)));

/// Một trang kết quả khách sạn (dữ liệu x5: ~1.790 KS nên bắt buộc phân trang).
class HotelPage {
  final List<Hotel> items;
  final int page;
  final bool hasMore;
  final int total;
  const HotelPage({required this.items, required this.page, required this.hasMore, required this.total});
}

class HotelRepository {
  final ApiClient _api;
  HotelRepository(this._api);

  /// Một trang khách sạn. `q` = tìm full-text (Meilisearch: không dấu / sai chính tả vẫn ra),
  /// `city` = lọc theo thành phố. Trả kèm cờ còn trang sau để màn hình cuộn vô tận.
  Future<HotelPage> page({String? city, String? q, String? sort, int page = 0, int size = 20}) => _api.getData(
        '/api/v1/hotels',
        query: {
          'page': page,
          'size': size,
          if (q != null && q.isNotEmpty) 'q': q,
          if (sort != null && sort.isNotEmpty) 'sort': sort,
          if ((q == null || q.isEmpty) && city != null && city.isNotEmpty) 'city': city,
        },
        parse: (d) {
          final m = d as Map<String, dynamic>;
          final content = (m['content'] as List?) ?? const [];
          final items = content.map((e) => Hotel.fromJson(e as Map<String, dynamic>)).toList();
          final totalPages = (m['totalPages'] as num?)?.toInt() ?? 1;
          final cur = (m['page'] as num?)?.toInt() ?? page;
          return HotelPage(
            items: items,
            page: cur,
            hasMore: cur + 1 < totalPages,
            total: (m['totalElements'] as num?)?.toInt() ?? items.length,
          );
        },
      );

  Future<Hotel> detail(int id) => _api.getData(
        '/api/v1/hotels/$id',
        parse: (d) => Hotel.fromJson(d as Map<String, dynamic>),
      );

  /// Ảnh bìa của CẢ TRANG trong 1 request (fix N+1 phía client: trước đây mỗi thẻ KS
  /// gọi /{id}/images riêng → 20 request/trang, cuộn vô tận thì bùng nổ).
  Future<Map<int, String>> covers(List<int> ids) {
    if (ids.isEmpty) return Future.value(const {});
    return _api.getData(
      '/api/v1/hotels/covers',
      query: {'ids': ids.join(',')},
      parse: (d) {
        final m = (d as Map?) ?? const {};
        return m.map((k, v) => MapEntry(int.parse('$k'), '${Env.baseUrl}$v'));
      },
    );
  }

  /// URL ảnh bìa (ảnh đầu) của khách sạn — ảnh công khai, dùng thẳng Image.network. Null nếu chưa có ảnh.
  Future<String?> coverImage(int hotelId) => _api.getData(
        '/api/v1/hotels/$hotelId/images',
        parse: (d) {
          final list = (d as List?) ?? const [];
          if (list.isEmpty) return null;
          final path = (list.first as Map<String, dynamic>)['url'] as String?;
          return path == null ? null : '${Env.baseUrl}$path';
        },
      );

  /// Toàn bộ URL ảnh (gallery) của khách sạn.
  Future<List<String>> images(int hotelId) => _api.getData(
        '/api/v1/hotels/$hotelId/images',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => '${Env.baseUrl}${(e as Map<String, dynamic>)['url']}')
            .toList(),
      );

  Future<List<RoomType>> rooms(int hotelId) => _api.getData(
        '/api/v1/hotels/$hotelId/rooms',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => RoomType.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
