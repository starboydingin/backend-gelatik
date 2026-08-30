import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/features/home/models/home_dashboard_model.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';
import 'package:gelatik/features/home/repositories/announcement_repository.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';
import 'package:gelatik/features/services/presentation/screens/services_screen.dart';
import 'package:gelatik/features/shell/presentation/screens/main_shell.dart';
import 'package:gelatik/core/widgets/app_bottom_nav.dart';
import 'package:gelatik/features/peminjaman/presentation/screens/peminjaman_list_screen.dart';

void main() {
  testWidgets(
    'main shell lazily creates tabs and preserves visited tab state',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAnnouncementsProvider.overrideWith((ref) async => const []),
            homeProvider.overrideWith(
              (ref) => HomeNotifier.preview(
                const HomeDashboardModel(
                  userName: 'Pengguna Shell',
                  userRole: 'user',
                  namaOpd: 'Diskominfotik Lampung',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ServicesScreen), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text('Layanan'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ServicesScreen), findsOneWidget);
      expect(find.text('Apa yang Anda butuhkan?'), findsOneWidget);

      await tester.tap(find.text('Peminjaman Aset'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PeminjamanListScreen), findsOneWidget);
      expect(find.text('Daftar Peminjaman Aset'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ServicesScreen), findsOneWidget);
      expect(find.text('Apa yang Anda butuhkan?'), findsOneWidget);
      expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
    },
  );
}
