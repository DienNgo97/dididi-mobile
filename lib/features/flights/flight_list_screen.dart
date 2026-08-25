import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import 'flight_models.dart';
import 'flights_controller.dart';

const _brand = AppTheme.brand;

class FlightListScreen extends ConsumerStatefulWidget {
  const FlightListScreen({super.key});
  @override
  ConsumerState<FlightListScreen> createState() => _FlightListScreenState();
}

class _FlightListScreenState extends ConsumerState<FlightListScreen> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  DateTime? _date;
  String? _cabin; // null=mọi hạng | ECONOMY | BUSINESS
  bool _round = false; // Khứ hồi: chọn thêm ngày về, đặt 2 chặng nối tiếp
  DateTime? _returnDate;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        _date = d;
        // Ngày về không được trước ngày đi.
        if (_returnDate != null && _returnDate!.isBefore(d)) _returnDate = null;
      });
    }
  }

  Future<void> _pickReturnDate() async {
    final now = DateTime.now();
    final first = _date ?? DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? first,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _returnDate = d);
  }

  void _search() {
    ref.read(flightSearchProvider.notifier).search(FlightQuery(
          from: _from.text.trim().toUpperCase(),
          to: _to.text.trim().toUpperCase(),
          date: _date == null ? null : ymd(_date!),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(flightSearchProvider);
    return Column(
      children: [
        _searchCard(),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                ErrorView(error: e, onRetry: () => ref.invalidate(flightSearchProvider)),
            data: (flights) {
              if (flights.isEmpty) {
                return EmptyState(
                  icon: Icons.flight_takeoff_outlined,
                  title: trg('flight.noFlightsTitle'),
                  message: trg('flight.noFlightsMsg'),
                );
              }
              final ctl = ref.read(flightSearchProvider.notifier);
              return RefreshIndicator(
                onRefresh: () async => ref.read(flightSearchProvider.notifier).refresh(),
                child: NotificationListener<ScrollUpdateNotification>(
                  // Nạp 20 chuyến kế khi NGƯỜI DÙNG cuộn XUỐNG và gần chạm đáy
                  // (chặn nạp dây chuyền lúc mới dựng, khi maxScrollExtent còn ~0).
                  onNotification: (n) {
                    final m = n.metrics;
                    final delta = n.scrollDelta ?? 0;
                    if (delta > 0 && m.maxScrollExtent > 0 && m.extentAfter < 400) ctl.loadMore();
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: flights.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == flights.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: ctl.hasMore
                                ? const SizedBox(
                                    height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    trg('flight.loadedAll')
                                        .replaceAll('{n}', '${flights.length}')
                                        .replaceAll('{total}', '${ctl.total}'),
                                    style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                          ),
                        );
                      }
                      return _FlightCard(
                          f: flights[i], cabin: _cabin, round: _round, returnDate: _returnDate);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _swap() {
    final t = _from.text;
    setState(() {
      _from.text = _to.text;
      _to.text = t;
    });
  }

  Widget _searchCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(children: [
            _tripChip(trg('flight.oneWay'), false),
            const SizedBox(width: 6),
            _tripChip(trg('flight.roundTrip'), true),
          ]),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(children: [
                Expanded(child: _codeField(_from, Icons.flight_takeoff, trg('flight.origin'), trg('flight.originHint'))),
                const SizedBox(width: 44),
                Expanded(child: _codeField(_to, Icons.flight_land, trg('flight.destination'), trg('flight.destHint'))),
              ]),
              Material(
                color: _brand,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _swap,
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(Icons.swap_horiz, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_round)
            _dateBox(trg('flight.departDate'), _date, trg('flight.anyDate'), _pickDate,
                onClear: _date == null ? null : () => setState(() => _date = null))
          else
            Row(children: [
              Expanded(
                child: _dateBox(trg('flight.departDate'), _date, trg('flight.anyDate'), _pickDate,
                    onClear: _date == null ? null : () => setState(() => _date = null)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dateBox(trg('flight.returnDate'), _returnDate, '—', _pickReturnDate,
                    onClear: _returnDate == null ? null : () => setState(() => _returnDate = null)),
              ),
            ]),
          const SizedBox(height: 12),
          // Cuộn ngang: nhãn + 3 chip vừa khít tiếng Việt nhưng TRÀN khi đổi sang EN/中.
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Center(
                  child: Text(trg('flight.cabinClass'),
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
                ),
                const SizedBox(width: 10),
                Center(child: _cabinChip(trg('flight.anyCabin'), null)),
                const SizedBox(width: 6),
                Center(child: _cabinChip(trg('flight.economy'), 'ECONOMY')),
                const SizedBox(width: 6),
                Center(child: _cabinChip(trg('flight.business'), 'BUSINESS')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _search,
              child: Text(trg('flight.search')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String label, DateTime? value, String emptyText, VoidCallback onTap,
      {VoidCallback? onClear}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
              Text(value == null ? emptyText : dmy(value),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (onClear != null)
            InkWell(onTap: onClear, child: const Icon(Icons.close, size: 16, color: AppTheme.muted)),
        ]),
      ),
    );
  }

  Widget _tripChip(String label, bool roundValue) {
    final active = _round == roundValue;
    return InkWell(
      onTap: () => setState(() => _round = roundValue),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.brandSoft : Colors.white,
          border: Border.all(color: active ? _brand : AppTheme.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? _brand : AppTheme.ink)),
      ),
    );
  }

  Widget _cabinChip(String label, String? value) {
    final active = _cabin == value;
    return InkWell(
      onTap: () => setState(() => _cabin = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppTheme.brandSoft : Colors.white,
          border: Border.all(color: active ? _brand : AppTheme.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: active ? _brand : AppTheme.ink)),
      ),
    );
  }

  Widget _codeField(TextEditingController c, IconData icon, String label, String hint) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
              TextField(
                controller: c,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.muted),
                ),
              ),
            ]),
          ),
        ]),
      );
}

class _FlightCard extends StatelessWidget {
  final Flight f;
  final String? cabin;
  final bool round;
  final DateTime? returnDate;
  const _FlightCard({required this.f, this.cabin, this.round = false, this.returnDate});

  void _open(BuildContext context) {
    if (!round) {
      context.push(
          cabin == null ? '/flights/${f.id}/book' : '/flights/${f.id}/book?cabin=$cabin',
          extra: f);
      return;
    }
    // Khứ hồi: cần ngày về, và ngày về không được trước ngày của chuyến đi đã chọn.
    if (returnDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(trg('flight.pickReturnDate'))));
      return;
    }
    final dep = f.departureTime;
    if (dep != null && returnDate!.isBefore(DateTime(dep.year, dep.month, dep.day))) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(trg('flight.returnBeforeOutbound'))));
      return;
    }
    context.push('/flights/return?outId=${f.id}&date=${ymd(returnDate!)}'
        '${cabin == null ? '' : '&cabin=$cabin'}');
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _open(context),
      child: Column(
          children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: AppTheme.brandSoft, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.flight, size: 16, color: _brand),
              ),
              const SizedBox(width: 8),
              Text('${f.airlineCode ?? ''} ${f.flightNumber}'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(formatVnd(f.price), style: const TextStyle(fontWeight: FontWeight.w800, color: _brand, fontSize: 15)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _endpoint(f.from, f.departureTime),
              Expanded(
                child: Column(children: [
                  Text(_duration(), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                  const Divider(height: 8, color: AppTheme.line),
                  const Icon(Icons.flight, size: 14, color: AppTheme.muted),
                ]),
              ),
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
          ],
        ),
      );
  }

  Widget _endpoint(String code, DateTime? t, {bool alignEnd = false}) => Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(t == null ? '--:--' : hm(t),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(code, style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
          if (t != null) Text(dm(t), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
        ],
      );

  String _duration() {
    if (f.departureTime == null || f.arrivalTime == null) return '';
    final mins = f.arrivalTime!.difference(f.departureTime!).inMinutes;
    if (mins <= 0) return '';
    return '${mins ~/ 60}h${(mins % 60).toString().padLeft(2, '0')}';
  }
}
