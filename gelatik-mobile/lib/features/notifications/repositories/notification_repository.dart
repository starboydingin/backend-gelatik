import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/gelatik_notification.dart';

class NotificationRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;
  final int userId;

  NotificationRepository({
    required this.apiClient,
    required this.storage,
    required this.userId,
  });

  Future<List<GelatikNotification>> getNotifications() async {
    try {
      final response = await apiClient.dio.get(
        '/notifications',
        options: Options(extra: {'skipShortCache': true}),
      );
      final root = response.data;
      final data = root is Map ? root['data'] : root;
      final entries = data is Map ? data['data'] : data;
      if (entries is! List) {
        throw ApiException(message: 'Format notifikasi tidak valid.');
      }
      final notifications = entries
          .whereType<Map>()
          .map(
            (item) =>
                GelatikNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
      return _applyMobileReadState(notifications);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await apiClient.dio.post('/notifications/$id/read');
      await _acknowledge([id]);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> markAllRead(Iterable<int> ids) async {
    try {
      await apiClient.dio.post('/notifications/read-all');
      await _acknowledge(ids);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<GelatikNotification>> _applyMobileReadState(
    List<GelatikNotification> notifications,
  ) async {
    if (userId < 1) return notifications;
    var acknowledged = await storage.getMobileNotificationReadIds(userId);
    if (acknowledged == null) {
      // On first use, preserve the server's current unread set as the initial
      // mobile badge. From this point onward the mobile device is authoritative
      // for its own acknowledgement state.
      acknowledged = notifications
          .where((item) => item.isRead)
          .map((item) => item.id)
          .toSet();
      await storage.saveMobileNotificationReadIds(userId, acknowledged);
    }
    return notifications
        .map((item) => item.copyWith(isRead: acknowledged!.contains(item.id)))
        .toList(growable: false);
  }

  Future<void> _acknowledge(Iterable<int> ids) async {
    if (userId < 1) return;
    final acknowledged =
        await storage.getMobileNotificationReadIds(userId) ?? <int>{};
    acknowledged.addAll(ids.where((id) => id > 0));
    await storage.saveMobileNotificationReadIds(userId, acknowledged);
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageServiceProvider),
    userId: ref.watch(
      authProvider.select((state) => state.currentUser?.id ?? 0),
    ),
  );
});
