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

  Future<int?> submitKritikSaran({
    required String kritik,
    required String saran,
  }) async {
    if (state.isLoading) return null;

    state = const KritikSaranState(isLoading: true);
    try {
      final feedbackId = await repository.submit(kritik: kritik, saran: saran);
      state = const KritikSaranState(
        successMessage: 'Kritik & Saran berhasil dikirimkan!',
      );
      return feedbackId;
    } on ApiException catch (error) {
      state = KritikSaranState(errorMessage: error.message);
      return null;
    } catch (_) {
      state = const KritikSaranState(
        errorMessage: 'Kritik dan saran gagal dikirim. Silakan coba lagi.',
      );
      return null;
    }
  }
}

final kritikSaranProvider =
    StateNotifierProvider<KritikSaranNotifier, KritikSaranState>((ref) {
      return KritikSaranNotifier(
        repository: ref.watch(kritikSaranRepositoryProvider),
      );
    });
