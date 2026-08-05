import '../../info_alat/models/master_item_model.dart';

/// Rincian aset pada relasi `pinjam_items` dari backend.
class PinjamItemModel {
  final int id;
  final int pinjamId;
  final int itemId;
  final int quantity;
  final MasterItemModel? item;

  const PinjamItemModel({
    required this.id,
    required this.pinjamId,
    required this.itemId,
    required this.quantity,
    this.item,
  });

  factory PinjamItemModel.fromJson(Map<String, dynamic> json) {
    final relation = json['master_item'] ?? json['item'];
    if (relation != null && relation is! Map) {
      throw const FormatException(
        'Relasi master_item peminjaman harus berupa object atau null.',
      );
    }

    return PinjamItemModel(
      id: _requiredInt(json, 'id'),
      pinjamId: _requiredInt(json, 'pinjam_id'),
      itemId: _requiredInt(json, 'item_id'),
      quantity: _requiredInt(json, 'quantity'),
      item: relation == null
          ? null
          : MasterItemModel.fromJson(Map<String, dynamic>.from(relation)),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pinjam_id': pinjamId,
    'item_id': itemId,
    'quantity': quantity,
    'master_item': item?.toJson(),
  };

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Field "$key" wajib berupa angka bulat.');
  }
}
