import '../../shared/format.dart';

class HotelAmenity {
  final String code;
  final String name;
  final String icon;
  HotelAmenity(this.code, this.name, this.icon);
  factory HotelAmenity.fromJson(Map<String, dynamic> j) =>
      HotelAmenity((j['code'] ?? '') as String, (j['name'] ?? '') as String, (j['icon'] ?? '') as String);
}

class Hotel {
  final int id;
  final String name;
  final String? city;
  final String? address;
  final double? lat;
  final double? lng;
  final String? description;
  final int? starRating;
  final num? minPrice;
  final String? currency;
  final String? propertyTypeName;
  final List<HotelAmenity> amenities;
  final List<String> tags;
  final double? avgRating; // điểm đánh giá TB (null/0 nếu chưa có)

  Hotel({
    required this.id,
    required this.name,
    this.city,
    this.address,
    this.lat,
    this.lng,
    this.description,
    this.starRating,
    this.minPrice,
    this.currency,
    this.propertyTypeName,
    this.amenities = const [],
    this.tags = const [],
    this.avgRating,
  });

  factory Hotel.fromJson(Map<String, dynamic> j) => Hotel(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
        city: j['city'] as String?,
        address: j['address'] as String?,
        lat: asNum(j['lat'])?.toDouble(),
        lng: asNum(j['lng'])?.toDouble(),
        description: j['description'] as String?,
        starRating: asNum(j['starRating'])?.toInt(),
        minPrice: asNum(j['minPrice']),
        currency: j['currency'] as String?,
        propertyTypeName: j['propertyTypeName'] as String?,
        amenities: ((j['amenities'] as List?) ?? [])
            .map((e) => HotelAmenity.fromJson(e as Map<String, dynamic>))
            .toList(),
        tags: ((j['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
        avgRating: asNum(j['avgRating'])?.toDouble(),
      );
}
