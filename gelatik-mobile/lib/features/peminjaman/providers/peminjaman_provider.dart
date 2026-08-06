import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../info_alat/models/master_item_model.dart';
import '../models/pinjam_model.dart';
import '../models/pinjam_request.dart';
import '../repositories/peminjaman_repository.dart';

enum PeminjamanLoadStatus {
  initial,
  loading,
  success,
  empty,
  error,
  refreshing,
}

enum PeminjamanMutationStatus {
  idle,
  submitting,
  success,
  validationError,
  forbidden,
  conflict,
  error,
}

class PeminjamanState {
  final List<PinjamModel> listPinjam;
  final PinjamModel? selectedPinjam;
  final PeminjamanLoadStatus status;
  final PeminjamanMutationStatus mutationStatus;
  final String? successMessage;
  final String? errorMessage;
  final PeminjamanErrorType? errorType;
  final Map<String, dynamic> validationErrors;

  const PeminjamanState({
    this.listPinjam = const [],
    this.selectedPinjam,
    this.status = PeminjamanLoadStatus.initial,
    this.mutationStatus = PeminjamanMutationStatus.idle,
    this.successMessage,
    this.errorMessage,
    this.errorType,
    this.validationErrors = const {},
  });

  bool get isLoading =>
      status == PeminjamanLoadStatus.loading ||
      mutationStatus == PeminjamanMutationStatus.submitting;
  bool get isRefreshing => status == PeminjamanLoadStatus.refreshing;
  bool get isSubmitting =>
      mutationStatus == PeminjamanMutationStatus.submitting;

  PeminjamanState copyWith({
    List<PinjamModel>? listPinjam,
    PinjamModel? selectedPinjam,
    PeminjamanLoadStatus? status,
    PeminjamanMutationStatus? mutationStatus,
    String? successMessage,
    String? errorMessage,
    PeminjamanErrorType? errorType,
    Map<String, dynamic>? validationErrors,
    bool clearSelected = false,
    bool clearMessages = false,
  }) => PeminjamanState(
    listPinjam: listPinjam ?? this.listPinjam,
    selectedPinjam: clearSelected
        ? null
        : (selectedPinjam ?? this.selectedPinjam),
    status: status ?? this.status,
    mutationStatus: mutationStatus ?? this.mutationStatus,
    successMessage: clearMessages
        ? null
        : (successMessage ?? this.successMessage),
    errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    errorType: clearMessages ? null : (errorType ?? this.errorType),
    validationErrors: clearMessages
        ? const {}
        : (validationErrors ?? this.validationErrors),
  );
}

class PeminjamanNotifier extends StateNotifier<PeminjamanState> {
  final PeminjamanRepository repository;
  int _listGeneration = 0;
  int _detailGeneration = 0;

  PeminjamanNotifier({required this.repository})
    : super(const PeminjamanState());

  Future<void> loadPeminjaman({bool force = false}) async {
    final inFlight =
        state.status == PeminjamanLoadStatus.loading ||
        state.status == PeminjamanLoadStatus.refreshing;
    if (!force && inFlight) return;
    if (!force &&
        (state.status == PeminjamanLoadStatus.success ||
            state.status == PeminjamanLoadStatus.empty)) {
      return;
    }
    await _fetchList(refreshing: false);
  }

  Future<void> refresh() => _fetchList(refreshing: true);
  Future<void> retry() => _fetchList(refreshing: false);

  Future<void> refreshFromRealtime(int entityId) async {
    await _fetchList(refreshing: true);
    if (!mounted) return;
    if (state.selectedPinjam?.id == entityId) await loadDetail(entityId);
  }

  Future<void> _fetchList({required bool refreshing}) async {
    final generation = ++_listGeneration;
    state = state.copyWith(
      status: refreshing
          ? PeminjamanLoadStatus.refreshing
          : PeminjamanLoadStatus.loading,
      clearMessages: true,
    );
    try {
      final list = await repository.getPeminjaman();
      if (generation != _listGeneration) return;
      state = state.copyWith(
        listPinjam: list,
        status: list.isEmpty
            ? PeminjamanLoadStatus.empty
            : PeminjamanLoadStatus.success,
        clearMessages: true,
      );
    } on PeminjamanRepositoryException catch (error) {
      if (generation != _listGeneration) return;
      state = state.copyWith(
        status: PeminjamanLoadStatus.error,
        errorMessage: error.message,
        errorType: error.type,
      );
    } catch (_) {
      if (generation != _listGeneration) return;
      state = state.copyWith(
        status: PeminjamanLoadStatus.error,
        errorMessage: 'Terjadi kesalahan saat memuat peminjaman.',
        errorType: PeminjamanErrorType.unknown,
      );
    }
  }

  Future<void> loadDetail(int id) async {
    final generation = ++_detailGeneration;
    state = state.copyWith(
      status: PeminjamanLoadStatus.loading,
      clearMessages: true,
    );
    try {
      final detail = await repository.getPeminjamanDetail(id);
      if (generation != _detailGeneration) return;
      _replace(detail);
      state = state.copyWith(
        selectedPinjam: detail,
        status: PeminjamanLoadStatus.success,
      );
    } on PeminjamanRepositoryException catch (error) {
      if (generation != _detailGeneration) return;
      state = state.copyWith(
        status: PeminjamanLoadStatus.error,
        errorMessage: error.message,
        errorType: error.type,
        clearSelected: true,
      );
    } catch (_) {
      if (generation != _detailGeneration) return;
      state = state.copyWith(
        status: PeminjamanLoadStatus.error,
        errorMessage: 'Terjadi kesalahan saat memuat detail peminjaman.',
        errorType: PeminjamanErrorType.unknown,
        clearSelected: true,
      );
    }
  }

  Future<bool> submitPengajuan({
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
    if (state.isSubmitting) return false;
    final itemQuantities = <int, int>{
      for (final entry in selectedItemsWithQuantity.entries)
        if (entry.value > 0) entry.key.id: entry.value,
    };
    if (itemQuantities.isEmpty) {
      state = state.copyWith(
        mutationStatus: PeminjamanMutationStatus.validationError,
        errorMessage: 'Minimal satu aset harus dipilih.',
        validationErrors: const {
          'items': ['Minimal satu aset harus dipilih.'],
        },
      );
      return false;
    }
    state = state.copyWith(
      mutationStatus: PeminjamanMutationStatus.submitting,
      clearMessages: true,
    );
    try {
      final created = await repository.createPeminjaman(
        PinjamRequest(
          namaPic: namaPic,
          jabatanPic: jabatanPic,
          instansiPic: instansiPic,
          kontakPic: kontakPic,
          jenisIdentitas: jenisIdentitas,
          nomorIdentitas: nomorIdentitas,
          alamatPeminjam: alamatPeminjam,
          jenisDurasi: jenisDurasi,
          tanggalMulai: tanggalMulai,
          jamMulai: jamMulai,
          durasiPeminjaman: durasiPeminjaman,
          keterangan: keterangan,
          urlDokumen: urlDokumen,
          itemQuantities: itemQuantities,
        ),
      );
      final list = [
        created,
        ...state.listPinjam.where((item) => item.id != created.id),
      ];
      state = state.copyWith(
        listPinjam: list,
        selectedPinjam: created,
        status: PeminjamanLoadStatus.success,
        mutationStatus: PeminjamanMutationStatus.success,
        successMessage: 'Pengajuan peminjaman berhasil dikirim!',
      );
      return true;
    } on PeminjamanRepositoryException catch (error) {
      _setMutationError(error);
      return false;
    } catch (_) {
      state = state.copyWith(
        mutationStatus: PeminjamanMutationStatus.error,
        errorMessage: 'Gagal mengirim pengajuan peminjaman.',
        errorType: PeminjamanErrorType.unknown,
      );
      return false;
    }
  }

  Future<bool> setujuPeminjaman(int id) => _changeStatus(id, 'Proses');

  Future<bool> tolakPeminjaman(int id, String catatanPetugas) =>
      _changeStatus(id, 'Ditolak', catatan: catatanPetugas);

  Future<bool> selesaikanPeminjaman(int id, {String? buktiPengembalian}) =>
      _changeStatus(id, 'Selesai');

  Future<bool> _changeStatus(int id, String status, {String? catatan}) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(
      mutationStatus: PeminjamanMutationStatus.submitting,
      clearMessages: true,
    );
    try {
      var updated = await repository.updateStatus(id, status, catatan: catatan);
      PinjamModel? previous;
      for (final item in state.listPinjam) {
        if (item.id == id) {
          previous = item;
          break;
        }
      }
      if (updated.items.isEmpty &&
          previous != null &&
          previous.items.isNotEmpty) {
        updated = updated.copyWith(items: previous.items);
      }
      _replace(updated);
      state = state.copyWith(
        selectedPinjam: updated,
        mutationStatus: PeminjamanMutationStatus.success,
        successMessage: 'Status peminjaman berhasil diperbarui.',
      );
      return true;
    } on PeminjamanRepositoryException catch (error) {
      _setMutationError(error);
      return false;
    } catch (_) {
      state = state.copyWith(
        mutationStatus: PeminjamanMutationStatus.error,
        errorMessage: 'Status peminjaman gagal diperbarui.',
        errorType: PeminjamanErrorType.unknown,
      );
      return false;
    }
  }

  Future<bool> cancelPeminjaman(int id) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(
      mutationStatus: PeminjamanMutationStatus.submitting,
      clearMessages: true,
    );
    try {
      await repository.cancelPeminjaman(id);
      final remaining = state.listPinjam
          .where((item) => item.id != id)
          .toList();
      state = state.copyWith(
        listPinjam: remaining,
        status: remaining.isEmpty
            ? PeminjamanLoadStatus.empty
            : PeminjamanLoadStatus.success,
        mutationStatus: PeminjamanMutationStatus.success,
        successMessage: 'Pengajuan peminjaman berhasil dibatalkan.',
        clearSelected: true,
      );
      return true;
    } on PeminjamanRepositoryException catch (error) {
      _setMutationError(error);
      return false;
    } catch (_) {
      state = state.copyWith(
        mutationStatus: PeminjamanMutationStatus.error,
        errorMessage: 'Pengajuan peminjaman gagal dibatalkan.',
        errorType: PeminjamanErrorType.unknown,
      );
      return false;
    }
  }

  void _replace(PinjamModel updated) {
    final found = state.listPinjam.any((item) => item.id == updated.id);
    final list = found
        ? state.listPinjam
              .map((item) => item.id == updated.id ? updated : item)
              .toList()
        : [updated, ...state.listPinjam];
    state = state.copyWith(listPinjam: list);
  }

  void _setMutationError(PeminjamanRepositoryException error) {
    final mutationStatus = switch (error.type) {
      PeminjamanErrorType.validation =>
        PeminjamanMutationStatus.validationError,
      PeminjamanErrorType.forbidden => PeminjamanMutationStatus.forbidden,
      PeminjamanErrorType.conflict ||
      PeminjamanErrorType.invalidState => PeminjamanMutationStatus.conflict,
      _ => PeminjamanMutationStatus.error,
    };
    state = state.copyWith(
      mutationStatus: mutationStatus,
      errorMessage: error.message,
      errorType: error.type,
      validationErrors: error.errors ?? const {},
    );
  }

  void clearMessage() {
    state = state.copyWith(
      mutationStatus: PeminjamanMutationStatus.idle,
      clearMessages: true,
    );
  }
}

final peminjamanProvider =
    StateNotifierProvider<PeminjamanNotifier, PeminjamanState>((ref) {
      return PeminjamanNotifier(
        repository: ref.watch(peminjamanRepositoryProvider),
      );
    });
