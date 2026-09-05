/// Chuỗi i18n nhóm Cộng đồng (social + DM). vi/en/zh.
const socialStrings = <String, Map<String, String>>{
  // ----- Chung nhóm social -----
  'social.anonymous': {'vi': 'Ẩn danh', 'en': 'Anonymous', 'zh': '匿名'},
  'social.someone': {'vi': 'Ai đó', 'en': 'Someone', 'zh': '某人'},
  'social.user': {'vi': 'Người dùng', 'en': 'User', 'zh': '用户'},
  'social.post': {'vi': 'Bài viết', 'en': 'Post', 'zh': '帖子'},
  'social.posts': {'vi': 'Bài viết', 'en': 'Posts', 'zh': '帖子'},
  'social.noPosts': {'vi': 'Chưa có bài viết', 'en': 'No posts yet', 'zh': '暂无帖子'},
  'social.noPostsMsg': {
    'vi': 'Hãy là người đầu tiên chia sẻ trải nghiệm du lịch của bạn!',
    'en': 'Be the first to share your travel experience!',
    'zh': '快来分享你的第一段旅行体验吧！'
  },

  // ----- Feed cộng đồng -----
  'social.repostedBy': {'vi': '{name} đã đăng lại', 'en': '{name} reposted', 'zh': '{name} 转发了'},

  // ----- Khám phá -----
  'social.explore': {'vi': 'Khám phá', 'en': 'Explore', 'zh': '发现'},
  'social.noPublicPosts': {'vi': 'Chưa có bài viết công khai', 'en': 'No public posts yet', 'zh': '暂无公开帖子'},
  'social.noPublicPostsMsg': {
    'vi': 'Hãy quay lại sau để khám phá trải nghiệm mới.',
    'en': 'Check back later to discover new experiences.',
    'zh': '稍后再来发现新体验吧。'
  },
  'social.trendingHashtags': {'vi': 'Hashtag thịnh hành', 'en': 'Trending hashtags', 'zh': '热门话题'},

  // ----- Chi tiết bài viết + báo cáo -----
  'social.reportSpam': {'vi': 'Spam / quảng cáo', 'en': 'Spam / advertising', 'zh': '垃圾信息 / 广告'},
  'social.reportHarassment': {'vi': 'Quấy rối', 'en': 'Harassment', 'zh': '骚扰'},
  'social.reportNudity': {'vi': 'Phản cảm', 'en': 'Nudity', 'zh': '色情内容'},
  'social.reportViolence': {'vi': 'Bạo lực', 'en': 'Violence', 'zh': '暴力'},
  'social.reportMisinfo': {'vi': 'Sai sự thật', 'en': 'Misinformation', 'zh': '虚假信息'},
  'social.reportOther': {'vi': 'Khác', 'en': 'Other', 'zh': '其他'},
  'social.reportPost': {'vi': 'Báo cáo bài viết', 'en': 'Report post', 'zh': '举报帖子'},
  'social.reportSent': {'vi': 'Đã gửi báo cáo. Cảm ơn bạn.', 'en': 'Report sent. Thank you.', 'zh': '举报已发送，谢谢。'},
  'social.report': {'vi': 'Báo cáo', 'en': 'Report', 'zh': '举报'},
  'social.repost': {'vi': 'Đăng lại', 'en': 'Repost', 'zh': '转发'},
  'social.repostOn': {'vi': 'Đã đăng lại bài viết', 'en': 'Post reposted', 'zh': '已转发帖子'},
  'social.repostOff': {'vi': 'Đã bỏ đăng lại', 'en': 'Repost removed', 'zh': '已取消转发'},
  'social.shareViaDm': {'vi': 'Chia sẻ qua tin nhắn', 'en': 'Share via message', 'zh': '通过私信分享'},
  'social.shareTo': {'vi': 'Chia sẻ tới…', 'en': 'Share to…', 'zh': '分享到…'},
  'social.sharedViaDm': {'vi': 'Đã chia sẻ qua tin nhắn', 'en': 'Shared via message', 'zh': '已通过私信分享'},
  'social.savePost': {'vi': 'Lưu bài', 'en': 'Save post', 'zh': '收藏帖子'},
  'social.deleteMyPost': {'vi': 'Xoá bài (của tôi)', 'en': 'Delete post (mine)', 'zh': '删除帖子（我的）'},
  'social.deletePostTitle': {'vi': 'Xoá bài viết?', 'en': 'Delete post?', 'zh': '删除帖子？'},
  'social.deletePostBody': {
    'vi': 'Bài viết sẽ bị gỡ khỏi cộng đồng. Hành động này không thể hoàn tác.',
    'en': 'The post will be removed from the community. This action cannot be undone.',
    'zh': '帖子将从社区中移除，此操作无法撤销。'
  },
  'social.postDeleted': {'vi': 'Đã xoá bài viết', 'en': 'Post deleted', 'zh': '帖子已删除'},
  'social.deletePostDenied': {
    'vi': 'Không xoá được: bạn chỉ xoá được bài của mình.',
    'en': 'Cannot delete: you can only delete your own posts.',
    'zh': '无法删除：只能删除自己的帖子。'
  },
  'social.noConversations': {
    'vi': 'Bạn chưa có cuộc trò chuyện nào. Hãy nhắn tin cho ai đó trước.',
    'en': 'You have no conversations yet. Message someone first.',
    'zh': '你还没有对话，先给别人发条消息吧。'
  },
  'social.comments': {'vi': 'Bình luận', 'en': 'Comments', 'zh': '评论'},
  'social.noComments': {'vi': 'Chưa có bình luận', 'en': 'No comments yet', 'zh': '暂无评论'},
  'social.noCommentsMsg': {'vi': 'Hãy là người bình luận đầu tiên!', 'en': 'Be the first to comment!', 'zh': '来抢沙发吧！'},
  'social.deleteMyComment': {'vi': 'Xoá bình luận (của tôi)', 'en': 'Delete comment (mine)', 'zh': '删除评论（我的）'},
  'social.commentDeleted': {'vi': 'Đã xoá bình luận', 'en': 'Comment deleted', 'zh': '评论已删除'},
  'social.deleteCommentDenied': {
    'vi': 'Chỉ xoá được bình luận của mình.',
    'en': 'You can only delete your own comments.',
    'zh': '只能删除自己的评论。'
  },
  'social.reply': {'vi': 'Trả lời', 'en': 'Reply', 'zh': '回复'},
  'social.replyingTo': {'vi': 'Đang trả lời {name}', 'en': 'Replying to {name}', 'zh': '正在回复 {name}'},
  'social.aComment': {'vi': 'bình luận', 'en': 'a comment', 'zh': '评论'},
  'social.writeReply': {'vi': 'Viết câu trả lời…', 'en': 'Write a reply…', 'zh': '写回复…'},
  'social.writeComment': {'vi': 'Viết bình luận…', 'en': 'Write a comment…', 'zh': '写评论…'},

  // ----- Soạn bài -----
  'social.composeEmpty': {
    'vi': 'Nhập nội dung hoặc thêm ảnh/video',
    'en': 'Enter content or add a photo/video',
    'zh': '请输入内容或添加图片/视频'
  },
  'social.posted': {'vi': 'Đã đăng bài', 'en': 'Posted', 'zh': '已发布'},
  'social.postFailed': {'vi': 'Không đăng được: {err}', 'en': 'Post failed: {err}', 'zh': '发布失败：{err}'},
  'social.compose': {'vi': 'Đăng bài', 'en': 'New post', 'zh': '发帖'},
  'social.publish': {'vi': 'Đăng', 'en': 'Post', 'zh': '发布'},
  'social.composeHint': {
    'vi': 'Chia sẻ trải nghiệm du lịch của bạn… (dùng #hashtag để gắn thẻ)',
    'en': 'Share your travel experience… (use #hashtag to tag)',
    'zh': '分享你的旅行体验…（用 #话题 添加标签）'
  },
  'social.addPhoto': {'vi': 'Thêm ảnh', 'en': 'Add photos', 'zh': '添加图片'},
  'social.addVideo': {'vi': 'Thêm video', 'en': 'Add video', 'zh': '添加视频'},
  'social.changeVideo': {'vi': 'Đổi video', 'en': 'Change video', 'zh': '更换视频'},
  'social.videoSelected': {'vi': 'Video đã chọn', 'en': 'Selected video', 'zh': '已选视频'},
  'social.removeVideo': {'vi': 'Bỏ video', 'en': 'Remove video', 'zh': '移除视频'},
  'social.tagHotel': {'vi': 'Gắn thẻ khách sạn (tuỳ chọn)', 'en': 'Tag a hotel (optional)', 'zh': '标记酒店（可选）'},
  'social.tagHotelHint': {'vi': 'Tên khách sạn hoặc thành phố', 'en': 'Hotel name or city', 'zh': '酒店名称或城市'},
  'social.checkinTitle': {'vi': 'Check-in tại khách sạn', 'en': 'Check in at the hotel', 'zh': '在酒店签到'},
  'social.checkinSub': {
    'vi': 'Hiển thị đang có mặt tại nơi được gắn thẻ',
    'en': "Show that you're at the tagged place",
    'zh': '显示你在标记的地点'
  },
  'social.visibility': {'vi': 'Quyền xem', 'en': 'Visibility', 'zh': '可见范围'},
  'social.visPublic': {'vi': 'Công khai', 'en': 'Public', 'zh': '公开'},
  'social.visPrivate': {'vi': 'Chỉ mình tôi', 'en': 'Only me', 'zh': '仅自己'},
  'social.postAs': {'vi': 'Đăng như', 'en': 'Post as', 'zh': '以身份发布'},
  'social.postAsMe': {'vi': 'Tôi', 'en': 'Me', 'zh': '我'},

  // ----- Trang cá nhân -----
  'social.coverUpdated': {'vi': 'Đã cập nhật ảnh bìa', 'en': 'Cover photo updated', 'zh': '封面已更新'},
  'social.avatarUpdated': {'vi': 'Đã cập nhật ảnh đại diện', 'en': 'Profile photo updated', 'zh': '头像已更新'},
  'social.profileUpdated': {'vi': 'Đã cập nhật hồ sơ', 'en': 'Profile updated', 'zh': '资料已更新'},
  'social.errorWith': {'vi': 'Lỗi: {err}', 'en': 'Error: {err}', 'zh': '错误：{err}'},
  'social.dmOpenFailed': {'vi': 'Không mở được tin nhắn.', 'en': 'Could not open messages.', 'zh': '无法打开消息。'},
  'social.editProfile': {'vi': 'Chỉnh sửa hồ sơ', 'en': 'Edit profile', 'zh': '编辑资料'},
  'social.displayName': {'vi': 'Tên hiển thị', 'en': 'Display name', 'zh': '显示名称'},
  'social.handle': {'vi': 'Tên người dùng (@handle)', 'en': 'Username (@handle)', 'zh': '用户名（@handle）'},
  'social.handleHelp': {
    'vi': 'Chỉ chữ thường, số, gạch dưới (3–30)',
    'en': 'Lowercase letters, numbers, underscore only (3–30)',
    'zh': '仅限小写字母、数字、下划线（3–30）'
  },
  'social.bio': {'vi': 'Tiểu sử', 'en': 'Bio', 'zh': '简介'},
  'social.privateAccount': {'vi': 'Tài khoản riêng tư', 'en': 'Private account', 'zh': '私密账户'},
  'social.privateAccountSub': {
    'vi': 'Chỉ người được duyệt mới xem bài',
    'en': 'Only approved followers can see posts',
    'zh': '仅通过审批的人可查看帖子'
  },
  'social.followRequests': {'vi': 'Yêu cầu theo dõi', 'en': 'Follow requests', 'zh': '关注请求'},
  'social.followers': {'vi': 'Người theo dõi', 'en': 'Followers', 'zh': '粉丝'},
  'social.following': {'vi': 'Đang theo dõi', 'en': 'Following', 'zh': '已关注'},
  'social.requested': {'vi': 'Đã yêu cầu', 'en': 'Requested', 'zh': '已请求'},
  'social.follow': {'vi': 'Theo dõi', 'en': 'Follow', 'zh': '关注'},
  'social.message': {'vi': 'Nhắn tin', 'en': 'Message', 'zh': '发消息'},
  'social.postWithPhoto': {'vi': '(Bài viết có ảnh)', 'en': '(Post with photo)', 'zh': '（含图片的帖子）'},
  'social.likesComments': {
    'vi': '{likes} thích · {comments} bình luận',
    'en': '{likes} likes · {comments} comments',
    'zh': '{likes} 赞 · {comments} 评论'
  },

  // ----- Tìm kiếm -----
  'social.searchHint': {
    'vi': 'Tìm người dùng, hashtag, bài viết…',
    'en': 'Search users, hashtags, posts…',
    'zh': '搜索用户、话题、帖子…'
  },
  'social.suggestFollow': {'vi': 'Gợi ý theo dõi', 'en': 'Suggested to follow', 'zh': '推荐关注'},
  'social.noSuggest': {'vi': 'Chưa có gợi ý', 'en': 'No suggestions yet', 'zh': '暂无推荐'},
  'social.noSuggestMsg': {
    'vi': 'Hãy tìm kiếm để khám phá thêm người dùng.',
    'en': 'Search to discover more people.',
    'zh': '搜索以发现更多用户。'
  },
  'social.noResults': {'vi': 'Không tìm thấy kết quả', 'en': 'No results found', 'zh': '未找到结果'},
  'social.noResultsMsg': {
    'vi': 'Thử từ khoá khác hoặc kiểm tra chính tả.',
    'en': 'Try another keyword or check spelling.',
    'zh': '换个关键词或检查拼写。'
  },
  'social.users': {'vi': 'Người dùng', 'en': 'Users', 'zh': '用户'},
  'social.hashtags': {'vi': 'Hashtag', 'en': 'Hashtags', 'zh': '话题'},
  'social.view': {'vi': 'Xem', 'en': 'View', 'zh': '查看'},
  'social.noContent': {'vi': '(Không có nội dung)', 'en': '(No content)', 'zh': '（无内容）'},
  'social.searchFailed': {'vi': 'Không tìm được: {err}', 'en': 'Search failed: {err}', 'zh': '搜索失败：{err}'},

  // ----- Cộng đồng khách sạn -----
  'social.hotelCommunity': {'vi': 'Cộng đồng khách sạn', 'en': 'Hotel community', 'zh': '酒店社区'},
  'social.noHotelPostsMsg': {
    'vi': 'Chưa có bài viết nào về khách sạn này.',
    'en': 'No posts about this hotel yet.',
    'zh': '暂无关于此酒店的帖子。'
  },

  // ----- Yêu cầu theo dõi -----
  'social.noRequests': {'vi': 'Không có yêu cầu', 'en': 'No requests', 'zh': '没有请求'},
  'social.noRequestsMsg': {
    'vi': 'Không có yêu cầu theo dõi nào đang chờ.',
    'en': 'No pending follow requests.',
    'zh': '没有待处理的关注请求。'
  },
  'social.accepted': {'vi': 'Đã chấp nhận', 'en': 'Accepted', 'zh': '已接受'},
  'social.rejected': {'vi': 'Đã từ chối', 'en': 'Rejected', 'zh': '已拒绝'},
  'social.accept': {'vi': 'Chấp nhận', 'en': 'Accept', 'zh': '接受'},
  'social.reject': {'vi': 'Từ chối', 'en': 'Reject', 'zh': '拒绝'},

  // ----- Hashtag -----
  'social.noHashtagPostsMsg': {
    'vi': 'Chưa có bài viết cho thẻ này.',
    'en': 'No posts for this tag yet.',
    'zh': '此话题暂无帖子。'
  },

  // ----- Bài đã lưu -----
  'social.bookmarks': {'vi': 'Bài đã lưu', 'en': 'Saved posts', 'zh': '已收藏'},
  'social.noBookmarks': {'vi': 'Chưa có bài đã lưu', 'en': 'No saved posts yet', 'zh': '暂无收藏'},
  'social.noBookmarksMsg': {
    'vi': 'Bấm biểu tượng lưu ở bài viết để lưu lại và xem sau.',
    'en': 'Tap the save icon on a post to save it for later.',
    'zh': '点击帖子上的收藏图标以便稍后查看。'
  },

  // ----- Thông báo -----
  'social.notifications': {'vi': 'Thông báo', 'en': 'Notifications', 'zh': '通知'},
  'social.markAllRead': {'vi': 'Đánh dấu đã đọc', 'en': 'Mark all as read', 'zh': '全部标为已读'},
  'social.noNotifs': {'vi': 'Chưa có thông báo', 'en': 'No notifications yet', 'zh': '暂无通知'},
  'social.noNotifsMsg': {
    'vi': 'Các cập nhật về đơn, cộng đồng và tin nhắn sẽ hiện ở đây.',
    'en': 'Updates about bookings, community and messages will appear here.',
    'zh': '关于订单、社区和消息的更新会显示在这里。'
  },
  'social.viewPost': {'vi': 'Xem bài viết', 'en': 'View post', 'zh': '查看帖子'},

  // ----- Tin nhắn (DM) -----
  'dm.newMessage': {'vi': 'Nhắn tin mới', 'en': 'New message', 'zh': '新消息'},
  'dm.noPeople': {'vi': 'Chưa có người để nhắn.', 'en': 'No one to message yet.', 'zh': '暂无可发消息的人。'},
  'dm.noMessages': {'vi': 'Chưa có tin nhắn', 'en': 'No messages yet', 'zh': '暂无消息'},
  'dm.noMessagesMsg': {
    'vi': 'Bắt đầu cuộc trò chuyện với người bạn theo dõi.',
    'en': 'Start a conversation with someone you follow.',
    'zh': '与你关注的人开始对话。'
  },
  'dm.startChat': {'vi': 'Bắt đầu cuộc trò chuyện', 'en': 'Start the conversation', 'zh': '开始对话'},
  'dm.startChatMsg': {
    'vi': 'Gửi tin nhắn đầu tiên để mở đầu câu chuyện.',
    'en': 'Send the first message to break the ice.',
    'zh': '发送第一条消息打破僵局。'
  },
  'dm.sendImage': {'vi': 'Gửi ảnh', 'en': 'Send image', 'zh': '发送图片'},
  'dm.messageHint': {'vi': 'Nhắn tin…', 'en': 'Message…', 'zh': '发消息…'},

  // ----- Xoá / lưu trữ cuộc trò chuyện -----
  'dm.archive': {'vi': 'Lưu trữ', 'en': 'Archive', 'zh': '归档'},
  'dm.unarchive': {'vi': 'Bỏ lưu trữ', 'en': 'Unarchive', 'zh': '取消归档'},
  'dm.archived': {'vi': 'Lưu trữ', 'en': 'Archived', 'zh': '已归档'},
  'dm.archivedDone': {'vi': 'Đã chuyển vào mục Lưu trữ.', 'en': 'Moved to Archived.', 'zh': '已移入归档。'},
  'dm.unarchivedDone': {'vi': 'Đã đưa lại về hộp thư.', 'en': 'Moved back to your inbox.', 'zh': '已移回收件箱。'},
  'dm.deletedDone': {
    'vi': 'Đã xoá cuộc trò chuyện khỏi hộp thư của bạn.',
    'en': 'The conversation was removed from your inbox.',
    'zh': '已从你的收件箱删除该会话。'
  },
  'dm.emptyArchived': {'vi': 'Chưa có gì trong Lưu trữ', 'en': 'Nothing archived', 'zh': '归档中暂无内容'},
  'dm.emptyArchivedMsg': {
    'vi': 'Nhấn giữ một cuộc trò chuyện ở hộp thư để cất vào đây.',
    'en': 'Long-press a conversation in your inbox to move it here.',
    'zh': '在收件箱长按会话即可移到这里。'
  },
  'dm.delete': {'vi': 'Xoá cuộc trò chuyện', 'en': 'Delete conversation', 'zh': '删除会话'},
  'dm.deleteConfirm': {
    'vi': 'Xoá cuộc trò chuyện này khỏi hộp thư của bạn? Người kia vẫn giữ lịch sử của họ.',
    'en': 'Delete this conversation from your inbox? The other person keeps their own copy.',
    'zh': '从你的收件箱删除此会话？对方仍保留自己的记录。'
  },
  'dm.deleteGroupConfirm': {
    'vi': 'Ẩn nhóm này khỏi hộp thư của bạn? Có tin nhắn mới thì nhóm sẽ quay lại.',
    'en': 'Hide this group from your inbox? It comes back when there is a new message.',
    'zh': '把该群从收件箱隐藏？有新消息时会自动回来。'
  },

  // ----- Nhóm chat -----
  'dm.newGroup': {'vi': 'Tạo nhóm chat', 'en': 'New group chat', 'zh': '新建群聊'},
  'dm.createGroup': {'vi': 'Tạo nhóm', 'en': 'Create group', 'zh': '创建群聊'},
  'dm.groupName': {'vi': 'Tên nhóm', 'en': 'Group name', 'zh': '群名称'},
  'dm.groupNamePh': {'vi': 'Ví dụ: Đà Nẵng tháng 9', 'en': 'e.g. Da Nang in September', 'zh': '例如：九月岘港'},
  'dm.needGroupName': {'vi': 'Vui lòng đặt tên nhóm', 'en': 'Please name the group', 'zh': '请填写群名称'},
  'dm.groupInfo': {'vi': 'Thông tin nhóm', 'en': 'Group info', 'zh': '群信息'},
  'dm.owner': {'vi': 'Chủ nhóm', 'en': 'Owner', 'zh': '群主'},
  'dm.rename': {'vi': 'Đổi tên', 'en': 'Rename', 'zh': '重命名'},
  'dm.renamed': {'vi': 'Đã đổi tên nhóm.', 'en': 'Group renamed.', 'zh': '群名称已更新。'},
  'dm.addMember': {'vi': 'Thêm thành viên', 'en': 'Add members', 'zh': '添加成员'},
  'dm.addHint': {
    'vi': 'Thành viên nào cũng mời thêm được, nhưng chỉ mời được người theo dõi qua lại.',
    'en': 'Any member can invite more people, but only those who follow each other.',
    'zh': '群内任何成员都可以邀请他人，但只能邀请互相关注的人。'
  },
  'dm.removeConfirm': {'vi': 'Xoá người này khỏi nhóm?', 'en': 'Remove this person from the group?', 'zh': '将该成员移出群聊？'},
  'dm.leave': {'vi': 'Rời nhóm', 'en': 'Leave group', 'zh': '退出群聊'},
  'dm.leaveConfirm': {
    'vi': 'Rời khỏi nhóm này? Bạn sẽ không nhận được tin nhắn mới nữa.',
    'en': 'Leave this group? You will stop receiving its messages.',
    'zh': '退出该群聊？你将不再收到群消息。'
  },
  'dm.searchPeople': {'vi': 'Tìm theo tên hoặc @handle…', 'en': 'Search by name or @handle…', 'zh': '按名字或 @handle 搜索…'},
  'dm.mutualOnly': {
    'vi': 'Chỉ hiện những người theo dõi qua lại với bạn — tránh kéo người lạ vào nhóm.',
    'en': 'Only people who follow you back are listed — so nobody drags in a stranger.',
    'zh': '仅显示与你互相关注的人——避免把陌生人拉进群。'
  },
  'dm.noMutual': {'vi': 'Chưa có ai để mời', 'en': 'No one to invite', 'zh': '暂无可邀请的人'},
  'dm.noMutualMsg': {
    'vi': 'Chỉ mời được người theo dõi qua lại với bạn. Hãy theo dõi nhau trước đã.',
    'en': 'You can only invite people who follow you back. Follow each other first.',
    'zh': '只能邀请与你互相关注的人，请先互相关注。'
  },
  'dm.pickOne': {'vi': 'Hãy chọn ít nhất một người.', 'en': 'Please pick at least one person.', 'zh': '请至少选择一个人。'},
};
