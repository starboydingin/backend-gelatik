class GelatikNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final String? resourceType;
  final int? resourceId;

  const GelatikNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.createdAt,
    this.resourceType,
    this.resourceId,
  });

  factory GelatikNotification.fromJson(Map<String, dynamic> json) {
    final read = json['read'];
    final rawType =
        '${json['resource_type'] ?? json['type'] ?? json['jenis'] ?? 'informasi'}'
            .toLowerCase();
    final rawContent =
        '${json['judul'] ?? ''} ${json['message'] ?? ''}'.toLowerCase();
    String? resolvedResourceType = json['resource_type']?.toString();
    if (resolvedResourceType == null || resolvedResourceType.isEmpty) {
      if (rawType.contains('konsul') || rawContent.contains('konsultasi')) {
        resolvedResourceType = 'konsultasi';
      } else if (rawType.contains('pinjam') ||
          rawContent.contains('peminjaman')) {
        resolvedResourceType = 'peminjaman';
      } else if (rawType.contains('email') ||
          rawContent.contains('usulan email')) {
        resolvedResourceType = 'usulan_email';
      } else if (rawType.contains('kritik') ||
          rawType.contains('saran') ||
          rawContent.contains('feedback')) {
        resolvedResourceType = 'kritik_saran';
      }
    }
    final rawId =
        json['resource_id'] ?? json['item_id'] ?? json['reference_id'];
    final resolvedResourceId = int.tryParse('$rawId');

    return GelatikNotification(
      id: int.tryParse('${json['id']}') ?? 0,
      title: '${json['judul'] ?? 'Informasi layanan'}',
      message: '${json['message'] ?? ''}',
      type: '${json['type'] ?? 'informasi'}',
      isRead:
          read == true || read == 1 || read == '1' || json['read_at'] != null,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      resourceType: resolvedResourceType,
      resourceId: resolvedResourceId,
    );
  }

  GelatikNotification copyWith({bool? isRead}) => GelatikNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    resourceType: resourceType,
    resourceId: resourceId,
  );
}
