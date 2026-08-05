import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dummy/dummy_data.dart';
import '../models/master_item_model.dart';

class InfoAlatState {
  final List<MasterItemModel> items;
  final bool isLoading;
  final String? errorMessage;

  const InfoAlatState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  InfoAlatState copyWith({
    List<MasterItemModel>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearErrors = false,
  }) {
    return InfoAlatState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class InfoAlatNotifier extends StateNotifier<InfoAlatState> {
  InfoAlatNotifier() : super(const InfoAlatState(items: DummyData.masterItems));

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearErrors: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    state = state.copyWith(
      items: DummyData.masterItems,
      isLoading: false,
    );
  }
}

final infoAlatProvider =
    StateNotifierProvider<InfoAlatNotifier, InfoAlatState>((ref) {
  return InfoAlatNotifier();
});
