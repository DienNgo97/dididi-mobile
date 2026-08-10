import '../../shared/format.dart';

/// Kết quả 1 dòng đặt hàng loạt (khớp BulkLineResult).
class BulkLineResult {
  final int no;
  final String guest;
  final String? code;
  final String status; // PENDING_PAYMENT | CONFIRMED | PENDING_APPROVAL | FAILED | SKIPPED
  final String? note;

  BulkLineResult({required this.no, required this.guest, this.code, required this.status, this.note});

  factory BulkLineResult.fromJson(Map<String, dynamic> j) => BulkLineResult(
        no: asNum(j['no'])?.toInt() ?? 0,
        guest: (j['guest'] ?? '') as String,
        code: j['code'] as String?,
        status: (j['status'] ?? '') as String,
        note: j['note'] as String?,
      );

  bool get ok => code != null && (status == 'PENDING_PAYMENT' || status == 'CONFIRMED' || status == 'PENDING_APPROVAL');

  String get statusLabel => switch (status) {
        'PENDING_PAYMENT' => 'Chờ thanh toán',
        'CONFIRMED' => 'Đã xác nhận',
        'PENDING_APPROVAL' => 'Chờ duyệt',
        'FAILED' => 'Thất bại',
        'SKIPPED' => 'Bỏ qua',
        _ => status,
      };
}
