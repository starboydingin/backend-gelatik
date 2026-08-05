import '../../auth/models/user_model.dart';
import '../../info_alat/models/master_item_model.dart';
import '../../konsultasi/models/konsultasi_model.dart';
import '../../peminjaman/models/pinjam_model.dart';
import '../../../core/models/paginated_result.dart';

class HomeDashboardModel {
  final String userName;
  final String userRole;
  final String? namaOpd;
  final int? availableItemCount;
  final int? totalBorrowingCount;
  final int? totalConsultationCount;
  final List<PinjamModel> recentBorrowings;
  final List<KonsultasiModel> recentConsultations;

  const HomeDashboardModel({
    required this.userName,
    required this.userRole,
    this.namaOpd,
    this.availableItemCount,
    this.totalBorrowingCount,
    this.totalConsultationCount,
    this.recentBorrowings = const [],
    this.recentConsultations = const [],
  });

  bool get isAdmin {
    final role = userRole.toLowerCase();
    return role == 'admin' || role == 'superadmin';
  }

  bool get hasAnySectionData =>
      availableItemCount != null ||
      totalBorrowingCount != null ||
      totalConsultationCount != null;

  bool get isEmpty =>
      availableItemCount == 0 &&
      totalBorrowingCount == 0 &&
      totalConsultationCount == 0;

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
      recentBorrowings: borrowings == null
          ? (previous?.recentBorrowings ?? const [])
          : borrowings.items.take(3).toList(growable: false),
      recentConsultations: consultations == null
          ? (previous?.recentConsultations ?? const [])
          : consultations.items.take(3).toList(growable: false),
    );
  }

  static String? _display(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
