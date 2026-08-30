import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/models/user_model.dart';

/// Service untuk menangani FCM Topic Subscription (M-K / FR-37 / FR-38).
/// Saat ini menggunakan simulasilog debugPrint sebelum dipasang firebase_messaging sungguhan.
class FcmTopicService {
  final List<String> _activeSubscribedTopics = [];

  List<String> get activeSubscribedTopics =>
      List.unmodifiable(_activeSubscribedTopics);

  /// FR-37: Subscribe ke topik pengguna saat login berhasil
  Future<void> subscribeToUserTopics(UserModel user) async {
    _activeSubscribedTopics.clear();

    // 1. Topic Personal & General Pengumuman (Selalu)
    final userTopic = 'user_${user.id}';
    const generalTopic = 'pengumuman';

    _subscribe(userTopic);
    _subscribe(generalTopic);

    // 2. Topic Khusus Role
    final role = user.role.toLowerCase();
    if (role == 'admin') {
      _subscribe('admin');
    } else if (role == 'bkd') {
      _subscribe('bkd');
    }

    debugPrint(
      '[FCM] Active subscribed topics for user ${user.id} (${user.role}): $_activeSubscribedTopics',
    );
  }

  void _subscribe(String topic) {
    if (!_activeSubscribedTopics.contains(topic)) {
      _activeSubscribedTopics.add(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    }
  }

  /// FR-38: Unsubscribe dari semua topik saat logout (sebelum logout selesai)
  Future<void> unsubscribeFromAllTopics() async {
    for (final topic in _activeSubscribedTopics) {
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    }
    _activeSubscribedTopics.clear();
    debugPrint('[FCM] Successfully unsubscribed from all topics.');
  }
}

/// Provider Riverpod untuk FcmTopicService
final fcmTopicServiceProvider = Provider<FcmTopicService>((ref) {
  return FcmTopicService();
});
