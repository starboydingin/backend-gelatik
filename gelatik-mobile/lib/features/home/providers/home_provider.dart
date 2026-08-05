import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/paginated_result.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../info_alat/models/master_item_model.dart';
import '../../info_alat/repositories/master_item_repository.dart';
import '../../konsultasi/models/konsultasi_model.dart';
import '../../konsultasi/repositories/konsultasi_repository.dart';
import '../../peminjaman/models/pinjam_model.dart';
import '../../peminjaman/repositories/peminjaman_repository.dart';
import '../models/home_dashboard_model.dart';

enum HomeLoadStatus {
  initial,
  loading,
  success,
  partialSuccess,
  empty,
  error,
  refreshing,
}

enum HomeSection { items, borrowings, consultations }

enum HomeErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  server,
  malformed,
  unknown,
}

class HomeState {
  final HomeLoadStatus status;
  final HomeDashboardModel data;
  final Map<HomeSection, String> sectionErrors;
  final String? errorMessage;
  final HomeErrorType? errorType;

  const HomeState({
    required this.data,
    this.status = HomeLoadStatus.initial,
    this.sectionErrors = const {},
    this.errorMessage,
    this.errorType,
  });

  bool get isLoading => status == HomeLoadStatus.loading;
  bool get isRefreshing => status == HomeLoadStatus.refreshing;
  bool get hasPartialFailure => sectionErrors.isNotEmpty;
}

class HomeNotifier extends StateNotifier<HomeState> {
  final MasterItemRepository? masterItemRepository;
  final PeminjamanRepository? peminjamanRepository;
  final KonsultasiRepository? konsultasiRepository;
  final UserModel? user;
  int _generation = 0;

  HomeNotifier({
    required MasterItemRepository this.masterItemRepository,
    required PeminjamanRepository this.peminjamanRepository,
    required KonsultasiRepository this.konsultasiRepository,
    required this.user,
  }) : super(HomeState(data: HomeDashboardModel.fromSources(user: user)));

  HomeNotifier.preview(
    HomeDashboardModel data, {
    HomeLoadStatus status = HomeLoadStatus.success,
    Map<HomeSection, String> sectionErrors = const {},
    String? errorMessage,
    HomeErrorType? errorType,
  }) : masterItemRepository = null,
       peminjamanRepository = null,
       konsultasiRepository = null,
       user = null,
       super(
         HomeState(
           status: status,
           data: data,
           sectionErrors: sectionErrors,
           errorMessage: errorMessage,
           errorType: errorType,
         ),
       );

  Future<void> load({bool force = false}) async {
    final inFlight =
        state.status == HomeLoadStatus.loading ||
        state.status == HomeLoadStatus.refreshing;
    final loaded =
        state.status == HomeLoadStatus.success ||
        state.status == HomeLoadStatus.partialSuccess ||
        state.status == HomeLoadStatus.empty;
    if (!force && (inFlight || loaded)) return;
    await _fetch(refreshing: false);
  }

  Future<void> refresh() => _fetch(refreshing: true);
  Future<void> retry() => _fetch(refreshing: false);

  Future<void> _fetch({required bool refreshing}) async {
    final itemRepository = masterItemRepository;
    final borrowRepository = peminjamanRepository;
    final consultRepository = konsultasiRepository;
    if (itemRepository == null ||
        borrowRepository == null ||
        consultRepository == null) {
      return;
    }

    final generation = ++_generation;
    state = HomeState(
      status: refreshing ? HomeLoadStatus.refreshing : HomeLoadStatus.loading,
      data: state.data,
    );

    final outcomes = await Future.wait<_HomeOutcome<dynamic>>([
      _capture(HomeSection.items, itemRepository.getItems()),
      _capture(HomeSection.borrowings, borrowRepository.getPeminjamanPage()),
      _capture(
        HomeSection.consultations,
        consultRepository.getKonsultasiPage(),
      ),
    ]);
    if (generation != _generation) return;

    final errors = <HomeSection, String>{};
    HomeErrorType? primaryError;
    List<MasterItemModel>? items;
    PaginatedResult<PinjamModel>? borrowings;
    PaginatedResult<KonsultasiModel>? consultations;

    for (final outcome in outcomes) {
      if (outcome.error != null) {
        errors[outcome.section] = outcome.error!.message;
        primaryError ??= outcome.error!.type;
        continue;
      }
      switch (outcome.section) {
        case HomeSection.items:
          items = outcome.value as List<MasterItemModel>;
        case HomeSection.borrowings:
          borrowings = outcome.value as PaginatedResult<PinjamModel>;
        case HomeSection.consultations:
          consultations = outcome.value as PaginatedResult<KonsultasiModel>;
      }
    }

    final data = HomeDashboardModel.fromSources(
      user: user,
      items: items,
      borrowings: borrowings,
      consultations: consultations,
      previous: state.data,
    );
    final allFailed = errors.length == HomeSection.values.length;
    final unauthorized = outcomes.any(
      (outcome) => outcome.error?.type == HomeErrorType.unauthorized,
    );
    final status = unauthorized || (allFailed && !data.hasAnySectionData)
        ? HomeLoadStatus.error
        : errors.isNotEmpty
        ? HomeLoadStatus.partialSuccess
        : data.isEmpty
        ? HomeLoadStatus.empty
        : HomeLoadStatus.success;

    state = HomeState(
      status: status,
      data: data,
      sectionErrors: errors,
      errorMessage: status == HomeLoadStatus.error
          ? (unauthorized
                ? 'Sesi Anda telah berakhir. Silakan login kembali.'
                : 'Data Home tidak dapat dimuat. Silakan coba lagi.')
          : null,
      errorType: unauthorized ? HomeErrorType.unauthorized : primaryError,
    );
  }

  Future<_HomeOutcome<T>> _capture<T>(
    HomeSection section,
    Future<T> request,
  ) async {
    try {
      return _HomeOutcome(section: section, value: await request);
    } on MasterItemRepositoryException catch (error) {
      return _HomeOutcome(
        section: section,
        error: _HomeFailure(error.message, _masterError(error.type)),
      );
    } on PeminjamanRepositoryException catch (error) {
      return _HomeOutcome(
        section: section,
        error: _HomeFailure(error.message, _borrowingError(error.type)),
      );
    } on KonsultasiRepositoryException catch (error) {
      return _HomeOutcome(
        section: section,
        error: _HomeFailure(error.message, _consultationError(error.type)),
      );
    } catch (_) {
      return _HomeOutcome(
        section: section,
        error: const _HomeFailure(
          'Terjadi kesalahan saat memuat bagian ini.',
          HomeErrorType.unknown,
        ),
      );
    }
  }

  HomeErrorType _masterError(MasterItemErrorType type) => switch (type) {
    MasterItemErrorType.network => HomeErrorType.network,
    MasterItemErrorType.timeout => HomeErrorType.timeout,
    MasterItemErrorType.unauthorized => HomeErrorType.unauthorized,
    MasterItemErrorType.forbidden => HomeErrorType.forbidden,
    MasterItemErrorType.server => HomeErrorType.server,
    MasterItemErrorType.malformed => HomeErrorType.malformed,
    _ => HomeErrorType.unknown,
  };

  HomeErrorType _borrowingError(PeminjamanErrorType type) => switch (type) {
    PeminjamanErrorType.network => HomeErrorType.network,
    PeminjamanErrorType.timeout => HomeErrorType.timeout,
    PeminjamanErrorType.unauthorized => HomeErrorType.unauthorized,
    PeminjamanErrorType.forbidden => HomeErrorType.forbidden,
    PeminjamanErrorType.server => HomeErrorType.server,
    PeminjamanErrorType.malformed => HomeErrorType.malformed,
    _ => HomeErrorType.unknown,
  };

  HomeErrorType _consultationError(KonsultasiErrorType type) => switch (type) {
    KonsultasiErrorType.network => HomeErrorType.network,
    KonsultasiErrorType.timeout => HomeErrorType.timeout,
    KonsultasiErrorType.unauthorized => HomeErrorType.unauthorized,
    KonsultasiErrorType.forbidden => HomeErrorType.forbidden,
    KonsultasiErrorType.server => HomeErrorType.server,
    KonsultasiErrorType.malformed => HomeErrorType.malformed,
    _ => HomeErrorType.unknown,
  };
}

class _HomeOutcome<T> {
  final HomeSection section;
  final T? value;
  final _HomeFailure? error;

  const _HomeOutcome({required this.section, this.value, this.error});
}

class _HomeFailure {
  final String message;
  final HomeErrorType type;

  const _HomeFailure(this.message, this.type);
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(
    masterItemRepository: ref.watch(masterItemRepositoryProvider),
    peminjamanRepository: ref.watch(peminjamanRepositoryProvider),
    konsultasiRepository: ref.watch(konsultasiRepositoryProvider),
    user: ref.watch(authProvider).currentUser,
  );
});
