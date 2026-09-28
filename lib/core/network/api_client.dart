import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(String siteUrl, String token)
      : _dio = Dio(BaseOptions(baseUrl: '${siteUrl.replaceAll(RegExp(r'/$'), '')}/wp-json/woo-manager/v1', headers: {'Authorization': 'Bearer $token'}, connectTimeout: const Duration(seconds: 15)));
  final Dio _dio;
  Future<Map<String, dynamic>> health() async => Map<String, dynamic>.from((await _dio.get('/health')).data as Map);
  Future<List<dynamic>> orders() async => (await _dio.get('/orders')).data as List<dynamic>;
}
