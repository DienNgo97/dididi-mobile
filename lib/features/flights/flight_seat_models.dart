import '../../shared/format.dart';

/// Một ghế trong sơ đồ (khớp SeatItem). status = FREE | HELD | BOOKED.
class SeatItem {
  final String code;
  final int row;
  final String col;
  final String? seatClass; // BUSINESS | ECONOMY
  final String? position; // WINDOW | AISLE | MIDDLE
  final num? price;
  final String status;
  SeatItem({
    required this.code,
    required this.row,
    required this.col,
    this.seatClass,
    this.position,
    this.price,
    this.status = 'FREE',
  });
  factory SeatItem.fromJson(Map<String, dynamic> j) => SeatItem(
        code: (j['code'] ?? '') as String,
        row: asNum(j['row'])?.toInt() ?? 0,
        col: (j['col'] ?? '') as String,
        seatClass: j['seatClass'] as String?,
        position: j['position'] as String?,
        price: asNum(j['price']),
        status: (j['status'] ?? 'FREE') as String,
      );
  bool get free => status == 'FREE';
  bool get business => seatClass == 'BUSINESS';
}

/// Sơ đồ ghế của chuyến (khớp SeatMapResult).
class SeatMap {
  final int rows;
  final List<String> cols;
  final int businessRows;
  final List<SeatItem> seats;
  SeatMap({this.rows = 0, this.cols = const [], this.businessRows = 0, this.seats = const []});
  factory SeatMap.fromJson(Map<String, dynamic> j) => SeatMap(
        rows: asNum(j['rows'])?.toInt() ?? 0,
        cols: ((j['cols'] as List?) ?? const []).map((e) => e.toString()).toList(),
        businessRows: asNum(j['businessRows'])?.toInt() ?? 0,
        seats: ((j['seats'] as List?) ?? const [])
            .map((e) => SeatItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  SeatItem? at(int row, String col) {
    for (final s in seats) {
      if (s.row == row && s.col == col) return s;
    }
    return null;
  }
}

/// Lựa chọn suất ăn / hành lý (khớp FlightAddons.Option).
class Addon {
  final String code;
  final String label;
  final num price;
  Addon({required this.code, required this.label, this.price = 0});
  factory Addon.fromJson(Map<String, dynamic> j) => Addon(
        code: (j['code'] ?? '') as String,
        label: (j['label'] ?? '') as String,
        price: asNum(j['price']) ?? 0,
      );
}

class FlightAddonsData {
  final List<Addon> meals;
  final List<Addon> bags;
  FlightAddonsData({this.meals = const [], this.bags = const []});
  factory FlightAddonsData.fromJson(Map<String, dynamic> j) => FlightAddonsData(
        meals: ((j['meals'] as List?) ?? const []).map((e) => Addon.fromJson(e as Map<String, dynamic>)).toList(),
        bags: ((j['bags'] as List?) ?? const []).map((e) => Addon.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
