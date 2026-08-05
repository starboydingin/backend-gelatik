import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/features/email/providers/email_provider.dart';
import 'package:gelatik/features/email/presentation/screens/daftar_pegawai_screen.dart';
import 'package:gelatik/features/internet/presentation/screens/layanan_internet_screen.dart';
import 'package:gelatik/features/info_alat/models/master_item_model.dart';
import 'package:gelatik/features/info_alat/providers/info_alat_provider.dart';
import 'package:gelatik/features/info_alat/presentation/screens/info_alat_screen.dart';
import 'package:gelatik/features/info_alat/repositories/master_item_repository.dart';
import 'package:gelatik/features/kritik_saran/providers/kritik_saran_provider.dart';
import 'package:gelatik/features/kritik_saran/presentation/screens/kritik_saran_screen.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';

class MockInfoAlatNotifier extends InfoAlatNotifier {
  MockInfoAlatNotifier({List<MasterItemModel> items = DummyData.masterItems})
    : super(
        repository: MasterItemRepository(
          apiClient: ApiClient(secureStorageService: SecureStorageService()),
        ),
      ) {
    state = InfoAlatState(status: InfoAlatStatus.success, items: items);
  }

  @override
  Future<void> loadItems({bool force = false}) async {}
}

void main() {
  group('Modules M-E s.d. M-H Unit & Widget Tests', () {
    test(
      '1. Submit Usulan Email Resmi (tambahUsulanEmail) creates item with LOWERCASE status "diajukan"',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(emailProvider.notifier);

        final pegawaiData = DummyData.pegawaiBelumPunyaEmail[0];

        final success = await notifier.tambahUsulanEmail(
          userId: 1,
          pegawaiData: pegawaiData,
          emailPribadi: 'endang.rahmawati79@gmail.com',
        );

        expect(success, isTrue);

        final state = container.read(emailProvider);
        final newlySubmitted = state.listUsulanEmail.first;

        // VERIFIKASI STATUS MUST BE LOWERCASE 'diajukan'
        expect(newlySubmitted.status, 'diajukan');
        expect(newlySubmitted.status, isNot('Diajukan'));
        expect(newlySubmitted.emailPribadi, 'endang.rahmawati79@gmail.com');
        expect(newlySubmitted.namaPegawai, 'Dra. Endang Rahmawati, M.Si.');
      },
    );

    test(
      '2. Submit Kritik & Saran (submitKritikSaran) succeeds without error',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(kritikSaranProvider.notifier);

        final success = await notifier.submitKritikSaran(
          userId: 1,
          kritik:
              'Aplikasi sudah bagus, namun mohon tambahkan notifikasi realtime.',
          saran:
              'Integrasi dengan WhatsApp gateway untuk pengingat tenggat pengembalian.',
        );

        expect(success, isTrue);
        expect(
          container.read(kritikSaranProvider).successMessage,
          'Kritik & Saran berhasil dikirimkan!',
        );
      },
    );

    testWidgets(
      '3. LayananInternetScreen renders bandwidth statistics and router cards',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: LayananInternetScreen()),
          ),
        );

        expect(find.text('Layanan Internet OPD'), findsOneWidget);
        expect(find.text('DOWNLOAD'), findsOneWidget);
        expect(find.text('UPLOAD'), findsOneWidget);
        expect(find.text('500'), findsNWidgets(2));
        expect(find.text('Buat Pengaduan Internet'), findsOneWidget);
      },
    );

    testWidgets(
      '4. DaftarPegawaiScreen renders list of employees without email',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: DaftarPegawaiScreen())),
        );

        expect(find.text('Usulkan Email Pegawai'), findsOneWidget);
        expect(find.text('Dra. Endang Rahmawati, M.Si.'), findsOneWidget);
        expect(find.text('Ir. Bambang Triyono, M.T.'), findsOneWidget);
      },
    );

    testWidgets('5. InfoAlatScreen renders catalog items in READ-ONLY mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            infoAlatProvider.overrideWith((ref) => MockInfoAlatNotifier()),
          ],
          child: const MaterialApp(home: InfoAlatScreen()),
        ),
      );

      expect(find.text('Katalog Alat TIK'), findsOneWidget);
      expect(find.text('Laptop Lenovo ThinkPad L14 Gen 3'), findsOneWidget);
      expect(find.text('Proyektor Epson EB-X05'), findsOneWidget);

      // Verify NO quantity steppers / selection buttons exist
      expect(find.byIcon(Icons.remove), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets(
      '5b. InfoAlatScreen renders items from InfoAlatProvider when overridden',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              infoAlatProvider.overrideWith(
                (ref) => MockInfoAlatNotifier(
                  items: const [
                    MasterItemModel(
                      id: 99,
                      nama: 'Alat Custom dari Provider Override',
                      deskripsi: 'Deskripsi Override Provider',
                      kondisi: 'Baik',
                      stok: 5,
                    ),
                  ],
                ),
              ),
            ],
            child: const MaterialApp(home: InfoAlatScreen()),
          ),
        );

        expect(find.text('Katalog Alat TIK'), findsOneWidget);
        expect(find.text('Alat Custom dari Provider Override'), findsOneWidget);
        expect(find.text('Laptop Lenovo ThinkPad L14 Gen 3'), findsNothing);
      },
    );

    testWidgets(
      '6. KritikSaranScreen form submit shows confirmation dialog and closes',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: KritikSaranScreen())),
        );

        expect(find.text('Form Kritik & Saran'), findsOneWidget);

        // Enter Kritik & Saran
        await tester.enterText(
          find.byType(TextField).at(0),
          'Perlu peningkatan antarmuka.',
        );
        await tester.enterText(
          find.byType(TextField).at(1),
          'Tambahkan fitur dark mode otomatis.',
        );

        // Tap Kirim
        await tester.tap(find.text('Kirim Kritik & Saran'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Verify Success Dialog is rendered
        expect(find.text('Terima Kasih!'), findsOneWidget);
        expect(find.text('Tutup & Kembali'), findsOneWidget);
      },
    );

    testWidgets('7. HomeScreen navigates to all 4 new modules successfully', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );

      expect(find.text('Gelatik Dashboard'), findsOneWidget);
      expect(find.text('Layanan Internet'), findsOneWidget);
      expect(find.text('Usulan Email'), findsOneWidget);
      expect(find.text('Info Alat TIK'), findsOneWidget);
      expect(find.text('Kritik & Saran'), findsOneWidget);

      // Tap Layanan Internet
      final finder = find.widgetWithText(InkWell, 'Layanan Internet');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(find.text('Layanan Internet OPD'), findsOneWidget);
    });
  });
}
