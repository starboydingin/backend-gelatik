import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/gelatik_notification.dart';

class NotificationRepository {
  final ApiClient apiClient;
  NotificationRepository({required this.apiClient});

  Future<List<GelatikNotification>> getNotifications() async {
    try {
      final response = await apiClient.dio.get('/notifications');
      final root = response.data;
      final data = root is Map ? root['data'] : root;
      final entries = data is Map ? data['data'] : data;
      if (entries is! List) {
        throw ApiException(message: 'Format notifikasi tidak valid.');
      }
      return entries
          .whereType<Map>()
          .map(
            (item) =>
                GelatikNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await apiClient.dio.post('/notifications/$id/read');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      await apiClient.dio.post('/notifications/read-all');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(apiClient: ref.watch(apiClientProvider));
});
