import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// Single aggregate request for the signed-in user's dashboard.
///
/// The Laravel endpoint is deliberately the source for KPI and recent activity;
/// this prevents a home visit from fanning out into several independent calls.
class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<Map<String, dynamic>> getDashboard({bool bypassCache = false}) async {
    try {
      final response = await _apiClient.dio.get(
        '/dashboard',
        options: Options(extra: {'skipShortCache': bypassCache}),
      );
      final root = response.data;
      final data = root is Map ? root['data'] : null;
      if (data is! Map) {
        throw ApiException(message: 'Format dashboard tidak valid.');
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});
