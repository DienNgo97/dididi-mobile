import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n.dart';

/// Bối cảnh tìm kiếm khách sạn (ngày + số khách/phòng) — chia sẻ giữa màn tìm & màn đặt phòng.
class HotelSearch {
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final int rooms;

  /// true = chỗ ở trong ngày (đặt theo giờ); false = qua đêm.
  final bool dayUse;

  const HotelSearch({
    required this.checkIn,
    required this.checkOut,
    this.adults = 2,
    this.children = 0,
    this.rooms = 1,
    this.dayUse = false,
  });

  HotelSearch copyWith({DateTime? checkIn, DateTime? checkOut, int? adults, int? children, int? rooms, bool? dayUse}) =>
      HotelSearch(
        checkIn: checkIn ?? this.checkIn,
        checkOut: checkOut ?? this.checkOut,
        adults: adults ?? this.adults,
        children: children ?? this.children,
        rooms: rooms ?? this.rooms,
        dayUse: dayUse ?? this.dayUse,
      );

  String guestLabel() {
    final c = children > 0 ? ' · ${trg('hotel.childrenCount').replaceAll('{n}', '$children')}' : '';
    return '${trg('hotel.adultsCount').replaceAll('{n}', '$adults')}$c · ${trg('hotel.roomsCount').replaceAll('{n}', '$rooms')}';
  }
}

final hotelSearchProvider = StateProvider<HotelSearch>((ref) {
  final now = DateTime.now();
  final ci = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  return HotelSearch(checkIn: ci, checkOut: ci.add(const Duration(days: 1)));
});
