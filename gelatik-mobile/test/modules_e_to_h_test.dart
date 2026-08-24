import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/features/email/providers/email_provider.dart';
import 'package:gelatik/features/email/models/usulan_email_model.dart';
import 'package:gelatik/features/email/repositories/email_repository.dart';
import 'package:gelatik/features/email/presentation/screens/daftar_pegawai_screen.dart';
import 'package:gelatik/features/internet/presentation/screens/layanan_internet_screen.dart';
import 'package:gelatik/features/internet/repositories/internet_repository.dart';
import 'package:gelatik/features/internet/utils/faq_html_formatter.dart';
import 'package:gelatik/features/info_alat/models/master_item_model.dart';
import 'package:gelatik/features/info_alat/providers/info_alat_provider.dart';
import 'package:gelatik/features/info_alat/presentation/screens/info_alat_screen.dart';
import 'package:gelatik/features/info_alat/repositories/master_item_repository.dart';
import 'package:gelatik/features/kritik_saran/presentation/screens/kritik_saran_screen.dart';
import 'package:gelatik/features/kritik_saran/repositories/kritik_saran_repository.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';
import 'package:gelatik/features/home/models/home_dashboard_model.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';

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

class _EmailRepositoryFake extends EmailRepository {
  _EmailRepositoryFake()
    : super(apiClient: ApiClient(secureStorageService: SecureStorageService()));

  @override
  Future<List<Map<String, dynamic>>> getPegawai({String? search}) async => [
    {
      'nama': 'Dra. Endang Rahmawati, M.Si.',
      'nip_baru': '197901012005012001',
      'jabatan': 'Kepala Bidang',
      'unit_kerja': 'Diskominfotik',
      'opd': 'Diskominfotik',
      'email_usulan': 'endang@lampungprov.go.id',
      'email_pribadi': '',
    },
    {
      'nama': 'Ir. Bambang Triyono, M.T.',
      'nip_baru': '197801012004011001',
      'jabatan': 'Pranata Komputer',
      'unit_kerja': 'Diskominfotik',
      'opd': 'Diskominfotik',
      'email_usulan': 'bambang@lampungprov.go.id',
      'email_pribadi': '',
    },
  ];

  @override
  Future<UsulanEmailModel> submit({
    required String nip,
    required String emailPribadi,
  }) async => UsulanEmailModel(
    id: 901,
    userId: 1,
    idPegBkd: 1,
    emailPribadi: emailPribadi,
    status: 'diajukan',
    pegawai: {'nama': 'Dra. Endang Rahmawati, M.Si.', 'nip_baru': nip},
  );
}

class _KritikSaranRepositoryFake extends KritikSaranRepository {
  _KritikSaranRepositoryFake()
    : super(apiClient: ApiClient(secureStorageService: SecureStorageService()));

  @override
  Future<void> submit({required String kritik, required String saran}) async {}
}

class _InternetRepositoryFake extends InternetRepository {
  _InternetRepositoryFake()
    : super(apiClient: ApiClient(secureStorageService: SecureStorageService()));

  @override
  Future<Map<String, dynamic>> getInternetOverview() async => {
    'bandwidth': {
      'opd': 'Informasi bandwidth belum tersedia',
      'provider': 'Tidak tersedia dari API',
      'status': 'Belum tersedia',
      'available': false,
      'download_mbps': '-',
      'upload_mbps': '-',
    },
    'routers': await getRouters(),
  };

  @override
  Future<List<Map<String, dynamic>>> getRouters() async => [
    {
      'nama_router': 'Router OPD',
      'ip_address': '10.0.0.1',
      'tipe': 'MikroTik',
      'status': 'Aktif',
      'lokasi': 'Kantor',
      'beban_traffic': '-',
    },
  ];
}

void main() {
  group('Modules M-E s.d. M-H Unit & Widget Tests', () {
    test(
      '1. Submit Usulan Email Resmi (tambahUsulanEmail) creates item with LOWERCASE status "diajukan"',
      () async {
        final container = ProviderContainer(
          overrides: [
            emailRepositoryProvider.overrideWithValue(_EmailRepositoryFake()),
          ],
        );
        final notifier = container.read(emailProvider.notifier);

        final pegawaiData = DummyData.pegawaiBelumPunyaEmail[0];

        final success = await notifier.tambahUsulanEmail(
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

    testWidgets(
      '3. LayananInternetScreen renders a compact unavailable bandwidth state',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              internetRepositoryProvider.overrideWithValue(
                _InternetRepositoryFake(),
              ),
            ],
            child: MaterialApp(home: LayananInternetScreen()),
          ),
        );

        expect(find.text('Layanan Internet OPD'), findsOneWidget);
        expect(find.text('DOWNLOAD'), findsNothing);
        expect(find.text('UPLOAD'), findsNothing);
        expect(find.text('Informasi bandwidth belum tersedia'), findsOneWidget);
        expect(
          find.text('Informasi bandwidth untuk OPD Anda belum tersedia.'),
          findsOneWidget,
        );
        expect(find.text('Buat Pengaduan Internet'), findsOneWidget);
      },
    );

    test('FAQ HTML is converted into readable text', () {
      final text = faqHtmlToPlainText(
        '<p>Periksa koneksi.</p><ul><li>Restart perangkat</li></ul>',
      );

      expect(text, 'Periksa koneksi.\n\n• Restart perangkat');
      expect(text, isNot(contains('<li>')));
    });

    testWidgets(
      '4. DaftarPegawaiScreen renders list of employees without email',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              emailRepositoryProvider.overrideWithValue(_EmailRepositoryFake()),
            ],
            child: const MaterialApp(home: DaftarPegawaiScreen()),
          ),
        );
        await tester.pumpAndSettle();

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

      expect(find.text('Pinjam Aset TIK'), findsOneWidget);
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

        expect(find.text('Pinjam Aset TIK'), findsOneWidget);
        expect(find.text('Alat Custom dari Provider Override'), findsOneWidget);
        expect(find.text('Laptop Lenovo ThinkPad L14 Gen 3'), findsNothing);
      },
    );

    testWidgets(
      '6. KritikSaranScreen form submit shows confirmation dialog and closes',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              kritikSaranRepositoryProvider.overrideWithValue(
                _KritikSaranRepositoryFake(),
              ),
            ],
            child: const MaterialApp(home: KritikSaranScreen()),
          ),
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
        await tester.pumpAndSettle();

        // Verify Success Dialog is rendered
        expect(find.text('Terima Kasih!'), findsOneWidget);
        expect(find.text('Tutup & Kembali'), findsOneWidget);
      },
    );

    testWidgets('7. HomeScreen navigates to all 4 new modules successfully', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith(
              (ref) => HomeNotifier.preview(
                const HomeDashboardModel(
                  userName: 'Test User',
                  userRole: 'user',
                  availableItemCount: 0,
                  totalBorrowingCount: 0,
                  totalConsultationCount: 0,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.drag(
        find.byKey(const Key('home-scroll')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsAtLeastNWidgets(1));
      expect(find.text('Laporan Internet'), findsOneWidget);
      expect(find.text('Email Dinas'), findsOneWidget);
      expect(find.text('Layanan Lain'), findsOneWidget);
      expect(find.text('Kritik & Saran'), findsOneWidget);

      // Tap Laporan Internet
      final finder = find.widgetWithText(InkWell, 'Laporan Internet');
      await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(find.text('Layanan Internet OPD'), findsOneWidget);
    });
  });
}
