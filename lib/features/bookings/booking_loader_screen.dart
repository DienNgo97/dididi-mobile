import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../shared/widgets/error_view.dart';
import 'booking_detail_screen.dart';
import 'booking_repository.dart';

/// Mở chi tiết đơn khi chỉ có MÃ đơn (deep-link / thông báo) — tự tải rồi hiển thị.
class BookingLoaderScreen extends ConsumerWidget {
  final String code;
  const BookingLoaderScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_bookingByCodeProvider(code));
    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(trg('booking.detailTitle'))),
        body: ErrorView(message: e.toString(), onRetry: () => ref.invalidate(_bookingByCodeProvider(code))),
      ),
      data: (b) => BookingDetailScreen(booking: b),
    );
  }
}

final _bookingByCodeProvider = FutureProvider.autoDispose.family(
  (ref, String code) => ref.read(bookingRepositoryProvider).getBooking(code),
);
