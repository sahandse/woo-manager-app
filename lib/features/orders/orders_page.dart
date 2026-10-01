import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/format/persian_digits.dart';
import '../../core/network/api_client.dart';
import 'order_detail_page.dart';

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

  Future<void> _load() async {
    final next = widget.client.ordersResult(status: _status);
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  String _error(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return '${data['message']}';
      final code = error.response?.statusCode;
      if (code == 401 || code == 403) {
        return 'دسترسی این دستگاه به فروشگاه معتبر نیست. دوباره اتصال اپ را برقرار کنید.';
      }
      if (code == 404) {
        return 'API سفارش‌ها پیدا نشد. افزونه Woo Manager را به نسخه ۱.۲.۲ یا جدیدتر ارتقا دهید.';
      }
      if (code != null) return 'دریافت سفارش‌ها با خطای $code انجام نشد.';
      return 'ارتباط با فروشگاه برقرار نشد. اینترنت و آدرس سایت را بررسی کنید.';
    }
    return error.toString().replaceFirst('FormatException: ', '');
  }

  int? _orderId(Map<String, dynamic> order) {
    final value = order['id'];
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('سفارش‌ها'),
          actions: [
            IconButton(
              tooltip: 'به‌روزرسانی',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'جستجو با شماره سفارش یا نام مشتری',
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: _statuses.entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _status == entry.key,
                          onSelected: (_) {
                            _status = entry.key;
                            _load();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(children: [
                      const SizedBox(height: 120),
                      Icon(Icons.cloud_off_rounded, size: 52, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_error(snapshot.error!), textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('تلاش دوباره'),
                        ),
                      ),
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
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 72),
                        Icon(Icons.receipt_long_outlined, size: 58, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          _search.isNotEmpty
                              ? 'سفارشی با این عبارت پیدا نشد.'
                              : _status.isNotEmpty
                                  ? 'سفارشی در این وضعیت وجود ندارد.'
                                  : 'هیچ سفارشی از ووکامرس دریافت نشد.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        if (_search.isEmpty && _status.isEmpty)
                          Text(
                            'تعداد ثبت‌شده در فروشگاه: ${(result['store_total'] ?? 0).fa}\n'
                            'نوع ذخیره‌سازی: ${result['storage'] ?? '-'} • افزونه ${result['plugin_version'] ?? '-'}',
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 18),
                        Center(
                          child: FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.sync_rounded),
                            label: const Text('دریافت دوباره از ووکامرس'),
                          ),
                        ),
                      ],
                    );
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
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: id, client: widget.client)),
                            );
                            if (mounted) _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(Icons.receipt_long_rounded),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('سفارش ${id.fa}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Text('${customer.isNotEmpty ? customer : 'مهمان'} • ${_statuses[status] ?? status}'),
                                    const SizedBox(height: 7),
                                    Text('$total $currency'.fa, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_left_rounded),
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
