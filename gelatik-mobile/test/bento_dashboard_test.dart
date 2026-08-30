import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/widgets/bento_block.dart';
import 'package:gelatik/core/widgets/bento_dashboard_grid.dart';

void main() {
  for (final size in const [Size(280, 640), Size(320, 720), Size(412, 915)]) {
    testWidgets('Bento dashboard adapts without overflow at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: BentoDashboardGrid(
                items: const [
                  BentoDashboardItem(
                    span: 2,
                    child: BentoBlock(child: Text('Informasi utama')),
                  ),
                  BentoDashboardItem(
                    child: BentoBlock(child: Text('Peminjaman aktif')),
                  ),
                  BentoDashboardItem(
                    child: BentoBlock(child: Text('Konsultasi aktif')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BentoBlock), findsNWidgets(3));
    });
  }
}
