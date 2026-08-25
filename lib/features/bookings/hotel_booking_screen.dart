import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import '../group/group_repository.dart';
import '../hotels/hotel_search.dart';
import '../hotels/hotels_controller.dart';
import '../hotels/room_models.dart';
import '../home/home_shell.dart';
import 'booking_models.dart';
import 'booking_repository.dart';
import 'payment_flow.dart';

/// GĐ2: chọn phòng → ngày → tên khách → số phòng → tạo đơn → thanh toán (giả lập).
class HotelBookingScreen extends ConsumerStatefulWidget {
  final int hotelId;
  final String hotelName;
  final int? preselectRoomId;
  const HotelBookingScreen(
      {super.key, required this.hotelId, required this.hotelName, this.preselectRoomId});

  @override
  ConsumerState<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends ConsumerState<HotelBookingScreen> {
  RoomType? _room;
  late DateTime _checkIn;
  late DateTime _checkOut;
  final _guest = TextEditingController();
  int _rooms = 1;
  bool _submitting = false;

  bool _dayUse = false;
  TimeOfDay _timeIn = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _timeOut = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    // Điền sẵn theo bối cảnh tìm kiếm (ngày + số phòng + kiểu ở) từ màn tìm khách sạn.
    final s = ref.read(hotelSearchProvider);
    _checkIn = s.checkIn;
    _checkOut = s.checkOut;
    _rooms = s.rooms;
    _dayUse = s.dayUse;
  }

  int get _durationMinutes => (_timeOut.hour * 60 + _timeOut.minute) - (_timeIn.hour * 60 + _timeIn.minute);

  String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTimeIn() async {
    final t = await showTimePicker(context: context, initialTime: _timeIn);
    if (t != null) setState(() => _timeIn = t);
  }

  Future<void> _pickTimeOut() async {
    final t = await showTimePicker(context: context, initialTime: _timeOut);
    if (t != null) setState(() => _timeOut = t);
  }

  @override
  void dispose() {
    _guest.dispose();
    super.dispose();
  }

  int get _nights {
    final d = _checkOut.difference(_checkIn).inDays;
    return d < 1 ? 1 : d;
  }

  num get _estTotal {
    final base = _room?.basePrice ?? 0;
    if (_dayUse) {
      if (_durationMinutes <= 0) return 0; // giờ trả chưa hợp lệ → không hiện giá ảo
      final factor = _durationMinutes <= 240 ? 0.5 : 1.0;
      return base * factor * _rooms;
    }
    return base * _nights * _rooms;
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _checkIn,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        _checkIn = d;
        if (!_checkOut.isAfter(_checkIn)) _checkOut = _checkIn.add(const Duration(days: 1));
      });
    }
  }

  Future<void> _pickCheckOut() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _checkOut,
      firstDate: _checkIn.add(const Duration(days: 1)),
      lastDate: _checkIn.add(const Duration(days: 366)),
    );
    if (d != null) setState(() => _checkOut = d);
  }

  Future<void> _submit() async {
    final room = _room;
    if (room == null) return _snack(trg('hotel.pickRoomType'));
    if (_guest.text.trim().isEmpty) return _snack(trg('hotel.enterGuestName'));
    if (_dayUse) {
      if (_durationMinutes <= 0) return _snack(trg('hotel.checkOutTimeAfter'));
    } else {
      if (!_checkOut.isAfter(_checkIn)) return _snack(trg('hotel.checkOutDateAfter'));
    }

    setState(() => _submitting = true);
    final repo = ref.read(bookingRepositoryProvider);
    try {
      final booking = await repo.createHotelBooking(
        hotelId: widget.hotelId,
        roomTypeId: room.id,
        roomName: room.name,
        guestName: _guest.text.trim(),
        checkIn: ymd(_checkIn),
        checkOut: _dayUse ? ymd(_checkIn) : ymd(_checkOut),
        rooms: _rooms,
        dayUse: _dayUse,
        checkInTime: _dayUse ? _hhmm(_timeIn) : null,
        checkOutTime: _dayUse ? _hhmm(_timeOut) : null,
      );
      if (!mounted) return;

      final confirmed = await runPaymentFlow(context, ref, booking);
      if (!mounted) return;
      if (confirmed != null && confirmed.status == 'CONFIRMED') {
        await _successDialog(confirmed);
      } else if (confirmed == null) {
        _snack(trg('hotel.orderCreatedPending').replaceAll('{code}', booking.publicCode));
      }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack(trg('common.error'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _successDialog(Booking b) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(trg('hotel.bookSuccessTitle')),
          content: Text(trg('hotel.bookSuccessBody')
              .replaceAll('{code}', b.publicCode)
              .replaceAll('{status}', b.statusLabel)
              .replaceAll('{amount}', formatVnd(b.amount))),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (context.mounted) context.go('/');
              },
              child: Text(trg('hotel.backToHome')),
            ),
            FilledButton(
              onPressed: () {
                ref.read(homeTabProvider.notifier).state = 3; // tab "Đơn của tôi"
                Navigator.pop(ctx);
                if (context.mounted) context.go('/');
              },
              child: Text(trg('hotel.viewMyOrders')),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(hotelRoomsProvider(widget.hotelId));
    return Scaffold(
      appBar: AppBar(title: Text(trg('hotel.book'))),
      body: Column(
        children: [
          Expanded(
            child: roomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                  error: e, onRetry: () => ref.invalidate(hotelRoomsProvider(widget.hotelId))),
              data: (rooms) {
                _applyPreselect(rooms);
                return rooms.isEmpty ? _empty() : _form(rooms);
              },
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  bool _preselectDone = false;
  void _applyPreselect(List<RoomType> rooms) {
    if (_preselectDone || _room != null || widget.preselectRoomId == null) return;
    _preselectDone = true;
    RoomType? match;
    for (final r in rooms) {
      if (r.id == widget.preselectRoomId) {
        match = r;
        break;
      }
    }
    if (match != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _room = match);
      });
    }
  }

  Widget _empty() => EmptyState(
        icon: Icons.meeting_room_outlined,
        title: trg('hotel.noRoomsTitle'),
        message: trg('hotel.noRoomsMsg'),
      );

  Widget _form(List<RoomType> rooms) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.hotelName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.ink, letterSpacing: -0.3)),
        const SizedBox(height: 16),
        _SectionLabel(trg('hotel.chooseRoomType')),
        const SizedBox(height: 8),
        for (final r in rooms) _roomTile(r),
        const SizedBox(height: 12),
        Row(children: [
          _SectionLabel(trg('hotel.stayTime')),
          const Spacer(),
          _stayToggle(),
        ]),
        const SizedBox(height: 8),
        if (_dayUse) ...[
          Row(children: [_dateBox(trg('hotel.date'), _checkIn, _pickCheckIn)]),
          const SizedBox(height: 10),
          Row(children: [
            _timeBox(trg('hotel.timeIn'), _timeIn, _pickTimeIn),
            const SizedBox(width: 12),
            _timeBox(trg('hotel.timeOut'), _timeOut, _pickTimeOut),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _durationMinutes > 0
                  ? trg('hotel.duration')
                      .replaceAll('{t}', '${_durationMinutes ~/ 60}h${(_durationMinutes % 60).toString().padLeft(2, '0')}')
                      .replaceAll('{p}', _durationMinutes <= 240 ? trg('hotel.halfPrice') : trg('hotel.fullPrice'))
                  : trg('hotel.checkOutTimeAfterShort'),
              style: const TextStyle(fontSize: 12.5, color: AppTheme.muted),
            ),
          ),
        ] else ...[
          Row(children: [
            _dateBox(trg('hotel.checkIn'), _checkIn, _pickCheckIn),
            const SizedBox(width: 12),
            _dateBox(trg('hotel.checkOut'), _checkOut, _pickCheckOut),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(trg('hotel.nightsCount').replaceAll('{n}', '$_nights'), style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
          ),
        ],
        const SizedBox(height: 16),
        _SectionLabel(trg('hotel.guestName')),
        const SizedBox(height: 8),
        TextField(
          controller: _guest,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: trg('hotel.guestNameHint'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Text(trg('hotel.roomCount'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.ink)),
          const Spacer(),
          IconButton.outlined(
            onPressed: _rooms > 1 ? () => setState(() => _rooms--) : null,
            icon: const Icon(Icons.remove),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$_rooms', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          IconButton.outlined(
            onPressed: _rooms < 9 ? () => setState(() => _rooms++) : null,
            icon: const Icon(Icons.add),
          ),
        ]),
        if (!_dayUse) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _createGroup,
            icon: const Icon(Icons.groups_outlined),
            label: Text(trg('hotel.groupBooking')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _submitting
                ? null
                : () {
                    if (_room == null) return _snack(trg('hotel.pickRoomFirst'));
                    context.push('/bulk', extra: {
                      'hotelId': widget.hotelId,
                      'roomTypeId': _room!.id,
                      'roomName': _room!.name,
                      'hotelName': widget.hotelName,
                      'checkIn': ymd(_checkIn),
                      'checkOut': ymd(_checkOut),
                    });
                  },
            icon: const Icon(Icons.people_alt_outlined),
            label: Text(trg('hotel.bulkBooking')),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _createGroup() async {
    final room = _room;
    if (room == null) return _snack(trg('hotel.pickRoomFirst'));
    if (!_checkOut.isAfter(_checkIn)) return _snack(trg('hotel.checkOutDateAfter'));
    setState(() => _submitting = true);
    try {
      final g = await ref.read(groupRepositoryProvider).create(
            hotelId: widget.hotelId,
            roomTypeId: room.id,
            roomName: room.name,
            checkIn: ymd(_checkIn),
            checkOut: ymd(_checkOut),
            title: widget.hotelName,
          );
      if (!mounted) return;
      context.push('/groups/${g.token}');
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack(trg('hotel.groupCreateError'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _roomTile(RoomType r) {
    final selected = _room?.id == r.id;
    return InkWell(
      onTap: () => setState(() => _room = r),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandSoft : AppTheme.surface,
          border: Border.all(
              color: selected ? AppTheme.brand : AppTheme.line, width: selected ? 1.6 : 1),
          borderRadius: BorderRadius.circular(AppTheme.rControl),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? AppTheme.brand : AppTheme.muted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
                  if (r.capacity != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(trg('hotel.capacityMax').replaceAll('{n}', '${r.capacity}'),
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
                    ),
                  if (r.description != null && r.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(r.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatVnd(r.basePrice),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.brand)),
                Text(trg('hotel.perNight'), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stayToggle() {
    Widget seg(String label, bool val) {
      final active = _dayUse == val;
      return InkWell(
        onTap: () => setState(() => _dayUse = val),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: active ? AppTheme.brand : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.muted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F3), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg(trg('hotel.overnight'), false), seg(trg('hotel.dayUse'), true)]),
    );
  }

  Widget _timeBox(String label, TimeOfDay value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.line),
            borderRadius: BorderRadius.circular(AppTheme.rControl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time, size: 14, color: AppTheme.muted),
                const SizedBox(width: 6),
                Text(value.format(context), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateBox(String label, DateTime value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.line),
            borderRadius: BorderRadius.circular(AppTheme.rControl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.muted),
                const SizedBox(width: 6),
                Text(dmy(value), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(trg('hotel.subtotal'), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                  Text(_room == null ? '—' : formatVnd(_estTotal),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.brand)),
                  if (_room != null)
                    Text(
                        _dayUse
                            ? trg('hotel.byHourRooms').replaceAll('{r}', '$_rooms')
                            : trg('hotel.nightsRooms').replaceAll('{n}', '$_nights').replaceAll('{r}', '$_rooms'),
                        style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: (_submitting || _room == null) ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(trg('hotel.bookAndPay')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(color: AppTheme.brand, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.ink, letterSpacing: -0.2)),
        ],
      );
}
