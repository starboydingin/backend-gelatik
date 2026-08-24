import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  /// GET /api/opd
  Future<List<String>> getOpds() async {
    try {
      final response = await apiClient.dio.get('/opd');
      final responseData = response.data;
      final dynamic rawItems = responseData is Map
          ? responseData['data']
          : responseData;

      if (rawItems is! List) {
        throw ApiException(message: 'Format response daftar OPD tidak valid.');
      }

      final opds = <String>[];
      for (final item in rawItems) {
        final String? name;
        if (item is String) {
          name = item.trim();
        } else if (item is Map) {
          final value = item['nama_opd'] ?? item['nama'] ?? item['name'];
          name = value?.toString().trim();
        } else {
          name = null;
        }

        if (name != null && name.isNotEmpty && !opds.contains(name)) {
          opds.add(name);
        }
      }

      return opds;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/login
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/login',
        data: {'identifier': identifier, 'password': password},
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
  Future<Map<String, dynamic>> register({
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
      final data = response.data;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data is Map<String, dynamic> &&
          data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      throw ApiException(message: 'Format response register tidak valid.');
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

  /// PATCH /api/me
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String noHp,
    required String namaOpd,
  }) async {
    try {
      final response = await apiClient.dio.patch(
        '/me',
        data: {
          'name': name,
          'email': email,
          'no_hp': noHp,
          'nama_opd': namaOpd,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      throw ApiException(message: 'Format respons profil tidak valid.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/me/change-password for an already authenticated account.
  Future<String> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/me/change-password',
        data: {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return data['message']?.toString() ?? 'Kata sandi berhasil diperbarui.';
      }
      throw ApiException(message: 'Kata sandi tidak dapat diperbarui.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/forgot-password
  Future<Map<String, dynamic>> requestPasswordReset(String identifier) async {
    try {
      final response = await apiClient.dio.post(
        '/forgot-password',
        data: {'identifier': identifier},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        if (data['data'] is Map) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
      }
      throw ApiException(message: 'Permintaan reset kata sandi gagal.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> verifyPasswordResetOtp({
    required String challengeId,
    required String otp,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/forgot-password/verify',
        data: {'challenge_id': challengeId, 'otp': otp},
      );
      final data = response.data;
      final resetData = data is Map ? data['data'] : null;
      if (data is Map && data['success'] == true && resetData is Map) {
        return resetData['reset_token']?.toString() ?? '';
      }
      throw ApiException(message: 'Verifikasi kode gagal.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/reset-password
  Future<String> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/reset-password',
        data: {
          'reset_token': resetToken,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return data['message']?.toString() ?? 'Kata sandi berhasil diperbarui.';
      }
      throw ApiException(message: 'Reset kata sandi gagal.');
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
