import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import 'flight_models.dart';
import 'flight_repository.dart';
import 'flights_controller.dart';

const _brand = AppTheme.brand;

/// Bước 2 của luồng KHỨ HỒI: đã chọn chuyến đi (outboundId), giờ tìm & chọn chuyến VỀ
/// (đảo sân bay, ngày về đã chọn). Chỉ hiện chuyến về cất cánh SAU khi chuyến đi hạ cánh.
/// Chọn xong → mở màn đặt vé chuyến đi kèm returnId để đặt nối 2 chặng.
class ReturnFlightScreen extends ConsumerStatefulWidget {
  final int outboundId;
  final String dateYmd; // ngày về yyyy-MM-dd
  final String? cabin;
  const ReturnFlightScreen({super.key, required this.outboundId, required this.dateYmd, this.cabin});

  @override
  ConsumerState<ReturnFlightScreen> createState() => _ReturnFlightScreenState();
}

class _ReturnFlightScreenState extends ConsumerState<ReturnFlightScreen> {
  Future<List<Flight>>? _future; // tạo 1 lần khi biết chuyến đi, tránh search lại mỗi rebuild

  Future<List<Flight>> _searchReturn(Flight outbound) =>
      ref.read(flightRepositoryProvider).search(from: outbound.to, to: outbound.from, date: widget.dateYmd);

  @override
  Widget build(BuildContext context) {
    final outAsync = ref.watch(flightDetailProvider(widget.outboundId));
    return Scaffold(
      appBar: AppBar(title: Text(trg('flight.chooseReturnTitle'))),
      body: outAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
            message: e.toString(), onRetry: () => ref.invalidate(flightDetailProvider(widget.outboundId))),
        data: (outbound) {
          _future ??= _searchReturn(outbound);
          return FutureBuilder<List<Flight>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return ErrorView(
                    message: snap.error.toString(),
                    onRetry: () => setState(() => _future = _searchReturn(outbound)));
              }
              final all = snap.data ?? const <Flight>[];
              // Chuyến về phải khởi hành sau khi chuyến đi hạ cánh (trường hợp về cùng ngày).
              final flights = all
                  .where((r) =>
                      outbound.arrivalTime == null ||
                      r.departureTime == null ||
                      r.departureTime!.isAfter(outbound.arrivalTime!))
                  .toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _outboundSummary(outbound),
                  const SizedBox(height: 16),
                  SectionHeader(trg('flight.chooseReturnTitle'),
                      subtitle: '${outbound.to} → ${outbound.from}'),
                  const SizedBox(height: 8),
                  if (flights.isEmpty)
                    EmptyState(
                      icon: Icons.flight_land_outlined,
                      title: trg('flight.noFlightsTitle'),
                      message: trg('flight.noReturnFlights'),
                    )
                  else
                    for (final r in flights) ...[
                      _ReturnCard(
                        f: r,
                        onTap: () => context.push(
                            '/flights/${outbound.id}/book?returnId=${r.id}'
                            '${widget.cabin == null ? '' : '&cabin=${widget.cabin}'}'),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _outboundSummary(Flight f) {
    return AppCard(
      color: AppTheme.brandSoft,
      border: false,
      child: Column(children: [
        Row(children: [
          const Icon(Icons.flight_takeoff, size: 16, color: _brand),
          const SizedBox(width: 6),
          Pill(trg('flight.outboundLeg'), color: _brand),
          const Spacer(),
          Text('${f.airlineCode ?? ''} ${f.flightNumber}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${f.from} ${f.departureTime == null ? '' : hm(f.departureTime!)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const Icon(Icons.arrow_forward, size: 16, color: AppTheme.muted),
          Text('${f.to} ${f.arrivalTime == null ? '' : hm(f.arrivalTime!)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        if (f.departureTime != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(dmy(f.departureTime!), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
          ),
        ],
      ]),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final Flight f;
  final VoidCallback onTap;
  const _ReturnCard({required this.f, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(children: [
        Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: AppTheme.brandSoft, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.flight_land, size: 16, color: _brand),
          ),
          const SizedBox(width: 8),
          Text('${f.airlineCode ?? ''} ${f.flightNumber}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(formatVnd(f.price),
              style: const TextStyle(fontWeight: FontWeight.w800, color: _brand, fontSize: 15)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _endpoint(f.from, f.departureTime),
          const Expanded(child: Divider(color: AppTheme.line)),
          _endpoint(f.to, f.arrivalTime, alignEnd: true),
        ]),
        if (f.availableSeats != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(trg('flight.seatsLeft').replaceAll('{n}', '${f.availableSeats}'),
                style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
          ),
        ],
      ]),
    );
  }

  Widget _endpoint(String code, DateTime? t, {bool alignEnd = false}) => Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(t == null ? '--:--' : hm(t), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(code, style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
          if (t != null) Text(dm(t), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
        ],
      );
}
