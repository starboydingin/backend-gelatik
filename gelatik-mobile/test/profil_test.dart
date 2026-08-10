import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/features/auth/models/user_model.dart';
import 'package:gelatik/features/auth/providers/auth_provider.dart';
import 'package:gelatik/features/profil/presentation/screens/notifikasi_whatsapp_screen.dart';
import 'package:gelatik/features/profil/presentation/screens/profil_screen.dart';
import 'package:gelatik/features/profil/providers/wa_notification_provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ProfilScreen & NotifikasiWhatsAppScreen Widget Tests (M-J & F-WA)', () {
    test(
      'UserModel reads the account registration date returned by the API',
      () {
        final user = UserModel.fromJson({
          'id': 99,
          'name': 'Pengguna Uji',
          'email': 'uji@example.test',
          'username': 'penggunauji',
          'no_hp': '081234567890',
          'nama_opd': 'OPD Uji',
          'role': 'user',
          'status': '1',
          'created_at': '2026-01-15T09:30:00.000000Z',
        });

        expect(user.createdAt, DateTime.parse('2026-01-15T09:30:00.000000Z'));
      },
    );

    Widget buildProfilWidget({AuthState? initialState}) {
      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.state =
                initialState ??
                AuthState(isLoggedIn: true, currentUser: DummyData.activeUser);
            return notifier;
          }),
        ],
        child: const MaterialApp(home: ProfilScreen()),
      );
    }

    testWidgets(
      '1. ProfilScreen renders header avatar initials, name, email, and menu list',
      (tester) async {
        await tester.pumpWidget(buildProfilWidget());
        await tester.pumpAndSettle();

        // Verify Header details
        expect(find.text('Profil').first, findsOneWidget);
        expect(find.text(DummyData.activeUser.name), findsOneWidget);
        expect(find.text(DummyData.activeUser.email), findsOneWidget);

        // Verify Menu Items
        expect(find.text('Informasi Akun'), findsOneWidget);
        expect(find.text('Ganti Password'), findsOneWidget);
        expect(find.text('Notifikasi WhatsApp'), findsOneWidget);
        expect(find.textContaining('Terhubung'), findsOneWidget);
        expect(find.text('Bantuan & FAQ'), findsOneWidget);
        expect(find.text('Tentang Aplikasi'), findsOneWidget);
        expect(find.text('Keluar (Logout)'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Tapping Notifikasi WhatsApp navigates to NotifikasiWhatsAppScreen',
      (tester) async {
        await tester.pumpWidget(buildProfilWidget());
        await tester.pumpAndSettle();

        // Tap Notifikasi WhatsApp
        final waCard = find.widgetWithText(InkWell, 'Notifikasi WhatsApp');
        await Scrollable.ensureVisible(tester.element(waCard), alignment: 0.5);
        await tester.tap(waCard);
        await tester.pumpAndSettle();

        expect(find.byType(NotifikasiWhatsAppScreen), findsOneWidget);
        expect(find.text('Layanan Notifikasi WA'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Submitting invalid WhatsApp number is rejected by validation',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: NotifikasiWhatsAppScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Enter invalid WA number (not starting with 08 or 628)
        await tester.enterText(find.byType(TextField), '07123456789');
        await tester.pumpAndSettle();

        // Tap Simpan Pengaturan
        await tester.tap(find.text('Simpan Pengaturan'));
        await tester.pumpAndSettle();

        // Verify validation error
        expect(
          find.text('Nomor WhatsApp harus diawali 08 atau 628.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('4. Toggle cannot be activated without valid WhatsApp number', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: NotifikasiWhatsAppScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Turn switch OFF first so we can test toggling ON
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Clear input text to empty
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Try to toggle switch back to ON
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify validation error appears
      expect(find.text('Nomor WhatsApp wajib diisi.'), findsOneWidget);
    });

    testWidgets(
      '5. Submitting valid WhatsApp number saves data to dummy store and returns success',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: NotifikasiWhatsAppScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Enter valid number
        await tester.enterText(find.byType(TextField), '089876543210');
        await tester.pumpAndSettle();

        // Tap Simpan Pengaturan
        await tester.tap(find.text('Simpan Pengaturan'));
        await tester.pump(); // Start save async
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Verify state in provider updated
        final updatedSub = container.read(waNotificationProvider).subscription;
        expect(updatedSub.waNumber, '089876543210');
        expect(updatedSub.isSubscribed, isTrue);
      },
    );

    testWidgets('WhatsApp shows the authenticated account registration date', (
      tester,
    ) async {
      final registeredUser = UserModel(
        id: 99,
        name: 'Pengguna Uji',
        email: 'uji@example.test',
        username: 'penggunauji',
        noHp: '081234567890',
        namaOpd: 'OPD Uji',
        role: 'user',
        status: '1',
        createdAt: DateTime(2026, 1, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.state = AuthState(
                isLoggedIn: true,
                currentUser: registeredUser,
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(home: NotifikasiWhatsAppScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Akun terdaftar sejak 15 Januari 2026'), findsOneWidget);
    });

    testWidgets('6. Tapping Keluar opens logout confirmation dialog', (
      tester,
    ) async {
      await tester.pumpWidget(buildProfilWidget());
      await tester.pumpAndSettle();

      // Ensure logout button visible and tap
      final logoutCard = find.widgetWithText(InkWell, 'Keluar (Logout)');
      await Scrollable.ensureVisible(
        tester.element(logoutCard),
        alignment: 0.5,
      );
      await tester.tap(logoutCard);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Konfirmasi Logout'), findsOneWidget);
      expect(
        find.text('Anda yakin ingin keluar dari aplikasi Gelatik?'),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya, Keluar'), findsOneWidget);
    });
  });
}
