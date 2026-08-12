import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import '../auth/auth_providers.dart';
import 'profile_models.dart';
import 'profile_repository.dart';

const _brand = AppTheme.brand;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(trg('profile.title'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(profileProvider)),
        data: (p) => _body(context, ref, p),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Profile p) {
    final name = (p.fullName != null && p.fullName!.isNotEmpty) ? p.fullName! : trg('profile.noName');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.brandSoft,
                child: Text(
                  (p.email.isNotEmpty ? p.email[0] : '?').toUpperCase(),
                  style: const TextStyle(fontSize: 30, color: _brand, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.ink)),
              const SizedBox(height: 4),
              Text(p.email, style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 10),
              Pill('${trg('role')}: ${p.role}', icon: Icons.verified_user_outlined),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(trg('profile.personalInfo')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined, color: _brand),
                title: Text(trg('common.name')),
                subtitle: Text(name),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => _editName(context, ref, p),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: _brand),
                title: Text(trg('common.phone')),
                subtitle: Row(children: [
                  Text((p.phone != null && p.phone!.isNotEmpty) ? p.phone! : trg('profile.phoneNone')),
                  if (p.phone != null && p.phone!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _badge(p.phoneVerified ? trg('profile.verified') : trg('profile.unverified'), p.phoneVerified),
                  ],
                ]),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => _editPhone(context, ref),
              ),
              const SoftDivider(),
              // Ngày sinh: cần cho chương trình khuyến mãi sinh nhật (tặng voucher đúng ngày).
              ListTile(
                leading: const Icon(Icons.cake_outlined, color: _brand),
                title: Text(trg('profile.birthDate')),
                subtitle: Text(p.birthDate == null ? trg('profile.birthDateNone') : dmy(p.birthDate!)),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => _editBirthDate(context, ref, p),
              ),
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.email_outlined, color: _brand),
                title: Text(trg('common.email')),
                // 1 dòng + ellipsis: email dài trước đây bị ngắt giữa từ ("...gmail.co / m").
                subtitle: Text(p.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: _badge(p.emailVerified ? trg('profile.verified') : trg('profile.notActivated'), p.emailVerified),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(trg('profile.security')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline, color: _brand),
                title: Text(trg('profile.changePassword')),
                subtitle: Text(trg('profile.changePasswordSub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePassword(context, ref),
              ),
              if (!p.emailVerified) ...[
                const SoftDivider(),
                ListTile(
                  leading: const Icon(Icons.mark_email_unread_outlined, color: _brand),
                  title: Text(trg('profile.resendActivation')),
                  subtitle: Text(trg('profile.accountNotActivated')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _resendEmail(context, ref),
                ),
              ],
              const SoftDivider(),
              ListTile(
                leading: const Icon(Icons.link_off, color: _brand),
                title: Text(trg('profile.unlinkGoogle')),
                subtitle: Text(trg('profile.unlinkGoogleSub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _unlinkGoogle(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(trg('profile.dangerZone')),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.no_accounts_outlined, color: Colors.redAccent),
            title: Text(trg('profile.closeAccount'), style: const TextStyle(color: Colors.redAccent)),
            subtitle: Text(trg('profile.closeAccountSub')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _closeAccount(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _resendEmail(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).resendActivation();
      messenger.showSnackBar(SnackBar(content: Text(trg('profile.resendActivationDone'))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(trg('account.errorWith').replaceAll('{v}', '$e'))));
    }
  }

  Future<void> _unlinkGoogle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('profile.unlinkGoogleConfirm')),
        content: Text(trg('profile.unlinkGoogleBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('profile.unlink'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(profileRepositoryProvider).unlinkGoogle();
      messenger.showSnackBar(SnackBar(content: Text(trg('profile.unlinkGoogleDone'))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(trg('account.errorWith').replaceAll('{v}', '$e'))));
    }
  }

  Future<void> _closeAccount(BuildContext context, WidgetRef ref) async {
    final pwC = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('profile.closeAccountConfirm')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trg('profile.closeAccountBody')),
            const SizedBox(height: 12),
            TextField(
              controller: pwC,
              obscureText: true,
              decoration: InputDecoration(labelText: trg('common.password'), border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(trg('profile.closeAccount')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(profileRepositoryProvider).closeAccount(pwC.text);
      await ref.read(authControllerProvider.notifier).logout();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(trg('account.errorWith').replaceAll('{v}', '$e'))));
    }
  }

  Widget _badge(String label, bool ok) => StatusBadge(label, ok ? AppTheme.brand : const Color(0xFFC0392B));

  // ---------------- Ngày sinh (chương trình khuyến mãi sinh nhật) ----------------
  Future<void> _editBirthDate(BuildContext context, WidgetRef ref, Profile p) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: p.birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: today, // chặn ngày tương lai ngay từ giao diện (backend cũng chặn)
      helpText: trg('profile.birthDate'),
    );
    if (d == null) return;
    try {
      await ref.read(profileRepositoryProvider).updateBirthDate(ymd(d));
      ref.invalidate(profileProvider);
      messenger.showSnackBar(SnackBar(content: Text(trg('profile.birthDateSaved'))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(trg('account.errorWith').replaceAll('{v}', '$e'))));
    }
  }

  // ---------------- Sửa tên ----------------
  Future<void> _editName(BuildContext context, WidgetRef ref, Profile p) async {
    final c = TextEditingController(text: p.fullName ?? '');
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật họ tên'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(profileRepositoryProvider).updateName(c.text.trim());
      ref.invalidate(profileProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Đã cập nhật họ tên.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(trg('account.errorWith').replaceAll('{v}', '$e'))));
    }
  }

  // ---------------- Sửa / xác thực SĐT ----------------
  Future<void> _editPhone(BuildContext context, WidgetRef ref) async {
    final phoneC = TextEditingController();
    final codeC = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    bool sent = false;
    bool busy = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Số điện thoại'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneC,
                enabled: !sent,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
              ),
              if (sent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: codeC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mã OTP', border: OutlineInputBorder()),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: const Text('Đóng')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setS(() => busy = true);
                      try {
                        if (!sent) {
                          await ref.read(profileRepositoryProvider).sendPhoneOtp(phoneC.text.trim());
                          setS(() {
                            sent = true;
                            busy = false;
                          });
                          messenger.showSnackBar(const SnackBar(content: Text('Đã gửi mã OTP.')));
                        } else {
                          await ref.read(profileRepositoryProvider).confirmPhone(codeC.text.trim());
                          ref.invalidate(profileProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(const SnackBar(content: Text('Đã xác thực số điện thoại.')));
                        }
                      } catch (e) {
                        setS(() => busy = false);
                        messenger.showSnackBar(SnackBar(content: Text(trg('account.errorWith').replaceAll('{v}', '$e'))));
                      }
                    },
              child: Text(sent ? 'Xác nhận' : 'Gửi mã'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Đổi mật khẩu ----------------
  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final curC = TextEditingController();
    final newC = TextEditingController();
    final confC = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: curC,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newC,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                helperText: 'Tối thiểu 8 ký tự, gồm chữ và số',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confC,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đổi')),
        ],
      ),
    );
    if (ok != true) return;
    if (newC.text != confC.text) {
      messenger.showSnackBar(const SnackBar(content: Text('Mật khẩu xác nhận không khớp.')));
      return;
    }
    try {
      await ref.read(profileRepositoryProvider).changePassword(curC.text, newC.text);
      messenger.showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(trg('account.errorWith').replaceAll('{v}', '$e'))));
    }
  }
}
