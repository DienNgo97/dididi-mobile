import '../../shared/format.dart';

class Booking {
  final String publicCode;
  final String type; // HOTEL | FLIGHT
  final String? title;
  final String status; // PENDING_PAYMENT | CONFIRMED | CANCELLED | FAILED
  final String? checkIn;
  final String? checkOut;
  final int quantity;
  final num? amount;
  final String? currency;
  final int? groupId; // != null nếu là đơn thuộc nhóm

  Booking({
    required this.publicCode,
    required this.type,
    this.title,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.quantity = 1,
    this.amount,
    this.currency,
    this.groupId,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        publicCode: (j['publicCode'] ?? '') as String,
        type: (j['type'] ?? '') as String,
        title: j['title'] as String?,
        status: (j['status'] ?? '') as String,
        checkIn: j['checkIn']?.toString(),
        checkOut: j['checkOut']?.toString(),
        quantity: asNum(j['quantity'])?.toInt() ?? 1,
        amount: asNum(j['amount']),
        currency: j['currency'] as String?,
        groupId: asNum(j['groupId'])?.toInt(),
      );

  String get statusLabel => switch (status) {
        'CONFIRMED' => 'Đã xác nhận',
        'PENDING_PAYMENT' => 'Chờ thanh toán',
        'CANCELLED' => 'Đã huỷ',
        'FAILED' => 'Hết hạn/Thất bại',
        _ => status,
      };
}
