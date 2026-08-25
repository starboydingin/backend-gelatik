import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService secureStorageService;
  final _ShortLivedGetCacheInterceptor _getCache =
      _ShortLivedGetCacheInterceptor();

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
    dio.interceptors.add(_getCache);

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

  /// Clears only GET cache entries affected by a realtime resource signal.
  void invalidateCacheForResource(String resource) =>
      _getCache.invalidateResource(resource);
}

class _ShortLivedGetCacheInterceptor extends Interceptor {
  // Navigation uses the most recent in-memory response first. Realtime,
  // pull-to-refresh, and post-mutation reads opt out with `skipShortCache`,
  // so this improves perceived speed without hiding fresh business updates.
  static const _defaultTtl = Duration(seconds: 60);
  final Duration staleIfError = const Duration(minutes: 5);
  final Map<String, _CachedGetResponse> _responses = {};
  int _cacheGeneration = 0;

  _ShortLivedGetCacheInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      _cacheGeneration++;
      _responses.clear();
      return handler.next(options);
    }
    options.extra['shortCacheGeneration'] = _cacheGeneration;
    if (options.extra['skipShortCache'] == true) {
      return handler.next(options);
    }

    final cached = _responses[_key(options)];
    if (cached != null &&
        DateTime.now().difference(cached.savedAt) <= _ttlFor(options)) {
      return handler.resolve(cached.toResponse(options, fromStaleCache: false));
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    if (options.method.toUpperCase() == 'GET' &&
        options.extra['shortCacheGeneration'] == _cacheGeneration &&
        (response.statusCode ?? 500) < 400) {
      _responses[_key(options)] = _CachedGetResponse.fromResponse(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final options = error.requestOptions;
    final mayUseStale =
        options.method.toUpperCase() == 'GET' &&
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

  Duration _ttlFor(RequestOptions options) {
    final requested = options.extra['cacheTtlSeconds'];
    if (requested is int && requested > 0) {
      return Duration(seconds: requested);
    }
    final path = options.path;
    if (path == '/dashboard' || path == '/admin/dashboard') {
      return const Duration(seconds: 30);
    }
    if (path.startsWith('/notifications') || path.startsWith('/chatbot')) {
      return const Duration(seconds: 20);
    }
    if (RegExp(
      r'^/(faq|topik|items?|opd|pengumuman|slider|list-router-opd)',
    ).hasMatch(path)) {
      return const Duration(minutes: 5);
    }
    return _defaultTtl;
  }

  void invalidateResource(String rawResource) {
    _cacheGeneration++;
    final resource = rawResource.trim().toLowerCase().replaceAll('-', '_');
    if (resource.isEmpty || resource == 'session') {
      _responses.clear();
      return;
    }
    final prefixes = <String>[
      if (resource == 'peminjaman') '/pinjam',
      if (resource == 'peminjaman') '/dashboard',
      if (resource == 'konsultasi') '/konsul',
      if (resource == 'konsultasi') '/dashboard',
      if (resource == 'usulan_email') '/pengajuan-email',
      if (resource == 'usulan_email') '/pegawai',
      if (resource == 'usulan_email') '/dashboard',
      if (resource == 'notification') '/notifications',
      if (resource == 'notification') '/dashboard',
      if (resource == 'kritik_saran') '/kritik-saran',
      if (resource == 'kritik_saran') '/notifications',
      if (resource == 'rating') '/rating',
      if (resource == 'rating') '/dashboard',
      if (resource == 'user') '/me',
      if (resource == 'user') '/dashboard',
      if (resource == 'whatsapp_subscription') '/notifikasi/wa',
      if (resource == 'faq') '/faq',
      if (resource == 'mastertopik') '/topik',
      if (resource == 'mastertopik') '/faq',
      if (resource == 'masteritem') '/items',
      if (resource == 'masteritem') '/item',
      if (resource == 'router' || resource == 'routerlist') '/list-router-opd',
      if (resource == 'pengumuman' || resource == 'slider') '/pengumuman',
      if (resource == 'pengumuman' || resource == 'slider') '/dashboard',
      if (resource == 'insights') '/dashboard',
    ];
    if (prefixes.isEmpty) {
      _responses.clear();
      return;
    }
    _responses.removeWhere(
      (key, _) => prefixes.any((prefix) => key.contains(prefix)),
    );
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
    extra: {...extra, 'memoryCache': true, 'staleCache': fromStaleCache},
  );
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return ApiClient(secureStorageService: storageService);
});
