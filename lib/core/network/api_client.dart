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
  Future<Map<String, dynamic>> order(int orderId) async => Map<String, dynamic>.from((await _dio.get('/orders/$orderId')).data as Map);
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async => Map<String, dynamic>.from((await _dio.patch('/orders/$orderId', data: {'status': status})).data as Map);
  Future<Map<String, dynamic>> addOrderNote(int orderId, String content, {bool customerNote = false}) async {
    final response = await _dio.post('/orders/$orderId/notes', data: {'content': content, 'customer_note': customerNote});
    return Map<String, dynamic>.from((response.data as Map)['order'] as Map);
  }
  Future<Map<String, dynamic>> refundOrder(int orderId, {required double amount, required String reason, required bool refundPayment, required bool restockItems}) async {
    final response = await _dio.post('/orders/$orderId/refunds', data: {'amount': amount, 'reason': reason, 'refund_payment': refundPayment, 'restock_items': restockItems, 'confirm': true});
    return Map<String, dynamic>.from((response.data as Map)['order'] as Map);
  }
  Future<Map<String, dynamic>> products({String search = '', int page = 1}) async => Map<String, dynamic>.from((await _dio.get('/products', queryParameters: {'search': search, 'page': page, 'limit': 30})).data as Map);
  Future<Map<String, dynamic>> product(int productId) async => Map<String, dynamic>.from((await _dio.get('/products/$productId')).data as Map);
  Future<Map<String, dynamic>> updateProduct(int productId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/products/$productId', data: data)).data as Map);
  Future<Map<String, dynamic>> updateVariation(int productId, int variationId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/products/$productId/variations/$variationId', data: data)).data as Map);
  Future<Map<String, dynamic>> customers({String search = '', int page = 1}) async => Map<String, dynamic>.from((await _dio.get('/customers', queryParameters: {'search': search, 'page': page, 'limit': 30})).data as Map);
  Future<Map<String, dynamic>> customer(int customerId) async => Map<String, dynamic>.from((await _dio.get('/customers/$customerId')).data as Map);
  Future<Map<String, dynamic>> updateCustomer(int customerId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/customers/$customerId', data: data)).data as Map);
  Future<Map<String, dynamic>> registerShipment(int orderId, Map<String, dynamic> options) async => Map<String, dynamic>.from((await _dio.post('/tapin/register/$orderId', data: options)).data as Map);
  Future<Map<String, dynamic>> shipmentPdf(List<String> ids, {required String type}) async => Map<String, dynamic>.from((await _dio.post('/tapin/pdf', data: {'ids': ids, 'type': type})).data as Map);
}
