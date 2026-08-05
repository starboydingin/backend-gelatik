import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dummy/dummy_data.dart';
import '../../info_alat/models/master_item_model.dart';
import '../models/pinjam_item_model.dart';
import '../models/pinjam_model.dart';

class PeminjamanState {
  final List<PinjamModel> listPinjam;
  final List<MasterItemModel> listMasterItem;
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  const PeminjamanState({
    required this.listPinjam,
    required this.listMasterItem,
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  PeminjamanState copyWith({
    List<PinjamModel>? listPinjam,
    List<MasterItemModel>? listMasterItem,
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return PeminjamanState(
      listPinjam: listPinjam ?? this.listPinjam,
      listMasterItem: listMasterItem ?? this.listMasterItem,
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

class PeminjamanNotifier extends StateNotifier<PeminjamanState> {
  PeminjamanNotifier()
      : super(
          PeminjamanState(
            listPinjam: List.from(DummyData.pinjamList),
            listMasterItem: List.from(DummyData.masterItems),
          ),
        );

  /// Submit pengajuan peminjaman baru (menggabungkan Step 1 list item & Step 2 form details)
  Future<bool> submitPengajuan({
    required int userId,
    required String namaPic,
    required String jabatanPic,
    required String instansiPic,
    required String kontakPic,
    required String jenisIdentitas,
    required String nomorIdentitas,
    required String alamatPeminjam,
    required String jenisDurasi,
    required DateTime tanggalMulai,
    String? jamMulai,
    required int durasiPeminjaman,
    String? keterangan,
    String? urlDokumen,
    required Map<MasterItemModel, int> selectedItemsWithQuantity,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Simulasi delay request backend (800ms)
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final newPinjamId = DateTime.now().millisecondsSinceEpoch % 100000;

      final List<PinjamItemModel> items = [];
      int itemIdCounter = 1;

      selectedItemsWithQuantity.forEach((masterItem, qty) {
        if (qty > 0) {
          items.add(
            PinjamItemModel(
              id: newPinjamId * 10 + itemIdCounter++,
              pinjamId: newPinjamId,
              itemId: masterItem.id,
              quantity: qty,
              item: masterItem,
            ),
          );
        }
      });

      if (items.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Minimal satu aset harus dipilih.',
        );
        return false;
      }

      final newPinjam = PinjamModel(
        id: newPinjamId,
        userId: userId,
        namaPic: namaPic,
        jabatanPic: jabatanPic,
        instansiPic: instansiPic,
        kontakPic: kontakPic,
        jenisIdentitas: jenisIdentitas,
        nomorIdentitas: nomorIdentitas,
        alamatPeminjam: alamatPeminjam,
        jenisDurasi: jenisDurasi,
        tanggalMulai: tanggalMulai,
        jamMulai: jamMulai ?? '08:00',
        durasiPeminjaman: durasiPeminjaman,
        keterangan: keterangan,
        urlDokumen: urlDokumen,
        status: 'Menunggu',
        items: items,
      );

      final updatedList = [newPinjam, ...state.listPinjam];

      // Juga update di DummyData agar konsisten
      DummyData.pinjamList = updatedList;

      state = state.copyWith(
        isLoading: false,
        listPinjam: updatedList,
        successMessage: 'Pengajuan peminjaman berhasil dikirim!',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengirim pengajuan: ${e.toString()}',
      );
      return false;
    }
  }

  /// Admin Action: Setujui Peminjaman (Status 'Menunggu' -> 'Proses')
  Future<bool> setujuPeminjaman(int id) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedList = state.listPinjam.map((p) {
      if (p.id == id) {
        return p.copyWith(status: 'Proses');
      }
      return p;
    }).toList();

    DummyData.pinjamList = updatedList;
    state = state.copyWith(
      isLoading: false,
      listPinjam: updatedList,
      successMessage: 'Peminjaman berhasil disetujui!',
    );
    return true;
  }

  /// Admin Action: Tolak Peminjaman (Status 'Menunggu' -> 'Ditolak' + catatanPetugas)
  Future<bool> tolakPeminjaman(int id, String catatanPetugas) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedList = state.listPinjam.map((p) {
      if (p.id == id) {
        return p.copyWith(
          status: 'Ditolak',
          catatanPetugas: catatanPetugas,
        );
      }
      return p;
    }).toList();

    DummyData.pinjamList = updatedList;
    state = state.copyWith(
      isLoading: false,
      listPinjam: updatedList,
      successMessage: 'Peminjaman berhasil ditolak.',
    );
    return true;
  }

  /// Admin Action: Tandai Selesai (Status 'Proses' -> 'Selesai' + buktiPengembalian)
  Future<bool> selesaikanPeminjaman(int id, {String? buktiPengembalian}) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedList = state.listPinjam.map((p) {
      if (p.id == id) {
        return p.copyWith(
          status: 'Selesai',
          waktuPengembalian: DateTime.now(),
          buktiPengembalian: buktiPengembalian ?? 'bukti_pengembalian_dummy.jpg',
        );
      }
      return p;
    }).toList();

    DummyData.pinjamList = updatedList;
    state = state.copyWith(
      isLoading: false,
      listPinjam: updatedList,
      successMessage: 'Peminjaman ditandai selesai.',
    );
    return true;
  }

  void clearMessage() {
    state = state.copyWith(successMessage: null, errorMessage: null);
  }
}

final peminjamanProvider =
    StateNotifierProvider<PeminjamanNotifier, PeminjamanState>((ref) {
  return PeminjamanNotifier();
});
