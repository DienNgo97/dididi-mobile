import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import '../auth/auth_providers.dart';
import '../reviews/review_models.dart';
import '../reviews/review_repository.dart';
import '../wishlist/wishlist_repository.dart';
import 'hotel_models.dart';
import 'hotels_controller.dart';
import 'room_models.dart';

const _brand = Color(0xFF2F8B60);

class HotelDetailScreen extends ConsumerWidget {
  final int id;
  const HotelDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hotelDetailProvider(id));
    // Theo dõi luôn ở ĐÂY (widget cha) dù giá trị dùng ở _RatingBadge bên dưới.
    //
    // Vì sao: trước đây chỉ mình _RatingBadge watch provider này. Khung hình đầu nó trả về
    // một Text ("Chưa có đánh giá"); khi dữ liệu về, RIÊNG nhánh đó dựng lại và đổi sang Row.
    // Lượt bố trí lẻ giữa chừng đó rơi đúng lúc cây semantics của Flutter 3.44.4 đang hỏng
    // (assertion !semantics.parentDataDirty), khiến render object không được gán vị trí —
    // badge bị vẽ ở gốc toạ độ, đè lên tên khách sạn, và chiếm 0 pixel chiều cao.
    // Watch ở cha khiến cả trang dựng lại MỘT LƯỢT khi dữ liệu về, không còn bố trí lẻ.
    // CHỈ watch reviews. Không cần thêm hotelRoomsProvider / hotelImagesProvider vào đây —
    // hai phần đó tự quản trạng thái tải của mình, watch ở cha chỉ làm cả trang
    // dựng lại thừa mỗi khi một trong hai có dữ liệu.
    ref.watch(hotelReviewsProvider(id));
    final h = async.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(trg('hotel.detailTitle')),
        actions: [_WishlistButton(hotelId: id)],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(hotelDetailProvider(id))),
        data: (h) => _body(context, h),
      ),
      // Thanh "Đặt phòng" đặt ở bottomNavigationBar của Scaffold thay vì lồng
      // `Column > Expanded > ListView` + thanh nút như trước 27/08/2026.
      // Đây là cấu trúc đúng cho màn hình có thanh hành động cố định: Scaffold
      // tự chừa chỗ và tự xử lý vùng an toàn, không phải ghép tay bằng Column.
      bottomNavigationBar: h == null ? null : _thanhDatPhong(context, h),
    );
  }

  /// Thanh hành động cố định ở đáy màn hình.
  Widget _thanhDatPhong(BuildContext context, Hotel h) => Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => context.push('/hotels/${h.id}/book', extra: h.name),
              child: Text(h.minPrice != null
                  ? trg('hotel.bookFrom').replaceAll('{p}', formatVnd(h.minPrice))
                  : trg('hotel.book')),
            ),
          ),
        ),
      );

  Widget _body(BuildContext context, Hotel h) {
    return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Gallery(hotelId: h.id),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.ink, letterSpacing: -0.4)),
                    const SizedBox(height: 6),
                    Row(children: [
                      if (h.starRating != null)
                        Text('${'★' * h.starRating!}  ', style: const TextStyle(color: AppTheme.amber)),
                      Expanded(child: Text(h.address ?? h.city ?? '', style: const TextStyle(color: AppTheme.muted))),
                    ]),
                    const SizedBox(height: 10),
                    _RatingBadge(hotelId: h.id),
                    if (h.propertyTypeName != null) ...[
                      const SizedBox(height: 10),
                      _chip(h.propertyTypeName!),
                    ],
                    if (h.description != null && h.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(h.description!, style: const TextStyle(height: 1.5)),
                    ],
                    if (h.amenities.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      SectionHeader(trg('hotel.amenities'), padding: EdgeInsets.zero),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [for (final a in h.amenities) _amenity(a.name)]),
                    ],
                    if (h.lat != null && h.lng != null) ...[
                      const SizedBox(height: 22),
                      SectionHeader(trg('hotel.location'), padding: EdgeInsets.zero),
                      const SizedBox(height: 12),
                      // Bản đồ xem trước: AbsorbPointer để platform view KHÔNG nuốt cử chỉ
                      // cuộn của trang (đặt ngón lên bản đồ là trang đứng im).
                      // Bấm vào bản đồ -> mở màn bản đồ đầy đủ để thao tác.
                      // Bản đồ xem trước ĐƠN GIẢN: AbsorbPointer để platform view iOS không
                      // nuốt cử chỉ cuộn của trang. Không lồng Stack/Positioned quanh platform
                      // view — trên iOS cách đó chặn luôn phần nội dung phía dưới.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AbsorbPointer(
                          child: SizedBox(
                            height: 170,
                            child: GoogleMap(
                              initialCameraPosition:
                                  CameraPosition(target: LatLng(h.lat!, h.lng!), zoom: 15),
                              markers: {
                                Marker(
                                  markerId: MarkerId('h${h.id}'),
                                  position: LatLng(h.lat!, h.lng!),
                                  infoWindow: InfoWindow(title: h.name, snippet: h.address ?? h.city),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              // Lite mode CHỈ có trên Android — bật trên iOS làm hỏng cả trang.
                              liteModeEnabled: defaultTargetPlatform == TargetPlatform.android,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Nút mở bản đồ đầy đủ đặt NGOÀI khối bản đồ (bản đồ xem trước không bấm được).
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/map'),
                          icon: const Icon(Icons.open_in_full, size: 16),
                          label: Text(trg('hotel.openMap')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _brand,
                            side: const BorderSide(color: AppTheme.line),
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SectionHeader(trg('hotel.roomTypes'), padding: EdgeInsets.zero),
                    const SizedBox(height: 12),
                    _RoomsSection(hotelId: h.id, hotelName: h.name),
                    const SizedBox(height: 24),
                    SectionHeader(trg('hotel.reviews'), padding: EdgeInsets.zero),
                    const SizedBox(height: 12),
                    _ReviewList(hotelId: h.id),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppTheme.brandSoft, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.brand, fontWeight: FontWeight.w600)),
      );

  Widget _amenity(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 15, color: AppTheme.brand),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.ink)),
        ]),
      );
}

class _Gallery extends ConsumerWidget {
  final int hotelId;
  const _Gallery({required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imgs = ref.watch(hotelImagesProvider(hotelId)).asData?.value ?? const [];
    if (imgs.isEmpty) {
      return Container(
        height: 220,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFEAF3EE), Color(0xFFD6E9DE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: const Center(child: Icon(Icons.apartment, size: 60, color: Color(0x552F8B60))),
      );
    }
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          PageView(
            children: [
              for (final u in imgs)
                Image.network(u, fit: BoxFit.cover, width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAF3EE))),
            ],
          ),
          if (imgs.length > 1)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(12)),
                child: Text(trg('hotel.photosCount').replaceAll('{n}', '${imgs.length}'), style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Danh sách hạng phòng ngay trên trang chi tiết (giống web): tên/sức chứa/giá + nút Đặt.
class _RoomsSection extends ConsumerWidget {
  final int hotelId;
  final String hotelName;
  const _RoomsSection({required this.hotelId, required this.hotelName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hotelRoomsProvider(hotelId));
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
      error: (_, __) => Text(trg('hotel.roomsLoadError'), style: const TextStyle(color: AppTheme.muted)),
      data: (rooms) {
        if (rooms.isEmpty) {
          return EmptyState(
            icon: Icons.meeting_room_outlined,
            title: trg('hotel.noRoomsTitle'),
            message: trg('hotel.noRoomsMsg'),
          );
        }
        return Column(children: [for (final r in rooms) _tile(context, r)]);
      },
    );
  }

  Widget _tile(BuildContext context, RoomType r) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.ink)),
          if (r.capacity != null) ...[
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.people_outline, size: 14, color: AppTheme.muted),
              const SizedBox(width: 4),
              Text(trg('hotel.capacityGuests').replaceAll('{n}', '${r.capacity}'), style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
            ]),
          ],
          if (r.description != null && r.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Text(r.basePrice != null ? trg('hotel.fromPerNight').replaceAll('{p}', formatVnd(r.basePrice)) : trg('hotel.contact'),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _brand, fontSize: 14.5)),
            ),
            FilledButton(
              onPressed: () => context.push('/hotels/$hotelId/book?roomId=${r.id}', extra: hotelName),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                // BẮT BUỘC phải đặt lại minimumSize khi nút nằm trong Row.
                //
                // Theme dùng chung đặt `minimumSize: Size.fromHeight(52)`, mà
                // Size.fromHeight(52) chính là Size(double.infinity, 52) — bề rộng
                // tối thiểu VÔ HẠN. Trong Column thì vô hại vì chiều rộng đã bị giới
                // hạn sẵn; nhưng Row cấp cho con chiều rộng KHÔNG giới hạn, nên bố trí
                // đổ vỡ với "BoxConstraints forces an infinite width", kéo theo
                // "RenderBox was not laid out" lan ngược lên và làm CẢ ListView không
                // vẽ được — trang trắng trơn.
                //
                // Triệu chứng đánh lừa rất mạnh: ngoại lệ chỉ in ĐẦY ĐỦ một lần rồi
                // các lần sau rút gọn thành "Another exception was thrown", nên nếu
                // xoá log trước khi thao tác thì tưởng là không có lỗi gì.
                // Truy ra ngày 27/08/2026 sau khi loại nhầm 10 giả thuyết khác.
                minimumSize: const Size(0, 40),
              ),
              child: Text(trg('common.book')),
            ),
          ]),
        ],
      ),
    );
  }
}

class _RatingBadge extends ConsumerWidget {
  final int hotelId;
  const _RatingBadge({required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(hotelReviewsProvider(hotelId)).asData?.value;
    if (r == null || r.count == 0) {
      return Text(trg('hotel.noRatingYet'), style: const TextStyle(color: AppTheme.muted, fontSize: 12.5));
    }
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.brand, borderRadius: BorderRadius.circular(8)),
        child: Text(r.avg.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 8),
      Text(trg('hotel.reviewsCount').replaceAll('{n}', '${r.count}'), style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
    ]);
  }
}

class _ReviewList extends ConsumerWidget {
  final int hotelId;
  const _ReviewList({required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hotelReviewsProvider(hotelId));
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(trg('hotel.reviewsLoadError'), style: const TextStyle(color: AppTheme.muted)),
      data: (r) {
        if (r.items.isEmpty) {
          return EmptyState(
            icon: Icons.reviews_outlined,
            title: trg('hotel.noReviewsTitle'),
            message: trg('hotel.noReviewsMsg'),
          );
        }
        return Column(children: [for (final rv in r.items) _tile(rv)]);
      },
    );
  }

  Widget _tile(Review rv) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(rv.reviewerName ?? trg('hotel.anonymous'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.ink)),
            const Spacer(),
            Text('${'★' * rv.rating}${'☆' * (5 - rv.rating)}',
                style: const TextStyle(color: AppTheme.amber, fontSize: 12)),
          ]),
          if (rv.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(dmy(rv.createdAt!), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
            ),
          if (rv.comment != null && rv.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(rv.comment!, style: const TextStyle(fontSize: 13, height: 1.35, color: AppTheme.ink)),
          ],
          if (rv.vendorReply != null && rv.vendorReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.brandSoft, borderRadius: BorderRadius.circular(8)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.storefront, size: 14, color: AppTheme.brand),
                const SizedBox(width: 6),
                Expanded(child: Text(trg('hotel.vendorReply').replaceAll('{t}', rv.vendorReply!), style: const TextStyle(fontSize: 12.5, color: AppTheme.ink))),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _WishlistButton extends ConsumerWidget {
  final int hotelId;
  const _WishlistButton({required this.hotelId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(authControllerProvider).status == AuthStatus.authenticated;
    final saved = authed && (ref.watch(wishlistCheckProvider(hotelId)).asData?.value ?? false);
    return IconButton(
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: saved ? Colors.redAccent : null),
      tooltip: saved ? trg('hotel.unsave') : trg('hotel.saveToWishlist'),
      onPressed: () async {
        if (!authed) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('auth.loginToSave'))));
          context.push('/login');
          return;
        }
        await ref.read(wishlistRepositoryProvider).toggle(hotelId);
        ref.invalidate(wishlistCheckProvider(hotelId));
        ref.invalidate(wishlistedIdsProvider);
        ref.invalidate(wishlistProvider);
      },
    );
  }
}
