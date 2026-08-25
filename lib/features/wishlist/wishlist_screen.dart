import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import '../hotels/hotel_models.dart';
import 'wishlist_repository.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wishlistProvider);
    return Scaffold(
      appBar: AppBar(title: Text(trg('hotel.wishlistTitle'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(wishlistProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_border,
              title: trg('hotel.wishlistEmptyTitle'),
              message: trg('hotel.wishlistEmptyMsg'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(wishlistProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _HotelRow(h: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HotelRow extends StatelessWidget {
  final Hotel h;
  const _HotelRow({required this.h});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/hotels/${h.id}'),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: AppTheme.brandSoft, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.apartment, color: AppTheme.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
            const SizedBox(height: 3),
            Text([
              if (h.starRating != null) '${'★' * h.starRating!} ',
              h.city ?? h.address ?? '',
            ].join(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
            const SizedBox(height: 6),
            Text(h.minPrice != null ? trg('hotel.fromPerNight').replaceAll('{p}', formatVnd(h.minPrice)) : trg('hotel.contact'),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.brand)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppTheme.muted),
      ]),
    );
  }
}
