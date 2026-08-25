import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/fcm_topic_service.dart';
import '../../../core/realtime/realtime_socket_service.dart';
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
  final Map<String, String> validationErrors;

  const AuthState({
    this.isLoggedIn = false,
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.pendingActivationMessage,
    this.opds = const [],
    this.isOpdLoading = false,
    this.opdErrorMessage,
    this.validationErrors = const {},
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
    Map<String, String>? validationErrors,
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
      validationErrors: clearErrors
          ? const {}
          : (validationErrors ?? this.validationErrors),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository? authRepository;
  final SecureStorageService? secureStorageService;
  final FcmTopicService? fcmTopicService;
  final RealtimeSocketService? realtimeSocketService;
  final ApiClient? apiClient;

  AuthNotifier({
    this.authRepository,
    this.secureStorageService,
    this.fcmTopicService,
    this.realtimeSocketService,
    this.apiClient,
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
              'Akun Anda sedang tidak aktif atau telah dinonaktifkan. Hubungi administrator jika Anda memerlukan bantuan.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        currentUser: user,
      );

      await fcmTopicService?.subscribeToUserTopics(user);
      try {
        await realtimeSocketService?.connect();
      } catch (_) {
        // Realtime is optional; REST session remains valid when it is offline.
      }
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
      await _storeAuthenticatedSession(loginData, repo, storage);

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
  Future<AuthResultStatus> register({
    required String name,
    required String nip,
    required String email,
    required String noHp,
    required String namaOpd,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (state.isLoading) return AuthResultStatus.error;

    state = state.copyWith(isLoading: true, clearErrors: true);

    if (password != passwordConfirmation) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Konfirmasi password tidak cocok.',
      );
      return AuthResultStatus.error;
    }

    final repo = authRepository;
    if (repo == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'AuthRepository belum diinisialisasi.',
      );
      return AuthResultStatus.error;
    }

    try {
      final registerData = await repo.register(
        name: name,
        email: email,
        nip: nip,
        noHp: noHp,
        namaOpd: namaOpd,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      final storage = secureStorageService;
      if (storage == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'SecureStorageService belum diinisialisasi.',
        );
        return AuthResultStatus.error;
      }

      await _storeAuthenticatedSession(registerData, repo, storage);
      return AuthResultStatus.authenticated;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        validationErrors: _normalizeValidationErrors(e.errors),
      );
      return AuthResultStatus.error;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return AuthResultStatus.error;
    }
  }

  Future<void> _storeAuthenticatedSession(
    Map<String, dynamic> authData,
    AuthRepository repo,
    SecureStorageService storage,
  ) async {
    final token = authData['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException(
        message: 'Token autentikasi tidak ditemukan dari server.',
      );
    }

    await storage.saveToken(token);

    late final UserModel user;
    try {
      if (authData['user'] is Map) {
        user = UserModel.fromJson(
          Map<String, dynamic>.from(authData['user'] as Map),
        );
      } else {
        user = UserModel.fromJson(await repo.getMe());
      }
    } catch (_) {
      await storage.deleteToken();
      rethrow;
    }

    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      currentUser: user,
      clearErrors: true,
    );
    try {
      await fcmTopicService?.subscribeToUserTopics(user);
    } catch (_) {
      // Session remains valid even when optional notification subscription fails.
    }
    try {
      await realtimeSocketService?.connect();
    } catch (_) {
      // Realtime is optional; REST session remains valid when it is offline.
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String noHp,
    required String namaOpd,
  }) async {
    final repo = authRepository;
    if (repo == null || state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearErrors: true);
    try {
      final user = UserModel.fromJson(
        await repo.updateProfile(
          name: name,
          email: email,
          noHp: noHp,
          namaOpd: namaOpd,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        currentUser: user,
        clearErrors: true,
      );
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Profil tidak dapat diperbarui.',
      );
      return false;
    }
  }

  /// Refresh identity fields when this same account changes them from another
  /// signed-in client. A transient background failure must not end the session.
  Future<void> refreshFromRealtime() async {
    final repo = authRepository;
    if (repo == null || !state.isLoggedIn) return;
    try {
      final user = UserModel.fromJson(await repo.getMe());
      state = state.copyWith(currentUser: user, clearErrors: true);
    } catch (_) {
      // A later foreground refresh retries the canonical profile endpoint.
    }
  }

  Map<String, String> _normalizeValidationErrors(Map<String, dynamic>? errors) {
    if (errors == null) return const {};

    return errors.map((field, value) {
      if (value is List && value.isNotEmpty) {
        return MapEntry(field, value.first.toString());
      }
      return MapEntry(field, value.toString());
    });
  }

  /// Membersihkan pesan error atau banner
  void clearMessages() {
    state = state.copyWith(clearErrors: true);
  }

  /// Logout (FR-38)
  Future<void> logout() async {
    await realtimeSocketService?.disconnect();
    await fcmTopicService?.unsubscribeFromAllTopics();
    await authRepository?.logout();
    await secureStorageService?.deleteToken();
    apiClient?.clearCache();

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
  final realtimeSocketService = ref.watch(realtimeSocketServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(
    authRepository: authRepository,
    secureStorageService: secureStorageService,
    fcmTopicService: fcmTopicService,
    realtimeSocketService: realtimeSocketService,
    apiClient: apiClient,
  );
});
