import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/usulan_email_model.dart';

class EmailRepository {
  final ApiClient apiClient;

  EmailRepository({required this.apiClient});

  Future<List<Map<String, dynamic>>> getPegawai({String? search}) async {
    try {
      final response = await apiClient.dio.get(
        '/pegawai',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = _data(response.data);
      final entries = data is Map ? data['data'] : null;
      if (entries is! List) {
        throw const FormatException('Daftar pegawai tidak valid.');
      }
      return entries
          .whereType<Map>()
          .map((entry) {
            final raw = Map<String, dynamic>.from(entry);
            return {
              'nama': raw['Nama'] ?? raw['nama'] ?? '',
              'nip_baru':
                  raw['NIP_Baru'] ?? raw['nip_baru'] ?? raw['nip'] ?? '',
              'jabatan': raw['NJab'] ?? raw['jabatan'] ?? '-',
              'unit_kerja': raw['Unit_Kerja'] ?? raw['unit_kerja'] ?? '-',
              'opd': raw['NUnKer'] ?? raw['opd'] ?? raw['Unit_Kerja'] ?? '-',
              'email_usulan': raw['EmailUsulan'] ?? raw['email_usulan'] ?? '-',
              'email_pribadi':
                  raw['EmailPribadi'] ?? raw['email_pribadi'] ?? '',
            };
          })
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<UsulanEmailModel>> getUsulan() async {
    try {
      final response = await apiClient.dio.get('/pengajuan-email');
      final data = _data(response.data);
      final entries = data is Map ? data['data'] : null;
      if (entries is! List) {
        throw const FormatException('Daftar usulan tidak valid.');
      }
      return entries
          .whereType<Map>()
          .map(
            (entry) =>
                UsulanEmailModel.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<UsulanEmailModel> submit({
    required String nip,
    required String emailPribadi,
  }) => _object(
    () => apiClient.dio.post(
      '/pengajuan-email',
      data: {'nip': nip, 'email_pribadi': emailPribadi},
    ),
  );

  Future<UsulanEmailModel> approve(int id, String emailResmi) => _object(
    () => apiClient.dio.post(
      '/pengajuan-email/$id/buat-email-resmi',
      data: {'email_resmi': emailResmi},
    ),
  );

  Future<UsulanEmailModel> verify(int id, {String? catatan}) => _object(
    () => apiClient.dio.post(
      '/pengajuan-email/$id/verifikasi',
      data: {
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan': catatan.trim(),
      },
    ),
  );

  Future<UsulanEmailModel> reject(int id, String catatan) => _object(
    () => apiClient.dio.post(
      '/pengajuan-email/$id/tolak-email',
      data: {'catatan': catatan},
    ),
  );

  Future<UsulanEmailModel> _object(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final data = _data((await request()).data);
      if (data is! Map) throw const FormatException('Data usulan tidak valid.');
      return UsulanEmailModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  dynamic _data(dynamic response) {
    if (response is! Map ||
        response['success'] != true ||
        !response.containsKey('data')) {
      throw const FormatException('Envelope response Email tidak valid.');
    }
    return response['data'];
  }
}

final emailRepositoryProvider = Provider<EmailRepository>(
  (ref) => EmailRepository(apiClient: ref.watch(apiClientProvider)),
);
