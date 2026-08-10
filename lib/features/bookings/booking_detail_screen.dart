import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../company/company_repository.dart';
import '../reviews/review_repository.dart';
import 'booking_models.dart';
import 'booking_repository.dart';
import 'payment_flow.dart';

const _brand = AppTheme.brand;

/// Chi tiết đơn: xem đầy đủ + thanh toán lại / huỷ / viết đánh giá.
class BookingDetailScreen extends ConsumerStatefulWidget {
  final Booking booking;
  const BookingDetailScreen({super.key, required this.booking});
  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  late Booking _b;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _b = widget.booking;
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Color get _statusColor => switch (_b.status) {
        'CONFIRMED' => _brand,
        'PENDING_PAYMENT' => AppTheme.amber,
        'CANCELLED' => const Color(0xFFD64545),
        _ => AppTheme.muted,
      };

  Future<void> _refresh() async {
    try {
      final b = await ref.read(bookingRepositoryProvider).getBooking(_b.publicCode);
      if (mounted) setState(() => _b = b);
      ref.invalidate(myBookingsProvider);
    } catch (_) {}
  }

  Future<void> _pay() async {
    final confirmed = await runPaymentFlow(context, ref, _b);
    if (!mounted) return;
    if (confirmed != null) {
      setState(() => _b = confirmed);
      ref.invalidate(myBookingsProvider);
    }
  }

  Future<void> _cancel() async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('booking.cancelTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trg('booking.cancelBody')),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: trg('booking.cancelReasonLabel'),
                hintText: trg('booking.cancelReasonHint'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('booking.no'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(trg('booking.cancelOrder')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(bookingRepositoryProvider).cancel(_b.publicCode, reason: reason.text.trim());
      _snack(trg('booking.cancelSent'));
      await _refresh();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(trg('booking.cancelFail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review() async {
    int rating = 5;
    final comment = TextEditingController();
    final List<XFile> photos = [];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(trg('booking.writeReview')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setS(() => rating = i),
                      icon: Icon(i <= rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF5A623), size: 30),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: comment,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: trg('booking.reviewHint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickMultiImage();
                    if (picked.isNotEmpty) setS(() => photos.addAll(picked));
                  },
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: Text(trg('booking.addPhoto')),
                ),
                const SizedBox(width: 8),
                if (photos.isNotEmpty)
                  Text(trg('booking.photosCount').replaceAll('{n}', '${photos.length}'),
                      style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.send'))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      final reviewId = await repo.create(_b.publicCode, rating, comment.text.trim().isEmpty ? null : comment.text.trim());
      if (photos.isNotEmpty) {
        final files = <MultipartFile>[];
        for (final x in photos) {
          files.add(MultipartFile.fromBytes(await x.readAsBytes(), filename: x.name));
        }
        await repo.uploadImages(reviewId, files);
      }
      _snack(trg('booking.reviewThanks'));
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(trg('booking.reviewFail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _edit() async {
    DateTime parse(String? s) => (s != null ? DateTime.tryParse(s) : null) ?? DateTime.now();
    DateTime checkIn = parse(_b.checkIn);
    DateTime checkOut = parse(_b.checkOut ?? _b.checkIn);
    if (!checkOut.isAfter(checkIn)) checkOut = checkIn.add(const Duration(days: 1));
    int rooms = _b.quantity;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(trg('booking.editOrder')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.login, color: _brand),
                title: Text(trg('booking.checkIn')),
                subtitle: Text(_fmtDate(checkIn)),
                onTap: () async {
                  final today = DateUtils.dateOnly(DateTime.now());
                  final init = checkIn.isBefore(today) ? today : checkIn;
                  final d = await showDatePicker(
                      context: ctx, initialDate: init, firstDate: today, lastDate: DateTime(2100));
                  if (d != null) {
                    setS(() {
                      checkIn = d;
                      if (!checkOut.isAfter(checkIn)) checkOut = checkIn.add(const Duration(days: 1));
                    });
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: _brand),
                title: Text(trg('booking.checkOut')),
                subtitle: Text(_fmtDate(checkOut)),
                onTap: () async {
                  final fd = checkIn.add(const Duration(days: 1));
                  final init = checkOut.isBefore(fd) ? fd : checkOut;
                  final d = await showDatePicker(
                      context: ctx, initialDate: init, firstDate: fd, lastDate: DateTime(2100));
                  if (d != null) setS(() => checkOut = d);
                },
              ),
              Row(
                children: [
                  Text(trg('booking.roomCount')),
                  const Spacer(),
                  IconButton(onPressed: rooms > 1 ? () => setS(() => rooms--) : null, icon: const Icon(Icons.remove_circle_outline)),
                  Text('$rooms', style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(onPressed: () => setS(() => rooms++), icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.save'))),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() => _busy = true);
    try {
      final b = await ref
          .read(bookingRepositoryProvider)
          .editOvernight(_b.publicCode, checkIn: _fmtDate(checkIn), checkOut: _fmtDate(checkOut), rooms: rooms);
      setState(() => _b = b);
      ref.invalidate(myBookingsProvider);
      _snack(trg('booking.updated'));
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('booking.editOnlyPending'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _voucher() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('pay.voucher')),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: trg('pay.enterVoucher'), border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.apply'))),
        ],
      ),
    );
    if (ok != true || c.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final b = await ref.read(bookingRepositoryProvider).applyVoucher(_b.publicCode, c.text.trim());
      setState(() => _b = b);
      ref.invalidate(myBookingsProvider);
      _snack(trg('pay.voucherApplied'));
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('pay.voucherInvalid'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payCompany(CompanyInfo company) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('pay.companyTitle')),
        content: Text(trg('pay.companyBody')
            .replaceAll('{name}', company.name)
            .replaceAll('{remaining}', formatVnd(company.budgetRemaining))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.confirm'))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(bookingRepositoryProvider).payCompany(_b.publicCode);
      setState(() => _b = r.booking);
      ref.invalidate(myBookingsProvider);
      _snack(r.outcome == 'CONFIRMED' ? trg('pay.companyPaid') : trg('pay.companyPending'));
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('pay.companyFail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invoice() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(bookingRepositoryProvider).invoiceBytes(_b.publicCode);
      final uri = Uri.dataFromBytes(Uint8List.fromList(bytes), mimeType: 'application/pdf');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(trg('booking.invoiceFail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHotel = _b.type == 'HOTEL';
    final pending = _b.status == 'PENDING_PAYMENT';
    final company = ref.watch(companyMeProvider).asData?.value;
    final confirmed = _b.status == 'CONFIRMED';
    final cancellable = pending || confirmed;
    return Scaffold(
      appBar: AppBar(title: Text(trg('booking.detailTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(_b.title ?? _b.publicCode, icon: isHotel ? Icons.hotel : Icons.flight),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _row(trg('booking.orderCode'), _b.publicCode),
                _row(trg('booking.status'), _b.statusLabel, color: _statusColor),
                if (_b.checkIn != null)
                  _row(isHotel ? trg('booking.date') : trg('flight.departDate'),
                      '${dmyStr(_b.checkIn)}'
                      '${_b.checkOut != null && _b.checkOut != _b.checkIn ? ' → ${dmyStr(_b.checkOut)}' : ''}'),
                _row(isHotel ? trg('booking.roomCount') : trg('booking.seatCount'), '${_b.quantity}'),
                _row(trg('common.total'), formatVnd(_b.amount), color: _brand, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (pending) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _pay,
                icon: const Icon(Icons.payment),
                label: Text(trg('booking.payNow')),
              ),
            ),
            const SizedBox(height: 10),
            if (company != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3A5BA0)),
                  onPressed: _busy ? null : () => _payCompany(company),
                  icon: const Icon(Icons.business_center_outlined),
                  label: Text(trg('pay.payWithCompany').replaceAll('{name}', company.name)),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _voucher,
                icon: const Icon(Icons.local_offer_outlined),
                label: Text(trg('booking.applyVoucherBtn')),
              ),
            ),
            const SizedBox(height: 10),
            if (isHotel) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _edit,
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: Text(trg('booking.editOrderBtn')),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
          if (confirmed && isHotel) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _review,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Viết đánh giá'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (confirmed) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _invoice,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Tải hoá đơn VAT'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (cancellable)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _cancel,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                icon: const Icon(Icons.close),
                label: const Text('Huỷ đơn'),
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 13))),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: color ?? AppTheme.ink)),
            ),
          ],
        ),
      );
}
