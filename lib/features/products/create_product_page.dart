import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key, required this.client});
  final ApiClient client;

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final name = TextEditingController();
  final sku = TextEditingController();
  final regular = TextEditingController();
  final sale = TextEditingController();
  final stock = TextEditingController();
  final weight = TextEditingController();
  final shortDescription = TextEditingController();
  final description = TextEditingController();

  bool saving = false;
  bool manageStock = false;
  bool featured = false;
  String status = 'draft';
  String stockStatus = 'instock';
  int? categoryId;
  String? categoryName;
  int? imageId;
  String? imageUrl;

  @override
  void dispose() {
    for (final c in [name, sku, regular, sale, stock, weight, shortDescription, description]) {
      c.dispose();
    }
    super.dispose();
  }

  String _error(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] != null) return '${data['message']}';
    }
    return '$e';
  }

  Future<void> _pickCategory() async {
    try {
      final raw = await widget.client.categories();
      if (!mounted) return;
      final items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: ListView(
            children: [
              const ListTile(title: Text('انتخاب دسته‌بندی')),
              ...items.map((item) => ListTile(
                    title: Text('${item['name'] ?? item['title'] ?? '-'}'),
                    onTap: () => Navigator.pop(context, item),
                  )),
            ],
          ),
        ),
      );
      if (selected != null) {
        final id = selected['id'];
        setState(() {
          categoryId = id is num ? id.toInt() : int.tryParse('$id');
          categoryName = '${selected['name'] ?? selected['title'] ?? ''}';
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    }
  }

  Future<void> _pickImage() async {
    try {
      final data = await widget.client.media();
      if (!mounted) return;
      final items = (data['items'] is List ? data['items'] as List : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final url = '${item['thumbnail'] ?? item['url'] ?? ''}';
              return InkWell(
                onTap: () => Navigator.pop(context, item),
                borderRadius: BorderRadius.circular(14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: url.isEmpty
                      ? const ColoredBox(color: Colors.black12, child: Icon(Icons.image_outlined))
                      : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
                ),
              );
            },
          ),
        ),
      );
      if (selected != null) {
        final id = selected['id'];
        setState(() {
          imageId = id is num ? id.toInt() : int.tryParse('$id');
          imageUrl = '${selected['thumbnail'] ?? selected['url'] ?? ''}';
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    }
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام محصول الزامی است.')));
      return;
    }
    setState(() => saving = true);
    try {
      final result = await widget.client.createProduct({
        'name': name.text.trim(),
        'sku': sku.text.trim(),
        'regular_price': regular.text.trim(),
        'sale_price': sale.text.trim(),
        'short_description': shortDescription.text.trim(),
        'description': description.text.trim(),
        'status': status,
        'featured': featured,
        'manage_stock': manageStock,
        'stock_quantity': int.tryParse(stock.text.trim()) ?? 0,
        'stock_status': stockStatus,
        'weight': weight.text.trim(),
        'category_ids': [if (categoryId != null) categoryId],
        if (imageId != null) 'image_id': imageId,
      });
      if (!mounted) return;
      final id = result['id'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('محصول #$id ساخته شد.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('محصول جدید'),
          actions: [FilledButton(onPressed: saving ? null : _save, child: const Text('ساخت محصول'))],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (saving) const LinearProgressIndicator(),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                        clipBehavior: Clip.antiAlias,
                        child: imageUrl == null || imageUrl!.isEmpty
                            ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 38), SizedBox(height: 8), Text('انتخاب تصویر از رسانه‌ها')])
                            : Image.network(imageUrl!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: name, decoration: const InputDecoration(labelText: 'نام محصول *')),
                    TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU')),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(categoryName ?? 'دسته‌بندی'),
                      subtitle: const Text('برای انتخاب دسته‌بندی بزنید'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: _pickCategory,
                    ),
                    TextField(controller: shortDescription, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'توضیح کوتاه')),
                    TextField(controller: description, minLines: 3, maxLines: 7, decoration: const InputDecoration(labelText: 'توضیحات کامل')),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [Expanded(child: TextField(controller: regular, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت اصلی'))), const SizedBox(width: 10), Expanded(child: TextField(controller: sale, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت فروش ویژه')))]),
                  TextField(controller: weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'وزن محصول', helperText: 'طبق واحد وزن تنظیم‌شده در ووکامرس')),
                ]),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  SwitchListTile(contentPadding: EdgeInsets.zero, value: manageStock, onChanged: (v) => setState(() => manageStock = v), title: const Text('مدیریت موجودی')),
                  if (manageStock) TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'تعداد موجودی')),
                  DropdownButtonFormField<String>(value: stockStatus, decoration: const InputDecoration(labelText: 'وضعیت موجودی'), items: const [DropdownMenuItem(value: 'instock', child: Text('موجود')), DropdownMenuItem(value: 'outofstock', child: Text('ناموجود')), DropdownMenuItem(value: 'onbackorder', child: Text('پیش‌خرید'))], onChanged: (v) => setState(() => stockStatus = v!)),
                  DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'وضعیت انتشار'), items: const [DropdownMenuItem(value: 'draft', child: Text('پیش‌نویس')), DropdownMenuItem(value: 'publish', child: Text('منتشرشده')), DropdownMenuItem(value: 'pending', child: Text('در انتظار بررسی')), DropdownMenuItem(value: 'private', child: Text('خصوصی'))], onChanged: (v) => setState(() => status = v!)),
                  SwitchListTile(contentPadding: EdgeInsets.zero, value: featured, onChanged: (v) => setState(() => featured = v), title: const Text('محصول ویژه')),
                ]),
              ),
            ),
          ],
        ),
      );
}
