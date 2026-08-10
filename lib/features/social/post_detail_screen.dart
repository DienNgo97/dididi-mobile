import 'dart:async';

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
import 'community_feed_screen.dart' show LikeButton;
import 'dm_models.dart';
import 'social_controller.dart';
import 'social_models.dart';
import 'social_repository.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});
  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _c = TextEditingController();
  final _commentFocus = FocusNode();
  bool _sending = false;
  Comment? _replyTo; // bình luận đang được trả lời (null = bình luận gốc)
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Tự cập nhật bình luận mới ~5s (giống web poll). Không làm mới khi đang gõ để tránh giật.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _sending || _replyTo != null || _c.text.isNotEmpty) return;
      ref.invalidate(postCommentsProvider(widget.postId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _c.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(socialRepositoryProvider).addComment(widget.postId, t, parentId: _replyTo?.id);
      _c.clear();
      setState(() => _replyTo = null);
      ref.invalidate(postCommentsProvider(widget.postId));
      ref.invalidate(postDetailProvider(widget.postId));
      ref.invalidate(feedProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _likeComment(Comment c) async {
    try {
      await ref.read(socialRepositoryProvider).likeComment(c.id);
      ref.invalidate(postCommentsProvider(widget.postId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _startReply(Comment c) {
    setState(() => _replyTo = c);
    _commentFocus.requestFocus();
  }

  Future<void> _toggleBookmark() async {
    try {
      await ref.read(socialRepositoryProvider).bookmark(widget.postId);
      ref.invalidate(postDetailProvider(widget.postId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _report() async {
    final reasons = {
      'SPAM': trg('social.reportSpam'),
      'HARASSMENT': trg('social.reportHarassment'),
      'NUDITY': trg('social.reportNudity'),
      'VIOLENCE': trg('social.reportViolence'),
      'MISINFO': trg('social.reportMisinfo'),
      'OTHER': trg('social.reportOther'),
    };
    final reason = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(trg('social.reportPost'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final e in reasons.entries)
              ListTile(title: Text(e.value), onTap: () => Navigator.pop(ctx, e.key)),
          ],
        ),
      ),
    );
    if (reason == null) return;
    try {
      await ref.read(socialRepositoryProvider).report(type: 'POST', id: widget.postId, reason: reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.reportSent'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// Chống bấm chồng: nhiều lượt repost song song từng tạo nhiều bài đăng lại trùng nhau.
  bool _reposting = false;

  Future<void> _repost() async {
    if (_reposting) return;
    setState(() => _reposting = true);
    try {
      final on = await ref.read(socialRepositoryProvider).repost(widget.postId);
      ref.invalidate(feedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(on ? trg('social.repostOn') : trg('social.repostOff'))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _reposting = false);
    }
  }

  Future<void> _deletePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg('social.deletePostTitle')),
        content: Text(trg('social.deletePostBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(trg('common.delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(socialRepositoryProvider).deletePost(widget.postId);
      ref.invalidate(feedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.postDeleted'))));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.deletePostDenied'))));
    }
  }

  Future<void> _shareToDm() async {
    List<Conversation> convs;
    try {
      convs = await ref.read(socialRepositoryProvider).inbox();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    if (!mounted) return;
    if (convs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trg('social.noConversations'))));
      return;
    }
    final conv = await showModalBottomSheet<Conversation>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(trg('social.shareTo'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in convs)
                    ListTile(
                      leading: ActorAvatar(c.other, size: 38),
                      title: Text(c.other?.name ?? trg('social.user')),
                      onTap: () => Navigator.pop(ctx, c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (conv == null) return;
    try {
      await ref.read(socialRepositoryProvider).sharePost(conv.id, widget.postId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.sharedViaDm'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    return Scaffold(
      appBar: AppBar(
        title: Text(trg('social.post')),
        actions: [
          IconButton(
            icon: _reposting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.repeat),
            tooltip: trg('social.repost'),
            onPressed: _reposting ? null : _repost,
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            tooltip: trg('social.shareViaDm'),
            onPressed: _shareToDm,
          ),
          IconButton(
            icon: Icon(postAsync.asData?.value.bookmarked == true ? Icons.bookmark : Icons.bookmark_border),
            tooltip: trg('social.savePost'),
            onPressed: _toggleBookmark,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'report') _report();
              if (v == 'delete') _deletePost();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'report', child: Row(children: [
                const Icon(Icons.flag_outlined, size: 18, color: Colors.black54),
                const SizedBox(width: 8),
                Text(trg('social.report')),
              ])),
              PopupMenuItem(value: 'delete', child: Row(children: [
                const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                const SizedBox(width: 8),
                Text(trg('social.deleteMyPost')),
              ])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                postAsync.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => ErrorView(
                      message: e.toString(), onRetry: () => ref.invalidate(postDetailProvider(widget.postId))),
                  data: _postHeader,
                ),
                const SizedBox(height: 18),
                SectionHeader(trg('social.comments')),
                commentsAsync.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text(e.toString(), style: const TextStyle(color: AppTheme.muted)),
                  data: (list) => list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            icon: Icons.mode_comment_outlined,
                            title: trg('social.noComments'),
                            message: trg('social.noCommentsMsg'),
                          ))
                      : Column(children: [for (final c in list) _commentTile(c)]),
                ),
              ],
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _postHeader(Post p) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ActorAvatar(p.actor, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.actor?.name ?? trg('social.anonymous'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.ink, letterSpacing: -0.2)),
                const SizedBox(height: 1),
                Text(ago(p.createdAtMs), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
              ]),
            ),
          ]),
          if (p.caption != null && p.caption!.isNotEmpty) ...[
            const SizedBox(height: 12),
            HashtagText(
              p.caption!,
              style: const TextStyle(height: 1.45, color: AppTheme.ink),
              onTapTag: (t) => context.push('/community/tag/$t'),
              onTapMention: (h) => context.push('/community/users/$h'),
            ),
          ],
          for (final m in p.media)
            if (m.url != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: m.isVideo
                      ? PostVideo(m.url!, height: 240)
                      : AuthImage(m.url!, width: double.infinity, height: 240),
                ),
              ),
          const SizedBox(height: 6),
          const SoftDivider(),
          const SizedBox(height: 2),
          Row(children: [
            LikeButton(postId: p.id, liked: p.liked, count: p.likeCount),
            const SizedBox(width: 8),
            const Icon(Icons.mode_comment_outlined, size: 16, color: AppTheme.muted),
            const SizedBox(width: 4),
            Text('${p.commentCount}', style: const TextStyle(color: AppTheme.muted)),
          ]),
        ],
      ),
    );
  }

  Future<void> _deleteComment(Comment c) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(trg('social.deleteMyComment')),
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(socialRepositoryProvider).deleteComment(c.id);
      ref.invalidate(postCommentsProvider(widget.postId));
      ref.invalidate(postDetailProvider(widget.postId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.commentDeleted'))));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(trg('social.deleteCommentDenied'))));
      }
    }
  }

  Widget _commentTile(Comment c, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onLongPress: () => _deleteComment(c),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ActorAvatar(c.author, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(c.author?.name ?? trg('social.anonymous'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(width: 6),
                  Text(ago(c.createdAtMs), style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                ]),
                const SizedBox(height: 2),
                Text(c.content, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                const SizedBox(height: 4),
                Row(children: [
                  InkWell(
                    onTap: () => _likeComment(c),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(c.liked ? Icons.favorite : Icons.favorite_border,
                            size: 15, color: c.liked ? Colors.redAccent : AppTheme.muted),
                        if (c.likeCount > 0) ...[
                          const SizedBox(width: 3),
                          Text('${c.likeCount}', style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: () => _startReply(c),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Text(trg('social.reply'), style: const TextStyle(fontSize: 11.5, color: AppTheme.brand, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ]),
            ),
            InkWell(
              onTap: () => _deleteComment(c),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.more_horiz, size: 16, color: AppTheme.muted),
              ),
            ),
          ])),
          for (final r in c.replies) _commentTile(r, indent: indent + 38),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyTo != null)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 8, 0),
                child: Row(children: [
                  Expanded(
                    child: Text(
                        trg('social.replyingTo').replaceAll('{name}', _replyTo!.author?.name ?? trg('social.aComment')),
                        style: const TextStyle(fontSize: 12, color: AppTheme.brand, fontWeight: FontWeight.w600)),
                  ),
                  InkWell(
                    onTap: () => setState(() => _replyTo = null),
                    child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 16, color: AppTheme.muted)),
                  ),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    focusNode: _commentFocus,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _replyTo != null ? trg('social.writeReply') : trg('social.writeComment'),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppTheme.brand),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
