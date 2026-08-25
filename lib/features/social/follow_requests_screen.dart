import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/actor_avatar.dart';
import '../../shared/widgets/error_view.dart';
import 'social_models.dart';
import 'social_repository.dart';

final followRequestsProvider = FutureProvider.autoDispose<List<FollowRequest>>((ref) {
  return ref.read(socialRepositoryProvider).followRequests();
});

/// Yêu cầu theo dõi đang chờ duyệt (tài khoản riêng tư).
class FollowRequestsScreen extends ConsumerWidget {
  const FollowRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(followRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(trg('social.followRequests'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(followRequestsProvider)),
        data: (reqs) {
          if (reqs.isEmpty) {
            return EmptyState(
              icon: Icons.person_add_alt,
              title: trg('social.noRequests'),
              message: trg('social.noRequestsMsg'),
            );
          }
          return ListView.separated(
            itemCount: reqs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _RequestTile(req: reqs[i]),
          );
        },
      ),
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  final FollowRequest req;
  const _RequestTile({required this.req});
  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;
  String? _done;

  Future<void> _act(bool accept) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(socialRepositoryProvider);
      if (accept) {
        await repo.acceptFollowRequest(widget.req.followId);
      } else {
        await repo.rejectFollowRequest(widget.req.followId);
      }
      if (mounted) setState(() => _done = accept ? trg('social.accepted') : trg('social.rejected'));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.req.profile;
    final actor = Actor(name: p.displayName, handle: p.handle, avatarUrl: p.avatarUrl, id: p.userId, type: 'USER');
    return ListTile(
      leading: ActorAvatar(actor, size: 44),
      title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: p.handle == null ? null : Text('@${p.handle}'),
      onTap: p.handle == null ? null : () => context.push('/community/users/${p.handle}'),
      trailing: _done != null
          ? Text(_done!, style: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.w600))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: _busy ? null : () => _act(true),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: Text(trg('social.accept')),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _act(false),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: Text(trg('social.reject')),
                ),
              ),
            ]),
    );
  }
}
