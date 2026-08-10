import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Lưu access/refresh token an toàn (Keychain iOS / Keystore Android).
class TokenStorage {
  static const _kAccess = 'dd_access_token';
  static const _kRefresh = 'dd_refresh_token';

  final FlutterSecureStorage _s = const FlutterSecureStorage();

  Future<void> save({required String access, required String refresh}) async {
    await _s.write(key: _kAccess, value: access);
    await _s.write(key: _kRefresh, value: refresh);
  }

  Future<String?> get access => _s.read(key: _kAccess);
  Future<String?> get refresh => _s.read(key: _kRefresh);
  Future<bool> get hasToken async => (await access)?.isNotEmpty ?? false;

  Future<void> clear() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
  }
}
