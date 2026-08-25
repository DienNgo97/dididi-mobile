import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/i18n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/auth_image.dart';
import '../../shared/widgets/error_view.dart';
import 'social_models.dart';
import 'social_repository.dart';

const _brand = Color(0xFF2F8B60);

/// Trang cá nhân mạng xã hội theo handle + nút theo dõi.
class SocialProfileScreen extends ConsumerStatefulWidget {
  final String handle;
  const SocialProfileScreen({super.key, required this.handle});
  @override
  ConsumerState<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends ConsumerState<SocialProfileScreen> {
  SocialProfile? _p;
  List<Post> _posts = [];
  bool _loading = true;
  bool _busy = false;
  Object? _error; // giữ lỗi THÔ để ErrorView tự dịch sang câu tiếng người
  late String _handle = widget.handle; // handle hiện tại (đổi khi user đổi @handle)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await ref.read(socialRepositoryProvider).profileByHandle(_handle);
      if (mounted) setState(() => _p = p);
      // Tải bài của người dùng (để hiện trên trang cá nhân)
      if (p.userId != null) {
        try {
          final page = await ref.read(socialRepositoryProvider).userPosts(p.userId!);
          if (mounted) setState(() => _posts = page.items);
        } catch (_) {
          if (mounted) setState(() => _posts = []);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final file = MultipartFile.fromBytes(await picked.readAsBytes(), filename: picked.name);
      await ref.read(socialRepositoryProvider).setCover(file);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.coverUpdated'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.errorWith').replaceAll('{err}', '$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFollow() async {
    final p = _p;
    if (p == null || p.userId == null) return;
    setState(() => _busy = true);
    try {
      if (p.isFollowing) {
        await ref.read(socialRepositoryProvider).unfollowUser(p.userId!);
      } else {
        await ref.read(socialRepositoryProvider).followUser(p.userId!);
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('common.error'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _message() async {
    final p = _p;
    if (p == null || p.userId == null) return;
    setState(() => _busy = true);
    try {
      final convId = await ref.read(socialRepositoryProvider).openConversation(p.userId!);
      if (mounted) context.push('/dm/$convId', extra: p.displayName);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.dmOpenFailed'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1000);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final file = MultipartFile.fromBytes(await picked.readAsBytes(), filename: picked.name);
      await ref.read(socialRepositoryProvider).setAvatar(file);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.avatarUpdated'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.errorWith').replaceAll('{err}', '$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final p = _p;
    if (p == null) return;
    final nameC = TextEditingController(text: p.displayName);
    final bioC = TextEditingController(text: p.bio ?? '');
    final handleC = TextEditingController(text: p.handle ?? '');
    bool isPrivate = p.privateAccount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(trg('social.editProfile')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameC, decoration: InputDecoration(labelText: trg('social.displayName'), border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                  controller: handleC,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: trg('social.handle'),
                    prefixText: '@',
                    helperText: trg('social.handleHelp'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: bioC, maxLines: 3, decoration: InputDecoration(labelText: trg('social.bio'), border: const OutlineInputBorder())),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(trg('social.privateAccount')),
                  subtitle: Text(trg('social.privateAccountSub')),
                  value: isPrivate,
                  onChanged: (v) => setS(() => isPrivate = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.save'))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final repo = ref.read(socialRepositoryProvider);
      final newHandle = handleC.text.trim();
      if (newHandle.isNotEmpty && newHandle != (p.handle ?? '')) {
        await repo.changeHandle(newHandle);
        _handle = newHandle; // tải lại bằng handle mới (tránh 404 do handle cũ)
      }
      await repo.updateSocialProfile(displayName: nameC.text.trim(), bio: bioC.text.trim(), isPrivate: isPrivate);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.profileUpdated'))));
    } catch (e) {
      final msg = e is ApiException ? e.message : trg('social.errorWith').replaceAll('{err}', '$e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@$_handle'),
        actions: [
          if (_p?.owner == true) ...[
            IconButton(
              icon: const Icon(Icons.person_add_alt),
              tooltip: trg('social.followRequests'),
              onPressed: () => context.push('/community/requests'),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined), tooltip: trg('social.editProfile'), onPressed: _edit),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(error: _error, onRetry: _load)
              : _body(_p!),
    );
  }

  Widget _body(SocialProfile p) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Ảnh bìa (cover)
        Stack(
          children: [
            (p.coverUrl != null && p.coverUrl!.isNotEmpty)
                ? AuthImage(p.coverUrl!, width: double.infinity, height: 130, radius: BorderRadius.circular(12))
                : Container(
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF3EE), Color(0xFFD6E9DE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
            if (p.owner)
              Positioned(
                right: 8,
                top: 8,
                child: InkWell(
                  onTap: _busy ? null : _pickCover,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Center(
          child: Stack(
            children: [
              (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                  ? ClipOval(child: AuthImage(p.avatarUrl!, width: 84, height: 84))
                  : CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.brandSoft,
                      child: Text(
                        p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 34, color: _brand, fontWeight: FontWeight.bold),
                      ),
                    ),
              if (p.owner)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: _busy ? null : _pickAvatar,
                    child: Container(
                      decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(p.displayName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
        if (p.handle != null)
          Center(child: Text('@${p.handle}', style: const TextStyle(color: AppTheme.muted))),
        if (p.bio != null && p.bio!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(p.bio!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.ink, height: 1.4)),
        ],
        const SizedBox(height: 18),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('${p.postsCount}', trg('social.posts')),
              _stat('${p.followersCount}', trg('social.followers')),
              _stat('${p.followingCount}', trg('social.following')),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!p.owner)
          Row(children: [
            Expanded(
              child: p.isFollowing
                  ? OutlinedButton.icon(
                      onPressed: _busy ? null : _toggleFollow,
                      icon: const Icon(Icons.check),
                      label: Text(p.followState == 'PENDING' ? trg('social.requested') : trg('social.following')),
                    )
                  : FilledButton.icon(
                      onPressed: _busy ? null : _toggleFollow,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(trg('social.follow')),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _message,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(trg('social.message')),
              ),
            ),
          ]),
        const SizedBox(height: 22),
        SectionHeader(trg('social.posts')),
        if (_posts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: EmptyState(
              icon: Icons.article_outlined,
              title: trg('social.noPosts'),
            ),
          )
        else
          for (final post in _posts) _postRow(post),
      ],
    );
  }

  Widget _postRow(Post post) {
    final img = post.media.isNotEmpty ? post.media.first.url : null;
    return InkWell(
      onTap: () => context.push('/community/posts/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (img != null && img.isNotEmpty)
                ? AuthImage(img, width: 56, height: 56, radius: BorderRadius.circular(8))
                : Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppTheme.brandSoft, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.article_outlined, color: _brand, size: 22),
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  (post.caption != null && post.caption!.trim().isNotEmpty) ? post.caption!.trim() : trg('social.postWithPhoto'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                    trg('social.likesComments')
                        .replaceAll('{likes}', '${post.likeCount}')
                        .replaceAll('{comments}', '${post.commentCount}'),
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _brand)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        ],
      );
}
