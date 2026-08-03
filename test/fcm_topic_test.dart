import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/core/services/fcm_topic_service.dart';
import 'package:gelatik/features/auth/models/user_model.dart';
import 'package:gelatik/features/auth/providers/auth_provider.dart';

/// Test Spy untuk memverifikasi pemanggilan method FcmTopicService
class FakeFcmTopicService extends FcmTopicService {
  int subscribeCallCount = 0;
  int unsubscribeCallCount = 0;
  UserModel? lastSubscribedUser;

  @override
  Future<void> subscribeToUserTopics(UserModel user) async {
    subscribeCallCount++;
    lastSubscribedUser = user;
    await super.subscribeToUserTopics(user);
  }

  @override
  Future<void> unsubscribeFromAllTopics() async {
    unsubscribeCallCount++;
    await super.unsubscribeFromAllTopics();
  }
}

void main() {
  group('FCM Topic Subscribe / Unsubscribe Timing Tests (M-K, FR-37, FR-38)', () {
    late FakeFcmTopicService fakeFcmService;
    late ProviderContainer container;

    setUp(() {
      fakeFcmService = FakeFcmTopicService();
      container = ProviderContainer(
        overrides: [
          fcmTopicServiceProvider.overrideWithValue(fakeFcmService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('1. FcmTopicService topic calculation logic for active user', () async {
      const user = UserModel(
        id: 101,
        name: 'Admin Test',
        email: 'admin@lampungprov.go.id',
        username: 'admin101',
        noHp: '081234567890',
        namaOpd: 'Diskominfotik',
        role: 'admin',
        status: '1',
      );

      await fakeFcmService.subscribeToUserTopics(user);

      expect(fakeFcmService.activeSubscribedTopics, contains('user_101'));
      expect(fakeFcmService.activeSubscribedTopics, contains('pengumuman'));
      expect(fakeFcmService.activeSubscribedTopics, contains('admin'));
      expect(fakeFcmService.activeSubscribedTopics.length, 3);
    });

    test('2. FcmTopicService topic calculation logic for bkd user', () async {
      const user = UserModel(
        id: 102,
        name: 'BKD Test',
        email: 'bkd@lampungprov.go.id',
        username: 'bkd102',
        noHp: '081234567891',
        namaOpd: 'BKD Lampung',
        role: 'bkd',
        status: '1',
      );

      await fakeFcmService.subscribeToUserTopics(user);

      expect(fakeFcmService.activeSubscribedTopics, contains('user_102'));
      expect(fakeFcmService.activeSubscribedTopics, contains('pengumuman'));
      expect(fakeFcmService.activeSubscribedTopics, contains('bkd'));
      expect(fakeFcmService.activeSubscribedTopics.length, 3);
    });

    test('3. AuthNotifier.login() with ACTIVE user triggers subscribeToUserTopics (FR-37)', () async {
      final notifier = container.read(authProvider.notifier);

      expect(fakeFcmService.subscribeCallCount, 0);

      final result = await notifier.login(DummyData.activeUser.email, 'password123');

      expect(result, AuthResultStatus.authenticated);
      expect(fakeFcmService.subscribeCallCount, 1);
      expect(fakeFcmService.lastSubscribedUser?.email, DummyData.activeUser.email);
    });

    test('4. AuthNotifier.login() with PENDING user DOES NOT trigger subscribeToUserTopics', () async {
      final notifier = container.read(authProvider.notifier);

      expect(fakeFcmService.subscribeCallCount, 0);

      final result = await notifier.login(DummyData.pendingUser.email, 'password123');

      expect(result, AuthResultStatus.pendingActivation);
      expect(fakeFcmService.subscribeCallCount, 0);
    });

    test('5. AuthNotifier.logout() triggers unsubscribeFromAllTopics before completion (FR-38)', () async {
      final notifier = container.read(authProvider.notifier);

      // Login first
      await notifier.login(DummyData.activeUser.email, 'password123');
      expect(fakeFcmService.subscribeCallCount, 1);
      expect(fakeFcmService.unsubscribeCallCount, 0);

      // Perform logout
      await notifier.logout();

      expect(fakeFcmService.unsubscribeCallCount, 1);
      expect(fakeFcmService.activeSubscribedTopics, isEmpty);
      expect(container.read(authProvider).isLoggedIn, isFalse);
    });
  });
}
