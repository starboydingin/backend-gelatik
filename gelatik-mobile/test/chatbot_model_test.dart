import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/features/chatbot/models/chat_message_model.dart';
import 'package:gelatik/features/chatbot/models/chatbot_request.dart';
import 'package:gelatik/features/chatbot/models/chatbot_response_model.dart';

void main() {
  group('Chatbot model contract', () {
    test('1. parse message lengkap', () {
      final message = ChatMessageModel.fromJson({
        'id': 12,
        'role': 'assistant',
        'content': 'Jawaban layanan TIK',
        'provider_used': 'gemini',
        'created_at': '2026-08-06T10:00:00.000Z',
      });
      expect(message.id, '12');
      expect(message.isAssistant, isTrue);
      expect(message.provider, 'gemini');
    });

    test('2. parse nullable/minimal dengan timestamp aman', () {
      final message = ChatMessageModel.fromJson({
        'id': '1',
        'role': 'user',
        'content': 'Halo',
      });
      expect(message.provider, isNull);
      expect(message.timestamp.millisecondsSinceEpoch, 0);
    });

    test('3. invalid required field ditolak', () {
      expect(
        () => ChatMessageModel.fromJson({'id': 1, 'role': 'user'}),
        throwsFormatException,
      );
      expect(
        () => ChatbotResponseModel.fromJson({
          'session_id': 'session-1',
          'reply': '',
        }),
        throwsFormatException,
      );
    });

    test('4. unknown sender/status tidak crash', () {
      final message = ChatMessageModel.fromJson({
        'id': 1,
        'role': 'tool',
        'content': 'Unknown role',
        'created_at': 'invalid',
      });
      expect(message.sender, ChatMessageSender.unknown);
      expect(message.status, ChatMessageStatus.sent);
    });

    test('5. timestamp ISO diparse', () {
      final message = ChatMessageModel.fromJson({
        'id': 1,
        'role': 'user',
        'content': 'Halo',
        'created_at': '2026-08-06T17:30:00+07:00',
      });
      expect(message.timestamp.toUtc().hour, 10);
    });

    test('6. request trim dan hanya memetakan field kontrak', () {
      final first = ChatbotMessageRequest(message: '  Halo  ');
      final continued = ChatbotMessageRequest(
        message: ' Lanjut ',
        sessionId: ' session-1 ',
      );
      expect(first.toJson(), {'message': 'Halo'});
      expect(continued.toJson(), {
        'message': 'Lanjut',
        'session_id': 'session-1',
      });
      expect(() => ChatbotMessageRequest(message: '   '), throwsArgumentError);
    });
  });
}
