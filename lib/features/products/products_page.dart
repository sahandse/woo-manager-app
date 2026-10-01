import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../catalog/catalog_page.dart';
import 'create_product_page.dart';
import 'product_detail_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<Map<String, dynamic>> _future;
  final _search = TextEditingController();
  Timer? _timer;
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _load() => setState(() => _future = widget.client.products(search: _search.text.trim()));
  void _changed(String _) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 450), _load);
  }

  int? _id(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
  int _stockQty(Map<String, dynamic> p) => p['stock_quantity'] is num ? (p['stock_quantity'] as num).toInt() : int.tryParse('${p['stock_quantity'] ?? ''}') ?? 0;

  bool _show(Map<String, dynamic> p) {
    final status = '${p['stock_status'] ?? ''}';
    if (filter == 'in') return status == 'instock';
    if (filter == 'out') return status == 'outofstock';
    if (filter == 'low') return status == 'instock' && _stockQty(p) <= 5;
    return true;
  }

  Future<void> _create() async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => CreateProductPage(client: widget.client)));
    if (changed == true && mounted) _load();
  }

  Future<void> _quickEdit(Map<String, dynamic> p) async {
    final price = TextEditingController(text: '${p['price'] ?? ''}');
    final stock = TextEditingController(text: '${_stockQty(p)}');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('ویرایش سریع', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${p['name'] ?? ''}', maxLines: 2),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'موجودی'))),
          ]),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
        ]),
      ),
    );
    if (ok == true) {
      final qty = int.tryParse(stock.text.trim()) ?? 0;
      try {
        await widget.client.updateProduct((p['id'] as num).toInt(), {
          'regular_price': price.text.trim(),
          'manage_stock': true,
          'stock_quantity': qty,
          'stock_status': qty > 0 ? 'instock' : 'outofstock',
        });
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قیمت و موجودی ذخیره شد.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ویرایش انجام نشد: $e')));
      }
    }
    price.dispose();
    stock.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('محصولات'), actions: [
          IconButton(tooltip: 'محصول جدید', onPressed: _create, icon: const Icon(Icons.add_box_outlined)),
          IconButton(tooltip: 'مدیریت کاتالوگ', onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogPage(client: widget.client)));
            if (mounted) _load();
          }, icon: const Icon(Icons.tune_rounded)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ]),
        floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add_rounded), label: const Text('محصول جدید')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(controller: _search, hintText: 'نام، SKU یا محصول', leading: const Icon(Icons.search_rounded), onChanged: _changed),
          ),
          SizedBox(
            height: 50,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              _chip('all', 'همه'), _chip('in', 'موجود'), _chip('low', 'کم‌موجودی'), _chip('out', 'ناموجود'),
            ]),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: FilledButton(onPressed: _load, child: const Text('تلاش دوباره')));
                final raw = snapshot.data?['items'] as List? ?? const [];
                final items = raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).where(_show).toList();
                if (items.isEmpty) return const Center(child: Text('محصولی پیدا نشد.'));
                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = items[index];
                      final id = _id(p['id']);
                      final image = '${p['image'] ?? ''}'.trim();
                      final sku = '${p['sku'] ?? ''}'.trim();
                      return Card(
                        child: ListTile(
                          onTap: id == null ? null : () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(client: widget.client, productId: id)));
                            if (mounted) _load();
                          },
                          onLongPress: () => _quickEdit(p),
                          leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: image.isEmpty ? const SizedBox(width: 54, height: 54, child: Icon(Icons.inventory_2_outlined)) : Image.network(image, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 54, height: 54, child: Icon(Icons.broken_image_outlined)))),
                          title: Text('${p['name'] ?? 'محصول'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${p['price']?.toString().isNotEmpty == true ? p['price'] : 'بدون قیمت'} • ${_stock(p['stock_status'])}\n${sku.isEmpty ? 'بدون SKU' : sku}'),
                          isThreeLine: true,
                          trailing: IconButton(tooltip: 'ویرایش سریع', onPressed: () => _quickEdit(p), icon: const Icon(Icons.edit_outlined)),
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

  String _stock(dynamic value) => value == 'instock' ? 'موجود' : value == 'onbackorder' ? 'پیش‌خرید' : 'ناموجود';
}
