import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/theme_controller.dart';
import '../inventory/inventory_page.dart';
import '../more/more_page.dart';
import '../operations/workflow_center_page.dart';
import '../orders/order_detail_page.dart';
import '../orders/orders_page.dart';
import '../products/create_product_page.dart';
import '../products/products_page.dart';
import '../shipping/shipping_center_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.storeName, required this.client});
  final String storeName;
  final ApiClient client;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> report;
  late Future<Map<String, dynamic>> orders;
  int days = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
        report = widget.client.reportSummary(days: days);
        orders = widget.client.ordersResult(limit: 20);
      });

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _load());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.asset('assets/woo_manager_logo.png', fit: BoxFit.cover)),
          ),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.storeName, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('مرکز مدیریت فروشگاه', style: Theme.of(context).textTheme.bodySmall),
          ]),
          actions: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.mode,
              builder: (context, mode, _) => IconButton(
                tooltip: mode == ThemeMode.dark ? 'حالت روشن' : 'حالت تاریک',
                onPressed: ThemeController.toggle,
                icon: Icon(mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              ),
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('امروز چه کاری داریم؟', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _quickActions(),
              const SizedBox(height: 18),
              SegmentedButton<int>(
                segments: const [ButtonSegment(value: 7, label: Text('۷ روز')), ButtonSegment(value: 30, label: Text('۳۰ روز')), ButtonSegment(value: 90, label: Text('۹۰ روز'))],
                selected: {days},
                onSelectionChanged: (value) {
                  days = value.first;
                  _load();
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>>(
                future: report,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())));
                  if (snapshot.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('گزارش فروش دریافت نشد: ${snapshot.error}')));
                  final d = snapshot.data!;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      _Metric('فروش', '${d['revenue']} ${d['currency']}', Icons.payments_outlined),
                      _Metric('سفارش', '${d['orders_count']}', Icons.receipt_long_outlined),
                      _Metric('میانگین خرید', '${d['average_order_value']} ${d['currency']}', Icons.analytics_outlined),
                      _Metric('بازپرداخت', '${d['refunded']} ${d['currency']}', Icons.currency_exchange_rounded),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('آخرین سفارش‌ها', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                TextButton(onPressed: () => _open(OrdersPage(client: widget.client)), child: const Text('مشاهده همه')),
              ]),
              FutureBuilder<Map<String, dynamic>>(
                future: orders,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                  final raw = snapshot.data?['items'] as List? ?? const [];
                  final items = raw.whereType<Map>().take(6).map((m) => Map<String, dynamic>.from(m)).toList();
                  if (items.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(22), child: Text('سفارشی برای نمایش وجود ندارد.', textAlign: TextAlign.center)));
                  return Column(
                    children: items.map((o) {
                      final id = o['id'] is num ? (o['id'] as num).toInt() : int.tryParse('${o['id']}') ?? 0;
                      final registered = o['tapin_order_id'] != null;
                      return Card(
                        child: ListTile(
                          onTap: () => _open(OrderDetailPage(orderId: id, client: widget.client)),
                          leading: CircleAvatar(child: Icon(registered ? Icons.local_shipping_outlined : Icons.receipt_long_outlined)),
                          title: Text('سفارش #$id', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${o['customer'] ?? 'مهمان'} • ${o['status'] ?? '-'}\n${o['total'] ?? 0} ${o['currency'] ?? ''}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_left_rounded),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (index) {
            if (index == 1) _open(OrdersPage(client: widget.client));
            if (index == 2) _open(ProductsPage(client: widget.client));
            if (index == 3) _open(WorkflowCenterPage(client: widget.client));
            if (index == 4) _open(MorePage(client: widget.client));
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'خانه'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'سفارشات'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'محصولات'),
            NavigationDestination(icon: Icon(Icons.hub_outlined), label: 'عملیات'),
            NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'بیشتر'),
          ],
        ),
      );

  Widget _quickActions() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: .82,
        children: [
          _Quick(Icons.add_box_outlined, 'محصول جدید', () => _open(CreateProductPage(client: widget.client))),
          _Quick(Icons.local_shipping_outlined, 'مرکز ارسال', () => _open(ShippingCenterPage(client: widget.client))),
          _Quick(Icons.qr_code_scanner_rounded, 'انبار', () => _open(InventoryPage(client: widget.client))),
          _Quick(Icons.hub_outlined, 'نیازمند اقدام', () => _open(WorkflowCenterPage(client: widget.client))),
        ],
      );
}

class _Quick extends StatelessWidget {
  const _Quick(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, maxLines: 2)]),
          ),
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.title, this.value, this.icon);
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(icon, size: 20),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            Text(title),
          ]),
        ),
      );
}
