import 'package:intl/intl.dart';

final _vnd = NumberFormat.decimalPattern('vi_VN');

/// 1510000 -> "1.510.000đ"
String formatVnd(num? v) => v == null ? '—' : '${_vnd.format(v)}đ';

final _ymd = DateFormat('yyyy-MM-dd');
final _dmy = DateFormat('dd/MM/yyyy');
final _hm = DateFormat('HH:mm');
final _dm = DateFormat('dd/MM');

/// DateTime -> "2026-07-02" (gửi cho backend LocalDate).
String ymd(DateTime d) => _ymd.format(d);

/// DateTime -> "02/07/2026" (hiển thị cho người dùng).
String dmy(DateTime d) => _dmy.format(d);

/// Ngày dạng API (yyyy-MM-dd / ISO) -> dd/MM/yyyy để hiển thị.
/// Chuỗi không parse được thì trả nguyên văn (không làm vỡ giao diện).
String dmyStr(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final d = DateTime.tryParse(raw);
  return d == null ? raw : _dmy.format(d);
}

/// DateTime -> "08:30".
String hm(DateTime d) => _hm.format(d);

/// DateTime -> "02/07".
String dm(DateTime d) => _dm.format(d);

/// Thời gian tương đối từ epoch ms: "vừa xong", "5 phút", "2 giờ", "3 ngày", rồi ngày.
String ago(int ms) {
  if (ms <= 0) return '';
  final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
  if (diff.inHours < 24) return '${diff.inHours} giờ';
  if (diff.inDays < 7) return '${diff.inDays} ngày';
  return dmy(DateTime.fromMillisecondsSinceEpoch(ms));
}

num? asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}
