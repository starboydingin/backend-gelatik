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
    return GelatikNotification(
      id: int.tryParse('${json['id']}') ?? 0,
      title: '${json['judul'] ?? 'Informasi layanan'}',
      message: '${json['message'] ?? ''}',
      type: '${json['type'] ?? 'informasi'}',
      isRead:
          read == true || read == 1 || read == '1' || json['read_at'] != null,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      resourceType: json['resource_type']?.toString(),
      resourceId: int.tryParse('${json['resource_id'] ?? ''}'),
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
