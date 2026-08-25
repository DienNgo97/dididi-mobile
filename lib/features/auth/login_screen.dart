import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/env.dart';
import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  /// Rời màn đăng nhập sau khi xác thực thành công.
  ///
  /// KHÔNG được phó thác việc này cho `redirect` của go_router. Màn đăng nhập
  /// thường được mở bằng `context.push('/login')` (xem home_shell, hotel_list,
  /// hotel_detail), tức là một trang MỆNH LỆNH đặt chồng lên vị trí hiện tại.
  /// Vị trí mà `redirect` nhìn thấy vẫn là trang bên dưới (`/`), nên nó kết luận
  /// "đang ở đúng chỗ rồi" và không làm gì cả — trang đăng nhập nằm nguyên đó,
  /// người dùng tưởng app hỏng và bấm lại nhiều lần. Lỗi này đã tái hiện được
  /// trên máy ảo Android ngày 24/08.
  ///
  /// PHẢI dùng `go` chứ KHÔNG dùng `pop`. Đã thử `pop` ngày 24/08 và hỏng:
  /// đúng lúc đăng nhập xong thì trạng thái đổi cũng kích `refreshListenable`
  /// của go_router, khiến nó dựng lại vị trí hiện tại — mà vị trí đó vẫn đang
  /// là `/login`. Hai việc chạy đua, cú dựng lại thắng: màn đăng nhập cũ bị
  /// huỷ và một màn đăng nhập MỚI mọc lên ngay chỗ đó (form trống trơn).
  /// `go` đặt vị trí một cách tuyệt đối nên không có cuộc đua nào cả.
  ///
  /// Tôn trọng tham số `from` nếu nơi gọi có truyền, để người dùng quay lại
  /// đúng chỗ họ đang đứng (ví dụ đang xem một khách sạn thì bị hỏi đăng nhập).
  void _roiManDangNhap() {
    if (!mounted) return;
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    context.go((from != null && from.isNotEmpty) ? from : '/');
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(_email.text.trim(), _pw.text);
      _roiManDangNhap();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('auth.noServer'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final signIn = GoogleSignIn(
        scopes: const ['email'],
        serverClientId: Env.googleServerClientId.isEmpty ? null : Env.googleServerClientId,
      );
      final account = await signIn.signIn();
      if (account == null) return; // người dùng huỷ
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _snack(trg('auth.googleNoToken'));
        return;
      }
      await ref.read(authControllerProvider.notifier).loginWithGoogle(idToken);
      _roiManDangNhap();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(trg('auth.googleLoginFailed').replaceAll('{v}', '$e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _otpLogin() async {
    final emailC = TextEditingController(text: _email.text.trim());
    final codeC = TextEditingController();
    bool sent = false;
    bool busy = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(trg('auth.otpLoginTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailC,
                enabled: !sent,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(labelText: trg('common.email'), border: const OutlineInputBorder()),
              ),
              if (sent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: codeC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: trg('auth.otpInEmail'), border: const OutlineInputBorder()),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: Text(trg('common.close'))),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setS(() => busy = true);
                      try {
                        if (!sent) {
                          await ref.read(authRepositoryProvider).requestOtp(emailC.text.trim());
                          setS(() {
                            sent = true;
                            busy = false;
                          });
                          _snack(trg('auth.otpSentIfValid'));
                        } else {
                          await ref
                              .read(authControllerProvider.notifier)
                              .loginWithOtp(emailC.text.trim(), codeC.text.trim());
                          if (ctx.mounted) Navigator.pop(ctx); // đóng hộp thoại OTP
                          _roiManDangNhap();                   // rồi mới rời màn đăng nhập
                        }
                      } on ApiException catch (e) {
                        setS(() => busy = false);
                        _snack(e.message);
                      } catch (_) {
                        setS(() => busy = false);
                        _snack(trg('common.error'));
                      }
                    },
              child: Text(sent ? trg('auth.login') : trg('auth.sendCode')),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.brandSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.travel_explore, color: AppTheme.brand, size: 38),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Dididi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppTheme.brand, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(trg('appTagline'),
                    textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
                const SizedBox(height: 34),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: trg('common.email'), prefixIcon: const Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pw,
                  obscureText: _obscure,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: trg('common.password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(trg('auth.login')),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(trg('auth.or'), style: const TextStyle(color: AppTheme.muted)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _google,
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFFDB4437)),
                  label: Text(trg('auth.loginGoogle')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppTheme.line),
                    foregroundColor: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _otpLogin,
                  icon: const Icon(Icons.pin_outlined, size: 20),
                  label: Text(trg('auth.loginOtp')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppTheme.line),
                    foregroundColor: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _loading ? null : () => context.push('/forgot-password'),
                  child: Text(trg('auth.forgotPassword')),
                ),
                TextButton(
                  onPressed: _loading ? null : () => context.push('/register'),
                  child: Text(trg('auth.noAccountRegister')),
                ),
                const Divider(height: 20),
                TextButton.icon(
                  onPressed: _loading ? null : () => context.push('/vendor-register'),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: Text(trg('auth.becomeVendor')),
                ),
                // Duyệt như KHÁCH — xem khách sạn/vé không cần tài khoản.
                TextButton.icon(
                  onPressed: _loading ? null : () => context.go('/'),
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: Text(trg('auth.continueGuest')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
