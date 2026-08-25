import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/notifications/repositories/notification_repository.dart';

class _MemoryStorage extends SecureStorageService {
  Set<int>? acknowledged;

  @override
  Future<String?> getToken() async => 'token';

  @override
  Future<Set<int>?> getMobileNotificationReadIds(int userId) async =>
      acknowledged == null ? null : {...acknowledged!};

  @override
  Future<void> saveMobileNotificationReadIds(
    int userId,
    Iterable<int> ids,
  ) async => acknowledged = ids.toSet();
}

class _Adapter implements HttpClientAdapter {
  dynamic body;

  _Adapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(options.method == 'GET' ? body : {'success': true}),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _inbox({required bool secondReadOnServer}) => {
  'success': true,
  'data': {
    'data': [
      {
        'id': 2,
        'judul': 'Balasan baru',
        'message': 'Admin membalas konsultasi.',
        'type': 'konsultasi_response',
        'read': secondReadOnServer,
      },
      {
        'id': 1,
        'judul': 'Lama',
        'message': 'Sudah dibuka sebelum aplikasi diinisialisasi.',
        'type': 'informasi',
        'read': true,
      },
    ],
  },
};

void main() {
  test('read website tidak menghapus unread khusus perangkat mobile', () async {
    final storage = _MemoryStorage();
    final adapter = _Adapter(_inbox(secondReadOnServer: false));
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = NotificationRepository(
      apiClient: ApiClient(
        secureStorageService: storage,
        baseUrl: 'https://example.invalid/api',
        dioOverride: dio,
      ),
      storage: storage,
      userId: 7,
    );

    final initial = await repository.getNotifications();
    expect(initial.first.isRead, isFalse);
    expect(initial.last.isRead, isTrue);

    // The same notification is opened on the website. Mobile must retain its
    // own unread badge until the user opens it on this device.
    adapter.body = _inbox(secondReadOnServer: true);
    final afterWebsiteRead = await repository.getNotifications();
    expect(afterWebsiteRead.first.isRead, isFalse);

    await repository.markRead(2);
    final afterMobileRead = await repository.getNotifications();
    expect(afterMobileRead.first.isRead, isTrue);
  });
}
