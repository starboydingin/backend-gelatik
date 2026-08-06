import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/info_alat/models/master_item_model.dart';
import 'package:gelatik/features/info_alat/repositories/master_item_repository.dart';
import 'package:gelatik/features/peminjaman/models/pinjam_model.dart';
import 'package:gelatik/features/peminjaman/models/pinjam_request.dart';
import 'package:gelatik/features/peminjaman/presentation/screens/ajukan_peminjaman_screen.dart';
import 'package:gelatik/features/peminjaman/presentation/screens/peminjaman_list_screen.dart';
import 'package:gelatik/features/peminjaman/providers/peminjaman_provider.dart';
import 'package:gelatik/features/peminjaman/repositories/peminjaman_repository.dart';

class _FakeStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'borrowing-test-token';
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
  final options = RequestOptions(path: '/pinjam');
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
  bool includeItems = true,
}) => {
  'id': id,
  'user_id': 7,
  'nama_pic': 'Ahmad Subagja',
  'jabatan_pic': 'Pranata Komputer',
  'instansi_pic': 'Diskominfotik',
  'kontak_pic': '081272345678',
  'jenis_identitas': 'NIP',
  'nomor_identitas': '198804122014031002',
  'alamat_peminjam': 'Bandar Lampung',
  'jenis_durasi': 'harian',
  'tanggal_mulai': '2026-08-10T00:00:00.000Z',
  'jam_mulai': null,
  'durasi_peminjaman': 2,
  'tanggal_selesai': '2026-08-12T00:00:00.000Z',
  'keterangan': null,
  'status': status,
  'catatan_petugas': null,
  'waktu_pengembalian': null,
  'bukti_pengembalian': null,
  'url_dokumen': null,
  if (includeItems)
    'pinjam_items': [
      {
        'id': 91,
        'pinjam_id': id,
        'item_id': 3,
        'quantity': 2,
        'master_item': {
          'id': 3,
          'nama': 'Laptop API',
          'deskripsi': null,
          'stok': 4,
        },
      },
    ],
};

final _model = PinjamModel.fromJson(_json());

class _FakeRepository extends PeminjamanRepository {
  List<PinjamModel> listResult;
  PinjamModel detailResult;
  PinjamModel createResult;
  PinjamModel statusResult;
  Object? listError;
  Object? createError;
  Future<List<PinjamModel>> Function()? listHandler;
  Completer<PinjamModel>? createCompleter;
  int listCalls = 0;
  int createCalls = 0;
  int statusCalls = 0;

  _FakeRepository({
    this.listResult = const [],
    PinjamModel? detailResult,
    PinjamModel? createResult,
    PinjamModel? statusResult,
    this.listError,
    this.createError,
    this.listHandler,
    this.createCompleter,
  }) : detailResult = detailResult ?? _model,
       createResult = createResult ?? _model,
       statusResult = statusResult ?? _model,
       super(apiClient: _client(data: const {}));

  @override
  Future<List<PinjamModel>> getPeminjaman({int page = 1}) async {
    listCalls++;
    if (listHandler != null) return listHandler!();
    if (listError != null) throw listError!;
    return listResult;
  }

  @override
  Future<PinjamModel> getPeminjamanDetail(int id) async => detailResult;

  @override
  Future<PinjamModel> createPeminjaman(PinjamRequest request) async {
    createCalls++;
    if (createError != null) throw createError!;
    if (createCompleter != null) return createCompleter!.future;
    return createResult;
  }

  @override
  Future<PinjamModel> updateStatus(
    int id,
    String status, {
    String? catatan,
  }) async {
    statusCalls++;
    return statusResult;
  }
}

class _FakeMasterItemRepository extends MasterItemRepository {
  final Future<List<MasterItemModel>> Function() handler;

  _FakeMasterItemRepository(this.handler)
    : super(apiClient: _client(data: const {}));

  @override
  Future<List<MasterItemModel>> getItems() => handler();
}

void main() {
  group('PinjamModel', () {
    test('parses complete, nullable, nested relation, and numeric IDs', () {
      final json = _json();
      json['id'] = '11';
      final model = PinjamModel.fromJson(json);

      expect(model.id, 11);
      expect(model.keterangan, isNull);
      expect(model.items.single.item?.nama, 'Laptop API');
      expect(model.tanggalSelesai, isNotNull);
    });

    test('keeps an unknown status visible without crashing', () {
      final model = PinjamModel.fromJson(_json(status: 'LegacyStatus'));
      expect(model.status, 'LegacyStatus');
      expect(model.statusType, PinjamStatus.unknown);
    });

    test('accepts a minimal response with missing optional relations', () {
      final model = PinjamModel.fromJson(_json(includeItems: false));
      expect(model.items, isEmpty);
      expect(model.createdAt, isNull);
    });

    test('rejects invalid required business fields', () {
      final json = _json()..['nama_pic'] = null;
      expect(() => PinjamModel.fromJson(json), throwsFormatException);
    });
  });

  group('PinjamRequest', () {
    test('does not send user_id and uses backend field names', () {
      final payload = PinjamRequest(
        namaPic: 'PIC',
        jabatanPic: 'Staf',
        instansiPic: 'OPD',
        kontakPic: '0812',
        jenisIdentitas: 'NIP',
        nomorIdentitas: '123',
        alamatPeminjam: 'Alamat',
        jenisDurasi: 'harian',
        tanggalMulai: DateTime(2026, 8, 10),
        durasiPeminjaman: 2,
        itemQuantities: const {3: 2},
      ).toJson();

      expect(payload, isNot(contains('user_id')));
      expect(payload['tanggal_mulai'], '2026-08-10');
      expect(payload['items'], [
        {'item_id': 3, 'quantity': 2},
      ]);
    });
  });

  group('PeminjamanRepository', () {
    test('parses paginator list and sends Bearer token', () async {
      RequestOptions? request;
      final repository = PeminjamanRepository(
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
      final page = await repository.getPeminjamanPage();
      expect(page.items.single.id, 11);
      expect(page.total, 1);
      expect(page.currentPage, 1);
      expect(request?.path, '/pinjam');
      expect(request?.headers['Authorization'], 'Bearer borrowing-test-token');
    });

    test('parses detail success', () async {
      final repository = PeminjamanRepository(
        apiClient: _client(data: {'success': true, 'data': _json()}),
      );
      expect((await repository.getPeminjamanDetail(11)).id, 11);
    });

    test('create sends the actual endpoint and payload', () async {
      RequestOptions? request;
      final repository = PeminjamanRepository(
        apiClient: _client(
          data: {'success': true, 'data': _json()},
          inspect: (options) => request = options,
        ),
      );
      await repository.createPeminjaman(
        PinjamRequest(
          namaPic: 'PIC',
          jabatanPic: 'Staf',
          instansiPic: 'OPD',
          kontakPic: '0812',
          jenisIdentitas: 'NIP',
          nomorIdentitas: '123',
          alamatPeminjam: 'Alamat',
          jenisDurasi: 'harian',
          tanggalMulai: DateTime(2026, 8, 10),
          durasiPeminjaman: 1,
          itemQuantities: const {3: 1},
        ),
      );
      expect(request?.method, 'POST');
      expect(request?.path, '/pinjam');
      expect((request?.data as Map)['user_id'], isNull);
    });

    for (final entry in {
      401: PeminjamanErrorType.unauthorized,
      403: PeminjamanErrorType.forbidden,
      404: PeminjamanErrorType.notFound,
      409: PeminjamanErrorType.conflict,
      422: PeminjamanErrorType.validation,
      500: PeminjamanErrorType.server,
    }.entries) {
      test('maps HTTP ${entry.key}', () async {
        final repository = PeminjamanRepository(
          apiClient: _client(error: _httpError(entry.key)),
        );
        await expectLater(
          repository.getPeminjaman(),
          throwsA(
            isA<PeminjamanRepositoryException>().having(
              (error) => error.type,
              'type',
              entry.value,
            ),
          ),
        );
      });
    }

    test('preserves backend field validation errors', () async {
      final repository = PeminjamanRepository(
        apiClient: _client(
          error: _httpError(
            422,
            data: {
              'message': 'Invalid',
              'errors': {
                'items': ['Stok tidak cukup'],
              },
            },
          ),
        ),
      );
      await expectLater(
        repository.getPeminjaman(),
        throwsA(
          isA<PeminjamanRepositoryException>().having(
            (error) => error.errors?['items'],
            'items error',
            ['Stok tidak cukup'],
          ),
        ),
      );
    });

    test('maps network, timeout, and malformed responses', () async {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
      ]) {
        final repository = PeminjamanRepository(
          apiClient: _client(
            error: DioException(
              requestOptions: RequestOptions(path: '/pinjam'),
              type: type,
            ),
          ),
        );
        await expectLater(
          repository.getPeminjaman(),
          throwsA(isA<PeminjamanRepositoryException>()),
        );
      }
      final malformed = PeminjamanRepository(
        apiClient: _client(data: {'success': true, 'data': {}}),
      );
      await expectLater(
        malformed.getPeminjaman(),
        throwsA(
          isA<PeminjamanRepositoryException>().having(
            (error) => error.type,
            'type',
            PeminjamanErrorType.malformed,
          ),
        ),
      );
    });
  });

  group('PeminjamanNotifier', () {
    test('loads success, empty, error, and refresh', () async {
      final repository = _FakeRepository(listResult: [_model]);
      final notifier = PeminjamanNotifier(repository: repository);
      await notifier.loadPeminjaman();
      expect(notifier.state.status, PeminjamanLoadStatus.success);

      repository.listResult = [];
      await notifier.refresh();
      expect(notifier.state.status, PeminjamanLoadStatus.empty);

      repository.listError = PeminjamanRepositoryException(
        message: 'Jaringan gagal',
        type: PeminjamanErrorType.network,
      );
      await notifier.retry();
      expect(notifier.state.status, PeminjamanLoadStatus.error);
    });

    test('realtime event refreshes authoritative borrowing state', () async {
      final repository = _FakeRepository(listResult: [_model]);
      final notifier = PeminjamanNotifier(repository: repository);
      await notifier.loadPeminjaman();
      repository.listResult = [PinjamModel.fromJson(_json(status: 'Proses'))];

      await notifier.refreshFromRealtime(_model.id);

      expect(repository.listCalls, 2);
      expect(notifier.state.listPinjam.single.status, 'Proses');
    });

    test('prevents duplicate submit', () async {
      final completer = Completer<PinjamModel>();
      final repository = _FakeRepository(createCompleter: completer);
      final notifier = PeminjamanNotifier(repository: repository);
      const item = MasterItemModel(id: 3, nama: 'Laptop', stok: 2);
      Future<bool> submit() => notifier.submitPengajuan(
        namaPic: 'PIC',
        jabatanPic: 'Staf',
        instansiPic: 'OPD',
        kontakPic: '0812',
        jenisIdentitas: 'NIP',
        nomorIdentitas: '123',
        alamatPeminjam: 'Alamat',
        jenisDurasi: 'harian',
        tanggalMulai: DateTime(2026, 8, 10),
        durasiPeminjaman: 1,
        selectedItemsWithQuantity: const {item: 1},
      );

      final first = submit();
      final second = await submit();
      expect(second, isFalse);
      expect(repository.createCalls, 1);
      completer.complete(_model);
      expect(await first, isTrue);
    });

    test('exposes validation errors and updates status from API', () async {
      final validation = PeminjamanRepositoryException(
        message: 'Stok tidak cukup',
        type: PeminjamanErrorType.validation,
        statusCode: 422,
        errors: const {
          'items': ['Stok tidak cukup'],
        },
      );
      final repository = _FakeRepository(createError: validation);
      final notifier = PeminjamanNotifier(repository: repository);
      const item = MasterItemModel(id: 3, nama: 'Laptop', stok: 2);
      final result = await notifier.submitPengajuan(
        namaPic: 'PIC',
        jabatanPic: 'Staf',
        instansiPic: 'OPD',
        kontakPic: '0812',
        jenisIdentitas: 'NIP',
        nomorIdentitas: '123',
        alamatPeminjam: 'Alamat',
        jenisDurasi: 'harian',
        tanggalMulai: DateTime(2026, 8, 10),
        durasiPeminjaman: 1,
        selectedItemsWithQuantity: const {item: 1},
      );
      expect(result, isFalse);
      expect(
        notifier.state.mutationStatus,
        PeminjamanMutationStatus.validationError,
      );
      expect(notifier.state.validationErrors['items'], isNotNull);

      repository.createError = null;
      repository.statusResult = PinjamModel.fromJson(_json(status: 'Proses'));
      notifier.state = PeminjamanState(listPinjam: [_model]);
      expect(await notifier.setujuPeminjaman(_model.id), isTrue);
      expect(notifier.state.listPinjam.single.status, 'Proses');
    });

    test('ignores stale list responses', () async {
      final first = Completer<List<PinjamModel>>();
      var call = 0;
      final repository = _FakeRepository(
        listHandler: () {
          call++;
          return call == 1 ? first.future : Future.value([_model]);
        },
      );
      final notifier = PeminjamanNotifier(repository: repository);
      final oldRequest = notifier.loadPeminjaman();
      await notifier.refresh();
      first.complete([]);
      await oldRequest;
      expect(notifier.state.listPinjam, [_model]);
    });
  });

  group('PeminjamanListScreen', () {
    testWidgets('shows loading, list success, and status badge', (
      tester,
    ) async {
      final completer = Completer<List<PinjamModel>>();
      final repository = _FakeRepository(listHandler: () => completer.future);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            peminjamanRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: PeminjamanListScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete([_model]);
      await tester.pumpAndSettle();
      expect(find.textContaining('Ahmad Subagja'), findsOneWidget);
      expect(find.text('Menunggu'), findsWidgets);
    });

    testWidgets('shows error with retry', (tester) async {
      final repository = _FakeRepository(
        listError: PeminjamanRepositoryException(
          message: 'Tidak dapat terhubung',
          type: PeminjamanErrorType.network,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            peminjamanRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: PeminjamanListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tidak dapat terhubung'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });

  group('AjukanPeminjamanScreen', () {
    testWidgets('shows catalog loading then real Master Item data', (
      tester,
    ) async {
      final completer = Completer<List<MasterItemModel>>();
      final masterRepository = _FakeMasterItemRepository(
        () => completer.future,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            masterItemRepositoryProvider.overrideWithValue(masterRepository),
            peminjamanRepositoryProvider.overrideWithValue(_FakeRepository()),
          ],
          child: const MaterialApp(home: AjukanPeminjamanScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(const [
        MasterItemModel(id: 3, nama: 'Laptop API', stok: 2),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Laptop API'), findsOneWidget);
    });

    testWidgets('shows local required-field validation before submit', (
      tester,
    ) async {
      final masterRepository = _FakeMasterItemRepository(
        () async => const [MasterItemModel(id: 3, nama: 'Laptop API', stok: 2)],
      );
      final borrowingRepository = _FakeRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            masterItemRepositoryProvider.overrideWithValue(masterRepository),
            peminjamanRepositoryProvider.overrideWithValue(borrowingRepository),
          ],
          child: const MaterialApp(home: AjukanPeminjamanScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pump();
      await tester.tap(find.textContaining('Lanjut ke Detail Pinjam'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Kirim Pengajuan'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Kirim Pengajuan'));
      await tester.pump();
      expect(find.text('Nama PIC wajib diisi'), findsOneWidget);
      expect(borrowingRepository.createCalls, 0);
    });
  });
}
