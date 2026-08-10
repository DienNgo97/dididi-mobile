import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flight_models.dart';
import 'flight_repository.dart';

/// Bộ lọc tìm chuyến bay.
class FlightQuery {
  final String? from;
  final String? to;
  final String? date; // yyyy-MM-dd
  const FlightQuery({this.from, this.to, this.date});
}

/// Kết quả tìm chuyến bay.
final flightSearchProvider =
    AsyncNotifierProvider<FlightSearchController, List<Flight>>(FlightSearchController.new);

class FlightSearchController extends AsyncNotifier<List<Flight>> {
  static const _pageSize = 20;
  FlightQuery _q = const FlightQuery();
  int _page = 0;
  bool _hasMore = false;
  bool _loadingMore = false;
  int _total = 0;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;
  int get total => _total;

  Future<List<Flight>> _fetchFirst() async {
    final p = await ref
        .read(flightRepositoryProvider)
        .page(from: _q.from, to: _q.to, date: _q.date, page: 0, size: _pageSize);
    _page = p.page;
    _hasMore = p.hasMore;
    _total = p.total;
    return p.items;
  }

  @override
  Future<List<Flight>> build() => _fetchFirst();

  Future<void> search(FlightQuery q) async {
    _q = q;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchFirst);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirst);
  }

  /// Nạp thêm 20 chuyến kế khi cuộn tới cuối (tổng ~4.500 chuyến).
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.asData?.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final p = await ref
          .read(flightRepositoryProvider)
          .page(from: _q.from, to: _q.to, date: _q.date, page: _page + 1, size: _pageSize);
      _page = p.page;
      _hasMore = p.hasMore;
      _total = p.total;
      state = AsyncValue.data([...current, ...p.items]);
    } catch (_) {
      _hasMore = true;
    } finally {
      _loadingMore = false;
    }
  }
}

/// Chi tiết 1 chuyến bay.
final flightDetailProvider = FutureProvider.family<Flight, int>(
  (ref, id) => ref.read(flightRepositoryProvider).detail(id),
);
