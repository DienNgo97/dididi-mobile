import '../../shared/format.dart';

class Review {
  final int id;
  final int rating;
  final String? comment;
  final String? reviewerName;
  final String? vendorReply;
  final DateTime? createdAt;
  Review({required this.id, this.rating = 0, this.comment, this.reviewerName, this.vendorReply, this.createdAt});
  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: (j['id'] as num).toInt(),
        rating: asNum(j['rating'])?.toInt() ?? 0,
        comment: j['comment'] as String?,
        reviewerName: j['reviewerName'] as String?,
        vendorReply: j['vendorReply'] as String?,
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse(j['createdAt'].toString()),
      );
}

/// Điểm trung bình + danh sách review của 1 khách sạn/chuyến bay.
class ReviewSummary {
  final double avg;
  final int count;
  final List<Review> items;
  ReviewSummary({this.avg = 0, this.count = 0, this.items = const []});
  factory ReviewSummary.fromJson(Map<String, dynamic> j) {
    final r = j['reviews'] as Map<String, dynamic>?;
    return ReviewSummary(
      avg: asNum(j['averageRating'])?.toDouble() ?? 0,
      count: asNum(r?['totalElements'])?.toInt() ?? 0,
      items: ((r?['content'] as List?) ?? const [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
