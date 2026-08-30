import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/models/paginated_result.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/auth/models/user_model.dart';
import 'package:gelatik/features/home/models/home_dashboard_model.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';
import 'package:gelatik/features/home/repositories/announcement_repository.dart';
import 'package:gelatik/features/info_alat/models/master_item_model.dart';
import 'package:gelatik/features/info_alat/repositories/master_item_repository.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_model.dart';
import 'package:gelatik/features/konsultasi/presentation/screens/konsultasi_list_screen.dart';
import 'package:gelatik/features/konsultasi/repositories/konsultasi_repository.dart';
import 'package:gelatik/features/notifications/models/gelatik_notification.dart';
import 'package:gelatik/features/notifications/repositories/notification_repository.dart';
import 'package:gelatik/features/peminjaman/models/pinjam_model.dart';
import 'package:gelatik/features/peminjaman/presentation/screens/peminjaman_list_screen.dart';
import 'package:gelatik/features/peminjaman/repositories/peminjaman_repository.dart';

ApiClient _client() =>
    ApiClient(secureStorageService: SecureStorageService(), dioOverride: Dio());

const _user = UserModel(
  id: 7,
  name: 'Pengguna Home',
  email: 'user@example.test',
  username: 'user7',
  noHp: '0812',
  namaOpd: 'OPD Pengujian',
  role: 'user',
  status: '1',
);

const _admin = UserModel(
  id: 9,
  name: 'Admin Home',
  email: 'admin@example.test',
  username: 'admin9',
  noHp: '0813',
  namaOpd: 'Diskominfotik',
  role: 'admin',
  status: '1',
);

const _item = MasterItemModel(id: 3, nama: 'Laptop', stok: 4);
const _emptyItem = MasterItemModel(id: 4, nama: 'Proyektor', stok: 0);

final _borrowing = PinjamModel(
  id: 11,
  userId: 7,
  namaPic: 'PIC Home',
  jabatanPic: 'Staf',
  instansiPic: 'OPD Pengujian',
  kontakPic: '0812',
  jenisIdentitas: 'NIP',
  nomorIdentitas: '123',
  alamatPeminjam: 'Bandar Lampung',
  jenisDurasi: 'harian',
  tanggalMulai: DateTime(2026, 8, 5),
  durasiPeminjaman: 2,
  status: 'Menunggu',
  createdAt: DateTime(2026, 8, 5),
);

final _consultation = KonsultasiModel(
  id: 21,
  userId: 7,
  judul: 'Konsultasi Home',
  pesan: 'Isi konsultasi',
  status: 'Diproses',
  createdAt: DateTime(2026, 8, 5),
);

PaginatedResult<PinjamModel> _borrowPage({
  List<PinjamModel>? items,
  int total = 12,
}) => PaginatedResult(
  items: items ?? [_borrowing],
  total: total,
  currentPage: 1,
  lastPage: total == 0 ? 1 : 2,
);

PaginatedResult<KonsultasiModel> _consultPage({
  List<KonsultasiModel>? items,
  int total = 8,
}) => PaginatedResult(
  items: items ?? [_consultation],
  total: total,
  currentPage: 1,
  lastPage: total == 0 ? 1 : 1,
);

class _FakeMasterRepository extends MasterItemRepository {
  Future<List<MasterItemModel>> Function() handler;
  int calls = 0;

  _FakeMasterRepository(this.handler) : super(apiClient: _client());

  @override
  Future<List<MasterItemModel>> getItems() {
    calls++;
    return handler();
  }
}

class _FakeBorrowingRepository extends PeminjamanRepository {
  Future<PaginatedResult<PinjamModel>> Function() handler;
  int calls = 0;

  _FakeBorrowingRepository(this.handler) : super(apiClient: _client());

  @override
  Future<PaginatedResult<PinjamModel>> getPeminjamanPage({int page = 1}) {
    calls++;
    return handler();
  }
}

class _FakeConsultationRepository extends KonsultasiRepository {
  Future<PaginatedResult<KonsultasiModel>> Function() handler;
  int calls = 0;

  _FakeConsultationRepository(this.handler) : super(apiClient: _client());

  @override
  Future<PaginatedResult<KonsultasiModel>> getKonsultasiPage({int page = 1}) {
    calls++;
    return handler();
  }
}

class _FakeNotificationRepository extends NotificationRepository {
  _FakeNotificationRepository()
    : super(
        apiClient: _client(),
        storage: SecureStorageService(),
        userId: _user.id,
      );

  @override
  Future<List<GelatikNotification>> getNotifications() async => const [];
}

HomeNotifier _notifier({
  _FakeMasterRepository? items,
  _FakeBorrowingRepository? borrowings,
  _FakeConsultationRepository? consultations,
  UserModel user = _user,
}) => HomeNotifier(
  masterItemRepository:
      items ?? _FakeMasterRepository(() async => const [_item, _emptyItem]),
  peminjamanRepository:
      borrowings ?? _FakeBorrowingRepository(() async => _borrowPage()),
  konsultasiRepository:
      consultations ?? _FakeConsultationRepository(() async => _consultPage()),
  user: user,
);

HomeDashboardModel _dashboard({
  String role = 'user',
  int? items = 1,
  int? borrowings = 12,
  int? consultations = 8,
  bool recent = true,
}) => HomeDashboardModel(
  userName: role == 'admin' ? 'Admin Home' : 'Pengguna Home',
  userRole: role,
  namaOpd: 'OPD Pengujian dengan nama yang cukup panjang untuk UI',
  availableItemCount: items,
  totalBorrowingCount: borrowings,
  totalConsultationCount: consultations,
  recentBorrowings: recent ? [_borrowing] : const [],
  recentConsultations: recent ? [_consultation] : const [],
);

void main() {
  group('HomeDashboardModel', () {
    test('maps regular user identity and section data', () {
      final model = HomeDashboardModel.fromSources(
        user: _user,
        items: const [_item, _emptyItem],
        borrowings: _borrowPage(),
        consultations: _consultPage(),
      );
      expect(model.userName, 'Pengguna Home');
      expect(model.isAdmin, isFalse);
      expect(model.availableItemCount, 1);
    });

    test('maps admin role without changing backend totals', () {
      final model = HomeDashboardModel.fromSources(
        user: _admin,
        borrowings: _borrowPage(total: 44),
        consultations: _consultPage(total: 33),
      );
      expect(model.isAdmin, isTrue);
      expect(model.totalBorrowingCount, 44);
      expect(model.totalConsultationCount, 33);
    });

    test('BKD receives Email admin-panel capability without admin role', () {
      final data = _dashboard(role: 'bkd');

      expect(data.isAdmin, isFalse);
      expect(data.canAccessAdminPanel, isTrue);
    });

    test('keeps failed nullable sections distinct from zero', () {
      final model = HomeDashboardModel.fromSources(user: _user);
      expect(model.availableItemCount, isNull);
      expect(model.totalBorrowingCount, isNull);
      expect(model.isEmpty, isFalse);
    });

    test('unknown role and status do not crash', () {
      final unknown = _consultation.copyWith(status: 'Legacy');
      final model = HomeDashboardModel.fromSources(
        user: const UserModel(
          id: 1,
          name: 'Unknown',
          email: '',
          username: '',
          noHp: '',
          namaOpd: '',
          role: 'operator-legacy',
          status: '1',
        ),
        consultations: _consultPage(items: [unknown]),
      );
      expect(model.isAdmin, isFalse);
      expect(model.recentConsultations.single.status, 'Legacy');
    });

    test('uses paginator total instead of first-page item length', () {
      final model = HomeDashboardModel.fromSources(
        user: _user,
        borrowings: _borrowPage(items: [_borrowing], total: 87),
        consultations: _consultPage(items: [_consultation], total: 65),
      );
      expect(model.recentBorrowings.length, 1);
      expect(model.totalBorrowingCount, 87);
      expect(model.totalConsultationCount, 65);
    });
  });

  group('HomeNotifier', () {
    test('initial load succeeds with three parallel sections', () async {
      final notifier = _notifier();
      await notifier.load();
      expect(notifier.state.status, HomeLoadStatus.success);
      expect(notifier.state.data.availableItemCount, 1);
      expect(notifier.state.data.totalBorrowingCount, 12);
      expect(notifier.state.data.totalConsultationCount, 8);
    });

    test('all successful empty sources become empty', () async {
      final notifier = _notifier(
        items: _FakeMasterRepository(() async => const []),
        borrowings: _FakeBorrowingRepository(
          () async => _borrowPage(items: const [], total: 0),
        ),
        consultations: _FakeConsultationRepository(
          () async => _consultPage(items: const [], total: 0),
        ),
      );
      await notifier.load();
      expect(notifier.state.status, HomeLoadStatus.empty);
    });

    test('all failed sections become full error', () async {
      final error = MasterItemRepositoryException(
        message: 'offline',
        type: MasterItemErrorType.network,
      );
      final notifier = _notifier(
        items: _FakeMasterRepository(() async => throw error),
        borrowings: _FakeBorrowingRepository(
          () async => throw PeminjamanRepositoryException(
            message: 'offline',
            type: PeminjamanErrorType.network,
          ),
        ),
        consultations: _FakeConsultationRepository(
          () async => throw KonsultasiRepositoryException(
            message: 'offline',
            type: KonsultasiErrorType.network,
          ),
        ),
      );
      await notifier.load();
      expect(notifier.state.status, HomeLoadStatus.error);
      expect(notifier.state.sectionErrors.length, 3);
    });

    test(
      'one failed section becomes partial success without fake zero',
      () async {
        final notifier = _notifier(
          items: _FakeMasterRepository(
            () async => throw MasterItemRepositoryException(
              message: 'Katalog gagal',
              type: MasterItemErrorType.server,
            ),
          ),
        );
        await notifier.load();
        expect(notifier.state.status, HomeLoadStatus.partialSuccess);
        expect(notifier.state.data.availableItemCount, isNull);
        expect(notifier.state.data.totalBorrowingCount, 12);
        expect(notifier.state.sectionErrors, contains(HomeSection.items));
      },
    );

    test('refresh reloads each repository', () async {
      final items = _FakeMasterRepository(() async => const [_item]);
      final borrow = _FakeBorrowingRepository(() async => _borrowPage());
      final consult = _FakeConsultationRepository(() async => _consultPage());
      final notifier = _notifier(
        items: items,
        borrowings: borrow,
        consultations: consult,
      );
      await notifier.load();
      await notifier.refresh();
      expect(items.calls, 2);
      expect(borrow.calls, 2);
      expect(consult.calls, 2);
    });

    test('realtime event uses the same authoritative Home refresh', () async {
      final items = _FakeMasterRepository(() async => const [_item]);
      final borrow = _FakeBorrowingRepository(() async => _borrowPage());
      final consult = _FakeConsultationRepository(() async => _consultPage());
      final notifier = _notifier(
        items: items,
        borrowings: borrow,
        consultations: consult,
      );

      await notifier.load();
      await notifier.refreshFromRealtime();

      expect(items.calls, 2);
      expect(borrow.calls, 2);
      expect(consult.calls, 2);
    });

    test('unauthorized section invalidates the Home session state', () async {
      final notifier = _notifier(
        items: _FakeMasterRepository(
          () async => throw MasterItemRepositoryException(
            message: 'Unauthorized',
            type: MasterItemErrorType.unauthorized,
          ),
        ),
      );
      await notifier.load();
      expect(notifier.state.status, HomeLoadStatus.error);
      expect(notifier.state.errorType, HomeErrorType.unauthorized);
    });

    test('stale initial response cannot overwrite refresh', () async {
      final oldItems = Completer<List<MasterItemModel>>();
      var call = 0;
      final repository = _FakeMasterRepository(
        () => call++ == 0 ? oldItems.future : Future.value(const [_item]),
      );
      final notifier = _notifier(items: repository);
      final oldLoad = notifier.load();
      final refresh = notifier.refresh();
      await refresh;
      oldItems.complete(const [_emptyItem]);
      await oldLoad;
      expect(notifier.state.data.availableItemCount, 1);
    });

    test('duplicate load while active is ignored', () async {
      final completer = Completer<List<MasterItemModel>>();
      final repository = _FakeMasterRepository(() => completer.future);
      final notifier = _notifier(items: repository);
      final first = notifier.load();
      await notifier.load();
      expect(repository.calls, 1);
      completer.complete(const [_item]);
      await first;
    });
  });

  group('Home UI', () {
    testWidgets('shows section loading indicators', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAnnouncementsProvider.overrideWith((ref) async => const []),
            notificationRepositoryProvider.overrideWith(
              (ref) => _FakeNotificationRepository(),
            ),
            homeProvider.overrideWith(
              (ref) => HomeNotifier.preview(
                _dashboard(items: null, borrowings: null, consultations: null),
                status: HomeLoadStatus.loading,
              ),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      await _scrollHomeTo(tester, find.byType(CircularProgressIndicator));
      expect(find.byType(CircularProgressIndicator), findsNWidgets(4));
    });

    testWidgets('renders user success totals and recent data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAnnouncementsProvider.overrideWith((ref) async => const []),
            homeProvider.overrideWith(
              (ref) => HomeNotifier.preview(_dashboard()),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pengguna Home'), findsOneWidget);
      await _scrollHomeTo(tester, find.text('12'));
      expect(find.text('12'), findsOneWidget);
      await _scrollHomeTo(tester, find.text('PIC Home'));
      expect(find.text('PIC Home'), findsOneWidget);
      expect(find.text('Konsultasi Home'), findsOneWidget);
      expect(find.text('Admin'), findsNothing);
    });

    testWidgets(
      'renders an active announcement even when dashboard data is empty',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeAnnouncementsProvider.overrideWith(
                (ref) async => const [
                  Announcement(
                    title: 'Pemeliharaan layanan',
                    content: 'Layanan akan dipelihara malam ini.',
                  ),
                ],
              ),
              homeProvider.overrideWith(
                (ref) => HomeNotifier.preview(_dashboard()),
              ),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );

        await tester.pumpAndSettle();

        await _scrollHomeTo(tester, find.text('Pengumuman terbaru'));

        expect(find.text('Pengumuman terbaru'), findsOneWidget);
        expect(find.text('Pemeliharaan layanan'), findsOneWidget);
        expect(find.text('Layanan akan dipelihara malam ini.'), findsOneWidget);
      },
    );

    testWidgets('announcement carousel supports swipe and autoplay', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAnnouncementsProvider.overrideWith(
              (ref) async => const [
                Announcement(title: 'Pengumuman pertama', content: 'Satu'),
                Announcement(title: 'Pengumuman kedua', content: 'Dua'),
              ],
            ),
            homeProvider.overrideWith(
              (ref) => HomeNotifier.preview(_dashboard()),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollHomeTo(
        tester,
        find.byKey(const Key('announcement-carousel')),
      );

      PageView carousel() => tester.widget<PageView>(
        find.byKey(const Key('announcement-carousel')),
      );
      expect(carousel().controller?.page, closeTo(0, 0.01));
      await tester.fling(
        find.byKey(const Key('announcement-carousel')),
        const Offset(-600, 0),
        1200,
      );
      await tester.pumpAndSettle();
      expect(carousel().controller?.page, closeTo(1, 0.01));

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
      expect(carousel().controller?.page, closeTo(0, 0.01));
    });

    testWidgets('admin sees role-aware Admin tab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAnnouncementsProvider.overrideWith((ref) async => const []),
            homeProvider.overrideWith(
              (ref) => HomeNotifier.preview(_dashboard(role: 'admin')),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('empty sections show explicit empty messages', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAnnouncementsProvider.overrideWith((ref) async => const []),
            homeProvider.overrideWith(
              (ref) => HomeNotifier.preview(
                _dashboard(
                  items: 0,
                  borrowings: 0,
                  consultations: 0,
                  recent: false,
                ),
                status: HomeLoadStatus.empty,
              ),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await _scrollHomeTo(tester, find.text('Belum ada peminjaman.'));
      expect(find.text('Belum ada peminjaman.'), findsOneWidget);
      expect(find.text('Belum ada konsultasi.'), findsOneWidget);
    });

    testWidgets('partial error keeps successful sections visible', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAnnouncementsProvider.overrideWith((ref) async => const []),
            homeProvider.overrideWith(
              (ref) => HomeNotifier.preview(
                _dashboard(items: null),
                status: HomeLoadStatus.partialSuccess,
                sectionErrors: const {HomeSection.items: 'Katalog gagal'},
              ),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await _scrollHomeTo(tester, find.byKey(const Key('home-partial-error')));
      expect(find.byKey(const Key('home-partial-error')), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('full error retries and recovers', (tester) async {
      var fail = true;
      final items = _FakeMasterRepository(() async {
        if (fail) {
          throw MasterItemRepositoryException(
            message: 'offline',
            type: MasterItemErrorType.network,
          );
        }
        return const [_item];
      });
      final borrow = _FakeBorrowingRepository(() async {
        if (fail) {
          throw PeminjamanRepositoryException(
            message: 'offline',
            type: PeminjamanErrorType.network,
          );
        }
        return _borrowPage();
      });
      final consult = _FakeConsultationRepository(() async {
        if (fail) {
          throw KonsultasiRepositoryException(
            message: 'offline',
            type: KonsultasiErrorType.network,
          );
        }
        return _consultPage();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAnnouncementsProvider.overrideWith((ref) async => const []),
            homeProvider.overrideWith(
              (ref) => HomeNotifier(
                masterItemRepository: items,
                peminjamanRepository: borrow,
                konsultasiRepository: consult,
                user: _user,
              ),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-retry')), findsOneWidget);
      fail = false;
      await tester.tap(find.byKey(const Key('home-retry')));
      await tester.pumpAndSettle();
      await _scrollHomeTo(tester, find.text('PIC Home'));
      expect(find.text('PIC Home'), findsOneWidget);
    });

    testWidgets('pull to refresh reloads dashboard sources', (tester) async {
      final items = _FakeMasterRepository(() async => const [_item]);
      final borrow = _FakeBorrowingRepository(() async => _borrowPage());
      final consult = _FakeConsultationRepository(() async => _consultPage());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAnnouncementsProvider.overrideWith((ref) async => const []),
            homeProvider.overrideWith(
              (ref) => HomeNotifier(
                masterItemRepository: items,
                peminjamanRepository: borrow,
                konsultasiRepository: consult,
                user: _user,
              ),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('home-scroll')),
        const Offset(0, 350),
      );
      await tester.pumpAndSettle();
      expect(items.calls, 2);
      expect(borrow.calls, 2);
      expect(consult.calls, 2);
    });

    testWidgets('summary borrowing navigates to Peminjaman', (tester) async {
      await _pumpNavigationHome(tester);
      await _scrollHomeTo(tester, find.text('Peminjaman aktif'));
      await tester.tap(find.text('Peminjaman aktif'));
      await tester.pumpAndSettle();
      expect(find.byType(PeminjamanListScreen), findsOneWidget);
    });

    testWidgets('summary consultation navigates to Konsultasi', (tester) async {
      await _pumpNavigationHome(tester);
      await _scrollHomeTo(tester, find.text('Konsultasi aktif'));
      await tester.tap(find.text('Konsultasi aktif'));
      await tester.pumpAndSettle();
      expect(find.byType(KonsultasiListScreen), findsOneWidget);
    });
  });
}

Future<void> _scrollHomeTo(WidgetTester tester, Finder target) async {
  final homeScroll = find.byKey(const Key('home-scroll'));
  for (var attempt = 0; attempt < 12 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(homeScroll, const Offset(0, -360));
    await tester.pump(const Duration(milliseconds: 120));
  }
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target.first);
  }
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _pumpNavigationHome(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeAnnouncementsProvider.overrideWith((ref) async => const []),
        masterItemRepositoryProvider.overrideWithValue(
          _FakeMasterRepository(() async => const [_item]),
        ),
        peminjamanRepositoryProvider.overrideWithValue(
          _FakeBorrowingRepository(() async => _borrowPage()),
        ),
        konsultasiRepositoryProvider.overrideWithValue(
          _FakeConsultationRepository(() async => _consultPage()),
        ),
        homeProvider.overrideWith((ref) => HomeNotifier.preview(_dashboard())),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
