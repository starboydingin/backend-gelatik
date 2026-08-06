import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _chatbotSessionKey = 'chatbot_session_id';

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
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
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
