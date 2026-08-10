/// Chuỗi i18n nhóm Khách sạn (list/detail/booking/wishlist). vi/en/zh.
const hotelStrings = <String, Map<String, String>>{
  // ----- Danh sách khách sạn (list) -----
  'hotel.heroTitle': {'vi': 'Khám phá theo cách của bạn', 'en': 'Explore your way', 'zh': '按你的方式探索'},
  'hotel.heroSub': {
    'vi': 'Chọn điểm đến, để chúng tôi lo phần còn lại.',
    'en': 'Pick a destination, we handle the rest.',
    'zh': '选好目的地，其余交给我们。'
  },
  'hotel.statBookings': {'vi': 'Lượt đặt', 'en': 'Bookings', 'zh': '预订量'},
  'hotel.statAvg': {'vi': 'Điểm TB', 'en': 'Avg rating', 'zh': '平均评分'},
  'hotel.statCities': {'vi': 'Thành phố', 'en': 'Cities', 'zh': '城市'},
  'hotel.dayDate': {'vi': 'Ngày (theo giờ)', 'en': 'Date (hourly)', 'zh': '日期（按小时）'},
  'hotel.checkIn': {'vi': 'Nhận phòng', 'en': 'Check-in', 'zh': '入住'},
  'hotel.checkOut': {'vi': 'Trả phòng', 'en': 'Check-out', 'zh': '退房'},
  'hotel.guestsRooms': {'vi': 'Khách & phòng', 'en': 'Guests & rooms', 'zh': '客人与房间'},
  'hotel.overnight': {'vi': 'Qua đêm', 'en': 'Overnight', 'zh': '过夜'},
  'hotel.dayUse': {'vi': 'Trong ngày', 'en': 'Day use', 'zh': '日间'},
  'hotel.adults': {'vi': 'Người lớn', 'en': 'Adults', 'zh': '成人'},
  'hotel.children': {'vi': 'Trẻ em', 'en': 'Children', 'zh': '儿童'},
  'hotel.rooms': {'vi': 'Phòng', 'en': 'Rooms', 'zh': '房间'},
  'hotel.emptyTitle': {'vi': 'Không tìm thấy khách sạn', 'en': 'No hotels found', 'zh': '未找到酒店'},
  'hotel.openMap': {'vi': 'Mở bản đồ', 'en': 'Open map', 'zh': '打开地图'},
  'hotel.loadedAll': {
    'vi': 'Đã hiện {n}/{total} khách sạn',
    'en': 'Showing {n} of {total} hotels',
    'zh': '已显示 {n}/{total} 家酒店'
  },
  'hotel.emptyMsg': {
    'vi': 'Thử đổi từ khoá hoặc bỏ bớt bộ lọc để xem thêm chỗ ở.',
    'en': 'Try changing keywords or removing filters to see more stays.',
    'zh': '试试更换关键词或减少筛选条件以查看更多住宿。'
  },
  'hotel.searchHint': {
    'vi': 'Tìm theo tên khách sạn, thành phố',
    'en': 'Search by hotel name or city',
    'zh': '按酒店名称或城市搜索'
  },
  'hotel.featuredTitle': {'vi': 'Nổi bật · đánh giá cao', 'en': 'Featured · top rated', 'zh': '精选 · 高评分'},
  'hotel.featuredSub': {'vi': 'Được khách yêu thích nhất', 'en': 'Most loved by guests', 'zh': '最受客人喜爱'},
  'hotel.placesCount': {'vi': '{n} chỗ ở', 'en': '{n} stays', 'zh': '{n} 处住宿'},
  'hotel.filters': {'vi': 'Bộ lọc', 'en': 'Filters', 'zh': '筛选'},
  'hotel.sortDefault': {'vi': 'Đề xuất', 'en': 'Recommended', 'zh': '推荐'},
  'hotel.sortPriceAsc': {'vi': 'Giá ↑', 'en': 'Price ↑', 'zh': '价格 ↑'},
  'hotel.sortPriceDesc': {'vi': 'Giá ↓', 'en': 'Price ↓', 'zh': '价格 ↓'},
  'hotel.sortRatingDesc': {'vi': 'Đánh giá cao', 'en': 'Top rated', 'zh': '高评分'},
  'hotel.sortStarDesc': {'vi': 'Sao ↓', 'en': 'Stars ↓', 'zh': '星级 ↓'},
  'hotel.clearFilter': {'vi': 'Xoá lọc', 'en': 'Clear', 'zh': '清除'},
  'hotel.pricePerNight': {'vi': 'Giá mỗi đêm (đ)', 'en': 'Price per night (đ)', 'zh': '每晚价格（đ）'},
  'hotel.min': {'vi': 'Tối thiểu', 'en': 'Min', 'zh': '最低'},
  'hotel.max': {'vi': 'Tối đa', 'en': 'Max', 'zh': '最高'},
  'hotel.ratingScore': {'vi': 'Điểm đánh giá', 'en': 'Rating score', 'zh': '评分'},
  'hotel.starClass': {'vi': 'Hạng sao', 'en': 'Star class', 'zh': '星级'},
  'hotel.starsN': {'vi': '{n} sao', 'en': '{n} stars', 'zh': '{n} 星'},
  'hotel.propertyType': {'vi': 'Loại chỗ ở', 'en': 'Property type', 'zh': '住宿类型'},
  'hotel.amenities': {'vi': 'Tiện nghi', 'en': 'Amenities', 'zh': '设施'},
  'hotel.tagsSection': {'vi': 'Nổi bật', 'en': 'Highlights', 'zh': '亮点'},
  'hotel.instantConfirm': {'vi': 'Xác nhận tức thì', 'en': 'Instant confirmation', 'zh': '即时确认'},
  'hotel.payOnline': {'vi': 'Thanh toán online', 'en': 'Online payment', 'zh': '在线支付'},
  'hotel.fromPerNight': {'vi': 'Từ {p}/đêm', 'en': 'From {p}/night', 'zh': '{p}/晚起'},
  'hotel.contact': {'vi': 'Liên hệ', 'en': 'Contact', 'zh': '联系'},
  'hotel.mapTitle': {'vi': 'Bản đồ khách sạn', 'en': 'Hotel map', 'zh': '酒店地图'},
  'hotel.viewDetail': {'vi': 'Xem chi tiết', 'en': 'View details', 'zh': '查看详情'},
  'hotel.fromPrice': {'vi': 'Từ {p}', 'en': 'From {p}', 'zh': '{p}起'},
  'hotel.locOff': {'vi': 'Vui lòng bật dịch vụ vị trí.', 'en': 'Please turn on location services.', 'zh': '请开启定位服务。'},
  'hotel.locDenied': {'vi': 'Chưa cấp quyền vị trí.', 'en': 'Location permission not granted.', 'zh': '尚未授予定位权限。'},
  'hotel.locFail': {'vi': 'Không lấy được vị trí: {e}', 'en': 'Could not get location: {e}', 'zh': '无法获取位置：{e}'},
  'hotel.view': {'vi': 'Xem', 'en': 'View', 'zh': '查看'},

  // Nhãn tag nổi bật (chip lọc)
  'hotel.tag.beachfront': {'vi': 'Gần biển', 'en': 'Near beach', 'zh': '近海滩'},
  'hotel.tag.familyFriendly': {'vi': 'Hợp gia đình', 'en': 'Family-friendly', 'zh': '适合家庭'},
  'hotel.tag.business': {'vi': 'Công tác', 'en': 'Business', 'zh': '商务'},
  'hotel.tag.romantic': {'vi': 'Lãng mạn', 'en': 'Romantic', 'zh': '浪漫'},
  'hotel.tag.luxury': {'vi': 'Sang trọng', 'en': 'Luxury', 'zh': '豪华'},
  'hotel.tag.budget': {'vi': 'Tiết kiệm', 'en': 'Budget', 'zh': '经济实惠'},
  'hotel.tag.cityCenter': {'vi': 'Trung tâm', 'en': 'City center', 'zh': '市中心'},
  'hotel.tag.pool': {'vi': 'Có hồ bơi', 'en': 'Pool', 'zh': '泳池'},
  'hotel.tag.petFriendly': {'vi': 'Cho thú cưng', 'en': 'Pet-friendly', 'zh': '允许宠物'},
  'hotel.tag.new': {'vi': 'Mới', 'en': 'New', 'zh': '新开业'},
  'hotel.tag.topRated': {'vi': 'Được yêu thích', 'en': 'Top rated', 'zh': '备受好评'},

  // ----- Chi tiết khách sạn (detail) -----
  'hotel.detailTitle': {'vi': 'Chi tiết khách sạn', 'en': 'Hotel details', 'zh': '酒店详情'},
  'hotel.location': {'vi': 'Vị trí', 'en': 'Location', 'zh': '位置'},
  'hotel.roomTypes': {'vi': 'Các hạng phòng', 'en': 'Room types', 'zh': '房型'},
  'hotel.reviews': {'vi': 'Đánh giá', 'en': 'Reviews', 'zh': '评价'},
  'hotel.book': {'vi': 'Đặt phòng', 'en': 'Book room', 'zh': '预订房间'},
  'hotel.bookFrom': {'vi': 'Đặt phòng · từ {p}', 'en': 'Book · from {p}', 'zh': '预订 · {p}起'},
  'hotel.photosCount': {'vi': '{n} ảnh', 'en': '{n} photos', 'zh': '{n} 张照片'},
  'hotel.roomsLoadError': {'vi': 'Chưa lấy được hạng phòng.', 'en': 'Could not load room types.', 'zh': '无法加载房型。'},
  'hotel.noRoomsTitle': {'vi': 'Chưa mở đặt phòng', 'en': 'Booking not open yet', 'zh': '尚未开放预订'},
  'hotel.noRoomsMsg': {
    'vi': 'Khách sạn này chưa mở đặt phòng trên app.',
    'en': 'This hotel is not open for booking on the app yet.',
    'zh': '该酒店尚未在应用上开放预订。'
  },
  'hotel.capacityGuests': {'vi': 'Sức chứa {n} khách', 'en': 'Fits {n} guests', 'zh': '可住 {n} 人'},
  'hotel.noRatingYet': {'vi': 'Chưa có đánh giá', 'en': 'No ratings yet', 'zh': '暂无评分'},
  'hotel.reviewsCount': {'vi': '{n} đánh giá', 'en': '{n} reviews', 'zh': '{n} 条评价'},
  'hotel.reviewsLoadError': {'vi': 'Không tải được đánh giá.', 'en': 'Could not load reviews.', 'zh': '无法加载评价。'},
  'hotel.noReviewsTitle': {'vi': 'Chưa có đánh giá nào', 'en': 'No reviews yet', 'zh': '暂无评价'},
  'hotel.noReviewsMsg': {
    'vi': 'Hãy là người đầu tiên chia sẻ trải nghiệm về khách sạn này.',
    'en': 'Be the first to share your experience about this hotel.',
    'zh': '成为第一个分享该酒店体验的人。'
  },
  'hotel.anonymous': {'vi': 'Ẩn danh', 'en': 'Anonymous', 'zh': '匿名'},
  'hotel.vendorReply': {'vi': 'Phản hồi: {t}', 'en': 'Reply: {t}', 'zh': '回复：{t}'},
  'hotel.unsave': {'vi': 'Bỏ lưu', 'en': 'Remove', 'zh': '取消收藏'},
  'hotel.saveToWishlist': {'vi': 'Lưu vào yêu thích', 'en': 'Save to wishlist', 'zh': '加入收藏'},

  // ----- Đặt phòng (booking) -----
  'hotel.pickRoomType': {'vi': 'Vui lòng chọn loại phòng', 'en': 'Please choose a room type', 'zh': '请选择房型'},
  'hotel.enterGuestName': {'vi': 'Vui lòng nhập tên khách', 'en': 'Please enter the guest name', 'zh': '请输入客人姓名'},
  'hotel.checkOutTimeAfter': {
    'vi': 'Giờ trả phòng phải sau giờ nhận phòng',
    'en': 'Check-out time must be after check-in time',
    'zh': '退房时间必须晚于入住时间'
  },
  'hotel.checkOutDateAfter': {
    'vi': 'Ngày trả phòng phải sau ngày nhận phòng',
    'en': 'Check-out date must be after check-in date',
    'zh': '退房日期必须晚于入住日期'
  },
  'hotel.orderCreatedPending': {
    'vi': 'Đơn {code} đã tạo (chờ thanh toán) — xem ở "Đơn của tôi".',
    'en': 'Order {code} created (awaiting payment) — see it in "My bookings".',
    'zh': '订单 {code} 已创建（待支付）——请在"我的订单"中查看。'
  },
  'hotel.bookSuccessTitle': {'vi': 'Đặt phòng thành công', 'en': 'Booking successful', 'zh': '预订成功'},
  'hotel.bookSuccessBody': {
    'vi': 'Đơn {code} — {status}.\nTổng thanh toán: {amount}',
    'en': 'Order {code} — {status}.\nTotal paid: {amount}',
    'zh': '订单 {code} — {status}。\n支付总额：{amount}'
  },
  'hotel.backToHome': {'vi': 'Về trang chủ', 'en': 'Back to home', 'zh': '返回首页'},
  'hotel.viewMyOrders': {'vi': 'Xem đơn của tôi', 'en': 'View my bookings', 'zh': '查看我的订单'},
  'hotel.chooseRoomType': {'vi': 'Chọn loại phòng', 'en': 'Choose room type', 'zh': '选择房型'},
  'hotel.stayTime': {'vi': 'Thời gian ở', 'en': 'Stay duration', 'zh': '入住时间'},
  'hotel.date': {'vi': 'Ngày', 'en': 'Date', 'zh': '日期'},
  'hotel.timeIn': {'vi': 'Giờ nhận', 'en': 'Check-in time', 'zh': '入住时间'},
  'hotel.timeOut': {'vi': 'Giờ trả', 'en': 'Check-out time', 'zh': '退房时间'},
  'hotel.duration': {'vi': 'Thời lượng {t} · {p}', 'en': 'Duration {t} · {p}', 'zh': '时长 {t} · {p}'},
  'hotel.halfPrice': {'vi': 'nửa giá (≤4h)', 'en': 'half price (≤4h)', 'zh': '半价（≤4小时）'},
  'hotel.fullPrice': {'vi': 'nguyên giá', 'en': 'full price', 'zh': '全价'},
  'hotel.checkOutTimeAfterShort': {
    'vi': 'Giờ trả phải sau giờ nhận',
    'en': 'Check-out must be after check-in',
    'zh': '退房时间须晚于入住时间'
  },
  'hotel.nightsCount': {'vi': '{n} đêm', 'en': '{n} nights', 'zh': '{n} 晚'},
  'hotel.guestName': {'vi': 'Tên khách', 'en': 'Guest name', 'zh': '客人姓名'},
  'hotel.guestNameHint': {'vi': 'Họ tên người nhận phòng', 'en': 'Full name of the guest', 'zh': '入住人姓名'},
  'hotel.roomCount': {'vi': 'Số phòng', 'en': 'Rooms', 'zh': '房间数'},
  'hotel.groupBooking': {
    'vi': 'Đặt theo nhóm (rủ bạn bè cùng đặt)',
    'en': 'Group booking (invite friends to book together)',
    'zh': '团体预订（邀请好友一起预订）'
  },
  'hotel.pickRoomFirst': {
    'vi': 'Vui lòng chọn loại phòng trước',
    'en': 'Please choose a room type first',
    'zh': '请先选择房型'
  },
  'hotel.bulkBooking': {
    'vi': 'Đặt hàng loạt (nhiều khách)',
    'en': 'Bulk booking (multiple guests)',
    'zh': '批量预订（多位客人）'
  },
  'hotel.groupCreateError': {
    'vi': 'Không tạo được nhóm, vui lòng thử lại.',
    'en': 'Could not create the group, please try again.',
    'zh': '无法创建团体，请重试。'
  },
  'hotel.capacityMax': {'vi': 'Tối đa {n} khách', 'en': 'Up to {n} guests', 'zh': '最多 {n} 人'},
  'hotel.perNight': {'vi': '/đêm', 'en': '/night', 'zh': '/晚'},
  'hotel.subtotal': {'vi': 'Tạm tính', 'en': 'Subtotal', 'zh': '小计'},
  'hotel.byHourRooms': {'vi': 'Theo giờ × {r} phòng', 'en': 'Hourly × {r} rooms', 'zh': '按小时 × {r} 间'},
  'hotel.nightsRooms': {'vi': '{n} đêm × {r} phòng', 'en': '{n} nights × {r} rooms', 'zh': '{n} 晚 × {r} 间'},
  'hotel.bookAndPay': {'vi': 'Đặt & thanh toán', 'en': 'Book & pay', 'zh': '预订并支付'},

  // ----- Yêu thích (wishlist) -----
  'hotel.wishlistTitle': {'vi': 'Khách sạn yêu thích', 'en': 'Favorite hotels', 'zh': '收藏的酒店'},
  'hotel.wishlistEmptyTitle': {'vi': 'Chưa có khách sạn yêu thích', 'en': 'No favorite hotels yet', 'zh': '暂无收藏的酒店'},
  'hotel.wishlistEmptyMsg': {
    'vi': 'Bấm ♥ ở trang chi tiết khách sạn để lưu lại chỗ ở bạn thích.',
    'en': 'Tap ♥ on a hotel detail page to save the stays you like.',
    'zh': '在酒店详情页点击 ♥ 即可收藏你喜欢的住宿。'
  },

  // ----- Nhãn khách & phòng (hotel_search) -----
  'hotel.adultsCount': {'vi': '{n} người lớn', 'en': '{n} adults', 'zh': '{n} 位成人'},
  'hotel.childrenCount': {'vi': '{n} trẻ em', 'en': '{n} children', 'zh': '{n} 位儿童'},
  'hotel.roomsCount': {'vi': '{n} phòng', 'en': '{n} rooms', 'zh': '{n} 间'},
};
