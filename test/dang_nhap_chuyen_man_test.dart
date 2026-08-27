import 'package:dididi_mobile/features/auth/auth_models.dart';
import 'package:dididi_mobile/features/auth/auth_providers.dart';
import 'package:dididi_mobile/features/auth/login_screen.dart';
import 'package:dididi_mobile/core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ho_tro/do_gia.dart';

/// Kiểm tra: đăng nhập xong thì PHẢI rời khỏi màn đăng nhập.
///
/// Vì sao có tệp này: ngày 24/08/2026 phát hiện bấm Đăng nhập xong màn hình
/// đứng im. Máy chủ xác thực thành công, trạng thái trong ứng dụng đã chuyển
/// sang "đã đăng nhập", nhưng trang đăng nhập vẫn nằm đè lên. Người dùng tưởng
/// app hỏng và bấm lại nhiều lần — mỗi lần là một phiên mới trên máy chủ.
///
/// Bài kiểm tra dựng lại BỘ ĐỊNH TUYẾN CÓ refreshListenable giống hệt ứng dụng
/// thật, chứ không phải một bộ định tuyến đơn giản hoá. Lý do: bản vá đầu tiên
/// dùng `pop()` chạy đúng với router đơn giản nhưng HỎNG với router thật, vì
/// đúng khoảnh khắc đăng nhập xong thì trạng thái đổi cũng kích refreshListenable,
/// khiến bộ định tuyến dựng lại vị trí hiện tại — mà vị trí đó vẫn là `/login`.
/// Hai việc chạy đua nhau và cú dựng lại thắng: màn đăng nhập cũ bị huỷ, một màn
/// đăng nhập MỚI mọc lên đúng chỗ đó. Router đơn giản không có cuộc đua ấy nên
/// sẽ cho qua một bản vá hỏng — đúng cái bẫy cần tránh ở đây.
void main() {
  setUpAll(() {
    // Chặn google_fonts gọi mạng trong lúc kiểm tra: dùng font đi kèm là đủ,
    // và tránh cho bài kiểm tra phụ thuộc vào đường truyền.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('đăng nhập thành công thì rời khỏi màn đăng nhập', (tester) async {
    final kho = KhoTokenGia();
    final repo = KhoXacThucGia(
      tokenDangNhap: AuthTokens(
        accessToken: 'AT',
        refreshToken: 'RT',
        email: 'a@b.com',
        role: 'CUSTOMER',
      ),
      nguoiDung: AppUser(id: 1, email: 'a@b.com', role: 'CUSTOMER'),
    );

    // Provider dựng router giống thật: có refreshListenable ăn theo trạng thái
    // đăng nhập, và có redirect đẩy người đã đăng nhập ra khỏi /login.
    final routerGiongThat = Provider<GoRouter>((ref) {
      final refresh = ValueNotifier<int>(0);
      ref.listen(authControllerProvider, (_, __) => refresh.value++);
      ref.onDispose(refresh.dispose);
      return GoRouter(
        initialLocation: '/',
        refreshListenable: refresh,
        redirect: (context, state) {
          final status = ref.read(authControllerProvider).status;
          final loc = state.matchedLocation;
          if (status == AuthStatus.authenticated && loc == '/login') return '/';
          return null;
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, __) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('TRANG_CHU'),
                ),
              ),
            ),
          ),
          GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        ],
      );
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(kho),
        authRepositoryProvider.overrideWithValue(repo),
      ],
      child: Consumer(builder: (context, ref, _) {
        return MaterialApp.router(routerConfig: ref.watch(routerGiongThat));
      }),
    ));
    await tester.pumpAndSettle();

    // Mở màn đăng nhập ĐÚNG CÁCH ứng dụng thật làm: context.push, tức đặt một
    // trang mệnh lệnh lên trên. Đây chính là mấu chốt của lỗi gốc.
    await tester.tap(find.text('TRANG_CHU'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget, reason: 'Đã vào màn đăng nhập');

    // Điền và bấm.
    final oNhap = find.byType(TextField);
    expect(oNhap, findsAtLeastNWidgets(2), reason: 'Phải có ô email và ô mật khẩu');
    await tester.enterText(oNhap.at(0), 'a@b.com');
    await tester.enterText(oNhap.at(1), 'MatKhau@123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    // KHẲNG ĐỊNH CHÍNH: không còn màn đăng nhập nào trên màn hình.
    // Trước bản vá 24/08/2026 dòng này TRƯỢT — trang đăng nhập vẫn nằm đè.
    expect(find.byType(LoginScreen), findsNothing,
        reason: 'Đăng nhập xong phải rời màn đăng nhập, không được đứng im');
    expect(find.text('TRANG_CHU'), findsOneWidget);

    // Và trạng thái phải thật sự là đã đăng nhập, không phải chỉ chuyển màn suông.
    expect(await kho.access, 'AT');
  });

  testWidgets('đăng nhập SAI thì Ở LẠI màn đăng nhập và báo lỗi', (tester) async {
    // Mặt còn lại của cùng một luồng: đừng vì lo "phải chuyển màn" mà chuyển
    // cả khi thất bại.
    final kho = KhoTokenGia();
    final repo = KhoXacThucGia(loiCuaLogin: loiHetPhien());

    final router = Provider<GoRouter>((ref) => GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('TRANG_CHU'))),
            GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
          ],
        ));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(kho),
        authRepositoryProvider.overrideWithValue(repo),
      ],
      child: Consumer(builder: (context, ref, _) {
        return MaterialApp.router(routerConfig: ref.watch(router));
      }),
    ));
    await tester.pumpAndSettle();

    final oNhap = find.byType(TextField);
    await tester.enterText(oNhap.at(0), 'a@b.com');
    await tester.enterText(oNhap.at(1), 'SaiRoi@123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget,
        reason: 'Đăng nhập thất bại thì phải ở lại để người dùng thử lại');
    expect(await kho.access, isNull, reason: 'Không được lưu token khi thất bại');
  });
}
