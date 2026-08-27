import 'package:dididi_mobile/core/network/api_exception.dart';
import 'package:dididi_mobile/core/storage/token_storage.dart';
import 'package:dididi_mobile/features/auth/auth_models.dart';
import 'package:dididi_mobile/features/auth/auth_repository.dart';

/// Đồ giả dùng chung cho các bài kiểm tra tự động.
///
/// Vì sao cần: [TokenStorage] thật ghi vào Keychain/Keystore và
/// [AuthRepository] thật gọi mạng — cả hai đều không chạy được trong môi trường
/// kiểm tra. Thay bằng bản giả để bài kiểm tra CHẠY NHANH và KHÔNG phụ thuộc
/// máy chủ, đồng thời cho phép dựng đúng những tình huống khó tái hiện bằng tay
/// (mất mạng giữa chừng, máy chủ từ chối token…).

/// Kho token trong bộ nhớ. Đếm luôn số lần bị xoá để bài kiểm tra khẳng định
/// được "token KHÔNG bị xoá" — thứ mà chỉ nhìn trạng thái cuối thì không thấy.
class KhoTokenGia implements TokenStorage {
  String? _access;
  String? _refresh;

  /// Số lần clear() được gọi. Đây là điểm mấu chốt của lỗi mất phiên khi sóng yếu.
  int soLanXoa = 0;

  KhoTokenGia({String? access, String? refresh})
      : _access = access,
        _refresh = refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<String?> get access async => _access;

  @override
  Future<String?> get refresh async => _refresh;

  @override
  Future<bool> get hasToken async => (_access?.isNotEmpty ?? false);

  @override
  Future<void> clear() async {
    soLanXoa++;
    _access = null;
    _refresh = null;
  }
}

/// Kho xác thực giả: cho phép chỉ định TRƯỚC me() và login() sẽ trả gì hoặc ném gì.
class KhoXacThucGia implements AuthRepository {
  /// Kết quả của me(): trả người dùng, hoặc ném lỗi đã chỉ định.
  final AppUser? nguoiDung;
  final Object? loiCuaMe;

  /// Kết quả của login().
  final AuthTokens? tokenDangNhap;
  final Object? loiCuaLogin;

  /// Đếm số lần me() được gọi — để khẳng định "không có token thì đừng hỏi máy chủ".
  int soLanGoiMe = 0;

  KhoXacThucGia({this.nguoiDung, this.loiCuaMe, this.tokenDangNhap, this.loiCuaLogin});

  @override
  Future<AppUser> me() async {
    soLanGoiMe++;
    if (loiCuaMe != null) throw loiCuaMe!;
    return nguoiDung!;
  }

  @override
  Future<AuthTokens> login(String email, String password) async {
    if (loiCuaLogin != null) throw loiCuaLogin!;
    return tokenDangNhap!;
  }

  // ----- Các phương thức còn lại: bài kiểm tra hiện tại không dùng tới. -----
  // Dart bắt buộc phải hiện thực hết khi dùng `implements`. Ném lỗi rõ ràng để
  // nếu sau này có bài kiểm tra vô tình gọi tới thì biết ngay mà bổ sung.
  @override
  Future<void> register(String email, String password, String fullName) =>
      throw UnimplementedError('KhoXacThucGia.register chưa dùng tới');
  @override
  Future<void> logout(String? refreshToken) async {}
  @override
  Future<void> logoutAll() async {}
  @override
  Future<AuthTokens> googleLogin(String idToken) =>
      throw UnimplementedError('KhoXacThucGia.googleLogin chưa dùng tới');
  @override
  Future<void> requestOtp(String email) =>
      throw UnimplementedError('KhoXacThucGia.requestOtp chưa dùng tới');
  @override
  Future<AuthTokens> verifyOtp(String email, String code) =>
      throw UnimplementedError('KhoXacThucGia.verifyOtp chưa dùng tới');
  @override
  Future<void> forgotPassword(String email) =>
      throw UnimplementedError('KhoXacThucGia.forgotPassword chưa dùng tới');
  @override
  Future<void> resetPassword(String token, String newPassword) =>
      throw UnimplementedError('KhoXacThucGia.resetPassword chưa dùng tới');
}

/// Lỗi tầng mạng đúng như ApiClient tạo ra khi máy không có kết nối.
/// Mã 'OFFLINE' là thứ quyết định app GIỮ hay XOÁ phiên đăng nhập.
ApiException loiMatMang() => ApiException('OFFLINE', 'Không có kết nối mạng');

/// Lỗi máy chủ TỪ CHỐI token — trường hợp duy nhất được phép xoá phiên.
ApiException loiHetPhien() => ApiException('UNAUTHORIZED', 'Phiên hết hạn', 401);
