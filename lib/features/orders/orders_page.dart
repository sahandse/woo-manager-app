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
  late Future<List<dynamic>> _future;
  String _status = '';

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
    _load();
  }

  void _load() => setState(() => _future = widget.client.orders(status: _status));

  String _error(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return '${data['message']}';
      if (error.response?.statusCode == 401) return 'اتصال این دستگاه منقضی شده است. دوباره با کد یک‌بارمصرف متصل شوید.';
      if (error.response?.statusCode == 404) return 'API سفارش‌ها پیدا نشد. افزونه Woo Manager را به نسخه جدید ارتقا دهید.';
      return 'ارتباط با فروشگاه برقرار نشد. اینترنت و آدرس سایت را بررسی کنید.';
    }
    return error.toString().replaceFirst('FormatException: ', '');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('سفارش‌ها'),
          actions: [IconButton(tooltip: 'به‌روزرسانی', onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: Column(children: [
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
              onRefresh: () async => _load(),
              child: FutureBuilder<List<dynamic>>(
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
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(_error(snapshot.error!), textAlign: TextAlign.center)),
                      const SizedBox(height: 18),
                      Center(child: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('تلاش دوباره'))),
                    ]);
                  }
                  final orders = snapshot.data ?? const [];
                  if (orders.isEmpty) return const Center(child: Text('سفارشی در این وضعیت وجود ندارد.'));
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = Map<String, dynamic>.from(orders[index] as Map);
                      final id = (order['id'] as num).toInt();
                      final status = '${order['status'] ?? ''}';
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: id, client: widget.client)));
                            _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.receipt_long_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('سفارش ${id.fa}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text('${order['customer']?.toString().trim().isNotEmpty == true ? order['customer'] : 'مهمان'} • ${_statuses[status] ?? status}'),
                                const SizedBox(height: 7),
                                Text('${order['total'].fa} ${order['currency'] ?? ''}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                              ])),
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
