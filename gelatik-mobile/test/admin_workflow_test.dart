import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:gelatik/features/admin/presentation/screens/admin_konsultasi_list_screen.dart';
import 'package:gelatik/features/admin/presentation/screens/admin_peminjaman_detail_screen.dart';
import 'package:gelatik/features/admin/presentation/screens/admin_peminjaman_list_screen.dart';
import 'package:gelatik/features/auth/models/user_model.dart';
import 'package:gelatik/features/auth/providers/auth_provider.dart';
import 'package:gelatik/features/email/providers/email_provider.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';
import 'package:gelatik/features/info_alat/models/master_item_model.dart';
import 'package:gelatik/features/info_alat/repositories/master_item_repository.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_model.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_request.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_response_model.dart';
import 'package:gelatik/features/konsultasi/presentation/screens/konsultasi_detail_screen.dart';
import 'package:gelatik/features/konsultasi/providers/konsultasi_provider.dart';
import 'package:gelatik/features/konsultasi/repositories/konsultasi_repository.dart';
import 'package:gelatik/features/peminjaman/models/pinjam_model.dart';
import 'package:gelatik/features/peminjaman/providers/peminjaman_provider.dart';
import 'package:gelatik/features/peminjaman/repositories/peminjaman_repository.dart';
import 'package:intl/date_symbol_data_local.dart';

ApiClient _client() => ApiClient(secureStorageService: SecureStorageService());

const _user = UserModel(
  id: 10,
  name: 'User Baru',
  email: 'user@example.test',
  username: 'user10',
  noHp: '081200000010',
  namaOpd: 'OPD User',
  role: 'user',
  status: '1',
);

const _admin = UserModel(
  id: 99,
  name: 'Admin Baru',
  email: 'admin@example.test',
  username: 'admin99',
  noHp: '081200000099',
  namaOpd: 'Diskominfotik',
  role: 'admin',
  status: '1',
);

class _MasterRepository extends MasterItemRepository {
  _MasterRepository() : super(apiClient: _client());

  @override
  Future<List<MasterItemModel>> getItems({String? search}) async => const [];
}

class _LoanRepository extends PeminjamanRepository {
  List<PinjamModel> list;
  PinjamModel detail;
  Completer<List<PinjamModel>>? listCompleter;
  Completer<PinjamModel>? statusCompleter;
  int listCalls = 0;
  int detailCalls = 0;
  int statusCalls = 0;
  String? lastStatus;
  String? lastNote;

  _LoanRepository({
    required this.list,
    required this.detail,
    this.listCompleter,
    this.statusCompleter,
  }) : super(apiClient: _client());

  @override
  Future<List<PinjamModel>> getPeminjaman({int page = 1}) {
    listCalls++;
    return listCompleter?.future ?? Future.value(list);
  }

  @override
  Future<PinjamModel> getPeminjamanDetail(int id) async {
    detailCalls++;
    return detail;
  }

  @override
  Future<PinjamModel> updateStatus(int id, String status, {String? catatan}) {
    statusCalls++;
    lastStatus = status;
    lastNote = catatan;
    return statusCompleter?.future ??
        Future.value(detail.copyWith(status: status, catatanPetugas: catatan));
  }
}

class _ConsultationRepository extends KonsultasiRepository {
  List<KonsultasiModel> list;
  KonsultasiModel detail;
  Completer<List<KonsultasiModel>>? listCompleter;
  Completer<KonsultasiResponseModel>? answerCompleter;
  Completer<KonsultasiModel>? statusCompleter;
  int listCalls = 0;
  int detailCalls = 0;
  int answerCalls = 0;
  int statusCalls = 0;
  String? lastAnswer;
  String? lastStatus;

  _ConsultationRepository({
    required this.list,
    required this.detail,
    this.listCompleter,
    this.answerCompleter,
    this.statusCompleter,
  }) : super(apiClient: _client());

  @override
  Future<List<KonsultasiModel>> getKonsultasi({int page = 1}) {
    listCalls++;
    return listCompleter?.future ?? Future.value(list);
  }

  @override
  Future<KonsultasiModel> getDetail(int id) async {
    detailCalls++;
    return detail;
  }

  @override
  Future<KonsultasiResponseModel> answer(
    int id,
    BalasKonsultasiRequest request,
  ) {
    answerCalls++;
    lastAnswer = request.isiRespon;
    return answerCompleter?.future ??
        Future.value(
          KonsultasiResponseModel(
            id: 501,
            konsultasiId: id,
            userId: _admin.id,
            pesan: request.isiRespon,
            createdAt: DateTime(2026, 8, 10),
            userName: _admin.name,
          ),
        );
  }

  @override
  Future<KonsultasiModel> updateStatus(int id, String status) {
    statusCalls++;
    lastStatus = status;
    return statusCompleter?.future ??
        Future.value(detail.copyWith(status: status));
  }
}

PeminjamanNotifier _loanNotifier(_LoanRepository repository) {
  final notifier = PeminjamanNotifier(repository: repository);
  notifier.state = PeminjamanState(
    status: PeminjamanLoadStatus.success,
    listPinjam: repository.list,
    selectedPinjam: repository.detail,
  );
  return notifier;
}

KonsultasiNotifier _consultNotifier(_ConsultationRepository repository) {
  final notifier = KonsultasiNotifier(repository: repository);
  notifier.state = KonsultasiState(
    status: KonsultasiLoadStatus.success,
    listKonsultasi: repository.list,
    selectedKonsultasi: repository.detail,
  );
  return notifier;
}

AuthNotifier _auth(UserModel user) {
  final notifier = AuthNotifier();
  notifier.state = AuthState(isLoggedIn: true, currentUser: user);
  return notifier;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final loan = DummyData.pinjamList.firstWhere(
    (item) => item.status == 'Menunggu',
  );
  final consultation = DummyData.konsultasiList.first;

  group('role switching and admin navigation', () {
    test('user -> logout -> admin rebuilds role-derived Home state', () async {
      final auth = _auth(_user);
      final loanRepo = _LoanRepository(list: [loan], detail: loan);
      final consultRepo = _ConsultationRepository(
        list: [consultation],
        detail: consultation,
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          masterItemRepositoryProvider.overrideWithValue(_MasterRepository()),
          peminjamanRepositoryProvider.overrideWithValue(loanRepo),
          konsultasiRepositoryProvider.overrideWithValue(consultRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(homeProvider).data.isAdmin, isFalse);
      expect(container.read(homeProvider).data.userName, _user.name);

      await auth.logout();
      expect(auth.state.currentUser, isNull);
      expect(container.read(homeProvider).data.isAdmin, isFalse);

      auth.state = const AuthState(isLoggedIn: true, currentUser: _admin);
      expect(container.read(homeProvider).data.isAdmin, isTrue);
      expect(container.read(homeProvider).data.userName, _admin.name);
    });

    test('admin -> logout -> user clears stale admin capability', () async {
      final auth = _auth(_admin);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          masterItemRepositoryProvider.overrideWithValue(_MasterRepository()),
          peminjamanRepositoryProvider.overrideWithValue(
            _LoanRepository(list: [loan], detail: loan),
          ),
          konsultasiRepositoryProvider.overrideWithValue(
            _ConsultationRepository(list: [consultation], detail: consultation),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(homeProvider).data.isAdmin, isTrue);
      await auth.logout();
      auth.state = const AuthState(isLoggedIn: true, currentUser: _user);

      expect(container.read(homeProvider).data.isAdmin, isFalse);
      expect(container.read(homeProvider).data.userName, _user.name);
    });

    testWidgets('normal user direct admin route is blocked', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => _auth(_user))],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      expect(find.byKey(const Key('admin-access-denied')), findsOneWidget);
      expect(find.text('Kelola Peminjaman Aset'), findsNothing);
    });

    testWidgets('admin dashboard exposes all existing workflow entries', (
      tester,
    ) async {
      final loanRepo = _LoanRepository(list: [loan], detail: loan);
      final consultRepo = _ConsultationRepository(
        list: [consultation],
        detail: consultation,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _auth(_admin)),
            peminjamanProvider.overrideWith((ref) => _loanNotifier(loanRepo)),
            konsultasiProvider.overrideWith(
              (ref) => _consultNotifier(consultRepo),
            ),
            emailProvider.overrideWith((ref) => EmailNotifier()),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      expect(find.text('Kelola Peminjaman Aset'), findsOneWidget);
      expect(find.text('Kelola Konsultasi TIK'), findsOneWidget);
      expect(find.text('Kelola Usulan Email'), findsOneWidget);

      await tester.tap(find.text('Kelola Peminjaman Aset'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminPeminjamanListScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kelola Konsultasi TIK'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminKonsultasiListScreen), findsOneWidget);
    });
  });

  group('admin Peminjaman workflow', () {
    testWidgets('list loads repository data and opens admin detail', (
      tester,
    ) async {
      final pending = Completer<List<PinjamModel>>();
      final repository = _LoanRepository(
        list: [loan],
        detail: loan,
        listCompleter: pending,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _auth(_admin)),
            peminjamanProvider.overrideWith(
              (ref) => PeminjamanNotifier(repository: repository),
            ),
          ],
          child: const MaterialApp(home: AdminPeminjamanListScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete([loan]);
      await tester.pumpAndSettle();
      expect(find.text(loan.namaPic), findsOneWidget);

      await tester.tap(find.text(loan.namaPic));
      await tester.pumpAndSettle();
      expect(find.byType(AdminPeminjamanDetailScreen), findsOneWidget);
      expect(find.text('Nama Pemohon (PIC)'), findsOneWidget);
      expect(find.text(loan.instansiPic), findsWidgets);
      expect(find.text('Setujui'), findsOneWidget);
    });

    test(
      'status mutation refreshes state and rejects duplicate request',
      () async {
        final pending = Completer<PinjamModel>();
        final repository = _LoanRepository(
          list: [loan],
          detail: loan,
          statusCompleter: pending,
        );
        final notifier = _loanNotifier(repository);

        final first = notifier.setujuPeminjaman(loan.id);
        final duplicate = await notifier.setujuPeminjaman(loan.id);
        expect(duplicate, isFalse);
        expect(repository.statusCalls, 1);

        pending.complete(loan.copyWith(status: 'Proses'));
        expect(await first, isTrue);
        expect(notifier.state.selectedPinjam?.status, 'Proses');
        expect(notifier.state.listPinjam.single.status, 'Proses');
      },
    );

    test('valid rejection note is sent exactly once', () async {
      final repository = _LoanRepository(list: [loan], detail: loan);
      final notifier = _loanNotifier(repository);

      expect(
        await notifier.tolakPeminjaman(loan.id, 'Stok tidak tersedia'),
        isTrue,
      );
      expect(repository.statusCalls, 1);
      expect(repository.lastStatus, 'Ditolak');
      expect(repository.lastNote, 'Stok tidak tersedia');
    });

    testWidgets('normal user direct loan detail has no admin mutations', (
      tester,
    ) async {
      final repository = _LoanRepository(list: [loan], detail: loan);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _auth(_user)),
            peminjamanProvider.overrideWith((ref) => _loanNotifier(repository)),
          ],
          child: MaterialApp(
            home: AdminPeminjamanDetailScreen(pinjamId: loan.id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();

      expect(find.text('Setujui'), findsNothing);
      expect(find.text('Tolak'), findsNothing);
    });
  });

  group('admin Konsultasi workflow', () {
    testWidgets('list loads data, detail history, and admin actions', (
      tester,
    ) async {
      final pending = Completer<List<KonsultasiModel>>();
      final repository = _ConsultationRepository(
        list: [consultation],
        detail: consultation,
        listCompleter: pending,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _auth(_admin)),
            konsultasiProvider.overrideWith(
              (ref) => KonsultasiNotifier(repository: repository),
            ),
          ],
          child: const MaterialApp(home: AdminKonsultasiListScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete([consultation]);
      await tester.pumpAndSettle();
      expect(find.text(consultation.judul), findsOneWidget);
      await tester.tap(find.text(consultation.judul));
      await tester.pumpAndSettle();

      expect(find.byType(KonsultasiDetailScreen), findsOneWidget);
      expect(find.byKey(const Key('admin-status-actions')), findsOneWidget);
      expect(
        find.text('Balasan (${consultation.responses.length})'),
        findsOneWidget,
      );
    });

    test('response refreshes detail and duplicate submit is ignored', () async {
      final pending = Completer<KonsultasiResponseModel>();
      final response = KonsultasiResponseModel(
        id: 700,
        konsultasiId: consultation.id,
        userId: _admin.id,
        pesan: 'Silakan restart perangkat.',
        createdAt: DateTime(2026, 8, 10),
        userName: _admin.name,
      );
      final refreshed = consultation.copyWith(responses: [response]);
      final repository = _ConsultationRepository(
        list: [consultation],
        detail: refreshed,
        answerCompleter: pending,
      );
      final notifier = _consultNotifier(repository);

      final first = notifier.kirimBalasan(
        konsultasiId: consultation.id,
        isiRespon: response.pesan,
      );
      final duplicate = await notifier.kirimBalasan(
        konsultasiId: consultation.id,
        isiRespon: response.pesan,
      );
      expect(duplicate, isFalse);
      expect(repository.answerCalls, 1);

      pending.complete(response);
      expect(await first, isTrue);
      expect(repository.detailCalls, 1);
      expect(notifier.state.selectedKonsultasi?.responses, hasLength(1));
    });

    test(
      'status mutation updates detail and ignores duplicate submit',
      () async {
        final pending = Completer<KonsultasiModel>();
        final repository = _ConsultationRepository(
          list: [consultation],
          detail: consultation,
          statusCompleter: pending,
        );
        final notifier = _consultNotifier(repository);

        final first = notifier.ubahStatus(consultation.id, 'Diproses');
        final duplicate = await notifier.ubahStatus(
          consultation.id,
          'Diproses',
        );
        expect(duplicate, isFalse);
        expect(repository.statusCalls, 1);

        pending.complete(consultation.copyWith(status: 'Diproses'));
        expect(await first, isTrue);
        expect(notifier.state.selectedKonsultasi?.status, 'Diproses');
      },
    );

    testWidgets('normal user cannot gain admin actions from admin-view flag', (
      tester,
    ) async {
      final repository = _ConsultationRepository(
        list: [consultation],
        detail: consultation,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _auth(_user)),
            konsultasiProvider.overrideWith(
              (ref) => _consultNotifier(repository),
            ),
          ],
          child: MaterialApp(
            home: KonsultasiDetailScreen(
              konsultasi: consultation,
              isAdminView: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin-status-actions')), findsNothing);
      expect(repository.statusCalls, 0);
    });
  });
}
