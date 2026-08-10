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
import 'social_controller.dart';
import 'social_models.dart';
import 'social_repository.dart';

/// Feed cộng đồng du lịch (body của tab Cộng đồng).
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(feedProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(feedProvider)),
      data: (posts) {
        if (posts.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(feedProvider.notifier).refresh(),
            child: ListView(
              children: [
                const SizedBox(height: 80),
                EmptyState(
                  icon: Icons.forum_outlined,
                  title: trg('social.noPosts'),
                  message: trg('social.noPostsMsg'),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(feedProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PostCard(key: ValueKey(posts[i].id), post: posts[i]),
          ),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  const _PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Bài đăng lại: hiển thị banner + nội dung bài gốc; tương tác trỏ về bài gốc.
    final bool isRepost = post.repost && post.original != null;
    final Post display = isRepost ? post.original! : post;
    final bool hasMedia = display.media.isNotEmpty && display.media.first.url != null;
    return AppCard(
      onTap: () => context.push('/community/posts/${display.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRepost)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(children: [
                const Icon(Icons.repeat, size: 15, color: AppTheme.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      trg('social.repostedBy').replaceAll('{name}', post.actor?.name ?? trg('social.someone')),
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.muted)),
                ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              InkWell(
                onTap: display.actor?.handle == null
                    ? null
                    : () => context.push('/community/users/${display.actor!.handle}'),
                child: ActorAvatar(display.actor, size: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: display.actor?.handle == null
                      ? null
                      : () => context.push('/community/users/${display.actor!.handle}'),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(display.actor?.name ?? trg('social.anonymous'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.ink, letterSpacing: -0.2)),
                    const SizedBox(height: 1),
                    Text(ago(display.createdAtMs), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                  ]),
                ),
              ),
              if (display.hotelName != null)
                InkWell(
                  onTap: display.hotelId == null
                      ? null
                      : () => context.push('/community/hotel/${display.hotelId}', extra: display.hotelName),
                  borderRadius: BorderRadius.circular(100),
                  child: Pill(display.hotelName!, icon: Icons.place),
                ),
            ]),
          ),
          // Bài KHÔNG ẢNH: caption là nội dung chính nên cho chữ to hơn, thoáng hơn
          // (giống bố cục web mới); bài có ảnh thì caption giữ cỡ thường, ảnh là điểm nhấn.
          if (display.caption != null && display.caption!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, hasMedia ? 12 : 14),
              child: HashtagText(
                display.caption!,
                style: TextStyle(
                  height: 1.45,
                  color: AppTheme.ink,
                  fontSize: hasMedia ? 14 : 15.5,
                  fontWeight: hasMedia ? FontWeight.w400 : FontWeight.w500,
                ),
                onTapTag: (t) => context.push('/community/tag/$t'),
                onTapMention: (h) => context.push('/community/users/$h'),
              ),
            ),
          if (hasMedia)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: display.media.first.isVideo
                    ? PostVideo(display.media.first.url!, height: 220)
                    : AuthImage(display.media.first.url!, height: 220, width: double.infinity),
              ),
            ),
          const SoftDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(children: [
              LikeButton(
                  key: ValueKey('like-${display.id}'),
                  postId: display.id,
                  liked: display.liked,
                  count: display.likeCount),
              InkWell(
                onTap: () => context.push('/community/posts/${display.id}'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.mode_comment_outlined, size: 18, color: AppTheme.muted),
                    const SizedBox(width: 6),
                    Text('${display.commentCount}', style: const TextStyle(color: AppTheme.muted)),
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Nút tim với cập nhật lạc quan (không cần refresh cả feed).
class LikeButton extends ConsumerStatefulWidget {
  final int postId;
  final bool liked;
  final int count;
  const LikeButton({super.key, required this.postId, required this.liked, required this.count});

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton> {
  late bool _liked = widget.liked;
  late int _count = widget.count;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant LikeButton old) {
    super.didUpdateWidget(old);
    // Đồng bộ với dữ liệu mới từ server sau khi feed refresh (không ghi đè khi đang gửi).
    if (!_busy && (old.liked != widget.liked || old.count != widget.count)) {
      _liked = widget.liked;
      _count = widget.count;
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _liked = !_liked;
      _count += _liked ? 1 : -1;
    });
    try {
      final r = await ref.read(socialRepositoryProvider).like(widget.postId);
      if (mounted) {
        setState(() {
          _liked = r['liked'] == true;
          _count = (r['count'] as num?)?.toInt() ?? _count;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !_liked;
          _count += _liked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_liked ? Icons.favorite : Icons.favorite_border,
              size: 18, color: _liked ? Colors.redAccent : AppTheme.muted),
          const SizedBox(width: 6),
          Text('$_count', style: const TextStyle(color: AppTheme.muted)),
        ]),
      ),
    );
  }
}
