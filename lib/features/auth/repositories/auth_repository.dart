import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  /// POST /api/login
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Map<String, dynamic>.from(data['data']);
      }
      throw ApiException(message: 'Format response login tidak valid.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/register
  Future<bool> register({
    required String name,
    required String email,
    required String nip,
    required String noHp,
    required String namaOpd,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'nip': nip,
          'no_hp': noHp,
          'nama_opd': namaOpd,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /api/me
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await apiClient.dio.get('/me');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return Map<String, dynamic>.from(data['data']);
      }
      throw ApiException(message: 'Format response me tidak valid.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/logout
  Future<void> logout() async {
    try {
      await apiClient.dio.post('/logout');
    } on DioException catch (_) {
      // Ignored or logged if token already invalidated on backend
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient: apiClient);
});
