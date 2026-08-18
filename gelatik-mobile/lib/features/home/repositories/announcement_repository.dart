import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class Announcement {
  final String title;
  final String content;
  const Announcement({required this.title, required this.content});

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    title: '${json['judul'] ?? 'Pengumuman layanan'}',
    content: '${json['konten'] ?? json['deskripsi'] ?? ''}',
  );
}

class AnnouncementRepository {
  final ApiClient apiClient;
  AnnouncementRepository({required this.apiClient});

  Future<List<Announcement>> getActive({CancelToken? cancelToken}) async {
    try {
      final response = await apiClient.dio.get(
        '/pengumuman',
        cancelToken: cancelToken,
      );
      final root = response.data;
      final data = root is Map ? root['data'] : root;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map(
            (entry) => Announcement.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false);
    } on DioException {
      return const [];
    }
  }
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(apiClient: ref.watch(apiClientProvider));
});
final activeAnnouncementsProvider =
    FutureProvider.autoDispose<List<Announcement>>((ref) {
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);
      return ref
          .watch(announcementRepositoryProvider)
          .getActive(cancelToken: cancelToken);
    });
