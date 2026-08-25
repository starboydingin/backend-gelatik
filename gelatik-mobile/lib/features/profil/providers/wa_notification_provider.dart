import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../models/wa_subscription_model.dart';
import '../repositories/wa_notification_repository.dart';

class WaNotificationState {
  final WaSubscriptionModel subscription;
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  const WaNotificationState({
    required this.subscription,
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  WaNotificationState copyWith({
    WaSubscriptionModel? subscription,
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WaNotificationState(
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class WaNotificationNotifier extends StateNotifier<WaNotificationState> {
  final WaNotificationRepository repository;

  WaNotificationNotifier({
    required this.repository,
    WaSubscriptionModel? initialSubscription,
  })
      : super(
          WaNotificationState(
            subscription:
                initialSubscription ??
                const WaSubscriptionModel(
                  userId: 0,
                  waNumber: '',
                  isSubscribed: false,
                ),
          ),
        );

  /// Validasi format nomor WhatsApp:
  /// - Wajib diawali '08' atau '628'
  /// - Panjang total 10 s.d. 15 digit angka
  static String? validateWaNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor WhatsApp wajib diisi.';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Nomor WhatsApp hanya boleh berisi angka.';
    }
    if (!trimmed.startsWith('08') && !trimmed.startsWith('628')) {
      return 'Nomor WhatsApp harus diawali 08 atau 628.';
    }
    if (trimmed.length < 10 || trimmed.length > 15) {
      return 'Panjang nomor WhatsApp harus 10–15 digit.';
    }
    return null;
  }

  Future<void> loadSubscription() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        subscription: await repository.getStatus(),
        isLoading: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } on FormatException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Status notifikasi WhatsApp tidak valid.',
      );
    }
  }

  /// Mengambil ulang preferensi dari server saat perangkat lain mengubahnya.
  Future<void> refreshFromRealtime() => loadSubscription();

  /// Simpan nomor terbaru untuk user yang sedang login melalui API upsert.
  Future<bool> saveSubscription({
    required String waNumber,
    required bool isSubscribed,
  }) async {
    final validationError = validateWaNumber(waNumber);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(isLoading: true);
    try {
      final updated = await repository.save(
        waNumber: waNumber.trim(),
        isSubscribed: isSubscribed,
      );
      state = state.copyWith(
        subscription: updated,
        isLoading: false,
        successMessage: 'Pengaturan Notifikasi WhatsApp berhasil disimpan.',
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } on FormatException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Respons notifikasi WhatsApp tidak valid.',
      );
      return false;
    }
  }
}

final waNotificationProvider =
    StateNotifierProvider<WaNotificationNotifier, WaNotificationState>((ref) {
  return WaNotificationNotifier(
    repository: ref.watch(waNotificationRepositoryProvider),
  );
});
