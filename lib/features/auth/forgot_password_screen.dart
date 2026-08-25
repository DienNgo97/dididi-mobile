import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/password_rule.dart';
import '../../shared/ui/ui_kit.dart';
import 'auth_providers.dart';

/// Quên mật khẩu: gửi email đặt lại → nhập token + mật khẩu mới.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _newPass = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _newPass.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) return _snack(trg('auth.enterEmail'));
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      setState(() => _sent = true);
      _snack(trg('auth.resetSent'));
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('common.error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_token.text.trim().isEmpty) return _snack(trg('auth.enterToken'));
    if (!matKhauDuManh(_newPass.text)) return _snack(trg('auth.newPasswordMin8'));
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(_token.text.trim(), _newPass.text);
      if (!mounted) return;
      _snack(trg('auth.resetSuccess'));
      context.go('/login');
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('common.error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trg('auth.forgotPasswordTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(trg('auth.forgotIntro'),
              style: const TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: trg('common.email'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _send,
              child: Text(_sent ? trg('auth.resend') : trg('auth.sendResetLink')),
            ),
          ),
          if (_sent) ...[
            const SizedBox(height: 24),
            const SoftDivider(),
            const SizedBox(height: 16),
            SectionHeader(trg('auth.resetPassword')),
            const SizedBox(height: 4),
            TextField(
              controller: _token,
              decoration: InputDecoration(labelText: trg('auth.tokenInEmail'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: trg('profile.newPassword'),
                helperText: trg('profile.passwordHint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _reset,
                child: Text(trg('auth.resetPassword')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
