import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  String? _cachedToken;
  bool _tokenLoaded = false;

  static const String _tokenKey = 'auth_token';
  static const String _chatbotSessionKey = 'chatbot_session_id';
  static const String _notificationReadKeyPrefix =
      'mobile_notification_reads_v1';

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _cachedToken = token;
    _tokenLoaded = true;
  }

  Future<String?> getToken() async {
    if (_tokenLoaded) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    _tokenLoaded = true;
    return _cachedToken;
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    _cachedToken = null;
    _tokenLoaded = true;
    await deleteChatbotSessionId();
  }

  Future<void> saveChatbotSessionId(String sessionId) async {
    await _storage.write(key: _chatbotSessionKey, value: sessionId);
  }

  Future<String?> getChatbotSessionId() async {
    return _storage.read(key: _chatbotSessionKey);
  }

  Future<void> deleteChatbotSessionId() async {
    await _storage.delete(key: _chatbotSessionKey);
  }

  /// Returns `null` until this device has initialized its own notification
  /// read state for the account. Website read-state must not clear this set.
  Future<Set<int>?> getMobileNotificationReadIds(int userId) async {
    final raw = await _storage.read(key: _notificationReadKey(userId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <int>{};
      return decoded
          .map((value) => int.tryParse(value.toString()))
          .whereType<int>()
          .where((value) => value > 0)
          .toSet();
    } catch (_) {
      return <int>{};
    }
  }

  Future<void> saveMobileNotificationReadIds(
    int userId,
    Iterable<int> ids,
  ) async {
    final normalized = ids.where((id) => id > 0).toSet().toList()..sort();
    // Notification IDs are monotonically increasing. Keeping the newest 500
    // bounds secure-storage usage without affecting the visible inbox pages.
    final retained = normalized.length > 500
        ? normalized.sublist(normalized.length - 500)
        : normalized;
    await _storage.write(
      key: _notificationReadKey(userId),
      value: jsonEncode(retained),
    );
  }

  String _notificationReadKey(int userId) =>
      '${_notificationReadKeyPrefix}_$userId';
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
