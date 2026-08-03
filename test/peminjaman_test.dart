import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gelatik/core/dummy/dummy_data.dart';
import 'package:gelatik/features/peminjaman/models/pinjam_model.dart';
import 'package:gelatik/features/peminjaman/providers/peminjaman_provider.dart';
import 'package:gelatik/features/peminjaman/presentation/screens/ajukan_peminjaman_screen.dart';

void main() {
  group('Peminjaman Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Multi-select submission with 2 different items succeeds and populates items correctly',
        () async {
      final notifier = container.read(peminjamanProvider.notifier);

      final item1 = DummyData.masterItems[0]; // Laptop ThinkPad
      final item2 = DummyData.masterItems[1]; // Proyektor Epson

      final selectedItemsMap = {
        item1: 2,
        item2: 1,
      };

      final success = await notifier.submitPengajuan(
        userId: 1,
        namaPic: 'Ahmad Subagja, S.Kom.',
        jabatanPic: 'Pranata Komputer Ahli Muda',
        instansiPic: 'Dinas Komunikasi, Informatika dan Statistik Provinsi Lampung',
        kontakPic: '081272345678',
        jenisIdentitas: 'NIP',
        nomorIdentitas: '198804122014031002',
        alamatPeminjam: 'Jl. Wolter Monginsidi No. 69, Bandar Lampung',
        jenisDurasi: 'harian',
        tanggalMulai: DateTime(2026, 8, 1, 8, 0),
        jamMulai: '08:00',
        durasiPeminjaman: 3,
        keterangan: 'Keperluan Rapat Koordinasi',
        urlDokumen: 'surat_permohonan.pdf',
        selectedItemsWithQuantity: selectedItemsMap,
      );

      expect(success, isTrue);

      final state = container.read(peminjamanProvider);
      final newlyAdded = state.listPinjam.first;

      expect(newlyAdded.namaPic, 'Ahmad Subagja, S.Kom.');
      expect(newlyAdded.urlDokumen, 'surat_permohonan.pdf');
      expect(newlyAdded.buktiPengembalian, isNull); // Field url_dokumen != buktiPengembalian
      expect(newlyAdded.items.length, 2); // 2 items selected!
      expect(newlyAdded.items[0].itemId, item1.id);
      expect(newlyAdded.items[0].quantity, 2);
      expect(newlyAdded.items[1].itemId, item2.id);
      expect(newlyAdded.items[1].quantity, 1);
    });

    test('2. PinjamModel json serialization handles url_dokumen correctly', () {
      final jsonMap = {
        'id': 99,
        'user_id': 1,
        'nama_pic': 'Test PIC',
        'jabatan_pic': 'Staf',
        'instansi_pic': 'Diskominfotik',
        'kontak_pic': '08123',
        'jenis_identitas': 'KTP',
        'nomor_identitas': '123456',
        'alamat_peminjam': 'Jl. Test',
        'jenis_durasi': 'harian',
        'tanggal_mulai': '2026-08-01T08:00:00.000',
        'durasi_peminjaman': 2,
        'status': 'Menunggu',
        'url_dokumen': 'dokumen_pengajuan_v1.pdf',
        'items': [
          {
            'id': 10,
            'pinjam_id': 99,
            'item_id': 101,
            'quantity': 2,
          }
        ]
      };

      final model = PinjamModel.fromJson(jsonMap);
      expect(model.urlDokumen, 'dokumen_pengajuan_v1.pdf');
      expect(model.items.length, 1);

      final serializedJson = model.toJson();
      expect(serializedJson['url_dokumen'], 'dokumen_pengajuan_v1.pdf');
      expect(serializedJson['bukti_pengembalian'], isNull);
    });
  });

  group('AjukanPeminjamanScreen Widget Tests', () {
    testWidgets('AjukanPeminjamanScreen renders Step 1 with stepper header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AjukanPeminjamanScreen(),
          ),
        ),
      );

      // Verify Header Stepper numbers 1 and 2
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify Step 1 Title & master item names
      expect(find.text('Pilih Aset TIK yang Ingin Dipinjam'), findsOneWidget);
      expect(find.text('Laptop Lenovo ThinkPad L14 Gen 3'), findsOneWidget);
      expect(find.text('Proyektor Epson EB-X05'), findsOneWidget);
    });
  });
}
