import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dummy/dummy_data.dart';

class InternetState {
  final Map<String, dynamic> bandwidthInfo;
  final List<Map<String, dynamic>> listRouter;
  final List<Map<String, dynamic>> listFaq;

  const InternetState({
    required this.bandwidthInfo,
    required this.listRouter,
    required this.listFaq,
  });
}

class InternetNotifier extends StateNotifier<InternetState> {
  InternetNotifier()
      : super(
          const InternetState(
            bandwidthInfo: DummyData.internetBandwidthInfo,
            listRouter: DummyData.listRouterOpd,
            listFaq: DummyData.internetFaqList,
          ),
        );
}

final internetProvider =
    StateNotifierProvider<InternetNotifier, InternetState>((ref) {
  return InternetNotifier();
});
