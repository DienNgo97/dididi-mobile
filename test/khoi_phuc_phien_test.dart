import 'package:dididi_mobile/features/auth/auth_models.dart';
import 'package:dididi_mobile/features/auth/auth_providers.dart';
import 'package:dididi_mobile/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ho_tro/do_gia.dart';

/// Kiểm tra luồng KHÔI PHỤC PHIÊN lúc mở ứng dụng.
///
/// Vì sao có tệp này: ngày 25/08/2026 phát hiện lỗi mở ứng dụng lúc không có
/// mạng thì bị đăng xuất VĨNH VIỄN. Nguyên nhân là đoạn khởi động dùng
/// `catch (_)` bắt mọi loại lỗi rồi xoá sạch token — không phân biệt
/// "máy chủ nói token không hợp lệ" với "chưa hỏi được máy chủ vì mất mạng".
///
/// Lỗi này IM LẶNG: không văng, không thông báo, không dòng log nào. Người dùng
/// chỉ thấy mình bị đăng xuất mà không hiểu tại sao. Đúng loại lỗi cần bài kiểm
/// tra tự động canh giữ, vì kiểm thử thủ công rất khó nghĩ tới việc mở app
/// đúng lúc mất sóng.
void main() {
  /// Chờ giai đoạn khởi động chạy xong.
  ///
  /// `AuthController.build()` gọi `_bootstrap()` theo kiểu bắn-rồi-quên, nên
  /// ngay sau khi đọc provider trạng thái vẫn còn là `unknown`. Chờ tới khi nó
  /// chuyển sang trạng thái dứt khoát, có hạn để bài kiểm tra không treo mãi.
  Future<AuthState> choKhoiDongXong(ProviderContainer container) async {
    final hetHan = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(hetHan)) {
      final s = container.read(authControllerProvider);
      if (s.status != AuthStatus.unknown) return s;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Khởi động không kết thúc sau 5 giây — trạng thái vẫn là unknown');
  }

  ProviderContainer dungContainer({
    required KhoTokenGia kho,
    required KhoXacThucGia repo,
  }) {
    final c = ProviderContainer(overrides: [
      tokenStorageProvider.overrideWithValue(kho),
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('không có token thì ra trạng thái khách, và KHÔNG hỏi máy chủ', () async {
    final kho = KhoTokenGia(); // rỗng
    final repo = KhoXacThucGia();
    final c = dungContainer(kho: kho, repo: repo);

    final s = await choKhoiDongXong(c);

    expect(s.status, AuthStatus.unauthenticated);
    expect(repo.soLanGoiMe, 0, reason: 'Không có token thì đừng gọi mạng vô ích');
  });

  test('có token và máy chủ trả lời được thì vào thẳng trạng thái đã đăng nhập', () async {
    final kho = KhoTokenGia(access: 'AT', refresh: 'RT');
    final repo = KhoXacThucGia(
      nguoiDung: AppUser(id: 1, email: 'a@b.com', role: 'CUSTOMER'),
    );
    final c = dungContainer(kho: kho, repo: repo);

    final s = await choKhoiDongXong(c);

    expect(s.status, AuthStatus.authenticated);
    expect(s.email, 'a@b.com');
    expect(kho.soLanXoa, 0);
  });

  test('MẤT MẠNG lúc khởi động thì GIỮ NGUYÊN token, không xoá phiên', () async {
    // Đây là bài kiểm tra chính của tệp này. Trước bản vá 25/08/2026 nó sẽ TRƯỢT:
    // token bị xoá sạch, người dùng phải đăng nhập lại dù mạng có trở lại.
    final kho = KhoTokenGia(access: 'AT', refresh: 'RT');
    final repo = KhoXacThucGia(loiCuaMe: loiMatMang());
    final c = dungContainer(kho: kho, repo: repo);

    final s = await choKhoiDongXong(c);

    expect(s.status, AuthStatus.unauthenticated,
        reason: 'Chưa xác minh được thì tạm coi là khách — đúng');
    expect(kho.soLanXoa, 0,
        reason: 'KHÔNG được xoá token chỉ vì mất mạng');
    expect(await kho.access, 'AT',
        reason: 'Lần mở sau có mạng phải vào thẳng, không bắt đăng nhập lại');
  });

  test('máy chủ TỪ CHỐI token (401) thì mới được xoá phiên', () async {
    final kho = KhoTokenGia(access: 'AT', refresh: 'RT');
    final repo = KhoXacThucGia(loiCuaMe: loiHetPhien());
    final c = dungContainer(kho: kho, repo: repo);

    final s = await choKhoiDongXong(c);

    expect(s.status, AuthStatus.unauthenticated);
    expect(kho.soLanXoa, 1,
        reason: 'Token thật sự hết hiệu lực thì phải dọn đi');
    expect(await kho.access, isNull);
  });

  test('lỗi lạ không rõ nguồn gốc thì GIỮ token cho an toàn', () async {
    // Thà bắt người dùng bấm đăng nhập một lần còn hơn xoá mất phiên của họ
    // vì một lỗi mình chưa lường trước.
    final kho = KhoTokenGia(access: 'AT', refresh: 'RT');
    final repo = KhoXacThucGia(loiCuaMe: StateError('lỗi lạ'));
    final c = dungContainer(kho: kho, repo: repo);

    final s = await choKhoiDongXong(c);

    expect(s.status, AuthStatus.unauthenticated);
    expect(kho.soLanXoa, 0);
  });
}
