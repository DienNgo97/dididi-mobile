import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/error_view.dart';
import 'social_models.dart';
import 'social_repository.dart';

const _brand = Color(0xFF2F8B60);

final bookmarksProvider =
    FutureProvider.autoDispose<List<Post>>((ref) => ref.read(socialRepositoryProvider).bookmarks());

/// Bài viết đã lưu (bookmark) của tôi.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookmarksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(trg('social.bookmarks'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(bookmarksProvider)),
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyState(
              icon: Icons.bookmark_border,
              title: trg('social.noBookmarks'),
              message: trg('social.noBookmarksMsg'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(bookmarksProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _card(context, posts[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, Post p) {
    final a = p.actor;
    return AppCard(
      onTap: () => context.push('/community/posts/${p.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.brandSoft,
              child: Text(a?.initial ?? '?', style: const TextStyle(color: _brand, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(a?.name ?? trg('social.anonymous'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.ink))),
            if (p.createdAtMs > 0) Text(ago(p.createdAtMs), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
          ]),
          if (p.caption != null && p.caption!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(p.caption!, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppTheme.ink)),
          ],
        ],
      ),
    );
  }
}
