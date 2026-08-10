import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/format.dart';
import '../../shared/ui/ui_kit.dart';
import '../../shared/widgets/auth_image.dart';
import '../../shared/widgets/error_view.dart';
import 'dm_models.dart';
import 'social_controller.dart';
import 'social_models.dart';
import 'social_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int convId;
  final String title;
  const ChatScreen({super.key, required this.convId, required this.title});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _c = TextEditingController();
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(conversationMessagesProvider(widget.convId)); // luôn lấy tin mới nhất (kể cả bài vừa chia sẻ)
      ref.read(socialRepositoryProvider).markConversationRead(widget.convId).ignore();
      ref.invalidate(dmInboxProvider);
    });
    // Tự cập nhật tin nhắn mới ~5s (giống web poll).
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _sending) return;
      ref.invalidate(conversationMessagesProvider(widget.convId));
      ref.read(socialRepositoryProvider).markConversationRead(widget.convId).ignore();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(socialRepositoryProvider).sendText(widget.convId, t);
      _c.clear();
      ref.invalidate(conversationMessagesProvider(widget.convId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (picked == null) return;
    setState(() => _sending = true);
    try {
      final bytes = await picked.readAsBytes();
      final file = MultipartFile.fromBytes(bytes, filename: picked.name);
      await ref.read(socialRepositoryProvider).sendImage(widget.convId, file);
      ref.invalidate(conversationMessagesProvider(widget.convId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationMessagesProvider(widget.convId));
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                  message: e.toString(), onRetry: () => ref.invalidate(conversationMessagesProvider(widget.convId))),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: trg('dm.startChat'),
                    message: trg('dm.startChatMsg'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _bubble(msgs[i]),
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(Message m) {
    final mine = m.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: mine ? AppTheme.brand : const Color(0xFFEDEFEE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AuthImage('/api/v1/social/conversations/${widget.convId}/media/${m.id}',
                    width: 200, height: 200, fit: BoxFit.cover),
              )
            else if (m.isPostShare && m.sharedPost != null)
              _sharedPostCard(m.sharedPost!, mine)
            else
              Text(m.content ?? '',
                  style: TextStyle(color: mine ? Colors.white : AppTheme.ink)),
            const SizedBox(height: 2),
            Text(ago(m.createdAtMs),
                style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : AppTheme.muted)),
          ],
        ),
      ),
    );
  }

  Widget _sharedPostCard(Post p, bool mine) {
    final onDark = mine;
    return InkWell(
      onTap: () => context.push('/community/posts/${p.id}'),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: onDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onDark ? Colors.white24 : AppTheme.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.media.isNotEmpty && p.media.first.url != null)
              AuthImage(p.media.first.url!, width: 220, height: 120, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.actor?.name ?? trg('social.post'),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: onDark ? Colors.white : AppTheme.ink)),
                  if (p.caption != null && p.caption!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(p.caption!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: onDark ? Colors.white70 : AppTheme.muted)),
                    ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.article_outlined, size: 13, color: onDark ? Colors.white60 : AppTheme.muted),
                    const SizedBox(width: 4),
                    Text(trg('social.viewPost'),
                        style: TextStyle(fontSize: 11, color: onDark ? Colors.white60 : AppTheme.muted)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(children: [
            IconButton(
              onPressed: _sending ? null : _pickAndSendImage,
              tooltip: trg('dm.sendImage'),
              icon: const Icon(Icons.image_outlined, color: AppTheme.brand),
            ),
            Expanded(
              child: TextField(
                controller: _c,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(hintText: trg('dm.messageHint'), isDense: true),
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
      ),
    );
  }
}
