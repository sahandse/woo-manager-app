import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import 'order_detail_page.dart';
import 'order_shipping_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<Map<String, dynamic>> _future;
  String _status = '';
  String _search = '';

  static const _statuses = <String, String>{
    '': 'همه',
    'pending': 'در انتظار پرداخت',
    'processing': 'در حال انجام',
    'on-hold': 'در انتظار بررسی',
    'completed': 'تکمیل‌شده',
    'cancelled': 'لغوشده',
    'refunded': 'بازپرداخت‌شده',
    'failed': 'ناموفق',
  };

  @override
  void initState() {
    super.initState();
    _future = widget.client.ordersResult();
  }

  String _fa(Object? value) => '${value ?? ''}'
      .replaceAll('0', '۰')
      .replaceAll('1', '۱')
      .replaceAll('2', '۲')
      .replaceAll('3', '۳')
      .replaceAll('4', '۴')
      .replaceAll('5', '۵')
      .replaceAll('6', '۶')
      .replaceAll('7', '۷')
      .replaceAll('8', '۸')
      .replaceAll('9', '۹');

  Future<void> _load() async {
    final next = widget.client.ordersResult(status: _status);
    setState(() => _future = next);
    try { await next; } catch (_) {}
  }

  String _error(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return '${data['message']}';
      final code = error.response?.statusCode;
      if (code == 401 || code == 403) return 'دسترسی این دستگاه به فروشگاه معتبر نیست. دوباره اتصال اپ را برقرار کنید.';
      if (code == 404) return 'API سفارش‌ها پیدا نشد. افزونه Woo Manager را به‌روزرسانی کنید.';
      if (code != null) return 'درخواست با خطای $code انجام نشد.';
      return 'ارتباط با فروشگاه برقرار نشد. اینترنت و آدرس سایت را بررسی کنید.';
    }
    return error.toString().replaceFirst('FormatException: ', '');
  }

  int? _orderId(Map<String, dynamic> order) {
    final value = order['id'];
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  Future<void> _message(int id) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('پیام به مشتری سفارش ${_fa(id)}'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'متن پیامک',
            hintText: 'مثلاً: سفارش شما آماده ارسال است.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ارسال پیام')),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (ok != true || text.isEmpty) return;
    try {
      await widget.client.sendOrderMessage(id, text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پیام برای مشتری ارسال شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    }
  }

  Future<void> _shipping(int id) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderShippingPage(client: widget.client, orderId: id)));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('سفارش‌ها'),
          actions: [IconButton(tooltip: 'به‌روزرسانی', onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'جستجو با شماره سفارش یا نام مشتری'),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: _statuses.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(label: Text(entry.value), selected: _status == entry.key, onSelected: (_) { _status = entry.key; _load(); }),
              )).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) {
                    return ListView(children: [
                      const SizedBox(height: 120),
                      Icon(Icons.cloud_off_rounded, size: 52, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 14),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(_error(snapshot.error!), textAlign: TextAlign.center)),
                      const SizedBox(height: 18),
                      Center(child: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('تلاش دوباره'))),
                    ]);
                  }

                  final result = snapshot.data ?? const <String, dynamic>{};
                  final source = result['items'];
                  final rawOrders = source is List ? source : const <dynamic>[];
                  final orders = <Map<String, dynamic>>[];
                  for (final raw in rawOrders) {
                    if (raw is! Map) continue;
                    final order = Map<String, dynamic>.from(raw);
                    if (_orderId(order) == null) continue;
                    if (_search.isNotEmpty) {
                      final haystack = '${order['id']} ${order['number'] ?? ''} ${order['customer'] ?? ''}'.toLowerCase();
                      if (!haystack.contains(_search)) continue;
                    }
                    orders.add(order);
                  }

                  if (orders.isEmpty) {
                    return ListView(padding: const EdgeInsets.all(24), children: [
                      const SizedBox(height: 72),
                      Icon(Icons.receipt_long_outlined, size: 58, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(_search.isNotEmpty ? 'سفارشی با این عبارت پیدا نشد.' : _status.isNotEmpty ? 'سفارشی در این وضعیت وجود ندارد.' : 'هیچ سفارشی از ووکامرس دریافت نشد.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (_search.isEmpty && _status.isEmpty) Text('تعداد ثبت‌شده در فروشگاه: ${_fa(result['store_total'] ?? 0)}\nنوع ذخیره‌سازی: ${result['storage'] ?? '-'} • افزونه ${result['plugin_version'] ?? '-'}', textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      Center(child: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.sync_rounded), label: const Text('دریافت دوباره از ووکامرس'))),
                    ]);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final id = _orderId(order)!;
                      final status = '${order['status'] ?? ''}';
                      final customer = '${order['customer'] ?? ''}'.trim();
                      final total = order['total'] ?? 0;
                      final currency = '${order['currency'] ?? ''}';
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: id, client: widget.client)));
                            if (mounted) _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.receipt_long_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('سفارش ${_fa(id)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text('${customer.isNotEmpty ? customer : 'مهمان'} • ${_statuses[status] ?? status}'),
                                const SizedBox(height: 7),
                                Text(_fa('$total $currency'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                              ])),
                              PopupMenuButton<String>(
                                tooltip: 'عملیات سفارش',
                                onSelected: (value) {
                                  if (value == 'message') _message(id);
                                  if (value == 'shipping') _shipping(id);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'shipping', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.local_shipping_outlined), title: Text('ارسال و تاپین'))),
                                  PopupMenuItem(value: 'message', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.sms_outlined), title: Text('پیام به مشتری'))),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ]),
      );
}
