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

  Future<void> _quickCreate() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController(text: '1');
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 6, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.bolt_rounded)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('محصول سریع', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const Text('نام، قیمت و موجودی؛ بقیه را بعداً تکمیل کن.')]))]),
          const SizedBox(height: 18),
          TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'نام محصول *', prefixIcon: Icon(Icons.inventory_2_outlined))),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت'))), const SizedBox(width: 10), Expanded(child: TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'موجودی')))]),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.add_rounded), label: const Text('ساخت پیش‌نویس')),
        ]),
      ),
    );
    if (result == true && name.text.trim().isNotEmpty) {
      try {
        final qty = int.tryParse(stock.text.trim()) ?? 0;
        await widget.client.createProduct({'name': name.text.trim(), 'regular_price': price.text.trim(), 'status': 'draft', 'manage_stock': true, 'stock_quantity': qty, 'stock_status': qty > 0 ? 'instock' : 'outofstock'});
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('محصول سریع به‌صورت پیش‌نویس ساخته شد.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ساخت محصول انجام نشد: $e')));
      }
    }
    name.dispose();
    price.dispose();
    stock.dispose();
  }

  Future<void> _duplicate(Map<String, dynamic> summary) async {
    final id = _id(summary['id']);
    if (id == null) return;
    try {
      final p = await widget.client.product(id);
      final categories = p['category_ids'] is List ? p['category_ids'] as List : const [];
      await widget.client.createProduct({
        'name': '${p['name'] ?? summary['name'] ?? 'محصول'} - کپی',
        'type': p['type'] == 'variable' ? 'variable' : 'simple',
        'regular_price': p['regular_price'] ?? p['price'] ?? '',
        'sale_price': p['sale_price'] ?? '',
        'short_description': p['short_description'] ?? '',
        'description': p['description'] ?? '',
        'status': 'draft',
        'featured': false,
        'manage_stock': p['manage_stock'] == true,
        'stock_quantity': p['stock_quantity'] ?? 0,
        'stock_status': p['stock_status'] ?? 'instock',
        'weight': p['weight'] ?? '',
        'length': p['length'] ?? '',
        'width': p['width'] ?? '',
        'height': p['height'] ?? '',
        'category_ids': categories,
        if (p['image_id'] != null) 'image_id': p['image_id'],
      });
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('یک کپی پیش‌نویس از محصول ساخته شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('کپی محصول انجام نشد: $e')));
    }
  }

  Future<void> _quickEdit(Map<String, dynamic> p) async {
    final price = TextEditingController(text: '${p['price'] ?? ''}');
    final stock = TextEditingController(text: '${_stockQty(p)}');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 6, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('ویرایش سریع', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${p['name'] ?? ''}', maxLines: 2),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت'))), const SizedBox(width: 10), Expanded(child: TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'موجودی')))]),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
        ]),
      ),
    );
    if (ok == true) {
      final qty = int.tryParse(stock.text.trim()) ?? 0;
      try {
        await widget.client.updateProduct((p['id'] as num).toInt(), {'regular_price': price.text.trim(), 'manage_stock': true, 'stock_quantity': qty, 'stock_status': qty > 0 ? 'instock' : 'outofstock'});
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
          IconButton(tooltip: 'مدیریت کاتالوگ', onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogPage(client: widget.client)));
            if (mounted) _load();
          }, icon: const Icon(Icons.tune_rounded)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ]),
        floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add_rounded), label: const Text('محصول جدید')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.surfaceContainerHighest])),
              child: Column(children: [
                Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('کاتالوگ فروشگاه', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 3), const Text('محصول جدید، ویرایش سریع، کپی و کنترل موجودی')]))]),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: FilledButton.tonalIcon(onPressed: _quickCreate, icon: const Icon(Icons.bolt_rounded), label: const Text('محصول سریع'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: _create, icon: const Icon(Icons.auto_awesome_outlined), label: const Text('ساخت حرفه‌ای')))]),
              ]),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SearchBar(controller: _search, hintText: 'نام، SKU یا محصول', leading: const Icon(Icons.search_rounded), onChanged: _changed)),
          SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), children: [_chip('all', 'همه'), _chip('in', 'موجود'), _chip('low', 'کم‌موجودی'), _chip('out', 'ناموجود')])),
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final p = items[index];
                      final id = _id(p['id']);
                      final image = '${p['image'] ?? ''}'.trim();
                      final sku = '${p['sku'] ?? ''}'.trim();
                      final qty = _stockQty(p);
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: id == null ? null : () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(client: widget.client, productId: id)));
                            if (mounted) _load();
                          },
                          onLongPress: () => _quickEdit(p),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(16), child: image.isEmpty ? Container(width: 66, height: 66, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.inventory_2_outlined)) : Image.network(image, width: 66, height: 66, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 66, height: 66, child: Icon(Icons.broken_image_outlined)))),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${p['name'] ?? 'محصول'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 5),
                                Wrap(spacing: 6, runSpacing: 4, children: [_Badge(text: _stock(p['stock_status']), icon: Icons.inventory_outlined), if (p['stock_status'] == 'instock') _Badge(text: '$qty عدد', icon: Icons.numbers_rounded), if (sku.isNotEmpty) _Badge(text: sku, icon: Icons.qr_code_2_rounded)]),
                                const SizedBox(height: 6),
                                Text('${p['price']?.toString().isNotEmpty == true ? p['price'] : 'بدون قیمت'}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
                              ])),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _quickEdit(p);
                                  if (value == 'copy') _duplicate(p);
                                },
                                itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.edit_outlined), title: Text('ویرایش سریع'))), PopupMenuItem(value: 'copy', child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.copy_all_outlined), title: Text('کپی محصول')))],
                              ),
                            ]),
                          ),
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

  Widget _chip(String value, String label) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(label: Text(label), selected: filter == value, onSelected: (_) => setState(() => filter = value)));
  String _stock(dynamic value) => value == 'instock' ? 'موجود' : value == 'onbackorder' ? 'پیش‌خرید' : 'ناموجود';
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.icon});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13), const SizedBox(width: 4), Text(text, style: Theme.of(context).textTheme.labelSmall)]),
      );
}
