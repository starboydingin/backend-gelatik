import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/network/api_client.dart';
import 'package:gelatik/core/storage/secure_storage_service.dart';
import 'package:gelatik/features/chatbot/models/chatbot_request.dart';
import 'package:gelatik/features/chatbot/repositories/chatbot_repository.dart';

class _MemoryStorage extends SecureStorageService {
  _MemoryStorage();

  @override
  Future<String?> getToken() async => 'token';
}

class _Adapter implements HttpClientAdapter {
  dynamic body;
  int status;
  DioExceptionType? errorType;
  RequestOptions? lastRequest;

  _Adapter({this.body, this.status = 200, this.errorType});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (errorType != null) {
      throw DioException(requestOptions: options, type: errorType!);
    }
    return ResponseBody.fromString(
      body is String ? body as String : _json(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  String _json(dynamic value) {
    if (value == null) return '';
    return const JsonEncoder().convert(value);
  }

  @override
  void close({bool force = false}) {}
}

// Avoid a network mocking dependency: Dio talks only to this in-memory adapter.
ChatbotRepository _repository(_Adapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ChatbotRepository(
    apiClient: ApiClient(
      secureStorageService: _MemoryStorage(),
      baseUrl: 'https://example.invalid/api',
      dioOverride: dio,
    ),
  );
}

void main() {
  group('Chatbot repository contract', () {
    test('7. send success dan payload tidak membawa user_id', () async {
      final adapter = _Adapter(
        body: {
          'success': true,
          'data': {
            'success': true,
            'session_id': 'session-1',
            'reply': 'Silakan buka menu Peminjaman.',
            'provider': 'consultation_created',
            'escalated': true,
            'konsultasi_id': 91,
          },
        },
      );
      final result = await _repository(
        adapter,
      ).sendMessage(ChatbotMessageRequest(message: ' Pinjam alat '));
      expect(result.sessionId, 'session-1');
      expect(result.escalated, isTrue);
      expect(result.consultationId, 91);
      expect(adapter.lastRequest!.data, {'message': 'Pinjam alat'});
      expect(adapter.lastRequest!.data, isNot(contains('user_id')));
      expect(adapter.lastRequest!.receiveTimeout, const Duration(seconds: 15));
    });

    test('8. history success dan query session', () async {
      final adapter = _Adapter(
        body: {
          'success': true,
          'data': [
            {
              'id': 1,
              'role': 'user',
              'content': 'Halo',
              'created_at': '2026-08-06T10:00:00Z',
            },
          ],
        },
      );
      final result = await _repository(adapter).getHistory('session-1');
      expect(result.single.text, 'Halo');
      expect(adapter.lastRequest!.queryParameters['session_id'], 'session-1');
    });

    test('9. empty history valid', () async {
      final result = await _repository(
        _Adapter(body: {'success': true, 'data': []}),
      ).getHistory('session-1');
      expect(result, isEmpty);
    });

    test(
      'latest conversation memuat session dan history dalam satu request',
      () async {
        final adapter = _Adapter(
          body: {
            'success': true,
            'data': {
              'session_id': 'session-1',
              'messages': [
                {
                  'id': 1,
                  'role': 'user',
                  'content': 'Halo',
                  'created_at': '2026-08-06T10:00:00Z',
                },
              ],
            },
          },
        );
        final result = await _repository(adapter).getLatestConversation();
        expect(result?.sessionId, 'session-1');
        expect(result?.messages.single.text, 'Halo');
        expect(
          adapter.lastRequest!.path,
          endsWith('/chatbot/conversations/latest'),
        );
        expect(adapter.lastRequest!.extra['skipShortCache'], isTrue);
      },
    );

    for (final entry in <(int, ChatbotErrorType)>[
      (400, ChatbotErrorType.invalidRequest),
      (401, ChatbotErrorType.unauthorized),
      (403, ChatbotErrorType.forbidden),
      (404, ChatbotErrorType.notFound),
      (422, ChatbotErrorType.validation),
      (429, ChatbotErrorType.rateLimit),
      (503, ChatbotErrorType.upstream),
      (500, ChatbotErrorType.upstream),
      (504, ChatbotErrorType.timeout),
    ]) {
      test('HTTP ${entry.$1} dipetakan ke ${entry.$2.name}', () async {
        final repository = _repository(
          _Adapter(
            status: entry.$1,
            body: {
              'success': false,
              'message': 'Backend error',
              if (entry.$1 == 422)
                'errors': {
                  'message': ['Pesan wajib diisi.'],
                },
            },
          ),
        );
        await expectLater(
          repository.getHistory('session-1'),
          throwsA(
            isA<ChatbotRepositoryException>().having(
              (error) => error.type,
              'type',
              entry.$2,
            ),
          ),
        );
      });
    }

    test('15. timeout dan network dipetakan', () async {
      for (final value in <(DioExceptionType, ChatbotErrorType)>[
        (DioExceptionType.connectionTimeout, ChatbotErrorType.timeout),
        (DioExceptionType.connectionError, ChatbotErrorType.network),
      ]) {
        await expectLater(
          _repository(_Adapter(errorType: value.$1)).getHistory('session-1'),
          throwsA(
            isA<ChatbotRepositoryException>().having(
              (error) => error.type,
              'type',
              value.$2,
            ),
          ),
        );
      }
    });

    test('16. send timeout exposes a safe retryable message', () async {
      await expectLater(
        _repository(
          _Adapter(errorType: DioExceptionType.receiveTimeout),
        ).sendMessage(ChatbotMessageRequest(message: 'Halo')),
        throwsA(
          isA<ChatbotRepositoryException>()
              .having((error) => error.type, 'type', ChatbotErrorType.timeout)
              .having(
                (error) => error.message,
                'message',
                'Asisten Gelatik belum merespons. Silakan coba lagi.',
              ),
        ),
      );
    });

    test('17. malformed response ditolak', () async {
      await expectLater(
        _repository(
          _Adapter(body: {'success': true, 'data': {}}),
        ).getHistory('session-1'),
        throwsA(
          isA<ChatbotRepositoryException>().having(
            (error) => error.type,
            'type',
            ChatbotErrorType.malformed,
          ),
        ),
      );
    });

    test('18. empty reply ditolak khusus', () async {
      await expectLater(
        _repository(
          _Adapter(
            body: {
              'success': true,
              'data': {'session_id': 'session-1', 'reply': ''},
            },
          ),
        ).sendMessage(ChatbotMessageRequest(message: 'Halo')),
        throwsA(
          isA<ChatbotRepositoryException>().having(
            (error) => error.type,
            'type',
            ChatbotErrorType.emptyResponse,
          ),
        ),
      );
    });

    test('delete history success memakai session query', () async {
      final adapter = _Adapter(body: {'success': true, 'message': 'Dihapus'});
      await _repository(adapter).deleteHistory('session-1');
      expect(adapter.lastRequest!.method, 'DELETE');
      expect(adapter.lastRequest!.queryParameters['session_id'], 'session-1');
    });
  });
}
