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
}

final kritikSaranRepositoryProvider = Provider<KritikSaranRepository>((ref) {
  return KritikSaranRepository(apiClient: ref.watch(apiClientProvider));
});
