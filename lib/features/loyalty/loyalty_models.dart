import '../../shared/format.dart';

class LoyaltyTxn {
  final int id;
  final String type; // EARN | REDEEM | ADJUST
  final int points;
  final String? description;
  final DateTime? createdAt;
  LoyaltyTxn({required this.id, required this.type, required this.points, this.description, this.createdAt});
  factory LoyaltyTxn.fromJson(Map<String, dynamic> j) => LoyaltyTxn(
        id: (j['id'] as num).toInt(),
        type: (j['type'] ?? '') as String,
        points: asNum(j['points'])?.toInt() ?? 0,
        description: j['description'] as String?,
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse(j['createdAt'].toString()),
      );
}

class RedeemedVoucher {
  final String code;
  final num value;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;
  final bool used;
  RedeemedVoucher({required this.code, this.value = 0, this.redeemedAt, this.expiresAt, this.used = false});
  factory RedeemedVoucher.fromJson(Map<String, dynamic> j) => RedeemedVoucher(
        code: (j['code'] ?? '') as String,
        value: asNum(j['value']) ?? 0,
        redeemedAt: j['redeemedAt'] == null ? null : DateTime.tryParse(j['redeemedAt'].toString()),
        expiresAt: j['expiresAt'] == null ? null : DateTime.tryParse(j['expiresAt'].toString()),
        used: j['used'] == true,
      );
}

class LoyaltyAccount {
  final int balance;
  final String tier;
  final int lifetimeEarned;
  final int minRedeem;
  final int pointValue; // 1 điểm = pointValue đồng khi đổi
  final List<LoyaltyTxn> history;
  LoyaltyAccount({
    this.balance = 0,
    this.tier = 'SILVER',
    this.lifetimeEarned = 0,
    this.minRedeem = 0,
    this.pointValue = 0,
    this.history = const [],
  });
  factory LoyaltyAccount.fromJson(Map<String, dynamic> j) => LoyaltyAccount(
        balance: asNum(j['balance'])?.toInt() ?? 0,
        tier: (j['tier'] ?? 'SILVER') as String,
        lifetimeEarned: asNum(j['lifetimeEarned'])?.toInt() ?? 0,
        minRedeem: asNum(j['minRedeem'])?.toInt() ?? 0,
        pointValue: asNum(j['pointValue'])?.toInt() ?? 0,
        history: ((j['history'] as List?) ?? const [])
            .map((e) => LoyaltyTxn.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
