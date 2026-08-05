import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/pinjam_model.dart';
import '../models/pinjam_request.dart';

enum PeminjamanErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  validation,
  notFound,
  conflict,
  invalidState,
  server,
  malformed,
  unknown,
}

class PeminjamanRepositoryException extends ApiException {
  final PeminjamanErrorType type;

  PeminjamanRepositoryException({
    required super.message,
    required this.type,
    super.statusCode,
    super.errors,
  });

  factory PeminjamanRepositoryException.fromDioException(
    DioException exception,
  ) {
    final base = ApiException.fromDioException(exception);
    final status = exception.response?.statusCode;
    final type = switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => PeminjamanErrorType.timeout,
      DioExceptionType.connectionError => PeminjamanErrorType.network,
      _ =>
        status != null && status >= 500
            ? PeminjamanErrorType.server
            : switch (status) {
                400 => PeminjamanErrorType.invalidState,
                401 => PeminjamanErrorType.unauthorized,
                403 => PeminjamanErrorType.forbidden,
                404 => PeminjamanErrorType.notFound,
                409 => PeminjamanErrorType.conflict,
                422 => PeminjamanErrorType.validation,
                _ => PeminjamanErrorType.unknown,
              },
    };

    final message = switch (type) {
      PeminjamanErrorType.unauthorized =>
        'Sesi Anda telah berakhir. Silakan login kembali.',
      PeminjamanErrorType.forbidden =>
        'Anda tidak memiliki izin untuk melakukan aksi peminjaman ini.',
      PeminjamanErrorType.notFound => 'Data peminjaman tidak ditemukan.',
      PeminjamanErrorType.conflict =>
        'Data peminjaman berubah. Muat ulang lalu coba lagi.',
      PeminjamanErrorType.server =>
        'Server gagal memproses peminjaman. Silakan coba lagi.',
      _ => base.message,
    };
    return PeminjamanRepositoryException(
      message: message,
      type: type,
      statusCode: status,
      errors: base.errors,
    );
  }

  factory PeminjamanRepositoryException.malformed([String? detail]) =>
      PeminjamanRepositoryException(
        message: detail ?? 'Format response peminjaman tidak valid.',
        type: PeminjamanErrorType.malformed,
      );
}

class PeminjamanRepository {
  final ApiClient apiClient;

  PeminjamanRepository({required this.apiClient});

  Future<List<PinjamModel>> getPeminjaman({int page = 1}) async {
    try {
      final response = await apiClient.dio.get(
        '/pinjam',
        queryParameters: {'page': page},
      );
      final envelope = _envelopeData(response.data);
      final list = envelope is Map ? envelope['data'] : envelope;
      if (list is! List) {
        throw PeminjamanRepositoryException.malformed(
          'Data daftar peminjaman bukan list/paginator JSON.',
        );
      }
      return list.map(_parseEntry).toList(growable: false);
    } on DioException catch (error) {
      throw PeminjamanRepositoryException.fromDioException(error);
    } on PeminjamanRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw PeminjamanRepositoryException.malformed(error.message);
    }
  }

  Future<PinjamModel> getPeminjamanDetail(int id) async =>
      _objectRequest(() => apiClient.dio.get('/pinjam/$id'));

  Future<PinjamModel> createPeminjaman(PinjamRequest request) async =>
      _objectRequest(
        () => apiClient.dio.post('/pinjam', data: request.toJson()),
      );

  Future<PinjamModel> updatePeminjaman(
    int id,
    Map<String, dynamic> payload,
  ) async =>
      _objectRequest(() => apiClient.dio.put('/pinjam/$id', data: payload));

  Future<void> cancelPeminjaman(int id) async {
    try {
      final response = await apiClient.dio.delete('/pinjam/$id');
      _envelopeData(response.data, dataRequired: false);
    } on DioException catch (error) {
      throw PeminjamanRepositoryException.fromDioException(error);
    } on PeminjamanRepositoryException {
      rethrow;
    }
  }

  Future<PinjamModel> updateStatus(
    int id,
    String status, {
    String? catatan,
  }) async => _objectRequest(
    () => apiClient.dio.post(
      '/pinjam/$id/status',
      data: {
        'status': status,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      },
    ),
  );

  Future<PinjamModel> addItems(int id, Map<int, int> items) async =>
      _objectRequest(
        () => apiClient.dio.post(
          '/pinjam/$id',
          data: {
            'items': items.entries
                .map((entry) => {'item_id': entry.key, 'quantity': entry.value})
                .toList(),
          },
        ),
      );

  Future<PinjamModel> removeItem(int pinjamId, int itemId) async =>
      _objectRequest(
        () => apiClient.dio.delete('/pinjam/$pinjamId/item/$itemId'),
      );

  Future<PinjamModel> _objectRequest(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = _envelopeData(response.data);
      if (data is! Map) {
        throw PeminjamanRepositoryException.malformed(
          'Data peminjaman bukan object JSON.',
        );
      }
      return PinjamModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw PeminjamanRepositoryException.fromDioException(error);
    } on PeminjamanRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw PeminjamanRepositoryException.malformed(error.message);
    }
  }

  PinjamModel _parseEntry(dynamic entry) {
    if (entry is! Map) {
      throw PeminjamanRepositoryException.malformed(
        'Salah satu peminjaman bukan object JSON.',
      );
    }
    return PinjamModel.fromJson(Map<String, dynamic>.from(entry));
  }

  dynamic _envelopeData(dynamic responseData, {bool dataRequired = true}) {
    if (responseData is! Map || responseData['success'] != true) {
      throw PeminjamanRepositoryException.malformed(
        'Envelope response peminjaman tidak valid.',
      );
    }
    if (dataRequired && !responseData.containsKey('data')) {
      throw PeminjamanRepositoryException.malformed(
        'Response peminjaman tidak memiliki field data.',
      );
    }
    return responseData['data'];
  }
}

final peminjamanRepositoryProvider = Provider<PeminjamanRepository>((ref) {
  return PeminjamanRepository(apiClient: ref.watch(apiClientProvider));
});
