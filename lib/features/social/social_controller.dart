import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dm_models.dart';
import 'social_models.dart';
import 'social_repository.dart';

/// Feed cộng đồng.
final feedProvider = AsyncNotifierProvider<FeedController, List<Post>>(FeedController.new);

class FeedController extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async => (await ref.read(socialRepositoryProvider).feed()).items;

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async => (await ref.read(socialRepositoryProvider).feed()).items);
  }
}

/// Chi tiết 1 bài.
final postDetailProvider = FutureProvider.family<Post, int>(
  (ref, id) => ref.read(socialRepositoryProvider).post(id),
);

/// Bình luận của 1 bài.
final postCommentsProvider = FutureProvider.family<List<Comment>, int>(
  (ref, postId) => ref.read(socialRepositoryProvider).comments(postId),
);

/// Thông báo cộng đồng.
final notificationsProvider = FutureProvider<List<SocialNotification>>(
  (ref) => ref.read(socialRepositoryProvider).notifications(),
);

/// Hộp thư DM.
final dmInboxProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.read(socialRepositoryProvider).inbox(),
);

/// Hộp thư Lưu trữ (những hội thoại đã cất đi).
final dmArchivedProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.read(socialRepositoryProvider).archivedInbox(),
);

/// Tin nhắn trong 1 hội thoại.
final conversationMessagesProvider = FutureProvider.family<List<Message>, int>(
  (ref, convId) => ref.read(socialRepositoryProvider).messages(convId),
);

/// Thành viên + quyền chủ nhóm của hội thoại đang mở.
final groupInfoProvider = FutureProvider.autoDispose.family<GroupInfo, int>(
  (ref, convId) => ref.read(socialRepositoryProvider).groupInfo(convId),
);

/// Bạn bè mời vào nhóm được (theo dõi qua lại). Tham số: convId (0 = đang tạo nhóm mới) + từ khoá.
/// autoDispose: key co ca tu khoa tim nen khong bo thi go 6 chu = 6 provider song mai.
final invitableFriendsProvider =
    FutureProvider.autoDispose.family<List<Actor>, ({int convId, String q})>(
  (ref, arg) => ref.read(socialRepositoryProvider).invitableFriends(
        q: arg.q.isEmpty ? null : arg.q,
        convId: arg.convId == 0 ? null : arg.convId,
      ),
);
