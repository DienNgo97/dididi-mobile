import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import 'bulk_models.dart';
import 'bulk_repository.dart';

const _brand = AppTheme.brand;

class _GuestRow {
  final TextEditingController name = TextEditingController();
  int rooms = 1;
}

/// Đặt hàng loạt: nhiều khách, cùng khách sạn/loại phòng/ngày (qua đêm).
class BulkBookingScreen extends ConsumerStatefulWidget {
  final int hotelId;
  final int roomTypeId;
  final String? roomName;
  final String hotelName;
  final String checkIn;
  final String checkOut;
  const BulkBookingScreen({
    super.key,
    required this.hotelId,
    required this.roomTypeId,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
    this.roomName,
  });

  @override
  ConsumerState<BulkBookingScreen> createState() => _BulkBookingScreenState();
}

class _BulkBookingScreenState extends ConsumerState<BulkBookingScreen> {
  final List<_GuestRow> _rows = [_GuestRow(), _GuestRow(), _GuestRow()];
  bool _busy = false;
  bool _dayUse = false;
  TimeOfDay _timeIn = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _timeOut = const TimeOfDay(hour: 13, minute: 0);
  List<BulkLineResult>? _results;

  String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    for (final r in _rows) {
      r.name.dispose();
    }
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    final guests = <Map<String, dynamic>>[];
    for (final r in _rows) {
      final n = r.name.text.trim();
      if (n.isNotEmpty) guests.add({'name': n, 'rooms': r.rooms});
    }
    if (guests.isEmpty) return _snack(trg('bulk.enterOneGuest'));
    if (_dayUse) {
      final dur = (_timeOut.hour * 60 + _timeOut.minute) - (_timeIn.hour * 60 + _timeIn.minute);
      if (dur <= 0) return _snack(trg('bulk.timeOutAfterIn'));
    }
    setState(() => _busy = true);
    try {
      final res = await ref.read(bulkRepositoryProvider).createHotelBulk(
            hotelId: widget.hotelId,
            roomTypeId: widget.roomTypeId,
            roomName: widget.roomName,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            guests: guests,
            dayUse: _dayUse,
            timeIn: _dayUse ? _hhmm(_timeIn) : null,
            timeOut: _dayUse ? _hhmm(_timeOut) : null,
          );
      if (mounted) setState(() => _results = res);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('bulk.bookFail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trg('bulk.title'))),
      body: _results != null ? _resultsView(_results!) : _form(),
    );
  }

  Widget _form() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.hotelName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                      _dayUse
                          ? '${widget.roomName ?? trg('bulk.room')} · ${trg('bulk.dayUse')} ${widget.checkIn} · ${_hhmm(_timeIn)}–${_hhmm(_timeOut)}'
                          : '${widget.roomName ?? trg('bulk.room')} · ${widget.checkIn} → ${widget.checkOut}',
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
                ]),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(trg('bulk.overnight')), icon: const Icon(Icons.nightlight_outlined)),
                  ButtonSegment(value: true, label: Text(trg('bulk.dayUse')), icon: const Icon(Icons.wb_sunny_outlined)),
                ],
                selected: {_dayUse},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _dayUse = s.first),
              ),
              if (_dayUse) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _timeField(trg('bulk.timeIn'), _timeIn, (t) => setState(() => _timeIn = t))),
                  const SizedBox(width: 10),
                  Expanded(child: _timeField(trg('bulk.timeOut'), _timeOut, (t) => setState(() => _timeOut = t))),
                ]),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(trg('bulk.dayUseNote'), style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                ),
              ],
              const SizedBox(height: 12),
              SectionHeader(trg('bulk.guestList'),
                  subtitle: trg('bulk.guestListSub')),
              const SizedBox(height: 8),
              for (int i = 0; i < _rows.length; i++) _guestRow(i),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _rows.add(_GuestRow())),
                  icon: const Icon(Icons.add),
                  label: Text(trg('bulk.addGuest')),
                ),
              ),
            ],
          ),
        ),
        Material(
          elevation: 8,
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(trg('bulk.bookAll')),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeField(String label, TimeOfDay value, ValueChanged<TimeOfDay> onPick) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: value);
        if (t != null) onPick(t);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        child: Text(_hhmm(value)),
      ),
    );
  }

  Widget _guestRow(int i) {
    final r = _rows[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: r.name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: trg('bulk.guestN').replaceAll('{n}', '${i + 1}'),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: r.rooms > 1 ? () => setState(() => r.rooms--) : null,
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('${r.rooms}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        IconButton.outlined(
          onPressed: () => setState(() => r.rooms++),
          icon: const Icon(Icons.add),
        ),
      ]),
    );
  }

  Widget _resultsView(List<BulkLineResult> res) {
    final okCount = res.where((r) => r.ok).length;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.brandSoft,
          child: Text(trg('bulk.resultSummary').replaceAll('{ok}', '$okCount').replaceAll('{total}', '${res.length}'),
              style: const TextStyle(color: _brand, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: res.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = res[i];
              return ListTile(
                leading: Icon(r.ok ? Icons.check_circle : Icons.error_outline, color: r.ok ? _brand : const Color(0xFFD64545)),
                title: Text(r.guest),
                subtitle: Text([
                  if (r.code != null) '${trg('booking.codeWord')}: ${r.code}',
                  r.statusLabel,
                  if (r.note != null) r.note!,
                ].join(' · ')),
              );
            },
          ),
        ),
      ],
    );
  }
}
