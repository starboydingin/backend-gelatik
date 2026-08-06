import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_model.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_request.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_response_model.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_topik_model.dart';
import 'package:gelatik/features/konsultasi/presentation/screens/buat_konsultasi_screen.dart';
import 'package:gelatik/features/konsultasi/presentation/screens/konsultasi_detail_screen.dart';
import 'package:gelatik/features/konsultasi/presentation/screens/konsultasi_list_screen.dart';
import 'package:gelatik/features/konsultasi/providers/konsultasi_provider.dart';
import 'package:gelatik/features/konsultasi/repositories/konsultasi_repository.dart';

class _FakeStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'consultation-test-token';
}

ApiClient _client({
  dynamic data,
  DioException? error,
  void Function(RequestOptions options)? inspect,
}) {
  final client = ApiClient(
    secureStorageService: _FakeStorage(),
    dioOverride: Dio(),
  );
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        inspect?.call(options);
        if (error != null) {
          handler.reject(error.copyWith(requestOptions: options));
        } else {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        }
      },
    ),
  );
  return client;
}

DioException _httpError(int status, {Map<String, dynamic>? data}) {
  final options = RequestOptions(path: '/konsul');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data ?? {'message': 'HTTP $status'},
    ),
  );
}

Map<String, dynamic> _json({
  int id = 11,
  String status = 'Menunggu',
  bool relations = true,
}) => {
  'id': id,
  'user_id': 7,
  'faq_id': 3,
  'judul': 'Kendala jaringan',
  'pesan': 'Wi-Fi tidak dapat digunakan.',
  'file': null,
  'status': status,
  'created_at': '2026-08-05T08:30:00.000Z',
  'updated_at': null,
  if (relations) 'user': {'id': 7, 'name': 'Pemilik Tiket'},
  if (relations) 'topik': {'id': 3, 'topik': 'Jaringan', 'status': '1'},
  if (relations)
    'responses': [
      {
        'id': 41,
        'konsultasi_id': id,
        'user_id': 9,
        'pesan': 'Sedang kami periksa.',
        'file': null,
        'created_at': '2026-08-05T09:00:00.000Z',
        'user': {'id': 9, 'name': 'Admin TIK'},
      },
    ],
};

final _model = KonsultasiModel.fromJson(_json());
final _topik = KonsultasiTopikModel.fromJson({
  'id': 3,
  'topik': 'Jaringan',
  'status': '1',
});

class _FakeRepository extends KonsultasiRepository {
  List<KonsultasiModel> listResult;
  KonsultasiModel detailResult;
  KonsultasiModel createResult;
  KonsultasiModel statusResult;
  List<KonsultasiTopikModel> topikResult;
  Object? listError;
  Object? detailError;
  Object? createError;
  Object? answerError;
  Object? statusError;
  Future<List<KonsultasiModel>> Function()? listHandler;
  Completer<KonsultasiModel>? createCompleter;
  int listCalls = 0;
  int createCalls = 0;
  int answerCalls = 0;
  int statusCalls = 0;
  int deleteCalls = 0;

  _FakeRepository({
    this.listResult = const [],
    KonsultasiModel? detailResult,
    KonsultasiModel? createResult,
    KonsultasiModel? statusResult,
    this.topikResult = const [],
    this.listError,
    this.detailError,
    this.createError,
    this.answerError,
    this.statusError,
    this.listHandler,
    this.createCompleter,
  }) : detailResult = detailResult ?? _model,
       createResult = createResult ?? _model,
       statusResult = statusResult ?? _model,
       super(apiClient: _client(data: const {}));

  @override
  Future<List<KonsultasiModel>> getKonsultasi({int page = 1}) async {
    listCalls++;
    if (listHandler != null) return listHandler!();
    if (listError != null) throw listError!;
    return listResult;
  }

  @override
  Future<KonsultasiModel> getDetail(int id) async {
    if (detailError != null) throw detailError!;
    return detailResult;
  }

  @override
  Future<KonsultasiModel> create(BuatKonsultasiRequest request) async {
    createCalls++;
    if (createError != null) throw createError!;
    if (createCompleter != null) return createCompleter!.future;
    return createResult;
  }

  @override
  Future<KonsultasiResponseModel> answer(
    int id,
    BalasKonsultasiRequest request,
  ) async {
    answerCalls++;
    if (answerError != null) throw answerError!;
    return _model.responses.single;
  }

  @override
  Future<KonsultasiModel> updateStatus(int id, String status) async {
    statusCalls++;
    if (statusError != null) throw statusError!;
    return statusResult;
  }

  @override
  Future<void> delete(int id) async {
    deleteCalls++;
  }

  @override
  Future<List<KonsultasiTopikModel>> getTopik() async => topikResult;
}

void main() {
  group('Konsultasi model', () {
    test('parses complete response and nested relations', () {
      final model = KonsultasiModel.fromJson(_json());
      expect(model.id, 11);
      expect(model.userName, 'Pemilik Tiket');
      expect(model.topikNama, 'Jaringan');
      expect(model.responses.single.userName, 'Admin TIK');
    });

    test('parses minimal response and nullable values', () {
      final model = KonsultasiModel.fromJson(_json(relations: false));
      expect(model.file, isNull);
      expect(model.topik, isNull);
      expect(model.responses, isEmpty);
      expect(model.updatedAt, isNull);
    });

    test('keeps unknown status without crashing', () {
      expect(
        KonsultasiModel.fromJson(_json(status: 'Legacy')).status,
        'Legacy',
      );
    });

    test('rejects missing required ID', () {
      expect(
        () => KonsultasiModel.fromJson(_json()..remove('id')),
        throwsFormatException,
      );
    });

    test('rejects invalid required date', () {
      expect(
        () => KonsultasiModel.fromJson(_json()..['created_at'] = 'invalid'),
        throwsFormatException,
      );
    });

    test('rejects malformed nested relation', () {
      expect(
        () => KonsultasiModel.fromJson(_json()..['responses'] = {}),
        throwsFormatException,
      );
    });

    test('response model requires its business fields', () {
      final response = Map<String, dynamic>.from(_json()['responses'][0]);
      response['pesan'] = null;
      expect(
        () => KonsultasiResponseModel.fromJson(response),
        throwsFormatException,
      );
    });

    test('topik rejects missing display name', () {
      expect(
        () => KonsultasiTopikModel.fromJson({'id': 1}),
        throwsFormatException,
      );
    });
  });

  group('Request DTO', () {
    test('create uses backend fields and never sends user_id', () {
      final payload = const BuatKonsultasiRequest(
        topikId: 3,
        judul: ' Judul ',
        deskripsi: ' Isi ',
      ).toJson();
      expect(payload, {'topik_id': 3, 'judul': 'Judul', 'deskripsi': 'Isi'});
      expect(payload, isNot(contains('user_id')));
    });

    test('answer uses isi_respon contract', () {
      expect(const BalasKonsultasiRequest(isiRespon: ' Jawab ').toJson(), {
        'isi_respon': 'Jawab',
      });
    });
  });

  group('Konsultasi repository', () {
    test('list parses paginator and sends bearer token', () async {
      RequestOptions? request;
      final repository = KonsultasiRepository(
        apiClient: _client(
          data: {
            'success': true,
            'data': {
              'current_page': 1,
              'last_page': 1,
              'total': 1,
              'data': [_json()],
            },
          },
          inspect: (options) => request = options,
        ),
      );
      final page = await repository.getKonsultasiPage();
      expect(page.items.single.id, 11);
      expect(page.total, 1);
      expect(page.currentPage, 1);
      expect(
        request?.headers['Authorization'],
        'Bearer consultation-test-token',
      );
      expect(request?.path, '/konsul');
    });

    test('detail parses object response', () async {
      final repository = KonsultasiRepository(
        apiClient: _client(data: {'success': true, 'data': _json()}),
      );
      expect((await repository.getDetail(11)).judul, 'Kendala jaringan');
    });

    test('create posts contract payload', () async {
      RequestOptions? request;
      final repository = KonsultasiRepository(
        apiClient: _client(
          data: {'success': true, 'data': _json()},
          inspect: (options) => request = options,
        ),
      );
      await repository.create(
        const BuatKonsultasiRequest(
          topikId: 3,
          judul: 'Judul',
          deskripsi: 'Isi',
        ),
      );
      expect(request?.method, 'POST');
      expect(request?.data['topik_id'], 3);
      expect(request?.data, isNot(contains('user_id')));
    });

    test('answer parses response object', () async {
      final repository = KonsultasiRepository(
        apiClient: _client(
          data: {'success': true, 'data': _json()['responses'][0]},
        ),
      );
      final response = await repository.answer(
        11,
        const BalasKonsultasiRequest(isiRespon: 'Jawab'),
      );
      expect(response.id, 41);
    });

    test('status posts exact backend value', () async {
      RequestOptions? request;
      final repository = KonsultasiRepository(
        apiClient: _client(
          data: {
            'success': true,
            'data': _json(status: 'Diproses'),
          },
          inspect: (options) => request = options,
        ),
      );
      await repository.updateStatus(11, 'Diproses');
      expect(request?.data, {'status': 'Diproses'});
    });

    test('delete accepts message-only envelope', () async {
      final repository = KonsultasiRepository(
        apiClient: _client(data: {'success': true, 'message': 'ok'}),
      );
      await repository.delete(11);
    });

    test('topik parses backend field topik', () async {
      final repository = KonsultasiRepository(
        apiClient: _client(
          data: {
            'success': true,
            'data': [
              {'id': 3, 'topik': 'Jaringan', 'status': '1'},
            ],
          },
        ),
      );
      expect((await repository.getTopik()).single.nama, 'Jaringan');
    });

    for (final entry in const {
      400: KonsultasiErrorType.invalidState,
      401: KonsultasiErrorType.unauthorized,
      403: KonsultasiErrorType.forbidden,
      404: KonsultasiErrorType.notFound,
      409: KonsultasiErrorType.conflict,
      422: KonsultasiErrorType.validation,
      500: KonsultasiErrorType.server,
    }.entries) {
      test('maps HTTP ${entry.key} to ${entry.value.name}', () async {
        final repository = KonsultasiRepository(
          apiClient: _client(error: _httpError(entry.key)),
        );
        await expectLater(
          repository.getDetail(11),
          throwsA(
            isA<KonsultasiRepositoryException>().having(
              (error) => error.type,
              'type',
              entry.value,
            ),
          ),
        );
      });
    }

    test('preserves 422 field errors', () async {
      final repository = KonsultasiRepository(
        apiClient: _client(
          error: _httpError(
            422,
            data: {
              'message': 'Invalid',
              'errors': {
                'judul': ['Judul wajib diisi.'],
              },
            },
          ),
        ),
      );
      try {
        await repository.getDetail(11);
        fail('Expected exception');
      } on KonsultasiRepositoryException catch (error) {
        expect(error.errors?['judul'], ['Judul wajib diisi.']);
      }
    });

    test('maps timeout and network separately', () {
      final options = RequestOptions(path: '/konsul');
      expect(
        KonsultasiRepositoryException.fromDioException(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
        ).type,
        KonsultasiErrorType.timeout,
      );
      expect(
        KonsultasiRepositoryException.fromDioException(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ).type,
        KonsultasiErrorType.network,
      );
    });

    test('rejects malformed envelope and object', () async {
      final badEnvelope = KonsultasiRepository(
        apiClient: _client(data: {'data': _json()}),
      );
      final badObject = KonsultasiRepository(
        apiClient: _client(data: {'success': true, 'data': []}),
      );
      await expectLater(
        badEnvelope.getDetail(11),
        throwsA(isA<KonsultasiRepositoryException>()),
      );
      await expectLater(
        badObject.getDetail(11),
        throwsA(isA<KonsultasiRepositoryException>()),
      );
    });
  });

  group('Konsultasi provider', () {
    test('initial load reaches success', () async {
      final notifier = KonsultasiNotifier(
        repository: _FakeRepository(listResult: [_model]),
      );
      await notifier.loadKonsultasi();
      expect(notifier.state.status, KonsultasiLoadStatus.success);
      expect(notifier.state.listKonsultasi.single.id, 11);
    });

    test('empty load reaches empty state', () async {
      final notifier = KonsultasiNotifier(repository: _FakeRepository());
      await notifier.loadKonsultasi();
      expect(notifier.state.status, KonsultasiLoadStatus.empty);
    });

    test('load error is exposed', () async {
      final notifier = KonsultasiNotifier(
        repository: _FakeRepository(
          listError: KonsultasiRepositoryException(
            message: 'offline',
            type: KonsultasiErrorType.network,
          ),
        ),
      );
      await notifier.loadKonsultasi();
      expect(notifier.state.status, KonsultasiLoadStatus.error);
      expect(notifier.state.errorType, KonsultasiErrorType.network);
    });

    test('detail forbidden clears selected data', () async {
      final notifier = KonsultasiNotifier(
        repository: _FakeRepository(
          detailError: KonsultasiRepositoryException(
            message: 'Dilarang',
            type: KonsultasiErrorType.forbidden,
          ),
        ),
      );
      await notifier.loadDetail(11);
      expect(notifier.state.status, KonsultasiLoadStatus.error);
      expect(notifier.state.selectedKonsultasi, isNull);
      expect(notifier.state.errorType, KonsultasiErrorType.forbidden);
    });

    test('refresh calls repository again', () async {
      final repository = _FakeRepository(listResult: [_model]);
      final notifier = KonsultasiNotifier(repository: repository);
      await notifier.loadKonsultasi();
      await notifier.refresh();
      expect(repository.listCalls, 2);
    });

    test('realtime event refreshes authoritative consultation state', () async {
      final repository = _FakeRepository(listResult: [_model]);
      final notifier = KonsultasiNotifier(repository: repository);
      await notifier.loadKonsultasi();
      repository.listResult = [
        KonsultasiModel.fromJson(_json(status: 'Diproses')),
      ];

      await notifier.refreshFromRealtime(_model.id);

      expect(repository.listCalls, 2);
      expect(notifier.state.listKonsultasi.single.status, 'Diproses');
    });

    test('create success updates list', () async {
      final notifier = KonsultasiNotifier(
        repository: _FakeRepository(createResult: _model),
      );
      expect(
        await notifier.tambahKonsultasi(
          topikId: 3,
          judul: 'Judul',
          deskripsi: 'Isi',
        ),
        isTrue,
      );
      expect(notifier.state.listKonsultasi.single.id, 11);
    });

    test('create validation stays local', () async {
      final repository = _FakeRepository();
      final notifier = KonsultasiNotifier(repository: repository);
      expect(
        await notifier.tambahKonsultasi(topikId: 0, judul: '', deskripsi: ''),
        isFalse,
      );
      expect(repository.createCalls, 0);
      expect(notifier.state.validationErrors, contains('topik_id'));
    });

    test('backend validation errors are preserved', () async {
      final notifier = KonsultasiNotifier(
        repository: _FakeRepository(
          createError: KonsultasiRepositoryException(
            message: 'Invalid',
            type: KonsultasiErrorType.validation,
            errors: const {
              'judul': ['Judul ditolak server.'],
            },
          ),
        ),
      );
      await notifier.tambahKonsultasi(
        topikId: 3,
        judul: 'Judul',
        deskripsi: 'Isi',
      );
      expect(notifier.state.validationErrors['judul'], isNotNull);
    });

    test('answer refreshes authoritative detail', () async {
      final repository = _FakeRepository(detailResult: _model);
      final notifier = KonsultasiNotifier(repository: repository);
      expect(
        await notifier.kirimBalasan(konsultasiId: 11, isiRespon: 'Balas'),
        isTrue,
      );
      expect(repository.answerCalls, 1);
      expect(notifier.state.selectedKonsultasi?.responses, isNotEmpty);
    });

    test('answer forbidden maps mutation state', () async {
      final notifier = KonsultasiNotifier(
        repository: _FakeRepository(
          answerError: KonsultasiRepositoryException(
            message: 'Dilarang',
            type: KonsultasiErrorType.forbidden,
          ),
        ),
      );
      expect(
        await notifier.kirimBalasan(konsultasiId: 11, isiRespon: 'Balas'),
        isFalse,
      );
      expect(notifier.state.mutationStatus, KonsultasiMutationStatus.forbidden);
    });

    test('admin status success updates detail', () async {
      final updated = KonsultasiModel.fromJson(_json(status: 'Diproses'));
      final notifier = KonsultasiNotifier(
        repository: _FakeRepository(statusResult: updated),
      );
      expect(await notifier.ubahStatus(11, 'Diproses'), isTrue);
      expect(notifier.state.selectedKonsultasi?.status, 'Diproses');
    });

    test('invalid transition is represented separately', () async {
      final notifier = KonsultasiNotifier(
        repository: _FakeRepository(
          statusError: KonsultasiRepositoryException(
            message: 'Transisi tidak valid',
            type: KonsultasiErrorType.invalidState,
          ),
        ),
      );
      await notifier.ubahStatus(11, 'Diproses');
      expect(
        notifier.state.mutationStatus,
        KonsultasiMutationStatus.invalidState,
      );
    });

    test('duplicate create submit is prevented', () async {
      final completer = Completer<KonsultasiModel>();
      final repository = _FakeRepository(createCompleter: completer);
      final notifier = KonsultasiNotifier(repository: repository);
      final first = notifier.tambahKonsultasi(
        topikId: 3,
        judul: 'Judul',
        deskripsi: 'Isi',
      );
      final second = await notifier.tambahKonsultasi(
        topikId: 3,
        judul: 'Judul',
        deskripsi: 'Isi',
      );
      expect(second, isFalse);
      expect(repository.createCalls, 1);
      completer.complete(_model);
      expect(await first, isTrue);
    });

    test('stale list response cannot overwrite refresh', () async {
      final first = Completer<List<KonsultasiModel>>();
      final second = Completer<List<KonsultasiModel>>();
      var call = 0;
      final notifier = KonsultasiNotifier(
        repository: _FakeRepository(
          listHandler: () => call++ == 0 ? first.future : second.future,
        ),
      );
      final oldRequest = notifier.loadKonsultasi();
      final refresh = notifier.refresh();
      second.complete([KonsultasiModel.fromJson(_json(id: 22))]);
      await refresh;
      first.complete([_model]);
      await oldRequest;
      expect(notifier.state.listKonsultasi.single.id, 22);
    });

    test('delete removes item from list', () async {
      final repository = _FakeRepository(listResult: [_model]);
      final notifier = KonsultasiNotifier(repository: repository);
      await notifier.loadKonsultasi();
      expect(await notifier.hapusKonsultasi(11), isTrue);
      expect(repository.deleteCalls, 1);
      expect(notifier.state.status, KonsultasiLoadStatus.empty);
    });
  });

  group('Konsultasi UI', () {
    testWidgets('list shows loading then API result and status badge', (
      tester,
    ) async {
      final completer = Completer<List<KonsultasiModel>>();
      final repository = _FakeRepository(listHandler: () => completer.future);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            konsultasiRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: KonsultasiListScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete([_model]);
      await tester.pumpAndSettle();
      expect(find.text('Kendala jaringan'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
    });

    testWidgets('list renders empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            konsultasiRepositoryProvider.overrideWithValue(_FakeRepository()),
          ],
          child: const MaterialApp(home: KonsultasiListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belum Ada Konsultasi'), findsOneWidget);
    });

    testWidgets('list error has retry action', (tester) async {
      final repository = _FakeRepository(
        listError: KonsultasiRepositoryException(
          message: 'Tidak tersambung',
          type: KonsultasiErrorType.network,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            konsultasiRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: KonsultasiListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tidak tersambung'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      expect(repository.listCalls, 2);
    });

    testWidgets('form validates required fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            konsultasiRepositoryProvider.overrideWithValue(
              _FakeRepository(topikResult: [_topik]),
            ),
          ],
          child: const MaterialApp(home: BuatKonsultasiScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim Konsultasi'));
      await tester.pump();
      expect(find.text('Topik wajib dipilih'), findsOneWidget);
      expect(find.text('Judul konsultasi wajib diisi'), findsOneWidget);
    });

    testWidgets('form shows submitting state and prevents duplicate tap', (
      tester,
    ) async {
      final completer = Completer<KonsultasiModel>();
      final repository = _FakeRepository(
        topikResult: [_topik],
        createCompleter: completer,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            konsultasiRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: BuatKonsultasiScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('topik-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jaringan').last);
      await tester.enterText(find.byType(TextField).at(0), 'Judul API');
      await tester.enterText(find.byType(TextField).at(1), 'Deskripsi API');
      await tester.tap(find.text('Kirim Konsultasi'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repository.createCalls, 1);
      completer.complete(_model);
      await tester.pumpAndSettle();
    });

    testWidgets('form displays backend field validation error', (tester) async {
      final repository = _FakeRepository(
        topikResult: [_topik],
        createError: KonsultasiRepositoryException(
          message: 'Judul ditolak server.',
          type: KonsultasiErrorType.validation,
          errors: const {
            'judul': ['Judul ditolak server.'],
          },
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            konsultasiRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: BuatKonsultasiScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('topik-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jaringan').last);
      await tester.enterText(find.byType(TextField).at(0), 'Judul API');
      await tester.enterText(find.byType(TextField).at(1), 'Deskripsi API');
      await tester.tap(find.text('Kirim Konsultasi'));
      await tester.pumpAndSettle();
      expect(find.text('Judul ditolak server.'), findsWidgets);
    });

    testWidgets(
      'detail renders nullable response and no admin actions for user',
      (tester) async {
        final minimal = KonsultasiModel.fromJson(_json(relations: false));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              konsultasiRepositoryProvider.overrideWithValue(
                _FakeRepository(detailResult: minimal),
              ),
            ],
            child: MaterialApp(
              home: KonsultasiDetailScreen(konsultasi: minimal),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Belum ada tanggapan.'), findsOneWidget);
        expect(find.byKey(const Key('admin-status-actions')), findsNothing);
      },
    );

    testWidgets('admin detail shows allowed status actions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            konsultasiRepositoryProvider.overrideWithValue(
              _FakeRepository(detailResult: _model),
            ),
          ],
          child: MaterialApp(
            home: KonsultasiDetailScreen(konsultasi: _model, isAdminView: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-status-actions')), findsOneWidget);
      expect(find.text('Diproses'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });
  });
}
