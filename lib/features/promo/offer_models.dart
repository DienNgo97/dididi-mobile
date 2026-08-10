/// Một ưu đãi cá nhân hoá của tôi (khớp GET /api/v1/offers).
/// Voucher tặng riêng (sinh nhật / quay lại / tri ân hạng / chào mừng) và voucher đổi điểm
/// đều nằm chung ở đây — dùng bằng cách nhập mã ở bước thanh toán.
class Offer {
  final String code;
  final String? description;
  final String discountType; // PERCENT | AMOUNT
  final num? discountValue;
  final num? maxDiscount;
  final num? minOrderAmount;
  final DateTime? validTo;
  final bool usable; // còn hiệu lực & chưa dùng

  const Offer({
    required this.code,
    this.description,
    this.discountType = 'AMOUNT',
    this.discountValue,
    this.maxDiscount,
    this.minOrderAmount,
    this.validTo,
    this.usable = false,
  });

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        code: (j['code'] ?? '') as String,
        description: j['description'] as String?,
        discountType: (j['discountType'] ?? 'AMOUNT') as String,
        discountValue: j['discountValue'] as num?,
        maxDiscount: j['maxDiscount'] as num?,
        minOrderAmount: j['minOrderAmount'] as num?,
        validTo: j['validTo'] == null ? null : DateTime.tryParse('${j['validTo']}')?.toLocal(),
        usable: (j['usable'] ?? false) as bool,
      );

  bool get isPercent => discountType == 'PERCENT';
}
