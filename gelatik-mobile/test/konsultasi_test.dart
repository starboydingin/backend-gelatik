import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_model.dart';
import 'package:gelatik/features/konsultasi/models/konsultasi_response_model.dart';
import 'package:gelatik/features/konsultasi/providers/konsultasi_provider.dart';
import 'package:gelatik/features/konsultasi/presentation/screens/konsultasi_list_screen.dart';
import 'package:gelatik/features/konsultasi/presentation/screens/konsultasi_detail_screen.dart';
import 'package:gelatik/features/konsultasi/presentation/screens/buat_konsultasi_screen.dart';

void main() {
  group('Konsultasi Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
        '1. Submit new consultation (tambahKonsultasi) adds item to state and dummy data',
        () async {
      final notifier = container.read(konsultasiProvider.notifier);

      final success = await notifier.tambahKonsultasi(
        userId: 1,
        judul: 'Permohonan Akses VPN OPD',
        pesan: 'Mohon dibantu pembuatan akun VPN untuk akses SIMPEG dari luar jaringan.',
        topikNama: 'Jaringan & Internet',
      );

      expect(success, isTrue);

      final state = container.read(konsultasiProvider);
      final newlyAdded = state.listKonsultasi.first;

      expect(newlyAdded.judul, 'Permohonan Akses VPN OPD');
      expect(newlyAdded.pesan,
          'Mohon dibantu pembuatan akun VPN untuk akses SIMPEG dari luar jaringan.');
      expect(newlyAdded.status, 'Menunggu');
      expect(newlyAdded.topik?['nama'], 'Jaringan & Internet');
    });

    test(
        '2. Sending replies (kirimBalasan) appends responses with correct user vs admin flags',
        () async {
      final notifier = container.read(konsultasiProvider.notifier);
      final targetTiketId = DummyData.konsultasiList[0].id;

      // User sends reply
      final userSuccess = await notifier.kirimBalasan(
        konsultasiId: targetTiketId,
        userId: 1,
        namaPengirim: 'Ahmad Subagja',
        pesan: 'Terima kasih, tim teknis sudah sampai di lokasi.',
        isAdmin: false,
      );

      expect(userSuccess, isTrue);

      // Admin sends reply
      final adminSuccess = await notifier.kirimBalasan(
        konsultasiId: targetTiketId,
        userId: 3,
        namaPengirim: 'Petugas Helpdesk TIK',
        pesan: 'Baik Pak Ahmad, perbaikan Access Point sudah selesai.',
        isAdmin: true,
      );

      expect(adminSuccess, isTrue);

      final state = container.read(konsultasiProvider);
      final updatedTiket =
          state.listKonsultasi.firstWhere((k) => k.id == targetTiketId);

      expect(updatedTiket.responses.length, greaterThanOrEqualTo(2));
      final userResp = updatedTiket.responses[updatedTiket.responses.length - 2];
      final adminResp = updatedTiket.responses.last;

      expect(userResp.isAdminUser, isFalse);
      expect(userResp.namaPengirim, 'Ahmad Subagja');
      expect(adminResp.isAdminUser, isTrue);
      expect(adminResp.namaPengirim, 'Petugas Helpdesk TIK');
    });
  });

  group('Konsultasi Screens Widget Tests', () {
    testWidgets('KonsultasiListScreen renders list of tickets from provider',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: KonsultasiListScreen(),
          ),
        ),
      );

      expect(find.text('Konsultasi TIK'), findsOneWidget);
      expect(
          find.text('Kendala Koneksi Wi-Fi Jaringan Lampung Smart di Lantai 2'),
          findsOneWidget);
    });

    testWidgets(
        'KonsultasiDetailScreen renders thread chat bubbles for admin and user responses',
        (tester) async {
      final sampleTiket = KonsultasiModel(
        id: 901,
        userId: 1,
        judul: 'Uji Coba Chat Bubble',
        pesan: 'Bagaimana status perbaikan server?',
        status: 'Diproses',
        createdAt: DateTime.now(),
        topik: {'id': 1, 'nama': 'Jaringan'},
        responses: [
          KonsultasiResponseModel(
            id: 1,
            konsultasiId: 901,
            userId: 3,
            pesan: 'Server sedang di-restart oleh tim teknis.',
            createdAt: DateTime.now(),
            namaPengirim: 'Petugas Helpdesk TIK',
            isAdminUser: true,
          ),
          KonsultasiResponseModel(
            id: 2,
            konsultasiId: 901,
            userId: 1,
            pesan: 'Siap, terima kasih konfirmasinya.',
            createdAt: DateTime.now(),
            namaPengirim: 'Anda',
            isAdminUser: false,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: KonsultasiDetailScreen(konsultasi: sampleTiket),
          ),
        ),
      );

      // Verify Header & Initial Post
      expect(find.text('Uji Coba Chat Bubble'), findsOneWidget);
      expect(find.text('Bagaimana status perbaikan server?'), findsOneWidget);

      // Verify Admin & User Bubble Messages
      expect(find.text('Server sedang di-restart oleh tim teknis.'),
          findsOneWidget);
      expect(find.text('Siap, terima kasih konfirmasinya.'), findsOneWidget);

      // Verify Sender Names
      expect(find.text('Petugas Helpdesk TIK'), findsOneWidget);
      expect(find.text('Anda'), findsOneWidget);
    });

    testWidgets('BuatKonsultasiScreen form validation and submission flow',
        (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BuatKonsultasiScreen(),
          ),
        ),
      );

      expect(find.text('Form Konsultasi TIK'), findsOneWidget);

      // Enter Judul & Pesan
      await tester.enterText(
          find.byType(TextField).at(0), 'Tanya SSL Certificate Subdomain');
      await tester.enterText(
          find.byType(TextField).at(1), 'Mohon bantuan instalasi SSL pada server.');

      // Tap Kirim Konsultasi
      await tester.tap(find.text('Kirim Konsultasi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      final state = container.read(konsultasiProvider);
      expect(state.listKonsultasi.first.judul, 'Tanya SSL Certificate Subdomain');
    });
  });
}
