import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/info_alat/models/master_item_model.dart';
import 'package:gelatik/features/info_alat/presentation/screens/info_alat_screen.dart';
import 'package:gelatik/features/info_alat/providers/info_alat_provider.dart';
import 'package:gelatik/features/info_alat/repositories/master_item_repository.dart';

class _FakeStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'test-token';
}

ApiClient _apiClient({
  dynamic responseData,
  DioException? exception,
  void Function(RequestOptions options)? inspectRequest,
}) {
  final client = ApiClient(
    secureStorageService: _FakeStorage(),
    dioOverride: Dio(),
  );
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        inspectRequest?.call(options);
        if (exception != null) {
          return handler.reject(exception.copyWith(requestOptions: options));
        }
        return handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: responseData,
          ),
        );
      },
    ),
  );
  return client;
}

DioException _httpError(int statusCode, {String? message}) {
  final options = RequestOptions(path: '/items');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: {'message': message ?? 'HTTP error'},
    ),
  );
}

const _item = MasterItemModel(
  id: 1,
  nama: 'Laptop API',
  deskripsi: 'Laptop dari backend',
  stok: 3,
  kondisi: 'Baik',
);

class _FakeMasterItemRepository extends MasterItemRepository {
  final Queue<dynamic> getResults;
  final Future<List<MasterItemModel>> Function()? getHandler;
  int getCalls = 0;
  int searchCalls = 0;
  String? lastSearch;

  _FakeMasterItemRepository({
    Iterable<dynamic> getResults = const [],
    this.getHandler,
  }) : getResults = Queue<dynamic>.of(getResults),
       super(apiClient: _apiClient(responseData: const {}));

  @override
  Future<List<MasterItemModel>> getItems() async {
    getCalls++;
    if (getHandler != null) return getHandler!();
    if (getResults.isEmpty) return const [_item];
    final result = getResults.removeFirst();
    if (result is Exception) throw result;
    return List<MasterItemModel>.from(result as List);
  }

  @override
  Future<List<MasterItemModel>> searchItems(String keyword) async {
    searchCalls++;
    lastSearch = keyword;
    return getItems();
  }
}

void main() {
  group('MasterItemModel parsing', () {
    test('parses a complete backend response', () {
      final model = MasterItemModel.fromJson({
        'id': 7,
        'nama': 'Proyektor',
        'deskripsi': 'XGA',
        'stok': 2,
        'foto': 'https://example.test/item.jpg',
        'kondisi': 'Baik',
        'tersedia': true,
        'created_by': 4,
        'updated_by': null,
        'created_at': '2026-08-01T10:00:00.000Z',
        'updated_at': '2026-08-02T10:00:00.000Z',
      });

      expect(model.id, 7);
      expect(model.nama, 'Proyektor');
      expect(model.tersedia, isTrue);
      expect(model.createdBy, 4);
      expect(model.createdAt, DateTime.utc(2026, 8, 1, 10));
    });

    test('handles nullable and missing optional fields safely', () {
      final model = MasterItemModel.fromJson({
        'id': '8',
        'nama': 'Switch',
        'deskripsi': null,
        'stok': '0',
      });

      expect(model.deskripsi, isEmpty);
      expect(model.kondisi, isEmpty);
      expect(model.foto, isNull);
      expect(model.tersedia, isFalse);
      expect(model.createdAt, isNull);
    });

    test('rejects invalid required field types', () {
      expect(
        () => MasterItemModel.fromJson({
          'id': 'invalid',
          'nama': 'Router',
          'stok': 1,
        }),
        throwsFormatException,
      );
    });
  });

  group('MasterItemRepository', () {
    test('maps list response and sends the existing Bearer token', () async {
      RequestOptions? captured;
      final repository = MasterItemRepository(
        apiClient: _apiClient(
          responseData: {
            'success': true,
            'data': [
              {'id': 1, 'nama': 'Laptop API', 'stok': 3},
            ],
          },
          inspectRequest: (options) => captured = options,
        ),
      );

      final items = await repository.getItems();

      expect(items.single.nama, 'Laptop API');
      expect(captured?.path, '/items');
      expect(captured?.headers['Authorization'], 'Bearer test-token');
    });

    test('uses the actual search endpoint with an encoded keyword', () async {
      String? path;
      final repository = MasterItemRepository(
        apiClient: _apiClient(
          responseData: {'success': true, 'data': <dynamic>[]},
          inspectRequest: (options) => path = options.path,
        ),
      );

      expect(await repository.searchItems('laptop kantor'), isEmpty);
      expect(path, '/items/search/laptop%20kantor');
    });

    for (final entry in {
      401: MasterItemErrorType.unauthorized,
      403: MasterItemErrorType.forbidden,
      404: MasterItemErrorType.notFound,
    }.entries) {
      test('maps HTTP ${entry.key} explicitly', () async {
        final repository = MasterItemRepository(
          apiClient: _apiClient(exception: _httpError(entry.key)),
        );

        await expectLater(
          repository.getItems(),
          throwsA(
            isA<MasterItemRepositoryException>()
                .having((error) => error.type, 'type', entry.value)
                .having((error) => error.statusCode, 'statusCode', entry.key),
          ),
        );
      });
    }

    test('maps malformed envelopes explicitly', () async {
      final repository = MasterItemRepository(
        apiClient: _apiClient(responseData: {'success': true, 'data': {}}),
      );

      await expectLater(
        repository.getItems(),
        throwsA(
          isA<MasterItemRepositoryException>().having(
            (error) => error.type,
            'type',
            MasterItemErrorType.malformed,
          ),
        ),
      );
    });

    test('maps network errors explicitly', () async {
      final options = RequestOptions(path: '/items');
      final repository = MasterItemRepository(
        apiClient: _apiClient(
          exception: DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      );

      await expectLater(
        repository.getItems(),
        throwsA(
          isA<MasterItemRepositoryException>().having(
            (error) => error.type,
            'type',
            MasterItemErrorType.network,
          ),
        ),
      );
    });

    test('maps server errors explicitly', () async {
      final repository = MasterItemRepository(
        apiClient: _apiClient(exception: _httpError(500)),
      );

      await expectLater(
        repository.getItems(),
        throwsA(
          isA<MasterItemRepositoryException>().having(
            (error) => error.type,
            'type',
            MasterItemErrorType.server,
          ),
        ),
      );
    });
  });

  group('InfoAlatNotifier state', () {
    test('moves from loading to success', () async {
      final repository = _FakeMasterItemRepository();
      final notifier = InfoAlatNotifier(repository: repository);

      final future = notifier.loadItems();
      expect(notifier.state.status, InfoAlatStatus.loading);
      await future;

      expect(notifier.state.status, InfoAlatStatus.success);
      expect(notifier.state.items, const [_item]);
    });

    test('exposes an empty state', () async {
      final notifier = InfoAlatNotifier(
        repository: _FakeMasterItemRepository(getResults: const [<dynamic>[]]),
      );

      await notifier.loadItems();

      expect(notifier.state.status, InfoAlatStatus.empty);
      expect(notifier.state.items, isEmpty);
    });

    test('exposes typed repository errors', () async {
      final notifier = InfoAlatNotifier(
        repository: _FakeMasterItemRepository(
          getResults: [
            MasterItemRepositoryException(
              message: 'Tidak diizinkan',
              type: MasterItemErrorType.forbidden,
              statusCode: 403,
            ),
          ],
        ),
      );

      await notifier.loadItems();

      expect(notifier.state.status, InfoAlatStatus.error);
      expect(notifier.state.errorType, MasterItemErrorType.forbidden);
    });

    test('retry recovers after an error', () async {
      final repository = _FakeMasterItemRepository(
        getResults: [
          MasterItemRepositoryException(
            message: 'Jaringan gagal',
            type: MasterItemErrorType.network,
          ),
          const [_item],
        ],
      );
      final notifier = InfoAlatNotifier(repository: repository);

      await notifier.loadItems();
      await notifier.retry();

      expect(repository.getCalls, 2);
      expect(notifier.state.status, InfoAlatStatus.success);
    });

    test('refresh keeps data while the request is in progress', () async {
      final completer = Completer<List<MasterItemModel>>();
      final repository = _FakeMasterItemRepository(
        getHandler: () => completer.future,
      );
      final notifier = InfoAlatNotifier(repository: repository);
      notifier.state = const InfoAlatState(
        items: [_item],
        status: InfoAlatStatus.success,
      );

      final future = notifier.refresh();
      expect(notifier.state.status, InfoAlatStatus.refreshing);
      expect(notifier.state.items, const [_item]);
      completer.complete(const [_item]);
      await future;

      expect(notifier.state.status, InfoAlatStatus.success);
    });

    test('prevents duplicate in-flight loads for the same query', () async {
      final completer = Completer<List<MasterItemModel>>();
      final repository = _FakeMasterItemRepository(
        getHandler: () => completer.future,
      );
      final notifier = InfoAlatNotifier(repository: repository);

      final first = notifier.loadItems();
      final second = notifier.loadItems();
      expect(repository.getCalls, 1);
      completer.complete(const [_item]);
      await Future.wait([first, second]);
    });
  });

  group('InfoAlatScreen', () {
    testWidgets('shows the empty state returned by the API', (tester) async {
      final repository = _FakeMasterItemRepository(
        getResults: const [<dynamic>[]],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            masterItemRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: InfoAlatScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Belum Ada Aset TIK'), findsOneWidget);
    });

    testWidgets('shows a forbidden error and recovers through retry', (
      tester,
    ) async {
      final repository = _FakeMasterItemRepository(
        getResults: [
          MasterItemRepositoryException(
            message: 'Anda tidak memiliki izin untuk mengakses katalog alat.',
            type: MasterItemErrorType.forbidden,
            statusCode: 403,
          ),
          const [_item],
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            masterItemRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: InfoAlatScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Akses Ditolak'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Laptop API'), findsOneWidget);
    });
  });
}
