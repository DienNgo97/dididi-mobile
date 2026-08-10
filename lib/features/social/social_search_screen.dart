import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/ui_kit.dart';
import 'social_models.dart';
import 'social_repository.dart';

const _brand = Color(0xFF2F8B60);

/// Tìm kiếm mạng xã hội: người dùng + hashtag + bài viết; gợi ý người khi ô trống.
class SocialSearchScreen extends ConsumerStatefulWidget {
  const SocialSearchScreen({super.key});
  @override
  ConsumerState<SocialSearchScreen> createState() => _SocialSearchScreenState();
}

class _SocialSearchScreenState extends ConsumerState<SocialSearchScreen> {
  final _q = TextEditingController();
  SearchResult? _result;
  List<UserCard> _suggest = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSuggest();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _loadSuggest() async {
    try {
      final s = await ref.read(socialRepositoryProvider).peopleSuggest();
      if (mounted) setState(() => _suggest = s);
    } catch (_) {}
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _result = null);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ref.read(socialRepositoryProvider).search(q.trim());
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('social.searchFailed').replaceAll('{err}', '$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _q,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _doSearch,
          decoration: InputDecoration(
            hintText: trg('social.searchHint'),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _doSearch(_q.text)),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : (_result == null ? _suggestions() : _results(_result!)),
    );
  }

  Widget _suggestions() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionHeader(trg('social.suggestFollow'), icon: Icons.person_add_alt_1),
        if (_suggest.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: EmptyState(
              icon: Icons.group_outlined,
              title: trg('social.noSuggest'),
              message: trg('social.noSuggestMsg'),
            ),
          )
        else
          for (final u in _suggest) _userTile(u),
      ],
    );
  }

  Widget _results(SearchResult r) {
    if (r.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: trg('social.noResults'),
        message: trg('social.noResultsMsg'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (r.users.isNotEmpty) ...[
          _sectionTitle(trg('social.users')),
          for (final u in r.users) _userTile(u),
        ],
        if (r.hashtags.isNotEmpty) ...[
          _sectionTitle(trg('social.hashtags')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final h in r.hashtags)
              InkWell(
                onTap: () => context.push('/community/tag/${h.tag}'),
                borderRadius: BorderRadius.circular(100),
                child: Pill('#${h.tag} · ${h.postCount}'),
              ),
          ]),
          const SizedBox(height: 8),
        ],
        if (r.posts.isNotEmpty) ...[
          _sectionTitle(trg('social.posts')),
          for (final p in r.posts) _postTile(p),
        ],
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: SectionHeader(t),
      );

  Widget _userTile(UserCard u) {
    final a = u.actor;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: a?.handle == null ? null : () => context.push('/community/users/${a!.handle}'),
      leading: CircleAvatar(
        backgroundColor: AppTheme.brandSoft,
        child: Text(a?.initial ?? '?', style: const TextStyle(color: _brand, fontWeight: FontWeight.bold)),
      ),
      title: Text(a?.name ?? '?', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([if (a?.handle != null) '@${a!.handle}', if (u.bio != null && u.bio!.isNotEmpty) u.bio!].join(' · '),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: u.self
          ? null
          : Text(u.isFollowing ? trg('social.following') : trg('social.view'), style: const TextStyle(color: _brand, fontSize: 12.5)),
    );
  }

  Widget _postTile(Post p) => ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => context.push('/community/posts/${p.id}'),
        leading: const Icon(Icons.article_outlined, color: _brand),
        title: Text(p.caption ?? trg('social.noContent'), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(p.actor?.name ?? trg('social.anonymous'), style: const TextStyle(fontSize: 12)),
      );
}
