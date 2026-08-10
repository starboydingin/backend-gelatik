import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/features/home/models/home_dashboard_model.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';
import 'package:gelatik/features/info_alat/models/master_item_model.dart';
import 'package:gelatik/features/info_alat/presentation/screens/pilih_aset_screen.dart';
import 'package:gelatik/features/internet/presentation/screens/self_assessment_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Widget _homeHarness() => ProviderScope(
  overrides: [
    homeProvider.overrideWith(
      (ref) => HomeNotifier.preview(
        const HomeDashboardModel(
          userName:
              'Nama Pengguna Dengan Nama OPD Sangat Panjang Untuk Uji Layar Sempit',
          userRole: 'user',
          availableItemCount: 1,
          totalBorrowingCount: 0,
          totalConsultationCount: 0,
        ),
      ),
    ),
  ],
  child: const MaterialApp(home: HomeScreen()),
);

void main() {
  test('Indonesian locale date formatting is initialized', () async {
    await initializeDateFormatting('id_ID', null);

    expect(
      () => DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime(2026, 8, 10)),
      returnsNormally,
    );
  });

  testWidgets('Home FAQ opens the existing FAQ flow and returns', (
    tester,
  ) async {
    await tester.pumpWidget(_homeHarness());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('home-scroll')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    final faqCard = find.ancestor(
      of: find.text('Bantuan & FAQ'),
      matching: find.byType(InkWell),
    );
    await Scrollable.ensureVisible(tester.element(faqCard), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(faqCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.byType(SelfAssessmentScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Asset selection adapts long content at narrow widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PilihAsetWidget(
              masterItems: const [
                MasterItemModel(
                  id: 1,
                  nama: 'Logitech Group (Untuk Zoom Meeting) - 03',
                  deskripsi:
                      'Perangkat konferensi dengan keterangan penggunaan yang panjang.',
                  kondisi: 'Baik',
                  stok: 12,
                ),
              ],
              selectedQuantities: const {},
              onQuantityChanged: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Logitech Group (Untuk Zoom Meeting) - 03'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home remains usable across representative widths', (
    tester,
  ) async {
    const viewports = [
      Size(320, 700),
      Size(430, 900),
      Size(700, 900),
      Size(1100, 800),
    ];
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final viewport in viewports) {
      await tester.binding.setSurfaceSize(viewport);
      await tester.pumpWidget(_homeHarness());
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    }
  });
}
