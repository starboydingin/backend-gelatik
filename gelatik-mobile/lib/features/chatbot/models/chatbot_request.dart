class ChatbotMessageRequest {
  final String message;
  final String? sessionId;

  ChatbotMessageRequest({required String message, String? sessionId})
    : message = message.trim(),
      sessionId = _normalizeSession(sessionId) {
    if (this.message.isEmpty) {
      throw ArgumentError.value(
        message,
        'message',
        'Pesan tidak boleh kosong.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    if (sessionId != null) 'session_id': sessionId,
  };

  static String? _normalizeSession(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
