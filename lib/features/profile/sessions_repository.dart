import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../auth/auth_providers.dart';

/// Một phiên đăng nhập (thiết bị). id = mã băm token, dùng để thu hồi.
class DeviceSession {
  final String id;
  final String device;
  final int createdAtMs;
  final bool current;
  DeviceSession({required this.id, required this.device, required this.createdAtMs, required this.current});
  factory DeviceSession.fromJson(Map<String, dynamic> j) => DeviceSession(
        id: (j['id'] ?? '').toString(),
        device: (j['device'] ?? 'Thiết bị').toString(),
        createdAtMs: int.tryParse('${j['createdAt'] ?? 0}') ?? 0,
        current: j['current'] == true,
      );
}

final sessionsRepositoryProvider = Provider<SessionsRepository>(
    (ref) => SessionsRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)));

final sessionsProvider = FutureProvider.autoDispose<List<DeviceSession>>(
    (ref) => ref.read(sessionsRepositoryProvider).list());

class SessionsRepository {
  final ApiClient _api;
  final TokenStorage _storage;
  SessionsRepository(this._api, this._storage);

  /// Gửi kèm refresh token hiện tại (header) để backend đánh dấu "phiên hiện tại".
  Future<List<DeviceSession>> list() async {
    final refresh = await _storage.refresh;
    return _api.getData(
      '/api/v1/profile/sessions',
      headers: {if (refresh != null && refresh.isNotEmpty) 'X-Refresh-Token': refresh},
      parse: (d) => ((d as List?) ?? const [])
          .map((e) => DeviceSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> revoke(String sessionId) =>
      _api.postData<void>('/api/v1/profile/sessions/$sessionId/revoke', parse: (_) {});
}
