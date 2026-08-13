import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatbotVisitTracker {
  static const promptResetAfter = Duration(minutes: 5);

  final Map<String, DateTime> _lastLeftAt = {};

  bool shouldShowStarter(String sessionKey, DateTime now) {
    final lastLeftAt = _lastLeftAt[sessionKey];
    return lastLeftAt == null || now.difference(lastLeftAt) >= promptResetAfter;
  }

  void markLeft(String sessionKey, DateTime now) {
    _lastLeftAt[sessionKey] = now;
  }
}

final chatbotVisitTrackerProvider = Provider<ChatbotVisitTracker>((ref) {
  return ChatbotVisitTracker();
});
