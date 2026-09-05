import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/actor_avatar.dart';
import '../../shared/widgets/error_view.dart';
import 'dm_models.dart';
import 'social_controller.dart';
import 'social_models.dart';
import 'social_repository.dart';

/// Hộp thư DM. [archived] = true thì hiện mục Lưu trữ thay cho hộp thư chính.
class DmInboxScreen extends ConsumerWidget {
  const DmInboxScreen({super.key, this.archived = false});

  final bool archived;

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

  /// Nhấn giữ một hàng: lưu trữ / bỏ lưu trữ / xoá đoạn chat.
  Future<void> _actions(BuildContext context, WidgetRef ref, Conversation c) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(c.other?.name ?? trg('social.user'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ListTile(
              leading: Icon(c.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
              title: Text(trg(c.archived ? 'dm.unarchive' : 'dm.archive')),
              onTap: () => Navigator.pop(ctx, 'archive'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFC0392B)),
              title: Text(trg('dm.delete'), style: const TextStyle(color: Color(0xFFC0392B))),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(trg('dm.delete')),
          content: Text(trg(c.group ? 'dm.deleteGroupConfirm' : 'dm.deleteConfirm')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.ok'))),
          ],
        ),
      );
      if (ok != true) return;
    }

    final repo = ref.read(socialRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (choice == 'delete') {
        await repo.deleteConversation(c.id);
      } else {
        await repo.archiveConversation(c.id, !c.archived);
      }
      if (!context.mounted) return;
      // Cả hai danh sách đều đổi: cất đi thì biến khỏi hộp thư và hiện ở Lưu trữ.
      ref.invalidate(dmInboxProvider);
      ref.invalidate(dmArchivedProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(trg(choice == 'delete'
            ? 'dm.deletedDone'
            : (c.archived ? 'dm.unarchivedDone' : 'dm.archivedDone'))),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = archived ? dmArchivedProvider : dmInboxProvider;
    final async = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: Text(trg(archived ? 'dm.archived' : 'messages')),
        actions: archived
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  tooltip: trg('dm.archived'),
                  onPressed: () => context.push('/dm/archived'),
                ),
                IconButton(
                  icon: const Icon(Icons.group_add_outlined),
                  tooltip: trg('dm.newGroup'),
                  onPressed: () => context.push('/dm/group/new'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_square),
                  tooltip: trg('dm.newMessage'),
                  onPressed: () => _newMessage(context, ref),
                ),
              ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(provider)),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: archived ? Icons.archive_outlined : Icons.forum_outlined,
              title: trg(archived ? 'dm.emptyArchived' : 'dm.noMessages'),
              message: trg(archived ? 'dm.emptyArchivedMsg' : 'dm.noMessagesMsg'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(provider),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  leading: ActorAvatar(c.other, size: 46),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(c.other?.name ?? trg('social.user'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (c.group) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.group, size: 15, color: AppTheme.muted),
                        const SizedBox(width: 3),
                        Text('${c.memberCount}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                      ],
                    ],
                  ),
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
                  onLongPress: () => _actions(context, ref, c),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
