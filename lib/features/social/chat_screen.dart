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
import '../../shared/widgets/actor_avatar.dart';
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
  /// Tên hiển thị: giữ ở state để đổi tên nhóm xong tiêu đề đổi ngay, khỏi phải quay ra hộp thư.
  late String _title = widget.title;

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

  // ---- Nhóm: thông tin, đổi tên, thêm/xoá thành viên, rời nhóm ----

  Future<void> _openGroupSheet() async {
    final GroupInfo info;
    try {
      info = await ref.read(groupInfoProvider(widget.convId).future);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    if (!mounted || info.members.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _GroupSheet(
        convId: widget.convId,
        title: _title,
        info: info,
        onRenamed: (t) => setState(() => _title = t),
      ),
    );
    if (mounted) {
      ref.invalidate(conversationMessagesProvider(widget.convId));
      ref.invalidate(groupInfoProvider(widget.convId));
      ref.invalidate(dmInboxProvider);
    }
  }

  Future<void> _archive() async {
    try {
      await ref.read(socialRepositoryProvider).archiveConversation(widget.convId, true);
      if (!mounted) return;
      ref.invalidate(dmInboxProvider);
      ref.invalidate(dmArchivedProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trg('dm.archivedDone'))));
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// [group] = true thì là rời nhóm, ngược lại là xoá đoạn chat 1-1.
  Future<void> _deleteOrLeave(bool group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trg(group ? 'dm.leave' : 'dm.delete')),
        content: Text(trg(group ? 'dm.leaveConfirm' : 'dm.deleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.ok'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final repo = ref.read(socialRepositoryProvider);
      if (group) {
        await repo.leaveGroup(widget.convId);
      } else {
        await repo.deleteConversation(widget.convId);
      }
      if (!mounted) return;
      ref.invalidate(dmInboxProvider);
      ref.invalidate(dmArchivedProvider);
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationMessagesProvider(widget.convId));
    // Cần biết là nhóm hay 1-1 để bày đúng menu; lỗi thì coi như 1-1, menu vẫn dùng được.
    final isGroup = ref.watch(groupInfoProvider(widget.convId)).maybeWhen(
          data: (g) => g.group,
          orElse: () => false,
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (isGroup)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: trg('dm.groupInfo'),
              onPressed: _openGroupSheet,
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'archive') _archive();
              if (v == 'delete') _deleteOrLeave(isGroup);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'archive', child: Text(trg('dm.archive'))),
              PopupMenuItem(
                value: 'delete',
                child: Text(trg(isGroup ? 'dm.leave' : 'dm.delete'),
                    style: const TextStyle(color: Color(0xFFC0392B))),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                  error: e, onRetry: () => ref.invalidate(conversationMessagesProvider(widget.convId))),
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
                  itemBuilder: (_, i) => _bubble(msgs[i], isGroup),
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(Message m, [bool isGroup = false]) {
    // Dòng hệ thống của nhóm: hiện giữa khung, không bong bóng (giống Messenger).
    if (m.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(m.content ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
          ),
        ),
      );
    }
    final mine = m.mine;
    // Nhóm 3+ người: tin của người khác mà không kèm avatar + tên thì không biết ai nói.
    if (isGroup && !mine) {
      return Padding(
        padding: const EdgeInsets.only(right: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 6),
              child: ActorAvatar(m.sender, size: 26),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: Text(m.sender?.name ?? '',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
                  ),
                  _plainBubble(m, false),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: _plainBubble(m, mine),
    );
  }

  Widget _plainBubble(Message m, bool mine) {
    return Container(
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

/// Bảng thông tin nhóm: danh sách thành viên, đổi tên + xoá người (chỉ chủ nhóm),
/// thêm thành viên (mọi thành viên đều làm được).
class _GroupSheet extends ConsumerStatefulWidget {
  const _GroupSheet({
    required this.convId,
    required this.title,
    required this.info,
    required this.onRenamed,
  });

  final int convId;
  final String title;
  final GroupInfo info;
  final ValueChanged<String> onRenamed;

  @override
  ConsumerState<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends ConsumerState<_GroupSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.title);
  late List<Actor> _members = List.of(widget.info.members);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _rename() async {
    final t = _name.text.trim();
    if (t.isEmpty) {
      _snack(trg('dm.needGroupName'));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(socialRepositoryProvider).renameGroup(widget.convId, t);
      if (!mounted) return;
      widget.onRenamed(t);        // đẩy tên mới lên AppBar của khung chat
      _snack(trg('dm.renamed'));
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(Actor a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(trg('dm.removeConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(trg('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(trg('common.ok'))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(socialRepositoryProvider).removeMember(widget.convId, a.id ?? 0);
      if (mounted) setState(() => _members = _members.where((m) => m.id != a.id).toList());
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    // Lấy tên trong ô nhập, không phải widget.title: vừa đổi tên xong mà vẫn đưa tên cũ
    // sang màn "Thêm thành viên" thì người dùng tưởng bấm nhầm nhóm.
    final ten = _name.text.trim().isEmpty ? widget.title : _name.text.trim();
    final added = await context.push<bool>('/dm/group/add/${widget.convId}', extra: ten);
    if (added != true || !mounted) return;
    try {
      final info = await ref.read(socialRepositoryProvider).groupInfo(widget.convId);
      if (mounted) setState(() => _members = info.members);
    } catch (_) {/* danh sách sẽ tự nạp lại khi đóng bảng */}
  }

  @override
  Widget build(BuildContext context) {
    final owner = widget.info.owner;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(trg('dm.groupInfo'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            if (owner)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _name,
                      maxLength: 120,
                      decoration: InputDecoration(labelText: trg('dm.groupName'), counterText: '', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _busy ? null : _rename, child: Text(trg('dm.rename'))),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              // KHÔNG bọc trong Row: theme đặt minimumSize = Size.fromHeight(50)
              // tức rộng tối thiểu vô hạn, Row cấp constraint không giới hạn -> vỡ bố trí.
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _add,
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text(trg('dm.addMember')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(trg('dm.addHint'), style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            ),
            const SoftDivider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < _members.length; i++)
                    ListTile(
                      dense: true,
                      leading: ActorAvatar(_members[i], size: 36),
                      title: Text(_members[i].name),
                      subtitle: i == 0 ? Text(trg('dm.owner')) : null,
                      trailing: (owner && i > 0)
                          ? IconButton(
                              icon: const Icon(Icons.person_remove_outlined, color: Color(0xFFC0392B)),
                              onPressed: _busy ? null : () => _remove(_members[i]),
                            )
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
