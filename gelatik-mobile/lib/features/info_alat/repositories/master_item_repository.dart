import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/master_item_model.dart';

enum MasterItemErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  validation,
  notFound,
  server,
  malformed,
  unknown,
}

class MasterItemRepositoryException extends ApiException {
  final MasterItemErrorType type;

  MasterItemRepositoryException({
    required super.message,
    required this.type,
    super.statusCode,
    super.errors,
  });

  factory MasterItemRepositoryException.fromDioException(
    DioException exception,
  ) {
    final baseException = ApiException.fromDioException(exception);
    final statusCode = exception.response?.statusCode;

    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout) {
      return MasterItemRepositoryException(
        message: baseException.message,
        type: MasterItemErrorType.timeout,
        statusCode: statusCode,
      );
    }

    if (exception.type == DioExceptionType.connectionError) {
      return MasterItemRepositoryException(
        message: baseException.message,
        type: MasterItemErrorType.network,
        statusCode: statusCode,
      );
    }

    final type = statusCode != null && statusCode >= 500
        ? MasterItemErrorType.server
        : switch (statusCode) {
            401 => MasterItemErrorType.unauthorized,
            403 => MasterItemErrorType.forbidden,
            404 => MasterItemErrorType.notFound,
            422 => MasterItemErrorType.validation,
            _ => MasterItemErrorType.unknown,
          };

    final message = switch (type) {
      MasterItemErrorType.unauthorized =>
        'Sesi Anda telah berakhir. Silakan login kembali.',
      MasterItemErrorType.forbidden =>
        'Anda tidak memiliki izin untuk mengakses katalog alat.',
      MasterItemErrorType.notFound => 'Data alat tidak ditemukan.',
      MasterItemErrorType.server =>
        'Server gagal memproses katalog alat. Silakan coba lagi.',
      _ => baseException.message,
    };

    return MasterItemRepositoryException(
      message: message,
      type: type,
      statusCode: statusCode,
      errors: baseException.errors,
    );
  }

  factory MasterItemRepositoryException.malformed([String? detail]) {
    return MasterItemRepositoryException(
      message: detail ?? 'Format response katalog alat tidak valid.',
      type: MasterItemErrorType.malformed,
    );
  }
}

class MasterItemRepository {
  final ApiClient apiClient;

  MasterItemRepository({required this.apiClient});

  Future<List<MasterItemModel>> getItems() async {
    try {
      final response = await apiClient.dio.get('/items');
      return _parseListEnvelope(response.data);
    } on DioException catch (error) {
      throw MasterItemRepositoryException.fromDioException(error);
    } on MasterItemRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw MasterItemRepositoryException.malformed(error.message);
    }
  }

  Future<List<MasterItemModel>> searchItems(String keyword) async {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) return getItems();

    try {
      final encodedKeyword = Uri.encodeComponent(normalizedKeyword);
      final response = await apiClient.dio.get('/items/search/$encodedKeyword');
      return _parseListEnvelope(response.data);
    } on DioException catch (error) {
      throw MasterItemRepositoryException.fromDioException(error);
    } on MasterItemRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw MasterItemRepositoryException.malformed(error.message);
    }
  }

  Future<MasterItemModel> getItem(int id) async {
    try {
      final response = await apiClient.dio.get('/items/$id');
      final data = _extractEnvelopeData(response.data);
      if (data is! Map) {
        throw MasterItemRepositoryException.malformed(
          'Data detail alat bukan object JSON.',
        );
      }
      return MasterItemModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw MasterItemRepositoryException.fromDioException(error);
    } on MasterItemRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw MasterItemRepositoryException.malformed(error.message);
    }
  }

  List<MasterItemModel> _parseListEnvelope(dynamic responseData) {
    final data = _extractEnvelopeData(responseData);
    if (data is! List) {
      throw MasterItemRepositoryException.malformed(
        'Data katalog alat bukan list JSON.',
      );
    }

    return data
        .map((item) {
          if (item is! Map) {
            throw MasterItemRepositoryException.malformed(
              'Salah satu item katalog bukan object JSON.',
            );
          }
          return MasterItemModel.fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
  }

  dynamic _extractEnvelopeData(dynamic responseData) {
    if (responseData is! Map || responseData['success'] != true) {
      throw MasterItemRepositoryException.malformed(
        'Envelope response katalog alat tidak valid.',
      );
    }
    if (!responseData.containsKey('data')) {
      throw MasterItemRepositoryException.malformed(
        'Response katalog alat tidak memiliki field data.',
      );
    }
    return responseData['data'];
  }
}

final masterItemRepositoryProvider = Provider<MasterItemRepository>((ref) {
  return MasterItemRepository(apiClient: ref.watch(apiClientProvider));
});
