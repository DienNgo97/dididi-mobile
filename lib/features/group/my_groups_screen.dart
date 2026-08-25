import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import 'group_models.dart';
import 'group_repository.dart';

const _brand = AppTheme.brand;

/// Danh sách nhóm của tôi (tổ chức / tham gia).
class MyGroupsScreen extends ConsumerWidget {
  const MyGroupsScreen({super.key});

  Future<void> _joinByCode(BuildContext context) async {
    final c = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('group.joinTitle')),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(labelText: trg('group.groupCode'), border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(trg('common.cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(trg('group.openGroup'))),
        ],
      ),
    );
    if (code != null && code.isNotEmpty && context.mounted) {
      context.push('/groups/$code');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myGroupsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(trg('group.myGroups')),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: trg('group.joinByCode'),
            onPressed: () => _joinByCode(context),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myGroupsProvider)),
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: trg('group.emptyTitle'),
              message: trg('group.emptySub'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myGroupsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _GroupCard(g: groups[i]),
            ),
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupSummary g;
  const _GroupCard({required this.g});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/groups/${g.token}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.groups, size: 18, color: _brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(g.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
            ),
            _badge(g.organizer ? trg('group.organizer') : trg('group.memberRole'), g.organizer),
          ]),
          const SizedBox(height: 6),
          Text(g.hotelName, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
          if (g.checkIn != null)
            Text('${g.checkIn} → ${g.checkOut ?? ''}', style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(g.ended ? trg('group.ended') : trg('group.planning'),
              style: TextStyle(fontSize: 12, color: g.ended ? AppTheme.muted : _brand, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _badge(String label, bool primary) => StatusBadge(label, primary ? AppTheme.brand : AppTheme.muted);
}
