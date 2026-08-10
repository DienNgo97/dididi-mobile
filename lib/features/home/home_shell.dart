import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../shared/ui/ui_kit.dart';
import '../account/account_screen.dart';
import '../auth/auth_providers.dart';
import '../bookings/my_bookings_screen.dart';
import '../flights/flight_list_screen.dart';
import '../hotels/hotel_list_screen.dart';
import '../social/community_feed_screen.dart';
import '../social/notif_feed.dart';

/// Tab đang chọn ở khung chính (0=KS,1=Vé,2=Cộng đồng,3=Đơn,4=Tài khoản).
/// Cho phép màn khác chuyển tab (vd sau khi đặt xong → mở "Đơn của tôi" = index 3).
final homeTabProvider = StateProvider<int>((ref) => 0);

/// Khung chính sau khi đăng nhập: bottom nav 5 tab.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _pages = [
    HotelListScreen(),
    FlightListScreen(),
    CommunityFeedScreen(),
    MyBookingsScreen(),
    AccountScreen(),
  ];

  Widget _notifButton(BuildContext context, int unread) => Badge.count(
        count: unread,
        isLabelVisible: unread > 0,
        child: IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: trg('social.notifications'),
            onPressed: () => context.push('/notifications')),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final authed = ref.watch(authControllerProvider).status == AuthStatus.authenticated;
    final unread = authed ? (ref.watch(notifUnreadProvider).asData?.value ?? 0) : 0;

    // Khách chưa đăng nhập: xem Khách sạn/Vé thoải mái; 3 tab cần tài khoản hiện lời mời.
    final pages = authed
        ? _pages
        : <Widget>[
            const HotelListScreen(),
            const FlightListScreen(),
            _GuestGate(icon: Icons.groups_outlined, titleKey: 'auth.guestCommunityTitle', msgKey: 'auth.guestCommunityMsg'),
            _GuestGate(icon: Icons.receipt_long_outlined, titleKey: 'auth.guestOrdersTitle', msgKey: 'auth.guestOrdersMsg'),
            _GuestGate(
                icon: Icons.person_outline,
                titleKey: 'auth.guestAccountTitle',
                msgKey: 'auth.guestAccountMsg',
                showLanguage: true),
          ];
    return Scaffold(
      appBar: AppBar(
        title: Text([tr(ref, 'hotels'), tr(ref, 'flights'), tr(ref, 'community'), tr(ref, 'orders'), tr(ref, 'account')][index]),
        actions: index == 2
            ? [
                IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: trg('common.search'),
                    onPressed: () => context.push('/community/search')),
                IconButton(
                    icon: const Icon(Icons.explore_outlined),
                    tooltip: trg('social.explore'),
                    onPressed: () => context.push('/community/explore')),
                IconButton(
                    icon: const Icon(Icons.add_box_outlined),
                    tooltip: trg('social.compose'),
                    onPressed: () => context.push('/community/compose')),
                _notifButton(context, unread),
                IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: tr(ref, 'messages'),
                    onPressed: () => context.push('/dm')),
              ]
            : (index == 0 || index == 1)
                ? [
                    if (index == 0)
                      IconButton(
                          icon: const Icon(Icons.map_outlined),
                          tooltip: trg('hotel.mapTitle'),
                          onPressed: () => context.push('/map')),
                    IconButton(
                        icon: const Icon(Icons.favorite_border),
                        tooltip: tr(ref, 'wishlist'),
                        onPressed: () => context.push('/wishlist')),
                    _notifButton(context, unread),
                  ]
                : index == 3
                    ? [
                        IconButton(
                            icon: const Icon(Icons.support_agent),
                            tooltip: 'Trợ lý Dididi',
                            onPressed: () => context.push('/support')),
                      ]
                    : null,
      ),
      // Key theo ngôn ngữ: các tab dùng trg() là const nên không tự rebuild khi đổi
      // locale — key đổi buộc dựng lại toàn bộ tab với chuỗi ngôn ngữ mới.
      body: KeyedSubtree(key: ValueKey('tabs-$lang-$authed'), child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        key: ValueKey('nav-$lang'),
        selectedIndex: index,
        onDestinationSelected: (v) => ref.read(homeTabProvider.notifier).state = v,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.hotel_outlined), selectedIcon: const Icon(Icons.hotel), label: tr(ref, 'hotels')),
          NavigationDestination(icon: const Icon(Icons.flight_outlined), selectedIcon: const Icon(Icons.flight), label: tr(ref, 'flightsShort')),
          NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: tr(ref, 'community')),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: tr(ref, 'ordersShort')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: tr(ref, 'account')),
        ],
      ),
    );
  }
}

/// Màn mời đăng nhập cho KHÁCH ở các tab cần tài khoản (Cộng đồng/Đơn/Tài khoản)
/// — giống các app booking thật: duyệt tự do, chỉ đăng nhập khi cần.
class _GuestGate extends ConsumerWidget {
  final IconData icon;
  final String titleKey;
  final String msgKey;
  final bool showLanguage;
  const _GuestGate({required this.icon, required this.titleKey, required this.msgKey, this.showLanguage = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(icon: icon, title: trg(titleKey), message: trg(msgKey)),
            SizedBox(
              width: 280,
              child: FilledButton(
                onPressed: () => context.push('/login'),
                child: Text(trg('auth.login')),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 280,
              child: OutlinedButton(
                onPressed: () => context.push('/register'),
                child: Text(trg('auth.register')),
              ),
            ),
            if (showLanguage) ...[
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'vi', label: Text('VI')),
                  ButtonSegment(value: 'en', label: Text('EN')),
                  ButtonSegment(value: 'zh', label: Text('中')),
                ],
                selected: {lang},
                showSelectedIcon: false,
                onSelectionChanged: (s) => ref.read(localeProvider.notifier).state = Locale(s.first),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
