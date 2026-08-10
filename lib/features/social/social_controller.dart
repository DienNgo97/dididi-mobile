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

/// Tin nhắn trong 1 hội thoại.
final conversationMessagesProvider = FutureProvider.family<List<Message>, int>(
  (ref, convId) => ref.read(socialRepositoryProvider).messages(convId),
);
