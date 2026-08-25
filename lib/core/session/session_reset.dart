import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/bookings/booking_repository.dart';
import '../../features/group/group_repository.dart';
import '../../features/loyalty/loyalty_repository.dart';
import '../../features/profile/profile_repository.dart';
import '../../features/profile/sessions_repository.dart';
import '../../features/promo/offer_repository.dart';
import '../../features/social/bookmarks_screen.dart';
import '../../features/social/follow_requests_screen.dart';
import '../../features/social/notif_feed.dart';
import '../../features/social/social_controller.dart';
import '../../features/social/social_repository.dart';
import '../../features/wishlist/wishlist_repository.dart';

/// Xoá sạch mọi dữ liệu thuộc về NGƯỜI DÙNG CŨ.
///
/// Phải gọi mỗi khi danh tính thay đổi: đăng nhập, đăng xuất, hết phiên.
///
/// Vì sao cần: 8 trên 10 provider chứa dữ liệu riêng tư KHÔNG dùng autoDispose,
/// nên chúng sống suốt vòng đời ứng dụng. Trước ngày 24/08/2026 không có chỗ
/// nào xoá chúng khi đổi tài khoản — nghĩa là người A đăng xuất, người B đăng
/// nhập trên cùng máy thì B có thể thấy đơn hàng, yêu thích, điểm thưởng, tin
/// nhắn và thông báo của A cho tới khi từng màn tự gọi lại máy chủ.
///
/// Phát hiện khi chạy TC-M-15: đổi từ tài khoản mới sang tài khoản chính mà
/// bảng tin vẫn giữ kết quả rỗng của tài khoản trước.
///
/// LƯU Ý CHO NGƯỜI SỬA SAU: mỗi khi thêm provider chứa dữ liệu riêng của người
/// dùng, NHỚ thêm vào danh sách dưới đây. Quên là rò dữ liệu.
///
/// Nhận thẳng phép xoá (`ref.invalidate`) thay vì nhận `Ref`, để dùng được cả
/// từ widget (`WidgetRef`) lẫn từ provider (`Ref`) — hai kiểu này không có cha
/// chung — và để tệp này không phải phụ thuộc ngược vào tầng auth.
void xoaDuLieuPhienCu(void Function(ProviderOrFamily) xoa) {
  // Đơn hàng & nhóm
  xoa(myBookingsProvider);
  xoa(myGroupsProvider);

  // Điểm thưởng & ưu đãi
  xoa(loyaltyAccountProvider);
  xoa(loyaltyVouchersProvider);
  xoa(myOffersProvider);
  xoa(usableOfferCountProvider);

  // Yêu thích
  xoa(wishlistProvider);
  xoa(wishlistedIdsProvider);

  // Hồ sơ & phiên đăng nhập
  xoa(profileProvider);
  xoa(sessionsProvider);

  // Mạng xã hội
  xoa(feedProvider);
  xoa(notificationsProvider);
  xoa(dmInboxProvider);
  xoa(notifFeedProvider);
  xoa(notifUnreadProvider);
  xoa(bookmarksProvider);
  xoa(followRequestsProvider);
  xoa(myHotelsProvider);
}
