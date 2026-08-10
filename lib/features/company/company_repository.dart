import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../shared/format.dart';
import '../auth/auth_providers.dart';

/// Thông tin công ty B2B của người dùng (ngân sách còn lại).
class CompanyInfo {
  final String name;
  final String? code;
  final num budgetTotal;
  final num budgetUsed;
  final num budgetRemaining;
  CompanyInfo({
    required this.name,
    this.code,
    this.budgetTotal = 0,
    this.budgetUsed = 0,
    this.budgetRemaining = 0,
  });
  factory CompanyInfo.fromJson(Map<String, dynamic> j) => CompanyInfo(
        name: (j['name'] ?? '') as String,
        code: j['code'] as String?,
        budgetTotal: asNum(j['budgetTotal']) ?? 0,
        budgetUsed: asNum(j['budgetUsed']) ?? 0,
        budgetRemaining: asNum(j['budgetRemaining']) ?? 0,
      );
}

final companyRepositoryProvider =
    Provider<CompanyRepository>((ref) => CompanyRepository(ref.watch(apiClientProvider)));

class CompanyRepository {
  final ApiClient _api;
  CompanyRepository(this._api);

  /// Công ty của tôi — null nếu chưa thuộc công ty nào.
  Future<CompanyInfo?> me() => _api.getData(
        '/api/v1/company/me',
        parse: (d) => d == null ? null : CompanyInfo.fromJson(d as Map<String, dynamic>),
      );

  Future<Map<String, dynamic>> viewInvite(String token) => _api.getData(
        '/api/v1/company-invite/$token',
        parse: (d) => (d as Map).cast<String, dynamic>(),
      );

  Future<String> acceptInvite(String token) => _api.postData(
        '/api/v1/company-invite/$token/accept',
        parse: (d) => ((d as Map)['companyName'] ?? '').toString(),
      );
}

/// Công ty của tôi (dùng để quyết định có hiện nút "Thanh toán bằng công ty").
final companyMeProvider = FutureProvider.autoDispose<CompanyInfo?>((ref) => ref.read(companyRepositoryProvider).me());
