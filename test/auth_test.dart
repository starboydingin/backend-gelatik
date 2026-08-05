import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/network/api_exception.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/auth/repositories/auth_repository.dart';
import 'package:gelatik/features/auth/providers/auth_provider.dart';
import 'package:gelatik/features/auth/presentation/screens/splash_screen.dart';
import 'package:gelatik/features/auth/presentation/screens/login_screen.dart';
import 'package:gelatik/features/auth/presentation/screens/register_screen.dart';

class FakeSecureStorageService implements SecureStorageService {
  String? _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<void> deleteToken() async {
    _token = null;
  }
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({
    this.opds = const ['Dinas Komunikasi dan Informatika'],
    this.opdFailure,
  }) : super(
         apiClient: ApiClient(secureStorageService: FakeSecureStorageService()),
       );

  final List<String> opds;
  final Object? opdFailure;
  int opdRequestCount = 0;
  Map<String, String>? lastRegisterPayload;

  @override
  Future<List<String>> getOpds() async {
    opdRequestCount++;
    if (opdFailure != null) {
      throw opdFailure!;
    }
    return opds;
  }

  @override
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final trimmed = identifier.trim().toLowerCase();

    if (trimmed == DummyData.pendingUser.email.toLowerCase()) {
      throw ApiException(
        message: 'Akun Anda belum aktif atau telah dinonaktifkan.',
        statusCode: 403,
      );
    }

    if (trimmed == 'unknown.user@lampungprov.go.id') {
      throw ApiException(
        message: 'Email/NIP atau password salah.',
        statusCode: 401,
      );
    }

    return {
      'access_token': 'fake_access_token_123',
      'user': DummyData.activeUser.toJson(),
    };
  }

  @override
  Future<bool> register({
    required String name,
    required String email,
    required String nip,
    required String noHp,
    required String namaOpd,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (password != passwordConfirmation) {
      throw ApiException(message: 'Konfirmasi password tidak cocok.');
    }
    lastRegisterPayload = {
      'name': name,
      'email': email,
      'nip': nip,
      'no_hp': noHp,
      'nama_opd': namaOpd,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    return true;
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    return DummyData.activeUser.toJson();
  }

  @override
  Future<void> logout() async {}
}

class DeferredOpdAuthRepository extends FakeAuthRepository {
  final Completer<List<String>> completer = Completer<List<String>>();

  @override
  Future<List<String>> getOpds() => completer.future;
}

void main() {
  group('AuthNotifier Unit Tests', () {
    late ProviderContainer container;
    late FakeAuthRepository fakeAuthRepo;
    late FakeSecureStorageService fakeStorage;

    setUp(() {
      fakeAuthRepo = FakeAuthRepository();
      fakeStorage = FakeSecureStorageService();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          secureStorageServiceProvider.overrideWithValue(fakeStorage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      '1. Login scenario with active user (status="1") should succeed',
      () async {
        final notifier = container.read(authProvider.notifier);

        final result = await notifier.login(
          DummyData.activeUser.email,
          'password123',
        );

        final state = container.read(authProvider);

        expect(result, AuthResultStatus.authenticated);
        expect(state.isLoggedIn, isTrue);
        expect(state.currentUser?.email, DummyData.activeUser.email);
        expect(state.currentUser?.status, '1');
        expect(await fakeStorage.getToken(), 'fake_access_token_123');
      },
    );

    test(
      '2. Login scenario with pending user (status="0") should return pendingActivation (FR-35)',
      () async {
        final notifier = container.read(authProvider.notifier);

        final result = await notifier.login(
          DummyData.pendingUser.email,
          'password123',
        );

        final state = container.read(authProvider);

        expect(result, AuthResultStatus.pendingActivation);
        expect(state.isLoggedIn, isFalse);
        expect(
          state.pendingActivationMessage,
          'Akun Anda belum aktif atau telah dinonaktifkan.',
        );
      },
    );

    test(
      '3. Login scenario with non-existent email/NIP should return error',
      () async {
        final notifier = container.read(authProvider.notifier);

        final result = await notifier.login(
          'unknown.user@lampungprov.go.id',
          'password123',
        );

        final state = container.read(authProvider);

        expect(result, AuthResultStatus.error);
        expect(state.isLoggedIn, isFalse);
        expect(state.errorMessage, 'Email/NIP atau password salah.');
      },
    );

    test(
      '4. Register flow (FR-36) should return true without auto-login',
      () async {
        final notifier = container.read(authProvider.notifier);

        final success = await notifier.register(
          name: 'Pegawai Baru, S.T.',
          nip: '199501012022031001',
          email: 'pegawai.baru@gmail.com',
          noHp: '081234567890',
          namaOpd: fakeAuthRepo.opds.first,
          password: 'password123',
          passwordConfirmation: 'password123',
        );

        final state = container.read(authProvider);

        expect(success, isTrue);
        expect(state.isLoggedIn, isFalse); // FR-36: JANGAN auto login
        expect(await fakeStorage.getToken(), isNull);
        expect(fakeAuthRepo.lastRegisterPayload?['nip'], '199501012022031001');
        expect(
          fakeAuthRepo.lastRegisterPayload?.containsKey('username'),
          isFalse,
        );
      },
    );

    test(
      '5. Register with mismatched password and passwordConfirmation should fail with error',
      () async {
        final notifier = container.read(authProvider.notifier);

        final success = await notifier.register(
          name: 'Pegawai Baru, S.T.',
          nip: '199501012022031001',
          email: 'pegawai.baru@gmail.com',
          noHp: '081234567890',
          namaOpd: fakeAuthRepo.opds.first,
          password: 'password123',
          passwordConfirmation: 'differentPassword',
        );

        final state = container.read(authProvider);

        expect(success, isFalse);
        expect(state.errorMessage, 'Konfirmasi password tidak cocok.');
      },
    );

    test(
      '6. OPD loading and success states are exposed by AuthNotifier',
      () async {
        final deferredRepo = DeferredOpdAuthRepository();
        final deferredContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(deferredRepo),
            secureStorageServiceProvider.overrideWithValue(fakeStorage),
          ],
        );
        addTearDown(deferredContainer.dispose);

        final future = deferredContainer.read(authProvider.notifier).loadOpds();
        expect(deferredContainer.read(authProvider).isOpdLoading, isTrue);

        deferredRepo.completer.complete(['Dinas A', 'Dinas B']);
        await future;

        final state = deferredContainer.read(authProvider);
        expect(state.isOpdLoading, isFalse);
        expect(state.opds, ['Dinas A', 'Dinas B']);
        expect(state.opdErrorMessage, isNull);
      },
    );

    test('7. OPD empty response remains a successful empty state', () async {
      final emptyRepo = FakeAuthRepository(opds: const []);
      final emptyContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(emptyRepo),
          secureStorageServiceProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(emptyContainer.dispose);

      await emptyContainer.read(authProvider.notifier).loadOpds();
      final state = emptyContainer.read(authProvider);

      expect(state.opds, isEmpty);
      expect(state.opdErrorMessage, isNull);
      expect(state.isOpdLoading, isFalse);
    });

    test('8. OPD repository failure is exposed and can be retried', () async {
      final failingRepo = FakeAuthRepository(
        opdFailure: ApiException(message: 'Daftar OPD gagal dimuat.'),
      );
      final failingContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(failingRepo),
          secureStorageServiceProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(failingContainer.dispose);

      await failingContainer.read(authProvider.notifier).loadOpds();
      await failingContainer.read(authProvider.notifier).loadOpds();

      final state = failingContainer.read(authProvider);
      expect(state.opds, isEmpty);
      expect(state.opdErrorMessage, 'Daftar OPD gagal dimuat.');
      expect(failingRepo.opdRequestCount, 2);
    });

    test(
      '9. AuthRepository maps the OPD response envelope defensively',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': [
                    {'nama_opd': 'Dinas A'},
                    {'nama': 'Dinas B'},
                    {'name': 'Dinas C'},
                    {'nama_opd': 'Dinas A'},
                    {'id': 99},
                  ],
                },
              ),
            ),
          ),
        );
        final repository = AuthRepository(
          apiClient: ApiClient(
            secureStorageService: fakeStorage,
            dioOverride: dio,
          ),
        );

        expect(await repository.getOpds(), ['Dinas A', 'Dinas B', 'Dinas C']);
      },
    );
  });

  group('Auth Screens Widget Tests', () {
    late FakeAuthRepository fakeAuthRepo;
    late FakeSecureStorageService fakeStorage;

    setUp(() {
      fakeAuthRepo = FakeAuthRepository();
      fakeStorage = FakeSecureStorageService();
    });

    testWidgets('SplashScreen navigates to LoginScreen when not logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            secureStorageServiceProvider.overrideWithValue(fakeStorage),
          ],
          child: const MaterialApp(home: SplashScreen()),
        ),
      );

      expect(find.text('MEMUAT SISTEM...'), findsOneWidget);
      expect(find.text('Gerbang Layanan TIK'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Selamat Datang'), findsOneWidget);
    });

    testWidgets(
      'LoginScreen displays FR-35 pending activation error when logging in as pending user',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              secureStorageServiceProvider.overrideWithValue(fakeStorage),
            ],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );

        await tester.enterText(
          find.byType(TextField).at(0),
          DummyData.pendingUser.email,
        );
        await tester.enterText(find.byType(TextField).at(1), 'password123');

        await tester.tap(find.text('Masuk'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();

        expect(
          find.text('Akun Anda belum aktif atau telah dinonaktifkan.'),
          findsWidgets,
        );
        expect(
          find.text('Home - akan dibangun di fase berikutnya'),
          findsNothing,
        );
      },
    );

    testWidgets('LoginScreen does not expose dummy credential helpers', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            secureStorageServiceProvider.overrideWithValue(fakeStorage),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.textContaining('Quick Testing'), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('User Aktif (status=1)'), findsNothing);
    });

    testWidgets(
      'RegisterScreen form submit shows FR-36 confirmation dialog and pops back to LoginScreen',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              secureStorageServiceProvider.overrideWithValue(fakeStorage),
            ],
            child: const MaterialApp(home: RegisterScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Daftar Akun Baru'), findsWidgets);

        await tester.enterText(
          find.byType(TextField).at(0),
          'Dewi Sartika, S.Pd.',
        );
        await tester.enterText(
          find.byType(TextField).at(1),
          '199501012022031001',
        );
        await tester.enterText(
          find.byType(TextField).at(2),
          'dewi.sartika@gmail.com',
        );
        await tester.enterText(find.byType(TextField).at(3), '081298765432');

        await tester.ensureVisible(
          find.byType(DropdownButtonFormField<String>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>));

        await tester.pumpAndSettle();
        await tester.tap(find.text(fakeAuthRepo.opds.first).last);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(4), 'password123');
        await tester.enterText(find.byType(TextField).at(5), 'password123');

        await tester.ensureVisible(find.byType(Checkbox));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Daftar Sekarang'));

        await tester.pumpAndSettle();
        await tester.tap(find.text('Daftar Sekarang'));
        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Registrasi berhasil. Akun Anda akan diaktifkan oleh admin sebelum dapat digunakan.',
          ),
          findsOneWidget,
        );
        expect(
          fakeAuthRepo.lastRegisterPayload?['nama_opd'],
          fakeAuthRepo.opds.first,
        );
        expect(fakeAuthRepo.lastRegisterPayload?['nip'], '199501012022031001');
        expect(
          fakeAuthRepo.lastRegisterPayload?.containsKey('username'),
          isFalse,
        );

        await tester.tap(find.text('Kembali ke Login'));
        await tester.pumpAndSettle();

        expect(find.text('Selamat Datang'), findsOneWidget);
      },
    );
  });
}
