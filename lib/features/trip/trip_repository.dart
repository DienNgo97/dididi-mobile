import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../core/network/api_client.dart';
import 'trip_models.dart';

final tripRepositoryProvider =
    Provider<TripRepository>((ref) => TripRepository(ref.watch(apiClientProvider)));

class TripRepository {
  final ApiClient _api;
  TripRepository(this._api);

  Future<TripSuggestion> suggest(String city, {String? from}) => _api.postData(
        '/api/v1/trip-planner/suggest',
        body: {'city': city, if (from != null && from.isNotEmpty) 'from': from},
        parse: (d) => TripSuggestion.fromJson(d as Map<String, dynamic>),
      );

  /// AI hướng dẫn viên du lịch: hỏi tự do (lịch trình theo giờ, đi lại, ăn uống, ngân sách...).
  /// Backend hybrid KB 12 thành phố + LLM tuỳ chọn; endpoint permitAll nên KHÁCH cũng hỏi được.
  Future<TripGuideAnswer> guide(String q) => _api.postData(
        '/api/v1/trip-planner/guide',
        body: {'q': q},
        parse: (d) => TripGuideAnswer.fromJson(d as Map<String, dynamic>),
      );
}
