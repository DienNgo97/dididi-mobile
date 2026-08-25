import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import 'offer_models.dart';
import 'offer_repository.dart';

const _brand = AppTheme.brand;

/// "Ưu đãi của tôi" — voucher tặng riêng theo chương trình khuyến mãi cá nhân hoá
/// (sinh nhật, khách quay lại, tri ân hạng, chào mừng) + voucher đổi điểm.
/// Dùng bằng cách sao chép mã rồi nhập ở hộp thoại thanh toán.
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOffersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(trg('offer.title'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myOffersProvider)),
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.card_giftcard_outlined,
              title: trg('offer.emptyTitle'),
              message: trg('offer.emptyMsg'),
            );
          }
          // Còn dùng được lên trước, hết hạn/đã dùng xuống dưới.
          final usable = all.where((o) => o.usable).toList();
          final others = all.where((o) => !o.usable).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myOffersProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (usable.isNotEmpty) ...[
                  SectionHeader(trg('offer.usableTitle'),
                      subtitle: trg('offer.usableSub').replaceAll('{n}', '${usable.length}'),
                      icon: Icons.card_giftcard),
                  const SizedBox(height: 8),
                  for (final o in usable) _OfferCard(offer: o),
                ],
                if (others.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SectionHeader(trg('offer.expiredTitle'), icon: Icons.history),
                  const SizedBox(height: 8),
                  for (final o in others) _OfferCard(offer: o),
                ],
                const SizedBox(height: 8),
                Text(trg('offer.howToUse'),
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  const _OfferCard({required this.offer});

  String _discountLabel() {
    final v = offer.discountValue;
    if (v == null) return '';
    if (offer.isPercent) {
      final cap = offer.maxDiscount;
      final base = trg('offer.percentOff').replaceAll('{v}', '${v.toStringAsFixed(0)}');
      return cap == null ? base : '$base · ${trg('offer.maxCap').replaceAll('{v}', formatVnd(cap))}';
    }
    return trg('offer.amountOff').replaceAll('{v}', formatVnd(v));
  }

  @override
  Widget build(BuildContext context) {
    final dim = !offer.usable;
    // AppCard không tự áp margin -> tự chừa khoảng cách giữa các thẻ bằng Padding.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
      color: dim ? AppTheme.bg : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: dim ? AppTheme.line : AppTheme.brandSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.local_activity_outlined,
                  size: 20, color: dim ? AppTheme.muted : _brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Row cho chiều cao vô hạn -> phải bó lại
                children: [
                  Text(_discountLabel(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: dim ? AppTheme.muted : _brand)),
                  if (offer.description != null && offer.description!.isNotEmpty)
                    Text(offer.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
                ],
              ),
            ),
            if (!offer.usable) StatusBadge(trg('offer.unusable'), AppTheme.muted),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Text(offer.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 1.1, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: offer.code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(trg('offer.copied'))));
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(trg('offer.copy')),
            ),
          ]),
          if (offer.minOrderAmount != null || offer.validTo != null) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (offer.minOrderAmount != null)
                Pill(trg('offer.minOrder').replaceAll('{v}', formatVnd(offer.minOrderAmount!)),
                    icon: Icons.receipt_long_outlined),
              if (offer.validTo != null)
                Pill(trg('offer.validTo').replaceAll('{v}', dmy(offer.validTo!)),
                    icon: Icons.schedule,
                    color: offer.usable ? AppTheme.amber : AppTheme.muted),
            ]),
          ],
        ],
      ),
      ),
    );
  }
}
