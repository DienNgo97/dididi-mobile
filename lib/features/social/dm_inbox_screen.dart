import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/actor_avatar.dart';
import '../../shared/widgets/error_view.dart';
import 'social_controller.dart';
import 'social_models.dart';
import 'social_repository.dart';

class DmInboxScreen extends ConsumerWidget {
  const DmInboxScreen({super.key});

  Future<void> _newMessage(BuildContext context, WidgetRef ref) async {
    List<UserCard> people;
    try {
      people = await ref.read(socialRepositoryProvider).peopleSuggest();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<UserCard>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(trg('dm.newMessage'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            if (people.isEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(trg('dm.noPeople'), style: const TextStyle(color: AppTheme.muted)))
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final u in people)
                      ListTile(
                        leading: ActorAvatar(u.actor, size: 40),
                        title: Text(u.actor?.name ?? trg('social.user')),
                        subtitle: u.actor?.handle != null ? Text('@${u.actor!.handle}') : null,
                        onTap: () => Navigator.pop(ctx, u),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked.userId == null) return;
    try {
      final convId = await ref.read(socialRepositoryProvider).openConversation(picked.userId!);
      if (context.mounted) context.push('/dm/$convId', extra: picked.actor?.name);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dmInboxProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(trg('messages')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            tooltip: trg('dm.newMessage'),
            onPressed: () => _newMessage(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(dmInboxProvider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.forum_outlined,
              title: trg('dm.noMessages'),
              message: trg('dm.noMessagesMsg'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dmInboxProvider),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  leading: ActorAvatar(c.other, size: 46),
                  title: Text(c.other?.name ?? trg('social.user'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(c.preview ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(ago(c.lastMessageAtMs), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                      const SizedBox(height: 4),
                      if (c.unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: const BoxDecoration(color: AppTheme.brand, borderRadius: BorderRadius.all(Radius.circular(20))),
                          child: Text('${c.unread}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/dm/${c.id}', extra: c.other?.name),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
