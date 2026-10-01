import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../inventory/inventory_page.dart';
import '../orders/orders_page.dart';

class AttentionCenterPage extends StatefulWidget {
  const AttentionCenterPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<AttentionCenterPage> createState() => _AttentionCenterPageState();
}

class _AttentionCenterPageState extends State<AttentionCenterPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => future = widget.client.notifications());

  void _openFor(String type) {
    if (type == 'low_stock') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryPage(client: widget.client)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersPage(client: widget.client)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('نیازمند اقدام'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
        body: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')));
            final items = snapshot.data?['items'] as List? ?? const [];
            if (items.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.task_alt_rounded, size: 56), SizedBox(height: 12), Text('همه‌چیز مرتب است؛ مورد فوری وجود ندارد.') ]));
            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final n = Map<String, dynamic>.from(items[index] as Map);
                  final error = n['severity'] == 'error';
                  return Card(
                    child: ListTile(
                      onTap: () => _openFor('${n['type']}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(backgroundColor: (error ? Colors.red : Colors.orange).withValues(alpha: .12), child: Icon(error ? Icons.error_outline_rounded : Icons.priority_high_rounded, color: error ? Colors.red : Colors.orange)),
                      title: Text('${n['title']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: const Text('برای رسیدگی لمس کنید'),
                      trailing: Badge(label: Text('${n['count']}')),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}
