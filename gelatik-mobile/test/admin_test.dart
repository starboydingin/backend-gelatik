import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/admin/presentation/screens/admin_peminjaman_detail_screen.dart';
import 'package:gelatik/features/admin/presentation/screens/admin_usulan_email_detail_screen.dart';
import 'package:gelatik/features/auth/models/user_model.dart';
import 'package:gelatik/features/auth/providers/auth_provider.dart';
import 'package:gelatik/features/email/models/usulan_email_model.dart';
import 'package:gelatik/features/email/providers/email_provider.dart';
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
        final container = ProviderContainer();
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
  });
}
