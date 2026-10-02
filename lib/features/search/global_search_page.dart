import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../customers/customer_detail_page.dart';
import '../orders/order_detail_page.dart';
import '../products/product_detail_page.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final search = TextEditingController();
  Timer? timer;
  Future<List<dynamic>>? future;

  @override
  void dispose() {
    timer?.cancel();
    search.dispose();
    super.dispose();
  }

  void _changed(String value) {
    timer?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() => future = null);
      return;
    }
    timer = Timer(const Duration(milliseconds: 350), () {
      setState(() => future = Future.wait([
            widget.client.products(search: q),
            widget.client.customers(search: q),
            widget.client.ordersResult(limit: 50),
          ]));
    });
  }

  int? _id(dynamic value) => value is num ? value.toInt() : int.tryParse('$value');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('جستجوی سراسری')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SearchBar(
                controller: search,
                autofocus: true,
                hintText: 'سفارش، محصول، SKU، مشتری یا موبایل',
                leading: const Icon(Icons.search_rounded),
                onChanged: _changed,
              ),
            ),
            Expanded(
              child: future == null
                  ? _Empty(icon: Icons.manage_search_rounded, text: 'هر چیزی را از فروشگاه در یک جا پیدا کن.')
                  : FutureBuilder<List<dynamic>>(
                      future: future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return _Empty(icon: Icons.cloud_off_outlined, text: 'جستجو انجام نشد. دوباره تلاش کن.');
                        final q = search.text.trim().toLowerCase();
                        final productData = Map<String, dynamic>.from(snapshot.data![0] as Map);
                        final customerData = Map<String, dynamic>.from(snapshot.data![1] as Map);
                        final orderData = Map<String, dynamic>.from(snapshot.data![2] as Map);
                        final products = (productData['items'] as List? ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
                        final customers = (customerData['items'] as List? ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
                        final orders = (orderData['items'] as List? ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).where((o) => '${o['id']} ${o['number'] ?? ''} ${o['customer'] ?? ''} ${o['phone'] ?? ''}'.toLowerCase().contains(q)).toList();
                        if (products.isEmpty && customers.isEmpty && orders.isEmpty) return _Empty(icon: Icons.search_off_rounded, text: 'نتیجه‌ای پیدا نشد.');
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            if (orders.isNotEmpty) _Section(title: 'سفارش‌ها', icon: Icons.receipt_long_outlined, children: orders.take(8).map((o) {
                              final id = _id(o['id']);
                              return ListTile(leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)), title: Text('سفارش #${o['number'] ?? id}'), subtitle: Text('${o['customer'] ?? 'مهمان'} • ${o['status'] ?? '-'}'), trailing: const Icon(Icons.chevron_left_rounded), onTap: id == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(client: widget.client, orderId: id))));
                            }).toList()),
                            if (products.isNotEmpty) _Section(title: 'محصولات', icon: Icons.inventory_2_outlined, children: products.take(10).map((p) {
                              final id = _id(p['id']);
                              return ListTile(leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)), title: Text('${p['name'] ?? 'محصول'}'), subtitle: Text('${p['sku'] ?? 'بدون SKU'} • ${p['price'] ?? ''}'), trailing: const Icon(Icons.chevron_left_rounded), onTap: id == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(client: widget.client, productId: id))));
                            }).toList()),
                            if (customers.isNotEmpty) _Section(title: 'مشتریان', icon: Icons.people_outline_rounded, children: customers.take(10).map((c) {
                              final id = _id(c['id']);
                              return ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)), title: Text('${c['name'] ?? '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'}'), subtitle: Text('${c['email'] ?? c['phone'] ?? ''}'), trailing: const Icon(Icons.chevron_left_rounded), onTap: id == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailPage(client: widget.client, customerId: id))));
                            }).toList()),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [Row(children: [Icon(icon), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900))]), const Divider(height: 20), ...children]),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 58, color: Theme.of(context).colorScheme.outline), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center)])));
}
