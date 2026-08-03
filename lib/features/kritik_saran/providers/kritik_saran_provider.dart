import 'package:flutter_riverpod/flutter_riverpod.dart';

class KritikSaranState {
  final bool isLoading;
  final String? successMessage;

  const KritikSaranState({
    this.isLoading = false,
    this.successMessage,
  });
}

class KritikSaranNotifier extends StateNotifier<KritikSaranState> {
  KritikSaranNotifier() : super(const KritikSaranState());

  Future<bool> submitKritikSaran({
    int? userId,
    required String kritik,
    required String saran,
  }) async {
    state = const KritikSaranState(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate saving feedback
    state = const KritikSaranState(
      isLoading: false,
      successMessage: 'Kritik & Saran berhasil dikirimkan!',
    );
    return true;
  }
}

final kritikSaranProvider =
    StateNotifierProvider<KritikSaranNotifier, KritikSaranState>((ref) {
  return KritikSaranNotifier();
});
