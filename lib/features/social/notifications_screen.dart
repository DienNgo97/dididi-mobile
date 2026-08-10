import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
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
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(notifFeedProvider)),
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
              itemBuilder: (_, i) => _tile(context, list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, NotifFeedItem n) {
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
        onTap: n.url == null ? null : () => _open(context, n.url!),
      ),
    );
  }

  /// Mở thông báo: chuyển các url web sang route mobile tương ứng khi có thể.
  void _open(BuildContext context, String url) {
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
      if (code.isNotEmpty) context.push('/bookings/$code');
    }
    // các url khác: bỏ qua (không rời app sang trình duyệt).
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
