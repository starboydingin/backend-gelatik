import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDioException(DioException dioException) {
    int? statusCode = dioException.response?.statusCode;
    String message = 'Terjadi kesalahan jaringan atau server.';
    Map<String, dynamic>? errors;

    final responseData = dioException.response?.data;

    if (responseData != null && responseData is Map<String, dynamic>) {
      // Parse errors field if validation errors (422)
      if (responseData.containsKey('errors') && responseData['errors'] is Map) {
        errors = Map<String, dynamic>.from(responseData['errors']);
      }

      // Parse primary message
      if (responseData['message'] != null &&
          responseData['message'].toString().isNotEmpty) {
        message = responseData['message'].toString();
      } else if (responseData['error'] != null &&
          responseData['error'].toString().isNotEmpty) {
        message = responseData['error'].toString();
      }

      // If validation error and message is generic 'The given data was invalid.', format first field error if available
      if (statusCode == 422 && errors != null && errors.isNotEmpty) {
        final firstKey = errors.keys.first;
        final firstVal = errors[firstKey];
        if (firstVal is List && firstVal.isNotEmpty) {
          message = firstVal.first.toString();
        } else if (firstVal is String) {
          message = firstVal;
        }
      }
    } else if (dioException.type == DioExceptionType.connectionTimeout ||
        dioException.type == DioExceptionType.sendTimeout ||
        dioException.type == DioExceptionType.receiveTimeout) {
      message = 'Koneksi ke server timeout (lebih dari 15 detik).';
    } else if (dioException.type == DioExceptionType.connectionError) {
      message = 'Gagal terhubung ke server backend. Pastikan server aktif.';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  @override
  String toString() => message;
}
