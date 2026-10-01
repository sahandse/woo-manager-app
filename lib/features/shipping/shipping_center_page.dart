import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../orders/order_detail_page.dart';
import '../orders/order_shipping_page.dart';

class ShippingCenterPage extends StatefulWidget {
  const ShippingCenterPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<ShippingCenterPage> createState() => _ShippingCenterPageState();
}

class _ShippingCenterPageState extends State<ShippingCenterPage> {
  late Future<Map<String, dynamic>> _future;
  String filter = 'ready';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = widget.client.ordersResult(limit: 100));

  bool _show(Map<String, dynamic> o) {
    final registered = o['tapin_order_id'] != null && '${o['tapin_order_id']}'.isNotEmpty;
    final tracking = '${o['tracking_number'] ?? ''}'.trim().isNotEmpty;
    final status = '${o['status'] ?? ''}';
    if (filter == 'registered') return registered;
    if (filter == 'tracking') return tracking;
    if (filter == 'ready') return !registered && ['processing', 'on-hold'].contains(status);
    return true;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مرکز ارسال'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
        body: Column(children: [
          SizedBox(
            height: 58,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _chip('ready', 'آماده ثبت'),
                _chip('registered', 'ثبت‌شده در تاپین'),
                _chip('tracking', 'دارای رهگیری'),
                _chip('all', 'همه'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')));
                final raw = snapshot.data?['items'] as List? ?? const [];
                final items = raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).where(_show).toList();
                if (items.isEmpty) return const Center(child: Text('مرسوله‌ای در این بخش وجود ندارد.'));
                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final o = items[index];
                      final id = (o['id'] as num).toInt();
                      final registered = o['tapin_order_id'] != null && '${o['tapin_order_id']}'.isNotEmpty;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(client: widget.client, orderId: id))),
                              leading: CircleAvatar(child: Icon(registered ? Icons.local_shipping_rounded : Icons.inventory_2_outlined)),
                              title: Text('سفارش #$id', style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text('${o['customer'] ?? 'مهمان'}\n${registered ? 'تاپین: ${o['tapin_order_id']}' : 'هنوز در تاپین ثبت نشده'}${o['tracking_number'] != null ? '\nرهگیری: ${o['tracking_number']}' : ''}'),
                              isThreeLine: true,
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderShippingPage(client: widget.client, orderId: id)));
                                if (mounted) _load();
                              },
                              icon: const Icon(Icons.local_shipping_outlined),
                              label: Text(registered ? 'جزئیات ارسال' : 'استعلام و ثبت در تاپین'),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      );

  Widget _chip(String value, String label) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ChoiceChip(label: Text(label), selected: filter == value, onSelected: (_) => setState(() => filter = value)),
      );
}
