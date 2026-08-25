import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService secureStorageService;

  static String get defaultBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  ApiClient({
    required this.secureStorageService,
    String? baseUrl,
    Dio? dioOverride,
  }) : dio = dioOverride ?? Dio() {
    dio.options = BaseOptions(
      baseUrl: baseUrl ?? defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    // Interceptor untuk menyuntikkan token & logging
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
    dio.interceptors.add(_ShortLivedGetCacheInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          // Tokens, passwords, and business payloads must not be printed even
          // in debug builds. URI/status/error remain available for diagnosis.
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      );
    }
  }
}

class _ShortLivedGetCacheInterceptor extends Interceptor {
  // Navigation uses the most recent in-memory response first. Realtime,
  // pull-to-refresh, and post-mutation reads opt out with `skipShortCache`,
  // so this improves perceived speed without hiding fresh business updates.
  final Duration ttl = const Duration(seconds: 90);
  final Duration staleIfError = const Duration(minutes: 5);
  final Map<String, _CachedGetResponse> _responses = {};

  _ShortLivedGetCacheInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      _responses.clear();
      return handler.next(options);
    }
    if (options.extra['skipShortCache'] == true) {
      return handler.next(options);
    }

    final cached = _responses[_key(options)];
    if (cached != null && DateTime.now().difference(cached.savedAt) <= ttl) {
      return handler.resolve(cached.toResponse(options, fromStaleCache: false));
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    if (options.method.toUpperCase() == 'GET' &&
        options.extra['skipShortCache'] != true &&
        (response.statusCode ?? 500) < 400) {
      _responses[_key(options)] = _CachedGetResponse.fromResponse(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final options = error.requestOptions;
    final mayUseStale = options.method.toUpperCase() == 'GET' &&
        (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            (error.response?.statusCode ?? 0) >= 500);
    final cached = mayUseStale ? _responses[_key(options)] : null;
    if (cached != null &&
        DateTime.now().difference(cached.savedAt) <= staleIfError) {
      return handler.resolve(cached.toResponse(options, fromStaleCache: true));
    }
    handler.next(error);
  }

  String _key(RequestOptions options) {
    final query = options.queryParameters.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final normalizedQuery = query
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    final token = options.headers['Authorization']?.toString() ?? '';
    return '${options.baseUrl}${options.path}?$normalizedQuery|$token';
  }
}

class _CachedGetResponse {
  final dynamic data;
  final int? statusCode;
  final String? statusMessage;
  final Headers headers;
  final Map<String, dynamic> extra;
  final DateTime savedAt;

  const _CachedGetResponse({
    required this.data,
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.extra,
    required this.savedAt,
  });

  factory _CachedGetResponse.fromResponse(Response response) =>
      _CachedGetResponse(
        data: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        extra: Map<String, dynamic>.from(response.extra),
        savedAt: DateTime.now(),
      );

  Response<dynamic> toResponse(
    RequestOptions options, {
    required bool fromStaleCache,
  }) => Response<dynamic>(
    requestOptions: options,
    data: data,
    statusCode: statusCode,
    statusMessage: statusMessage,
    headers: headers,
    extra: {
      ...extra,
      'memoryCache': true,
      'staleCache': fromStaleCache,
    },
  );
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return ApiClient(secureStorageService: storageService);
});
