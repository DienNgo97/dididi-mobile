import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import '../auth/auth_providers.dart';
import '../promo/offer_repository.dart';
import '../wishlist/wishlist_repository.dart';
import 'hotel_models.dart';
import 'hotel_search.dart';
import 'hotels_controller.dart';

const _brand = Color(0xFF2F8B60);

class HotelListScreen extends ConsumerStatefulWidget {
  const HotelListScreen({super.key});
  @override
  ConsumerState<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends ConsumerState<HotelListScreen> {
  final _q = TextEditingController();
  final Set<int> _stars = {};
  final Set<String> _types = {};
  final Set<String> _amenities = {}; // mã tiện nghi (AND)
  final Set<String> _tags = {}; // mã tag nổi bật (OR)
  double? _minRating; // ≥4.5 / 4.0 / 3.5
  int? _priceMin;
  int? _priceMax;
  String _sort = 'default';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  bool get _hasFilter =>
      _stars.isNotEmpty ||
      _types.isNotEmpty ||
      _amenities.isNotEmpty ||
      _tags.isNotEmpty ||
      _minRating != null ||
      _priceMin != null ||
      _priceMax != null;

  List<Hotel> _apply(List<Hotel> all) {
    var xs = all.where((h) {
      final p = h.minPrice?.toDouble();
      if (_priceMin != null && (p == null || p < _priceMin!)) return false;
      if (_priceMax != null && (p == null || p > _priceMax!)) return false;
      if (_stars.isNotEmpty && !(h.starRating != null && _stars.contains(h.starRating))) return false;
      if (_types.isNotEmpty && !(h.propertyTypeName != null && _types.contains(h.propertyTypeName))) return false;
      if (_minRating != null && (h.avgRating ?? 0) < _minRating!) return false;
      // Tiện nghi: KS phải có TẤT CẢ tiện nghi được chọn (AND)
      if (_amenities.isNotEmpty && !_amenities.every((c) => h.amenities.any((a) => a.code == c))) return false;
      // Tag nổi bật: KS có ÍT NHẤT một tag được chọn (OR)
      if (_tags.isNotEmpty && !_tags.any((t) => h.tags.contains(t))) return false;
      return true;
    }).toList();
    switch (_sort) {
      case 'price_asc':
        xs.sort((a, b) => (a.minPrice?.toDouble() ?? double.maxFinite)
            .compareTo(b.minPrice?.toDouble() ?? double.maxFinite));
        break;
      case 'price_desc':
        xs.sort((a, b) => (b.minPrice?.toDouble() ?? -1).compareTo(a.minPrice?.toDouble() ?? -1));
        break;
      case 'star_desc':
        xs.sort((a, b) => (b.starRating ?? 0).compareTo(a.starRating ?? 0));
        break;
      case 'rating_desc':
        xs.sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
        break;
    }
    return xs;
  }

  /// Nhãn thân thiện cho mã tag (HotelTag enum name).
  static String _tagLabel(String code) {
    final m = {
      'BEACHFRONT': trg('hotel.tag.beachfront'),
      'FAMILY_FRIENDLY': trg('hotel.tag.familyFriendly'),
      'BUSINESS': trg('hotel.tag.business'),
      'ROMANTIC': trg('hotel.tag.romantic'),
      'LUXURY': trg('hotel.tag.luxury'),
      'BUDGET': trg('hotel.tag.budget'),
      'CITY_CENTER': trg('hotel.tag.cityCenter'),
      'POOL': trg('hotel.tag.pool'),
      'PET_FRIENDLY': trg('hotel.tag.petFriendly'),
      'NEW': trg('hotel.tag.new'),
      'TOP_RATED': trg('hotel.tag.topRated'),
    };
    if (m.containsKey(code)) return m[code]!;
    return code
        .split('_')
        .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
        .join(' ');
  }

  // ---- Hero + chỉ số tin cậy (giống homepage web) ----
  Widget _hero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2F8B60), Color(0xFF215B3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trg('hotel.heroTitle'),
              style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(trg('hotel.heroSub'),
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
          const SizedBox(height: 12),
          Row(children: [
            _Stat('500+', trg('hotels')),
            _Stat('12K+', trg('hotel.statBookings')),
            _Stat('4.8', trg('hotel.statAvg')),
            _Stat('30+', trg('hotel.statCities')),
          ]),
        ],
      ),
    );
  }

  // ---- Tuỳ chọn tìm kiếm (toggle/ngày/khách) — cuộn theo danh sách ----
  Widget _searchOptions() {
    final s = ref.watch(hotelSearchProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          _stayToggle(s),
          const SizedBox(height: 10),
          if (s.dayUse)
            _fieldBox(Icons.calendar_today_outlined, trg('hotel.dayDate'), dmy(s.checkIn), _pickCheckIn)
          else
            Row(children: [
              Expanded(child: _fieldBox(Icons.calendar_today_outlined, trg('hotel.checkIn'), dmy(s.checkIn), _pickCheckIn)),
              const SizedBox(width: 10),
              Expanded(child: _fieldBox(Icons.event_outlined, trg('hotel.checkOut'), dmy(s.checkOut), _pickCheckOut)),
            ]),
          const SizedBox(height: 10),
          _fieldBox(Icons.person_outline, trg('hotel.guestsRooms'), s.guestLabel(), _editGuests),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ref.read(hotelListProvider.notifier).search(_q.text),
              child: Text(trg('common.search')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stayToggle(HotelSearch s) {
    Widget seg(String label, bool val) {
      final active = s.dayUse == val;
      return Expanded(
        child: InkWell(
          onTap: () => ref.read(hotelSearchProvider.notifier).state = s.copyWith(dayUse: val),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? _brand : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.black54)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F3), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [seg(trg('hotel.overnight'), false), seg(trg('hotel.dayUse'), true)]),
    );
  }

  Widget _fieldBox(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDE1E0)), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.black45)),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _pickCheckIn() async {
    final s = ref.read(hotelSearchProvider);
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: s.checkIn,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      var co = s.checkOut;
      if (!co.isAfter(d)) co = d.add(const Duration(days: 1));
      ref.read(hotelSearchProvider.notifier).state = s.copyWith(checkIn: d, checkOut: co);
    }
  }

  Future<void> _pickCheckOut() async {
    final s = ref.read(hotelSearchProvider);
    final d = await showDatePicker(
      context: context,
      initialDate: s.checkOut,
      firstDate: s.checkIn.add(const Duration(days: 1)),
      lastDate: s.checkIn.add(const Duration(days: 366)),
    );
    if (d != null) ref.read(hotelSearchProvider.notifier).state = s.copyWith(checkOut: d);
  }

  void _editGuests() {
    final s0 = ref.read(hotelSearchProvider);
    int adults = s0.adults, children = s0.children, rooms = s0.rooms;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget stepRow(String label, int val, int min, void Function(int) set) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Text(label, style: const TextStyle(fontSize: 15)),
                  const Spacer(),
                  IconButton.outlined(onPressed: val > min ? () => set(val - 1) : null, icon: const Icon(Icons.remove)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$val', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  IconButton.outlined(onPressed: () => set(val + 1), icon: const Icon(Icons.add)),
                ]),
              );
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trg('hotel.guestsRooms'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              stepRow(trg('hotel.adults'), adults, 1, (v) => setSheet(() => adults = v)),
              stepRow(trg('hotel.children'), children, 0, (v) => setSheet(() => children = v)),
              stepRow(trg('hotel.rooms'), rooms, 1, (v) => setSheet(() => rooms = v)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref.read(hotelSearchProvider.notifier).state =
                        s0.copyWith(adults: adults, children: children, rooms: rooms);
                    Navigator.pop(ctx);
                  },
                  child: Text(trg('common.done')),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(hotelListProvider);
    final ctl = ref.read(hotelListProvider.notifier);
    return RefreshIndicator(
      onRefresh: () => ref.read(hotelListProvider.notifier).refresh(),
      child: NotificationListener<ScrollUpdateNotification>(
        // Nạp trang kế khi NGƯỜI DÙNG cuộn XUỐNG và còn <600px tới đáy.
        // CHỈ nghe ScrollUpdateNotification + bắt buộc scrollDelta > 0: nếu nghe mọi
        // ScrollNotification thì lúc mới dựng (maxScrollExtent còn ~0) điều kiện luôn đúng
        // → nạp liên tiếp hết trang này tới trang khác → hàng nghìn thẻ + treo hẳn app.
        onNotification: (n) {
          final m = n.metrics;
          final delta = n.scrollDelta ?? 0;
          if (delta > 0 && m.maxScrollExtent > 0 && m.extentAfter < 600) ctl.loadMore();
          return false;
        },
        child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Thanh tìm kiếm GỌN, ghim trên cùng — luôn thao tác được, chiếm ít chỗ.
          SliverPersistentHeader(pinned: true, delegate: _PinnedBar(height: 70, child: _pinnedSearch())),
          // Hero + tuỳ chọn (toggle/ngày/khách) — CUỘN THEO danh sách để nhường chỗ.
          const SliverToBoxAdapter(child: SizedBox(height: 6)), // thở giữa ô tìm và hero
          SliverToBoxAdapter(child: _hero()),
          SliverToBoxAdapter(child: _searchOptions()),
          SliverToBoxAdapter(child: _offerBanner()),
          SliverToBoxAdapter(child: _guideBanner()),
          ...async.when<List<Widget>>(
            loading: () => const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
              ),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                    message: e.toString(), onRetry: () => ref.read(hotelListProvider.notifier).refresh()),
              ),
            ],
            data: (all) {
              final list = _apply(all);
              final showFeatured = !_hasFilter && _q.text.trim().isEmpty;
              return [
                if (showFeatured) SliverToBoxAdapter(child: _featuredStrip()),
                SliverToBoxAdapter(child: _filterBar(all, list.length)),
                if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: trg('hotel.emptyTitle'),
                      message: trg('hotel.emptyMsg'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: EdgeInsets.only(bottom: i == list.length - 1 ? 0 : 14),
                          child: _HotelCard(h: list[i]),
                        ),
                        childCount: list.length,
                      ),
                    ),
                  ),
                // Chân trang: vòng xoay khi đang nạp thêm, hoặc tổng số kết quả khi đã hết.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Center(
                      child: ctl.hasMore
                          ? const SizedBox(
                              height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : (list.isEmpty
                              ? const SizedBox.shrink()
                              : Text(
                                  trg('hotel.loadedAll')
                                      .replaceAll('{n}', '${list.length}')
                                      .replaceAll('{total}', '${ctl.total}'),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.muted))),
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
        ),
      ),
    );
  }

  /// Thanh tìm kiếm gọn (ghim). Bấm/nhập để tìm ngay không cần cuộn.
  /// Center để field tự căn giữa trong chiều cao header (tránh lỗi paintExtent).
  Widget _pinnedSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: TextField(
          controller: _q,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) => ref.read(hotelListProvider.notifier).search(v),
          decoration: InputDecoration(
            hintText: trg('hotel.searchHint'),
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: const Color(0xFFF1F4F3),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }

  /// Banner "Ưu đãi dành riêng cho bạn" — chỉ hiện khi ĐÃ ĐĂNG NHẬP và còn voucher
  /// cá nhân hoá dùng được (sinh nhật / quay lại / tri ân hạng / chào mừng).
  Widget _offerBanner() {
    final authed = ref.watch(authControllerProvider).status == AuthStatus.authenticated;
    if (!authed) return const SizedBox.shrink();
    final n = ref.watch(usableOfferCountProvider).asData?.value ?? 0;
    if (n <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: AppCard(
        onTap: () => context.push('/offers'),
        color: const Color(0xFFFFF6E5),
        border: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppTheme.amber, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.card_giftcard, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(trg('offer.bannerTitle').replaceAll('{n}', '$n'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              const SizedBox(height: 2),
              Text(trg('offer.bannerMsg'), style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.muted),
        ]),
      ),
    );
  }

  /// Banner "Hướng dẫn viên AI" — bản mobile của banner trang chủ web, mở màn chat /trip-guide.
  Widget _guideBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: AppCard(
        onTap: () => context.push('/trip-guide'),
        color: AppTheme.brandSoft,
        border: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _brand, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.travel_explore, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(trg('trip.guideBannerTitle'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              const SizedBox(height: 2),
              Text(trg('trip.guideBannerMsg'),
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.muted),
        ]),
      ),
    );
  }

  /// Dải "Nổi bật · đánh giá cao" (Top 10) — chỉ hiện khi chưa lọc/tìm, giống khối nổi bật của web.
  /// Lấy từ server (sort=rating) nên là Top 10 TOÀN HỆ THỐNG, không phụ thuộc đã cuộn tới đâu.
  Widget _featuredStrip() {
    final items = ref.watch(featuredHotelsProvider).asData?.value ?? const <Hotel>[];
    if (items.length < 3) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          trg('hotel.featuredTitle'),
          subtitle: trg('hotel.featuredSub'),
          icon: Icons.local_fire_department,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        ),
        SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _FeaturedCard(h: items[i], rank: i + 1),
          ),
        ),
      ],
    );
  }

  Widget _filterBar(List<Hotel> all, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 4),
      child: Row(
        children: [
          Text(trg('hotel.placesCount').replaceAll('{n}', '$count'), style: const TextStyle(color: AppTheme.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          _pill(Icons.tune, trg('hotel.filters'), () => _openFilter(all), active: _hasFilter),
          const SizedBox(width: 8),
          _sortMenu(),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, VoidCallback onTap, {bool active = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEAF3EE) : Colors.white,
          border: Border.all(color: active ? _brand : const Color(0xFFDDE1E0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: active ? _brand : Colors.black54),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 13, color: active ? _brand : Colors.black87)),
        ]),
      ),
    );
  }

  Widget _sortMenu() {
    final opts = {
      'default': trg('hotel.sortDefault'),
      'price_asc': trg('hotel.sortPriceAsc'),
      'price_desc': trg('hotel.sortPriceDesc'),
      'rating_desc': trg('hotel.sortRatingDesc'),
      'star_desc': trg('hotel.sortStarDesc'),
    };
    return PopupMenuButton<String>(
      initialValue: _sort,
      onSelected: (v) => setState(() => _sort = v),
      itemBuilder: (_) => opts.entries.map((e) => PopupMenuItem(value: e.key, child: Text(e.value))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDDE1E0)),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.swap_vert, size: 16, color: Colors.black54),
          const SizedBox(width: 5),
          Text(opts[_sort]!, style: const TextStyle(fontSize: 13)),
        ]),
      ),
    );
  }

  void _openFilter(List<Hotel> all) {
    final types = all.map((h) => h.propertyTypeName).whereType<String>().toSet().toList()..sort();
    // Tiện nghi & tag gộp từ toàn bộ KS đang hiển thị
    final amenityMap = <String, String>{};
    for (final h in all) {
      for (final a in h.amenities) {
        amenityMap[a.code] = a.name.isNotEmpty ? a.name : a.code;
      }
    }
    final amenityCodes = amenityMap.keys.toList()..sort((a, b) => amenityMap[a]!.compareTo(amenityMap[b]!));
    final tagCodes = <String>{for (final h in all) ...h.tags}.toList()..sort();

    final minC = TextEditingController(text: _priceMin?.toString() ?? '');
    final maxC = TextEditingController(text: _priceMax?.toString() ?? '');
    final stars = {..._stars};
    final selTypes = {..._types};
    final selAmenities = {..._amenities};
    final selTags = {..._tags};
    double? rating = _minRating;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(trg('hotel.filters'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      minC.clear();
                      maxC.clear();
                      stars.clear();
                      selTypes.clear();
                      selAmenities.clear();
                      selTags.clear();
                      rating = null;
                      setSheet(() {});
                    },
                    child: Text(trg('hotel.clearFilter')),
                  ),
                ]),
                Text(trg('hotel.pricePerNight'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: minC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: trg('hotel.min'), border: const OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: maxC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: trg('hotel.max'), border: const OutlineInputBorder(), isDense: true))),
                ]),
                const SizedBox(height: 16),
                Text(trg('hotel.ratingScore'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final r in [4.5, 4.0, 3.5])
                    FilterChip(
                      label: Text('≥ ${r.toStringAsFixed(1)}'),
                      selected: rating == r,
                      onSelected: (v) => setSheet(() => rating = v ? r : null),
                    ),
                ]),
                const SizedBox(height: 16),
                Text(trg('hotel.starClass'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [3, 4, 5]
                      .map((s) => FilterChip(
                            label: Text(trg('hotel.starsN').replaceAll('{n}', '$s')),
                            selected: stars.contains(s),
                            onSelected: (v) {
                              if (v) {
                                stars.add(s);
                              } else {
                                stars.remove(s);
                              }
                              setSheet(() {});
                            },
                          ))
                      .toList(),
                ),
                if (types.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(trg('hotel.propertyType'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: types
                        .map((t) => FilterChip(
                              label: Text(t),
                              selected: selTypes.contains(t),
                              onSelected: (v) {
                                if (v) {
                                  selTypes.add(t);
                                } else {
                                  selTypes.remove(t);
                                }
                                setSheet(() {});
                              },
                            ))
                        .toList(),
                  ),
                ],
                if (amenityCodes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(trg('hotel.amenities'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final c in amenityCodes)
                        FilterChip(
                          label: Text(amenityMap[c]!),
                          selected: selAmenities.contains(c),
                          onSelected: (v) {
                            if (v) {
                              selAmenities.add(c);
                            } else {
                              selAmenities.remove(c);
                            }
                            setSheet(() {});
                          },
                        ),
                    ],
                  ),
                ],
                if (tagCodes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(trg('hotel.tagsSection'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final t in tagCodes)
                        FilterChip(
                          label: Text(_tagLabel(t)),
                          selected: selTags.contains(t),
                          onSelected: (v) {
                            if (v) {
                              selTags.add(t);
                            } else {
                              selTags.remove(t);
                            }
                            setSheet(() {});
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _priceMin = int.tryParse(minC.text.trim());
                        _priceMax = int.tryParse(maxC.text.trim());
                        _stars
                          ..clear()
                          ..addAll(stars);
                        _types
                          ..clear()
                          ..addAll(selTypes);
                        _amenities
                          ..clear()
                          ..addAll(selAmenities);
                        _tags
                          ..clear()
                          ..addAll(selTags);
                        _minRating = rating;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(trg('common.apply')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header ghim có chiều cao cố định (dùng cho thanh tìm kiếm gọn).
class _PinnedBar extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  const _PinnedBar({required this.child, required this.height});
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Material(color: Colors.white, elevation: overlapsContent ? 2 : 0, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBar oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

class _HotelCard extends ConsumerWidget {
  final Hotel h;
  const _HotelCard({required this.h});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.push('/hotels/${h.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _Cover(hotelId: h.id),
                if (h.starRating != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xE6FFFFFF), borderRadius: BorderRadius.circular(20)),
                      child: Text('★' * h.starRating!,
                          style: const TextStyle(color: Color(0xFFF5A623), fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                Positioned(top: 6, right: 6, child: _WishHeart(hotelId: h.id)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.place, size: 14, color: AppTheme.muted),
                    const SizedBox(width: 3),
                    Expanded(
                        child: Text(h.city ?? h.address ?? '',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.muted, fontSize: 12.5))),
                    if ((h.avgRating ?? 0) > 0) ...[
                      const Icon(Icons.star, size: 14, color: AppTheme.amber),
                      const SizedBox(width: 2),
                      Text(h.avgRating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.ink)),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (h.propertyTypeName != null) _chip(h.propertyTypeName!),
                    _chip(trg('hotel.instantConfirm')),
                    _chip(trg('hotel.payOnline')),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: Text(h.minPrice != null ? trg('hotel.fromPerNight').replaceAll('{p}', formatVnd(h.minPrice)) : trg('hotel.contact'),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: _brand, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(color: _brand, borderRadius: BorderRadius.circular(8)),
                      child: Text(trg('hotel.view'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppTheme.brandSoft, borderRadius: BorderRadius.circular(6)),
        child: Text(t, style: const TextStyle(fontSize: 11, color: AppTheme.brand)),
      );
}

/// Thẻ nhỏ trong dải "Nổi bật" (ngang).
class _FeaturedCard extends StatelessWidget {
  final Hotel h;
  final int rank;
  const _FeaturedCard({required this.h, required this.rank});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/hotels/${h.id}'),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 176,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(children: [
                SizedBox(height: 104, width: double.infinity, child: _Cover(hotelId: h.id)),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: _brand, borderRadius: BorderRadius.circular(20)),
                    child: Text('#$rank', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.star, size: 13, color: Color(0xFFF5A623)),
                      const SizedBox(width: 2),
                      Text(h.avgRating!.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Flexible(
                        child: Text(h.minPrice != null ? formatVnd(h.minPrice) : '',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _brand)),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5)),
            Text(label, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 10.5)),
          ],
        ),
      );
}

class _Cover extends ConsumerWidget {
  final int hotelId;
  const _Cover({required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CHỈ đọc kho ảnh bìa nạp theo LÔ (1 request/trang). KHÔNG gọi lẻ từng thẻ:
    // trước đây mỗi thẻ tự fetch nên vẫn có 20 request/trang chạy song song với lô.
    // Chưa có trong kho (lô đang bay) thì hiện ảnh giữ chỗ, có rồi tự hiện.
    final url = ref.watch(hotelCoversProvider)[hotelId];
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: (url != null && url.isNotEmpty)
          ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFEAF3EE), Color(0xFFD6E9DE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: const Center(child: Icon(Icons.apartment, size: 44, color: Color(0x552F8B60))),
      );
}

class _WishHeart extends ConsumerWidget {
  final int hotelId;
  const _WishHeart({required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(authControllerProvider).status == AuthStatus.authenticated;
    final saved = authed && (ref.watch(wishlistedIdsProvider).asData?.value.contains(hotelId) ?? false);
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          if (!authed) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('auth.loginToSave'))));
            context.push('/login');
            return;
          }
          await ref.read(wishlistRepositoryProvider).toggle(hotelId);
          ref.invalidate(wishlistedIdsProvider);
          ref.invalidate(wishlistProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(saved ? Icons.favorite : Icons.favorite_border,
              size: 20, color: saved ? Colors.redAccent : Colors.black45),
        ),
      ),
    );
  }
}
