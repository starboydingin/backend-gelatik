import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/admin/presentation/screens/admin_peminjaman_detail_screen.dart';
import 'package:gelatik/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:gelatik/features/admin/presentation/screens/admin_usulan_email_detail_screen.dart';
import 'package:gelatik/features/auth/models/user_model.dart';
import 'package:gelatik/features/auth/providers/auth_provider.dart';
import 'package:gelatik/features/email/models/usulan_email_model.dart';
import 'package:gelatik/features/email/providers/email_provider.dart';
import 'package:gelatik/features/email/repositories/email_repository.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';
import 'package:gelatik/features/home/models/home_dashboard_model.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';
import 'package:gelatik/features/peminjaman/models/pinjam_model.dart';
import 'package:gelatik/features/peminjaman/providers/peminjaman_provider.dart';
import 'package:gelatik/features/peminjaman/repositories/peminjaman_repository.dart';

class _AdminFakePeminjamanRepository extends PeminjamanRepository {
  final PinjamModel? detail;

  _AdminFakePeminjamanRepository({this.detail})
    : super(apiClient: ApiClient(secureStorageService: SecureStorageService()));

  @override
  Future<PinjamModel> getPeminjamanDetail(int id) async {
    return detail ?? DummyData.pinjamList.firstWhere((item) => item.id == id);
  }

  @override
  Future<PinjamModel> updateStatus(
    int id,
    String status, {
    String? catatan,
  }) async {
    final source =
        detail ?? DummyData.pinjamList.firstWhere((item) => item.id == id);
    return source.copyWith(status: status, catatanPetugas: catatan);
  }
}

class _AdminFakeEmailRepository extends EmailRepository {
  final Completer<UsulanEmailModel>? verifyCompleter;
  final Completer<UsulanEmailModel>? approveCompleter;
  int verifyCalls = 0;
  int approveCalls = 0;
  int rejectCalls = 0;

  _AdminFakeEmailRepository({this.verifyCompleter, this.approveCompleter})
    : super(apiClient: ApiClient(secureStorageService: SecureStorageService()));

  @override
  Future<UsulanEmailModel> verify(int id, {String? catatan}) {
    verifyCalls++;
    return verifyCompleter?.future ??
        Future.value(
          UsulanEmailModel(
            id: id,
            userId: 1,
            idPegBkd: 1,
            emailPribadi: 'pegawai@example.test',
            status: 'diajukan',
            diverifikasiOleh: 'Verifikator BKD',
            tanggalVerifikasi: DateTime(2026, 8, 10),
            catatan: catatan,
          ),
        );
  }

  @override
  Future<UsulanEmailModel> approve(int id, String emailResmi) {
    approveCalls++;
    return approveCompleter?.future ??
        Future.value(
          UsulanEmailModel(
            id: id,
            userId: 1,
            idPegBkd: 1,
            emailPribadi: 'pegawai@example.test',
            emailResmi: emailResmi,
            status: 'disetujui',
          ),
        );
  }

  @override
  Future<UsulanEmailModel> reject(int id, String catatan) async {
    rejectCalls++;
    return UsulanEmailModel(
      id: id,
      userId: 1,
      idPegBkd: 1,
      emailPribadi: 'pegawai@example.test',
      status: 'ditolak',
      catatan: catatan,
    );
  }
}

AuthNotifier _authFor(UserModel user) {
  final notifier = AuthNotifier();
  notifier.state = AuthState(isLoggedIn: true, currentUser: user);
  return notifier;
}

HomeNotifier _homePreview(UserModel user) => HomeNotifier.preview(
  HomeDashboardModel(
    userName: user.name,
    userRole: user.role,
    namaOpd: user.namaOpd,
    availableItemCount: 0,
    totalBorrowingCount: 0,
    totalConsultationCount: 0,
  ),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Panel Admin (M-L) Unit & Widget Tests', () {
    test('EmailRepository verify uses current backend contract', () async {
      final dio = Dio();
      late RequestOptions captured;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'id': 600,
                    'created_by': 1,
                    'id_peg_bkd': 1,
                    'email_pribadi': 'pegawai@example.test',
                    'status': 'diajukan',
                    'diverifikasi_oleh': 'BKD Test',
                    'tanggal_verifikasi': '2026-08-10T10:00:00Z',
                    'catatan': 'Dokumen valid',
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = EmailRepository(
        apiClient: ApiClient(
          secureStorageService: SecureStorageService(),
          baseUrl: 'https://example.invalid/api',
          dioOverride: dio,
        ),
      );

      final result = await repository.verify(600, catatan: 'Dokumen valid');

      expect(captured.method, 'POST');
      expect(captured.path, '/pengajuan-email/600/verifikasi');
      expect(captured.data, {'catatan': 'Dokumen valid'});
      expect(result.status, 'diajukan');
      expect(result.diverifikasiOleh, 'BKD Test');
    });

    testWidgets('1. Login as Admin displays 4th tab "Admin" in AppBottomNav', (
      tester,
    ) async {
      const adminUser = UserModel(
        id: 999,
        name: 'Admin Test',
        email: 'admin@lampungprov.go.id',
        username: 'admin999',
        noHp: '081234567890',
        namaOpd: 'Diskominfotik',
        role: 'admin',
        status: '1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith((ref) => _homePreview(adminUser)),
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.state = const AuthState(
                isLoggedIn: true,
                currentUser: adminUser,
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Admin tab exists
      expect(find.text('Admin'), findsOneWidget);
      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsOneWidget);
    });

    testWidgets('2. Login as regular User DOES NOT display 4th tab "Admin"', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith(
              (ref) => _homePreview(DummyData.activeUser),
            ),
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.state = AuthState(
                isLoggedIn: true,
                currentUser: DummyData.activeUser, // role: 'user'
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Admin tab DOES NOT exist
      expect(find.text('Admin'), findsNothing);
      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsNothing);
    });

    testWidgets('BKD dashboard exposes Email workflow only', (tester) async {
      const bkd = UserModel(
        id: 44,
        name: 'BKD Test',
        email: 'bkd@example.test',
        username: 'bkd44',
        noHp: '081244',
        namaOpd: 'BKD',
        role: 'bkd',
        status: '1',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _authFor(bkd)),
            peminjamanProvider.overrideWith(
              (ref) => PeminjamanNotifier(
                repository: _AdminFakePeminjamanRepository(),
              ),
            ),
            emailProvider.overrideWith((ref) => EmailNotifier()),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kelola Usulan Email'), findsOneWidget);
      expect(find.text('Kelola Peminjaman Aset'), findsNothing);
      expect(find.text('Kelola Konsultasi TIK'), findsNothing);
    });

    test(
      '3. Admin setujuPeminjaman updates status from "Menunggu" to "Proses" in provider',
      () async {
        final container = ProviderContainer(
          overrides: [
            peminjamanProvider.overrideWith((ref) {
              final notifier = PeminjamanNotifier(
                repository: _AdminFakePeminjamanRepository(),
              );
              notifier.state = PeminjamanState(
                listPinjam: List.from(DummyData.pinjamList),
              );
              return notifier;
            }),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(peminjamanProvider.notifier);
        final initialList = container.read(peminjamanProvider).listPinjam;

        // Find item with status 'Menunggu'
        final pendingItem = initialList.firstWhere(
          (p) => p.status == 'Menunggu',
        );

        final success = await notifier.setujuPeminjaman(pendingItem.id);

        final updatedState = container.read(peminjamanProvider);
        final updatedItem = updatedState.listPinjam.firstWhere(
          (p) => p.id == pendingItem.id,
        );

        expect(success, isTrue);
        expect(updatedItem.status, 'Proses');
      },
    );

    testWidgets(
      '4. Rejecting email proposal without entering notes triggers validation error',
      (tester) async {
        const usulanDiajukan = UsulanEmailModel(
          id: 501,
          userId: 1,
          idPegBkd: 1,
          emailPribadi: 'pegawai.test@gmail.com',
          status: 'diajukan',
          pegawai: {'nama': 'Pegawai Test', 'nip': '199001012020011001'},
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => _authFor(
                  const UserModel(
                    id: 999,
                    name: 'Admin Test',
                    email: 'admin@example.test',
                    username: 'admin',
                    noHp: '0812',
                    namaOpd: 'Diskominfotik',
                    role: 'admin',
                    status: '1',
                  ),
                ),
              ),
              emailProvider.overrideWith((ref) {
                final notifier = EmailNotifier();
                notifier.state = EmailState(
                  listPegawai: [],
                  listUsulanEmail: [usulanDiajukan],
                );
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: AdminUsulanEmailDetailScreen(usulanId: 501),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag scroll view up to reveal bottom action buttons
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tolak'));
        await tester.pumpAndSettle();

        // Tap Konfirmasi Tolak without typing notes
        await tester.tap(find.text('Konfirmasi Tolak'));
        await tester.pumpAndSettle();

        // Verify validation error appears
        expect(find.text('Catatan penolakan wajib diisi.'), findsOneWidget);
      },
    );

    test(
      '5. Admin setujuUsulanEmail updates status to "disetujui" and assigns emailResmi',
      () async {
        final container = ProviderContainer(
          overrides: [
            emailProvider.overrideWith((ref) {
              final notifier = EmailNotifier(
                repository: _AdminFakeEmailRepository(),
              );
              notifier.state = const EmailState(
                listUsulanEmail: [
                  UsulanEmailModel(
                    id: 501,
                    userId: 1,
                    idPegBkd: 1,
                    emailPribadi: 'pegawai@example.test',
                    status: 'diajukan',
                  ),
                ],
              );
              return notifier;
            }),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(emailProvider.notifier);
        final initialList = container.read(emailProvider).listUsulanEmail;

        final diajukanItem = initialList.firstWhere(
          (e) => e.status == 'diajukan',
        );

        final success = await notifier.setujuUsulanEmail(
          id: diajukanItem.id,
          emailResmi: '199501012022031001@lampungprov.go.id',
          adminName: 'Admin Diskominfo',
        );

        final updatedState = container.read(emailProvider);
        final updatedItem = updatedState.listUsulanEmail.firstWhere(
          (e) => e.id == diajukanItem.id,
        );

        expect(success, isTrue);
        expect(updatedItem.status, 'disetujui');
        expect(updatedItem.emailResmi, '199501012022031001@lampungprov.go.id');
      },
    );

    testWidgets(
      '6. AdminPeminjamanDetailScreen: Rejecting loan without notes triggers error and prevents submit',
      (tester) async {
        final pinjamPending = PinjamModel(
          id: 101,
          userId: 1,
          namaPic: 'Budi Santoso',
          jabatanPic: 'Staf TIK',
          instansiPic: 'Diskominfo',
          kontakPic: '08123456789',
          jenisIdentitas: 'KTP',
          nomorIdentitas: '1234567890',
          alamatPeminjam: 'Jl. Merdeka No. 1',
          jenisDurasi: 'harian',
          tanggalMulai: DateTime.now(),
          durasiPeminjaman: 3,
          status: 'Menunggu',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier();
                notifier.state = const AuthState(
                  isLoggedIn: true,
                  currentUser: UserModel(
                    id: 999,
                    name: 'Admin Test',
                    email: 'admin@test.go.id',
                    username: 'admin',
                    noHp: '0812',
                    namaOpd: 'Diskominfotik',
                    role: 'admin',
                    status: '1',
                  ),
                );
                return notifier;
              }),
              peminjamanProvider.overrideWith((ref) {
                final notifier = PeminjamanNotifier(
                  repository: _AdminFakePeminjamanRepository(
                    detail: pinjamPending,
                  ),
                );
                notifier.state = PeminjamanState(listPinjam: [pinjamPending]);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: AdminPeminjamanDetailScreen(pinjamId: 101),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag scroll view up to reveal bottom action buttons
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();

        // Tap Tolak button to open dialog
        await tester.tap(find.text('Tolak'));
        await tester.pumpAndSettle();

        // Tap Konfirmasi Tolak without typing notes
        await tester.tap(find.text('Konfirmasi Tolak'));
        await tester.pumpAndSettle();

        // Verify validation error appears
        expect(find.text('Catatan penolakan wajib diisi.'), findsOneWidget);

        // Verify dialog is STILL present (submit was prevented)
        expect(find.text('Tolak Pengajuan Peminjaman'), findsOneWidget);
      },
    );

    testWidgets(
      '7. AdminUsulanEmailDetailScreen: Approving email with empty emailResmi triggers error and prevents submit',
      (tester) async {
        const usulanDiajukan = UsulanEmailModel(
          id: 502,
          userId: 1,
          idPegBkd: 1,
          emailPribadi: 'pegawai.test2@gmail.com',
          status: 'diajukan',
          pegawai: {'nama': 'Pegawai Test 2', 'nip': '199501012022031002'},
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => _authFor(
                  const UserModel(
                    id: 999,
                    name: 'Admin Test',
                    email: 'admin@example.test',
                    username: 'admin',
                    noHp: '0812',
                    namaOpd: 'Diskominfotik',
                    role: 'admin',
                    status: '1',
                  ),
                ),
              ),
              emailProvider.overrideWith((ref) {
                final notifier = EmailNotifier();
                notifier.state = const EmailState(
                  listPegawai: [],
                  listUsulanEmail: [usulanDiajukan],
                );
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: AdminUsulanEmailDetailScreen(usulanId: 502),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag scroll view up to reveal bottom action buttons
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();

        // Tap Setujui & Buat to open dialog
        await tester.tap(find.text('Setujui & Buat'));
        await tester.pumpAndSettle();

        // Clear the pre-filled email input
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();

        // Tap Setujui & Buat in the dialog with empty text
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(ElevatedButton, 'Setujui & Buat'),
          ),
        );
        await tester.pumpAndSettle();

        // Verify validation error appears
        expect(find.text('Alamat email resmi wajib diisi.'), findsOneWidget);

        // Verify dialog is STILL present (submit was prevented)
        expect(find.text('Setujui & Buat Email Resmi'), findsOneWidget);
      },
    );

    test(
      '8. BKD verify refreshes item and prevents duplicate mutation',
      () async {
        final pending = Completer<UsulanEmailModel>();
        final repository = _AdminFakeEmailRepository(verifyCompleter: pending);
        final notifier = EmailNotifier(repository: repository);
        notifier.state = const EmailState(
          listUsulanEmail: [
            UsulanEmailModel(
              id: 601,
              userId: 1,
              idPegBkd: 1,
              emailPribadi: 'pegawai@example.test',
              status: 'diajukan',
            ),
          ],
        );

        final first = notifier.verifikasiUsulanEmail(
          id: 601,
          catatan: 'Dokumen valid',
        );
        final duplicate = await notifier.verifikasiUsulanEmail(id: 601);
        expect(duplicate, isFalse);
        expect(repository.verifyCalls, 1);

        pending.complete(
          UsulanEmailModel(
            id: 601,
            userId: 1,
            idPegBkd: 1,
            emailPribadi: 'pegawai@example.test',
            status: 'diajukan',
            diverifikasiOleh: 'Verifikator BKD',
            tanggalVerifikasi: DateTime(2026, 8, 10),
          ),
        );
        expect(await first, isTrue);
        expect(
          notifier.state.listUsulanEmail.single.diverifikasiOleh,
          'Verifikator BKD',
        );
      },
    );

    test(
      'approve also rejects duplicate mutation while request is active',
      () async {
        final pending = Completer<UsulanEmailModel>();
        final repository = _AdminFakeEmailRepository(approveCompleter: pending);
        final notifier = EmailNotifier(repository: repository);
        notifier.state = const EmailState(
          listUsulanEmail: [
            UsulanEmailModel(
              id: 604,
              userId: 1,
              idPegBkd: 1,
              emailPribadi: 'pegawai@example.test',
              status: 'diajukan',
            ),
          ],
        );

        final first = notifier.setujuUsulanEmail(
          id: 604,
          emailResmi: 'pegawai@lampungprov.go.id',
        );
        expect(
          await notifier.tolakUsulanEmail(id: 604, catatan: 'Duplikat'),
          isFalse,
        );
        expect(repository.approveCalls, 1);
        expect(repository.rejectCalls, 0);

        pending.complete(
          const UsulanEmailModel(
            id: 604,
            userId: 1,
            idPegBkd: 1,
            emailPribadi: 'pegawai@example.test',
            emailResmi: 'pegawai@lampungprov.go.id',
            status: 'disetujui',
          ),
        );
        expect(await first, isTrue);
      },
    );

    testWidgets('9. BKD sees verify/reject but not create-email action', (
      tester,
    ) async {
      final repository = _AdminFakeEmailRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => _authFor(
                const UserModel(
                  id: 44,
                  name: 'BKD Test',
                  email: 'bkd@example.test',
                  username: 'bkd44',
                  noHp: '081244',
                  namaOpd: 'BKD',
                  role: 'bkd',
                  status: '1',
                ),
              ),
            ),
            emailProvider.overrideWith((ref) {
              final notifier = EmailNotifier(repository: repository);
              notifier.state = const EmailState(
                listUsulanEmail: [
                  UsulanEmailModel(
                    id: 602,
                    userId: 1,
                    idPegBkd: 1,
                    emailPribadi: 'pegawai@example.test',
                    status: 'diajukan',
                  ),
                ],
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: AdminUsulanEmailDetailScreen(usulanId: 602),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verify-email-proposal')), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
      expect(find.text('Setujui & Buat'), findsNothing);
    });

    testWidgets('10. normal user direct Email detail has no admin controls', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _authFor(DummyData.activeUser)),
            emailProvider.overrideWith((ref) {
              final notifier = EmailNotifier();
              notifier.state = const EmailState(
                listUsulanEmail: [
                  UsulanEmailModel(
                    id: 603,
                    userId: 1,
                    idPegBkd: 1,
                    emailPribadi: 'pegawai@example.test',
                    status: 'diajukan',
                  ),
                ],
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: AdminUsulanEmailDetailScreen(usulanId: 603),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verify-email-proposal')), findsNothing);
      expect(find.text('Tolak'), findsNothing);
      expect(find.text('Setujui & Buat'), findsNothing);
    });
  });
}
