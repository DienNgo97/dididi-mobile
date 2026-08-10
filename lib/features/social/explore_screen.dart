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

final exploreProvider =
    FutureProvider.autoDispose<FeedPage>((ref) => ref.read(socialRepositoryProvider).explore());

final trendingHashtagsProvider =
    FutureProvider.autoDispose<List<HashtagTrend>>((ref) => ref.read(socialRepositoryProvider).trendingHashtags());

/// Khám phá — bài viết công khai mới nhất.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(exploreProvider);
    return Scaffold(
      appBar: AppBar(title: Text(trg('social.explore'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(exploreProvider)),
        data: (page) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(exploreProvider);
              ref.invalidate(trendingHashtagsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _trendingBar(context, ref),
                if (page.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: EmptyState(
                      icon: Icons.explore_outlined,
                      title: trg('social.noPublicPosts'),
                      message: trg('social.noPublicPostsMsg'),
                    ),
                  )
                else
                  for (final p in page.items)
                    Padding(padding: const EdgeInsets.only(bottom: 10), child: _ExploreCard(post: p)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _trendingBar(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(trendingHashtagsProvider).asData?.value ?? const [];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(trg('social.trendingHashtags'), icon: Icons.local_fire_department_outlined),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in tags)
              InkWell(
                onTap: () => context.push('/community/tag/${t.tag}'),
                borderRadius: BorderRadius.circular(100),
                child: Pill('#${t.tag}'),
              ),
          ]),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final Post post;
  const _ExploreCard({required this.post});

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
              radius: 18,
              backgroundColor: AppTheme.brandSoft,
              child: Text(a?.initial ?? '?', style: const TextStyle(color: _brand, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a?.name ?? trg('social.anonymous'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.ink)),
                if (a?.handle != null)
                  Text('@${a!.handle}', style: const TextStyle(color: AppTheme.muted, fontSize: 11.5)),
              ]),
            ),
            if (post.media.isNotEmpty) const Icon(Icons.photo_outlined, size: 18, color: AppTheme.muted),
          ]),
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(post.caption!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppTheme.ink)),
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
            const Spacer(),
            if (post.createdAtMs > 0)
              Text(ago(post.createdAtMs), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
          ]),
        ],
      ),
    );
  }
}
