import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(String siteUrl, String token)
      : _dio = Dio(BaseOptions(baseUrl: '${siteUrl.replaceAll(RegExp(r'/$'), '')}/wp-json/woo-manager/v1', headers: {'Authorization': 'Bearer $token'}, connectTimeout: const Duration(seconds: 15)));
  final Dio _dio;
  static Future<Map<String, dynamic>> pair(String siteUrl, String code, String deviceId) async {
    final base = siteUrl.replaceAll(RegExp(r'/$'), '');
    final response = await Dio(BaseOptions(baseUrl: '$base/wp-json/woo-manager/v1', connectTimeout: const Duration(seconds: 15))).post('/pair', data: {'code': code, 'device_id': deviceId, 'device_name': 'Woo Manager Android'});
    return Map<String, dynamic>.from(response.data as Map);
  }
  Future<Map<String, dynamic>> health() async => Map<String, dynamic>.from((await _dio.get('/health')).data as Map);
  Future<List<dynamic>> orders() async => (await _dio.get('/orders')).data as List<dynamic>;
  Future<Map<String, dynamic>> registerShipment(int orderId, Map<String, dynamic> options) async => Map<String, dynamic>.from((await _dio.post('/tapin/register/$orderId', data: options)).data as Map);
  Future<Map<String, dynamic>> shipmentPdf(List<String> ids, {required String type}) async => Map<String, dynamic>.from((await _dio.post('/tapin/pdf', data: {'ids': ids, 'type': type})).data as Map);
}
