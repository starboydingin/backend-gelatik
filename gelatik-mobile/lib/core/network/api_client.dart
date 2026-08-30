import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Remove all account-scoped responses on logout/account replacement.
  void clearCache() => _getCache.clear();
}

class _ShortLivedGetCacheInterceptor extends Interceptor {
  // Navigation uses the most recent in-memory response first. Realtime,
  // pull-to-refresh, and post-mutation reads opt out with `skipShortCache`,
  // so this improves perceived speed without hiding fresh business updates.
  static const _defaultTtl = Duration(seconds: 60);
  final Duration staleIfError = const Duration(minutes: 5);
  final Map<String, _CachedGetResponse> _responses = {};
  final _PersistentGetCache _persistent = _PersistentGetCache();
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
      if (_supportsPersistentCache(options.path)) {
        unawaited(_persistent.write(_key(options), response));
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
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
    if (mayUseStale && _supportsPersistentCache(options.path)) {
      final persisted = await _persistent.read(_key(options), options);
      if (persisted != null) return handler.resolve(persisted);
    }
    handler.next(error);
  }

  bool _supportsPersistentCache(String path) => RegExp(
    r'^/(dashboard|faq|pengumuman|slider|pinjam|konsul)(/|$)',
  ).hasMatch(path);

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
    if (resource == 'session') {
      _responses.clear();
      return;
    }
    if (resource.isEmpty) return;
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
    if (prefixes.isEmpty) return;
    _responses.removeWhere(
      (key, _) => prefixes.any((prefix) => key.contains(prefix)),
    );
  }

  void clear() {
    _cacheGeneration++;
    _responses.clear();
    unawaited(_persistent.clear());
  }
}

class _PersistentGetCache {
  static const _prefix = 'gelatik_get_cache_v1_';
  static const _maxAge = Duration(days: 7);

  Future<void> write(String rawKey, Response<dynamic> response) async {
    try {
      final encoded = jsonEncode({
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'status_code': response.statusCode,
        'data': response.data,
      });
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey(rawKey), encoded);
    } catch (_) {
      // Persistent cache is an optional resilience layer and must never make a
      // successful REST response fail.
    }
  }

  Future<Response<dynamic>?> read(String rawKey, RequestOptions options) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_storageKey(rawKey));
      if (encoded == null) return null;
      final record = jsonDecode(encoded);
      if (record is! Map) return null;
      final savedAt = DateTime.tryParse('${record['saved_at']}');
      if (savedAt == null ||
          DateTime.now().toUtc().difference(savedAt) > _maxAge) {
        await preferences.remove(_storageKey(rawKey));
        return null;
      }
      return Response<dynamic>(
        requestOptions: options,
        data: record['data'],
        statusCode: int.tryParse('${record['status_code']}') ?? 200,
        extra: const {
          'persistentCache': true,
          'staleCache': true,
          'cacheLabel': 'Menampilkan data tersimpan',
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final keys = preferences.getKeys().where(
        (key) => key.startsWith(_prefix),
      );
      await Future.wait(keys.map(preferences.remove));
    } catch (_) {
      // Some pure Dart tests do not initialize Flutter's services binding.
      // Cache cleanup must remain best-effort and never block logout.
    }
  }

  String _storageKey(String value) {
    // BigInt keeps FNV-1a deterministic on both the Dart VM and JavaScript.
    // JavaScript numbers cannot represent the 64-bit literals exactly.
    var hash = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = BigInt.parse('7fffffffffffffff', radix: 16);
    for (final byte in utf8.encode(value)) {
      hash ^= BigInt.from(byte);
      hash = (hash * prime) & mask;
    }
    return '$_prefix${hash.toRadixString(16)}';
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
