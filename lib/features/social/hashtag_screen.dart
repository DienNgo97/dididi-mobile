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

final hashtagPostsProvider =
    FutureProvider.autoDispose.family<FeedPage, String>((ref, tag) => ref.read(socialRepositoryProvider).hashtagPosts(tag));

/// Trang hashtag: bài viết gắn thẻ #tag.
class HashtagScreen extends ConsumerWidget {
  final String tag;
  const HashtagScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hashtagPostsProvider(tag));
    return Scaffold(
      appBar: AppBar(title: Text('#$tag')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(hashtagPostsProvider(tag))),
        data: (page) {
          if (page.items.isEmpty) {
            return EmptyState(
              icon: Icons.tag,
              title: trg('social.noPosts'),
              message: trg('social.noHashtagPostsMsg'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(hashtagPostsProvider(tag)),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: page.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _TagPostCard(post: page.items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TagPostCard extends StatelessWidget {
  final Post post;
  const _TagPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final a = post.actor;
    return AppCard(
      onTap: () => context.push('/community/posts/${post.id}'),
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
            if (post.createdAtMs > 0)
              Text(ago(post.createdAtMs), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
          ]),
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(post.caption!, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppTheme.ink)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.favorite_border, size: 15, color: AppTheme.muted),
            const SizedBox(width: 4),
            Text('${post.likeCount}', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            const SizedBox(width: 14),
            const Icon(Icons.mode_comment_outlined, size: 15, color: AppTheme.muted),
            const SizedBox(width: 4),
            Text('${post.commentCount}', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
          ]),
        ],
      ),
    );
  }
}
