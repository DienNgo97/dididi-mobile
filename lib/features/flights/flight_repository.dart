import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../core/network/api_client.dart';
import 'flight_models.dart';
import 'flight_seat_models.dart';

final flightRepositoryProvider =
    Provider<FlightRepository>((ref) => FlightRepository(ref.watch(apiClientProvider)));

/// Sơ đồ ghế của chuyến (null nếu chuyến không hỗ trợ chọn chỗ).
final seatMapProvider =
    FutureProvider.autoDispose.family<SeatMap?, int>((ref, id) => ref.read(flightRepositoryProvider).seatmap(id));

/// Danh mục suất ăn + hành lý.
final flightAddonsProvider =
    FutureProvider.autoDispose<FlightAddonsData>((ref) => ref.read(flightRepositoryProvider).addons());

/// Một trang kết quả chuyến bay (dữ liệu x5: ~4.500 chuyến nên bắt buộc phân trang).
class FlightPage {
  final List<Flight> items;
  final int page;
  final bool hasMore;
  final int total;
  const FlightPage({required this.items, required this.page, required this.hasMore, required this.total});
}

class FlightRepository {
  final ApiClient _api;
  FlightRepository(this._api);

  Future<SeatMap?> seatmap(int id) => _api.getData(
        '/api/v1/flights/$id/seatmap',
        parse: (d) => d == null ? null : SeatMap.fromJson(d as Map<String, dynamic>),
      );

  Future<FlightAddonsData> addons() => _api.getData(
        '/api/v1/flights/addons',
        parse: (d) => FlightAddonsData.fromJson(d as Map<String, dynamic>),
      );

  /// Một trang chuyến bay (API đã phân trang + chỉ trả chuyến chưa khởi hành).
  Future<FlightPage> page({String? from, String? to, String? date, int page = 0, int size = 20}) =>
      _api.getData(
        '/api/v1/flights',
        query: {
          'page': page,
          'size': size,
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
          if (date != null && date.isNotEmpty) 'date': date,
        },
        parse: (d) {
          final m = d as Map<String, dynamic>;
          final items = ((m['content'] as List?) ?? const [])
              .map((e) => Flight.fromJson(e as Map<String, dynamic>))
              .toList();
          final totalPages = (m['totalPages'] as num?)?.toInt() ?? 1;
          final cur = (m['page'] as num?)?.toInt() ?? page;
          return FlightPage(
            items: items,
            page: cur,
            hasMore: cur + 1 < totalPages,
            total: (m['totalElements'] as num?)?.toInt() ?? items.length,
          );
        },
      );

  /// Tìm gọn (không phân trang) — dùng cho luồng chọn chuyến VỀ của vé khứ hồi.
  Future<List<Flight>> search({String? from, String? to, String? date}) async =>
      (await page(from: from, to: to, date: date, size: 50)).items;

  Future<Flight> detail(int id) => _api.getData(
        '/api/v1/flights/$id',
        parse: (d) => Flight.fromJson(d as Map<String, dynamic>),
      );
}
