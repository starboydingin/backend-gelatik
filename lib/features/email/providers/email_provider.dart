import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dummy/dummy_data.dart';
import '../models/usulan_email_model.dart';

class EmailState {
  final List<Map<String, dynamic>> listPegawai;
  final List<UsulanEmailModel> listUsulanEmail;
  final bool isLoading;

  const EmailState({
    required this.listPegawai,
    required this.listUsulanEmail,
    this.isLoading = false,
  });

  EmailState copyWith({
    List<Map<String, dynamic>>? listPegawai,
    List<UsulanEmailModel>? listUsulanEmail,
    bool? isLoading,
  }) {
    return EmailState(
      listPegawai: listPegawai ?? this.listPegawai,
      listUsulanEmail: listUsulanEmail ?? this.listUsulanEmail,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class EmailNotifier extends StateNotifier<EmailState> {
  EmailNotifier()
      : super(
          EmailState(
            listPegawai: List.from(DummyData.pegawaiBelumPunyaEmail),
            listUsulanEmail: List.from(DummyData.usulanEmailList),
          ),
        );

  /// Tambah Usulan Email Resmi Baru (Status MUST BE LOWERCASE 'diajukan')
  Future<bool> tambahUsulanEmail({
    required int userId,
    required Map<String, dynamic> pegawaiData,
    required String emailPribadi,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final newId = DateTime.now().millisecondsSinceEpoch % 100000;
      final newUsulan = UsulanEmailModel(
        id: newId,
        userId: userId,
        idPegBkd: pegawaiData['id_peg_bkd'] as int? ?? 0,
        emailPribadi: emailPribadi,
        emailResmi: null,
        tanggalVerifikasi: null,
        diverifikasiOleh: null,
        catatan: null,
        status: 'diajukan', // MUST BE LOWERCASE PER SPEC
        pegawai: pegawaiData,
      );

      final updatedList = [newUsulan, ...state.listUsulanEmail];
      DummyData.usulanEmailList = updatedList;

      state = state.copyWith(
        isLoading: false,
        listUsulanEmail: updatedList,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Admin Action: Setujui Usulan Email & Buat Email Resmi (Status 'diajukan' -> 'disetujui')
  Future<bool> setujuUsulanEmail({
    required int id,
    required String emailResmi,
    String? adminName,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedList = state.listUsulanEmail.map((u) {
      if (u.id == id) {
        return u.copyWith(
          status: 'disetujui', // MUST BE LOWERCASE
          emailResmi: emailResmi,
          tanggalVerifikasi: DateTime.now(),
          diverifikasiOleh: adminName ?? 'Admin BKD',
        );
      }
      return u;
    }).toList();

    DummyData.usulanEmailList = updatedList;
    state = state.copyWith(
      isLoading: false,
      listUsulanEmail: updatedList,
    );
    return true;
  }

  /// Admin Action: Tolak Usulan Email (Status 'diajukan' -> 'ditolak' + catatan)
  Future<bool> tolakUsulanEmail({
    required int id,
    required String catatan,
    String? adminName,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedList = state.listUsulanEmail.map((u) {
      if (u.id == id) {
        return u.copyWith(
          status: 'ditolak', // MUST BE LOWERCASE
          catatan: catatan,
          tanggalVerifikasi: DateTime.now(),
          diverifikasiOleh: adminName ?? 'Admin BKD',
        );
      }
      return u;
    }).toList();

    DummyData.usulanEmailList = updatedList;
    state = state.copyWith(
      isLoading: false,
      listUsulanEmail: updatedList,
    );
    return true;
  }
}

final emailProvider =
    StateNotifierProvider<EmailNotifier, EmailState>((ref) {
  return EmailNotifier();
});
