import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../auth/auth_providers.dart';
import 'support_models.dart';

final supportRepositoryProvider =
    Provider<SupportRepository>((ref) => SupportRepository(ref.watch(apiClientProvider)));

class SupportRepository {
  final ApiClient _api;
  SupportRepository(this._api);

  /// Hỏi trợ lý CSKH. [cid] = id hội thoại do client tự sinh (giữ nguyên cả phiên).
  Future<SupportAnswer> ask(String q, String cid) => _api.postData<SupportAnswer>(
        '/api/v1/support/ask',
        body: {'q': q, 'cid': cid},
        parse: (d) => SupportAnswer.fromJson(d as Map<String, dynamic>),
      );
}
