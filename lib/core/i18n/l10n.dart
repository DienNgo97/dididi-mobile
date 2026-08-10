import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'strings_account.dart';
import 'strings_bookings.dart';
import 'strings_hotels.dart';
import 'strings_social.dart';

/// Ngôn ngữ đang chọn (mặc định Tiếng Việt). Đổi qua màn Tài khoản.
/// Giá trị khởi tạo được override trong main() bằng ngôn ngữ đã lưu (LocalePrefs).
final localeProvider = StateProvider<Locale>((ref) => const Locale('vi'));

/// Lưu/đọc ngôn ngữ đã chọn để app mở lại vẫn giữ (Keychain/Keystore/localStorage web).
class LocalePrefs {
  static const _kLang = 'dd_lang';
  static const _s = FlutterSecureStorage();

  static Future<void> save(String code) => _s.write(key: _kLang, value: code);

  /// Trả về mã ngôn ngữ đã lưu ('vi'/'en'/'zh') hoặc 'vi' nếu chưa có/lỗi.
  static Future<String> load() async {
    try {
      final v = await _s.read(key: _kLang);
      if (v == 'en' || v == 'zh' || v == 'vi') return v!;
    } catch (_) {}
    return 'vi';
  }
}

/// Bản sao toàn cục của locale hiện tại — cập nhật trong DididiApp mỗi lần build.
/// Cho phép `trg(key)` dịch được ở MỌI widget (kể cả StatelessWidget/hàm helper)
/// mà không cần WidgetRef; khi đổi ngôn ngữ, MaterialApp rebuild toàn cây nên
/// mọi chuỗi trg() được tính lại theo locale mới.
Locale l10nLocale = const Locale('vi');

/// i18n cho toàn app. Khung + chuỗi dùng chung nằm ở đây; chuỗi theo nhóm nằm ở
/// các file strings_*.dart để chia việc song song không đụng nhau.
class L10n {
  static const supported = [Locale('vi'), Locale('en'), Locale('zh')];

  // Khung app + chuỗi DÙNG CHUNG (nút/nhãn xuất hiện nhiều nơi).
  static const _core = <String, Map<String, String>>{
    'appTagline': {'vi': 'Đặt khách sạn & vé máy bay', 'en': 'Hotels & flights booking', 'zh': '酒店和机票预订'},
    'hotels': {'vi': 'Khách sạn', 'en': 'Hotels', 'zh': '酒店'},
    'flights': {'vi': 'Vé máy bay', 'en': 'Flights', 'zh': '机票'},
    'flightsShort': {'vi': 'Vé bay', 'en': 'Flights', 'zh': '航班'},
    'community': {'vi': 'Cộng đồng', 'en': 'Community', 'zh': '社区'},
    'orders': {'vi': 'Đơn của tôi', 'en': 'My bookings', 'zh': '我的订单'},
    'ordersShort': {'vi': 'Đơn', 'en': 'Bookings', 'zh': '订单'},
    'account': {'vi': 'Tài khoản', 'en': 'Account', 'zh': '账户'},
    'tripPlanner': {'vi': 'Gợi ý chuyến đi', 'en': 'Trip planner', 'zh': '行程规划'},
    'tripPlannerSub': {
      'vi': 'Chuyến bay + khách sạn theo điểm đến',
      'en': 'Flights + hotels by destination',
      'zh': '按目的地推荐机票+酒店'
    },
    'messages': {'vi': 'Tin nhắn', 'en': 'Messages', 'zh': '消息'},
    'rewards': {'vi': 'Điểm thưởng & voucher', 'en': 'Rewards & vouchers', 'zh': '积分与优惠券'},
    'wishlist': {'vi': 'Yêu thích', 'en': 'Wishlist', 'zh': '收藏'},
    'logout': {'vi': 'Đăng xuất', 'en': 'Log out', 'zh': '退出登录'},
    'language': {'vi': 'Ngôn ngữ', 'en': 'Language', 'zh': '语言'},
    'role': {'vi': 'Vai trò', 'en': 'Role', 'zh': '角色'},

    // ----- Dùng chung (common.*) -----
    'common.save': {'vi': 'Lưu', 'en': 'Save', 'zh': '保存'},
    'common.cancel': {'vi': 'Huỷ', 'en': 'Cancel', 'zh': '取消'},
    'common.confirm': {'vi': 'Xác nhận', 'en': 'Confirm', 'zh': '确认'},
    'common.close': {'vi': 'Đóng', 'en': 'Close', 'zh': '关闭'},
    'common.delete': {'vi': 'Xoá', 'en': 'Delete', 'zh': '删除'},
    'common.edit': {'vi': 'Sửa', 'en': 'Edit', 'zh': '编辑'},
    'common.back': {'vi': 'Quay lại', 'en': 'Back', 'zh': '返回'},
    'common.retry': {'vi': 'Thử lại', 'en': 'Retry', 'zh': '重试'},
    'common.done': {'vi': 'Xong', 'en': 'Done', 'zh': '完成'},
    'common.next': {'vi': 'Tiếp tục', 'en': 'Continue', 'zh': '继续'},
    'common.send': {'vi': 'Gửi', 'en': 'Send', 'zh': '发送'},
    'common.search': {'vi': 'Tìm', 'en': 'Search', 'zh': '搜索'},
    'common.apply': {'vi': 'Áp dụng', 'en': 'Apply', 'zh': '应用'},
    'common.ok': {'vi': 'Đồng ý', 'en': 'OK', 'zh': '好的'},
    'common.later': {'vi': 'Để sau', 'en': 'Later', 'zh': '稍后'},
    'common.loading': {'vi': 'Đang tải…', 'en': 'Loading…', 'zh': '加载中…'},
    'common.error': {'vi': 'Đã xảy ra lỗi, vui lòng thử lại.', 'en': 'Something went wrong, please try again.', 'zh': '出错了，请重试。'},
    'common.errorShort': {'vi': 'Rất tiếc! Đã xảy ra lỗi.', 'en': 'Oops! Something went wrong.', 'zh': '哎呀，出错了。'},
    'common.noData': {'vi': 'Chưa có dữ liệu.', 'en': 'No data yet.', 'zh': '暂无数据。'},
    'common.required': {'vi': 'Bắt buộc', 'en': 'Required', 'zh': '必填'},
    'common.optional': {'vi': 'tuỳ chọn', 'en': 'optional', 'zh': '可选'},
    'common.name': {'vi': 'Họ tên', 'en': 'Full name', 'zh': '姓名'},
    'common.email': {'vi': 'Email', 'en': 'Email', 'zh': '邮箱'},
    'common.phone': {'vi': 'Số điện thoại', 'en': 'Phone number', 'zh': '电话号码'},
    'common.password': {'vi': 'Mật khẩu', 'en': 'Password', 'zh': '密码'},
    'common.price': {'vi': 'Giá', 'en': 'Price', 'zh': '价格'},
    'common.total': {'vi': 'Tổng tiền', 'en': 'Total', 'zh': '总计'},
    'common.from': {'vi': 'Từ', 'en': 'From', 'zh': '从'},
    'common.night': {'vi': 'đêm', 'en': 'night', 'zh': '晚'},
    'common.guest': {'vi': 'khách', 'en': 'guest', 'zh': '位客人'},
    'common.room': {'vi': 'phòng', 'en': 'room', 'zh': '间'},
    'common.book': {'vi': 'Đặt', 'en': 'Book', 'zh': '预订'},
    'common.pay': {'vi': 'Thanh toán', 'en': 'Pay', 'zh': '支付'},
  };

  static final Map<String, Map<String, String>> _m = {
    ..._core,
    ...hotelStrings,
    ...bookingStrings,
    ...socialStrings,
    ...accountStrings,
  };

  static String t(String key, Locale l) => _m[key]?[l.languageCode] ?? _m[key]?['vi'] ?? key;
}

/// Dịch trong ConsumerWidget (rebuild theo provider): `tr(ref, 'hotels')`.
String tr(WidgetRef ref, String key) => L10n.t(key, ref.watch(localeProvider));

/// Dịch ở BẤT KỲ widget/hàm nào không có ref: `trg('hotels')`.
/// Dùng locale toàn cục (đồng bộ trong DididiApp); cả cây rebuild khi đổi ngôn ngữ.
String trg(String key) => L10n.t(key, l10nLocale);
