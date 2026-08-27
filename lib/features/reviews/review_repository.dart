import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../core/network/api_client.dart';
import 'review_models.dart';

final reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) => ReviewRepository(ref.watch(apiClientProvider)));

class ReviewRepository {
  final ApiClient _api;
  ReviewRepository(this._api);

  Future<ReviewSummary> hotelReviews(int hotelId) => _api.getData(
        '/api/v1/hotels/$hotelId/reviews',
        query: {'page': 0, 'size': 10},
        parse: (d) => ReviewSummary.fromJson(d as Map<String, dynamic>),
      );

  Future<ReviewSummary> flightReviews(int flightId) => _api.getData(
        '/api/v1/flights/$flightId/reviews',
        query: {'page': 0, 'size': 10},
        parse: (d) => ReviewSummary.fromJson(d as Map<String, dynamic>),
      );

  /// Viết đánh giá cho 1 đơn đã xác nhận. Trả về id đánh giá (để đính ảnh).
  Future<int> create(String bookingCode, int rating, String? comment) => _api.postData<int>(
        '/api/v1/reviews',
        body: {'bookingCode': bookingCode, 'rating': rating, if (comment != null) 'comment': comment},
        parse: (d) => ((d as Map)['id'] as num).toInt(),
      );

  /// Đính ảnh vào 1 đánh giá (multipart field 'files').
  Future<void> uploadImages(int reviewId, List<MultipartFile> files) => _api.postMultipart<void>(
        '/api/v1/reviews/$reviewId/images',
        FormData.fromMap({'files': files}),
        parse: (_) {},
      );
}

final hotelReviewsProvider = FutureProvider.autoDispose
    .family<ReviewSummary, int>((ref, id) => ref.read(reviewRepositoryProvider).hotelReviews(id));
