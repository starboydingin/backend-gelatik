import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dummy/dummy_data.dart';
import '../../../core/services/fcm_topic_service.dart';
import '../models/user_model.dart';

enum AuthResultStatus {
  authenticated,
  pendingActivation,
  error,
}

class AuthState {
  final bool isLoggedIn;
  final UserModel? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final String? pendingActivationMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.pendingActivationMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserModel? currentUser,
    bool? isLoading,
    String? errorMessage,
    String? pendingActivationMessage,
    bool clearErrors = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      pendingActivationMessage: clearErrors
          ? null
          : (pendingActivationMessage ?? this.pendingActivationMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FcmTopicService? fcmTopicService;

  AuthNotifier({this.fcmTopicService}) : super(const AuthState());

  /// Simulasi pengecekan token tersimpan (BAGIAN 1)
  Future<bool> checkAuthToken() async {
    state = state.copyWith(isLoading: true, clearErrors: true);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false);
    return state.isLoggedIn;
  }

  /// Simulasi login terhadap dummy_data.dart (BAGIAN 2 & FR-35)
  Future<AuthResultStatus> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    await Future.delayed(const Duration(milliseconds: 1000));

    final trimmedIdentifier = identifier.trim().toLowerCase();

    // Cari user berdasarkan email atau username di DummyData
    final user = DummyData.dummyUsers.firstWhere(
      (u) =>
          u.email.toLowerCase() == trimmedIdentifier ||
          u.username.toLowerCase() == trimmedIdentifier,
      orElse: () => const UserModel(
        id: -1,
        name: '',
        email: '',
        username: '',
        noHp: '',
        namaOpd: '',
        role: '',
        status: '',
      ),
    );

    if (user.id == -1) {
      // User tidak ditemukan
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email/NIP atau password salah.',
      );
      return AuthResultStatus.error;
    }

    // FR-35: Cek status == '0' (nonaktif / pending aktivasi admin)
    if (user.status == '0') {
      state = state.copyWith(
        isLoading: false,
        pendingActivationMessage: 'Akun Anda belum aktif atau telah dinonaktifkan.',
      );
      return AuthResultStatus.pendingActivation;
    }

    // User ditemukan & status == '1' (aktif)
    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      currentUser: user,
    );

    // FR-37: Subscribe ke topic FCM pengguna setelah login BERHASIL
    await fcmTopicService?.subscribeToUserTopics(user);

    return AuthResultStatus.authenticated;
  }

  /// Simulasi registrasi (BAGIAN 3 & FR-36)
  Future<bool> register({
    required String name,
    required String nip,
    required String email,
    required String noHp,
    required String namaOpd,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    await Future.delayed(const Duration(milliseconds: 1000));

    state = state.copyWith(isLoading: false);
    // FR-36: Registrasi berhasil tetapi tidak menyimpan permanen / tidak auto-login
    return true;
  }

  /// Membersihkan pesan error atau banner
  void clearMessages() {
    state = state.copyWith(clearErrors: true);
  }

  /// Logout (FR-38: Unsubscribe dari topic FCM sebelum proses logout selesai)
  Future<void> logout() async {
    await fcmTopicService?.unsubscribeFromAllTopics();

    state = const AuthState(
      isLoggedIn: false,
      currentUser: null,
      isLoading: false,
      errorMessage: null,
      pendingActivationMessage: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final fcmTopicService = ref.watch(fcmTopicServiceProvider);
  return AuthNotifier(fcmTopicService: fcmTopicService);
});
