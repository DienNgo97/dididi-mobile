/// Chuỗi i18n nhóm Vé + Đơn + Trip + Bulk + Thanh toán. vi/en/zh.
const bookingStrings = <String, Map<String, String>>{
  // ---------------- Vé máy bay (flight.*) ----------------
  'flight.noFlightsTitle': {'vi': 'Không tìm thấy chuyến bay', 'en': 'No flights found', 'zh': '未找到航班'},
  'flight.noFlightsMsg': {
    'vi': 'Không có chuyến bay phù hợp. Thử tuyến hoặc ngày khác.',
    'en': 'No matching flights. Try another route or date.',
    'zh': '没有匹配的航班。请尝试其他航线或日期。'
  },
  'flight.noneShort': {'vi': 'Không có chuyến bay phù hợp.', 'en': 'No matching flights.', 'zh': '没有匹配的航班。'},
  'flight.origin': {'vi': 'Điểm đi', 'en': 'From', 'zh': '出发地'},
  'flight.originHint': {'vi': 'vd SGN', 'en': 'e.g. SGN', 'zh': '例如 SGN'},
  'flight.destination': {'vi': 'Điểm đến', 'en': 'To', 'zh': '目的地'},
  'flight.destHint': {'vi': 'vd HAN', 'en': 'e.g. HAN', 'zh': '例如 HAN'},
  'flight.departDate': {'vi': 'Ngày đi', 'en': 'Departure date', 'zh': '出发日期'},
  'flight.anyDate': {'vi': 'Mọi ngày', 'en': 'Any date', 'zh': '任意日期'},
  'flight.loadedAll': {
    'vi': 'Đã hiện {n}/{total} chuyến',
    'en': 'Showing {n} of {total} flights',
    'zh': '已显示 {n}/{total} 个航班'
  },
  'flight.oneWay': {'vi': 'Một chiều', 'en': 'One-way', 'zh': '单程'},
  'flight.roundTrip': {'vi': 'Khứ hồi', 'en': 'Round trip', 'zh': '往返'},
  'flight.returnDate': {'vi': 'Ngày về', 'en': 'Return date', 'zh': '返程日期'},
  'flight.pickReturnDate': {'vi': 'Vui lòng chọn ngày về', 'en': 'Please pick a return date', 'zh': '请选择返程日期'},
  'flight.returnBeforeOutbound': {'vi': 'Ngày về phải từ ngày đi trở đi', 'en': 'Return date must be on or after departure', 'zh': '返程日期不能早于出发日期'},
  'flight.chooseReturnTitle': {'vi': 'Chọn chuyến về', 'en': 'Choose return flight', 'zh': '选择返程航班'},
  'flight.outboundLeg': {'vi': 'Chuyến đi', 'en': 'Outbound', 'zh': '去程'},
  'flight.returnLeg': {'vi': 'Chuyến về', 'en': 'Return', 'zh': '返程'},
  'flight.legOutbound': {'vi': 'Khứ hồi · chặng 1/2 — chuyến đi', 'en': 'Round trip · leg 1/2 — outbound', 'zh': '往返 · 第 1/2 段 — 去程'},
  'flight.legReturn': {'vi': 'Khứ hồi · chặng 2/2 — chuyến về', 'en': 'Round trip · leg 2/2 — return', 'zh': '往返 · 第 2/2 段 — 返程'},
  'flight.noReturnFlights': {'vi': 'Không có chuyến về phù hợp ngày đã chọn', 'en': 'No return flights for the chosen date', 'zh': '所选日期没有合适的返程航班'},
  'flight.outboundBooked': {'vi': 'Đã đặt chuyến đi ({code}). Tiếp tục đặt chuyến về?', 'en': 'Outbound booked ({code}). Continue with the return flight?', 'zh': '去程已预订（{code}）。继续预订返程？'},
  'flight.continueReturn': {'vi': 'Đặt chuyến về', 'en': 'Book return flight', 'zh': '预订返程'},
  'flight.laterViewOrders': {'vi': 'Để sau (xem Đơn của tôi)', 'en': 'Later (see My orders)', 'zh': '稍后（查看订单）'},
  'flight.cabinClass': {'vi': 'Hạng ghế', 'en': 'Cabin class', 'zh': '舱位'},
  'flight.anyCabin': {'vi': 'Mọi hạng', 'en': 'All classes', 'zh': '所有舱位'},
  'flight.economy': {'vi': 'Phổ thông', 'en': 'Economy', 'zh': '经济舱'},
  'flight.business': {'vi': 'Thương gia', 'en': 'Business', 'zh': '商务舱'},
  'flight.search': {'vi': 'Tìm chuyến bay', 'en': 'Search flights', 'zh': '搜索航班'},
  'flight.seatsLeft': {'vi': 'Còn {n} ghế', 'en': '{n} seats left', 'zh': '剩余 {n} 个座位'},
  'flight.invalidEmail': {'vi': 'Email liên hệ không hợp lệ', 'en': 'Invalid contact email', 'zh': '联系邮箱无效'},
  'flight.selectSeat': {'vi': 'Vui lòng chọn ít nhất 1 ghế', 'en': 'Please select at least 1 seat', 'zh': '请至少选择 1 个座位'},
  'flight.enterAllNames': {
    'vi': 'Vui lòng nhập tên cho tất cả hành khách',
    'en': 'Please enter names for all passengers',
    'zh': '请填写所有乘客姓名'
  },
  'flight.orderCreatedPending': {
    'vi': 'Đơn {code} đã tạo (chờ thanh toán) — xem ở "Đơn của tôi".',
    'en': 'Booking {code} created (awaiting payment) — see it in "My bookings".',
    'zh': '订单 {code} 已创建（待支付）——请在"我的订单"中查看。'
  },
  'flight.bookSuccess': {'vi': 'Đặt vé thành công', 'en': 'Booking successful', 'zh': '订票成功'},
  'flight.bookSuccessBody': {
    'vi': 'Đơn {code} — {status}.\nTổng thanh toán: {amount}',
    'en': 'Booking {code} — {status}.\nTotal paid: {amount}',
    'zh': '订单 {code} — {status}。\n支付总额：{amount}'
  },
  'flight.backHome': {'vi': 'Về trang chủ', 'en': 'Back to home', 'zh': '返回首页'},
  'flight.viewMyOrders': {'vi': 'Xem đơn của tôi', 'en': 'View my bookings', 'zh': '查看我的订单'},
  'flight.bookTitle': {'vi': 'Đặt vé máy bay', 'en': 'Book flight', 'zh': '预订机票'},
  'flight.contactEmail': {'vi': 'Email liên hệ', 'en': 'Contact email', 'zh': '联系邮箱'},
  'flight.emailForTicket': {'vi': 'Email nhận vé', 'en': 'Email to receive ticket', 'zh': '接收机票的邮箱'},
  'flight.selectSeatToEnter': {
    'vi': 'Chọn ghế để nhập thông tin hành khách.',
    'en': 'Select a seat to enter passenger details.',
    'zh': '选择座位以填写乘客信息。'
  },
  'flight.passengersCount': {'vi': 'Hành khách ({n})', 'en': 'Passengers ({n})', 'zh': '乘客（{n}）'},
  'flight.passengerN': {'vi': 'Hành khách {n}', 'en': 'Passenger {n}', 'zh': '乘客 {n}'},
  'flight.seatN': {'vi': 'Ghế {code}', 'en': 'Seat {code}', 'zh': '座位 {code}'},
  'flight.passengerName': {'vi': 'Họ tên hành khách', 'en': 'Passenger full name', 'zh': '乘客姓名'},
  'flight.meal': {'vi': 'Suất ăn', 'en': 'Meal', 'zh': '餐食'},
  'flight.baggage': {'vi': 'Hành lý', 'en': 'Baggage', 'zh': '行李'},
  'flight.passengerCount': {'vi': 'Số hành khách', 'en': 'Number of passengers', 'zh': '乘客人数'},
  'flight.selectSeatTitle': {'vi': 'Chọn chỗ ngồi', 'en': 'Select seat', 'zh': '选择座位'},
  'flight.seatFree': {'vi': 'Trống', 'en': 'Free', 'zh': '空闲'},
  'flight.seatSelecting': {'vi': 'Đang chọn', 'en': 'Selecting', 'zh': '选择中'},
  'flight.seatBooked': {'vi': 'Đã đặt', 'en': 'Booked', 'zh': '已订'},
  'flight.selectedSeats': {'vi': 'Ghế đã chọn: {seats}', 'en': 'Selected seats: {seats}', 'zh': '已选座位：{seats}'},
  'flight.passengersN': {'vi': '{n} hành khách', 'en': '{n} passengers', 'zh': '{n} 位乘客'},
  'flight.bookAndPay': {'vi': 'Đặt & thanh toán', 'en': 'Book & pay', 'zh': '预订并支付'},

  // ---------------- Thanh toán (pay.*) ----------------
  'pay.subtotal': {'vi': 'Tạm tính', 'en': 'Subtotal', 'zh': '小计'},
  'pay.voucher': {'vi': 'Mã giảm giá', 'en': 'Discount code', 'zh': '优惠码'},
  'pay.enterVoucher': {'vi': 'Nhập mã voucher', 'en': 'Enter voucher code', 'zh': '输入优惠码'},
  'pay.voucherApplied': {'vi': 'Đã áp dụng mã giảm giá', 'en': 'Discount code applied', 'zh': '已应用优惠码'},
  'pay.voucherInvalid': {
    'vi': 'Mã không hợp lệ hoặc không áp dụng được cho đơn này.',
    'en': 'Invalid code or not applicable to this booking.',
    'zh': '优惠码无效或不适用于此订单。'
  },
  'pay.voucherAppliedCode': {'vi': 'Đã áp mã "{code}"', 'en': 'Applied code "{code}"', 'zh': '已应用优惠码"{code}"'},
  'pay.voucherRemoved': {'vi': 'Đã gỡ mã giảm giá', 'en': 'Discount code removed', 'zh': '已移除优惠码'},
  'pay.voucherRemoveFail': {'vi': 'Không gỡ được mã.', 'en': 'Could not remove code.', 'zh': '无法移除优惠码。'},
  'pay.companyTitle': {'vi': 'Thanh toán bằng công ty?', 'en': 'Pay with company?', 'zh': '用公司账户支付？'},
  'pay.companyBody': {
    'vi': 'Trừ vào ngân sách của {name}.\nCòn lại: {remaining}.\nNếu vượt hạn mức duyệt, đơn sẽ chuyển sang chờ quản lý duyệt.',
    'en': 'Deducted from the budget of {name}.\nRemaining: {remaining}.\nIf it exceeds the approval limit, the booking will await manager approval.',
    'zh': '从 {name} 的预算中扣除。\n剩余：{remaining}。\n如果超过审批额度，订单将转为等待经理审批。'
  },
  'pay.companyPaid': {'vi': 'Đã thanh toán bằng ngân sách công ty.', 'en': 'Paid with company budget.', 'zh': '已使用公司预算支付。'},
  'pay.companyPending': {
    'vi': 'Đã gửi yêu cầu duyệt chi cho quản lý công ty.',
    'en': 'Spending approval request sent to the company manager.',
    'zh': '已向公司经理发送支出审批请求。'
  },
  'pay.companyFail': {
    'vi': 'Không thanh toán được bằng công ty, thử lại sau.',
    'en': 'Could not pay with company, try again later.',
    'zh': '无法用公司账户支付，请稍后再试。'
  },
  'pay.payWithCompany': {'vi': 'Thanh toán bằng công ty ({name})', 'en': 'Pay with company ({name})', 'zh': '用公司支付（{name}）'},
  'pay.orderCode': {'vi': 'Mã đơn: {code}', 'en': 'Booking code: {code}', 'zh': '订单编号：{code}'},
  'pay.totalAmount': {'vi': 'Tổng tiền: {amount}', 'en': 'Total: {amount}', 'zh': '总计：{amount}'},
  'pay.applyShort': {'vi': 'Áp', 'en': 'Apply', 'zh': '应用'},
  'pay.removeShort': {'vi': 'Gỡ', 'en': 'Remove', 'zh': '移除'},
  'pay.selectMethod': {'vi': 'Chọn phương thức thanh toán:', 'en': 'Select payment method:', 'zh': '选择支付方式：'},
  'pay.mockPay': {'vi': 'Thanh toán giả lập', 'en': 'Mock payment', 'zh': '模拟支付'},
  'pay.vnpayLinkFail': {'vi': 'Không tạo được liên kết VNPay.', 'en': 'Could not create VNPay link.', 'zh': '无法创建 VNPay 链接。'},
  'pay.vnpayOpenFail': {'vi': 'Không mở được cổng VNPay.', 'en': 'Could not open VNPay gateway.', 'zh': '无法打开 VNPay 支付网关。'},
  'pay.vnpayTitle': {'vi': 'Thanh toán VNPay', 'en': 'VNPay payment', 'zh': 'VNPay 支付'},
  'pay.vnpayBody': {
    'vi': 'Hoàn tất thanh toán trên trang VNPay, sau đó quay lại đây và bấm "Tôi đã thanh toán" để xác nhận.',
    'en': 'Complete the payment on the VNPay page, then return here and tap "I have paid" to confirm.',
    'zh': '在 VNPay 页面完成支付，然后返回此处并点击"我已支付"以确认。'
  },
  'pay.iHavePaid': {'vi': 'Tôi đã thanh toán', 'en': 'I have paid', 'zh': '我已支付'},

  // ---------------- Đơn của tôi / Chi tiết đơn (booking.*) ----------------
  'booking.emptyTitle': {'vi': 'Bạn chưa có đơn nào', 'en': 'You have no bookings yet', 'zh': '您还没有订单'},
  'booking.emptyMsg': {
    'vi': 'Đặt khách sạn hoặc vé máy bay để xem đơn ở đây.',
    'en': 'Book a hotel or flight to see your bookings here.',
    'zh': '预订酒店或机票后即可在此查看订单。'
  },
  'booking.noMatchTitle': {'vi': 'Không có đơn phù hợp', 'en': 'No matching bookings', 'zh': '没有匹配的订单'},
  'booking.noMatchMsg': {
    'vi': 'Thử đổi bộ lọc loại hoặc trạng thái.',
    'en': 'Try changing the type or status filter.',
    'zh': '尝试更改类型或状态筛选。'
  },
  'booking.filterAll': {'vi': 'Tất cả', 'en': 'All', 'zh': '全部'},
  'booking.filterGroup': {'vi': 'Nhóm', 'en': 'Group', 'zh': '团体'},
  'booking.anyStatus': {'vi': 'Mọi trạng thái', 'en': 'Any status', 'zh': '所有状态'},
  'booking.statusPending': {'vi': 'Chờ thanh toán', 'en': 'Pending payment', 'zh': '待支付'},
  'booking.statusConfirmed': {'vi': 'Đã xác nhận', 'en': 'Confirmed', 'zh': '已确认'},
  'booking.statusCancelled': {'vi': 'Đã huỷ', 'en': 'Cancelled', 'zh': '已取消'},
  'booking.codeWord': {'vi': 'Mã', 'en': 'Code', 'zh': '编号'},
  'booking.cancelTitle': {'vi': 'Huỷ đơn?', 'en': 'Cancel booking?', 'zh': '取消订单？'},
  'booking.cancelBody': {
    'vi': 'Gửi yêu cầu huỷ đơn này? Admin sẽ duyệt và hoàn tiền nếu hợp lệ.',
    'en': 'Send a request to cancel this booking? An admin will review and refund if eligible.',
    'zh': '发送取消此订单的请求？管理员将审核，符合条件时退款。'
  },
  'booking.cancelReasonLabel': {'vi': 'Lý do huỷ (tuỳ chọn)', 'en': 'Cancellation reason (optional)', 'zh': '取消原因（可选）'},
  'booking.cancelReasonHint': {
    'vi': 'Vd: đổi lịch trình, đặt nhầm ngày…',
    'en': 'e.g. schedule change, wrong date…',
    'zh': '例如：行程变更、日期填错……'
  },
  'booking.no': {'vi': 'Không', 'en': 'No', 'zh': '否'},
  'booking.cancelOrder': {'vi': 'Huỷ đơn', 'en': 'Cancel booking', 'zh': '取消订单'},
  'booking.cancelSent': {
    'vi': 'Đã gửi yêu cầu huỷ, chờ admin duyệt.',
    'en': 'Cancellation request sent, awaiting admin approval.',
    'zh': '已发送取消请求，等待管理员审批。'
  },
  'booking.cancelFail': {
    'vi': 'Không huỷ được đơn, vui lòng thử lại.',
    'en': 'Could not cancel the booking, please try again.',
    'zh': '无法取消订单，请重试。'
  },
  'booking.writeReview': {'vi': 'Viết đánh giá', 'en': 'Write a review', 'zh': '写评价'},
  'booking.reviewHint': {'vi': 'Cảm nhận của bạn (tuỳ chọn)', 'en': 'Your thoughts (optional)', 'zh': '您的感受（可选）'},
  'booking.addPhoto': {'vi': 'Thêm ảnh', 'en': 'Add photos', 'zh': '添加照片'},
  'booking.photosCount': {'vi': '{n} ảnh', 'en': '{n} photos', 'zh': '{n} 张照片'},
  'booking.reviewThanks': {'vi': 'Cảm ơn bạn đã đánh giá!', 'en': 'Thank you for your review!', 'zh': '感谢您的评价！'},
  'booking.reviewFail': {
    'vi': 'Không gửi được đánh giá, vui lòng thử lại.',
    'en': 'Could not submit review, please try again.',
    'zh': '无法提交评价，请重试。'
  },
  'booking.editOrder': {'vi': 'Sửa đơn', 'en': 'Edit booking', 'zh': '修改订单'},
  'booking.checkIn': {'vi': 'Nhận phòng', 'en': 'Check-in', 'zh': '入住'},
  'booking.checkOut': {'vi': 'Trả phòng', 'en': 'Check-out', 'zh': '退房'},
  'booking.roomCount': {'vi': 'Số phòng', 'en': 'Rooms', 'zh': '房间数'},
  'booking.updated': {'vi': 'Đã cập nhật đơn', 'en': 'Booking updated', 'zh': '订单已更新'},
  'booking.editOnlyPending': {
    'vi': 'Chỉ sửa được đơn khách sạn trực tiếp (qua đêm) còn chờ thanh toán.',
    'en': 'Only direct overnight hotel bookings awaiting payment can be edited.',
    'zh': '仅可修改待支付的直连过夜酒店订单。'
  },
  'booking.invoiceFail': {
    'vi': 'Không tải được hoá đơn (đơn cần đã xác nhận).',
    'en': 'Could not download invoice (booking must be confirmed).',
    'zh': '无法下载发票（订单需已确认）。'
  },
  'booking.detailTitle': {'vi': 'Chi tiết đơn', 'en': 'Booking details', 'zh': '订单详情'},
  'booking.orderCode': {'vi': 'Mã đơn', 'en': 'Booking code', 'zh': '订单编号'},
  'booking.status': {'vi': 'Trạng thái', 'en': 'Status', 'zh': '状态'},
  'booking.date': {'vi': 'Ngày', 'en': 'Date', 'zh': '日期'},
  'booking.seatCount': {'vi': 'Số ghế', 'en': 'Seats', 'zh': '座位数'},
  'booking.payNow': {'vi': 'Thanh toán ngay', 'en': 'Pay now', 'zh': '立即支付'},
  'booking.applyVoucherBtn': {'vi': 'Áp mã giảm giá', 'en': 'Apply discount code', 'zh': '使用优惠码'},
  'booking.editOrderBtn': {'vi': 'Sửa đơn (đổi ngày/phòng)', 'en': 'Edit booking (change dates/rooms)', 'zh': '修改订单（改日期/房间）'},
  'booking.downloadInvoice': {'vi': 'Tải hoá đơn VAT', 'en': 'Download VAT invoice', 'zh': '下载增值税发票'},

  // ---------------- Đặt hàng loạt (bulk.*) ----------------
  'bulk.title': {'vi': 'Đặt hàng loạt', 'en': 'Bulk booking', 'zh': '批量预订'},
  'bulk.enterOneGuest': {'vi': 'Nhập ít nhất 1 tên khách', 'en': 'Enter at least 1 guest name', 'zh': '请至少填写 1 位客人姓名'},
  'bulk.timeOutAfterIn': {
    'vi': 'Giờ trả phòng phải sau giờ nhận phòng',
    'en': 'Check-out time must be after check-in time',
    'zh': '退房时间必须晚于入住时间'
  },
  'bulk.bookFail': {'vi': 'Không đặt được, vui lòng thử lại.', 'en': 'Booking failed, please try again.', 'zh': '预订失败，请重试。'},
  'bulk.overnight': {'vi': 'Qua đêm', 'en': 'Overnight', 'zh': '过夜'},
  'bulk.dayUse': {'vi': 'Trong ngày', 'en': 'Day use', 'zh': '钟点房'},
  'bulk.room': {'vi': 'Phòng', 'en': 'Room', 'zh': '房间'},
  'bulk.timeIn': {'vi': 'Giờ nhận', 'en': 'Check-in time', 'zh': '入住时间'},
  'bulk.timeOut': {'vi': 'Giờ trả', 'en': 'Check-out time', 'zh': '退房时间'},
  'bulk.dayUseNote': {
    'vi': 'Đặt theo giờ (≤4h) — nửa giá qua đêm.',
    'en': 'Hourly booking (≤4h) — half the overnight price.',
    'zh': '按小时预订（≤4小时）——过夜价的一半。'
  },
  'bulk.guestList': {'vi': 'Danh sách khách', 'en': 'Guest list', 'zh': '客人名单'},
  'bulk.guestListSub': {
    'vi': 'Mỗi dòng là 1 phòng đặt riêng. Bỏ trống dòng không dùng.',
    'en': 'Each row is a separate room booking. Leave unused rows blank.',
    'zh': '每行为一间单独预订的房间。不用的行请留空。'
  },
  'bulk.addGuest': {'vi': 'Thêm khách', 'en': 'Add guest', 'zh': '添加客人'},
  'bulk.bookAll': {'vi': 'Đặt tất cả', 'en': 'Book all', 'zh': '全部预订'},
  'bulk.guestN': {'vi': 'Khách {n}', 'en': 'Guest {n}', 'zh': '客人 {n}'},
  'bulk.resultSummary': {
    'vi': 'Đã tạo {ok}/{total} đơn. Vào "Đơn của tôi" để thanh toán từng đơn.',
    'en': 'Created {ok}/{total} bookings. Go to "My bookings" to pay each one.',
    'zh': '已创建 {ok}/{total} 个订单。前往"我的订单"逐一支付。'
  },

  // ---------------- Chuyến đi / Gợi ý (trip.*) ----------------
  'trip.enterDestAirport': {
    'vi': 'Nhập điểm đến và mã sân bay xuất phát (vd SGN)',
    'en': 'Enter destination and departure airport code (e.g. SGN)',
    'zh': '请输入目的地和出发机场代码（例如 SGN）'
  },
  'trip.returnAfterDepart': {'vi': 'Ngày về phải sau ngày đi', 'en': 'Return date must be after departure date', 'zh': '返程日期必须晚于出发日期'},
  'trip.searchFail': {
    'vi': 'Không tìm được gói chuyến đi, thử lại.',
    'en': 'Could not find a trip package, try again.',
    'zh': '未能找到行程套餐，请重试。'
  },
  'trip.hotelNoRooms': {
    'vi': 'Khách sạn đã chọn chưa có phòng để đặt. Vui lòng chọn KS khác.',
    'en': 'The selected hotel has no rooms available. Please choose another hotel.',
    'zh': '所选酒店暂无可订房间。请选择其他酒店。'
  },
  'trip.bookPackFail': {'vi': 'Không đặt được gói: {err}', 'en': 'Could not book the package: {err}', 'zh': '无法预订套餐：{err}'},
  'trip.packageTitle': {'vi': 'Kế hoạch chuyến đi trọn gói', 'en': 'Full trip plan', 'zh': '一站式行程规划'},
  // --- AI hướng dẫn viên du lịch (/trip-guide) ---
  'trip.guideTitle': {'vi': 'Hướng dẫn viên AI', 'en': 'AI travel guide', 'zh': 'AI 旅行向导'},
  'trip.guideGreeting': {
    'vi': 'Chào bạn! Mình là hướng dẫn viên du lịch của Dididi. Hỏi mình về lịch trình theo giờ, đi lại, ăn uống, ngân sách hay nên mang gì nhé.',
    'en': "Hi! I'm Dididi's travel guide. Ask me about hour-by-hour itineraries, getting around, food, budget or what to pack.",
    'zh': '你好！我是 Dididi 的旅行向导。可以问我按小时的行程、交通、美食、预算或行李清单。'
  },
  'trip.guideInputHint': {
    'vi': 'Hỏi về điểm đến, lịch trình, ăn uống…',
    'en': 'Ask about destinations, itineraries, food…',
    'zh': '询问目的地、行程、美食…'
  },
  'trip.guideByAi': {'vi': 'Trả lời bởi AI', 'en': 'Answered by AI', 'zh': '由 AI 生成'},
  'trip.guideFailed': {
    'vi': 'Chưa kết nối được hướng dẫn viên. Bạn thử lại sau nhé.',
    'en': "Couldn't reach the guide. Please try again later.",
    'zh': '暂时无法连接向导，请稍后再试。'
  },
  'trip.guideStarter1': {
    'vi': 'Lịch trình 3 ngày ở Đà Nẵng',
    'en': '3-day itinerary in Da Nang',
    'zh': '岘港 3 天行程'
  },
  'trip.guideStarter2': {
    'vi': 'Ăn gì ở Hà Nội?',
    'en': 'What to eat in Hanoi?',
    'zh': '河内有什么美食？'
  },
  'trip.guideStarter3': {
    'vi': 'Đi Đà Lạt mùa này nên mang gì?',
    'en': 'What to pack for Da Lat this season?',
    'zh': '这个季节去大叻要带什么？'
  },
  'trip.guideStarter4': {
    'vi': 'Ngân sách 5 triệu đi đâu 2 ngày?',
    'en': 'Where to go for 2 days on a 5M VND budget?',
    'zh': '预算 500 万越南盾，2 天去哪里？'
  },
  'trip.guideBannerTitle': {
    'vi': 'Hướng dẫn viên AI',
    'en': 'AI travel guide',
    'zh': 'AI 旅行向导'
  },
  'trip.guideBannerMsg': {
    'vi': 'Hỏi lịch trình, ăn uống, đi lại — trả lời ngay.',
    'en': 'Ask about itineraries, food, transport — instant answers.',
    'zh': '行程、美食、交通，随问随答。'
  },
  'trip.formIntro': {
    'vi': 'Chọn chuyến bay đi + về và khách sạn trong 1 lần, thanh toán lần lượt.',
    'en': 'Choose outbound + return flights and a hotel at once, pay one by one.',
    'zh': '一次选择去程+返程航班和酒店，逐一支付。'
  },
  'trip.destLabel': {'vi': 'Điểm đến (vd Đà Nẵng)', 'en': 'Destination (e.g. Da Nang)', 'zh': '目的地（例如岘港）'},
  'trip.fromAirport': {'vi': 'Bay từ (mã sân bay, vd SGN)', 'en': 'Fly from (airport code, e.g. SGN)', 'zh': '出发机场（代码，例如 SGN）'},
  'trip.returnDate': {'vi': 'Ngày về', 'en': 'Return date', 'zh': '返程日期'},
  'trip.searchPackage': {'vi': 'Tìm gói chuyến đi', 'en': 'Find trip package', 'zh': '查找行程套餐'},
  'trip.outboundFlight': {'vi': 'Chuyến bay đi', 'en': 'Outbound flight', 'zh': '去程航班'},
  'trip.returnFlight': {'vi': 'Chuyến bay về', 'en': 'Return flight', 'zh': '返程航班'},
  'trip.noOutbound': {'vi': 'Không có chuyến bay đi phù hợp.', 'en': 'No matching outbound flights.', 'zh': '没有匹配的去程航班。'},
  'trip.noReturn': {'vi': 'Không có chuyến bay về phù hợp.', 'en': 'No matching return flights.', 'zh': '没有匹配的返程航班。'},
  'trip.hotelsInCity': {'vi': 'Khách sạn ở {city} ({n} đêm)', 'en': 'Hotels in {city} ({n} nights)', 'zh': '{city}的酒店（{n} 晚）'},
  'trip.noHotel': {'vi': 'Không có khách sạn phù hợp.', 'en': 'No matching hotels.', 'zh': '没有匹配的酒店。'},
  'trip.bookPackage': {'vi': 'Đặt trọn gói', 'en': 'Book package', 'zh': '预订套餐'},
  'trip.allPaid': {'vi': 'Đã thanh toán toàn bộ chuyến đi!', 'en': 'The whole trip has been paid!', 'zh': '整个行程已支付完成！'},
  'trip.threeCreated': {
    'vi': 'Đã tạo 3 đơn. Thanh toán lần lượt bên dưới.',
    'en': '3 bookings created. Pay them one by one below.',
    'zh': '已创建 3 个订单。请在下方逐一支付。'
  },
  'trip.enterCity': {'vi': 'Nhập thành phố điểm đến', 'en': 'Enter destination city', 'zh': '请输入目的地城市'},
  'trip.suggestFail': {'vi': 'Không lấy được gợi ý, thử lại.', 'en': 'Could not get suggestions, try again.', 'zh': '未能获取推荐，请重试。'},
  'trip.packageCard': {'vi': 'Kế hoạch trọn gói', 'en': 'Full package plan', 'zh': '一站式套餐'},
  'trip.packageCardSub': {
    'vi': 'Chọn chuyến bay đi + về + khách sạn, đặt & trả tuần tự',
    'en': 'Choose outbound + return flights + hotel, book & pay in sequence',
    'zh': '选择去程+返程航班+酒店，依次预订并支付'
  },
  'trip.cityLabel': {'vi': 'Thành phố điểm đến (vd Đà Nẵng)', 'en': 'Destination city (e.g. Da Nang)', 'zh': '目的地城市（例如岘港）'},
  'trip.fromAirportOptional': {
    'vi': 'Bay từ (mã sân bay, vd SGN) — không bắt buộc',
    'en': 'Fly from (airport code, e.g. SGN) — optional',
    'zh': '出发机场（代码，例如 SGN）——可选'
  },
  'trip.suggestBtn': {'vi': 'Gợi ý chuyến bay + khách sạn', 'en': 'Suggest flights + hotels', 'zh': '推荐航班+酒店'},
  'trip.destination': {'vi': 'Điểm đến', 'en': 'Destination', 'zh': '目的地'},
  'trip.suggestedFlights': {'vi': 'Chuyến bay gợi ý', 'en': 'Suggested flights', 'zh': '推荐航班'},
  'trip.suggestedHotels': {'vi': 'Khách sạn gợi ý', 'en': 'Suggested hotels', 'zh': '推荐酒店'},
};
