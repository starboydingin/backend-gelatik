enum ChatMessageSender { user, assistant, unknown }

enum ChatMessageStatus { pending, sent, failed, unknown }

class ChatMessageModel {
  final String id;
  final ChatMessageSender sender;
  final String text;
  final DateTime timestamp;
  final ChatMessageStatus status;
  final String? provider;

  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.status = ChatMessageStatus.sent,
    this.provider,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final content = json['content']?.toString().trim() ?? '';
    if (id.isEmpty || content.isEmpty) {
      throw const FormatException('Pesan Chatbot tidak lengkap.');
    }

    final rawTimestamp = json['created_at']?.toString();
    final timestamp = rawTimestamp == null
        ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        : DateTime.tryParse(rawTimestamp) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return ChatMessageModel(
      id: id,
      sender: switch (json['role']?.toString().toLowerCase()) {
        'user' => ChatMessageSender.user,
        'assistant' => ChatMessageSender.assistant,
        _ => ChatMessageSender.unknown,
      },
      text: content,
      timestamp: timestamp,
      status: ChatMessageStatus.sent,
      provider: _optionalString(json['provider_used']),
    );
  }

  bool get isUser => sender == ChatMessageSender.user;
  bool get isAssistant => sender == ChatMessageSender.assistant;

  ChatMessageModel copyWith({
    String? id,
    ChatMessageSender? sender,
    String? text,
    DateTime? timestamp,
    ChatMessageStatus? status,
    String? provider,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      provider: provider ?? this.provider,
    );
  }

  static String? _optionalString(dynamic value) {
    final parsed = value?.toString().trim();
    return parsed == null || parsed.isEmpty ? null : parsed;
  }
}
