import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/chatbot/models/chat_message_model.dart';
import 'package:gelatik/features/chatbot/models/chatbot_request.dart';
import 'package:gelatik/features/chatbot/models/chatbot_response_model.dart';
import 'package:gelatik/features/chatbot/presentation/screens/chatbot_native_screen.dart';
import 'package:gelatik/features/chatbot/repositories/chatbot_repository.dart';
import 'package:gelatik/features/home/models/home_dashboard_model.dart';
import 'package:gelatik/features/home/presentation/screens/home_screen.dart';
import 'package:gelatik/features/home/providers/home_provider.dart';

class _MemoryStorage extends SecureStorageService {
  String? sessionId;

  @override
  Future<String?> getChatbotSessionId() async => sessionId;

  @override
  Future<void> saveChatbotSessionId(String value) async => sessionId = value;

  @override
  Future<void> deleteChatbotSessionId() async => sessionId = null;
}

class _WidgetRepository extends ChatbotRepository {
  _WidgetRepository()
    : super(
        apiClient: ApiClient(
          secureStorageService: _MemoryStorage(),
          dioOverride: Dio(),
        ),
      );

  List<ChatMessageModel> history = const [];
  Object? historyError;
  Object? sendError;
  Completer<ChatbotResponseModel>? sendCompleter;
  int deleteCalls = 0;

  @override
  Future<List<ChatMessageModel>> getHistory(String sessionId) async {
    if (historyError != null) throw historyError!;
    return history;
  }

  @override
  Future<ChatbotResponseModel> sendMessage(
    ChatbotMessageRequest request,
  ) async {
    if (sendError != null) throw sendError!;
    if (sendCompleter != null) return sendCompleter!.future;
    return const ChatbotResponseModel(
      sessionId: 'session-1',
      reply: 'Jawaban dari backend',
      provider: 'gemini',
    );
  }

  @override
  Future<void> deleteHistory(String sessionId) async {
    deleteCalls++;
  }
}

ChatMessageModel _historyMessage(String id, String text) => ChatMessageModel(
  id: id,
  sender: ChatMessageSender.assistant,
  text: text,
  timestamp: DateTime(2026, 8, 6, 10),
);

ChatbotRepositoryException _error(ChatbotErrorType type, String message) =>
    ChatbotRepositoryException(message: message, type: type);

Future<void> _pumpChat(
  WidgetTester tester,
  _WidgetRepository repository,
  _MemoryStorage storage,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatbotRepositoryProvider.overrideWithValue(repository),
        secureStorageServiceProvider.overrideWithValue(storage),
      ],
      child: const MaterialApp(home: ChatbotNativeScreen()),
    ),
  );
}

void main() {
  group('Chatbot native UI', () {
    testWidgets('29. loading history terlihat', (tester) async {
      final storage = _MemoryStorage()..sessionId = 'session-1';
      final completer = Completer<List<ChatMessageModel>>();
      final blocking = _BlockingHistoryRepository(completer);
      await _pumpChat(tester, blocking, storage);
      await tester.pump();
      expect(find.byKey(const Key('chatbot-loading')), findsOneWidget);
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('30. empty conversation terlihat', (tester) async {
      await _pumpChat(tester, _WidgetRepository(), _MemoryStorage());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chatbot-empty')), findsOneWidget);
      expect(find.byKey(const Key('chatbot-welcome')), findsOneWidget);
      expect(find.text('Pertanyaan cepat'), findsOneWidget);
      expect(find.byKey(const Key('chatbot-quick-0')), findsOneWidget);
      expect(find.byKey(const Key('chatbot-quick-4')), findsOneWidget);
    });

    testWidgets('30a. pertanyaan cepat mengirim pertanyaan ke chatbot', (
      tester,
    ) async {
      await _pumpChat(tester, _WidgetRepository(), _MemoryStorage());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chatbot-quick-0')));
      await tester.pumpAndSettle();
      expect(
        find.text('Bagaimana cara mengajukan peminjaman aset TIK?'),
        findsOneWidget,
      );
      expect(find.text('Jawaban dari backend'), findsOneWidget);
      expect(find.byKey(const Key('chatbot-welcome')), findsNothing);
      expect(find.byKey(const Key('chatbot-quick-0')), findsNothing);
    });

    testWidgets('31. history success dirender', (tester) async {
      final storage = _MemoryStorage()..sessionId = 'session-1';
      final repository = _WidgetRepository()
        ..history = [_historyMessage('1', 'History backend')];
      await _pumpChat(tester, repository, storage);
      await tester.pumpAndSettle();
      expect(find.text('History backend'), findsOneWidget);
      expect(find.byKey(const Key('chatbot-welcome')), findsOneWidget);
      expect(find.byKey(const Key('chatbot-quick-0')), findsOneWidget);
    });

    testWidgets('32. sending indicator dan duplicate tap terkunci', (
      tester,
    ) async {
      final completer = Completer<ChatbotResponseModel>();
      final repository = _WidgetRepository()..sendCompleter = completer;
      await _pumpChat(tester, repository, _MemoryStorage());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('chatbot-input')),
        'Tanya TIK',
      );
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('chatbot-send')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('chatbot-send')));
      await tester.pump();
      expect(find.byKey(const Key('chatbot-typing')), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('chatbot-send')))
            .onPressed,
        isNull,
      );
      completer.complete(
        const ChatbotResponseModel(sessionId: 'session-1', reply: 'Selesai'),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('33. send success menampilkan user dan assistant', (
      tester,
    ) async {
      await _pumpChat(tester, _WidgetRepository(), _MemoryStorage());
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('chatbot-input')), 'Halo');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatbot-send')));
      await tester.pumpAndSettle();
      expect(find.text('Halo'), findsOneWidget);
      expect(find.text('Jawaban dari backend'), findsOneWidget);
    });

    testWidgets('34. send failure menampilkan retry dan retry berhasil', (
      tester,
    ) async {
      final repository = _WidgetRepository()
        ..sendError = _error(ChatbotErrorType.network, 'Jaringan terputus');
      await _pumpChat(tester, repository, _MemoryStorage());
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('chatbot-input')), 'Halo');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatbot-send')));
      await tester.pumpAndSettle();
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Jaringan terputus'), findsOneWidget);
      repository.sendError = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Jawaban dari backend'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
    });

    testWidgets('35. rate limit message ramah tampil', (tester) async {
      final repository = _WidgetRepository()
        ..sendError = _error(
          ChatbotErrorType.rateLimit,
          'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
        );
      await _pumpChat(tester, repository, _MemoryStorage());
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('chatbot-input')), 'Halo');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatbot-send')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Terlalu banyak permintaan'), findsOneWidget);
    });

    testWidgets('36. input kosong membuat send disabled', (tester) async {
      await _pumpChat(tester, _WidgetRepository(), _MemoryStorage());
      await tester.pumpAndSettle();
      final button = tester.widget<IconButton>(
        find.byKey(const Key('chatbot-send')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
      '37. keyboard submit, scroll, dan text scaling tidak overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _pumpChat(tester, _WidgetRepository(), _MemoryStorage());
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('chatbot-input')),
          'Pesan melalui keyboard',
        );
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();
        expect(find.text('Pesan melalui keyboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('38. unauthorized menawarkan masuk ulang', (tester) async {
      final storage = _MemoryStorage()..sessionId = 'session-1';
      final repository = _WidgetRepository()
        ..historyError = _error(
          ChatbotErrorType.unauthorized,
          'Sesi Anda telah berakhir. Silakan login kembali.',
        );
      await _pumpChat(tester, repository, storage);
      await tester.pumpAndSettle();
      expect(find.text('Masuk ulang'), findsOneWidget);
      expect(find.byKey(const Key('chatbot-error-banner')), findsOneWidget);
    });

    test(
      '39. source production Chatbot bebas DummyData dan fake response',
      () async {
        final files = await Directory('lib/features/chatbot')
            .list(recursive: true)
            .where((entry) => entry is File && entry.path.endsWith('.dart'))
            .cast<File>()
            .toList();
        final source = (await Future.wait(
          files.map((file) => file.readAsString()),
        )).join('\n');
        expect(source, isNot(contains('DummyData')));
        expect(source, isNot(contains('_generateDummyResponse')));
        expect(source, isNot(contains('dart:math')));
      },
    );

    testWidgets('hapus history memanggil API lalu menampilkan empty state', (
      tester,
    ) async {
      final storage = _MemoryStorage()..sessionId = 'session-1';
      final repository = _WidgetRepository()
        ..history = [_historyMessage('1', 'Akan dihapus')];
      await _pumpChat(tester, repository, storage);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chatbot-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();
      expect(repository.deleteCalls, 1);
      expect(find.byKey(const Key('chatbot-empty')), findsOneWidget);
    });

    testWidgets('Home tile membuka Chatbot Native', (tester) async {
      final repository = _WidgetRepository();
      final storage = _MemoryStorage();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotRepositoryProvider.overrideWithValue(repository),
            secureStorageServiceProvider.overrideWithValue(storage),
            homeProvider.overrideWith(
              (ref) => HomeNotifier.preview(
                const HomeDashboardModel(
                  userName: 'Test User',
                  userRole: 'user',
                  availableItemCount: 0,
                  totalBorrowingCount: 0,
                  totalConsultationCount: 0,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('home-scroll')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Asisten Gelatik'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asisten Gelatik'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatbotNativeScreen), findsOneWidget);
    });
  });
}

class _BlockingHistoryRepository extends _WidgetRepository {
  final Completer<List<ChatMessageModel>> completer;

  _BlockingHistoryRepository(this.completer);

  @override
  Future<List<ChatMessageModel>> getHistory(String sessionId) =>
      completer.future;
}
