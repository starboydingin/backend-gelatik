import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class RatingRepository {
  final ApiClient apiClient;
  RatingRepository({required this.apiClient});

  Future<int?> getRating() async {
    try {
      final response = await apiClient.dio.get('/rating');
      final root = response.data;
      final data = root is Map ? root['data'] : null;
      if (data == null) return null;
      return int.tryParse(
        '${data is Map ? data['rating'] ?? data['nilai'] : ''}',
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> saveRating(int value, {required bool exists}) async {
    try {
      await apiClient.dio.post(
        exists ? '/rating/update' : '/rating',
        data: {'rating': value},
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepository(apiClient: ref.watch(apiClientProvider));
});
