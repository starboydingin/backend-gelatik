import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gelatik/main.dart';

void main() {
  testWidgets('App loads splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GelatikApp(),
      ),
    );

    expect(find.textContaining('MEMUAT SISTEM...'), findsOneWidget);


    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
  });


}
