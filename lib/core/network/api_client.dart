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
  Future<List<dynamic>> orders({int page = 1, int limit = 50, String status = ''}) async {
    final result = await ordersResult(page: page, limit: limit, status: status);
    return result['items'] as List<dynamic>;
  }
  Future<Map<String, dynamic>> ordersResult({int page = 1, int limit = 50, String status = ''}) async {
    final response = await _dio.get('/orders', queryParameters: {'page': page, 'limit': limit, 'envelope': 1, if (status.isNotEmpty) 'status': status});
    final data = response.data;
    if (data is List) return {'items': data, 'total': data.length, 'page': page, 'pages': 1};
    if (data is Map && data['items'] is List) return Map<String, dynamic>.from(data);
    throw const FormatException('پاسخ سفارش‌ها از افزونه معتبر نیست. افزونه Woo Manager را به‌روزرسانی کنید.');
  }
  Future<Map<String, dynamic>> order(int orderId) async => Map<String, dynamic>.from((await _dio.get('/orders/$orderId')).data as Map);
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async => Map<String, dynamic>.from((await _dio.patch('/orders/$orderId', data: {'status': status})).data as Map);
  Future<Map<String, dynamic>> addOrderNote(int orderId, String content, {bool customerNote = false}) async {
    final response = await _dio.post('/orders/$orderId/notes', data: {'content': content, 'customer_note': customerNote});
    return Map<String, dynamic>.from((response.data as Map)['order'] as Map);
  }
  Future<Map<String, dynamic>> sendOrderMessage(int orderId, String message) async => Map<String, dynamic>.from((await _dio.post('/orders/$orderId/message', data: {'message': message})).data as Map);
  Future<Map<String, dynamic>> orderMessageTemplates(int orderId) async => Map<String, dynamic>.from((await _dio.get('/orders/$orderId/message-templates')).data as Map);
  Future<Map<String, dynamic>> setShippingReady(int orderId, bool ready) async => Map<String, dynamic>.from((await _dio.post('/orders/$orderId/shipping-ready', data: {'ready': ready})).data as Map);
  Future<Map<String, dynamic>> refundOrder(int orderId, {required double amount, required String reason, required bool refundPayment, required bool restockItems}) async {
    final response = await _dio.post('/orders/$orderId/refunds', data: {'amount': amount, 'reason': reason, 'refund_payment': refundPayment, 'restock_items': restockItems, 'confirm': true});
    return Map<String, dynamic>.from((response.data as Map)['order'] as Map);
  }
  Future<Map<String, dynamic>> products({String search = '', int page = 1}) async => Map<String, dynamic>.from((await _dio.get('/products', queryParameters: {'search': search, 'page': page, 'limit': 30})).data as Map);
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/products', data: data)).data as Map);
  Future<Map<String, dynamic>> product(int productId) async => Map<String, dynamic>.from((await _dio.get('/products/$productId')).data as Map);
  Future<Map<String, dynamic>> updateProduct(int productId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/products/$productId', data: data)).data as Map);
  Future<Map<String, dynamic>> updateVariation(int productId, int variationId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/products/$productId/variations/$variationId', data: data)).data as Map);
  Future<Map<String, dynamic>> setupVariations(int productId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/products/$productId/variation-setup', data: {...data, 'confirm': true})).data as Map);
  Future<List<dynamic>> categories() async => (await _dio.get('/categories')).data as List<dynamic>;
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/categories', data: data)).data as Map);
  Future<Map<String, dynamic>> updateCategory(int categoryId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/categories/$categoryId', data: data)).data as Map);
  Future<Map<String, dynamic>> bulkProducts(List<int> ids, Map<String, dynamic> changes) async => Map<String, dynamic>.from((await _dio.post('/products/bulk', data: {'ids': ids, ...changes, 'confirm': true})).data as Map);
  Future<List<dynamic>> attributes() async => (await _dio.get('/attributes')).data as List<dynamic>;
  Future<Map<String, dynamic>> createAttribute(Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/attributes', data: data)).data as Map);
  Future<Map<String, dynamic>> updateAttribute(int id, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/attributes/$id', data: data)).data as Map);
  Future<List<dynamic>> attributeTerms(int id) async => (await _dio.get('/attributes/$id/terms')).data as List<dynamic>;
  Future<Map<String, dynamic>> createAttributeTerm(int id, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/attributes/$id/terms', data: data)).data as Map);
  Future<Map<String, dynamic>> updateAttributeTerm(int attributeId, int termId, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/attributes/$attributeId/terms/$termId', data: data)).data as Map);
  Future<Map<String, dynamic>> brands() async => Map<String, dynamic>.from((await _dio.get('/brands')).data as Map);
  Future<Map<String, dynamic>> createBrand(Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/brands', data: data)).data as Map);
  Future<Map<String, dynamic>> updateBrand(int id, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/brands/$id', data: data)).data as Map);
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
  Future<Map<String, dynamic>> tapinOptions(int orderId) async => Map<String, dynamic>.from((await _dio.get('/tapin/options/$orderId')).data as Map);
  Future<Map<String, dynamic>> registerShipment(int orderId, Map<String, dynamic> options) async => Map<String, dynamic>.from((await _dio.post('/tapin/register/$orderId', data: options)).data as Map);
  Future<Map<String, dynamic>> shipmentPdf(List<String> ids, {required String type}) async => Map<String, dynamic>.from((await _dio.post('/tapin/pdf', data: {'ids': ids, 'type': type})).data as Map);
  Future<Map<String, dynamic>> events({int since = 0}) async => Map<String, dynamic>.from((await _dio.get('/events', queryParameters: {'since': since})).data as Map);
  Future<Map<String, dynamic>> packing(int orderId) async => Map<String, dynamic>.from((await _dio.get('/packing/$orderId')).data as Map);
  Future<Map<String, dynamic>> scanPacking(int orderId, String code) async => Map<String, dynamic>.from((await _dio.post('/packing/$orderId/scan', data: {'code': code})).data as Map);
  Future<Map<String, dynamic>> completePacking(int orderId) async => Map<String, dynamic>.from((await _dio.post('/packing/$orderId/complete')).data as Map);
  Future<List<dynamic>> returns() async => (await _dio.get('/returns')).data as List<dynamic>;
  Future<Map<String, dynamic>> createReturn(Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.post('/returns', data: data)).data as Map);
  Future<Map<String, dynamic>> updateReturn(int id, String status, {String? resolution}) async => Map<String, dynamic>.from((await _dio.patch('/returns/$id', data: {'status': status, if (resolution != null) 'resolution': resolution})).data as Map);
  Future<Map<String, dynamic>> tapinQuote(int orderId, Map<String, dynamic> options) async => Map<String, dynamic>.from((await _dio.post('/tapin/quote/$orderId', data: options)).data as Map);
  Future<Map<String, dynamic>> thermalPdf(List<String> ids) async => Map<String, dynamic>.from((await _dio.post('/tapin/thermal', data: {'ids': ids})).data as Map);
  Future<Map<String, dynamic>> retryQueue({bool retry = false}) async => Map<String, dynamic>.from((retry ? await _dio.post('/retry-queue') : await _dio.get('/retry-queue')).data as Map);
  Future<Map<String, dynamic>> profit({int days = 30}) async => Map<String, dynamic>.from((await _dio.get('/reports/profit', queryParameters: {'days': days})).data as Map);
  Future<List<dynamic>> team() async => (await _dio.get('/team')).data as List<dynamic>;
  Future<List<dynamic>> audit() async => (await _dio.get('/audit', queryParameters: {'limit': 200})).data as List<dynamic>;
  Future<Map<String, dynamic>> preferences() async => Map<String, dynamic>.from((await _dio.get('/preferences')).data as Map);
  Future<Map<String, dynamic>> savePreferences(Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/preferences', data: data)).data as Map);
  Future<Map<String, dynamic>> releaseInfo() async => Map<String, dynamic>.from((await _dio.get('/release')).data as Map);
}
