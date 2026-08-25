import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class KritikSaranRepository {
  final ApiClient apiClient;

  KritikSaranRepository({required this.apiClient});

  /// POST /api/kritik-saran
  ///
  /// The backend determines an optional authenticated user from the bearer
  /// token; no user identifier is sent by the client.
  Future<void> submit({required String kritik, required String saran}) async {
    try {
      final response = await apiClient.dio.post(
        '/kritik-saran',
        data: {'kritik': kritik, 'saran': saran},
      );
      final data = response.data;
      if (response.statusCode != 201 ||
          data is! Map ||
          data['success'] != true) {
        throw ApiException(
          message: 'Format respons kritik dan saran tidak valid.',
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<Map<String, dynamic>>> getAdminFeedback() =>
      _getList('/admin/kritik-saran');

  Future<void> reply({required int id, required String balasan}) async {
    try {
      await apiClient.dio.post(
        '/admin/kritik-saran/$id/reply',
        data: {'balasan': balasan},
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    try {
      final response = await apiClient.dio.get(path);
      final body = response.data;
      final payload = body is Map ? body['data'] : null;
      final rows = payload is Map ? payload['data'] : payload;
      if (rows is! List) return const [];
      return rows
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}

final kritikSaranRepositoryProvider = Provider<KritikSaranRepository>((ref) {
  return KritikSaranRepository(apiClient: ref.watch(apiClientProvider));
});
