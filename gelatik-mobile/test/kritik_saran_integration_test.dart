import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/network/api_exception.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/kritik_saran/providers/kritik_saran_provider.dart';
import 'package:gelatik/features/kritik_saran/repositories/kritik_saran_repository.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'feedback-test-token';
}

ApiClient _client({
  required FutureOr<Response<dynamic>> Function(RequestOptions) handler,
}) {
  final client = ApiClient(
    secureStorageService: _Storage(),
    dioOverride: Dio(),
  );
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, interceptor) async {
        try {
          interceptor.resolve(await handler(options));
        } on DioException catch (error) {
          interceptor.reject(error.copyWith(requestOptions: options));
        }
      },
    ),
  );
  return client;
}

class _FakeRepository extends KritikSaranRepository {
  final Future<void> Function(String kritik, String saran) handler;
  int calls = 0;

  _FakeRepository(this.handler)
    : super(apiClient: _client(handler: (_) => throw UnimplementedError()));

  @override
  Future<void> submit({required String kritik, required String saran}) async {
    calls++;
    await handler(kritik, saran);
  }
}

void main() {
  group('KritikSaranRepository', () {
    test(
      'uses the existing endpoint and does not send a user identifier',
      () async {
        RequestOptions? request;
        final repository = KritikSaranRepository(
          apiClient: _client(
            handler: (options) {
              request = options;
              return Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'success': true,
                  'data': {'id': 1},
                },
              );
            },
          ),
        );

        await repository.submit(kritik: 'Kritik', saran: 'Saran');

        expect(request?.path, '/kritik-saran');
        expect(request?.data, {'kritik': 'Kritik', 'saran': 'Saran'});
        expect(request?.headers['Authorization'], 'Bearer feedback-test-token');
      },
    );

    test('maps API validation errors', () async {
      final repository = KritikSaranRepository(
        apiClient: _client(
          handler: (options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 422,
              data: {
                'message': 'The given data was invalid.',
                'errors': {
                  'kritik': ['Kritik wajib diisi.'],
                },
              },
            ),
          ),
        ),
      );

      await expectLater(
        repository.submit(kritik: '', saran: 'Saran'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'status code',
            422,
          ),
        ),
      );
    });
  });

  group('KritikSaranNotifier', () {
    test('moves from loading to success', () async {
      final notifier = KritikSaranNotifier(
        repository: _FakeRepository((_, _) async {}),
      );

      final submit = notifier.submitKritikSaran(
        kritik: 'Kritik',
        saran: 'Saran',
      );
      expect(notifier.state.isLoading, isTrue);
      await submit;

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.successMessage, isNotNull);
    });

    test(
      'exposes API errors and prevents duplicate in-flight submits',
      () async {
        final completer = Completer<void>();
        final repository = _FakeRepository((_, _) => completer.future);
        final notifier = KritikSaranNotifier(repository: repository);

        final first = notifier.submitKritikSaran(
          kritik: 'Kritik',
          saran: 'Saran',
        );
        final duplicate = notifier.submitKritikSaran(
          kritik: 'Kritik',
          saran: 'Saran',
        );
        expect(await duplicate, isFalse);
        expect(repository.calls, 1);
        completer.complete();
        expect(await first, isTrue);

        final failing = KritikSaranNotifier(
          repository: _FakeRepository(
            (_, _) =>
                throw ApiException(message: 'Tidak valid', statusCode: 422),
          ),
        );
        expect(
          await failing.submitKritikSaran(kritik: 'K', saran: 'S'),
          isFalse,
        );
        expect(failing.state.errorMessage, 'Tidak valid');
      },
    );
  });
}
