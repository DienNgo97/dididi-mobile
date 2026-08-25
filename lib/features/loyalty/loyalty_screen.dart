import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import '../promo/offer_repository.dart';
import 'loyalty_models.dart';
import 'loyalty_repository.dart';

const _brand = AppTheme.brand;

class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});
  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen> {
  /// Chặn đổi điểm chồng lần (bấm nhanh 2 lần / mở 2 hộp thoại) — cùng tinh thần với
  /// khoá theo user ở backend: 1 lần đổi = 1 voucher, số dư trừ đúng 1 lần.
  bool _redeeming = false;

  Color _tierColor(String t) => switch (t) {
        'DIAMOND' => const Color(0xFF3AAFA9),
        'PLATINUM' => const Color(0xFF6B7B8C),
        'GOLD' => const Color(0xFFD4A017),
        _ => const Color(0xFF9E9E9E),
      };

  @override
  Widget build(BuildContext context) {
    final accAsync = ref.watch(loyaltyAccountProvider);
    final vouchersAsync = ref.watch(loyaltyVouchersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(trg('rewards'))),
      body: accAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(loyaltyAccountProvider)),
        data: (acc) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _balanceCard(acc),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _redeeming ? null : () => _redeem(context, ref, acc),
                icon: _redeeming
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.card_giftcard),
                label: Text(trg('loyalty.redeem')),
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(trg('loyalty.myVouchers')),
            vouchersAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text(e.toString(), style: const TextStyle(color: AppTheme.muted)),
              data: (list) => list.isEmpty
                  ? Text(trg('loyalty.noVouchers'), style: const TextStyle(color: AppTheme.muted))
                  : Column(children: [for (final v in list) _voucherTile(v)]),
            ),
            const SizedBox(height: 22),
            SectionHeader(trg('loyalty.pointHistory')),
            if (acc.history.isEmpty)
              Text(trg('loyalty.noTxn'), style: const TextStyle(color: AppTheme.muted))
            else
              Column(children: [for (final t in acc.history) _txnTile(t)]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(LoyaltyAccount acc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brand, AppTheme.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.rCard),
        boxShadow: [BoxShadow(color: AppTheme.brand.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(trg('loyalty.available'), style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _tierColor(acc.tier), borderRadius: BorderRadius.circular(20)),
                child: Text(trg('loyalty.tier').replaceAll('{v}', acc.tier), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${acc.balance}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
          Text(trg('loyalty.approxRedeem').replaceAll('{v}', formatVnd(acc.balance * acc.pointValue)), style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 6),
          Text(trg('loyalty.lifetime').replaceAll('{v}', '${acc.lifetimeEarned}'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _voucherTile(RedeemedVoucher v) {
    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.confirmation_number_outlined, color: v.used ? AppTheme.muted : _brand),
        title: Text(v.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(trg('loyalty.discount').replaceAll('{v}', formatVnd(v.value)) +
            (v.expiresAt != null ? trg('loyalty.expiry').replaceAll('{v}', dmy(v.expiresAt!)) : '')),
        trailing: v.used
            ? StatusBadge(trg('loyalty.used'), AppTheme.muted)
            : StatusBadge(trg('loyalty.valid'), AppTheme.brand),
      ),
    );
  }

  Widget _txnTile(LoyaltyTxn t) {
    final earn = t.points >= 0;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(earn ? Icons.add_circle_outline : Icons.remove_circle_outline,
          color: earn ? _brand : Colors.redAccent, size: 20),
      title: Text(t.description ?? t.type, style: const TextStyle(fontSize: 13.5)),
      subtitle: t.createdAt == null ? null : Text(dmy(t.createdAt!), style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
      trailing: Text('${earn ? '+' : ''}${t.points}',
          style: TextStyle(fontWeight: FontWeight.w700, color: earn ? _brand : Colors.redAccent)),
    );
  }

  Future<void> _redeem(BuildContext context, WidgetRef ref, LoyaltyAccount acc) async {
    final ctrl = TextEditingController(text: acc.minRedeem > 0 ? '${acc.minRedeem}' : '');
    final points = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('loyalty.redeem')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trg('loyalty.balance').replaceAll('{v}', '${acc.balance}'), style: const TextStyle(color: AppTheme.muted)),
            Text(trg('loyalty.minRedeem').replaceAll('{a}', '${acc.minRedeem}').replaceAll('{b}', formatVnd(acc.pointValue)),
                style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: trg('loyalty.pointsToRedeem'), border: const OutlineInputBorder(), isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(trg('common.cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim())),
            child: Text(trg('loyalty.exchange')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (points == null) return;
    // Có 1 lệnh đổi đang chạy thì bỏ qua lệnh mới (chống bấm chồng → nhiều voucher).
    if (_redeeming) return;
    setState(() => _redeeming = true);
    try {
      final code = await ref.read(loyaltyRepositoryProvider).redeem(points);
      ref.invalidate(loyaltyAccountProvider);
      ref.invalidate(loyaltyVouchersProvider);
      ref.invalidate(myOffersProvider); // voucher đổi điểm cũng nằm ở "Ưu đãi của tôi"
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('loyalty.redeemed').replaceAll('{v}', code))));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('loyalty.redeemFailed'))));
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }
}
