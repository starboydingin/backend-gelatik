import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/master_item_model.dart';
import '../repositories/master_item_repository.dart';

enum InfoAlatStatus { initial, loading, success, empty, error, refreshing }

class InfoAlatState {
  final List<MasterItemModel> items;
  final InfoAlatStatus status;
  final String? errorMessage;
  final MasterItemErrorType? errorType;
  final String query;

  const InfoAlatState({
    this.items = const [],
    this.status = InfoAlatStatus.initial,
    this.errorMessage,
    this.errorType,
    this.query = '',
  });

  bool get isLoading => status == InfoAlatStatus.loading;
  bool get isRefreshing => status == InfoAlatStatus.refreshing;
}

class InfoAlatNotifier extends StateNotifier<InfoAlatState> {
  final MasterItemRepository repository;
  int _requestGeneration = 0;

  InfoAlatNotifier({required this.repository}) : super(const InfoAlatState());

  Future<void> loadItems({bool force = false}) {
    return _fetch(query: '', force: force);
  }

  Future<void> searchItems(String query) {
    return _fetch(query: query.trim());
  }

  Future<void> retry() {
    return _fetch(query: state.query, force: true);
  }

  Future<void> refresh() async {
    await _fetch(query: state.query, refreshing: true, force: true);
  }

  Future<void> _fetch({
    required String query,
    bool refreshing = false,
    bool force = false,
  }) async {
    final normalizedQuery = query.trim();
    final requestInProgress =
        state.status == InfoAlatStatus.loading ||
        state.status == InfoAlatStatus.refreshing;
    if (!force && requestInProgress && state.query == normalizedQuery) return;
    if (!force &&
        !requestInProgress &&
        state.query == normalizedQuery &&
        (state.status == InfoAlatStatus.success ||
            state.status == InfoAlatStatus.empty)) {
      return;
    }

    final generation = ++_requestGeneration;
    state = InfoAlatState(
      items: refreshing ? state.items : const [],
      status: refreshing ? InfoAlatStatus.refreshing : InfoAlatStatus.loading,
      query: normalizedQuery,
    );

    try {
      final items = normalizedQuery.isEmpty
          ? await repository.getItems()
          : await repository.searchItems(normalizedQuery);
      if (generation != _requestGeneration) return;

      state = InfoAlatState(
        items: items,
        status: items.isEmpty ? InfoAlatStatus.empty : InfoAlatStatus.success,
        query: normalizedQuery,
      );
    } on MasterItemRepositoryException catch (error) {
      if (generation != _requestGeneration) return;
      state = InfoAlatState(
        status: InfoAlatStatus.error,
        errorMessage: error.message,
        errorType: error.type,
        query: normalizedQuery,
      );
    } catch (_) {
      if (generation != _requestGeneration) return;
      state = InfoAlatState(
        status: InfoAlatStatus.error,
        errorMessage: 'Terjadi kesalahan saat memuat katalog alat.',
        errorType: MasterItemErrorType.unknown,
        query: normalizedQuery,
      );
    }
  }
}

final infoAlatProvider = StateNotifierProvider<InfoAlatNotifier, InfoAlatState>(
  (ref) {
    return InfoAlatNotifier(
      repository: ref.watch(masterItemRepositoryProvider),
    );
  },
);
