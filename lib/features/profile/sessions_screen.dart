import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import '../auth/auth_providers.dart';
import 'sessions_repository.dart';

const _brand = AppTheme.brand;

/// Danh sách thiết bị/phiên đăng nhập + thu hồi từng phiên (song song với web /account/profile/devices).
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(trg('session.devices')),
        actions: [
          TextButton.icon(
            onPressed: () => _logoutAll(context, ref),
            icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
            label: Text(trg('session.all'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(sessionsProvider)),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(sessionsProvider),
          child: list.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.devices_other,
                    title: trg('session.empty'),
                    message: trg('session.emptySub'),
                  ),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _tile(context, ref, list[i]),
                ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, DeviceSession s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.rControl),
        border: Border.all(color: s.current ? _brand : AppTheme.line, width: s.current ? 1.4 : 1),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.brandSoft,
            child: Icon(_iconFor(s.device), color: _brand, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.device, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.ink)),
              const SizedBox(height: 2),
              Text(trg('session.loginAt').replaceAll('{v}', _fmt(s.createdAtMs)), style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ]),
          ),
          if (s.current)
            StatusBadge(trg('session.current'), AppTheme.brand)
          else
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () => _revoke(context, ref, s),
              child: Text(trg('session.signOut')),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String device) {
    final d = device.toLowerCase();
    if (d.contains('android') || d.contains('ios') || d.contains('dididi')) return Icons.phone_iphone;
    if (d.contains('windows') || d.contains('mac') || d.contains('linux')) return Icons.computer;
    return Icons.devices_other;
  }

  String _fmt(int ms) {
    if (ms <= 0) return '—';
    final d = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _logoutAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('session.logoutAllConfirm')),
        content: Text(trg('session.logoutAllBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(trg('session.logoutAll')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authControllerProvider.notifier).logoutAllDevices();
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref, DeviceSession s) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('session.revokeConfirm')),
        content: Text(trg('session.revokeBody').replaceAll('{v}', s.device)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(sessionsRepositoryProvider).revoke(s.id);
      ref.invalidate(sessionsProvider);
      messenger.showSnackBar(SnackBar(content: Text(trg('session.revoked'))));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(trg('session.revokeFailed'))));
    }
  }
}
