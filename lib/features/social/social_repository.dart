import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../core/network/api_client.dart';
import '../../shared/format.dart';
import 'dm_models.dart';
import 'social_models.dart';

final socialRepositoryProvider =
    Provider<SocialRepository>((ref) => SocialRepository(ref.watch(apiClientProvider)));

/// Khách sạn mà tôi sở hữu (để đăng bài dưới danh nghĩa KS). Rỗng nếu không phải chủ KS.
final myHotelsProvider = FutureProvider.autoDispose<List<({int id, String name})>>(
    (ref) => ref.read(socialRepositoryProvider).myHotels());

class SocialRepository {
  final ApiClient _api;
  SocialRepository(this._api);

  // ---- Feed / bài viết ----
  Future<FeedPage> feed({int cursor = 0}) => _api.getData(
        '/api/v1/social/feed',
        query: {'cursor': cursor},
        parse: (d) => FeedPage.fromJson(d as Map<String, dynamic>),
      );

  Future<FeedPage> explore({int cursor = 0}) => _api.getData(
        '/api/v1/social/explore',
        query: {'cursor': cursor},
        parse: (d) => FeedPage.fromJson(d as Map<String, dynamic>),
      );

  Future<Post> post(int id) =>
      _api.getData('/api/v1/social/posts/$id', parse: (d) => Post.fromJson(d as Map<String, dynamic>));

  // ---- Trang cá nhân / theo dõi ----
  Future<SocialProfile> myProfile() =>
      _api.getData('/api/v1/social/me', parse: (d) => SocialProfile.fromJson(d as Map<String, dynamic>));

  Future<SocialProfile> profileByHandle(String handle) => _api.getData(
        '/api/v1/social/users/$handle/profile',
        parse: (d) => SocialProfile.fromJson(d as Map<String, dynamic>),
      );

  Future<void> followUser(int userId) =>
      _api.postData<void>('/api/v1/social/users/$userId/follow', parse: (_) {});

  Future<void> unfollowUser(int userId) =>
      _api.deleteData<void>('/api/v1/social/users/$userId/follow', parse: (_) {});

  Future<bool> bookmark(int postId) => _api.postData(
        '/api/v1/social/posts/$postId/bookmark',
        parse: (d) => (d as Map)['bookmarked'] == true,
      );

  /// Đăng lại (repost) — bật/tắt. Trả về true nếu đang repost sau thao tác.
  Future<bool> repost(int postId) => _api.postData(
        '/api/v1/social/posts/$postId/repost',
        parse: (d) => d is Map ? (d['reposted'] == true) : true,
      );

  /// Xoá bài của mình (backend kiểm quyền sở hữu).
  Future<void> deletePost(int postId) =>
      _api.deleteData<void>('/api/v1/social/posts/$postId', parse: (_) {});

  Future<Map<String, dynamic>> like(int id) => _api.postData(
        '/api/v1/social/posts/$id/like',
        parse: (d) => (d as Map).cast<String, dynamic>(),
      );

  Future<List<Comment>> comments(int id) => _api.getData(
        '/api/v1/social/posts/$id/comments',
        parse: (d) =>
            ((d as List?) ?? const []).map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<Comment> addComment(int id, String content, {int? parentId}) => _api.postData(
        '/api/v1/social/posts/$id/comments',
        query: {'content': content, if (parentId != null) 'parentId': parentId},
        parse: (d) => Comment.fromJson(d as Map<String, dynamic>),
      );

  /// Thả/bỏ tim một bình luận → {liked, count}.
  Future<Map<String, dynamic>> likeComment(int commentId) => _api.postData(
        '/api/v1/social/comments/$commentId/like',
        parse: (d) => (d as Map).cast<String, dynamic>(),
      );

  /// Bài viết của một người dùng (để hiển thị trên trang cá nhân).
  Future<FeedPage> userPosts(int userId, {int cursor = 0}) => _api.getData(
        '/api/v1/social/users/$userId/posts',
        query: {'cursor': cursor},
        parse: (d) => FeedPage.fromJson(d as Map<String, dynamic>),
      );

  Future<Post> createPost(
    String caption, {
    List<MultipartFile> files = const [],
    String visibility = 'PUBLIC',
    String? hotelKeyword,
    bool checkin = false,
    String postAs = 'self', // 'self' | 'hotel:{id}'
  }) =>
      _api.postMultipart(
        '/api/v1/social/posts',
        FormData.fromMap({
          'caption': caption,
          'visibility': visibility,
          'postAs': postAs,
          if (hotelKeyword != null && hotelKeyword.isNotEmpty) 'hotelKeyword': hotelKeyword,
          if (checkin) 'checkin': 'true',
          if (files.isNotEmpty) 'files': files,
        }),
        parse: (d) => Post.fromJson(d as Map<String, dynamic>),
      );

  /// Khách sạn mà tôi sở hữu (để đăng bài dưới danh nghĩa KS). Rỗng nếu không phải chủ KS.
  Future<List<({int id, String name})>> myHotels() => _api.getData(
        '/api/v1/social/my-hotels',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => (
                  id: int.tryParse('${(e as Map)['id']}') ?? 0,
                  name: (e['name'] ?? '').toString(),
                ))
            .toList(),
      );

  // ---- Hashtag ----
  Future<FeedPage> hashtagPosts(String tag, {int cursor = 0}) => _api.getData(
        '/api/v1/social/hashtags/$tag/posts',
        query: {'cursor': cursor},
        parse: (d) => FeedPage.fromJson(d as Map<String, dynamic>),
      );

  Future<List<HashtagTrend>> trendingHashtags() => _api.getData(
        '/api/v1/social/hashtags/trending',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => HashtagTrend.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // ---- Tìm kiếm / gợi ý / bài đã lưu / hồ sơ ----
  Future<SearchResult> search(String q) => _api.getData(
        '/api/v1/social/search',
        query: {'q': q},
        parse: (d) => SearchResult.fromJson(d as Map<String, dynamic>),
      );

  Future<List<UserCard>> peopleSuggest() => _api.getData(
        '/api/v1/social/people',
        parse: (d) => ((d as List?) ?? const []).map((e) => UserCard.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<List<Post>> bookmarks() => _api.getData(
        '/api/v1/social/bookmarks',
        parse: (d) => ((d as List?) ?? const []).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<void> updateSocialProfile({String? displayName, String? bio, String? link, bool? isPrivate}) =>
      _api.postData<void>(
        '/api/v1/social/me',
        body: {
          if (displayName != null) 'displayName': displayName,
          if (bio != null) 'bio': bio,
          if (link != null) 'link': link,
          if (isPrivate != null) 'private': isPrivate,
        },
        parse: (_) {},
      );

  // ---- Trang cộng đồng theo khách sạn ----
  Future<FeedPage> hotelPosts(int hotelId, {int cursor = 0}) => _api.getData(
        '/api/v1/social/hotels/$hotelId/posts',
        query: {'cursor': cursor},
        parse: (d) => FeedPage.fromJson(d as Map<String, dynamic>),
      );

  // ---- Yêu cầu theo dõi ----
  Future<List<FollowRequest>> followRequests() => _api.getData(
        '/api/v1/social/follow-requests',
        parse: (d) =>
            ((d as List?) ?? const []).map((e) => FollowRequest.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<void> acceptFollowRequest(int followId) =>
      _api.postData<void>('/api/v1/social/follow-requests/$followId/accept', parse: (_) {});

  Future<void> rejectFollowRequest(int followId) =>
      _api.postData<void>('/api/v1/social/follow-requests/$followId/reject', parse: (_) {});

  // ---- Ảnh đại diện / bìa / đổi @handle ----
  Future<void> setAvatar(MultipartFile image) => _api.postMultipart<void>(
        '/api/v1/social/me/avatar',
        FormData.fromMap({'image': image}),
        parse: (_) {},
      );

  Future<void> setCover(MultipartFile image) => _api.postMultipart<void>(
        '/api/v1/social/me/cover',
        FormData.fromMap({'image': image}),
        parse: (_) {},
      );

  Future<void> changeHandle(String handle) =>
      _api.postData<void>('/api/v1/social/me/handle', query: {'handle': handle}, parse: (_) {});

  // ---- Xoá bình luận ----
  Future<void> deleteComment(int commentId) =>
      _api.deleteData<void>('/api/v1/social/comments/$commentId', parse: (_) {});

  // ---- Báo cáo ----
  Future<void> report({required String type, required int id, required String reason, String? note}) =>
      _api.postData<void>(
        '/api/v1/social/reports',
        query: {'type': type, 'id': id, 'reason': reason, if (note != null && note.isNotEmpty) 'note': note},
        parse: (_) {},
      );

  // ---- Thông báo ----
  Future<List<SocialNotification>> notifications() => _api.getData(
        '/api/v1/social/notifications',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => SocialNotification.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<int> unreadCount() => _api.getData(
        '/api/v1/social/notifications/unread-count',
        parse: (d) => asNum((d as Map)['count'])?.toInt() ?? 0,
      );

  Future<void> markAllRead() =>
      _api.postData<void>('/api/v1/social/notifications/read', parse: (_) {});

  // ---- Tin nhắn (DM) ----
  Future<List<Conversation>> inbox() => _api.getData(
        '/api/v1/social/conversations',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<int> openConversation(int toUserId) => _api.postData(
        '/api/v1/social/conversations',
        query: {'toUserId': toUserId},
        parse: (d) => asNum((d as Map)['conversationId'])?.toInt() ?? 0,
      );

  Future<List<Message>> messages(int convId) => _api.getData(
        '/api/v1/social/conversations/$convId/messages',
        parse: (d) =>
            ((d as List?) ?? const []).map((e) => Message.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<Message> sendText(int convId, String content) => _api.postData(
        '/api/v1/social/conversations/$convId/messages',
        query: {'content': content},
        parse: (d) => Message.fromJson(d as Map<String, dynamic>),
      );

  /// Gửi ảnh trong hội thoại (multipart field 'image').
  Future<Message> sendImage(int convId, MultipartFile image) => _api.postMultipart(
        '/api/v1/social/conversations/$convId/messages',
        FormData.fromMap({'image': image}),
        parse: (d) => Message.fromJson(d as Map<String, dynamic>),
      );

  /// Chia sẻ một bài viết vào hội thoại.
  Future<Message> sharePost(int convId, int postId, {String? text}) => _api.postData(
        '/api/v1/social/conversations/$convId/share',
        query: {'postId': postId, if (text != null && text.isNotEmpty) 'text': text},
        parse: (d) => Message.fromJson(d as Map<String, dynamic>),
      );

  Future<void> markConversationRead(int convId) =>
      _api.postData<void>('/api/v1/social/conversations/$convId/read', parse: (_) {});

  // ---- Xoá / lưu trữ cuộc trò chuyện (chỉ ảnh hưởng phía mình) ----

  Future<List<Conversation>> archivedInbox() => _api.getData(
        '/api/v1/social/conversations/archived',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Xoá đoạn chat ở phía mình. Người kia vẫn giữ lịch sử; họ nhắn tiếp thì hội thoại
  /// quay lại hộp thư nhưng chỉ hiện tin mới.
  Future<void> deleteConversation(int convId) =>
      _api.deleteData<void>('/api/v1/social/conversations/$convId', parse: (_) {});

  Future<void> archiveConversation(int convId, bool on) => _api.postData<void>(
        '/api/v1/social/conversations/$convId/archive',
        query: {'on': on},
        parse: (_) {},
      );

  // ---- Nhóm chat ----

  /// Người mời vào nhóm được: chỉ ai theo dõi qua lại với mình (backend chặn, đây là để UI
  /// không bày ra rồi bấm xong mới ăn lỗi). convId != null thì bỏ luôn người đã trong nhóm.
  Future<List<Actor>> invitableFriends({String? q, int? convId}) => _api.getData(
        '/api/v1/social/conversations/invitable',
        query: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (convId != null) 'convId': convId,
        },
        parse: (d) =>
            ((d as List?) ?? const []).map((e) => Actor.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<int> createGroup(String title, List<int> memberIds) => _api.postData(
        '/api/v1/social/conversations/group',
        query: {'title': title, 'memberIds': memberIds},
        parse: (d) => asNum((d as Map)['conversationId'])?.toInt() ?? 0,
      );

  Future<GroupInfo> groupInfo(int convId) => _api.getData(
        '/api/v1/social/conversations/$convId/members',
        parse: (d) => GroupInfo.fromJson(d as Map<String, dynamic>),
      );

  Future<void> addMembers(int convId, List<int> memberIds) => _api.postData<void>(
        '/api/v1/social/conversations/$convId/members',
        query: {'memberIds': memberIds},
        parse: (_) {},
      );

  Future<void> removeMember(int convId, int userId) => _api.deleteData<void>(
        '/api/v1/social/conversations/$convId/members/$userId',
        parse: (_) {},
      );

  Future<void> renameGroup(int convId, String title) => _api.postData<void>(
        '/api/v1/social/conversations/$convId/rename',
        query: {'title': title},
        parse: (_) {},
      );

  Future<void> leaveGroup(int convId) =>
      _api.postData<void>('/api/v1/social/conversations/$convId/leave', parse: (_) {});
}
