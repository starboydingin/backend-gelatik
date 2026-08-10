import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/chat_message_model.dart';
import '../models/chatbot_request.dart';
import '../models/chatbot_response_model.dart';

enum ChatbotErrorType {
  network,
  timeout,
  invalidRequest,
  unauthorized,
  forbidden,
  notFound,
  validation,
  rateLimit,
  upstream,
  malformed,
  emptyResponse,
  unknown,
}

class ChatbotRepositoryException extends ApiException {
  final ChatbotErrorType type;

  ChatbotRepositoryException({
    required super.message,
    required this.type,
    super.statusCode,
    super.errors,
  });

  factory ChatbotRepositoryException.fromDioException(DioException error) {
    final base = ApiException.fromDioException(error);
    final status = error.response?.statusCode;
    final type = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ChatbotErrorType.timeout,
      DioExceptionType.connectionError => ChatbotErrorType.network,
      _ => switch (status) {
        400 => ChatbotErrorType.invalidRequest,
        401 => ChatbotErrorType.unauthorized,
        403 => ChatbotErrorType.forbidden,
        404 => ChatbotErrorType.notFound,
        422 => ChatbotErrorType.validation,
        429 => ChatbotErrorType.rateLimit,
        _ =>
          status != null && status >= 500
              ? ChatbotErrorType.upstream
              : ChatbotErrorType.unknown,
      },
    };

    final message = switch (type) {
      ChatbotErrorType.unauthorized =>
        'Sesi Anda telah berakhir. Silakan login kembali.',
      ChatbotErrorType.forbidden =>
        'Anda tidak memiliki izin untuk membuka percakapan ini.',
      ChatbotErrorType.notFound =>
        'Percakapan tidak ditemukan atau sudah dihapus.',
      ChatbotErrorType.timeout =>
        'Asisten Gelatik belum merespons. Silakan coba lagi.',
      ChatbotErrorType.rateLimit =>
        'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.',
      ChatbotErrorType.upstream =>
        'Asisten Gelatik sedang tidak tersedia. Silakan coba lagi.',
      _ => base.message,
    };

    return ChatbotRepositoryException(
      message: message,
      type: type,
      statusCode: status,
      errors: base.errors,
    );
  }

  factory ChatbotRepositoryException.malformed([String? message]) =>
      ChatbotRepositoryException(
        message: message ?? 'Format response Chatbot tidak valid.',
        type: ChatbotErrorType.malformed,
      );

  factory ChatbotRepositoryException.emptyResponse() =>
      ChatbotRepositoryException(
        message: 'Server mengembalikan jawaban Chatbot kosong.',
        type: ChatbotErrorType.emptyResponse,
      );
}

class ChatbotRepository {
  final ApiClient apiClient;

  ChatbotRepository({required this.apiClient});

  Future<ChatbotResponseModel> sendMessage(
    ChatbotMessageRequest request,
  ) async {
    try {
      final response = await apiClient.dio.post(
        '/chatbot/message',
        data: request.toJson(),
        options: Options(
          // Laravel may try Gemini and then Groq. This remains bounded above
          // the server provider budget without changing other API requests.
          receiveTimeout: const Duration(seconds: 35),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final data = _dataEnvelope(response.data);
      if (data is! Map) {
        throw ChatbotRepositoryException.malformed(
          'Data jawaban Chatbot bukan object JSON.',
        );
      }
      return ChatbotResponseModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw ChatbotRepositoryException.fromDioException(error);
    } on ChatbotRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      if (error.message.contains('tidak lengkap')) {
        throw ChatbotRepositoryException.emptyResponse();
      }
      throw ChatbotRepositoryException.malformed(error.message);
    }
  }

  Future<List<ChatMessageModel>> getHistory(String sessionId) async {
    try {
      final response = await apiClient.dio.get(
        '/chatbot/history',
        queryParameters: {'session_id': sessionId},
      );
      final data = _dataEnvelope(response.data);
      if (data is! List) {
        throw ChatbotRepositoryException.malformed(
          'Data riwayat Chatbot bukan list JSON.',
        );
      }
      return data
          .map((entry) {
            if (entry is! Map) {
              throw const FormatException('Pesan history bukan object JSON.');
            }
            return ChatMessageModel.fromJson(Map<String, dynamic>.from(entry));
          })
          .toList(growable: false);
    } on DioException catch (error) {
      throw ChatbotRepositoryException.fromDioException(error);
    } on ChatbotRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw ChatbotRepositoryException.malformed(error.message);
    }
  }

  Future<void> deleteHistory(String sessionId) async {
    try {
      final response = await apiClient.dio.delete(
        '/chatbot/history',
        queryParameters: {'session_id': sessionId},
      );
      _successEnvelope(response.data);
    } on DioException catch (error) {
      throw ChatbotRepositoryException.fromDioException(error);
    } on ChatbotRepositoryException {
      rethrow;
    }
  }

  dynamic _dataEnvelope(dynamic value) {
    final envelope = _successEnvelope(value);
    if (!envelope.containsKey('data')) {
      throw ChatbotRepositoryException.malformed(
        'Response Chatbot tidak memiliki field data.',
      );
    }
    return envelope['data'];
  }

  Map<dynamic, dynamic> _successEnvelope(dynamic value) {
    if (value is! Map || value['success'] != true) {
      throw ChatbotRepositoryException.malformed(
        'Envelope response Chatbot tidak valid.',
      );
    }
    return value;
  }
}

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepository(apiClient: ref.watch(apiClientProvider));
});
