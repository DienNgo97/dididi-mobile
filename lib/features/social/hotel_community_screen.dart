import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/actor_avatar.dart';
import '../../shared/widgets/auth_image.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/hashtag_text.dart';
import '../../shared/widgets/post_video.dart';
import 'social_models.dart';
import 'social_repository.dart';

/// Bài viết cộng đồng theo một khách sạn (trang KS).
final hotelPostsProvider = FutureProvider.family<List<Post>, int>((ref, hotelId) async {
  final page = await ref.read(socialRepositoryProvider).hotelPosts(hotelId);
  return page.items;
});

class HotelCommunityScreen extends ConsumerWidget {
  final int hotelId;
  final String? hotelName;
  const HotelCommunityScreen({super.key, required this.hotelId, this.hotelName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(hotelPostsProvider(hotelId));
    return Scaffold(
      appBar: AppBar(title: Text(hotelName ?? trg('social.hotelCommunity'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(hotelPostsProvider(hotelId))),
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyState(
              icon: Icons.forum_outlined,
              title: trg('social.noPosts'),
              message: trg('social.noHotelPostsMsg'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(hotelPostsProvider(hotelId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _tile(context, posts[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, Post p) {
    return AppCard(
      onTap: () => context.push('/community/posts/${p.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              ActorAvatar(p.actor, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.actor?.name ?? trg('social.anonymous'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.ink, letterSpacing: -0.2)),
                  const SizedBox(height: 1),
                  Text(ago(p.createdAtMs), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                ]),
              ),
            ]),
          ),
          if (p.caption != null && p.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: HashtagText(
                p.caption!,
                maxLines: 3,
                style: const TextStyle(height: 1.45, color: AppTheme.ink),
                onTapTag: (t) => context.push('/community/tag/$t'),
                onTapMention: (h) => context.push('/community/users/$h'),
              ),
            ),
          if (p.media.isNotEmpty && p.media.first.url != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: p.media.first.isVideo
                    ? PostVideo(p.media.first.url!, height: 200)
                    : AuthImage(p.media.first.url!, height: 200, width: double.infinity),
              ),
            ),
          const SoftDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Icons.favorite_border, size: 16, color: AppTheme.muted),
              const SizedBox(width: 4),
              Text('${p.likeCount}', style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(width: 14),
              const Icon(Icons.mode_comment_outlined, size: 16, color: AppTheme.muted),
              const SizedBox(width: 4),
              Text('${p.commentCount}', style: const TextStyle(color: AppTheme.muted)),
            ]),
          ),
        ],
      ),
    );
  }
}
