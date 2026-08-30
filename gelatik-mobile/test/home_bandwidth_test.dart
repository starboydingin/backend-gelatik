import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/home/models/home_dashboard_model.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';
import 'package:gelatik/features/home/repositories/announcement_repository.dart';
import 'package:gelatik/features/internet/repositories/internet_repository.dart';

class _AvailableBandwidthRepository extends InternetRepository {
  _AvailableBandwidthRepository()
    : super(apiClient: ApiClient(secureStorageService: SecureStorageService()));

  @override
  Future<Map<String, dynamic>> getInternetOverview() async => {
    'bandwidth': {
      'available': true,
      'opd': 'Diskominfotik Lampung',
      'provider': 'Data Router OPD',
      'status': 'Tersedia',
      'download_mbps': 250,
      'upload_mbps': 100,
      'connection_name': 'Router Utama',
      'connection_count': 1,
    },
    'routers': const <Map<String, dynamic>>[],
  };
}

void main() {
  testWidgets('Home displays current user OPD bandwidth from the API source', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeAnnouncementsProvider.overrideWith((ref) async => const []),
          homeProvider.overrideWith(
            (ref) => HomeNotifier.preview(
              const HomeDashboardModel(
                userName: 'Pengguna Bandwidth',
                userRole: 'user',
                namaOpd: 'Diskominfotik Lampung',
              ),
            ),
          ),
          internetRepositoryProvider.overrideWithValue(
            _AvailableBandwidthRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Download 250 Mbps • Upload 100 Mbps'), findsOneWidget);
    expect(find.text('↓ 250 Mbps\n↑ 100 Mbps'), findsOneWidget);
    expect(find.textContaining('Router Utama'), findsOneWidget);
  });
}
