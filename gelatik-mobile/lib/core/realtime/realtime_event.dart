class RealtimeEvent {
  static const supportedTypes = <String>{
    'pinjam.created',
    'pinjam.status_changed',
    'konsultasi.created',
    'konsultasi.responded',
    'konsultasi.status_changed',
    'usulan_email.status_changed',
  };

  final String eventId;
  final String type;
  final int entityId;
  final String? status;
  final String? oldStatus;
  final int? responseId;
  final DateTime createdAt;
  final String? message;

  const RealtimeEvent({
    required this.eventId,
    required this.type,
    required this.entityId,
    required this.createdAt,
    this.status,
    this.oldStatus,
    this.responseId,
    this.message,
  });

  static RealtimeEvent? tryParse(String eventName, dynamic raw) {
    if (!supportedTypes.contains(eventName) || raw is! Map) return null;
    late final Map<String, dynamic> json;
    try {
      json = Map<String, dynamic>.from(raw);
    } catch (_) {
      return null;
    }
    final eventId = json['event_id'];
    final type = json['type'];
    final entityId = _positiveInt(json['entity_id']);
    final createdAt = _date(json['created_at']);
    if (eventId is! String ||
        eventId.trim().isEmpty ||
        type != eventName ||
        entityId == null ||
        createdAt == null) {
      return null;
    }

    const requiresStatus = true;
    final status = _optionalText(json['status']);
    if (requiresStatus && status == null) return null;

    final responseId = eventName == 'konsultasi.responded'
        ? _positiveInt(json['response_id'])
        : null;
    if (eventName == 'konsultasi.responded' && responseId == null) return null;

    final oldStatus = _optionalText(json['old_status']);
    if (eventName.endsWith('status_changed') && oldStatus == null) return null;

    return RealtimeEvent(
      eventId: eventId,
      type: type,
      entityId: entityId,
      status: status,
      oldStatus: oldStatus,
      responseId: responseId,
      createdAt: createdAt,
      message: _optionalText(json['message']),
    );
  }

  static int? _positiveInt(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static String? _optionalText(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}
