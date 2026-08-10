import '../../shared/format.dart';

/// Chủ thể (người dùng hoặc trang khách sạn) — khớp ActorView.
class Actor {
  final String? type;
  final int? id;
  final String name;
  final String? handle;
  final String? avatarUrl;
  Actor({this.type, this.id, required this.name, this.handle, this.avatarUrl});

  factory Actor.fromJson(Map<String, dynamic> j) => Actor(
        type: j['type'] as String?,
        id: asNum(j['id'])?.toInt(),
        name: (j['name'] ?? '?') as String,
        handle: j['handle'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
      );

  String get initial {
    final n = name.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }
}

class Media {
  final int id;
  final String? mediaType;
  final String? url;
  Media({required this.id, this.mediaType, this.url});
  factory Media.fromJson(Map<String, dynamic> j) => Media(
        id: (j['id'] as num).toInt(),
        mediaType: j['mediaType'] as String?,
        url: j['url'] as String?,
      );
  bool get isVideo => mediaType == 'VIDEO';
}

/// Bài đăng — khớp PostView.
class Post {
  final int id;
  final Actor? actor;
  final String? caption;
  final int createdAtMs;
  final List<Media> media;
  final int? hotelId;
  final String? hotelName;
  final int likeCount;
  final int commentCount;
  final bool liked;
  final bool bookmarked;
  final bool repost;
  final bool reposted;
  final int repostCount;
  final Post? original;

  Post({
    required this.id,
    this.actor,
    this.caption,
    this.createdAtMs = 0,
    this.media = const [],
    this.hotelId,
    this.hotelName,
    this.likeCount = 0,
    this.commentCount = 0,
    this.liked = false,
    this.bookmarked = false,
    this.repost = false,
    this.reposted = false,
    this.repostCount = 0,
    this.original,
  });

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: (j['id'] as num).toInt(),
        actor: j['actor'] == null ? null : Actor.fromJson(j['actor'] as Map<String, dynamic>),
        caption: j['caption'] as String?,
        createdAtMs: asNum(j['createdAtMs'])?.toInt() ?? 0,
        media: ((j['media'] as List?) ?? const [])
            .map((e) => Media.fromJson(e as Map<String, dynamic>))
            .toList(),
        hotelId: asNum(j['hotelId'])?.toInt(),
        hotelName: j['hotelName'] as String?,
        likeCount: asNum(j['likeCount'])?.toInt() ?? 0,
        commentCount: asNum(j['commentCount'])?.toInt() ?? 0,
        liked: j['liked'] == true,
        bookmarked: j['bookmarked'] == true,
        repost: j['repost'] == true,
        reposted: j['reposted'] == true,
        repostCount: asNum(j['repostCount'])?.toInt() ?? 0,
        original: j['original'] == null ? null : Post.fromJson(j['original'] as Map<String, dynamic>),
      );
}

class Comment {
  final int id;
  final Actor? author;
  final String content;
  final int createdAtMs;
  final List<Comment> replies;
  final int likeCount;
  final bool liked;
  Comment({
    required this.id,
    this.author,
    required this.content,
    this.createdAtMs = 0,
    this.replies = const [],
    this.likeCount = 0,
    this.liked = false,
  });
  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: (j['id'] as num).toInt(),
        author: j['author'] == null ? null : Actor.fromJson(j['author'] as Map<String, dynamic>),
        content: (j['content'] ?? '') as String,
        createdAtMs: asNum(j['createdAtMs'])?.toInt() ?? 0,
        replies: ((j['replies'] as List?) ?? const [])
            .map((e) => Comment.fromJson(e as Map<String, dynamic>))
            .toList(),
        likeCount: asNum(j['likeCount'])?.toInt() ?? 0,
        liked: j['liked'] == true,
      );
}

class SocialNotification {
  final int id;
  final Actor? actor;
  final String? type;
  final String message;
  final bool read;
  final int createdAtMs;
  SocialNotification(
      {required this.id, this.actor, this.type, required this.message, this.read = false, this.createdAtMs = 0});
  factory SocialNotification.fromJson(Map<String, dynamic> j) => SocialNotification(
        id: (j['id'] as num).toInt(),
        actor: j['actor'] == null ? null : Actor.fromJson(j['actor'] as Map<String, dynamic>),
        type: j['type'] as String?,
        message: (j['message'] ?? '') as String,
        read: j['read'] == true,
        createdAtMs: asNum(j['createdAtMs'])?.toInt() ?? 0,
      );
}

/// Trang cá nhân mạng xã hội — khớp ProfileView.
class SocialProfile {
  final int? userId;
  final String? handle;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool owner;
  final String followState; // SELF | ACTIVE | PENDING | NONE
  final bool privateAccount;

  SocialProfile({
    this.userId,
    this.handle,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.owner = false,
    this.followState = 'NONE',
    this.privateAccount = false,
  });

  bool get isFollowing => followState == 'ACTIVE' || followState == 'PENDING';

  factory SocialProfile.fromJson(Map<String, dynamic> j) => SocialProfile(
        userId: asNum(j['userId'])?.toInt(),
        handle: j['handle'] as String?,
        displayName: (j['displayName'] ?? j['handle'] ?? '?') as String,
        bio: j['bio'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        coverUrl: j['coverUrl'] as String?,
        postsCount: asNum(j['postsCount'])?.toInt() ?? 0,
        followersCount: asNum(j['followersCount'])?.toInt() ?? 0,
        followingCount: asNum(j['followingCount'])?.toInt() ?? 0,
        owner: j['owner'] == true,
        followState: (j['followState'] ?? 'NONE') as String,
        privateAccount: j['privateAccount'] == true,
      );
}

/// Yêu cầu theo dõi đang chờ (tài khoản riêng tư).
class FollowRequest {
  final int followId;
  final SocialProfile profile;
  FollowRequest({required this.followId, required this.profile});
  factory FollowRequest.fromJson(Map<String, dynamic> j) => FollowRequest(
        followId: (j['followId'] as num).toInt(),
        profile: SocialProfile.fromJson((j['profile'] ?? const {}) as Map<String, dynamic>),
      );
}

/// Thẻ người dùng trong tìm kiếm / gợi ý (khớp UserCardView).
class UserCard {
  final int? userId;
  final Actor? actor;
  final String? bio;
  final String followState; // NONE | ACTIVE | PENDING | SELF
  final bool self;
  UserCard({this.userId, this.actor, this.bio, this.followState = 'NONE', this.self = false});
  factory UserCard.fromJson(Map<String, dynamic> j) => UserCard(
        userId: asNum(j['userId'])?.toInt(),
        actor: j['actor'] == null ? null : Actor.fromJson(j['actor'] as Map<String, dynamic>),
        bio: j['bio'] as String?,
        followState: (j['followState'] ?? 'NONE') as String,
        self: j['self'] == true,
      );
  bool get isFollowing => followState == 'ACTIVE' || followState == 'PENDING';
}

/// Kết quả tìm kiếm mạng xã hội.
class SearchResult {
  final List<UserCard> users;
  final List<Post> posts;
  final List<HashtagTrend> hashtags;
  SearchResult({this.users = const [], this.posts = const [], this.hashtags = const []});
  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
        users: ((j['users'] as List?) ?? const []).map((e) => UserCard.fromJson(e as Map<String, dynamic>)).toList(),
        posts: ((j['posts'] as List?) ?? const []).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList(),
        hashtags:
            ((j['hashtags'] as List?) ?? const []).map((e) => HashtagTrend.fromJson(e as Map<String, dynamic>)).toList(),
      );
  bool get isEmpty => users.isEmpty && posts.isEmpty && hashtags.isEmpty;
}

/// Hashtag thịnh hành.
class HashtagTrend {
  final String tag;
  final int postCount;
  HashtagTrend({required this.tag, this.postCount = 0});
  factory HashtagTrend.fromJson(Map<String, dynamic> j) => HashtagTrend(
        tag: (j['tag'] ?? '') as String,
        postCount: asNum(j['postCount'])?.toInt() ?? 0,
      );
}

/// Một trang feed theo cursor.
class FeedPage {
  final List<Post> items;
  final int? nextCursor;
  FeedPage({required this.items, this.nextCursor});
  factory FeedPage.fromJson(Map<String, dynamic> j) => FeedPage(
        items: ((j['items'] as List?) ?? const [])
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: asNum(j['nextCursor'])?.toInt(),
      );
}
