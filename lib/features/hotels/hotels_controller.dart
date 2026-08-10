import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hotel_models.dart';
import 'hotel_repository.dart';
import 'room_models.dart';

/// Danh sách khách sạn + tìm full-text, CUỘN VÔ TẬN (mỗi lần 20 KS).
/// Trước đây lấy cứng 50 KS đầu — sau khi nhân 5 dữ liệu (~1.790 KS) thì phần lớn không xem được.
final hotelListProvider =
    AsyncNotifierProvider<HotelListController, List<Hotel>>(HotelListController.new);

class HotelListController extends AsyncNotifier<List<Hotel>> {
  static const _pageSize = 20;
  String? _query; // từ khoá tìm (tên KS/thành phố, không dấu cũng được)
  int _page = 0;
  bool _hasMore = false;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;
  int _total = 0;
  int get total => _total;

  Future<List<Hotel>> _fetchFirst() async {
    final p = await ref.read(hotelRepositoryProvider).page(q: _query, page: 0, size: _pageSize);
    _page = p.page;
    _hasMore = p.hasMore;
    _total = p.total;
    _loadCovers(p.items);
    return p.items;
  }

  /// Nạp ảnh bìa cả trang trong 1 request rồi đổ vào kho chung.
  void _loadCovers(List<Hotel> items) {
    final ids = items.map((h) => h.id).toList();
    if (ids.isEmpty) return;
    ref.read(hotelRepositoryProvider).covers(ids).then((m) {
      if (m.isEmpty) return;
      final store = ref.read(hotelCoversProvider.notifier);
      store.state = {...store.state, ...m};
    }).catchError((_) {/* không có ảnh bìa cũng không sao */});
  }

  @override
  Future<List<Hotel>> build() => _fetchFirst();

  /// Tìm theo từ khoá (gửi lên server: Meilisearch không dấu/typo → fallback LIKE).
  Future<void> search(String? keyword) async {
    _query = (keyword == null || keyword.trim().isEmpty) ? null : keyword.trim();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchFirst);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirst);
  }

  /// Nạp thêm trang kế khi người dùng cuộn tới cuối danh sách.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.asData?.value;
    if (current == null) return;
    _loadingMore = true;
    try {
      final p = await ref
          .read(hotelRepositoryProvider)
          .page(q: _query, page: _page + 1, size: _pageSize);
      _page = p.page;
      _hasMore = p.hasMore;
      _total = p.total;
      _loadCovers(p.items);
      state = AsyncValue.data([...current, ...p.items]);
    } catch (_) {
      // Lỗi mạng khi nạp thêm: giữ nguyên danh sách đang có, cho phép thử lại.
      _hasMore = true;
    } finally {
      _loadingMore = false;
    }
  }
}

/// Top 10 khách sạn đánh giá cao NHẤT TOÀN HỆ THỐNG (server sort trước khi phân trang) —
/// dùng cho dải "Nổi bật · đánh giá cao"; trước đây chỉ xếp trong các KS đã tải về máy.
final featuredHotelsProvider = FutureProvider<List<Hotel>>((ref) async {
  final repo = ref.read(hotelRepositoryProvider);
  final items = (await repo.page(sort: 'rating', size: 10)).items;
  // Ảnh bìa của dải cũng lấy theo LÔ (nếu không sẽ là 10 request lẻ).
  repo.covers(items.map((h) => h.id).toList()).then((m) {
    if (m.isEmpty) return;
    final store = ref.read(hotelCoversProvider.notifier);
    store.state = {...store.state, ...m};
  }).catchError((_) {});
  return items;
});

/// Chi tiết 1 khách sạn.
final hotelDetailProvider = FutureProvider.family<Hotel, int>(
  (ref, id) => ref.read(hotelRepositoryProvider).detail(id),
);

/// Loại phòng của 1 khách sạn (để đặt phòng).
final hotelRoomsProvider = FutureProvider.family<List<RoomType>, int>(
  (ref, hotelId) => ref.read(hotelRepositoryProvider).rooms(hotelId),
);

/// Kho ảnh bìa dùng chung: controller nạp theo LÔ mỗi khi tải xong 1 trang KS
/// (1 request cho 20 thẻ thay vì 20 request).
final hotelCoversProvider = StateProvider<Map<int, String>>((ref) => const {});

/// Ảnh bìa 1 khách sạn — chỉ gọi lẻ khi kho chung chưa có (vd màn Yêu thích).
final hotelCoverProvider = FutureProvider.family<String?, int>(
  (ref, hotelId) {
    final cached = ref.watch(hotelCoversProvider)[hotelId];
    if (cached != null) return Future.value(cached);
    return ref.read(hotelRepositoryProvider).coverImage(hotelId);
  },
);

/// Tất cả ảnh 1 khách sạn (gallery ở màn chi tiết).
final hotelImagesProvider = FutureProvider.family<List<String>, int>(
  (ref, hotelId) => ref.read(hotelRepositoryProvider).images(hotelId),
);
