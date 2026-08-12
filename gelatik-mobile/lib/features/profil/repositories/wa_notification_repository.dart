import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/wa_subscription_model.dart';

class WaNotificationRepository {
  final ApiClient apiClient;

  WaNotificationRepository({required this.apiClient});

  Future<WaSubscriptionModel> getStatus() async {
    try {
      final response = await apiClient.dio.get('/notifikasi/wa/status');
      return _subscriptionFromEnvelope(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// The backend upserts by authenticated user ID, so a later save replaces
  /// the previously configured WhatsApp number for that account.
  Future<WaSubscriptionModel> save({
    required String waNumber,
    required bool isSubscribed,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/notifikasi/wa/subscribe',
        data: {
          'nomor_wa': waNumber,
          'is_opt_in': isSubscribed,
        },
      );
      return _subscriptionFromEnvelope(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  WaSubscriptionModel _subscriptionFromEnvelope(dynamic response) {
    if (response is! Map || response['success'] != true || response['data'] is! Map) {
      throw const FormatException('Status notifikasi WhatsApp tidak valid.');
    }

    return WaSubscriptionModel.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

final waNotificationRepositoryProvider = Provider<WaNotificationRepository>(
  (ref) => WaNotificationRepository(apiClient: ref.watch(apiClientProvider)),
);
