import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../core/network/api_client.dart';
import 'booking_models.dart';

final bookingRepositoryProvider =
    Provider<BookingRepository>((ref) => BookingRepository(ref.watch(apiClientProvider)));

class BookingRepository {
  final ApiClient _api;
  BookingRepository(this._api);

  Future<List<Booking>> myBookings() => _api.getData(
        '/api/v1/bookings/me',
        parse: (d) => ((d as List?) ?? const [])
            .map((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Tạo đơn đặt phòng (PENDING_PAYMENT). Backend tự tính tổng tiền.
  /// [dayUse]=true: đặt theo giờ trong ngày — gửi checkInTime/checkOutTime (HH:mm), checkIn = ngày ở.
  Future<Booking> createHotelBooking({
    required int hotelId,
    required int roomTypeId,
    required String roomName,
    required String guestName,
    required String checkIn, // yyyy-MM-dd
    required String checkOut,
    required int rooms,
    bool dayUse = false,
    String? checkInTime, // HH:mm (khi dayUse)
    String? checkOutTime,
  }) =>
      _api.postData(
        '/api/v1/bookings',
        body: {
          'type': 'HOTEL',
          'hotelId': hotelId,
          'roomTypeId': roomTypeId,
          'roomName': roomName,
          'guestName': guestName,
          'checkIn': checkIn,
          'checkOut': checkOut,
          'rooms': rooms,
          if (dayUse) 'dayUse': true,
          if (dayUse && checkInTime != null) 'checkInTime': checkInTime,
          if (dayUse && checkOutTime != null) 'checkOutTime': checkOutTime,
        },
        parse: (d) => Booking.fromJson(d as Map<String, dynamic>),
      );

  /// Tạo đơn vé máy bay (PENDING_PAYMENT). Backend tự tính tổng tiền.
  Future<Booking> createFlightBooking({
    required int flightId,
    required String passengerName,
    required String contactEmail,
    required int seats,
  }) =>
      _api.postData(
        '/api/v1/bookings',
        body: {
          'type': 'FLIGHT',
          'flightId': flightId,
          'passengerName': passengerName,
          'contactEmail': contactEmail,
          'seats': seats,
        },
        parse: (d) => Booking.fromJson(d as Map<String, dynamic>),
      );

  /// Đặt vé với thông tin TỪNG hành khách (tên + suất ăn + hành lý).
  /// [seatCodes] rỗng với chuyến nội bộ (backend tính số ghế theo số hành khách).
  /// [passengers] = [{name, meal?, bag?}] theo thứ tự ghế. Phụ phí do backend tính lại.
  Future<Booking> bookFlightWithSeats({
    required int flightId,
    required String contactEmail,
    required List<String> seatCodes,
    required List<Map<String, dynamic>> passengers,
  }) =>
      _api.postData(
        '/api/v1/bookings/flight-seats',
        body: {
          'flightId': flightId,
          'contactEmail': contactEmail,
          'seatCodes': seatCodes,
          'passengers': passengers,
        },
        parse: (d) => Booking.fromJson(d as Map<String, dynamic>),
      );

  /// Thanh toán giả lập → đơn chuyển sang CONFIRMED.
  Future<Booking> payMock(String code) => _api.postData(
        '/api/v1/bookings/$code/pay',
        parse: (d) => Booking.fromJson(d as Map<String, dynamic>),
      );

  /// Gửi yêu cầu huỷ đơn (admin duyệt). [reason] tuỳ chọn.
  Future<Booking> cancel(String code, {String? reason}) => _api.postData(
        '/api/v1/bookings/$code/cancel',
        query: {if (reason != null && reason.isNotEmpty) 'reason': reason},
        parse: (d) => Booking.fromJson(d as Map<String, dynamic>),
      );

  /// Lấy URL cổng VNPay cho đơn (mở trên trình duyệt).
  Future<String> vnpayUrl(String code) => _api.postData(
        '/api/v1/bookings/$code/vnpay-url',
        parse: (d) => ((d as Map)['payUrl'] ?? '').toString(),
      );

  /// Lấy trạng thái đơn (để poll sau khi thanh toán VNPay).
  Future<Booking> getBooking(String code) => _api.getData(
        '/api/v1/bookings/$code',
        parse: (d) => Booking.fromJson(d as Map<String, dynamic>),
      );

  /// Sửa đơn KS trực tiếp (đổi ngày/số phòng) khi còn chờ thanh toán — qua đêm.
  Future<Booking> editOvernight(String code, {required String checkIn, required String checkOut, required int rooms}) =>
      _api.postData(
        '/api/v1/bookings/$code/edit',
        body: {'checkIn': checkIn, 'checkOut': checkOut, 'rooms': rooms},
        parse: (d) => Booking.fromJson(d as Map<String, dynamic>),
      );

  /// Áp mã giảm giá cho đơn.
  Future<Booking> applyVoucher(String code, String voucherCode) => _api.postData(
        '/api/v1/bookings/$code/voucher',
        body: {'voucherCode': voucherCode},
        parse: (d) => Booking.fromJson(d as Map<String, dynamic>),
      );

  /// Gỡ mã giảm giá.
  Future<Booking> removeVoucher(String code) => _api.postData(
        '/api/v1/bookings/$code/voucher/remove',
        parse: (d) => Booking.fromJson(d as Map<String, dynamic>),
      );

  /// Tải hoá đơn VAT (PDF) — trả về bytes (đơn đã xác nhận).
  Future<List<int>> invoiceBytes(String code) => _api.getBytes('/api/v1/bookings/$code/invoice');

  /// Thanh toán bằng ngân sách công ty (B2B). Trả về (outcome, đơn cập nhật).
  /// outcome = CONFIRMED (xác nhận ngay) | PENDING_APPROVAL (chờ duyệt chi).
  Future<({String outcome, Booking booking})> payCompany(String code) => _api.postData(
        '/api/v1/bookings/$code/pay-company',
        parse: (d) {
          final m = (d as Map);
          return (
            outcome: (m['outcome'] ?? '').toString(),
            booking: Booking.fromJson((m['booking'] as Map).cast<String, dynamic>()),
          );
        },
      );
}

/// Danh sách đơn của tôi.
final myBookingsProvider = FutureProvider<List<Booking>>(
  (ref) => ref.read(bookingRepositoryProvider).myBookings(),
);
