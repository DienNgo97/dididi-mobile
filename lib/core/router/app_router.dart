import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/bookings/booking_detail_screen.dart';
import '../../features/bookings/booking_loader_screen.dart';
import '../../features/bookings/booking_models.dart';
import '../../features/bookings/hotel_booking_screen.dart';
import '../../features/bulk/bulk_booking_screen.dart';
import '../../features/company/company_screen.dart';
import '../../features/flights/flight_booking_screen.dart';
import '../../features/flights/return_flight_screen.dart';
import '../../features/group/group_dashboard_screen.dart';
import '../../features/group/my_groups_screen.dart';
import '../i18n/l10n.dart';
import '../../features/home/home_shell.dart';
import '../../features/hotels/hotel_detail_screen.dart';
import '../../features/hotels/hotel_map_screen.dart';
import '../../features/social/chat_screen.dart';
import '../../features/social/compose_post_screen.dart';
import '../../features/social/dm_inbox_screen.dart';
import '../../features/social/group_new_screen.dart';
import '../../features/social/notifications_screen.dart';
import '../../features/social/bookmarks_screen.dart';
import '../../features/social/explore_screen.dart';
import '../../features/social/follow_requests_screen.dart';
import '../../features/social/hashtag_screen.dart';
import '../../features/social/hotel_community_screen.dart';
import '../../features/social/post_detail_screen.dart';
import '../../features/social/social_profile_screen.dart';
import '../../features/social/social_search_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/loyalty/loyalty_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/sessions_screen.dart';
import '../../features/vendor/vendor_register_screen.dart';
import '../../features/promo/offers_screen.dart';
import '../../features/trip/trip_guide_screen.dart';
import '../../features/trip/trip_plan_screen.dart';
import '../../features/trip/trip_planner_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../shared/widgets/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-chạy redirect mỗi khi trạng thái đăng nhập đổi.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }
      final atAuth = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/vendor-register';

      if (status == AuthStatus.authenticated) {
        if (atAuth) {
          // Sau khi đăng nhập, quay lại đúng nơi người dùng định đến (nếu có).
          final from = state.uri.queryParameters['from'];
          return (from != null && from.isNotEmpty) ? from : '/';
        }
        return loc == '/splash' ? '/' : null;
      }

      // KHÁCH (chưa đăng nhập): duyệt tự do như các app booking thật —
      // xem khách sạn/vé/bản đồ thoải mái; chỉ chặn hành động cần tài khoản.
      if (loc == '/splash') return '/';
      final isPublic = atAuth ||
          loc == '/' ||
          loc == '/map' ||
          loc == '/support' ||
          loc == '/trip-guide' || // hướng dẫn viên AI: endpoint permitAll, khách hỏi được
          (loc.startsWith('/hotels/') && !loc.endsWith('/book'));
      if (isPublic) return null;
      // Route cần tài khoản → mời đăng nhập, nhớ điểm đến để quay lại.
      return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeShell()),
      GoRoute(path: '/map', builder: (_, __) => const HotelMapScreen()),
      GoRoute(
        path: '/hotels/:id',
        builder: (_, s) => HotelDetailScreen(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/hotels/:id/book',
        builder: (_, s) => HotelBookingScreen(
          hotelId: int.parse(s.pathParameters['id']!),
          hotelName: s.extra is String ? s.extra as String : 'Khách sạn',
          preselectRoomId: int.tryParse(s.uri.queryParameters['roomId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/flights/:id/book',
        builder: (_, s) => FlightBookingScreen(
          flightId: int.parse(s.pathParameters['id']!),
          cabin: s.uri.queryParameters['cabin'],
          returnFlightId: int.tryParse(s.uri.queryParameters['returnId'] ?? ''),
          leg: s.uri.queryParameters['leg'],
        ),
      ),
      // Khứ hồi bước 2: chọn chuyến về (đảo sân bay theo chuyến đi đã chọn).
      GoRoute(
        path: '/flights/return',
        builder: (_, s) => ReturnFlightScreen(
          outboundId: int.parse(s.uri.queryParameters['outId']!),
          dateYmd: s.uri.queryParameters['date']!,
          cabin: s.uri.queryParameters['cabin'],
        ),
      ),
      GoRoute(path: '/community/compose', builder: (_, __) => const ComposePostScreen()),
      GoRoute(path: '/community/explore', builder: (_, __) => const ExploreScreen()),
      GoRoute(path: '/community/search', builder: (_, __) => const SocialSearchScreen()),
      GoRoute(path: '/community/bookmarks', builder: (_, __) => const BookmarksScreen()),
      GoRoute(
        path: '/community/tag/:tag',
        builder: (_, s) => HashtagScreen(tag: s.pathParameters['tag']!),
      ),
      GoRoute(
        path: '/community/users/:handle',
        builder: (_, s) => SocialProfileScreen(handle: s.pathParameters['handle']!),
      ),
      GoRoute(
        path: '/community/posts/:id',
        builder: (_, s) => PostDetailScreen(postId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/community/hotel/:id',
        builder: (_, s) => HotelCommunityScreen(
          hotelId: int.parse(s.pathParameters['id']!),
          hotelName: s.extra is String ? s.extra as String : null,
        ),
      ),
      GoRoute(path: '/community/requests', builder: (_, __) => const FollowRequestsScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/dm', builder: (_, __) => const DmInboxScreen()),
      // 3 route dưới phải đứng TRƯỚC /dm/:id, nếu không 'archived'/'group' bị nuốt thành id.
      GoRoute(path: '/dm/archived', builder: (_, __) => const DmInboxScreen(archived: true)),
      GoRoute(path: '/dm/group/new', builder: (_, __) => const GroupNewScreen()),
      GoRoute(
        path: '/dm/group/add/:id',
        builder: (_, s) => GroupNewScreen(
          convId: int.parse(s.pathParameters['id']!),
          groupName: s.extra is String ? s.extra as String : null,
        ),
      ),
      GoRoute(
        path: '/dm/:id',
        builder: (_, s) => ChatScreen(
          convId: int.parse(s.pathParameters['id']!),
          title: s.extra is String ? s.extra as String : trg('messages'),
        ),
      ),
      GoRoute(path: '/offers', builder: (_, __) => const OffersScreen()),
      GoRoute(path: '/trip-guide', builder: (_, __) => const TripGuideScreen()),
      GoRoute(path: '/trip-planner', builder: (_, __) => const TripPlannerScreen()),
      GoRoute(path: '/trip-plan', builder: (_, __) => const TripPlanScreen()),
      GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
      GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/sessions', builder: (_, __) => const SessionsScreen()),
      GoRoute(path: '/vendor-register', builder: (_, __) => const VendorRegisterScreen()),
      GoRoute(
        path: '/bookings/:code',
        builder: (_, s) => s.extra is Booking
            ? BookingDetailScreen(booking: s.extra as Booking)
            : BookingLoaderScreen(code: s.pathParameters['code']!),
      ),
      GoRoute(path: '/loyalty', builder: (_, __) => const LoyaltyScreen()),
      GoRoute(path: '/company', builder: (_, __) => const CompanyScreen()),
      GoRoute(
        path: '/bulk',
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>?;
          if (e == null) return const Scaffold(body: Center(child: Text('Thiếu thông tin')));
          return BulkBookingScreen(
            hotelId: e['hotelId'] as int,
            roomTypeId: e['roomTypeId'] as int,
            roomName: e['roomName'] as String?,
            hotelName: e['hotelName'] as String,
            checkIn: e['checkIn'] as String,
            checkOut: e['checkOut'] as String,
          );
        },
      ),
      GoRoute(path: '/groups', builder: (_, __) => const MyGroupsScreen()),
      GoRoute(
        path: '/groups/:token',
        builder: (_, s) => GroupDashboardScreen(token: s.pathParameters['token']!),
      ),
    ],
  );
});
