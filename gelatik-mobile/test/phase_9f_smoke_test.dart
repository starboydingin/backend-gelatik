import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/auth/models/user_model.dart';
import 'package:gelatik/features/auth/providers/auth_provider.dart';
import 'package:gelatik/features/home/models/home_dashboard_model.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';
import 'package:gelatik/features/info_alat/models/master_item_model.dart';
import 'package:gelatik/features/info_alat/providers/info_alat_provider.dart';
import 'package:gelatik/features/info_alat/repositories/master_item_repository.dart';
import 'package:gelatik/features/kritik_saran/presentation/screens/kritik_saran_screen.dart';
import 'package:gelatik/features/profil/presentation/screens/profil_screen.dart';

class _InfoAlatRepositoryFake extends MasterItemRepository {
  _InfoAlatRepositoryFake()
    : super(apiClient: ApiClient(secureStorageService: SecureStorageService()));

  @override
  Future<List<MasterItemModel>> getItems() async => const [
    MasterItemModel(id: 1, nama: 'Alat Smoke', stok: 1),
  ];
}

HomeDashboardModel _dashboard() => const HomeDashboardModel(
  userName: 'Smoke User',
  userRole: 'user',
  availableItemCount: 1,
  totalBorrowingCount: 0,
  totalConsultationCount: 0,
);

Widget _homeHarness() {
  return ProviderScope(
    overrides: [
      homeProvider.overrideWith((ref) => HomeNotifier.preview(_dashboard())),
      infoAlatProvider.overrideWith(
        (ref) => InfoAlatNotifier(repository: _InfoAlatRepositoryFake()),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('Home reaches feedback and returns with back navigation', (
    tester,
  ) async {
    await tester.pumpWidget(_homeHarness());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('home-scroll')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    final feedbackCard = find.widgetWithText(InkWell, 'Kritik & Saran');
    await Scrollable.ensureVisible(
      tester.element(feedbackCard),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(feedbackCard);
    await tester.pumpAndSettle();
    expect(find.byType(KritikSaranScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Beranda'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home reaches equipment information and its back control returns home',
    (tester) async {
      await tester.pumpWidget(_homeHarness());
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('home-scroll')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      final infoAlatCard = find.widgetWithText(InkWell, 'Layanan Lain');
      await Scrollable.ensureVisible(
        tester.element(infoAlatCard),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(infoAlatCard);
      await tester.pumpAndSettle();
      expect(find.text('Pinjam Aset TIK'), findsOneWidget);
      expect(find.text('Alat Smoke'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Beranda'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home reaches profile and returns with back navigation', (
    tester,
  ) async {
    await tester.pumpWidget(_homeHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilScreen), findsOneWidget);

    await tester.tap(find.text('Beranda').last);
    await tester.pumpAndSettle();
    expect(find.text('Beranda'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Profile renders safe nullable values and logout clears session',
    (tester) async {
      final notifier = AuthNotifier();
      notifier.state = const AuthState(
        isLoggedIn: true,
        currentUser: UserModel(
          id: 9,
          name: 'Legacy Smoke',
          email: '',
          username: '',
          noHp: '',
          namaOpd: '',
          role: 'admin',
          status: '1',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((ref) => notifier)],
          child: const MaterialApp(home: ProfilScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Legacy Smoke'), findsOneWidget);
      expect(
        find.text('Dinas Komunikasi, Informatika dan Statistik'),
        findsNothing,
      );
      expect(find.text('email@lampungprov.go.id'), findsNothing);

      await tester.tap(find.widgetWithText(InkWell, 'Informasi Akun'));
      await tester.pumpAndSettle();
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('-'), findsWidgets);
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      final logoutCard = find.widgetWithText(InkWell, 'Keluar (Logout)');
      await Scrollable.ensureVisible(
        tester.element(logoutCard),
        alignment: 0.5,
      );
      await tester.tap(logoutCard);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, Keluar'));
      await tester.pumpAndSettle();

      expect(notifier.state.isLoggedIn, isFalse);
      expect(notifier.state.currentUser, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
