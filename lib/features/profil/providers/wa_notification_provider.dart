import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wa_subscription_model.dart';

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
  }) {
    return WaNotificationState(
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

class WaNotificationNotifier extends StateNotifier<WaNotificationState> {
  WaNotificationNotifier()
      : super(
          WaNotificationState(
            subscription: WaSubscriptionModel(
              userId: 1,
              waNumber: '081234567890',
              isSubscribed: true,
              subscribedAt: DateTime(2026, 1, 15),
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

  /// Update / Simpan Pengaturan Notifikasi WhatsApp
  Future<bool> saveSubscription({
    required String waNumber,
    required bool isSubscribed,
  }) async {
    if (isSubscribed) {
      final validationError = validateWaNumber(waNumber);
      if (validationError != null) {
        state = state.copyWith(errorMessage: validationError);
        return false;
      }
    }

    state = state.copyWith(isLoading: true);

    // Simulasikan delay API
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final updated = state.subscription.copyWith(
      waNumber: waNumber.trim(),
      isSubscribed: isSubscribed,
      subscribedAt: isSubscribed
          ? (state.subscription.subscribedAt ?? now)
          : state.subscription.subscribedAt,
    );

    state = state.copyWith(
      subscription: updated,
      isLoading: false,
      successMessage: 'Pengaturan Notifikasi WhatsApp berhasil disimpan.',
    );
    return true;
  }
}

final waNotificationProvider =
    StateNotifierProvider<WaNotificationNotifier, WaNotificationState>((ref) {
  return WaNotificationNotifier();
});
