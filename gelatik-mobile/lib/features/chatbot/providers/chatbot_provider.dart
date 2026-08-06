import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../models/chat_message_model.dart';
import '../models/chatbot_request.dart';
import '../repositories/chatbot_repository.dart';

enum ChatbotPhase {
  initial,
  loadingHistory,
  ready,
  sending,
  success,
  partialError,
  error,
  refreshing,
}

class ChatbotState {
  final ChatbotPhase phase;
  final List<ChatMessageModel> messages;
  final String? sessionId;
  final String? errorMessage;
  final ChatbotErrorType? errorType;
  final bool sendInFlight;

  const ChatbotState({
    this.phase = ChatbotPhase.initial,
    this.messages = const [],
    this.sessionId,
    this.errorMessage,
    this.errorType,
    this.sendInFlight = false,
  });

  bool get isTyping => sendInFlight;
  bool get isLoadingHistory => phase == ChatbotPhase.loadingHistory;
  bool get isRefreshing => phase == ChatbotPhase.refreshing;
  bool get isUnauthorized => errorType == ChatbotErrorType.unauthorized;

  ChatbotState copyWith({
    ChatbotPhase? phase,
    List<ChatMessageModel>? messages,
    String? sessionId,
    bool clearSession = false,
    String? errorMessage,
    ChatbotErrorType? errorType,
    bool? sendInFlight,
    bool clearError = false,
  }) {
    return ChatbotState(
      phase: phase ?? this.phase,
      messages: messages ?? this.messages,
      sessionId: clearSession ? null : sessionId ?? this.sessionId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      errorType: clearError ? null : errorType ?? this.errorType,
      sendInFlight: sendInFlight ?? this.sendInFlight,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  final ChatbotRepository repository;
  final SecureStorageService storage;
  int _generation = 0;
  int _localId = 0;

  ChatbotNotifier({
    required this.repository,
    required this.storage,
    bool autoLoad = true,
  }) : super(const ChatbotState()) {
    if (autoLoad) unawaited(loadHistory());
  }

  Future<void> loadHistory({bool refresh = false}) async {
    final generation = ++_generation;
    state = state.copyWith(
      phase: refresh ? ChatbotPhase.refreshing : ChatbotPhase.loadingHistory,
      clearError: true,
    );
    try {
      final sessionId = state.sessionId ?? await storage.getChatbotSessionId();
      if (generation != _generation) return;
      if (sessionId == null || sessionId.trim().isEmpty) {
        state = state.copyWith(
          phase: ChatbotPhase.ready,
          messages: const [],
          clearSession: true,
        );
        return;
      }
      final messages = await repository.getHistory(sessionId);
      if (generation != _generation) return;
      if (messages.isEmpty) {
        await storage.deleteChatbotSessionId();
        if (generation != _generation) return;
        state = state.copyWith(
          phase: ChatbotPhase.ready,
          messages: const [],
          clearSession: true,
          clearError: true,
        );
        return;
      }
      state = state.copyWith(
        phase: ChatbotPhase.ready,
        messages: messages,
        sessionId: sessionId,
        clearError: true,
      );
    } on ChatbotRepositoryException catch (error) {
      if (generation != _generation) return;
      await _handleFailure(error, fullErrorWhenEmpty: true);
    }
  }

  Future<void> refreshHistory() => loadHistory(refresh: true);

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || state.sendInFlight) return;

    final id = 'local_${DateTime.now().microsecondsSinceEpoch}_${_localId++}';
    final userMessage = ChatMessageModel(
      id: id,
      sender: ChatMessageSender.user,
      text: query,
      timestamp: DateTime.now(),
      status: ChatMessageStatus.pending,
    );
    state = state.copyWith(
      phase: ChatbotPhase.sending,
      messages: [...state.messages, userMessage],
      sendInFlight: true,
      clearError: true,
    );
    await _performSend(id, query);
  }

  Future<void> retryMessage(String messageId) async {
    if (state.sendInFlight) return;
    final index = state.messages.indexWhere(
      (message) =>
          message.id == messageId &&
          message.isUser &&
          message.status == ChatMessageStatus.failed,
    );
    if (index < 0) return;
    final messages = [...state.messages];
    final failed = messages[index];
    messages[index] = failed.copyWith(status: ChatMessageStatus.pending);
    state = state.copyWith(
      phase: ChatbotPhase.sending,
      messages: messages,
      sendInFlight: true,
      clearError: true,
    );
    await _performSend(failed.id, failed.text);
  }

  Future<void> _performSend(String messageId, String text) async {
    final generation = _generation;
    try {
      final response = await repository.sendMessage(
        ChatbotMessageRequest(message: text, sessionId: state.sessionId),
      );
      if (generation != _generation) {
        state = state.copyWith(sendInFlight: false);
        return;
      }
      await storage.saveChatbotSessionId(response.sessionId);
      if (generation != _generation) {
        state = state.copyWith(sendInFlight: false);
        return;
      }

      final messages =
          state.messages
              .map(
                (message) => message.id == messageId
                    ? message.copyWith(status: ChatMessageStatus.sent)
                    : message,
              )
              .toList(growable: true)
            ..add(
              ChatMessageModel(
                id: 'assistant_${DateTime.now().microsecondsSinceEpoch}',
                sender: ChatMessageSender.assistant,
                text: response.reply,
                timestamp: DateTime.now(),
                provider: response.provider,
              ),
            );
      state = state.copyWith(
        phase: ChatbotPhase.success,
        messages: messages,
        sessionId: response.sessionId,
        sendInFlight: false,
        clearError: true,
      );
    } on ChatbotRepositoryException catch (error) {
      if (generation != _generation) {
        state = state.copyWith(sendInFlight: false);
        return;
      }
      final messages = state.messages
          .map(
            (message) => message.id == messageId
                ? message.copyWith(status: ChatMessageStatus.failed)
                : message,
          )
          .toList(growable: false);
      state = state.copyWith(messages: messages, sendInFlight: false);
      await _handleFailure(error);
    }
  }

  Future<void> deleteHistory() async {
    if (state.sendInFlight) return;
    final sessionId = state.sessionId;
    final generation = ++_generation;
    if (sessionId == null) {
      await storage.deleteChatbotSessionId();
      if (generation == _generation) {
        state = const ChatbotState(phase: ChatbotPhase.ready);
      }
      return;
    }
    state = state.copyWith(phase: ChatbotPhase.refreshing, clearError: true);
    try {
      await repository.deleteHistory(sessionId);
      await storage.deleteChatbotSessionId();
      if (generation != _generation) return;
      state = const ChatbotState(phase: ChatbotPhase.ready);
    } on ChatbotRepositoryException catch (error) {
      if (generation != _generation) return;
      await _handleFailure(error);
    }
  }

  Future<void> _handleFailure(
    ChatbotRepositoryException error, {
    bool fullErrorWhenEmpty = false,
  }) async {
    if (error.type == ChatbotErrorType.unauthorized ||
        error.type == ChatbotErrorType.notFound) {
      await storage.deleteChatbotSessionId();
    }
    state = state.copyWith(
      phase: fullErrorWhenEmpty && state.messages.isEmpty
          ? ChatbotPhase.error
          : ChatbotPhase.partialError,
      errorMessage: error.message,
      errorType: error.type,
      clearSession: error.type == ChatbotErrorType.notFound,
    );
  }
}

final chatbotProvider =
    StateNotifierProvider.autoDispose<ChatbotNotifier, ChatbotState>((ref) {
      return ChatbotNotifier(
        repository: ref.watch(chatbotRepositoryProvider),
        storage: ref.watch(secureStorageServiceProvider),
      );
    });
