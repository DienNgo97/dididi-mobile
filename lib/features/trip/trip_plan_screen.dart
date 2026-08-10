import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../auth/auth_providers.dart';
import '../bookings/booking_models.dart';
import '../bookings/booking_repository.dart';
import '../bookings/payment_flow.dart';
import '../flights/flight_models.dart';
import '../flights/flight_repository.dart';
import '../hotels/hotel_models.dart';
import '../hotels/hotel_repository.dart';
import 'trip_models.dart';
import 'trip_repository.dart';

const _brand = AppTheme.brand;

/// Lập kế hoạch chuyến đi TRỌN GÓI: chọn chuyến bay đi + về + khách sạn,
/// đặt cả 3 rồi thanh toán tuần tự (giống luồng Trip Planner trên web).
class TripPlanScreen extends ConsumerStatefulWidget {
  const TripPlanScreen({super.key});
  @override
  ConsumerState<TripPlanScreen> createState() => _TripPlanScreenState();
}

enum _Phase { form, select, booked }

class _TripPlanScreenState extends ConsumerState<TripPlanScreen> {
  final _city = TextEditingController();
  final _from = TextEditingController();
  DateTime _depart = DateTime.now().add(const Duration(days: 2));
  DateTime _return = DateTime.now().add(const Duration(days: 5));

  _Phase _phase = _Phase.form;
  bool _busy = false;
  String? _error;

  TripSuggestion? _sugg; // chuyến bay ĐI + khách sạn + destAirport
  List<Flight> _returnFlights = const [];
  Flight? _selOut;
  Flight? _selReturn;
  Hotel? _selHotel;

  List<Booking> _created = const [];

  @override
  void dispose() {
    _city.dispose();
    _from.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  int get _nights {
    final d = _return.difference(_depart).inDays;
    return d < 1 ? 1 : (d > 60 ? 60 : d);
  }

  num get _total {
    num t = 0;
    if (_selOut != null) t += _selOut!.price ?? 0;
    if (_selReturn != null) t += _selReturn!.price ?? 0;
    if (_selHotel != null) t += (_selHotel!.minPrice ?? 0) * _nights;
    return t;
  }

  Future<void> _search() async {
    final city = _city.text.trim();
    final from = _from.text.trim().toUpperCase();
    if (city.isEmpty || from.isEmpty) {
      _snack(trg('trip.enterDestAirport'));
      return;
    }
    if (!_return.isAfter(_depart)) {
      _snack(trg('trip.returnAfterDepart'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sugg = await ref.read(tripRepositoryProvider).suggest(city, from: from);
      final dest = sugg.destinationAirport;
      List<Flight> ret = const [];
      if (dest != null && dest.isNotEmpty) {
        ret = await ref.read(flightRepositoryProvider).search(from: dest, to: from, date: _fmt(_return));
      }
      if (mounted) {
        setState(() {
          _sugg = sugg;
          _returnFlights = ret;
          _selOut = _selReturn = null;
          _selHotel = null;
          _phase = _Phase.select;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = trg('trip.searchFail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bookAll() async {
    if (_selOut == null || _selReturn == null || _selHotel == null) return;
    setState(() => _busy = true);
    try {
      final email = ref.read(authControllerProvider).email ?? 'khach@dididi.local';
      final name = email.split('@').first;
      final bookingRepo = ref.read(bookingRepositoryProvider);

      final out = await bookingRepo.createFlightBooking(
          flightId: _selOut!.id, passengerName: name, contactEmail: email, seats: 1);
      final ret = await bookingRepo.createFlightBooking(
          flightId: _selReturn!.id, passengerName: name, contactEmail: email, seats: 1);

      // Khách sạn: lấy loại phòng rẻ nhất của KS đã chọn.
      final rooms = await ref.read(hotelRepositoryProvider).rooms(_selHotel!.id);
      if (rooms.isEmpty) {
        _snack(trg('trip.hotelNoRooms'));
        setState(() => _busy = false);
        return;
      }
      rooms.sort((a, b) => (a.basePrice ?? 0).compareTo(b.basePrice ?? 0));
      final room = rooms.first;
      final hotel = await bookingRepo.createHotelBooking(
        hotelId: _selHotel!.id,
        roomTypeId: room.id,
        roomName: room.name,
        guestName: name,
        checkIn: _fmt(_depart),
        checkOut: _fmt(_return),
        rooms: 1,
      );

      ref.invalidate(myBookingsProvider);
      if (mounted) {
        setState(() {
          _created = [out, ret, hotel];
          _phase = _Phase.booked;
        });
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(trg('trip.bookPackFail').replaceAll('{err}', '$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay(int index) async {
    final confirmed = await runPaymentFlow(context, ref, _created[index]);
    if (!mounted || confirmed == null) return;
    final list = [..._created];
    list[index] = confirmed;
    setState(() => _created = list);
    ref.invalidate(myBookingsProvider);
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trg('trip.packageTitle'))),
      body: switch (_phase) {
        _Phase.form => _formView(),
        _Phase.select => _selectView(),
        _Phase.booked => _bookedView(),
      },
    );
  }

  // ---------------- Bước 1: nhập thông tin ----------------
  Widget _formView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(trg('trip.formIntro'),
            style: const TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 16),
        TextField(
          controller: _city,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
              labelText: trg('trip.destLabel'), border: const OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _from,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
              labelText: trg('trip.fromAirport'), border: const OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _dateField(trg('flight.departDate'), _depart, (d) => setState(() {
                _depart = d;
                if (!_return.isAfter(_depart)) _return = _depart.add(const Duration(days: 1));
              }))),
          const SizedBox(width: 12),
          Expanded(child: _dateField(trg('trip.returnDate'), _return, (d) => setState(() => _return = d), first: _depart.add(const Duration(days: 1)))),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _search,
          icon: _busy
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.search),
          label: Text(trg('trip.searchPackage')),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ],
    );
  }

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onPick, {DateTime? first}) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
            context: context, initialDate: value, firstDate: first ?? DateTime.now(), lastDate: DateTime(2100));
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        child: Text(_fmt(value)),
      ),
    );
  }

  // ---------------- Bước 2: chọn ----------------
  Widget _selectView() {
    final s = _sugg!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle('${trg('trip.outboundFlight')}  (${_from.text.trim().toUpperCase()} → ${s.destinationAirport ?? '?'})'),
              if (s.flights.isEmpty) _empty(trg('trip.noOutbound')),
              for (final f in s.flights.take(6)) _flightTile(f, _selOut, (v) => setState(() => _selOut = v)),
              const SizedBox(height: 16),
              _sectionTitle('${trg('trip.returnFlight')}  (${s.destinationAirport ?? '?'} → ${_from.text.trim().toUpperCase()})'),
              if (_returnFlights.isEmpty) _empty(trg('trip.noReturn')),
              for (final f in _returnFlights.take(6)) _flightTile(f, _selReturn, (v) => setState(() => _selReturn = v)),
              const SizedBox(height: 16),
              _sectionTitle(trg('trip.hotelsInCity').replaceAll('{city}', s.city ?? '').replaceAll('{n}', '$_nights')),
              if (s.hotels.isEmpty) _empty(trg('trip.noHotel')),
              for (final h in s.hotels.take(8)) _hotelTile(h),
              const SizedBox(height: 90),
            ],
          ),
        ),
        _bottomBar(),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SectionHeader(t));

  Widget _empty(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(color: AppTheme.muted)));

  Widget _flightTile(Flight f, Flight? sel, ValueChanged<Flight> onSel) {
    final active = sel?.id == f.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: active ? AppTheme.brandSoft : null,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: active ? _brand : AppTheme.line)),
      child: ListTile(
        leading: Icon(active ? Icons.check_circle : Icons.flight, color: _brand),
        title: Text('${f.from} → ${f.to} · ${f.airlineCode ?? ''} ${f.flightNumber}'.trim()),
        subtitle: Text(f.departureTime == null ? '' : '${hm(f.departureTime!)} · ${dmy(f.departureTime!)}'),
        trailing: Text(formatVnd(f.price), style: const TextStyle(fontWeight: FontWeight.w700, color: _brand)),
        onTap: () => onSel(f),
      ),
    );
  }

  Widget _hotelTile(Hotel h) {
    final active = _selHotel?.id == h.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: active ? AppTheme.brandSoft : null,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: active ? _brand : AppTheme.line)),
      child: ListTile(
        leading: Icon(active ? Icons.check_circle : Icons.hotel, color: _brand),
        title: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${h.starRating != null ? '${'★' * h.starRating!} ' : ''}${h.city ?? ''}'),
        trailing: h.minPrice != null
            ? Text('${formatVnd(h.minPrice)}/${trg('common.night')}', style: const TextStyle(fontWeight: FontWeight.w700, color: _brand))
            : null,
        onTap: () => setState(() => _selHotel = h),
      ),
    );
  }

  Widget _bottomBar() {
    final ready = _selOut != null && _selReturn != null && _selHotel != null;
    return Material(
      elevation: 10,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(trg('pay.subtotal'), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
              Text(formatVnd(_total), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _brand)),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: (!ready || _busy) ? null : _bookAll,
                  icon: _busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.shopping_cart_checkout),
                  label: Text(trg('trip.bookPackage')),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ---------------- Bước 3: đã đặt → thanh toán tuần tự ----------------
  Widget _bookedView() {
    final allPaid = _created.every((b) => b.status == 'CONFIRMED');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.brandSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.check_circle, color: _brand),
            const SizedBox(width: 10),
            Expanded(
                child: Text(allPaid ? trg('trip.allPaid') : trg('trip.threeCreated'),
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < _created.length; i++) _createdTile(i, _created[i]),
      ],
    );
  }

  Widget _createdTile(int i, Booking b) {
    final paid = b.status == 'CONFIRMED';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(b.type == 'HOTEL' ? Icons.hotel : Icons.flight, color: _brand, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(b.title ?? b.publicCode, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(formatVnd(b.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: _brand)),
            ]),
            const SizedBox(height: 4),
            Text('${trg('booking.codeWord')} ${b.publicCode} · ${b.statusLabel}',
                style: TextStyle(fontSize: 12.5, color: paid ? _brand : AppTheme.amber)),
            const SizedBox(height: 8),
            if (!paid)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _pay(i),
                  icon: const Icon(Icons.payment, size: 18),
                  label: Text(trg('common.pay')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
