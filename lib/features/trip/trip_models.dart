import '../flights/flight_models.dart';
import '../hotels/hotel_models.dart';

/// Một lượt trả lời của AI hướng dẫn viên du lịch (khớp TripGuideAnswer).
/// `source` = "kb" (tri thức nội bộ) | "llm" (mô hình ngôn ngữ); `suggests` = câu hỏi gợi ý tiếp.
class TripGuideAnswer {
  final String answer;
  final String source;
  final List<String> suggests;
  const TripGuideAnswer({required this.answer, this.source = 'kb', this.suggests = const []});
  factory TripGuideAnswer.fromJson(Map<String, dynamic> j) => TripGuideAnswer(
        answer: (j['answer'] as String?) ?? '',
        source: (j['source'] as String?) ?? 'kb',
        suggests: ((j['suggests'] as List?) ?? const []).map((e) => '$e').toList(),
      );
}

/// Gợi ý chuyến đi = chuyến bay + khách sạn theo thành phố (khớp TripSuggestionDto).
class TripSuggestion {
  final String? city;
  final String? destinationAirport;
  final List<Flight> flights;
  final List<Hotel> hotels;
  TripSuggestion({this.city, this.destinationAirport, this.flights = const [], this.hotels = const []});
  factory TripSuggestion.fromJson(Map<String, dynamic> j) => TripSuggestion(
        city: j['city'] as String?,
        destinationAirport: j['destinationAirport'] as String?,
        flights: ((j['flights'] as List?) ?? const [])
            .map((e) => Flight.fromJson(e as Map<String, dynamic>))
            .toList(),
        hotels: ((j['hotels'] as List?) ?? const [])
            .map((e) => Hotel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
