/// Chuỗi i18n nhóm Tài khoản/Auth/Hồ sơ/Loyalty/Nhóm/Công ty/Hỗ trợ/Vendor. vi/en/zh.
const accountStrings = <String, Map<String, String>>{
  // ---------------- Dùng chung trong nhóm này ----------------
  'account.errorWith': {'vi': 'Lỗi: {v}', 'en': 'Error: {v}', 'zh': '错误：{v}'},

  // ---------------- Chế độ khách (guest browsing) ----------------
  'auth.continueGuest': {
    'vi': 'Tiếp tục không cần đăng nhập',
    'en': 'Continue without signing in',
    'zh': '暂不登录，继续浏览'
  },
  'auth.guestCommunityTitle': {
    'vi': 'Tham gia cộng đồng du lịch',
    'en': 'Join the travel community',
    'zh': '加入旅行社区'
  },
  'auth.guestCommunityMsg': {
    'vi': 'Đăng nhập để xem bài viết, chia sẻ trải nghiệm và nhắn tin với mọi người.',
    'en': 'Sign in to view posts, share experiences and message others.',
    'zh': '登录后即可查看帖子、分享体验并与大家聊天。'
  },
  'auth.guestOrdersTitle': {
    'vi': 'Quản lý đơn của bạn',
    'en': 'Manage your bookings',
    'zh': '管理您的订单'
  },
  'auth.guestOrdersMsg': {
    'vi': 'Đăng nhập để xem và quản lý đơn đặt phòng, vé máy bay của bạn.',
    'en': 'Sign in to view and manage your hotel and flight bookings.',
    'zh': '登录后即可查看和管理您的酒店与机票订单。'
  },
  'auth.guestAccountTitle': {
    'vi': 'Chào mừng đến với Dididi',
    'en': 'Welcome to Dididi',
    'zh': '欢迎来到 Dididi'
  },
  'auth.guestAccountMsg': {
    'vi': 'Đăng nhập hoặc tạo tài khoản để đặt phòng, tích điểm và nhận ưu đãi.',
    'en': 'Sign in or create an account to book, earn points and get deals.',
    'zh': '登录或注册即可预订、积分并获取优惠。'
  },
  'auth.loginToSave': {
    'vi': 'Đăng nhập để lưu khách sạn yêu thích',
    'en': 'Sign in to save favourite hotels',
    'zh': '登录后即可收藏喜欢的酒店'
  },

  // ---------------- Tài khoản (account.*) ----------------
  'account.profileSub': {
    'vi': 'Họ tên, số điện thoại, đổi mật khẩu',
    'en': 'Name, phone, change password',
    'zh': '姓名、电话、修改密码'
  },
  'account.supportSub': {
    'vi': 'Huỷ đơn, hoàn tiền, đổi lịch, thanh toán…',
    'en': 'Cancel, refund, reschedule, payment…',
    'zh': '取消、退款、改期、支付…'
  },
  'account.bookmarks': {'vi': 'Bài đã lưu', 'en': 'Saved posts', 'zh': '已保存帖子'},
  'account.bookmarksSub': {
    'vi': 'Bài viết cộng đồng bạn đã lưu',
    'en': 'Community posts you saved',
    'zh': '你收藏的社区帖子'
  },
  'account.groupsSub': {
    'vi': 'Đặt phòng theo nhóm, chia tiền',
    'en': 'Group booking, split bills',
    'zh': '团体预订，分摊费用'
  },
  'account.companySub': {
    'vi': 'Ngân sách B2B, nhận lời mời công ty',
    'en': 'B2B budget, accept company invites',
    'zh': 'B2B 预算，接受公司邀请'
  },
  'account.terms': {'vi': 'Điều khoản sử dụng', 'en': 'Terms of use', 'zh': '使用条款'},
  'account.privacy': {'vi': 'Chính sách bảo mật', 'en': 'Privacy policy', 'zh': '隐私政策'},
  'account.devicesSub': {
    'vi': 'Xem các phiên & đăng xuất từng thiết bị',
    'en': 'View sessions & sign out each device',
    'zh': '查看会话并逐个登出设备'
  },

  // ---------------- Hồ sơ (profile.*) ----------------
  'profile.title': {'vi': 'Hồ sơ của tôi', 'en': 'My profile', 'zh': '我的资料'},
  'profile.noName': {'vi': 'Chưa đặt tên', 'en': 'No name set', 'zh': '未设置姓名'},
  'profile.personalInfo': {'vi': 'Thông tin cá nhân', 'en': 'Personal information', 'zh': '个人信息'},
  'profile.phoneNone': {'vi': 'Chưa có', 'en': 'Not set', 'zh': '未填写'},
  'profile.birthDate': {'vi': 'Ngày sinh', 'en': 'Date of birth', 'zh': '出生日期'},
  'profile.birthDateNone': {
    'vi': 'Chưa có — thêm để nhận quà sinh nhật',
    'en': 'Not set — add it to get a birthday gift',
    'zh': '未填写 — 填写可获生日礼遇'
  },
  'profile.birthDateSaved': {
    'vi': 'Đã lưu ngày sinh.',
    'en': 'Date of birth saved.',
    'zh': '出生日期已保存。'
  },
  'profile.verified': {'vi': 'Đã xác thực', 'en': 'Verified', 'zh': '已验证'},
  'profile.unverified': {'vi': 'Chưa xác thực', 'en': 'Not verified', 'zh': '未验证'},
  'profile.notActivated': {'vi': 'Chưa kích hoạt', 'en': 'Not activated', 'zh': '未激活'},
  'profile.security': {'vi': 'Bảo mật', 'en': 'Security', 'zh': '安全'},
  'profile.changePassword': {'vi': 'Đổi mật khẩu', 'en': 'Change password', 'zh': '修改密码'},
  'profile.changePasswordSub': {
    'vi': 'Đổi mật khẩu sẽ đăng xuất các phiên khác',
    'en': 'Changing password signs out other sessions',
    'zh': '修改密码将登出其他会话'
  },
  'profile.resendActivation': {'vi': 'Gửi lại email kích hoạt', 'en': 'Resend activation email', 'zh': '重新发送激活邮件'},
  'profile.accountNotActivated': {'vi': 'Tài khoản chưa kích hoạt', 'en': 'Account not activated', 'zh': '账户未激活'},
  'profile.unlinkGoogle': {'vi': 'Huỷ liên kết Google', 'en': 'Unlink Google', 'zh': '解绑 Google'},
  'profile.unlinkGoogleSub': {
    'vi': 'Gỡ đăng nhập bằng Google khỏi tài khoản',
    'en': 'Remove Google sign-in from your account',
    'zh': '从账户移除 Google 登录'
  },
  'profile.dangerZone': {'vi': 'Vùng nguy hiểm', 'en': 'Danger zone', 'zh': '危险操作'},
  'profile.closeAccount': {'vi': 'Đóng tài khoản', 'en': 'Close account', 'zh': '注销账户'},
  'profile.closeAccountSub': {
    'vi': 'Khoá vĩnh viễn tài khoản của bạn',
    'en': 'Permanently lock your account',
    'zh': '永久锁定你的账户'
  },
  'profile.resendActivationDone': {
    'vi': 'Đã gửi lại email kích hoạt.',
    'en': 'Activation email resent.',
    'zh': '已重新发送激活邮件。'
  },
  'profile.unlinkGoogleConfirm': {'vi': 'Huỷ liên kết Google?', 'en': 'Unlink Google?', 'zh': '解绑 Google？'},
  'profile.unlinkGoogleBody': {
    'vi': 'Bạn sẽ không thể đăng nhập bằng Google nữa. Hãy chắc chắn bạn đã đặt mật khẩu.',
    'en': 'You will no longer be able to sign in with Google. Make sure you have set a password.',
    'zh': '你将无法再使用 Google 登录。请确保已设置密码。'
  },
  'profile.unlink': {'vi': 'Huỷ liên kết', 'en': 'Unlink', 'zh': '解绑'},
  'profile.unlinkGoogleDone': {'vi': 'Đã huỷ liên kết Google.', 'en': 'Google unlinked.', 'zh': '已解绑 Google。'},
  'profile.closeAccountConfirm': {'vi': 'Đóng tài khoản?', 'en': 'Close account?', 'zh': '注销账户？'},
  'profile.closeAccountBody': {
    'vi': 'Hành động này sẽ khoá tài khoản của bạn. Nhập mật khẩu để xác nhận.',
    'en': 'This will lock your account. Enter your password to confirm.',
    'zh': '此操作将锁定你的账户。请输入密码确认。'
  },
  'profile.editName': {'vi': 'Cập nhật họ tên', 'en': 'Update name', 'zh': '更新姓名'},
  'profile.nameUpdated': {'vi': 'Đã cập nhật họ tên.', 'en': 'Name updated.', 'zh': '姓名已更新。'},
  'profile.otpCode': {'vi': 'Mã OTP', 'en': 'OTP code', 'zh': '验证码'},
  'profile.otpSent': {'vi': 'Đã gửi mã OTP.', 'en': 'OTP code sent.', 'zh': '验证码已发送。'},
  'profile.phoneVerified': {'vi': 'Đã xác thực số điện thoại.', 'en': 'Phone number verified.', 'zh': '电话号码已验证。'},
  'profile.currentPassword': {'vi': 'Mật khẩu hiện tại', 'en': 'Current password', 'zh': '当前密码'},
  'profile.newPassword': {'vi': 'Mật khẩu mới', 'en': 'New password', 'zh': '新密码'},
  'profile.passwordHint': {
    'vi': 'Tối thiểu 8 ký tự, gồm chữ và số',
    'en': 'At least 8 characters, letters and numbers',
    'zh': '至少 8 位，包含字母和数字'
  },
  'profile.confirmNewPassword': {'vi': 'Xác nhận mật khẩu mới', 'en': 'Confirm new password', 'zh': '确认新密码'},
  'profile.change': {'vi': 'Đổi', 'en': 'Change', 'zh': '修改'},
  'profile.passwordMismatch': {
    'vi': 'Mật khẩu xác nhận không khớp.',
    'en': 'Password confirmation does not match.',
    'zh': '确认密码不一致。'
  },
  'profile.passwordChanged': {'vi': 'Đã đổi mật khẩu.', 'en': 'Password changed.', 'zh': '密码已修改。'},

  // ---------------- Thiết bị/phiên (session.*) ----------------
  'session.devices': {'vi': 'Thiết bị đăng nhập', 'en': 'Logged-in devices', 'zh': '登录设备'},
  'session.all': {'vi': 'Tất cả', 'en': 'All', 'zh': '全部'},
  'session.empty': {'vi': 'Không có phiên nào', 'en': 'No sessions', 'zh': '暂无会话'},
  'session.emptySub': {
    'vi': 'Chưa ghi nhận thiết bị đăng nhập nào.',
    'en': 'No login devices recorded yet.',
    'zh': '尚未记录任何登录设备。'
  },
  'session.loginAt': {'vi': 'Đăng nhập: {v}', 'en': 'Signed in: {v}', 'zh': '登录时间：{v}'},
  'session.current': {'vi': 'Hiện tại', 'en': 'Current', 'zh': '当前'},
  'session.signOut': {'vi': 'Đăng xuất', 'en': 'Sign out', 'zh': '登出'},
  'session.logoutAllConfirm': {'vi': 'Đăng xuất tất cả thiết bị?', 'en': 'Sign out all devices?', 'zh': '登出所有设备？'},
  'session.logoutAllBody': {
    'vi': 'Mọi phiên đăng nhập trên tất cả thiết bị (kể cả thiết bị này) sẽ bị thu hồi. Bạn sẽ cần đăng nhập lại.',
    'en': 'All sessions on every device (including this one) will be revoked. You will need to sign in again.',
    'zh': '所有设备（包括本设备）上的会话都将被撤销。你需要重新登录。'
  },
  'session.logoutAll': {'vi': 'Đăng xuất tất cả', 'en': 'Sign out all', 'zh': '全部登出'},
  'session.revokeConfirm': {'vi': 'Đăng xuất thiết bị?', 'en': 'Sign out this device?', 'zh': '登出此设备？'},
  'session.revokeBody': {
    'vi': 'Thu hồi phiên đăng nhập trên "{v}"? Thiết bị đó sẽ phải đăng nhập lại.',
    'en': 'Revoke the session on "{v}"? That device will need to sign in again.',
    'zh': '撤销“{v}”上的会话？该设备需要重新登录。'
  },
  'session.revoked': {'vi': 'Đã đăng xuất thiết bị.', 'en': 'Device signed out.', 'zh': '设备已登出。'},
  'session.revokeFailed': {
    'vi': 'Không thu hồi được phiên, thử lại sau.',
    'en': 'Could not revoke session, try again later.',
    'zh': '无法撤销会话，请稍后再试。'
  },

  // ---------------- Auth (auth.*) ----------------
  'auth.login': {'vi': 'Đăng nhập', 'en': 'Log in', 'zh': '登录'},
  'auth.register': {'vi': 'Đăng ký', 'en': 'Sign up', 'zh': '注册'},
  'auth.sendCode': {'vi': 'Gửi mã', 'en': 'Send code', 'zh': '发送验证码'},
  'auth.or': {'vi': 'hoặc', 'en': 'or', 'zh': '或'},
  'auth.noServer': {
    'vi': 'Không kết nối được máy chủ. Kiểm tra backend đang chạy?',
    'en': 'Cannot reach the server. Is the backend running?',
    'zh': '无法连接服务器。后端是否正在运行？'
  },
  'auth.noServerShort': {'vi': 'Không kết nối được máy chủ', 'en': 'Cannot reach the server', 'zh': '无法连接服务器'},
  'auth.googleNoToken': {
    'vi': 'Không lấy được Google ID token. Kiểm tra cấu hình OAuth Client ID.',
    'en': 'Could not get Google ID token. Check OAuth Client ID configuration.',
    'zh': '无法获取 Google ID 令牌。请检查 OAuth 客户端 ID 配置。'
  },
  'auth.googleLoginFailed': {'vi': 'Đăng nhập Google thất bại: {v}', 'en': 'Google sign-in failed: {v}', 'zh': 'Google 登录失败：{v}'},
  'auth.googleRegisterFailed': {'vi': 'Đăng ký Google thất bại: {v}', 'en': 'Google sign-up failed: {v}', 'zh': 'Google 注册失败：{v}'},
  'auth.otpLoginTitle': {'vi': 'Đăng nhập bằng OTP email', 'en': 'Sign in with email OTP', 'zh': '使用邮箱验证码登录'},
  'auth.otpInEmail': {'vi': 'Mã OTP (trong email)', 'en': 'OTP code (in email)', 'zh': '验证码（邮件中）'},
  'auth.otpSentIfValid': {
    'vi': 'Nếu email hợp lệ, mã OTP đã được gửi.',
    'en': 'If the email is valid, an OTP code has been sent.',
    'zh': '如果邮箱有效，验证码已发送。'
  },
  'auth.loginGoogle': {'vi': 'Đăng nhập với Google', 'en': 'Sign in with Google', 'zh': '使用 Google 登录'},
  'auth.loginOtp': {'vi': 'Đăng nhập bằng mã OTP (email)', 'en': 'Sign in with OTP (email)', 'zh': '使用验证码登录（邮箱）'},
  'auth.forgotPassword': {'vi': 'Quên mật khẩu?', 'en': 'Forgot password?', 'zh': '忘记密码？'},
  'auth.noAccountRegister': {
    'vi': 'Chưa có tài khoản? Đăng ký',
    'en': 'Don\'t have an account? Sign up',
    'zh': '还没有账户？注册'
  },
  'auth.becomeVendor': {
    'vi': 'Đăng ký làm nhà cung cấp (bán phòng)',
    'en': 'Register as a vendor (sell rooms)',
    'zh': '注册成为供应商（出售房间）'
  },
  'auth.passwordMin8': {'vi': 'Mật khẩu tối thiểu 8 ký tự', 'en': 'Password must be at least 8 characters', 'zh': '密码至少 8 位'},
  'auth.registerSuccess': {
    'vi': 'Đăng ký thành công! Kiểm tra email để kích hoạt tài khoản.',
    'en': 'Sign-up successful! Check your email to activate your account.',
    'zh': '注册成功！请查收邮件激活账户。'
  },
  'auth.createAccount': {'vi': 'Tạo tài khoản Dididi', 'en': 'Create a Dididi account', 'zh': '创建 Dididi 账户'},
  'auth.registerSub': {
    'vi': 'Đăng ký để đặt phòng, săn ưu đãi và tích điểm thưởng.',
    'en': 'Sign up to book rooms, catch deals and earn reward points.',
    'zh': '注册以预订房间、抢优惠并赚取积分。'
  },
  'auth.passwordMin8Label': {
    'vi': 'Mật khẩu (tối thiểu 8 ký tự)',
    'en': 'Password (at least 8 characters)',
    'zh': '密码（至少 8 位）'
  },
  'auth.createAccountBtn': {'vi': 'Tạo tài khoản', 'en': 'Create account', 'zh': '创建账户'},
  'auth.registerGoogle': {'vi': 'Đăng ký với Google', 'en': 'Sign up with Google', 'zh': '使用 Google 注册'},
  'auth.enterEmail': {'vi': 'Vui lòng nhập email', 'en': 'Please enter your email', 'zh': '请输入邮箱'},
  'auth.resetSent': {
    'vi': 'Đã gửi hướng dẫn đặt lại tới email (nếu tồn tại). Nhập token trong email bên dưới.',
    'en': 'Reset instructions sent to your email (if it exists). Enter the token from the email below.',
    'zh': '重置说明已发送至邮箱（若存在）。请在下方输入邮件中的令牌。'
  },
  'auth.enterToken': {'vi': 'Nhập token trong email', 'en': 'Enter the token from the email', 'zh': '请输入邮件中的令牌'},
  'auth.newPasswordMin8': {
    'vi': 'Mật khẩu mới tối thiểu 8 ký tự',
    'en': 'New password must be at least 8 characters',
    'zh': '新密码至少 8 位'
  },
  'auth.resetSuccess': {
    'vi': 'Đặt lại mật khẩu thành công. Mời đăng nhập.',
    'en': 'Password reset successful. Please log in.',
    'zh': '密码重置成功。请登录。'
  },
  'auth.forgotPasswordTitle': {'vi': 'Quên mật khẩu', 'en': 'Forgot password', 'zh': '忘记密码'},
  'auth.forgotIntro': {
    'vi': 'Nhập email của bạn, chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu.',
    'en': 'Enter your email and we will send password reset instructions.',
    'zh': '输入你的邮箱，我们将发送密码重置说明。'
  },
  'auth.resend': {'vi': 'Gửi lại', 'en': 'Resend', 'zh': '重新发送'},
  'auth.sendResetLink': {'vi': 'Gửi liên kết đặt lại', 'en': 'Send reset link', 'zh': '发送重置链接'},
  'auth.resetPassword': {'vi': 'Đặt lại mật khẩu', 'en': 'Reset password', 'zh': '重置密码'},
  'auth.tokenInEmail': {'vi': 'Token (trong email)', 'en': 'Token (in email)', 'zh': '令牌（邮件中）'},

  // ---------------- Ưu đãi cá nhân hoá (offer.*) ----------------
  'offer.title': {'vi': 'Ưu đãi của tôi', 'en': 'My offers', 'zh': '我的优惠'},
  'offer.accountSub': {
    'vi': 'Voucher tặng riêng cho bạn',
    'en': 'Vouchers gifted just for you',
    'zh': '专属赠送优惠券'
  },
  'offer.emptyTitle': {'vi': 'Chưa có ưu đãi nào', 'en': 'No offers yet', 'zh': '暂无优惠'},
  'offer.emptyMsg': {
    'vi': 'Đặt phòng, tích điểm và cập nhật ngày sinh để nhận ưu đãi riêng nhé.',
    'en': 'Book, earn points and add your birthday to receive personal offers.',
    'zh': '预订、累积积分并填写生日，即可获得专属优惠。'
  },
  'offer.usableTitle': {'vi': 'Đang dùng được', 'en': 'Ready to use', 'zh': '可使用'},
  'offer.usableSub': {'vi': '{n} mã còn hiệu lực', 'en': '{n} valid codes', 'zh': '{n} 张有效'},
  'offer.expiredTitle': {'vi': 'Đã dùng / hết hạn', 'en': 'Used / expired', 'zh': '已用 / 已过期'},
  'offer.unusable': {'vi': 'Không dùng được', 'en': 'Unavailable', 'zh': '不可用'},
  'offer.percentOff': {'vi': 'Giảm {v}%', 'en': '{v}% off', 'zh': '减 {v}%'},
  'offer.amountOff': {'vi': 'Giảm {v}', 'en': '{v} off', 'zh': '减 {v}'},
  'offer.maxCap': {'vi': 'tối đa {v}', 'en': 'up to {v}', 'zh': '最高 {v}'},
  'offer.minOrder': {'vi': 'Đơn từ {v}', 'en': 'Orders from {v}', 'zh': '订单满 {v}'},
  'offer.validTo': {'vi': 'Đến {v}', 'en': 'Until {v}', 'zh': '至 {v}'},
  'offer.copy': {'vi': 'Sao chép', 'en': 'Copy', 'zh': '复制'},
  'offer.copied': {'vi': 'Đã sao chép mã', 'en': 'Code copied', 'zh': '已复制优惠码'},
  'offer.howToUse': {
    'vi': 'Cách dùng: khi thanh toán, dán mã vào ô "Mã giảm giá" rồi bấm Áp.',
    'en': 'How to use: paste the code into the "Discount code" box at checkout, then tap Apply.',
    'zh': '使用方法：结账时把优惠码粘贴到"优惠码"栏并点击应用。'
  },
  'offer.bannerTitle': {
    'vi': 'Bạn có {n} ưu đãi riêng',
    'en': 'You have {n} personal offers',
    'zh': '你有 {n} 张专属优惠'
  },
  'offer.bannerMsg': {
    'vi': 'Xem mã và dùng khi thanh toán.',
    'en': 'View your codes and use them at checkout.',
    'zh': '查看优惠码并在结账时使用。'
  },

  // ---------------- Loyalty (loyalty.*) ----------------
  'loyalty.redeem': {'vi': 'Đổi điểm lấy voucher', 'en': 'Redeem points for voucher', 'zh': '积分兑换优惠券'},
  'loyalty.myVouchers': {'vi': 'Voucher của tôi', 'en': 'My vouchers', 'zh': '我的优惠券'},
  'loyalty.noVouchers': {'vi': 'Chưa có voucher nào.', 'en': 'No vouchers yet.', 'zh': '暂无优惠券。'},
  'loyalty.pointHistory': {'vi': 'Lịch sử điểm', 'en': 'Point history', 'zh': '积分记录'},
  'loyalty.noTxn': {'vi': 'Chưa có giao dịch điểm.', 'en': 'No point transactions yet.', 'zh': '暂无积分交易。'},
  'loyalty.available': {'vi': 'Điểm khả dụng', 'en': 'Available points', 'zh': '可用积分'},
  'loyalty.tier': {'vi': 'Hạng {v}', 'en': '{v} tier', 'zh': '{v} 等级'},
  'loyalty.approxRedeem': {'vi': '≈ {v} khi đổi', 'en': '≈ {v} when redeemed', 'zh': '兑换约 {v}'},
  'loyalty.lifetime': {'vi': 'Tổng tích luỹ: {v} điểm', 'en': 'Total earned: {v} points', 'zh': '累计获得：{v} 积分'},
  'loyalty.discount': {'vi': 'Giảm {v}', 'en': '{v} off', 'zh': '减 {v}'},
  'loyalty.expiry': {'vi': ' · HSD {v}', 'en': ' · Exp {v}', 'zh': ' · 有效期至 {v}'},
  'loyalty.used': {'vi': 'Đã dùng', 'en': 'Used', 'zh': '已使用'},
  'loyalty.valid': {'vi': 'Còn hạn', 'en': 'Valid', 'zh': '有效'},
  'loyalty.balance': {'vi': 'Số dư: {v} điểm', 'en': 'Balance: {v} points', 'zh': '余额：{v} 积分'},
  'loyalty.minRedeem': {
    'vi': 'Tối thiểu {a} điểm · 1 điểm ≈ {b}',
    'en': 'Minimum {a} points · 1 point ≈ {b}',
    'zh': '最低 {a} 积分 · 1 积分 ≈ {b}'
  },
  'loyalty.pointsToRedeem': {'vi': 'Số điểm đổi', 'en': 'Points to redeem', 'zh': '兑换积分数'},
  'loyalty.exchange': {'vi': 'Đổi', 'en': 'Redeem', 'zh': '兑换'},
  'loyalty.redeemed': {'vi': 'Đã đổi! Mã voucher: {v}', 'en': 'Redeemed! Voucher code: {v}', 'zh': '已兑换！优惠券码：{v}'},
  'loyalty.redeemFailed': {'vi': 'Đổi điểm thất bại.', 'en': 'Redemption failed.', 'zh': '兑换失败。'},

  // ---------------- Công ty (company.*) ----------------
  'company.title': {'vi': 'Công ty của tôi', 'en': 'My company', 'zh': '我的公司'},
  'company.enterInvite': {'vi': 'Nhập mã lời mời', 'en': 'Enter invite code', 'zh': '请输入邀请码'},
  'company.joined': {
    'vi': 'Đã tham gia công ty {v}. Giờ bạn có thể thanh toán bằng ngân sách công ty.',
    'en': 'Joined company {v}. You can now pay with the company budget.',
    'zh': '已加入公司 {v}。现在你可以用公司预算支付。'
  },
  'company.inviteInvalid': {
    'vi': 'Mã lời mời không hợp lệ hoặc đã hết hạn.',
    'en': 'Invite code is invalid or expired.',
    'zh': '邀请码无效或已过期。'
  },
  'company.budget': {'vi': 'Ngân sách', 'en': 'Budget', 'zh': '预算'},
  'company.used': {'vi': 'Đã dùng', 'en': 'Used', 'zh': '已使用'},
  'company.remaining': {'vi': 'Còn lại', 'en': 'Remaining', 'zh': '剩余'},
  'company.payHint': {
    'vi': 'Bạn có thể chọn "Thanh toán bằng công ty" ở chi tiết đơn chờ thanh toán.',
    'en': 'You can choose "Pay with company" on the detail of a booking awaiting payment.',
    'zh': '你可以在待支付订单详情中选择“用公司支付”。'
  },
  'company.acceptInvite': {'vi': 'Nhận lời mời công ty', 'en': 'Accept company invite', 'zh': '接受公司邀请'},
  'company.inviteCode': {'vi': 'Mã lời mời', 'en': 'Invite code', 'zh': '邀请码'},
  'company.inviteHint': {
    'vi': 'Dán mã trong email mời của công ty',
    'en': 'Paste the code from your company invite email',
    'zh': '粘贴公司邀请邮件中的代码'
  },
  'company.join': {'vi': 'Tham gia công ty', 'en': 'Join company', 'zh': '加入公司'},
  'company.none': {
    'vi': 'Bạn chưa thuộc công ty nào. Nhập mã lời mời bên dưới để tham gia.',
    'en': 'You are not part of any company. Enter an invite code below to join.',
    'zh': '你还没有加入任何公司。请在下方输入邀请码加入。'
  },

  // ---------------- Nhóm du lịch (group.*) ----------------
  'group.myGroups': {'vi': 'Nhóm của tôi', 'en': 'My groups', 'zh': '我的团'},
  'group.title': {'vi': 'Nhóm', 'en': 'Group', 'zh': '团'},
  'group.share': {'vi': 'Chia sẻ nhóm', 'en': 'Share group', 'zh': '分享团'},
  'group.organizer': {'vi': 'Chủ nhóm', 'en': 'Organizer', 'zh': '团长'},
  'group.memberRole': {'vi': 'Thành viên', 'en': 'Member', 'zh': '成员'},
  'group.closed': {'vi': 'Đã đóng', 'en': 'Closed', 'zh': '已关闭'},
  'group.ended': {'vi': 'Đã kết thúc', 'en': 'Ended', 'zh': '已结束'},
  'group.members': {'vi': 'Thành viên', 'en': 'Members', 'zh': '成员'},
  'group.paid': {'vi': 'Đã trả', 'en': 'Paid', 'zh': '已付'},
  'group.pending': {'vi': 'Chờ trả', 'en': 'Pending', 'zh': '待付'},
  'group.noRooms': {'vi': 'Chưa có ai thêm phòng.', 'en': 'No one has added a room yet.', 'zh': '还没有人添加房间。'},
  'group.joinAddRoom': {'vi': 'Tham gia — thêm phòng của tôi', 'en': 'Join — add my room', 'zh': '加入 — 添加我的房间'},
  'group.payAll': {'vi': 'Thanh toán cả nhóm (VNPay)', 'en': 'Pay for the whole group (VNPay)', 'zh': '为整团支付（VNPay）'},
  'group.manage': {'vi': 'Quản lý (chủ nhóm)', 'en': 'Manage (organizer)', 'zh': '管理（团长）'},
  'group.reopen': {'vi': 'Mở lại nhóm', 'en': 'Reopen group', 'zh': '重新开团'},
  'group.close': {'vi': 'Đóng nhóm', 'en': 'Close group', 'zh': '关闭团'},
  'group.edit': {'vi': 'Sửa nhóm', 'en': 'Edit group', 'zh': '编辑团'},
  'group.reopenTrip': {'vi': 'Mở lại chuyến', 'en': 'Reopen trip', 'zh': '重新开始行程'},
  'group.endTrip': {'vi': 'Kết thúc chuyến', 'en': 'End trip', 'zh': '结束行程'},
  'group.settlement': {'vi': 'Hoá đơn chia tiền (PDF)', 'en': 'Split-bill invoice (PDF)', 'zh': '分账单（PDF）'},
  'group.inviteViaQr': {'vi': 'Mời qua QR / mã: {v}', 'en': 'Invite via QR / code: {v}', 'zh': '通过二维码/代码邀请：{v}'},
  'group.you': {'vi': ' (bạn)', 'en': ' (you)', 'zh': '（你）'},
  'group.roomsAmount': {'vi': '{a} phòng · {b}', 'en': '{a} room(s) · {b}', 'zh': '{a} 间 · {b}'},
  'group.deleteRoomItem': {'vi': 'Xoá phòng này', 'en': 'Delete this room', 'zh': '删除此房间'},
  'group.removeMember': {'vi': 'Xoá thành viên', 'en': 'Remove member', 'zh': '移除成员'},
  'group.inviteTitle': {'vi': 'Mời vào nhóm', 'en': 'Invite to group', 'zh': '邀请加入团'},
  'group.groupCode': {'vi': 'Mã nhóm', 'en': 'Group code', 'zh': '团代码'},
  'group.shareHint': {
    'vi': 'Bạn bè quét QR hoặc nhập mã ở "Nhóm của tôi → Tham gia bằng mã".',
    'en': 'Friends can scan the QR or enter the code in "My groups → Join by code".',
    'zh': '好友可扫描二维码或在“我的团 → 用代码加入”中输入代码。'
  },
  'group.codeCopied': {'vi': 'Đã sao chép mã nhóm.', 'en': 'Group code copied.', 'zh': '已复制团代码。'},
  'group.copyCode': {'vi': 'Sao chép mã', 'en': 'Copy code', 'zh': '复制代码'},
  'group.addMyRoom': {'vi': 'Thêm phòng của tôi', 'en': 'Add my room', 'zh': '添加我的房间'},
  'group.roomType': {'vi': 'Loại phòng', 'en': 'Room type', 'zh': '房型'},
  'group.roomCount': {'vi': 'Số phòng', 'en': 'Rooms', 'zh': '房间数'},
  'group.add': {'vi': 'Thêm', 'en': 'Add', 'zh': '添加'},
  'group.roomAdded': {
    'vi': 'Đã thêm phòng. Vào "Đơn của tôi" để thanh toán phần của bạn.',
    'en': 'Room added. Go to "My bookings" to pay your share.',
    'zh': '已添加房间。前往“我的订单”支付你的部分。'
  },
  'group.addRoomFailed': {
    'vi': 'Không thêm được phòng, thử lại sau.',
    'en': 'Could not add room, try again later.',
    'zh': '无法添加房间，请稍后再试。'
  },
  'group.updated': {'vi': 'Đã cập nhật nhóm', 'en': 'Group updated', 'zh': '团已更新'},
  'group.tripReopened': {'vi': 'Đã mở lại chuyến', 'en': 'Trip reopened', 'zh': '行程已重新开始'},
  'group.tripEnded': {'vi': 'Đã kết thúc chuyến', 'en': 'Trip ended', 'zh': '行程已结束'},
  'group.roomDeleted': {'vi': 'Đã xoá phòng', 'en': 'Room deleted', 'zh': '房间已删除'},
  'group.memberRemoved': {'vi': 'Đã xoá thành viên', 'en': 'Member removed', 'zh': '成员已移除'},
  'group.titleLabel': {'vi': 'Tiêu đề nhóm', 'en': 'Group title', 'zh': '团标题'},
  'group.splitEven': {'vi': 'Chia đều tiền', 'en': 'Split evenly', 'zh': '平均分摊'},
  'group.splitEvenSub': {
    'vi': 'Mỗi thành viên chịu phần bằng nhau',
    'en': 'Each member pays an equal share',
    'zh': '每位成员承担相等份额'
  },
  'group.endTripConfirm': {'vi': 'Kết thúc chuyến?', 'en': 'End trip?', 'zh': '结束行程？'},
  'group.endTripBody': {
    'vi': 'Sau khi kết thúc, bạn có thể xuất hoá đơn chia tiền cho nhóm.',
    'en': 'After ending, you can export the split-bill invoice for the group.',
    'zh': '结束后，你可以为团导出分账单。'
  },
  'group.end': {'vi': 'Kết thúc', 'en': 'End', 'zh': '结束'},
  'group.payAllConfirm': {'vi': 'Thanh toán cả nhóm?', 'en': 'Pay for the whole group?', 'zh': '为整团支付？'},
  'group.payAllBody': {
    'vi': 'Bạn (chủ nhóm) sẽ trả toàn bộ các phòng chưa thanh toán của nhóm trong 1 giao dịch VNPay.',
    'en': 'You (the organizer) will pay for all unpaid rooms in the group in a single VNPay transaction.',
    'zh': '你（团长）将在一笔 VNPay 交易中支付团内所有未付房间。'
  },
  'group.payLinkFailed': {
    'vi': 'Không tạo được liên kết thanh toán nhóm.',
    'en': 'Could not create group payment link.',
    'zh': '无法创建团付款链接。'
  },
  'group.nothingToPay': {'vi': 'Không có phòng nào cần thanh toán.', 'en': 'No rooms need payment.', 'zh': '没有需要支付的房间。'},
  'group.vnpayFailed': {'vi': 'Không mở được cổng VNPay.', 'en': 'Could not open the VNPay gateway.', 'zh': '无法打开 VNPay 支付网关。'},
  'group.payAllTitle': {'vi': 'Thanh toán nhóm (VNPay)', 'en': 'Group payment (VNPay)', 'zh': '团付款（VNPay）'},
  'group.payAllDone': {
    'vi': 'Tổng thanh toán: {v}.\nHoàn tất trên trang VNPay rồi bấm "Đã xong" để cập nhật trạng thái.',
    'en': 'Total payment: {v}.\nComplete on the VNPay page then tap "Done" to update the status.',
    'zh': '支付总额：{v}。\n在 VNPay 页面完成后点击“完成”以更新状态。'
  },
  'group.settlementFailed': {
    'vi': 'Không tải được hoá đơn chia tiền.',
    'en': 'Could not download the split-bill invoice.',
    'zh': '无法下载分账单。'
  },
  'group.deleteRoomConfirm': {'vi': 'Xoá phòng?', 'en': 'Delete room?', 'zh': '删除房间？'},
  'group.deleteRoomBody': {
    'vi': 'Xoá phòng của {a} ({b}) khỏi nhóm? Chỉ áp dụng với phòng chưa thanh toán.',
    'en': 'Remove {a}\'s room ({b}) from the group? Only applies to unpaid rooms.',
    'zh': '从团中删除 {a} 的房间（{b}）？仅适用于未付房间。'
  },
  'group.removeMemberConfirm': {'vi': 'Xoá thành viên?', 'en': 'Remove member?', 'zh': '移除成员？'},
  'group.removeMemberBody': {'vi': 'Xoá {v} khỏi nhóm?', 'en': 'Remove {v} from the group?', 'zh': '将 {v} 移出团？'},
  'group.joinTitle': {'vi': 'Tham gia nhóm', 'en': 'Join group', 'zh': '加入团'},
  'group.openGroup': {'vi': 'Mở nhóm', 'en': 'Open group', 'zh': '打开团'},
  'group.joinByCode': {'vi': 'Tham gia bằng mã', 'en': 'Join by code', 'zh': '用代码加入'},
  'group.emptyTitle': {'vi': 'Bạn chưa có nhóm nào', 'en': 'You have no groups yet', 'zh': '你还没有团'},
  'group.emptySub': {
    'vi': 'Tạo nhóm từ màn đặt phòng khách sạn để rủ bạn bè cùng đặt.',
    'en': 'Create a group from the hotel booking screen to invite friends to book together.',
    'zh': '在酒店预订页创建团，邀请好友一起预订。'
  },
  'group.planning': {'vi': 'Đang lên kế hoạch', 'en': 'Planning', 'zh': '规划中'},

  // ---------------- Hỗ trợ / chatbot (support.*) ----------------
  'support.title': {'vi': 'Trợ lý Dididi', 'en': 'Dididi Assistant', 'zh': 'Dididi 助手'},
  'support.greeting': {
    'vi': 'Chào bạn, mình là trợ lý của Dididi. Mình giúp được về huỷ đơn, hoàn tiền, đổi lịch, thanh toán, điểm thưởng… Bạn cần hỗ trợ gì ạ?',
    'en': 'Hi! I\'m the Dididi assistant. I can help with cancellations, refunds, rescheduling, payments, reward points… What do you need help with?',
    'zh': '你好，我是 Dididi 助手。我可以帮你处理取消、退款、改期、支付、积分等问题…… 需要什么帮助？'
  },
  'support.connectFailed': {
    'vi': 'Xin lỗi, mình chưa kết nối được. Bạn thử lại giúp nhé.',
    'en': 'Sorry, I couldn\'t connect. Please try again.',
    'zh': '抱歉，暂时无法连接。请再试一次。'
  },
  'support.callHotline': {'vi': 'Gọi tổng đài {v}', 'en': 'Call hotline {v}', 'zh': '拨打热线 {v}'},
  'support.inputHint': {'vi': 'Nhập câu hỏi của bạn…', 'en': 'Type your question…', 'zh': '输入你的问题…'},

  // ---------------- Nhà cung cấp (vendor.*) ----------------
  'vendor.title': {'vi': 'Đăng ký làm nhà cung cấp', 'en': 'Register as a vendor', 'zh': '注册成为供应商'},
  'vendor.successTitle': {'vi': 'Đăng ký thành công', 'en': 'Registration successful', 'zh': '注册成功'},
  'vendor.successBody': {
    'vi': 'Tài khoản nhà cung cấp và khách sạn của bạn đã được tạo và đang CHỜ ADMIN DUYỆT. Sau khi được duyệt, bạn có thể đăng nhập để quản lý phòng.',
    'en': 'Your vendor account and hotel have been created and are AWAITING ADMIN APPROVAL. Once approved, you can log in to manage your rooms.',
    'zh': '你的供应商账户和酒店已创建，正在等待管理员审核。审核通过后，你可以登录管理房间。'
  },
  'vendor.understood': {'vi': 'Đã hiểu', 'en': 'Got it', 'zh': '知道了'},
  'vendor.registerFailed': {
    'vi': 'Không đăng ký được, vui lòng thử lại.',
    'en': 'Could not register, please try again.',
    'zh': '注册失败，请重试。'
  },
  'vendor.intro': {
    'vi': 'Trở thành đối tác Dididi để đăng bán phòng của bạn. Tài khoản sẽ được tạo ở trạng thái chờ quản trị viên duyệt.',
    'en': 'Become a Dididi partner to list and sell your rooms. Your account will be created in a pending-approval state.',
    'zh': '成为 Dididi 合作伙伴，上架并出售你的房间。账户创建后将处于待审核状态。'
  },
  'vendor.emailReq': {'vi': 'Email *', 'en': 'Email *', 'zh': '邮箱 *'},
  'vendor.emailInvalid': {'vi': 'Email không hợp lệ', 'en': 'Invalid email', 'zh': '邮箱无效'},
  'vendor.passwordReq': {'vi': 'Mật khẩu *', 'en': 'Password *', 'zh': '密码 *'},
  'vendor.passwordMin6': {'vi': 'Mật khẩu tối thiểu 6 ký tự', 'en': 'Password must be at least 6 characters', 'zh': '密码至少 6 位'},
  'vendor.repName': {'vi': 'Họ tên người đại diện', 'en': 'Representative full name', 'zh': '代表人姓名'},
  'vendor.hotelNameReq': {'vi': 'Tên khách sạn *', 'en': 'Hotel name *', 'zh': '酒店名称 *'},
  'vendor.enterHotelName': {'vi': 'Nhập tên khách sạn', 'en': 'Enter the hotel name', 'zh': '请输入酒店名称'},
  'vendor.city': {'vi': 'Tỉnh/Thành phố', 'en': 'Province/City', 'zh': '省/市'},
  'vendor.address': {'vi': 'Địa chỉ', 'en': 'Address', 'zh': '地址'},
  'vendor.starRating': {'vi': 'Hạng sao', 'en': 'Star rating', 'zh': '星级'},
  'vendor.stars': {'vi': '{v} sao', 'en': '{v} stars', 'zh': '{v} 星'},
  'vendor.submit': {'vi': 'Gửi đăng ký', 'en': 'Submit registration', 'zh': '提交注册'},
};
