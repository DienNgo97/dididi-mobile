import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import '../auth/auth_providers.dart';
import '../bookings/booking_models.dart';
import '../bookings/booking_repository.dart';
import '../bookings/payment_flow.dart';
import '../home/home_shell.dart';
import 'flight_models.dart';
import 'flight_repository.dart';
import 'flight_seat_models.dart';
import 'flights_controller.dart';

const _brand = AppTheme.brand;

/// Đặt vé máy bay: thông tin TỪNG hành khách (tên + suất ăn + hành lý). Chuyến của hãng thì
/// chọn GHẾ (sơ đồ) — mỗi ghế là một hành khách; chuyến nội bộ thì chọn số hành khách.
class FlightBookingScreen extends ConsumerStatefulWidget {
  final int flightId;
  final String? cabin; // ECONOMY | BUSINESS — gợi ý hạng ghế từ màn tìm vé
  final int? returnFlightId; // KHỨ HỒI: id chuyến về — đặt xong chặng này thì mời đặt tiếp
  final String? leg; // 'return' = đang đặt chặng về (2/2)
  const FlightBookingScreen(
      {super.key, required this.flightId, this.cabin, this.returnFlightId, this.leg});
  @override
  ConsumerState<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends ConsumerState<FlightBookingScreen> {
  final _email = TextEditingController();
  int _seats = 1; // số hành khách với chuyến không có sơ đồ ghế
  final Set<String> _selSeats = {};
  // Dữ liệu từng hành khách, khoá theo MÃ GHẾ (chế độ sơ đồ) để dữ liệu bám đúng ghế
  // dù chọn ghế không theo thứ tự; chế độ không sơ đồ khoá 'p0','p1',...
  final Map<String, TextEditingController> _paxNames = {};
  final Map<String, String?> _paxMeals = {};
  final Map<String, String?> _paxBags = {};
  bool _submitting = false;

  TextEditingController _nameCtl(String key) => _paxNames.putIfAbsent(key, () => TextEditingController());

  /// Danh sách khoá hành khách theo đúng thứ tự hiển thị/gửi.
  List<String> _paxKeys(SeatMap? seatMap) => seatMap != null
      ? (_selSeats.toList()..sort())
      : [for (int i = 0; i < _seats; i++) 'p$i'];

  @override
  void initState() {
    super.initState();
    _email.text = ref.read(authControllerProvider).email ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    for (final c in _paxNames.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  num _addonPrice(List<Addon> list, String? code) {
    for (final a in list) {
      if (a.code == code) return a.price;
    }
    return 0;
  }

  Future<void> _submit(Flight f, SeatMap? seatMap) async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) return _snack(trg('flight.invalidEmail'));
    if (seatMap != null && _selSeats.isEmpty) return _snack(trg('flight.selectSeat'));

    final seatCodes = seatMap != null ? (_selSeats.toList()..sort()) : <String>[];
    final keys = _paxKeys(seatMap);
    final passengers = <Map<String, dynamic>>[];
    for (final key in keys) {
      final name = _nameCtl(key).text.trim();
      if (name.isEmpty) return _snack(trg('flight.enterAllNames'));
      passengers.add({
        'name': name,
        if (_paxMeals[key] != null) 'meal': _paxMeals[key],
        if (_paxBags[key] != null) 'bag': _paxBags[key],
      });
    }

    setState(() => _submitting = true);
    final repo = ref.read(bookingRepositoryProvider);
    try {
      final booking = await repo.bookFlightWithSeats(
        flightId: f.id,
        contactEmail: email,
        seatCodes: seatCodes,
        passengers: passengers,
      );
      if (!mounted) return;
      final confirmed = await runPaymentFlow(context, ref, booking);
      if (!mounted) return;
      if (widget.returnFlightId != null) {
        // Khứ hồi chặng 1: dù đã trả hay để sau, mời đặt tiếp chuyến về.
        await _continueReturnDialog(confirmed ?? booking);
      } else if (confirmed != null && confirmed.status == 'CONFIRMED') {
        await _successDialog(confirmed);
      } else if (confirmed == null) {
        _snack(trg('flight.orderCreatedPending').replaceAll('{code}', booking.publicCode));
      }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack(trg('common.error'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Khứ hồi: chặng đi đã đặt xong → mời đặt tiếp chuyến về (thay màn hiện tại
  /// bằng màn đặt chuyến về để back không quay lại form đã gửi).
  Future<void> _continueReturnDialog(Booking b) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(trg('flight.outboundLeg')),
          content: Text(trg('flight.outboundBooked').replaceAll('{code}', b.publicCode)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (context.mounted) {
                  ref.read(homeTabProvider.notifier).state = 3;
                  context.go('/');
                }
              },
              child: Text(trg('flight.laterViewOrders')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (context.mounted) {
                  context.pushReplacement(
                      '/flights/${widget.returnFlightId}/book?leg=return'
                      '${widget.cabin == null ? '' : '&cabin=${widget.cabin}'}');
                }
              },
              child: Text(trg('flight.continueReturn')),
            ),
          ],
        ),
      );

  Future<void> _successDialog(Booking b) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(trg('flight.bookSuccess')),
          content: Text(trg('flight.bookSuccessBody')
              .replaceAll('{code}', b.publicCode)
              .replaceAll('{status}', b.statusLabel)
              .replaceAll('{amount}', formatVnd(b.amount))),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (context.mounted) context.go('/');
              },
              child: Text(trg('flight.backHome')),
            ),
            FilledButton(
              onPressed: () {
                ref.read(homeTabProvider.notifier).state = 3;
                Navigator.pop(ctx);
                if (context.mounted) context.go('/');
              },
              child: Text(trg('flight.viewMyOrders')),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(flightDetailProvider(widget.flightId));
    return Scaffold(
      appBar: AppBar(title: Text(trg('flight.bookTitle'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
            message: e.toString(), onRetry: () => ref.invalidate(flightDetailProvider(widget.flightId))),
        data: (f) => _body(f),
      ),
    );
  }

  bool _cabinPreselectDone = false;
  // Tự chọn sẵn 1 ghế FREE đúng hạng đã tìm (giống web) — khách vẫn đổi được.
  void _applyCabinPreselect(SeatMap m) {
    if (_cabinPreselectDone || widget.cabin == null || _selSeats.isNotEmpty) return;
    _cabinPreselectDone = true;
    final wantBusiness = widget.cabin == 'BUSINESS';
    SeatItem? pick;
    for (final s in m.seats) {
      if (s.free && s.business == wantBusiness) {
        pick = s;
        break;
      }
    }
    if (pick != null) {
      final code = pick.code;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selSeats.add(code));
      });
    }
  }

  Widget _body(Flight f) {
    final seatAsync = ref.watch(seatMapProvider(widget.flightId));
    final addonsAsync = ref.watch(flightAddonsProvider);
    final seatMap = seatAsync.asData?.value;
    final addons = addonsAsync.asData?.value;
    if (seatMap != null) _applyCabinPreselect(seatMap);

    final seatCodes = seatMap != null ? (_selSeats.toList()..sort()) : <String>[];
    final keys = _paxKeys(seatMap);
    final int numSeats = keys.length;

    // Giá vé: có sơ đồ → cộng giá TỪNG ghế (ghế thương gia đắt hơn), khớp cách backend tính
    // (hold.totalPrice); không sơ đồ → giá vé × số khách.
    num total = 0;
    if (seatMap != null) {
      for (final code in seatCodes) {
        final s = seatMap.seats.firstWhere((e) => e.code == code,
            orElse: () => SeatItem(code: code, row: 0, col: ''));
        total += s.price ?? (f.price ?? 0);
      }
    } else {
      total = (f.price ?? 0) * _seats;
    }
    if (addons != null) {
      for (final key in keys) {
        total += _addonPrice(addons.meals, _paxMeals[key]) + _addonPrice(addons.bags, _paxBags[key]);
      }
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _flightSummary(f),
              const SizedBox(height: 20),
              SectionHeader(trg('flight.contactEmail')),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: trg('flight.emailForTicket'), border: const OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 20),
              if (seatAsync.isLoading)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
              else if (seatMap != null) ...[
                _seatSection(seatMap),
                const SizedBox(height: 20),
                _paxSection(seatCodes, addons, seatMapMode: true),
              ] else ...[
                _simpleSeats(f),
                const SizedBox(height: 20),
                _paxSection(const [], addons, seatMapMode: false),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
        _bottomBar(f, seatMap, total, numSeats),
      ],
    );
  }

  // ---------- Thông tin từng hành khách ----------
  Widget _paxSection(List<String> seatCodes, FlightAddonsData? addons, {required bool seatMapMode}) {
    final keys = seatMapMode ? seatCodes : [for (int i = 0; i < _seats; i++) 'p$i'];
    if (keys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(trg('flight.selectSeatToEnter'), style: const TextStyle(color: AppTheme.muted)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(trg('flight.passengersCount').replaceAll('{n}', '${keys.length}')),
        const SizedBox(height: 8),
        for (int i = 0; i < keys.length; i++)
          _paxCard(keys[i], i, seatMapMode ? keys[i] : null, addons),
      ],
    );
  }

  Widget _paxCard(String key, int index, String? seatCode, FlightAddonsData? addons) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(trg('flight.passengerN').replaceAll('{n}', '${index + 1}'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            if (seatCode != null) ...[
              const Spacer(),
              StatusBadge(trg('flight.seatN').replaceAll('{code}', seatCode), _brand),
            ],
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtl(key),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: trg('flight.passengerName'), border: const OutlineInputBorder(), isDense: true),
          ),
          if (addons != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trg('flight.meal'), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                  const SizedBox(height: 4),
                  _addonDropdown(addons.meals, _paxMeals[key], (v) => setState(() => _paxMeals[key] = v)),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trg('flight.baggage'), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                  const SizedBox(height: 4),
                  _addonDropdown(addons.bags, _paxBags[key], (v) => setState(() => _paxBags[key] = v)),
                ]),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  // ---------- Chuyến nội bộ: chọn số hành khách ----------
  Widget _simpleSeats(Flight f) {
    return Row(children: [
      Text(trg('flight.passengerCount'), style: const TextStyle(fontWeight: FontWeight.w600)),
      const Spacer(),
      IconButton.outlined(onPressed: _seats > 1 ? () => setState(() => _seats--) : null, icon: const Icon(Icons.remove)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('$_seats', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      IconButton.outlined(
        onPressed: (f.availableSeats == null || _seats < f.availableSeats!) ? () => setState(() => _seats++) : null,
        icon: const Icon(Icons.add),
      ),
    ]);
  }

  // ---------- Chuyến của hãng: sơ đồ ghế ----------
  Widget _seatSection(SeatMap m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(trg('flight.selectSeatTitle'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          if (widget.cabin != null) ...[
            const SizedBox(width: 8),
            Pill(widget.cabin == 'BUSINESS' ? trg('flight.business') : trg('flight.economy'),
                color: widget.cabin == 'BUSINESS' ? AppTheme.amber : _brand),
          ],
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 14, runSpacing: 4, children: [
          _Legend(color: const Color(0xFFEAF3EE), border: _brand, label: trg('flight.seatFree')),
          _Legend(color: _brand, border: _brand, label: trg('flight.seatSelecting'), filled: true),
          _Legend(color: const Color(0xFFECECEC), border: const Color(0xFFCCCCCC), label: trg('flight.seatBooked')),
          _Legend(color: const Color(0xFFFFF3E0), border: const Color(0xFFF5A623), label: trg('flight.business')),
        ]),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              for (int r = 1; r <= m.rows; r++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 24, child: Text('$r', style: const TextStyle(fontSize: 11, color: AppTheme.muted))),
                      for (int ci = 0; ci < m.cols.length; ci++) ...[
                        if (ci == (m.cols.length / 2).floor() && m.cols.length >= 4) const SizedBox(width: 14),
                        _seatBox(m.at(r, m.cols[ci])),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_selSeats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(trg('flight.selectedSeats').replaceAll('{seats}', (_selSeats.toList()..sort()).join(', ')),
                style: const TextStyle(color: _brand, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _seatBox(SeatItem? s) {
    if (s == null) return const SizedBox(width: 30, height: 30);
    final selected = _selSeats.contains(s.code);
    final booked = !s.free;
    Color bg;
    Color border;
    if (selected) {
      bg = _brand;
      border = _brand;
    } else if (booked) {
      bg = const Color(0xFFECECEC);
      border = const Color(0xFFCCCCCC);
    } else if (s.business) {
      bg = const Color(0xFFFFF3E0);
      border = const Color(0xFFF5A623);
    } else {
      bg = const Color(0xFFEAF3EE);
      border = _brand;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: booked
            ? null
            : () => setState(() {
                  if (selected) {
                    _selSeats.remove(s.code);
                  } else {
                    _selSeats.add(s.code);
                  }
                }),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: border)),
          alignment: Alignment.center,
          child: Text(s.col,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.muted)),
        ),
      ),
    );
  }

  Widget _addonDropdown(List<Addon> options, String? value, ValueChanged<String?> onChanged) {
    final current = value ?? (options.isNotEmpty ? options.first.code : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line), borderRadius: BorderRadius.circular(6)),
      child: DropdownButton<String>(
        value: current,
        isExpanded: true,
        isDense: true,
        underline: const SizedBox.shrink(),
        items: [
          for (final o in options)
            DropdownMenuItem(
              value: o.code,
              child: Text('${o.label}${o.price > 0 ? ' (+${formatVnd(o.price)})' : ''}',
                  overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _bottomBar(Flight f, SeatMap? seatMap, num total, int numSeats) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(trg('pay.subtotal'), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                Text(formatVnd(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _brand)),
                Text(trg('flight.passengersN').replaceAll('{n}', '$numSeats'),
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _submitting ? null : () => _submit(f, seatMap),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(trg('flight.bookAndPay')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _flightSummary(Flight f) {
    return AppCard(
      color: AppTheme.brandSoft,
      border: false,
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.flight, size: 18, color: _brand),
            const SizedBox(width: 8),
            Text('${f.airlineCode ?? ''} ${f.flightNumber}'.trim(), style: const TextStyle(fontWeight: FontWeight.w700)),
            if (widget.returnFlightId != null || widget.leg == 'return') ...[
              const Spacer(),
              Pill(
                widget.leg == 'return' ? trg('flight.legReturn') : trg('flight.legOutbound'),
                color: widget.leg == 'return' ? AppTheme.amber : _brand,
              ),
            ],
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.departureTime == null ? '--:--' : hm(f.departureTime!),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(f.from, style: const TextStyle(color: AppTheme.muted)),
              ]),
              const Icon(Icons.arrow_forward, color: AppTheme.muted),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(f.arrivalTime == null ? '--:--' : hm(f.arrivalTime!),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(f.to, style: const TextStyle(color: AppTheme.muted)),
              ]),
            ],
          ),
          if (f.departureTime != null) ...[
            const SizedBox(height: 8),
            Text(dmy(f.departureTime!), style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;
  final bool filled;
  const _Legend({required this.color, required this.border, required this.label, this.filled = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: border)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
      ]);
}
