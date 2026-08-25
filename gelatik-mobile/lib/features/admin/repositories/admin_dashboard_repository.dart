import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// The administrator dashboard is delivered as one aggregate response.
/// Keeping this separate from list repositories avoids a dashboard fan-out
/// into users, consultations, loans, and email requests on every visit.
class AdminDashboardRepository {
  final ApiClient _apiClient;

  AdminDashboardRepository(this._apiClient);

  Future<Map<String, dynamic>> getDashboard({bool bypassCache = false}) async {
    try {
      final response = await _apiClient.dio.get(
        '/admin/dashboard',
        options: Options(extra: {'skipShortCache': bypassCache}),
      );
      final root = response.data;
      final data = root is Map ? root['data'] : null;
      if (data is! Map) {
        throw ApiException(message: 'Format dashboard admin tidak valid.');
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>(
  (ref) => AdminDashboardRepository(ref.watch(apiClientProvider)),
);
