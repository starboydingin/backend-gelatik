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
  String? _chatbotSessionId;
  final Map<int, Set<int>> _mobileNotificationReads = {};

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
    _chatbotSessionId = null;
  }

  @override
  Future<void> saveChatbotSessionId(String sessionId) async {
    _chatbotSessionId = sessionId;
  }

  @override
  Future<String?> getChatbotSessionId() async => _chatbotSessionId;

  @override
  Future<void> deleteChatbotSessionId() async {
    _chatbotSessionId = null;
  }

  @override
  Future<Set<int>?> getMobileNotificationReadIds(int userId) async =>
      _mobileNotificationReads[userId];

  @override
  Future<void> saveMobileNotificationReadIds(
    int userId,
    Iterable<int> ids,
  ) async => _mobileNotificationReads[userId] = ids.toSet();
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
  int registerRequestCount = 0;
  Map<String, String>? lastRegisterPayload;
  Object? registerFailure;
  Map<String, dynamic>? registerResponse;

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
        message:
            'Akun Anda sedang tidak aktif atau telah dinonaktifkan. Hubungi administrator jika Anda memerlukan bantuan.',
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
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String nip,
    required String noHp,
    required String namaOpd,
    required String password,
    required String passwordConfirmation,
  }) async {
    registerRequestCount++;
    if (registerFailure != null) throw registerFailure!;
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
    return registerResponse ??
        {
          'access_token': 'register_access_token_456',
          'token_type': 'Bearer',
          'user': DummyData.activeUser.toJson(),
        };
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

class DeferredRegisterAuthRepository extends FakeAuthRepository {
  final Completer<Map<String, dynamic>> completer =
      Completer<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String nip,
    required String noHp,
    required String namaOpd,
    required String password,
    required String passwordConfirmation,
  }) {
    registerRequestCount++;
    return completer.future;
  }
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
          'Akun Anda sedang tidak aktif atau telah dinonaktifkan. Hubungi administrator jika Anda memerlukan bantuan.',
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
      '4. Register flow stores token and authenticates immediately',
      () async {
        final notifier = container.read(authProvider.notifier);

        final result = await notifier.register(
          name: 'Pegawai Baru, S.T.',
          nip: '199501012022031001',
          email: 'pegawai.baru@gmail.com',
          noHp: '081234567890',
          namaOpd: fakeAuthRepo.opds.first,
          password: 'password123',
          passwordConfirmation: 'password123',
        );

        final state = container.read(authProvider);

        expect(result, AuthResultStatus.authenticated);
        expect(state.isLoggedIn, isTrue);
        expect(state.currentUser?.status, '1');
        expect(await fakeStorage.getToken(), 'register_access_token_456');
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

        final result = await notifier.register(
          name: 'Pegawai Baru, S.T.',
          nip: '199501012022031001',
          email: 'pegawai.baru@gmail.com',
          noHp: '081234567890',
          namaOpd: fakeAuthRepo.opds.first,
          password: 'password123',
          passwordConfirmation: 'differentPassword',
        );

        final state = container.read(authProvider);

        expect(result, AuthResultStatus.error);
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

    test(
      '10. Register token failure is handled without a false session',
      () async {
        fakeAuthRepo.registerResponse = {
          'token_type': 'Bearer',
          'user': DummyData.activeUser.toJson(),
        };

        final result = await container
            .read(authProvider.notifier)
            .register(
              name: 'Pegawai Baru',
              nip: '199501012022031001',
              email: 'pegawai@example.test',
              noHp: '081234567890',
              namaOpd: fakeAuthRepo.opds.first,
              password: 'password123',
              passwordConfirmation: 'password123',
            );

        final state = container.read(authProvider);
        expect(result, AuthResultStatus.error);
        expect(state.isLoggedIn, isFalse);
        expect(await fakeStorage.getToken(), isNull);
        expect(state.errorMessage, contains('Token autentikasi'));
      },
    );

    test('11. Concurrent register submit is ignored while loading', () async {
      final deferredRepo = DeferredRegisterAuthRepository();
      final deferredContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(deferredRepo),
          secureStorageServiceProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(deferredContainer.dispose);
      final notifier = deferredContainer.read(authProvider.notifier);

      final first = notifier.register(
        name: 'Pegawai Baru',
        nip: '199501012022031001',
        email: 'pegawai@example.test',
        noHp: '081234567890',
        namaOpd: deferredRepo.opds.first,
        password: 'password123',
        passwordConfirmation: 'password123',
      );
      final second = await notifier.register(
        name: 'Pegawai Baru',
        nip: '199501012022031001',
        email: 'pegawai@example.test',
        noHp: '081234567890',
        namaOpd: deferredRepo.opds.first,
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(second, AuthResultStatus.error);
      expect(deferredRepo.registerRequestCount, 1);
      deferredRepo.completer.complete({
        'access_token': 'deferred_token',
        'user': DummyData.activeUser.toJson(),
      });
      expect(await first, AuthResultStatus.authenticated);
    });

    test('12. Register validation errors remain mapped by field', () async {
      fakeAuthRepo.registerFailure = ApiException(
        message: 'Data tidak valid.',
        statusCode: 422,
        errors: {
          'email': ['Email sudah digunakan.'],
          'nip': ['NIP sudah digunakan.'],
        },
      );

      final result = await container
          .read(authProvider.notifier)
          .register(
            name: 'Pegawai Baru',
            nip: '199501012022031001',
            email: 'pegawai@example.test',
            noHp: '081234567890',
            namaOpd: fakeAuthRepo.opds.first,
            password: 'password123',
            passwordConfirmation: 'password123',
          );

      expect(result, AuthResultStatus.error);
      expect(
        container.read(authProvider).validationErrors,
        containsPair('email', 'Email sudah digunakan.'),
      );
    });

    test('13. AuthRepository parses the register auth envelope', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'success': true,
                'data': {
                  'access_token': 'server_register_token',
                  'token_type': 'Bearer',
                  'user': DummyData.activeUser.toJson(),
                },
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

      final data = await repository.register(
        name: 'Pegawai Baru',
        email: 'pegawai@example.test',
        nip: '199501012022031001',
        noHp: '081234567890',
        namaOpd: fakeAuthRepo.opds.first,
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(data['access_token'], 'server_register_token');
      expect(data['user']['status'], '1');
    });
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
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
      expect(find.text('GERBANG LAYANAN TIK'), findsOneWidget);
      expect(find.byKey(const Key('splash_gelatik_logo')), findsOneWidget);
      expect(find.text('GELATIK'), findsNothing);
      final splashLogo = tester.widget<Image>(
        find.byKey(const Key('splash_gelatik_logo')),
      );
      expect(
        (splashLogo.image as AssetImage).assetName,
        'assets/images/logo-tanpabackground.png',
      );
      expect(
        tester.getCenter(find.byKey(const Key('splash_gelatik_logo'))).dx,
        closeTo(720, 1),
      );

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
          find.text(
            'Akun Anda sedang tidak aktif atau telah dinonaktifkan. Hubungi administrator jika Anda memerlukan bantuan.',
          ),
          findsWidgets,
        );
        expect(find.text('Akun Tidak Aktif'), findsWidgets);
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
      'RegisterScreen auto-login stores a session and navigates to Home',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              secureStorageServiceProvider.overrideWithValue(fakeStorage),
            ],
            child: MaterialApp(
              home: RegisterScreen(
                homeBuilder: (_) =>
                    const Scaffold(key: Key('home_destination')),
              ),
            ),
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

        final opdPicker = find.byKey(const Key('opd_dropdown'));
        await tester.ensureVisible(opdPicker);
        await tester.pumpAndSettle();
        await tester.tap(opdPicker);

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

        expect(find.byKey(const Key('home_destination')), findsOneWidget);
        expect(find.textContaining('diaktifkan oleh admin'), findsNothing);
        expect(await fakeStorage.getToken(), 'register_access_token_456');
        expect(
          fakeAuthRepo.lastRegisterPayload?['nama_opd'],
          fakeAuthRepo.opds.first,
        );
        expect(fakeAuthRepo.lastRegisterPayload?['nip'], '199501012022031001');
        expect(
          fakeAuthRepo.lastRegisterPayload?.containsKey('username'),
          isFalse,
        );
      },
    );

    testWidgets('Auth screens use the expected branding assets', (
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

      expect(find.byKey(const Key('login_gelatik_logo')), findsOneWidget);
      expect(find.byKey(const Key('login_siger_logo')), findsOneWidget);
      expect(find.text('GELATIK'), findsNothing);
      final loginLogo = tester.widget<Image>(
        find.byKey(const Key('login_gelatik_logo')),
      );
      final loginSiger = tester.widget<Image>(
        find.byKey(const Key('login_siger_logo')),
      );
      expect(
        (loginLogo.image as AssetImage).assetName,
        'assets/images/logo-tanpabackground.png',
      );
      expect(
        (loginSiger.image as AssetImage).assetName,
        'assets/images/icon lampung.png',
      );
      final brandText = tester.widget<Text>(find.text('GERBANG LAYANAN TIK'));
      expect(brandText.style?.fontFamily, contains('Montserrat'));

      await tester.tap(find.text('Daftar Akun Baru'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('register_gelatik_logo')), findsOneWidget);
      expect(find.byKey(const Key('register_siger_logo')), findsOneWidget);
      final registerLogo = tester.widget<Image>(
        find.byKey(const Key('register_gelatik_logo')),
      );
      expect(
        (registerLogo.image as AssetImage).assetName,
        'assets/images/logo-tanpabackground.png',
      );
    });

    for (final size in const [Size(360, 640), Size(390, 844), Size(412, 915)]) {
      testWidgets(
        'Login renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWithValue(fakeAuthRepo),
                secureStorageServiceProvider.overrideWithValue(fakeStorage),
              ],
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: child!,
                ),
                home: const LoginScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Email atau NIP'), findsOneWidget);
          expect(find.text('Kata Sandi'), findsOneWidget);
        },
      );
    }

    testWidgets('Login remains scrollable with a simulated keyboard inset', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            secureStorageServiceProvider.overrideWithValue(fakeStorage),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(viewInsets: const EdgeInsets.only(bottom: 280)),
              child: child!,
            ),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Register remains scrollable on a small screen with keyboard and scaled text',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              secureStorageServiceProvider.overrideWithValue(fakeStorage),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  viewInsets: const EdgeInsets.only(bottom: 240),
                  textScaler: const TextScaler.linear(1.2),
                ),
                child: child!,
              ),
              home: const RegisterScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byKey(const Key('register_gelatik_logo')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
