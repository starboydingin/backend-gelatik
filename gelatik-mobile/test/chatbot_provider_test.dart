import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/chatbot/models/chat_message_model.dart';
import 'package:gelatik/features/chatbot/models/chatbot_request.dart';
import 'package:gelatik/features/chatbot/models/chatbot_response_model.dart';
import 'package:gelatik/features/chatbot/providers/chatbot_provider.dart';
import 'package:gelatik/features/chatbot/repositories/chatbot_repository.dart';

class _MemoryStorage extends SecureStorageService {
  String? sessionId;

  @override
  Future<String?> getChatbotSessionId() async => sessionId;

  @override
  Future<void> saveChatbotSessionId(String value) async => sessionId = value;

  @override
  Future<void> deleteChatbotSessionId() async => sessionId = null;
}

class _FakeRepository extends ChatbotRepository {
  _FakeRepository()
    : super(
        apiClient: ApiClient(
          secureStorageService: _MemoryStorage(),
          dioOverride: Dio(),
        ),
      );

  List<ChatMessageModel> history = const [];
  ChatbotResponseModel response = const ChatbotResponseModel(
    sessionId: 'session-1',
    reply: 'Jawaban nyata',
    provider: 'gemini',
  );
  ChatbotRepositoryException? historyError;
  ChatbotRepositoryException? sendError;
  Completer<ChatbotResponseModel>? sendCompleter;
  int sendCalls = 0;
  int deleteCalls = 0;
  String? latestSessionId;

  @override
  Future<String?> getLatestSessionId() async => latestSessionId;

  @override
  Future<ChatbotConversationSnapshot?> getLatestConversation() async {
    if (historyError != null) throw historyError!;
    final sessionId =
        latestSessionId ?? (history.isNotEmpty ? 'session-1' : null);
    return sessionId == null
        ? null
        : ChatbotConversationSnapshot(sessionId: sessionId, messages: history);
  }

  @override
  Future<List<ChatMessageModel>> getHistory(String sessionId) async {
    if (historyError != null) throw historyError!;
    return history;
  }

  @override
  Future<ChatbotResponseModel> sendMessage(
    ChatbotMessageRequest request,
  ) async {
    sendCalls++;
    if (sendError != null) throw sendError!;
    if (sendCompleter != null) return sendCompleter!.future;
    return response;
  }

  @override
  Future<void> deleteHistory(String sessionId) async {
    deleteCalls++;
  }
}

ChatMessageModel _message(String id, ChatMessageSender sender, String text) =>
    ChatMessageModel(
      id: id,
      sender: sender,
      text: text,
      timestamp: DateTime(2026, 8, 6),
    );

ChatbotRepositoryException _error(ChatbotErrorType type) =>
    ChatbotRepositoryException(message: 'Gagal Chatbot', type: type);

void main() {
  group('Chatbot provider lifecycle', () {
    test('19. load history success', () async {
      final storage = _MemoryStorage()..sessionId = 'session-1';
      final repository = _FakeRepository()
        ..history = [_message('1', ChatMessageSender.user, 'Halo')];
      final notifier = ChatbotNotifier(
        repository: repository,
        storage: storage,
        autoLoad: false,
      );
      await notifier.loadHistory();
      expect(notifier.state.phase, ChatbotPhase.ready);
      expect(notifier.state.messages.single.text, 'Halo');
    });

    test('20. session kosong menghasilkan empty ready', () async {
      final notifier = ChatbotNotifier(
        repository: _FakeRepository(),
        storage: _MemoryStorage(),
        autoLoad: false,
      );
      await notifier.loadHistory();
      expect(notifier.state.messages, isEmpty);
      expect(notifier.state.phase, ChatbotPhase.ready);
    });

    test('21. load full error', () async {
      final storage = _MemoryStorage()..sessionId = 'session-1';
      final repository = _FakeRepository()
        ..historyError = _error(ChatbotErrorType.network);
      final notifier = ChatbotNotifier(
        repository: repository,
        storage: storage,
        autoLoad: false,
      );
      await notifier.loadHistory();
      expect(notifier.state.phase, ChatbotPhase.error);
      expect(notifier.state.errorType, ChatbotErrorType.network);
    });

    test('22. send success menyimpan session dan urutan', () async {
      final storage = _MemoryStorage();
      final notifier = ChatbotNotifier(
        repository: _FakeRepository(),
        storage: storage,
        autoLoad: false,
      );
      await notifier.sendMessage(' Halo ');
      expect(notifier.state.messages.map((item) => item.sender), [
        ChatMessageSender.user,
        ChatMessageSender.assistant,
      ]);
      expect(notifier.state.messages.first.status, ChatMessageStatus.sent);
      expect(storage.sessionId, 'session-1');
    });

    test(
      '23. send failure menandai pesan failed dan history tetap terbaca',
      () async {
        final repository = _FakeRepository()
          ..sendError = _error(ChatbotErrorType.upstream);
        final notifier = ChatbotNotifier(
          repository: repository,
          storage: _MemoryStorage(),
          autoLoad: false,
        );
        await notifier.sendMessage('Halo');
        expect(notifier.state.messages.single.status, ChatMessageStatus.failed);
        expect(notifier.state.phase, ChatbotPhase.partialError);
      },
    );

    test('24. retry tidak menggandakan pesan user', () async {
      final repository = _FakeRepository()
        ..sendError = _error(ChatbotErrorType.network);
      final notifier = ChatbotNotifier(
        repository: repository,
        storage: _MemoryStorage(),
        autoLoad: false,
      );
      await notifier.sendMessage('Halo');
      final failedId = notifier.state.messages.single.id;
      repository.sendError = null;
      await notifier.retryMessage(failedId);
      expect(
        notifier.state.messages.where((item) => item.isUser),
        hasLength(1),
      );
      expect(notifier.state.messages, hasLength(2));
    });

    test('25. duplicate submit dicegah saat request aktif', () async {
      final completer = Completer<ChatbotResponseModel>();
      final repository = _FakeRepository()..sendCompleter = completer;
      final notifier = ChatbotNotifier(
        repository: repository,
        storage: _MemoryStorage(),
        autoLoad: false,
      );
      final first = notifier.sendMessage('Pertama');
      await notifier.sendMessage('Kedua');
      expect(repository.sendCalls, 1);
      expect(notifier.state.messages, hasLength(1));
      completer.complete(repository.response);
      await first;
    });

    test('event realtime saat mengirim tidak membuang response REST', () async {
      final completer = Completer<ChatbotResponseModel>();
      final repository = _FakeRepository()..sendCompleter = completer;
      final notifier = ChatbotNotifier(
        repository: repository,
        storage: _MemoryStorage(),
        autoLoad: false,
      );
      final send = notifier.sendMessage('Halo');
      await notifier.syncFromRealtime('session-1');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      completer.complete(repository.response);
      await send;
      expect(
        notifier.state.messages.where((item) => item.isAssistant),
        hasLength(1),
      );
      notifier.dispose();
    });

    test(
      '26. stale response tidak masuk setelah generation berganti',
      () async {
        final completer = Completer<ChatbotResponseModel>();
        final repository = _FakeRepository()..sendCompleter = completer;
        final notifier = ChatbotNotifier(
          repository: repository,
          storage: _MemoryStorage(),
          autoLoad: false,
        );
        final send = notifier.sendMessage('Pesan lama');
        await notifier.loadHistory(refresh: true);
        await notifier.sendMessage('Pesan duplikat setelah refresh');
        expect(repository.sendCalls, 1);
        completer.complete(repository.response);
        await send;
        expect(notifier.state.isTyping, isFalse);
        expect(
          notifier.state.messages.where((item) => item.isAssistant),
          isEmpty,
        );
      },
    );

    test('27. ordering history dipertahankan saat pesan baru masuk', () async {
      final storage = _MemoryStorage()..sessionId = 'session-1';
      final repository = _FakeRepository()
        ..history = [
          _message('1', ChatMessageSender.user, 'Satu'),
          _message('2', ChatMessageSender.assistant, 'Dua'),
        ];
      final notifier = ChatbotNotifier(
        repository: repository,
        storage: storage,
        autoLoad: false,
      );
      await notifier.loadHistory();
      await notifier.sendMessage('Tiga');
      expect(notifier.state.messages.map((item) => item.text), [
        'Satu',
        'Dua',
        'Tiga',
        'Jawaban nyata',
      ]);
    });

    test('28. unauthorized membersihkan session aman', () async {
      final storage = _MemoryStorage()..sessionId = 'session-1';
      final repository = _FakeRepository()
        ..historyError = _error(ChatbotErrorType.unauthorized);
      final notifier = ChatbotNotifier(
        repository: repository,
        storage: storage,
        autoLoad: false,
      );
      await notifier.loadHistory();
      expect(notifier.state.isUnauthorized, isTrue);
      expect(storage.sessionId, isNull);
    });

    test(
      'refresh memakai loading non-blocking dan delete membersihkan state',
      () async {
        final storage = _MemoryStorage()..sessionId = 'session-1';
        final repository = _FakeRepository()
          ..history = [_message('1', ChatMessageSender.user, 'Halo')];
        final notifier = ChatbotNotifier(
          repository: repository,
          storage: storage,
          autoLoad: false,
        );
        await notifier.loadHistory();
        await notifier.deleteHistory();
        expect(repository.deleteCalls, 1);
        expect(storage.sessionId, isNull);
        expect(notifier.state.messages, isEmpty);
      },
    );

    test(
      'hapus realtime dari perangkat lain langsung membersihkan state',
      () async {
        final storage = _MemoryStorage()..sessionId = 'session-1';
        final repository = _FakeRepository()
          ..history = [_message('1', ChatMessageSender.user, 'Halo')];
        final notifier = ChatbotNotifier(
          repository: repository,
          storage: storage,
          autoLoad: false,
        );
        await notifier.loadHistory();
        await notifier.syncFromRealtime(
          'session-perangkat-lain',
          deleted: true,
        );
        expect(notifier.state.messages, isEmpty);
        expect(notifier.state.sessionId, isNull);
        expect(storage.sessionId, isNull);
      },
    );

    test(
      'pesan realtime dari perangkat lain mengambil snapshot terbaru',
      () async {
        final repository = _FakeRepository()
          ..history = [_message('1', ChatMessageSender.user, 'Dari website')];
        final notifier = ChatbotNotifier(
          repository: repository,
          storage: _MemoryStorage(),
          autoLoad: false,
        );
        await notifier.loadHistory();
        repository.history = [
          ...repository.history,
          _message('2', ChatMessageSender.assistant, 'Jawaban terbaru'),
        ];
        await notifier.syncFromRealtime('session-1');
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(notifier.state.messages.map((item) => item.text), [
          'Dari website',
          'Jawaban terbaru',
        ]);
        notifier.dispose();
      },
    );
  });
}
