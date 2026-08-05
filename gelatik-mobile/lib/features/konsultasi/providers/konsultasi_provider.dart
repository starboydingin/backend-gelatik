import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dummy/dummy_data.dart';
import '../models/konsultasi_model.dart';
import '../models/konsultasi_response_model.dart';

class KonsultasiState {
  final List<KonsultasiModel> listKonsultasi;
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  const KonsultasiState({
    required this.listKonsultasi,
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  KonsultasiState copyWith({
    List<KonsultasiModel>? listKonsultasi,
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return KonsultasiState(
      listKonsultasi: listKonsultasi ?? this.listKonsultasi,
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

class KonsultasiNotifier extends StateNotifier<KonsultasiState> {
  KonsultasiNotifier()
      : super(
          KonsultasiState(
            listKonsultasi: List.from(DummyData.konsultasiList),
          ),
        );

  /// Tambah Tiket Konsultasi Baru (BuatKonsultasiScreen)
  Future<bool> tambahKonsultasi({
    required int userId,
    required String judul,
    required String pesan,
    required String topikNama,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final newId = DateTime.now().millisecondsSinceEpoch % 100000;
      final newTiket = KonsultasiModel(
        id: newId,
        userId: userId,
        judul: judul,
        pesan: pesan,
        status: 'Menunggu',
        createdAt: DateTime.now(),
        topik: {'id': 99, 'nama': topikNama},
        responses: [],
      );

      final updatedList = [newTiket, ...state.listKonsultasi];
      DummyData.konsultasiList = updatedList;

      state = state.copyWith(
        isLoading: false,
        listKonsultasi: updatedList,
        successMessage: 'Konsultasi berhasil dibuat!',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membuat konsultasi: ${e.toString()}',
      );
      return false;
    }
  }

  /// Balas pesan pada thread konsultasi
  Future<bool> kirimBalasan({
    required int konsultasiId,
    required int userId,
    required String namaPengirim,
    required String pesan,
    bool isAdmin = false,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final updatedList = state.listKonsultasi.map((k) {
        if (k.id == konsultasiId) {
          final newResponse = KonsultasiResponseModel(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            konsultasiId: konsultasiId,
            userId: userId,
            pesan: pesan,
            createdAt: DateTime.now(),
            namaPengirim: namaPengirim,
            isAdminUser: isAdmin,
          );

          return KonsultasiModel(
            id: k.id,
            userId: k.userId,
            judul: k.judul,
            pesan: k.pesan,
            faqId: k.faqId,
            file: k.file,
            status: k.status == 'Menunggu' ? 'Diproses' : k.status,
            createdAt: k.createdAt,
            topik: k.topik,
            responses: [...k.responses, newResponse],
          );
        }
        return k;
      }).toList();

      DummyData.konsultasiList = updatedList;

      state = state.copyWith(
        isLoading: false,
        listKonsultasi: updatedList,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengirim balasan: ${e.toString()}',
      );
      return false;
    }
  }
}

final konsultasiProvider =
    StateNotifierProvider<KonsultasiNotifier, KonsultasiState>((ref) {
  return KonsultasiNotifier();
});
