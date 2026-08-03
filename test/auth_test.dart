import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/features/auth/providers/auth_provider.dart';
import 'package:gelatik/features/auth/presentation/screens/splash_screen.dart';
import 'package:gelatik/features/auth/presentation/screens/login_screen.dart';
import 'package:gelatik/features/auth/presentation/screens/register_screen.dart';

void main() {
  group('AuthNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Login scenario with active user (status="1") should succeed',
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
    });

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
      expect(state.pendingActivationMessage,
          'Akun Anda belum aktif atau telah dinonaktifkan.');
    });

    test('3. Login scenario with non-existent email/NIP should return error',
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
    });

    test('4. Register flow (FR-36) should return true without auto-login',
        () async {
      final notifier = container.read(authProvider.notifier);

      final success = await notifier.register(
        name: 'Pegawai Baru, S.T.',
        nip: '199501012022031001',
        email: 'pegawai.baru@gmail.com',
        noHp: '081234567890',
        namaOpd: DummyData.listOpd[0],
        password: 'password123',
      );

      final state = container.read(authProvider);

      expect(success, isTrue);
      expect(state.isLoggedIn, isFalse); // FR-36: JANGAN auto login
    });
  });

  group('Auth Screens Widget Tests', () {
    testWidgets('SplashScreen navigates to LoginScreen when not logged in',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify SplashScreen UI elements
      expect(find.text('MEMUAT SISTEM...'), findsOneWidget);
      expect(find.text('Gerbang Layanan TIK'), findsOneWidget);

      // Advance 2 seconds timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));

      // Should land on LoginScreen
      expect(find.text('Selamat Datang'), findsOneWidget);
    });

    testWidgets(
        'LoginScreen displays FR-35 pending activation error when logging in as pending user',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Fill in pending user details
      await tester.enterText(
        find.byType(TextField).at(0),
        DummyData.pendingUser.email,
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'password123',
      );

      // Tap Masuk button
      await tester.tap(find.text('Masuk'));
      await tester.pump(); // Start loading
      await tester.pump(const Duration(milliseconds: 1200)); // Finish delay
      await tester.pumpAndSettle();

      // Should show FR-35 banner/dialog with exact message
      expect(find.text('Akun Anda belum aktif atau telah dinonaktifkan.'),
          findsWidgets);
      expect(
          find.text('Home - akan dibangun di fase berikutnya'), findsNothing);
    });

    testWidgets(
        'RegisterScreen form submit shows FR-36 confirmation dialog and pops back to LoginScreen',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.text('Daftar Akun Baru'), findsWidgets);

      // Fill form fields
      // 0: Nama Lengkap
      await tester.enterText(
          find.byType(TextField).at(0), 'Dewi Sartika, S.Pd.');
      // 1: NIP (18 digits)
      await tester.enterText(
          find.byType(TextField).at(1), '199501012022031001');
      // 2: Email
      await tester.enterText(
          find.byType(TextField).at(2), 'dewi.sartika@gmail.com');
      // 3: No WA
      await tester.enterText(
          find.byType(TextField).at(3), '081298765432');

      // Select OPD from dropdown
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));

      await tester.pumpAndSettle();
      await tester.tap(find.text(DummyData.listOpd[0]).last);
      await tester.pumpAndSettle();

      // 4: Password
      await tester.enterText(find.byType(TextField).at(4), 'password123');
      // 5: Konfirmasi Password
      await tester.enterText(find.byType(TextField).at(5), 'password123');

      // Tap Checkbox Syarat & Ketentuan after ensuring visibility
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Tap Daftar Sekarang after ensuring visibility
      await tester.ensureVisible(find.text('Daftar Sekarang'));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // FR-36: Check exact dialog message
      expect(
        find.text(
            'Registrasi berhasil. Akun Anda akan diaktifkan oleh admin sebelum dapat digunakan.'),
        findsOneWidget,
      );

      // Tap Kembali ke Login
      await tester.tap(find.text('Kembali ke Login'));
      await tester.pumpAndSettle();

      // Should return to LoginScreen
      expect(find.text('Selamat Datang'), findsOneWidget);
    });
  });
}
