import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/fcm_topic_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

enum AuthResultStatus { authenticated, pendingActivation, error }

class AuthState {
  final bool isLoggedIn;
  final UserModel? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final String? pendingActivationMessage;
  final List<String> opds;
  final bool isOpdLoading;
  final String? opdErrorMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.pendingActivationMessage,
    this.opds = const [],
    this.isOpdLoading = false,
    this.opdErrorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserModel? currentUser,
    bool? isLoading,
    String? errorMessage,
    String? pendingActivationMessage,
    List<String>? opds,
    bool? isOpdLoading,
    String? opdErrorMessage,
    bool clearErrors = false,
    bool clearOpdError = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      pendingActivationMessage: clearErrors
          ? null
          : (pendingActivationMessage ?? this.pendingActivationMessage),
      opds: opds ?? this.opds,
      isOpdLoading: isOpdLoading ?? this.isOpdLoading,
      opdErrorMessage: clearOpdError
          ? null
          : (opdErrorMessage ?? this.opdErrorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository? authRepository;
  final SecureStorageService? secureStorageService;
  final FcmTopicService? fcmTopicService;

  AuthNotifier({
    this.authRepository,
    this.secureStorageService,
    this.fcmTopicService,
  }) : super(const AuthState());

  Future<void> loadOpds() async {
    final repo = authRepository;
    if (repo == null) {
      state = state.copyWith(
        isOpdLoading: false,
        opdErrorMessage: 'Repository daftar OPD belum diinisialisasi.',
      );
      return;
    }

    state = state.copyWith(isOpdLoading: true, clearOpdError: true);
    try {
      final opds = await repo.getOpds();
      state = state.copyWith(
        opds: opds,
        isOpdLoading: false,
        clearOpdError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        opds: const [],
        isOpdLoading: false,
        opdErrorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        opds: const [],
        isOpdLoading: false,
        opdErrorMessage: 'Gagal memuat daftar OPD.',
      );
    }
  }

  /// Pengecekan token tersimpan di SecureStorage (Splash)
  Future<bool> checkAuthToken() async {
    state = state.copyWith(isLoading: true, clearErrors: true);
    try {
      final storage = secureStorageService;
      final repo = authRepository;
      if (storage == null || repo == null) {
        state = state.copyWith(isLoading: false);
        return state.isLoggedIn;
      }

      final token = await storage.getToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          currentUser: null,
        );
        return false;
      }

      final userData = await repo.getMe();
      final user = UserModel.fromJson(userData);

      if (user.status == '0') {
        await storage.deleteToken();
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          currentUser: null,
          pendingActivationMessage:
              'Akun Anda belum aktif atau telah dinonaktifkan.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        currentUser: user,
      );

      await fcmTopicService?.subscribeToUserTopics(user);
      return true;
    } catch (e) {
      await secureStorageService?.deleteToken();
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        currentUser: null,
      );
      return false;
    }
  }

  /// Login via AuthRepository (FR-35)
  Future<AuthResultStatus> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    final repo = authRepository;
    final storage = secureStorageService;

    if (repo == null || storage == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'AuthRepository / SecureStorageService belum diinisialisasi.',
      );
      return AuthResultStatus.error;
    }

    try {
      final loginData = await repo.login(identifier, password);
      final String? token = loginData['access_token'] as String?;

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Token autentikasi tidak ditemukan dari server.',
        );
        return AuthResultStatus.error;
      }

      await storage.saveToken(token);

      UserModel user;
      if (loginData['user'] != null &&
          loginData['user'] is Map<String, dynamic>) {
        user = UserModel.fromJson(Map<String, dynamic>.from(loginData['user']));
      } else {
        final userData = await repo.getMe();
        user = UserModel.fromJson(userData);
      }

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        currentUser: user,
      );

      await fcmTopicService?.subscribeToUserTopics(user);

      return AuthResultStatus.authenticated;
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        state = state.copyWith(
          isLoading: false,
          pendingActivationMessage: e.message,
        );
        return AuthResultStatus.pendingActivation;
      }

      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return AuthResultStatus.error;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return AuthResultStatus.error;
    }
  }

  /// Registrasi via AuthRepository (FR-36)
  Future<bool> register({
    required String name,
    required String nip,
    required String email,
    required String noHp,
    required String namaOpd,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    if (password != passwordConfirmation) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Konfirmasi password tidak cocok.',
      );
      return false;
    }

    final repo = authRepository;
    if (repo == null) {
      state = state.copyWith(isLoading: false);
      return true;
    }

    try {
      final success = await repo.register(
        name: name,
        email: email,
        nip: nip,
        noHp: noHp,
        namaOpd: namaOpd,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      state = state.copyWith(isLoading: false);
      return success;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Membersihkan pesan error atau banner
  void clearMessages() {
    state = state.copyWith(clearErrors: true);
  }

  /// Logout (FR-38)
  Future<void> logout() async {
    await fcmTopicService?.unsubscribeFromAllTopics();
    await authRepository?.logout();
    await secureStorageService?.deleteToken();

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
  final authRepository = ref.watch(authRepositoryProvider);
  final secureStorageService = ref.watch(secureStorageServiceProvider);
  final fcmTopicService = ref.watch(fcmTopicServiceProvider);
  return AuthNotifier(
    authRepository: authRepository,
    secureStorageService: secureStorageService,
    fcmTopicService: fcmTopicService,
  );
});
