import '../../shared/format.dart';

/// Chuyến bay (khớp FlightApiDto của backend).
class Flight {
  final int id;
  final String flightNumber;
  final String? airlineCode;
  final String from;
  final String to;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final num? price;
  final String? currency;
  final int? availableSeats;
  final String? aircraftType;

  Flight({
    required this.id,
    required this.flightNumber,
    this.airlineCode,
    required this.from,
    required this.to,
    this.departureTime,
    this.arrivalTime,
    this.price,
    this.currency,
    this.availableSeats,
    this.aircraftType,
  });

  factory Flight.fromJson(Map<String, dynamic> j) => Flight(
        id: (j['id'] as num).toInt(),
        flightNumber: (j['flightNumber'] ?? '') as String,
        airlineCode: j['airlineCode'] as String?,
        from: (j['from'] ?? '') as String,
        to: (j['to'] ?? '') as String,
        departureTime: _dt(j['departureTime']),
        arrivalTime: _dt(j['arrivalTime']),
        price: asNum(j['price']),
        currency: j['currency'] as String?,
        availableSeats: asNum(j['availableSeats'])?.toInt(),
        aircraftType: j['aircraftType'] as String?,
      );

  static DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
}
