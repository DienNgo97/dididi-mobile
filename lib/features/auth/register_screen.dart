import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/env.dart';
import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_pw.text.length < 8) {
      _snack(trg('auth.passwordMin8'));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(_email.text.trim(), _pw.text, _name.text.trim());
      if (!mounted) return;
      _snack(trg('auth.registerSuccess'));
      context.pop();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(trg('auth.noServerShort'));
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
      if (account == null) return;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _snack(trg('auth.googleNoToken'));
        return;
      }
      await ref.read(authControllerProvider.notifier).loginWithGoogle(idToken);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(trg('auth.googleRegisterFailed').replaceAll('{v}', '$e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trg('auth.register'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Text(trg('auth.createAccount'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.ink, letterSpacing: -0.4)),
              const SizedBox(height: 6),
              Text(trg('auth.registerSub'),
                  style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: trg('common.name'), prefixIcon: const Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(labelText: trg('common.email'), prefixIcon: const Icon(Icons.mail_outline)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pw,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: trg('auth.passwordMin8Label'), prefixIcon: const Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(trg('auth.createAccountBtn')),
              ),
              const SizedBox(height: 10),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(trg('auth.or'), style: const TextStyle(color: AppTheme.muted))),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loading ? null : _google,
                icon: const Text('G', style: TextStyle(color: Color(0xFFDB4437), fontWeight: FontWeight.w900, fontSize: 16)),
                label: Text(trg('auth.registerGoogle')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
