import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../messages/customer_messages_page.dart';
import 'order_detail_page.dart';
import 'order_shipping_page.dart';
import 'order_workflow_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<Map<String, dynamic>> future;
  String status = '';
  String search = '';
  static const labels = <String, String>{'': 'همه', 'pending': 'در انتظار پرداخت', 'processing': 'در حال انجام', 'on-hold': 'در انتظار بررسی', 'completed': 'تکمیل‌شده', 'cancelled': 'لغوشده', 'refunded': 'بازپرداخت‌شده', 'failed': 'ناموفق'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final next = widget.client.ordersResult(status: status, limit: 100);
    setState(() => future = next);
    try { await next; } catch (_) {}
  }

  int? _id(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
  String _error(Object e) {
    if (e is DioException && e.response?.data is Map && (e.response!.data as Map)['message'] != null) return '${(e.response!.data as Map)['message']}';
    return '$e';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('سفارشات'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(onChanged: (v) => setState(() => search = v.trim().toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'شماره سفارش یا نام مشتری')),
          ),
          SizedBox(
            height: 54,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              children: labels.entries.map((e) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(label: Text(e.value), selected: status == e.key, onSelected: (_) { status = e.key; _load(); }))).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: FutureBuilder<Map<String, dynamic>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return ListView(children: [const SizedBox(height: 130), const Icon(Icons.cloud_off_rounded, size: 52), const SizedBox(height: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Text(_error(snapshot.error!), textAlign: TextAlign.center)), const SizedBox(height: 16), Center(child: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')))]);
                  final raw = snapshot.data?['items'] as List? ?? const [];
                  final items = raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).where((o) {
                    if (search.isEmpty) return true;
                    return '${o['id']} ${o['number'] ?? ''} ${o['customer'] ?? ''}'.toLowerCase().contains(search);
                  }).toList();
                  if (items.isEmpty) return const Center(child: Text('سفارشی برای نمایش وجود ندارد.'));
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final o = items[index];
                      final id = _id(o['id']);
                      if (id == null) return const SizedBox.shrink();
                      final registered = o['tapin_order_id'] != null && '${o['tapin_order_id']}'.isNotEmpty;
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(client: widget.client, orderId: id)));
                            if (mounted) _load();
                          },
                          leading: CircleAvatar(child: Icon(registered ? Icons.local_shipping_rounded : Icons.receipt_long_rounded)),
                          title: Text('سفارش #$id', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${o['customer']?.toString().trim().isNotEmpty == true ? o['customer'] : 'مهمان'} • ${labels['${o['status']}'] ?? o['status']}\n${o['total'] ?? 0} ${o['currency'] ?? ''}${o['tracking_number'] != null ? '\nرهگیری: ${o['tracking_number']}' : ''}'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'workflow') await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderWorkflowPage(client: widget.client, orderId: id)));
                              if (value == 'shipping') await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderShippingPage(client: widget.client, orderId: id)));
                              if (value == 'message') await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerMessagesPage(client: widget.client, orderId: id)));
                              if (mounted) _load();
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'workflow', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.route_outlined), title: Text('فرآیند سفارش'))),
                              PopupMenuItem(value: 'shipping', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.local_shipping_outlined), title: Text('ارسال و تاپین'))),
                              PopupMenuItem(value: 'message', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.sms_outlined), title: Text('پیام به مشتری'))),
                            ],
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
