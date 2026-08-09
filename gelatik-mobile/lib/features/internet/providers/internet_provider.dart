import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../repositories/internet_repository.dart';

class InternetState {
  final Map<String, dynamic> bandwidthInfo;
  final List<Map<String, dynamic>> listRouter;
  final List<Map<String, dynamic>> listFaq;
  final bool isLoading;
  final bool routersLoaded;
  final bool faqLoaded;
  final String? errorMessage;

  const InternetState({
    this.bandwidthInfo = const {
      'opd': 'Informasi bandwidth belum tersedia',
      'provider': 'Tidak tersedia dari API',
      'status': 'Belum tersedia',
      'download_mbps': '-',
      'upload_mbps': '-',
    },
    this.listRouter = const [],
    this.listFaq = const [],
    this.isLoading = false,
    this.routersLoaded = false,
    this.faqLoaded = false,
    this.errorMessage,
  });

  InternetState copyWith({
    Map<String, dynamic>? bandwidthInfo,
    List<Map<String, dynamic>>? listRouter,
    List<Map<String, dynamic>>? listFaq,
    bool? isLoading,
    bool? routersLoaded,
    bool? faqLoaded,
    String? errorMessage,
    bool clearError = false,
  }) => InternetState(
    bandwidthInfo: bandwidthInfo ?? this.bandwidthInfo,
    listRouter: listRouter ?? this.listRouter,
    listFaq: listFaq ?? this.listFaq,
    isLoading: isLoading ?? this.isLoading,
    routersLoaded: routersLoaded ?? this.routersLoaded,
    faqLoaded: faqLoaded ?? this.faqLoaded,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class InternetNotifier extends StateNotifier<InternetState> {
  final InternetRepository repository;
  InternetNotifier({required this.repository}) : super(const InternetState());

  Future<void> loadRouters() async {
    if (state.isLoading || state.routersLoaded) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        listRouter: await repository.getRouters(),
        isLoading: false,
        routersLoaded: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } on FormatException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Format data Internet tidak valid.',
      );
    }
  }

  Future<void> loadFaq() async {
    if (state.isLoading || state.faqLoaded) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        listFaq: await repository.getFaqInternet(),
        isLoading: false,
        faqLoaded: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } on FormatException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Format FAQ Internet tidak valid.',
      );
    }
  }
}

final internetProvider = StateNotifierProvider<InternetNotifier, InternetState>(
  (ref) => InternetNotifier(repository: ref.watch(internetRepositoryProvider)),
);
