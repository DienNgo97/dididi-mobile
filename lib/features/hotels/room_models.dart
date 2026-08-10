import '../../shared/format.dart';

/// Loại phòng của 1 khách sạn (khớp RoomTypeItem của backend).
class RoomType {
  final int id;
  final int? hotelId;
  final String name;
  final String? description;
  final int? capacity;
  final num? basePrice;
  final String? currency;
  final int? totalRooms;

  RoomType({
    required this.id,
    this.hotelId,
    required this.name,
    this.description,
    this.capacity,
    this.basePrice,
    this.currency,
    this.totalRooms,
  });

  factory RoomType.fromJson(Map<String, dynamic> j) => RoomType(
        id: (j['id'] as num).toInt(),
        hotelId: asNum(j['hotelId'])?.toInt(),
        name: (j['name'] ?? '') as String,
        description: j['description'] as String?,
        capacity: asNum(j['capacity'])?.toInt(),
        basePrice: asNum(j['basePrice']),
        currency: j['currency'] as String?,
        totalRooms: asNum(j['totalRooms'])?.toInt(),
      );
}
