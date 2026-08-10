import '../../shared/format.dart';
import 'social_models.dart';

/// Hội thoại (DM) — khớp ConversationView.
class Conversation {
  final int id;
  final Actor? other;
  final String? preview;
  final int lastMessageAtMs;
  final int unread;
  Conversation({required this.id, this.other, this.preview, this.lastMessageAtMs = 0, this.unread = 0});
  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: (j['id'] as num).toInt(),
        other: j['other'] == null ? null : Actor.fromJson(j['other'] as Map<String, dynamic>),
        preview: j['preview'] as String?,
        lastMessageAtMs: asNum(j['lastMessageAtMs'])?.toInt() ?? 0,
        unread: asNum(j['unread'])?.toInt() ?? 0,
      );
}

/// Tin nhắn — khớp MessageView. type = TEXT | IMAGE | POST_SHARE.
class Message {
  final int id;
  final bool mine;
  final Actor? sender;
  final String? type;
  final String? content;
  final String? mediaUrl;
  final Post? sharedPost;
  final int createdAtMs;
  Message({
    required this.id,
    this.mine = false,
    this.sender,
    this.type,
    this.content,
    this.mediaUrl,
    this.sharedPost,
    this.createdAtMs = 0,
  });

  bool get isImage => type == 'IMAGE';
  bool get isPostShare => type == 'POST_SHARE';

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: (j['id'] as num).toInt(),
        mine: j['mine'] == true,
        sender: j['sender'] == null ? null : Actor.fromJson(j['sender'] as Map<String, dynamic>),
        type: j['type'] as String?,
        content: j['content'] as String?,
        mediaUrl: j['mediaUrl'] as String?,
        sharedPost: j['sharedPost'] == null ? null : Post.fromJson(j['sharedPost'] as Map<String, dynamic>),
        createdAtMs: asNum(j['createdAtMs'])?.toInt() ?? 0,
      );
}
