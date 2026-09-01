import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/internet/repositories/internet_repository.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'bandwidth-test-token';
}

class _BandwidthAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'success': true,
      'data': {
        'list_router': const [],
        'bandwidth': {
          'available': true,
          'opd': 'Diskominfotik Lampung',
          'connections': [
            {
              'identity_router': 'Router tanpa metrik',
              'download_mbps': null,
              'upload_mbps': null,
            },
            {
              'identity_router': 'Router Utama',
              'lokasi': 'Ruang NOC',
              'download_mbps': 250,
              'upload_mbps': 100,
            },
          ],
          'user': {
            'available': true,
            'detected': true,
            'name': 'Pengguna Bandwidth',
            'download_mbps': 50,
            'upload_mbps': 20,
            'source': 'user_allocation',
            'source_label': 'Alokasi khusus akun',
            'inherited_from_opd': false,
          },
        },
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'bandwidth selects the first connection that has real metrics',
    () async {
      final dio = Dio()..httpClientAdapter = _BandwidthAdapter();
      final repository = InternetRepository(
        apiClient: ApiClient(
          secureStorageService: _Storage(),
          dioOverride: dio,
        ),
      );

      final overview = await repository.getInternetOverview();
      final bandwidth = overview['bandwidth'] as Map<String, dynamic>;

      expect(bandwidth['available'], isTrue);
      expect(bandwidth['download_mbps'], 250);
      expect(bandwidth['upload_mbps'], 100);
      expect(bandwidth['connection_name'], 'Router Utama');
      expect(bandwidth['connection_count'], 2);
      expect(bandwidth['user'], {
        'available': true,
        'detected': true,
        'name': 'Pengguna Bandwidth',
        'download_mbps': 50,
        'upload_mbps': 20,
        'source': 'user_allocation',
        'source_label': 'Alokasi khusus akun',
        'inherited_from_opd': false,
      });
    },
  );
}
