import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int days = 30;
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
        future = Future.wait([widget.client.reportSummary(days: days), widget.client.profit(days: days)]);
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('گزارش‌ها'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<int>(
              segments: const [ButtonSegment(value: 7, label: Text('۷ روز')), ButtonSegment(value: 30, label: Text('۳۰ روز')), ButtonSegment(value: 90, label: Text('۹۰ روز'))],
              selected: {days},
              onSelectionChanged: (v) {
                days = v.first;
                _load();
              },
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                if (snapshot.hasError) return Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('گزارش دریافت نشد: ${snapshot.error}')));
                final summary = snapshot.data![0];
                final profit = snapshot.data![1];
                final top = summary['top_products'] as List? ?? const [];
                final statuses = summary['statuses'] as List? ?? const [];
                return Column(children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      _Metric('فروش', '${summary['revenue']} ${summary['currency']}', Icons.payments_outlined),
                      _Metric('تعداد سفارش', '${summary['orders_count']}', Icons.receipt_long_outlined),
                      _Metric('میانگین سفارش', '${summary['average_order_value']} ${summary['currency']}', Icons.analytics_outlined),
                      _Metric('سود تقریبی', '${profit['profit']} ${profit['currency']}', Icons.trending_up_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('وضعیت سفارش‌ها', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ...statuses.whereType<Map>().where((s) => (s['count'] as num? ?? 0) > 0).map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Expanded(child: Text('${s['label']}')), Text('${s['count']}', style: const TextStyle(fontWeight: FontWeight.w800))]))),
                      ]),
                    ),
                  ),
                  if (top.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text('محصولات پرفروش', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          ...top.take(8).whereType<Map>().map((p) => ListTile(contentPadding: EdgeInsets.zero, title: Text('${p['name']}'), subtitle: Text('${p['revenue']} ${summary['currency']}'), trailing: Text('${p['quantity']} عدد'))),
                        ]),
                      ),
                    ),
                ]);
              },
            ),
          ],
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
            Icon(icon),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            Text(title),
          ]),
        ),
      );
}
