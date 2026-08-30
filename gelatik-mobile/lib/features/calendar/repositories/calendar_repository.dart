import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class CalendarEvent {
  final String id;
  final String type;
  final String title;
  final DateTime start;
  final String status;
  final int? referenceId;

  const CalendarEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.start,
    required this.status,
    this.referenceId,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'informasi',
      title: json['title']?.toString() ?? 'Informasi layanan',
      start:
          DateTime.tryParse(json['start']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'Informasi',
      referenceId: json['reference_id'] is int
          ? json['reference_id'] as int
          : int.tryParse('${json['reference_id'] ?? ''}'),
    );
  }
}

class CalendarRepository {
  final ApiClient _apiClient;

  CalendarRepository(this._apiClient);

  Future<List<CalendarEvent>> getEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/dashboard/calendar',
        queryParameters: {'start': _dateOnly(start), 'end': _dateOnly(end)},
      );
      final root = response.data;
      final data = root is Map ? root['data'] : null;
      if (data is! List) {
        throw ApiException(message: 'Format agenda tidak valid.');
      }
      return data
          .whereType<Map>()
          .map(
            (item) => CalendarEvent.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepository(ref.watch(apiClientProvider)),
);
