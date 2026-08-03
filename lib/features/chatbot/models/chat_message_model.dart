enum ChatMessageSender { user, assistant }

class ChatMessageModel {
  final String id;
  final ChatMessageSender sender;
  final String text;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => sender == ChatMessageSender.user;
  bool get isAssistant => sender == ChatMessageSender.assistant;
}
