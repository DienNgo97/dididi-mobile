import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../shared/format.dart';
import '../company/company_repository.dart';
import 'booking_models.dart';
import 'booking_repository.dart';

const _brand = Color(0xFF2F8B60);
const _corp = Color(0xFF3A5BA0);

/// Luồng thanh toán chung cho 1 đơn PENDING_PAYMENT (khách sạn hoặc vé).
/// Hộp thoại gộp đủ lựa chọn ngay tại đây: áp/gỡ mã giảm giá + chọn phương thức
/// (Giả lập / VNPay / Ngân sách công ty). Không phải sang màn chi tiết đơn nữa.
///
/// Trả về:
///  - Booking đã CONFIRMED (mock/vnpay/công ty duyệt ngay), hoặc
///  - Booking PENDING_APPROVAL (công ty chờ duyệt chi — đã báo snackbar), hoặc
///  - null nếu người dùng để đơn chờ / đóng hộp thoại.
Future<Booking?> runPaymentFlow(BuildContext context, WidgetRef ref, Booking booking) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(bookingRepositoryProvider);

  // Người dùng có thuộc công ty (còn hạn mức) không → quyết định hiện nút trả bằng công ty.
  CompanyInfo? companyTmp;
  try {
    companyTmp = await ref.read(companyMeProvider.future);
  } catch (_) {}
  final CompanyInfo? company = companyTmp;
  if (!context.mounted) return null;

  Booking current = booking; // cập nhật khi áp/gỡ voucher (đổi tổng tiền)
  final voucherCtl = TextEditingController();
  bool vBusy = false;
  String? vNote;
  bool vErr = false;

  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        Future<void> applyVoucher() async {
          final code = voucherCtl.text.trim();
          if (code.isEmpty) return;
          setLocal(() => vBusy = true);
          try {
            final b = await repo.applyVoucher(current.publicCode, code);
            current = b;
            setLocal(() {
              vNote = trg('pay.voucherAppliedCode').replaceAll('{code}', code);
              vErr = false;
            });
          } on ApiException catch (e) {
            setLocal(() {
              vNote = e.message;
              vErr = true;
            });
          } catch (_) {
            setLocal(() {
              vNote = trg('pay.voucherInvalid');
              vErr = true;
            });
          } finally {
            setLocal(() => vBusy = false);
          }
        }

        Future<void> removeVoucher() async {
          setLocal(() => vBusy = true);
          try {
            final b = await repo.removeVoucher(current.publicCode);
            current = b;
            voucherCtl.clear();
            setLocal(() {
              vNote = trg('pay.voucherRemoved');
              vErr = false;
            });
          } on ApiException catch (e) {
            setLocal(() {
              vNote = e.message;
              vErr = true;
            });
          } catch (_) {
            setLocal(() {
              vNote = trg('pay.voucherRemoveFail');
              vErr = true;
            });
          } finally {
            setLocal(() => vBusy = false);
          }
        }

        return AlertDialog(
          title: Text(trg('common.pay')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trg('pay.orderCode').replaceAll('{code}', current.publicCode)),
                const SizedBox(height: 6),
                Text(trg('pay.totalAmount').replaceAll('{amount}', formatVnd(current.amount)),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: _brand, fontSize: 16)),
                const SizedBox(height: 14),
                // ── Mã giảm giá ─────────────────────────────
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: voucherCtl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: trg('pay.voucher'),
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  vBusy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(onPressed: applyVoucher, child: Text(trg('pay.applyShort'))),
                ]),
                if (vNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      Expanded(
                        child: Text(vNote!,
                            style: TextStyle(fontSize: 12, color: vErr ? Colors.redAccent : _brand)),
                      ),
                      if (!vErr)
                        TextButton(
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero, minimumSize: const Size(40, 28), foregroundColor: Colors.black54),
                          onPressed: vBusy ? null : removeVoucher,
                          child: Text(trg('pay.removeShort'), style: const TextStyle(fontSize: 12)),
                        ),
                    ]),
                  ),
                const Divider(height: 24),
                Text(trg('pay.selectMethod'), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'vnpay'),
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    label: const Text('VNPay'),
                  ),
                ),
                const SizedBox(height: 8),
                if (company != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: _corp),
                      onPressed: () => Navigator.pop(ctx, 'company'),
                      icon: const Icon(Icons.business_center_outlined, size: 18),
                      label: Text(trg('pay.payWithCompany').replaceAll('{name}', company.name),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'mock'),
                    icon: const Icon(Icons.bolt_outlined, size: 18),
                    label: Text(trg('pay.mockPay')),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'later'), child: Text(trg('common.later'))),
          ],
        );
      },
    ),
  );

  if (choice == 'mock') {
    try {
      final b = await repo.payMock(current.publicCode);
      ref.invalidate(myBookingsProvider);
      return b;
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    }
  } else if (choice == 'vnpay') {
    return _vnpayFlow(context, ref, current);
  } else if (choice == 'company' && company != null) {
    return _companyFlow(context, ref, current, company, messenger);
  }
  // 'later' hoặc đóng hộp thoại: đơn vẫn ở trạng thái chờ
  ref.invalidate(myBookingsProvider);
  return null;
}

Future<Booking?> _companyFlow(
    BuildContext context, WidgetRef ref, Booking booking, CompanyInfo company, ScaffoldMessengerState messenger) async {
  final go = await showDialog<bool>(
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
  if (go != true) return null;
  try {
    final r = await ref.read(bookingRepositoryProvider).payCompany(booking.publicCode);
    ref.invalidate(myBookingsProvider);
    if (r.outcome != 'CONFIRMED') {
      messenger.showSnackBar(SnackBar(content: Text(trg('pay.companyPending'))));
    }
    return r.booking;
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return null;
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(trg('pay.companyFail'))));
    return null;
  }
}

Future<Booking?> _vnpayFlow(BuildContext context, WidgetRef ref, Booking booking) async {
  final repo = ref.read(bookingRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  String url;
  try {
    url = await repo.vnpayUrl(booking.publicCode);
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return null;
  }
  if (url.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(trg('pay.vnpayLinkFail'))));
    return null;
  }
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger.showSnackBar(SnackBar(content: Text(trg('pay.vnpayOpenFail'))));
    return null;
  }
  if (!context.mounted) return null;

  final done = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(trg('pay.vnpayTitle')),
      content: Text(trg('pay.vnpayBody')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.later'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('pay.iHavePaid'))),
      ],
    ),
  );
  if (done != true) {
    ref.invalidate(myBookingsProvider);
    return null;
  }

  // Poll trạng thái tối đa ~10s (backend cập nhật CONFIRMED qua vnpay-return).
  Booking? b;
  for (int i = 0; i < 5; i++) {
    try {
      b = await repo.getBooking(booking.publicCode);
    } catch (_) {}
    if (b != null && b.status == 'CONFIRMED') break;
    await Future.delayed(const Duration(seconds: 2));
  }
  ref.invalidate(myBookingsProvider);
  // Chỉ coi là thành công khi đã CONFIRMED; nếu chưa (poll hết giờ) trả null để
  // màn gọi hiển thị thông báo "đơn đang chờ — xem ở Đơn của tôi" thay vì im lặng.
  return (b != null && b.status == 'CONFIRMED') ? b : null;
}
