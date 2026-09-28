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
  Future<List<dynamic>> categories() async => (await _dio.get('/categories')).data as List<dynamic>;
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/categories', data: data)).data as Map);
  Future<Map<String, dynamic>> updateCategory(int categoryId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/categories/$categoryId', data: data)).data as Map);
  Future<Map<String, dynamic>> bulkProducts(List<int> ids, Map<String, dynamic> changes) async => Map<String, dynamic>.from((await _dio.post('/products/bulk', data: {'ids': ids, ...changes, 'confirm': true})).data as Map);
  Future<Map<String, dynamic>> customers({String search = '', int page = 1}) async => Map<String, dynamic>.from((await _dio.get('/customers', queryParameters: {'search': search, 'page': page, 'limit': 30})).data as Map);
  Future<Map<String, dynamic>> customer(int customerId) async => Map<String, dynamic>.from((await _dio.get('/customers/$customerId')).data as Map);
  Future<Map<String, dynamic>> updateCustomer(int customerId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/customers/$customerId', data: data)).data as Map);
  Future<Map<String, dynamic>> reportSummary({int days = 30}) async => Map<String, dynamic>.from((await _dio.get('/reports/summary', queryParameters: {'days': days})).data as Map);
  Future<Map<String, dynamic>> coupons({String search = ''}) async => Map<String, dynamic>.from((await _dio.get('/coupons', queryParameters: {'search': search, 'limit': 50})).data as Map);
  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/coupons', data: data)).data as Map);
  Future<Map<String, dynamic>> updateCoupon(int couponId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/coupons/$couponId', data: data)).data as Map);
  Future<List<dynamic>> reviews({String status = 'all'}) async => (await _dio.get('/reviews', queryParameters: {'status': status})).data as List<dynamic>;
  Future<Map<String, dynamic>> updateReview(int reviewId, String status) async => Map<String, dynamic>.from((await _dio.patch('/reviews/$reviewId', data: {'status': status})).data as Map);
  Future<Map<String, dynamic>> notifications() async => Map<String, dynamic>.from((await _dio.get('/notifications')).data as Map);
  Future<Map<String, dynamic>> system() async => Map<String, dynamic>.from((await _dio.get('/system')).data as Map);
  Future<List<dynamic>> devices() async => (await _dio.get('/devices')).data as List<dynamic>;
  Future<void> revokeDevice(int id) async => _dio.post('/devices/$id/revoke', data: {'confirm': true});
  Future<Map<String, dynamic>> testTapin() async => Map<String, dynamic>.from((await _dio.post('/tests/tapin')).data as Map);
  Future<Map<String, dynamic>> testSms(String mobile) async => Map<String, dynamic>.from((await _dio.post('/tests/sms', data: {'mobile': mobile})).data as Map);
  Future<List<dynamic>> logs() async => (await _dio.get('/logs', queryParameters: {'limit': 100})).data as List<dynamic>;
  Future<Map<String, dynamic>> media() async => Map<String, dynamic>.from((await _dio.get('/media', queryParameters: {'limit': 50})).data as Map);
  Future<Map<String, dynamic>> uploadMedia(Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/media', data: data)).data as Map);
  Future<List<dynamic>> content(String type) async => (await _dio.get('/content', queryParameters: {'type': type})).data as List<dynamic>;
  Future<Map<String, dynamic>> updateContent(int id, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/content/$id', data: data)).data as Map);
  Future<Map<String, dynamic>> exportSales(int days, String format) async => Map<String, dynamic>.from((await _dio.post('/exports/sales', data: {'days': days, 'format': format})).data as Map);
  Future<Map<String, dynamic>> backup() async => Map<String, dynamic>.from((await _dio.post('/backup')).data as Map);
  Future<Map<String, dynamic>> restoreBackup(String contentBase64) async => Map<String, dynamic>.from((await _dio.post('/restore', data: {'content_base64': contentBase64, 'confirm': true})).data as Map);
  Future<Map<String, dynamic>> maintenance() async => Map<String, dynamic>.from((await _dio.get('/maintenance')).data as Map);
  Future<Map<String, dynamic>> registerShipment(int orderId, Map<String, dynamic> options) async => Map<String, dynamic>.from((await _dio.post('/tapin/register/$orderId', data: options)).data as Map);
  Future<Map<String, dynamic>> shipmentPdf(List<String> ids, {required String type}) async => Map<String, dynamic>.from((await _dio.post('/tapin/pdf', data: {'ids': ids, 'type': type})).data as Map);
}
