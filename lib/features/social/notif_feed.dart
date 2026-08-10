import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../shared/format.dart';
import '../auth/auth_providers.dart';

/// Một dòng trong trung tâm thông báo TỔNG (khớp NotifFeedItem backend).
class NotifFeedItem {
  final String? icon;
  final String category; // BOOKING/PAYMENT/CANCEL/LOYALTY/REVIEW/INVITE/GROUP/SOCIAL/DM
  final String title;
  final String? text;
  final String? url;
  final bool read;
  final int createdAtMs;
  NotifFeedItem({
    this.icon,
    this.category = '',
    this.title = '',
    this.text,
    this.url,
    this.read = false,
    this.createdAtMs = 0,
  });
  factory NotifFeedItem.fromJson(Map<String, dynamic> j) => NotifFeedItem(
        icon: j['icon'] as String?,
        category: (j['category'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        text: j['text'] as String?,
        url: j['url'] as String?,
        read: j['read'] == true,
        createdAtMs: asNum(j['createdAtMs'])?.toInt() ?? 0,
      );
}

final notifFeedRepositoryProvider =
    Provider<NotifFeedRepository>((ref) => NotifFeedRepository(ref.watch(apiClientProvider)));

class NotifFeedRepository {
  final ApiClient _api;
  NotifFeedRepository(this._api);

  Future<List<NotifFeedItem>> feed() => _api.getData(
        '/api/v1/notifications/feed',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => NotifFeedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<void> markRead() => _api.postData<void>('/api/v1/notifications/read', parse: (_) {});

  /// Tổng số thông báo chưa đọc (badge chuông).
  Future<int> unreadCount() => _api.getData(
        '/api/v1/notifications/unread-count',
        parse: (d) => int.tryParse('${(d as Map)['count'] ?? 0}') ?? 0,
      );
}

final notifFeedProvider = FutureProvider.autoDispose<List<NotifFeedItem>>((ref) {
  return ref.read(notifFeedRepositoryProvider).feed();
});

/// Số thông báo chưa đọc (để hiện badge trên chuông/tab). Trả 0 nếu lỗi.
final notifUnreadProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    return await ref.read(notifFeedRepositoryProvider).unreadCount();
  } catch (_) {
    return 0;
  }
});
