import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class InternetRepository {
  final ApiClient apiClient;

  InternetRepository({required this.apiClient});

  Future<Map<String, dynamic>> getInternetOverview() async {
    try {
      final response = await apiClient.dio.get('/list-router-opd');
      final data = _data(response.data);
      if (data is! Map) throw const FormatException('Data Internet tidak valid.');
      final bandwidth = data['bandwidth'] is Map
          ? Map<String, dynamic>.from(data['bandwidth'])
          : <String, dynamic>{'available': false, 'connections': const []};
      final entries = data['list_router'] is List
          ? data['list_router']
          : (data['router'] is List ? data['router'] : const []);
      final routers = (entries as List)
          .whereType<Map>()
          .map((entry) {
            final value = Map<String, dynamic>.from(entry);
            return {
              'nama_router': value['nama_router'] ?? value['identity_router'] ?? 'Router OPD',
              'ip_address': value['ip_address'] ?? '-',
              'tipe': value['tipe'] ?? value['interface'] ?? '-',
              'status': _status(value['status'] ?? value['is_active']),
              'lokasi': value['lokasi'] ?? '-',
              'beban_traffic': value['beban_traffic'] ?? '-',
            };
          })
          .toList(growable: false);
      final connections = bandwidth['connections'] is List ? bandwidth['connections'] as List : const [];
      final primary = connections.whereType<Map>().firstOrNull;
      return {
        'routers': routers,
        'bandwidth': {
          'opd': bandwidth['opd'] ?? 'Informasi bandwidth belum tersedia',
          'provider': bandwidth['available'] == true ? 'Data Router OPD' : 'Tidak tersedia dari API',
          'status': bandwidth['available'] == true ? 'Tersedia' : 'Belum tersedia',
          'available': bandwidth['available'] == true,
          'download_mbps': primary?['download_mbps'] ?? '-',
          'upload_mbps': primary?['upload_mbps'] ?? '-',
        },
      };
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<Map<String, dynamic>>> getRouters() async {
    try {
      final response = await apiClient.dio.get('/list-router-opd');
      final data = _data(response.data);
      if (data is! Map) {
        throw const FormatException('Data router tidak valid.');
      }
      final entries = data['router'] is List
          ? data['router']
          : data['list_router'];
      if (entries is! List) {
        throw const FormatException('Daftar router tidak valid.');
      }
      return entries
          .whereType<Map>()
          .map((entry) {
            final value = Map<String, dynamic>.from(entry);
            return {
              'nama_router':
                  value['nama_router'] ??
                  value['identity_router'] ??
                  'Router OPD',
              'ip_address': value['ip_address'] ?? '-',
              'tipe': value['tipe'] ?? value['interface'] ?? '-',
              'status': _status(value['status'] ?? value['is_active']),
              'lokasi': value['lokasi'] ?? '-',
              'beban_traffic': value['beban_traffic'] ?? '-',
            };
          })
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<Map<String, dynamic>>> getFaqInternet() async {
    try {
      final response = await apiClient.dio.get(
        '/faq',
        queryParameters: {'topik_id': 39},
      );
      final data = _data(response.data);
      if (data is! List) throw const FormatException('Daftar FAQ tidak valid.');
      return data
          .whereType<Map>()
          .map((entry) {
            final value = Map<String, dynamic>.from(entry);
            return {
              'pertanyaan': value['judul'] ?? '',
              'jawaban': value['detail'] ?? '',
            };
          })
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  dynamic _data(dynamic response) {
    if (response is! Map ||
        response['success'] != true ||
        !response.containsKey('data')) {
      throw const FormatException('Envelope response Internet tidak valid.');
    }
    return response['data'];
  }

  String _status(dynamic value) => value == 1 || value == '1' || value == true
      ? 'Aktif'
      : (value?.toString() ?? '-');
}

final internetRepositoryProvider = Provider<InternetRepository>(
  (ref) => InternetRepository(apiClient: ref.watch(apiClientProvider)),
);
