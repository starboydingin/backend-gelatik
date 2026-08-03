import '../../info_alat/models/master_item_model.dart';

/// PinjamItemModel — Detail aset yang dipinjam dalam satu pengajuan peminjaman
class PinjamItemModel {
  final int id;
  final int pinjamId;
  final int itemId;
  final int quantity;
  final MasterItemModel? item; // Nested relation for UI

  const PinjamItemModel({
    required this.id,
    required this.pinjamId,
    required this.itemId,
    required this.quantity,
    this.item,
  });

  factory PinjamItemModel.fromJson(Map<String, dynamic> json) {
    return PinjamItemModel(
      id: json['id'] as int? ?? 0,
      pinjamId: (json['pinjam_id'] ?? json['pinjamId']) as int? ?? 0,
      itemId: (json['item_id'] ?? json['itemId']) as int? ?? 0,
      quantity: (json['quantity'] ?? json['jumlah']) as int? ?? 1,
      item: json['item'] != null
          ? MasterItemModel.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pinjam_id': pinjamId,
      'item_id': itemId,
      'quantity': quantity,
      'item': item?.toJson(),
    };
  }
}
