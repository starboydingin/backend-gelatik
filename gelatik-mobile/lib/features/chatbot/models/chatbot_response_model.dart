class ChatbotResponseModel {
  final String sessionId;
  final String reply;
  final String? provider;
  final bool escalated;
  final int? consultationId;

  const ChatbotResponseModel({
    required this.sessionId,
    required this.reply,
    this.provider,
    this.escalated = false,
    this.consultationId,
  });

  factory ChatbotResponseModel.fromJson(Map<String, dynamic> json) {
    final sessionId = json['session_id']?.toString().trim() ?? '';
    final reply = json['reply']?.toString().trim() ?? '';
    if (sessionId.isEmpty || reply.isEmpty) {
      throw const FormatException('Jawaban Chatbot tidak lengkap.');
    }
    final rawProvider = json['provider']?.toString().trim();
    final consultationId = int.tryParse(
      '${json['konsultasi_id'] ?? json['consultation_id'] ?? ''}',
    );
    return ChatbotResponseModel(
      sessionId: sessionId,
      reply: reply,
      provider: rawProvider == null || rawProvider.isEmpty ? null : rawProvider,
      escalated: json['escalated'] == true,
      consultationId: consultationId != null && consultationId > 0
          ? consultationId
          : null,
    );
  }
}
