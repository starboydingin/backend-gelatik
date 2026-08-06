class ChatbotResponseModel {
  final String sessionId;
  final String reply;
  final String? provider;

  const ChatbotResponseModel({
    required this.sessionId,
    required this.reply,
    this.provider,
  });

  factory ChatbotResponseModel.fromJson(Map<String, dynamic> json) {
    final sessionId = json['session_id']?.toString().trim() ?? '';
    final reply = json['reply']?.toString().trim() ?? '';
    if (sessionId.isEmpty || reply.isEmpty) {
      throw const FormatException('Jawaban Chatbot tidak lengkap.');
    }
    final rawProvider = json['provider']?.toString().trim();
    return ChatbotResponseModel(
      sessionId: sessionId,
      reply: reply,
      provider: rawProvider == null || rawProvider.isEmpty ? null : rawProvider,
    );
  }
}
