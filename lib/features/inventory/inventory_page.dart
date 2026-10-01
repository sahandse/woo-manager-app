import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/network/api_client.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late Future<Map<String, dynamic>> _future;
  String filter = 'low';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = widget.client.products());

  int _stock(Map<String, dynamic> p) {
    final value = p['stock_quantity'];
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  bool _show(Map<String, dynamic> p) {
    final status = '${p['stock_status'] ?? ''}';
    final qty = _stock(p);
    if (filter == 'out') return status == 'outofstock';
    if (filter == 'low') return status != 'outofstock' && qty <= 5;
    return true;
  }

  Future<void> _edit(Map<String, dynamic> p) async {
    final controller = TextEditingController(text: '${_stock(p)}');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${p['name']}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'موجودی جدید')),
            const SizedBox(height: 14),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره موجودی')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final qty = int.tryParse(controller.text.trim()) ?? 0;
      try {
        await widget.client.updateProduct((p['id'] as num).toInt(), {
          'manage_stock': true,
          'stock_quantity': qty,
          'stock_status': qty > 0 ? 'instock' : 'outofstock',
        });
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('موجودی محصول به‌روزرسانی شد.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تغییر موجودی انجام نشد: $e')));
      }
    }
    controller.dispose();
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const _StockScannerPage()));
    if (code == null || code.trim().isEmpty || !mounted) return;
    try {
      final result = await widget.client.products(search: code.trim());
      final items = result['items'] as List? ?? const [];
      final match = items.cast<dynamic>().whereType<Map>().map((m) => Map<String, dynamic>.from(m)).where((p) => '${p['sku'] ?? ''}'.trim() == code.trim()).toList();
      if (match.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('محصولی با SKU/بارکد $code پیدا نشد.')));
        return;
      }
      await _edit(match.first);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('جست‌وجوی کالا انجام نشد: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('انبار'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
        floatingActionButton: FloatingActionButton.extended(onPressed: _scan, icon: const Icon(Icons.qr_code_scanner_rounded), label: const Text('اسکن کالا')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('کم‌موجودی')),
                ButtonSegment(value: 'out', label: Text('ناموجود')),
                ButtonSegment(value: 'all', label: Text('همه')),
              ],
              selected: {filter},
              onSelectionChanged: (v) => setState(() => filter = v.first),
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
                if (items.isEmpty) return const Center(child: Text('موردی برای نمایش وجود ندارد.'));
                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = items[index];
                      final qty = _stock(p);
                      return Card(
                        child: ListTile(
                          onTap: () => _edit(p),
                          leading: CircleAvatar(child: Text('$qty')),
                          title: Text('${p['name'] ?? 'محصول'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('SKU: ${p['sku']?.toString().trim().isEmpty == false ? p['sku'] : '-'} • ${p['stock_status'] == 'outofstock' ? 'ناموجود' : qty <= 5 ? 'کم‌موجودی' : 'موجود'}'),
                          trailing: const Icon(Icons.edit_outlined),
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
}

class _StockScannerPage extends StatefulWidget {
  const _StockScannerPage();
  @override
  State<_StockScannerPage> createState() => _StockScannerPageState();
}

class _StockScannerPageState extends State<_StockScannerPage> {
  bool handled = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('اسکن SKU / بارکد')),
        body: MobileScanner(onDetect: (capture) {
          if (handled || capture.barcodes.isEmpty) return;
          final value = capture.barcodes.first.rawValue;
          if (value == null || value.trim().isEmpty) return;
          handled = true;
          Navigator.pop(context, value.trim());
        }),
      );
}
