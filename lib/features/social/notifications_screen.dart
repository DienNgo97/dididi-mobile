import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import '../home/home_shell.dart';
import 'notif_feed.dart';

const _brand = Color(0xFF2F8B60);

/// Trung tâm thông báo TỔNG: đơn/thanh toán/huỷ + cộng đồng + tin nhắn (khớp web /notifications).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notifFeedProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(trg('social.notifications')),
        actions: [
          IconButton(
            tooltip: trg('social.markAllRead'),
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await ref.read(notifFeedRepositoryProvider).markRead();
              ref.invalidate(notifFeedProvider);
              ref.invalidate(notifUnreadProvider); // cập nhật badge chuông về 0
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(notifFeedProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none,
              title: trg('social.noNotifs'),
              message: trg('social.noNotifsMsg'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notifFeedProvider),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _tile(context, ref, list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, NotifFeedItem n) {
    return Container(
      color: n.read ? null : AppTheme.brandSoft,
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.brandSoft,
          child: Icon(_iconFor(n.category), size: 20, color: _brand),
        ),
        title: Text(n.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (n.text != null && n.text!.isNotEmpty)
              Text(n.text!, style: const TextStyle(fontSize: 13, color: AppTheme.ink)),
            Text(ago(n.createdAtMs), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
          ],
        ),
        isThreeLine: n.text != null && n.text!.isNotEmpty,
        trailing: n.read
            ? null
            : Container(
                width: 9, height: 9,
                decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle)),
        onTap: n.url == null ? null : () => _open(context, ref, n.url!),
      ),
    );
  }

  /// Mở thông báo: chuyển các url web sang route mobile tương ứng khi có thể.
  void _open(BuildContext context, WidgetRef ref, String url) {
    if (url.startsWith('/community/p/')) {
      context.push('/community/posts/${url.split('/').last.split('?').first}');
    } else if (url.startsWith('/community/messages')) {
      context.push('/dm');
    } else if (url.startsWith('/community/requests')) {
      context.push('/community/requests');
    } else if (url.contains('/account/offers')) {
      // Thông báo khuyến mãi cá nhân hoá (web trỏ /account/offers) -> màn Ưu đãi của tôi.
      context.push('/offers');
    } else if (url.contains('/account/bookings/')) {
      final code = url.split('/account/bookings/').last.split('/').first.split('?').first;
      if (code.isNotEmpty) {
        context.push('/bookings/$code');
      } else {
        _moTabDon(context, ref);
      }
    } else if (url.contains('/account/bookings')) {
      // Máy chủ gửi đúng chuỗi "/account/bookings" KHÔNG kèm mã đơn
      // (BookingService, RefundService, AdminBookingApiController). Trước ngày
      // 24/08/2026 nhánh trên đòi phải có dấu "/" và mã ở cuối nên không khớp,
      // khiến mọi thông báo đơn hàng thành nút chết — bấm không đi đâu cả.
      _moTabDon(context, ref);
    } else if (url.contains('/account/points')) {
      // Thông báo cộng điểm thưởng (LoyaltyService gửi "/account/points").
      context.push('/loyalty');
    } else if (url.contains('/account/profile')) {
      context.push('/profile');
    } else if (url.contains('/account/wishlist')) {
      context.push('/wishlist');
    }
    // Các url khác: bỏ qua (không rời app sang trình duyệt).
    //
    // LƯU Ý CHO NGƯỜI SỬA SAU: mỗi khi backend thêm một loại thông báo mới,
    // PHẢI thêm nhánh tương ứng ở đây. Quên là người dùng bấm vào không có
    // phản hồi gì — lỗi rất khó nhận ra vì app không báo lỗi, chỉ im lặng.
  }

  /// Về tab "Đơn" của màn chính.
  ///
  /// Danh sách đơn không có route riêng — nó là tab số 3 trong home_shell.
  /// Phải đặt homeTabProvider TRƯỚC rồi mới điều hướng, vì `go('/')` chỉ đưa về
  /// khung màn chính chứ không tự chọn tab. (Đã thử `go('/?tab=3')` và không ăn:
  /// home_shell không đọc tham số truy vấn nào cả.)
  void _moTabDon(BuildContext context, WidgetRef ref) {
    ref.read(homeTabProvider.notifier).state = 3;
    context.go('/');
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'BOOKING':
        return Icons.event_available_outlined;
      case 'PAYMENT':
        return Icons.payments_outlined;
      case 'CANCEL':
        return Icons.cancel_outlined;
      case 'LOYALTY':
        return Icons.star_outline;
      case 'REVIEW':
        return Icons.rate_review_outlined;
      case 'INVITE':
        return Icons.mail_outline;
      case 'GROUP':
        return Icons.groups_outlined;
      case 'SOCIAL':
        return Icons.favorite_border;
      case 'DM':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none;
    }
  }
}
