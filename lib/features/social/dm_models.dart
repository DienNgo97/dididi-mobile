import '../../shared/format.dart';
import 'social_models.dart';

/// Hội thoại (DM) — khớp ConversationView.
/// Với nhóm: [other] là chủ thể giả mang TÊN NHÓM (backend dựng sẵn), không phải người kia.
class Conversation {
  final int id;
  final Actor? other;
  final String? preview;
  final int lastMessageAtMs;
  final int unread;
  final bool group;
  final bool archived;
  final int memberCount;
  Conversation({
    required this.id,
    this.other,
    this.preview,
    this.lastMessageAtMs = 0,
    this.unread = 0,
    this.group = false,
    this.archived = false,
    this.memberCount = 2,
  });
  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: (j['id'] as num).toInt(),
        other: j['other'] == null ? null : Actor.fromJson(j['other'] as Map<String, dynamic>),
        preview: j['preview'] as String?,
        lastMessageAtMs: asNum(j['lastMessageAtMs'])?.toInt() ?? 0,
        unread: asNum(j['unread'])?.toInt() ?? 0,
        group: j['group'] == true,
        archived: j['archived'] == true,
        memberCount: asNum(j['memberCount'])?.toInt() ?? 2,
      );
}

/// Thành viên nhóm + quyền của người đang xem (khớp GET /conversations/{id}/members).
class GroupInfo {
  final bool group;
  final bool owner;
  final List<Actor> members;
  GroupInfo({this.group = false, this.owner = false, this.members = const []});
  factory GroupInfo.fromJson(Map<String, dynamic> j) => GroupInfo(
        group: j['group'] == true,
        owner: j['owner'] == true,
        members: ((j['members'] as List?) ?? const [])
            .map((e) => Actor.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Tin nhắn — khớp MessageView. type = TEXT | IMAGE | POST_SHARE | SYSTEM.
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

  /// Dòng hệ thống của nhóm (tạo nhóm, thêm/xoá/rời, đổi tên) — hiện giữa khung, không bong bóng.
  bool get isSystem => type == 'SYSTEM';

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
