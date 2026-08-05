/// WaSubscriptionModel — Data model subscription Notifikasi WhatsApp (F-WA)
class WaSubscriptionModel {
  final int userId;
  final String waNumber;
  final bool isSubscribed;
  final DateTime? subscribedAt;

  const WaSubscriptionModel({
    required this.userId,
    required this.waNumber,
    required this.isSubscribed,
    this.subscribedAt,
  });

  WaSubscriptionModel copyWith({
    int? userId,
    String? waNumber,
    bool? isSubscribed,
    DateTime? subscribedAt,
  }) {
    return WaSubscriptionModel(
      userId: userId ?? this.userId,
      waNumber: waNumber ?? this.waNumber,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscribedAt: subscribedAt ?? this.subscribedAt,
    );
  }

  factory WaSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return WaSubscriptionModel(
      userId: json['user_id'] as int? ?? 0,
      waNumber: json['wa_number'] as String? ?? '',
      isSubscribed: json['is_subscribed'] as bool? ?? false,
      subscribedAt: json['subscribed_at'] != null
          ? DateTime.parse(json['subscribed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'wa_number': waNumber,
      'is_subscribed': isSubscribed,
      'subscribed_at': subscribedAt?.toIso8601String(),
    };
  }
}
