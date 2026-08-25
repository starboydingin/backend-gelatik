import '../../auth/models/user_model.dart';
import '../../email/models/usulan_email_model.dart';
import '../../info_alat/models/master_item_model.dart';
import '../../konsultasi/models/konsultasi_model.dart';
import '../../peminjaman/models/pinjam_model.dart';
import '../repositories/announcement_repository.dart';
import '../../../core/models/paginated_result.dart';

class HomeDashboardModel {
  final String userName;
  final String userRole;
  final String? namaOpd;
  final int? availableItemCount;
  final int? totalBorrowingCount;
  final int? totalConsultationCount;
  final int? activeBorrowingCount;
  final int? activeConsultationCount;
  final int? emailRequestCount;
  final int? unreadNotificationCount;
  final List<PinjamModel> recentBorrowings;
  final List<KonsultasiModel> recentConsultations;
  final List<UsulanEmailModel> recentEmailRequests;
  final List<Announcement> announcements;
  final List<ServiceActivityPoint> serviceActivity;
  final List<ServiceUsageMetric> consultationTopics;
  final List<ServiceUsageMetric> assetUsage;
  final double serviceRatingAverage;
  final int serviceRatingCount;
  final Map<int, int> serviceRatingDistribution;

  const HomeDashboardModel({
    required this.userName,
    required this.userRole,
    this.namaOpd,
    this.availableItemCount,
    this.totalBorrowingCount,
    this.totalConsultationCount,
    this.activeBorrowingCount,
    this.activeConsultationCount,
    this.emailRequestCount,
    this.unreadNotificationCount,
    this.recentBorrowings = const [],
    this.recentConsultations = const [],
    this.recentEmailRequests = const [],
    this.announcements = const [],
    this.serviceActivity = const [],
    this.consultationTopics = const [],
    this.assetUsage = const [],
    this.serviceRatingAverage = 0,
    this.serviceRatingCount = 0,
    this.serviceRatingDistribution = const {},
  });

  bool get isAdmin {
    final role = userRole.toLowerCase();
    return role == 'admin' || role == 'superadmin';
  }

  bool get canAccessAdminPanel => isAdmin || userRole.toLowerCase() == 'bkd';

  bool get hasAnySectionData =>
      availableItemCount != null ||
      totalBorrowingCount != null ||
      totalConsultationCount != null ||
      activeBorrowingCount != null ||
      activeConsultationCount != null ||
      emailRequestCount != null ||
      unreadNotificationCount != null;

  bool get isEmpty =>
      hasAnySectionData &&
      (availableItemCount == null || availableItemCount == 0) &&
      (totalBorrowingCount == null || totalBorrowingCount == 0) &&
      (totalConsultationCount == null || totalConsultationCount == 0) &&
      (activeBorrowingCount == null || activeBorrowingCount == 0) &&
      (activeConsultationCount == null || activeConsultationCount == 0) &&
      (emailRequestCount == null || emailRequestCount == 0) &&
      recentBorrowings.isEmpty &&
      recentConsultations.isEmpty &&
      recentEmailRequests.isEmpty;

  factory HomeDashboardModel.fromSources({
    required UserModel? user,
    List<MasterItemModel>? items,
    PaginatedResult<PinjamModel>? borrowings,
    PaginatedResult<KonsultasiModel>? consultations,
    HomeDashboardModel? previous,
  }) {
    return HomeDashboardModel(
      userName: _display(user?.name) ?? 'Pengguna Gelatik',
      userRole: _display(user?.role) ?? 'unknown',
      namaOpd: _display(user?.namaOpd),
      availableItemCount: items == null
          ? previous?.availableItemCount
          : items.where((item) => item.stok > 0).length,
      totalBorrowingCount: borrowings?.total ?? previous?.totalBorrowingCount,
      totalConsultationCount:
          consultations?.total ?? previous?.totalConsultationCount,
      activeBorrowingCount: previous?.activeBorrowingCount,
      activeConsultationCount: previous?.activeConsultationCount,
      emailRequestCount: previous?.emailRequestCount,
      unreadNotificationCount: previous?.unreadNotificationCount,
      recentBorrowings: borrowings == null
          ? (previous?.recentBorrowings ?? const [])
          : borrowings.items.take(3).toList(growable: false),
      recentConsultations: consultations == null
          ? (previous?.recentConsultations ?? const [])
          : consultations.items.take(3).toList(growable: false),
      recentEmailRequests: previous?.recentEmailRequests ?? const [],
      announcements: previous?.announcements ?? const [],
      serviceActivity: previous?.serviceActivity ?? const [],
      consultationTopics: previous?.consultationTopics ?? const [],
      assetUsage: previous?.assetUsage ?? const [],
      serviceRatingAverage: previous?.serviceRatingAverage ?? 0,
      serviceRatingCount: previous?.serviceRatingCount ?? 0,
      serviceRatingDistribution:
          previous?.serviceRatingDistribution ?? const {},
    );
  }

  factory HomeDashboardModel.fromDashboardPayload({
    required UserModel? user,
    required Map<String, dynamic> payload,
    HomeDashboardModel? previous,
  }) {
    final summary = payload['summary'] is Map
        ? Map<String, dynamic>.from(payload['summary'] as Map)
        : const <String, dynamic>{};
    final recent = payload['recent'] is Map
        ? Map<String, dynamic>.from(payload['recent'] as Map)
        : const <String, dynamic>{};
    final rating = payload['service_rating_statistics'] is Map
        ? Map<String, dynamic>.from(payload['service_rating_statistics'] as Map)
        : const <String, dynamic>{};

    return HomeDashboardModel(
      userName:
          _display(user?.name) ?? previous?.userName ?? 'Pengguna Gelatik',
      userRole: _display(user?.role) ?? previous?.userRole ?? 'user',
      namaOpd: _display(user?.namaOpd) ?? previous?.namaOpd,
      availableItemCount: previous?.availableItemCount,
      totalBorrowingCount: previous?.totalBorrowingCount,
      totalConsultationCount: previous?.totalConsultationCount,
      activeBorrowingCount: _asInt(summary['peminjaman_aktif']),
      activeConsultationCount: _asInt(summary['konsultasi_aktif']),
      emailRequestCount: _asInt(summary['usulan_email']),
      unreadNotificationCount: _asInt(summary['notifikasi_belum_dibaca']),
      recentBorrowings: _pinjamList(recent['peminjaman']),
      recentConsultations: _konsultasiList(recent['konsultasi']),
      recentEmailRequests: _emailList(recent['usulan_email']),
      announcements: _announcementList(recent['pengumuman']),
      serviceActivity: _activityList(payload['service_activity_series']),
      consultationTopics: _usageList(payload['consultation_topics']),
      assetUsage: _usageList(payload['asset_usage']),
      serviceRatingAverage: _asDouble(rating['rata_rata']),
      serviceRatingCount: _asInt(rating['total_user']),
      serviceRatingDistribution: _ratingDistribution(rating['distribusi']),
    );
  }

  static String? _display(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static int _asInt(dynamic value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse('${value ?? ''}') ?? 0;

  static double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;

  static Map<int, int> _ratingDistribution(dynamic raw) {
    if (raw is! Map) return const {};
    return Map<int, int>.unmodifiable({
      for (var score = 1; score <= 5; score++)
        score: _asInt(raw[score] ?? raw[score.toString()]),
    });
  }

  static List<ServiceActivityPoint> _activityList(dynamic raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((entry) {
              final data = Map<String, dynamic>.from(entry);
              return ServiceActivityPoint(
                date: data['tanggal']?.toString() ?? '',
                borrowings: _asInt(data['peminjaman']),
                consultations: _asInt(data['konsultasi']),
                emailRequests: _asInt(data['usulan_email']),
              );
            })
            .toList(growable: false)
      : const [];

  static List<ServiceUsageMetric> _usageList(dynamic raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((entry) {
              final data = Map<String, dynamic>.from(entry);
              return ServiceUsageMetric(
                label:
                    data['label']?.toString() ??
                    data['nama_item']?.toString() ??
                    'Tanpa nama',
                total: _asInt(data['total'] ?? data['total_peminjaman']),
              );
            })
            .toList(growable: false)
      : const [];

  static List<Announcement> _announcementList(dynamic raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((entry) {
              return Announcement.fromJson(Map<String, dynamic>.from(entry));
            })
            .toList(growable: false)
      : const [];

  static List<PinjamModel> _pinjamList(dynamic raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((entry) {
              try {
                return PinjamModel.fromJson(Map<String, dynamic>.from(entry));
              } catch (_) {
                return null;
              }
            })
            .whereType<PinjamModel>()
            .toList(growable: false)
      : const [];

  static List<KonsultasiModel> _konsultasiList(dynamic raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((entry) {
              try {
                return KonsultasiModel.fromJson(
                  Map<String, dynamic>.from(entry),
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<KonsultasiModel>()
            .toList(growable: false)
      : const [];

  static List<UsulanEmailModel> _emailList(dynamic raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((entry) {
              try {
                return UsulanEmailModel.fromJson(
                  Map<String, dynamic>.from(entry),
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<UsulanEmailModel>()
            .toList(growable: false)
      : const [];
}

/// Anonymous cross-user activity delivered by the aggregate dashboard API.
class ServiceActivityPoint {
  final String date;
  final int borrowings;
  final int consultations;
  final int emailRequests;

  const ServiceActivityPoint({
    required this.date,
    required this.borrowings,
    required this.consultations,
    required this.emailRequests,
  });

  int get total => borrowings + consultations + emailRequests;
}

class ServiceUsageMetric {
  final String label;
  final int total;

  const ServiceUsageMetric({required this.label, required this.total});
}
