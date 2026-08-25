import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';

class _TokenStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'cache-test-token';
}

class _CountingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests;

  _CountingAdapter(this.requests);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'request_number': requests.length}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _clientWithCounter(List<RequestOptions> requests) {
  final dio = Dio()..httpClientAdapter = _CountingAdapter(requests);
  final client = ApiClient(
    secureStorageService: _TokenStorage(),
    dioOverride: dio,
  );
  return client;
}

void main() {
  test('GET cache is isolated per endpoint page', () async {
    final requests = <RequestOptions>[];
    final client = _clientWithCounter(requests);

    final first = await client.dio.get('/konsul', queryParameters: {'page': 1});
    final cached = await client.dio.get(
      '/konsul',
      queryParameters: {'page': 1},
    );
    final secondPage = await client.dio.get(
      '/konsul',
      queryParameters: {'page': 2},
    );

    expect(first.data['request_number'], 1);
    expect(cached.data['request_number'], 1);
    expect(cached.extra['memoryCache'], true);
    expect(secondPage.data['request_number'], 2);
    expect(requests, hasLength(2));
  });

  test(
    'mutation invalidates cache and a forced refresh seeds it again',
    () async {
      final requests = <RequestOptions>[];
      final client = _clientWithCounter(requests);

      await client.dio.get('/dashboard');
      await client.dio.get('/dashboard');
      expect(requests, hasLength(1));

      await client.dio.post('/konsul', data: {'judul': 'Tes'});
      final afterMutation = await client.dio.get('/dashboard');
      expect(afterMutation.data['request_number'], 3);

      final forced = await client.dio.get(
        '/dashboard',
        options: Options(extra: {'skipShortCache': true}),
      );
      final cachedForced = await client.dio.get('/dashboard');

      expect(forced.data['request_number'], 4);
      expect(cachedForced.data['request_number'], 4);
      expect(cachedForced.extra['memoryCache'], true);
      expect(requests, hasLength(4));
    },
  );
}
