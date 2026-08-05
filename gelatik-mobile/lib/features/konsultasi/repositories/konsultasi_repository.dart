import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/konsultasi_model.dart';
import '../models/konsultasi_request.dart';
import '../models/konsultasi_response_model.dart';
import '../models/konsultasi_topik_model.dart';

enum KonsultasiErrorType {
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

class KonsultasiRepositoryException extends ApiException {
  final KonsultasiErrorType type;

  KonsultasiRepositoryException({
    required super.message,
    required this.type,
    super.statusCode,
    super.errors,
  });

  factory KonsultasiRepositoryException.fromDioException(
    DioException exception,
  ) {
    final base = ApiException.fromDioException(exception);
    final status = exception.response?.statusCode;
    final type = switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => KonsultasiErrorType.timeout,
      DioExceptionType.connectionError => KonsultasiErrorType.network,
      _ =>
        status != null && status >= 500
            ? KonsultasiErrorType.server
            : switch (status) {
                400 => KonsultasiErrorType.invalidState,
                401 => KonsultasiErrorType.unauthorized,
                403 => KonsultasiErrorType.forbidden,
                404 => KonsultasiErrorType.notFound,
                409 => KonsultasiErrorType.conflict,
                422 => KonsultasiErrorType.validation,
                _ => KonsultasiErrorType.unknown,
              },
    };
    final message = switch (type) {
      KonsultasiErrorType.unauthorized =>
        'Sesi Anda telah berakhir. Silakan login kembali.',
      KonsultasiErrorType.forbidden =>
        'Anda tidak memiliki izin untuk melakukan aksi konsultasi ini.',
      KonsultasiErrorType.notFound => 'Konsultasi tidak ditemukan.',
      KonsultasiErrorType.invalidState || KonsultasiErrorType.conflict =>
        base.message.isEmpty
            ? 'Status konsultasi tidak mengizinkan aksi ini.'
            : base.message,
      KonsultasiErrorType.server =>
        'Server gagal memproses konsultasi. Silakan coba lagi.',
      _ => base.message,
    };
    return KonsultasiRepositoryException(
      message: message,
      type: type,
      statusCode: status,
      errors: base.errors,
    );
  }

  factory KonsultasiRepositoryException.malformed([String? detail]) =>
      KonsultasiRepositoryException(
        message: detail ?? 'Format response konsultasi tidak valid.',
        type: KonsultasiErrorType.malformed,
      );
}

class KonsultasiRepository {
  final ApiClient apiClient;

  KonsultasiRepository({required this.apiClient});

  Future<List<KonsultasiModel>> getKonsultasi({int page = 1}) async {
    try {
      final response = await apiClient.dio.get(
        '/konsul',
        queryParameters: {'page': page},
      );
      final data = _envelope(response.data);
      final entries = data is Map ? data['data'] : data;
      if (entries is! List) {
        throw KonsultasiRepositoryException.malformed(
          'Data daftar konsultasi bukan list/paginator JSON.',
        );
      }
      return entries.map(_parseKonsultasi).toList(growable: false);
    } on DioException catch (error) {
      throw KonsultasiRepositoryException.fromDioException(error);
    } on KonsultasiRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw KonsultasiRepositoryException.malformed(error.message);
    }
  }

  Future<KonsultasiModel> getDetail(int id) =>
      _object(() => apiClient.dio.get('/konsul/$id'));

  Future<KonsultasiModel> create(BuatKonsultasiRequest request) => _object(
    () => apiClient.dio.post(
      '/konsul',
      data: _payload(request.toJson(), request.filePath, 'file'),
    ),
  );

  Future<KonsultasiResponseModel> answer(
    int id,
    BalasKonsultasiRequest request,
  ) async {
    try {
      final response = await apiClient.dio.post(
        '/konsul/$id/response',
        data: _payload(request.toJson(), request.filePath, 'file'),
      );
      final data = _envelope(response.data);
      if (data is! Map) {
        throw KonsultasiRepositoryException.malformed(
          'Data balasan konsultasi bukan object JSON.',
        );
      }
      return KonsultasiResponseModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw KonsultasiRepositoryException.fromDioException(error);
    } on KonsultasiRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw KonsultasiRepositoryException.malformed(error.message);
    }
  }

  Future<KonsultasiModel> updateStatus(int id, String status) => _object(
    () => apiClient.dio.post('/konsul/$id/status', data: {'status': status}),
  );

  Future<void> delete(int id) async {
    try {
      final response = await apiClient.dio.delete('/konsul/$id');
      _envelope(response.data, dataRequired: false);
    } on DioException catch (error) {
      throw KonsultasiRepositoryException.fromDioException(error);
    } on KonsultasiRepositoryException {
      rethrow;
    }
  }

  Future<List<KonsultasiTopikModel>> getTopik() async {
    try {
      final response = await apiClient.dio.get('/topik');
      final data = _envelope(response.data);
      if (data is! List) {
        throw KonsultasiRepositoryException.malformed(
          'Data topik konsultasi bukan list JSON.',
        );
      }
      return data
          .map((entry) {
            if (entry is! Map) {
              throw const FormatException('Salah satu topik bukan object.');
            }
            return KonsultasiTopikModel.fromJson(
              Map<String, dynamic>.from(entry),
            );
          })
          .toList(growable: false);
    } on DioException catch (error) {
      throw KonsultasiRepositoryException.fromDioException(error);
    } on KonsultasiRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw KonsultasiRepositoryException.malformed(error.message);
    }
  }

  Future<KonsultasiModel> _object(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = _envelope(response.data);
      if (data is! Map) {
        throw KonsultasiRepositoryException.malformed(
          'Data konsultasi bukan object JSON.',
        );
      }
      return KonsultasiModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw KonsultasiRepositoryException.fromDioException(error);
    } on KonsultasiRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw KonsultasiRepositoryException.malformed(error.message);
    }
  }

  dynamic _payload(
    Map<String, dynamic> values,
    String? filePath,
    String fileKey,
  ) {
    if (filePath == null || filePath.isEmpty) return values;
    return FormData.fromMap({
      ...values,
      fileKey: MultipartFile.fromFileSync(filePath),
    });
  }

  KonsultasiModel _parseKonsultasi(dynamic entry) {
    if (entry is! Map) {
      throw KonsultasiRepositoryException.malformed(
        'Salah satu konsultasi bukan object JSON.',
      );
    }
    return KonsultasiModel.fromJson(Map<String, dynamic>.from(entry));
  }

  dynamic _envelope(dynamic value, {bool dataRequired = true}) {
    if (value is! Map || value['success'] != true) {
      throw KonsultasiRepositoryException.malformed(
        'Envelope response konsultasi tidak valid.',
      );
    }
    if (dataRequired && !value.containsKey('data')) {
      throw KonsultasiRepositoryException.malformed(
        'Response konsultasi tidak memiliki field data.',
      );
    }
    return value['data'];
  }
}

final konsultasiRepositoryProvider = Provider<KonsultasiRepository>((ref) {
  return KonsultasiRepository(apiClient: ref.watch(apiClientProvider));
});
