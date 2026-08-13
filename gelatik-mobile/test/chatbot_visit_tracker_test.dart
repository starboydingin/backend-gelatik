import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/features/chatbot/services/chatbot_visit_tracker.dart';

void main() {
  test('starter tampil lagi hanya setelah chatbot ditinggalkan lima menit', () {
    final tracker = ChatbotVisitTracker();
    final leftAt = DateTime(2026, 8, 13, 10);

    expect(tracker.shouldShowStarter('user:1', leftAt), isTrue);

    tracker.markLeft('user:1', leftAt);
    expect(
      tracker.shouldShowStarter(
        'user:1',
        leftAt.add(const Duration(minutes: 4, seconds: 59)),
      ),
      isFalse,
    );
    expect(
      tracker.shouldShowStarter(
        'user:1',
        leftAt.add(const Duration(minutes: 5)),
      ),
      isTrue,
    );
    expect(tracker.shouldShowStarter('user:2', leftAt), isTrue);
  });
}
