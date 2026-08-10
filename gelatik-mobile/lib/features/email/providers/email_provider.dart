import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/network/api_exception.dart';
import '../models/usulan_email_model.dart';
import '../repositories/email_repository.dart';

class EmailState {
  final List<Map<String, dynamic>> listPegawai;
  final List<UsulanEmailModel> listUsulanEmail;
  final bool isLoading;
  final bool pegawaiLoaded;
  final bool usulanLoaded;
  final String? errorMessage;
  const EmailState({
    this.listPegawai = const [],
    this.listUsulanEmail = const [],
    this.isLoading = false,
    this.pegawaiLoaded = false,
    this.usulanLoaded = false,
    this.errorMessage,
  });
  EmailState copyWith({
    List<Map<String, dynamic>>? listPegawai,
    List<UsulanEmailModel>? listUsulanEmail,
    bool? isLoading,
    bool? pegawaiLoaded,
    bool? usulanLoaded,
    String? errorMessage,
    bool clearError = false,
  }) => EmailState(
    listPegawai: listPegawai ?? this.listPegawai,
    listUsulanEmail: listUsulanEmail ?? this.listUsulanEmail,
    isLoading: isLoading ?? this.isLoading,
    pegawaiLoaded: pegawaiLoaded ?? this.pegawaiLoaded,
    usulanLoaded: usulanLoaded ?? this.usulanLoaded,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class EmailNotifier extends StateNotifier<EmailState> {
  final EmailRepository repository;
  EmailNotifier({EmailRepository? repository})
    : repository =
          repository ??
          EmailRepository(
            apiClient: ApiClient(secureStorageService: SecureStorageService()),
          ),
      super(const EmailState());

  Future<void> loadPegawai() async {
    if (state.pegawaiLoaded) return;
    await _load(
      () => repository.getPegawai(),
      (value) => state.copyWith(listPegawai: value, pegawaiLoaded: true),
    );
  }

  Future<void> loadUsulan() async {
    if (state.usulanLoaded) return;
    await _load(
      () => repository.getUsulan(),
      (value) => state.copyWith(listUsulanEmail: value, usulanLoaded: true),
    );
  }

  Future<void> _load<T>(
    Future<T> Function() operation,
    EmailState Function(T) apply,
  ) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = apply(await operation()).copyWith(isLoading: false);
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } on FormatException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Format response Email tidak valid.',
      );
    }
  }

  Future<bool> tambahUsulanEmail({
    required Map<String, dynamic> pegawaiData,
    required String emailPribadi,
  }) async {
    final nip = pegawaiData['nip_baru']?.toString().trim() ?? '';
    if (nip.isEmpty) return false;
    return _mutate(
      () => repository.submit(nip: nip, emailPribadi: emailPribadi),
    );
  }

  Future<bool> setujuUsulanEmail({
    required int id,
    required String emailResmi,
    String? adminName,
  }) => _mutate(() => repository.approve(id, emailResmi));
  Future<bool> verifikasiUsulanEmail({required int id, String? catatan}) =>
      _mutate(() => repository.verify(id, catatan: catatan));
  Future<bool> tolakUsulanEmail({
    required int id,
    required String catatan,
    String? adminName,
  }) => _mutate(() => repository.reject(id, catatan));

  Future<bool> _mutate(Future<UsulanEmailModel> Function() operation) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await operation();
      final list = [
        updated,
        ...state.listUsulanEmail.where((item) => item.id != updated.id),
      ];
      state = state.copyWith(listUsulanEmail: list, isLoading: false);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } on FormatException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Format response Email tidak valid.',
      );
      return false;
    }
  }
}

final emailProvider = StateNotifierProvider<EmailNotifier, EmailState>(
  (ref) => EmailNotifier(repository: ref.watch(emailRepositoryProvider)),
);
