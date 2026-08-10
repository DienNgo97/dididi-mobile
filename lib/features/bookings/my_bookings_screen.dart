import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import 'booking_models.dart';
import 'booking_repository.dart';

const _brand = AppTheme.brand;

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  String _kind = 'all'; // all | HOTEL | FLIGHT | GROUP
  String _status = 'all'; // all | PENDING_PAYMENT | CONFIRMED | CANCELLED

  List<Booking> _apply(List<Booking> all) => all.where((b) {
        if (_kind == 'HOTEL' && b.type != 'HOTEL') return false;
        if (_kind == 'FLIGHT' && b.type != 'FLIGHT') return false;
        if (_kind == 'GROUP' && b.groupId == null) return false;
        if (_status != 'all' && b.status != _status) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myBookingsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(myBookingsProvider)),
      data: (all) {
        if (all.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: trg('booking.emptyTitle'),
            message: trg('booking.emptyMsg'),
          );
        }
        final list = _apply(all);
        return Column(
          children: [
            _filterBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(myBookingsProvider),
                child: list.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: trg('booking.noMatchTitle'),
                          message: trg('booking.noMatchMsg'),
                        ),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _BookingCard(b: list[i]),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterBar() {
    Widget chip(String label, bool sel, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: sel,
            onSelected: (_) => onTap(),
            selectedColor: _brand,
            labelStyle: TextStyle(color: sel ? Colors.white : AppTheme.ink, fontSize: 12.5),
            visualDensity: VisualDensity.compact,
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              chip(trg('booking.filterAll'), _kind == 'all', () => setState(() => _kind = 'all')),
              chip(trg('hotels'), _kind == 'HOTEL', () => setState(() => _kind = 'HOTEL')),
              chip(trg('flights'), _kind == 'FLIGHT', () => setState(() => _kind = 'FLIGHT')),
              chip(trg('booking.filterGroup'), _kind == 'GROUP', () => setState(() => _kind = 'GROUP')),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              chip(trg('booking.anyStatus'), _status == 'all', () => setState(() => _status = 'all')),
              chip(trg('booking.statusPending'), _status == 'PENDING_PAYMENT', () => setState(() => _status = 'PENDING_PAYMENT')),
              chip(trg('booking.statusConfirmed'), _status == 'CONFIRMED', () => setState(() => _status = 'CONFIRMED')),
              chip(trg('booking.statusCancelled'), _status == 'CANCELLED', () => setState(() => _status = 'CANCELLED')),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking b;
  const _BookingCard({required this.b});

  Color get _statusColor => switch (b.status) {
        'CONFIRMED' => AppTheme.brand,
        'PENDING_PAYMENT' => AppTheme.amber,
        'CANCELLED' => const Color(0xFFD64545),
        _ => AppTheme.muted,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/bookings/${b.publicCode}', extra: b),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(b.type == 'FLIGHT' ? Icons.flight : Icons.hotel, size: 18, color: AppTheme.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(b.title ?? b.publicCode,
                    // 2 dòng: tên "Khách sạn — Hạng phòng" dài hay bị cắt cụt ở 1 dòng.
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              StatusBadge(b.statusLabel, _statusColor),
            ]),
            const SizedBox(height: 8),
            Text('${trg('booking.codeWord')}: ${b.publicCode}', style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
            if (b.checkIn != null)
              // Ngày theo dd/MM/yyyy cho đồng bộ toàn app (trước đây hiện thô yyyy-MM-dd).
              Text('${dmyStr(b.checkIn)}${b.checkOut == null ? '' : ' → ${dmyStr(b.checkOut)}'}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
            const SizedBox(height: 6),
            Text(formatVnd(b.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: _brand)),
          ],
      ),
    );
  }
}
