import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tolerant wrapper around [FlutterSecureStorage]. A locked or missing
/// keyring (e.g., dev environments without an unlocked gnome-keyring) must
/// not crash the app — failures are logged and treated as "no session".
class AuthSecureStorage {
  AuthSecureStorage(this._storage, this._key);

  final FlutterSecureStorage _storage;
  final String _key;

  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (e, st) {
      debugPrint('AuthSecureStorage.read failed: $e\n$st');
      return null;
    }
  }

  Future<void> write(String value) async {
    try {
      await _storage.write(key: _key, value: value);
    } catch (e, st) {
      debugPrint('AuthSecureStorage.write failed: $e\n$st');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (e, st) {
      debugPrint('AuthSecureStorage.clear failed: $e\n$st');
    }
  }
}
