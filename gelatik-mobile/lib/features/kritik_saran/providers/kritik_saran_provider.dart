import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../repositories/kritik_saran_repository.dart';

class KritikSaranState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  const KritikSaranState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });
}

class KritikSaranNotifier extends StateNotifier<KritikSaranState> {
  final KritikSaranRepository repository;

  KritikSaranNotifier({required this.repository})
    : super(const KritikSaranState());

  Future<bool> submitKritikSaran({
    required String kritik,
    required String saran,
  }) async {
    if (state.isLoading) return false;

    state = const KritikSaranState(isLoading: true);
    try {
      await repository.submit(kritik: kritik, saran: saran);
      state = const KritikSaranState(
        successMessage: 'Kritik & Saran berhasil dikirimkan!',
      );
      return true;
    } on ApiException catch (error) {
      state = KritikSaranState(errorMessage: error.message);
      return false;
    } catch (_) {
      state = const KritikSaranState(
        errorMessage: 'Kritik dan saran gagal dikirim. Silakan coba lagi.',
      );
      return false;
    }
  }
}

final kritikSaranProvider =
    StateNotifierProvider<KritikSaranNotifier, KritikSaranState>((ref) {
      return KritikSaranNotifier(
        repository: ref.watch(kritikSaranRepositoryProvider),
      );
    });
