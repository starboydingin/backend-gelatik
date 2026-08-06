import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/konsultasi_model.dart';
import '../models/konsultasi_request.dart';
import '../models/konsultasi_topik_model.dart';
import '../repositories/konsultasi_repository.dart';

enum KonsultasiLoadStatus {
  initial,
  loading,
  success,
  empty,
  error,
  refreshing,
}

enum KonsultasiMutationStatus {
  idle,
  submitting,
  success,
  validationError,
  forbidden,
  invalidState,
  error,
}

class KonsultasiState {
  final List<KonsultasiModel> listKonsultasi;
  final KonsultasiModel? selectedKonsultasi;
  final List<KonsultasiTopikModel> topiks;
  final KonsultasiLoadStatus status;
  final KonsultasiMutationStatus mutationStatus;
  final bool isTopikLoading;
  final String? successMessage;
  final String? errorMessage;
  final KonsultasiErrorType? errorType;
  final Map<String, dynamic> validationErrors;

  const KonsultasiState({
    this.listKonsultasi = const [],
    this.selectedKonsultasi,
    this.topiks = const [],
    this.status = KonsultasiLoadStatus.initial,
    this.mutationStatus = KonsultasiMutationStatus.idle,
    this.isTopikLoading = false,
    this.successMessage,
    this.errorMessage,
    this.errorType,
    this.validationErrors = const {},
  });

  bool get isLoading =>
      status == KonsultasiLoadStatus.loading ||
      mutationStatus == KonsultasiMutationStatus.submitting;
  bool get isRefreshing => status == KonsultasiLoadStatus.refreshing;
  bool get isSubmitting =>
      mutationStatus == KonsultasiMutationStatus.submitting;

  KonsultasiState copyWith({
    List<KonsultasiModel>? listKonsultasi,
    KonsultasiModel? selectedKonsultasi,
    List<KonsultasiTopikModel>? topiks,
    KonsultasiLoadStatus? status,
    KonsultasiMutationStatus? mutationStatus,
    bool? isTopikLoading,
    String? successMessage,
    String? errorMessage,
    KonsultasiErrorType? errorType,
    Map<String, dynamic>? validationErrors,
    bool clearSelected = false,
    bool clearMessages = false,
  }) => KonsultasiState(
    listKonsultasi: listKonsultasi ?? this.listKonsultasi,
    selectedKonsultasi: clearSelected
        ? null
        : (selectedKonsultasi ?? this.selectedKonsultasi),
    topiks: topiks ?? this.topiks,
    status: status ?? this.status,
    mutationStatus: mutationStatus ?? this.mutationStatus,
    isTopikLoading: isTopikLoading ?? this.isTopikLoading,
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

class KonsultasiNotifier extends StateNotifier<KonsultasiState> {
  final KonsultasiRepository repository;
  int _listGeneration = 0;
  int _detailGeneration = 0;

  KonsultasiNotifier({required this.repository})
    : super(const KonsultasiState());

  Future<void> loadKonsultasi({bool force = false}) async {
    final loaded =
        state.status == KonsultasiLoadStatus.success ||
        state.status == KonsultasiLoadStatus.empty;
    final inFlight =
        state.status == KonsultasiLoadStatus.loading ||
        state.status == KonsultasiLoadStatus.refreshing;
    if (!force && (loaded || inFlight)) return;
    await _fetchList(refreshing: false);
  }

  Future<void> refresh() => _fetchList(refreshing: true);
  Future<void> retry() => _fetchList(refreshing: false);

  Future<void> refreshFromRealtime(int entityId) async {
    await _fetchList(refreshing: true);
    if (!mounted) return;
    if (state.selectedKonsultasi?.id == entityId) await loadDetail(entityId);
  }

  Future<void> _fetchList({required bool refreshing}) async {
    final generation = ++_listGeneration;
    state = state.copyWith(
      status: refreshing
          ? KonsultasiLoadStatus.refreshing
          : KonsultasiLoadStatus.loading,
      clearMessages: true,
    );
    try {
      final list = await repository.getKonsultasi();
      if (generation != _listGeneration) return;
      state = state.copyWith(
        listKonsultasi: list,
        status: list.isEmpty
            ? KonsultasiLoadStatus.empty
            : KonsultasiLoadStatus.success,
        clearMessages: true,
      );
    } on KonsultasiRepositoryException catch (error) {
      if (generation != _listGeneration) return;
      _setLoadError(error);
    } catch (_) {
      if (generation != _listGeneration) return;
      state = state.copyWith(
        status: KonsultasiLoadStatus.error,
        errorMessage: 'Terjadi kesalahan saat memuat konsultasi.',
        errorType: KonsultasiErrorType.unknown,
      );
    }
  }

  Future<void> loadDetail(int id) async {
    final generation = ++_detailGeneration;
    state = state.copyWith(
      status: KonsultasiLoadStatus.loading,
      clearMessages: true,
    );
    try {
      final detail = await repository.getDetail(id);
      if (generation != _detailGeneration) return;
      _replace(detail);
      state = state.copyWith(
        selectedKonsultasi: detail,
        status: KonsultasiLoadStatus.success,
      );
    } on KonsultasiRepositoryException catch (error) {
      if (generation != _detailGeneration) return;
      _setLoadError(error, clearSelected: true);
    } catch (_) {
      if (generation != _detailGeneration) return;
      state = state.copyWith(
        status: KonsultasiLoadStatus.error,
        errorMessage: 'Terjadi kesalahan saat memuat detail konsultasi.',
        errorType: KonsultasiErrorType.unknown,
        clearSelected: true,
      );
    }
  }

  Future<void> loadTopik({bool force = false}) async {
    if ((!force && state.topiks.isNotEmpty) || state.isTopikLoading) return;
    state = state.copyWith(isTopikLoading: true, clearMessages: true);
    try {
      final topiks = await repository.getTopik();
      state = state.copyWith(topiks: topiks, isTopikLoading: false);
    } on KonsultasiRepositoryException catch (error) {
      state = state.copyWith(
        isTopikLoading: false,
        errorMessage: error.message,
        errorType: error.type,
      );
    } catch (_) {
      state = state.copyWith(
        isTopikLoading: false,
        errorMessage: 'Gagal memuat topik konsultasi.',
        errorType: KonsultasiErrorType.unknown,
      );
    }
  }

  Future<bool> tambahKonsultasi({
    required int topikId,
    required String judul,
    required String deskripsi,
    String? filePath,
  }) async {
    if (state.isSubmitting) return false;
    final errors = <String, dynamic>{};
    if (topikId <= 0) errors['topik_id'] = ['Topik wajib dipilih.'];
    if (judul.trim().isEmpty) errors['judul'] = ['Judul wajib diisi.'];
    if (judul.trim().length > 255) {
      errors['judul'] = ['Judul maksimal 255 karakter.'];
    }
    if (deskripsi.trim().isEmpty) {
      errors['deskripsi'] = ['Deskripsi wajib diisi.'];
    }
    if (errors.isNotEmpty) {
      state = state.copyWith(
        mutationStatus: KonsultasiMutationStatus.validationError,
        errorMessage: _firstError(errors),
        validationErrors: errors,
      );
      return false;
    }
    state = state.copyWith(
      mutationStatus: KonsultasiMutationStatus.submitting,
      clearMessages: true,
    );
    try {
      final created = await repository.create(
        BuatKonsultasiRequest(
          topikId: topikId,
          judul: judul,
          deskripsi: deskripsi,
          filePath: filePath,
        ),
      );
      final list = [
        created,
        ...state.listKonsultasi.where((item) => item.id != created.id),
      ];
      state = state.copyWith(
        listKonsultasi: list,
        selectedKonsultasi: created,
        status: KonsultasiLoadStatus.success,
        mutationStatus: KonsultasiMutationStatus.success,
        successMessage: 'Konsultasi berhasil diajukan.',
      );
      return true;
    } on KonsultasiRepositoryException catch (error) {
      _setMutationError(error);
      return false;
    } catch (_) {
      _setUnknownMutation('Gagal mengirim konsultasi.');
      return false;
    }
  }

  Future<bool> kirimBalasan({
    required int konsultasiId,
    required String isiRespon,
    String? filePath,
  }) async {
    if (state.isSubmitting) return false;
    if (isiRespon.trim().isEmpty) {
      state = state.copyWith(
        mutationStatus: KonsultasiMutationStatus.validationError,
        errorMessage: 'Balasan wajib diisi.',
        validationErrors: const {
          'isi_respon': ['Balasan wajib diisi.'],
        },
      );
      return false;
    }
    state = state.copyWith(
      mutationStatus: KonsultasiMutationStatus.submitting,
      clearMessages: true,
    );
    try {
      await repository.answer(
        konsultasiId,
        BalasKonsultasiRequest(isiRespon: isiRespon, filePath: filePath),
      );
      final refreshed = await repository.getDetail(konsultasiId);
      _replace(refreshed);
      state = state.copyWith(
        selectedKonsultasi: refreshed,
        status: KonsultasiLoadStatus.success,
        mutationStatus: KonsultasiMutationStatus.success,
        successMessage: 'Balasan berhasil dikirim.',
      );
      return true;
    } on KonsultasiRepositoryException catch (error) {
      _setMutationError(error);
      return false;
    } catch (_) {
      _setUnknownMutation('Gagal mengirim balasan.');
      return false;
    }
  }

  Future<bool> ubahStatus(int id, String status) async {
    if (state.isSubmitting) return false;
    const allowed = {'Diproses', 'Ditolak', 'Selesai'};
    if (!allowed.contains(status)) {
      state = state.copyWith(
        mutationStatus: KonsultasiMutationStatus.validationError,
        errorMessage: 'Status konsultasi tidak valid.',
        validationErrors: const {
          'status': ['Status konsultasi tidak valid.'],
        },
      );
      return false;
    }
    state = state.copyWith(
      mutationStatus: KonsultasiMutationStatus.submitting,
      clearMessages: true,
    );
    try {
      var updated = await repository.updateStatus(id, status);
      final previous = state.selectedKonsultasi;
      if (previous != null && previous.id == id) {
        updated = updated.copyWith(
          responses: updated.responses.isEmpty
              ? previous.responses
              : updated.responses,
          topik: updated.topik ?? previous.topik,
          userName: updated.userName ?? previous.userName,
        );
      }
      _replace(updated);
      state = state.copyWith(
        selectedKonsultasi: updated,
        mutationStatus: KonsultasiMutationStatus.success,
        successMessage: 'Status konsultasi berhasil diperbarui.',
      );
      return true;
    } on KonsultasiRepositoryException catch (error) {
      _setMutationError(error);
      return false;
    } catch (_) {
      _setUnknownMutation('Gagal memperbarui status konsultasi.');
      return false;
    }
  }

  Future<bool> hapusKonsultasi(int id) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(
      mutationStatus: KonsultasiMutationStatus.submitting,
      clearMessages: true,
    );
    try {
      await repository.delete(id);
      final remaining = state.listKonsultasi
          .where((item) => item.id != id)
          .toList(growable: false);
      state = state.copyWith(
        listKonsultasi: remaining,
        status: remaining.isEmpty
            ? KonsultasiLoadStatus.empty
            : KonsultasiLoadStatus.success,
        mutationStatus: KonsultasiMutationStatus.success,
        successMessage: 'Konsultasi berhasil dihapus.',
        clearSelected: true,
      );
      return true;
    } on KonsultasiRepositoryException catch (error) {
      _setMutationError(error);
      return false;
    } catch (_) {
      _setUnknownMutation('Gagal menghapus konsultasi.');
      return false;
    }
  }

  void _replace(KonsultasiModel updated) {
    final found = state.listKonsultasi.any((item) => item.id == updated.id);
    final list = found
        ? state.listKonsultasi
              .map((item) => item.id == updated.id ? updated : item)
              .toList()
        : [updated, ...state.listKonsultasi];
    state = state.copyWith(listKonsultasi: list);
  }

  void _setLoadError(
    KonsultasiRepositoryException error, {
    bool clearSelected = false,
  }) {
    state = state.copyWith(
      status: KonsultasiLoadStatus.error,
      errorMessage: error.message,
      errorType: error.type,
      clearSelected: clearSelected,
    );
  }

  void _setMutationError(KonsultasiRepositoryException error) {
    final mutationStatus = switch (error.type) {
      KonsultasiErrorType.validation =>
        KonsultasiMutationStatus.validationError,
      KonsultasiErrorType.forbidden => KonsultasiMutationStatus.forbidden,
      KonsultasiErrorType.invalidState ||
      KonsultasiErrorType.conflict => KonsultasiMutationStatus.invalidState,
      _ => KonsultasiMutationStatus.error,
    };
    state = state.copyWith(
      mutationStatus: mutationStatus,
      errorMessage: error.message,
      errorType: error.type,
      validationErrors: error.errors ?? const {},
    );
  }

  void _setUnknownMutation(String message) {
    state = state.copyWith(
      mutationStatus: KonsultasiMutationStatus.error,
      errorMessage: message,
      errorType: KonsultasiErrorType.unknown,
    );
  }

  String _firstError(Map<String, dynamic> errors) {
    final value = errors.values.first;
    return value is List && value.isNotEmpty
        ? value.first.toString()
        : '$value';
  }

  void clearMessage() {
    state = state.copyWith(
      mutationStatus: KonsultasiMutationStatus.idle,
      clearMessages: true,
    );
  }
}

final konsultasiProvider =
    StateNotifierProvider<KonsultasiNotifier, KonsultasiState>((ref) {
      return KonsultasiNotifier(
        repository: ref.watch(konsultasiRepositoryProvider),
      );
    });
