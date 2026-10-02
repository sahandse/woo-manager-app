import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_client.dart';
import 'product_barcode_scanner_page.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key, required this.client, this.quick = false});
  final ApiClient client;
  final bool quick;

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  static const _storage = FlutterSecureStorage();
  static const _draftKey = 'woo_manager_product_draft_v2';

  final name = TextEditingController();
  final sku = TextEditingController();
  final barcode = TextEditingController();
  final regular = TextEditingController();
  final sale = TextEditingController();
  final stock = TextEditingController();
  final lowStock = TextEditingController();
  final weight = TextEditingController();
  final length = TextEditingController();
  final width = TextEditingController();
  final height = TextEditingController();
  final brand = TextEditingController();
  final tags = TextEditingController();
  final colors = TextEditingController();
  final sizes = TextEditingController();
  final shortDescription = TextEditingController();
  final description = TextEditingController();

  int step = 0;
  bool saving = false;
  bool manageStock = true;
  bool featured = false;
  bool advancedOpen = false;
  bool restoring = true;
  String type = 'simple';
  String status = 'draft';
  String stockStatus = 'instock';
  String backorders = 'no';
  int? categoryId;
  String? categoryName;
  int? imageId;
  String? imageUrl;
  final List<int> galleryIds = [];
  final List<String> galleryUrls = [];
  Timer? _draftTimer;

  List<TextEditingController> get _controllers => [
        name,
        sku,
        barcode,
        regular,
        sale,
        stock,
        lowStock,
        weight,
        length,
        width,
        height,
        brand,
        tags,
        colors,
        sizes,
        shortDescription,
        description,
      ];

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) c.addListener(_scheduleDraft);
    _restoreDraft();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _scheduleDraft() {
    if (restoring) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), _saveDraft);
  }

  Future<void> _restoreDraft() async {
    try {
      final raw = await _storage.read(key: _draftKey);
      if (raw != null && raw.isNotEmpty) {
        final d = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        name.text = '${d['name'] ?? ''}';
        sku.text = '${d['sku'] ?? ''}';
        barcode.text = '${d['barcode'] ?? ''}';
        regular.text = '${d['regular'] ?? ''}';
        sale.text = '${d['sale'] ?? ''}';
        stock.text = '${d['stock'] ?? ''}';
        lowStock.text = '${d['low_stock'] ?? ''}';
        weight.text = '${d['weight'] ?? ''}';
        length.text = '${d['length'] ?? ''}';
        width.text = '${d['width'] ?? ''}';
        height.text = '${d['height'] ?? ''}';
        brand.text = '${d['brand'] ?? ''}';
        tags.text = '${d['tags'] ?? ''}';
        colors.text = '${d['colors'] ?? ''}';
        sizes.text = '${d['sizes'] ?? ''}';
        shortDescription.text = '${d['short_description'] ?? ''}';
        description.text = '${d['description'] ?? ''}';
        type = '${d['type'] ?? 'simple'}';
        status = '${d['status'] ?? 'draft'}';
        manageStock = d['manage_stock'] != false;
        stockStatus = '${d['stock_status'] ?? 'instock'}';
        backorders = '${d['backorders'] ?? 'no'}';
        featured = d['featured'] == true;
      }
    } catch (_) {
      // Ignore an unreadable local draft.
    }
    if (mounted) setState(() => restoring = false);
  }

  Future<void> _saveDraft() async {
    if (restoring) return;
    final data = {
      'name': name.text,
      'sku': sku.text,
      'barcode': barcode.text,
      'regular': regular.text,
      'sale': sale.text,
      'stock': stock.text,
      'low_stock': lowStock.text,
      'weight': weight.text,
      'length': length.text,
      'width': width.text,
      'height': height.text,
      'brand': brand.text,
      'tags': tags.text,
      'colors': colors.text,
      'sizes': sizes.text,
      'short_description': shortDescription.text,
      'description': description.text,
      'type': type,
      'status': status,
      'manage_stock': manageStock,
      'stock_status': stockStatus,
      'backorders': backorders,
      'featured': featured,
    };
    await _storage.write(key: _draftKey, value: jsonEncode(data));
  }

  Future<void> _clearDraft() async {
    await _storage.delete(key: _draftKey);
  }

  String _error(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] != null) return '${data['message']}';
    }
    return '$e';
  }

  List<String> _csv(String value) => value
      .split(RegExp(r'[,،\n]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              const ListTile(title: Text('انتخاب دسته‌بندی', style: TextStyle(fontWeight: FontWeight.w900))),
              ...items.map((item) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.category_outlined)),
                      title: Text('${item['name'] ?? item['title'] ?? '-'}'),
                      onTap: () => Navigator.pop(context, item),
                    ),
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
        _scheduleDraft();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    }
  }

  Future<List<Map<String, dynamic>>> _mediaItems() async {
    final data = await widget.client.media();
    return (data['items'] is List ? data['items'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _pickMainImage() async {
    try {
      final items = await _mediaItems();
      if (!mounted) return;
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        builder: (_) => _MediaGrid(items: items),
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

  Future<void> _pickGallery() async {
    try {
      final items = await _mediaItems();
      if (!mounted) return;
      final selected = <int>{...galleryIds};
      final result = await showModalBottomSheet<Set<int>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheet) => SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(child: Text('گالری محصول', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
                      FilledButton(onPressed: () => Navigator.pop(sheetContext, selected), child: Text('تأیید ${selected.length} تصویر')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final id = item['id'] is num ? (item['id'] as num).toInt() : int.tryParse('${item['id']}') ?? 0;
                      final url = '${item['thumbnail'] ?? item['url'] ?? ''}';
                      final active = selected.contains(id);
                      return InkWell(
                        onTap: () => setSheet(() => active ? selected.remove(id) : selected.add(id)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(16), child: url.isEmpty ? const ColoredBox(color: Colors.black12) : Image.network(url, fit: BoxFit.cover)),
                            if (active) Positioned(top: 6, right: 6, child: CircleAvatar(radius: 13, child: Text('${selected.toList().indexOf(id) + 1}'))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (result != null) {
        galleryIds
          ..clear()
          ..addAll(result);
        galleryUrls
          ..clear()
          ..addAll(items.where((m) {
            final id = m['id'] is num ? (m['id'] as num).toInt() : int.tryParse('${m['id']}') ?? 0;
            return result.contains(id);
          }).map((m) => '${m['thumbnail'] ?? m['url'] ?? ''}'));
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    }
  }

  Future<void> _scanBarcode() async {
    final value = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const ProductBarcodeScannerPage()));
    if (value == null || !mounted) return;
    setState(() {
      barcode.text = value;
      if (sku.text.trim().isEmpty) sku.text = value;
    });
  }

  void _autoSku() {
    final prefix = name.text.trim().isEmpty ? 'PRD' : name.text.trim().replaceAll(RegExp(r'\s+'), '-').toUpperCase();
    sku.text = '${prefix.substring(0, prefix.length.clamp(1, 8))}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  List<Map<String, dynamic>> _variations() {
    final colorList = _csv(colors.text);
    final sizeList = _csv(sizes.text);
    final result = <Map<String, dynamic>>[];
    if (colorList.isEmpty && sizeList.isEmpty) return result;
    final cs = colorList.isEmpty ? [''] : colorList;
    final ss = sizeList.isEmpty ? [''] : sizeList;
    for (final color in cs) {
      for (final size in ss) {
        result.add({
          'attributes': {
            if (color.isNotEmpty) 'رنگ': color,
            if (size.isNotEmpty) 'سایز': size,
          },
          'regular_price': regular.text.trim(),
          'sale_price': sale.text.trim(),
          'manage_stock': manageStock,
          'stock_quantity': int.tryParse(stock.text.trim()) ?? 0,
        });
      }
    }
    return result;
  }

  Future<void> _save({String? forceStatus}) async {
    if (name.text.trim().isEmpty) {
      setState(() => step = 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام محصول الزامی است.')));
      return;
    }
    setState(() => saving = true);
    try {
      final colorList = _csv(colors.text);
      final sizeList = _csv(sizes.text);
      final attributes = <Map<String, dynamic>>[
        if (colorList.isNotEmpty) {'name': 'رنگ', 'options': colorList},
        if (sizeList.isNotEmpty) {'name': 'سایز', 'options': sizeList},
      ];
      final result = await widget.client.createProduct({
        'name': name.text.trim(),
        'type': type,
        'sku': sku.text.trim(),
        'barcode': barcode.text.trim(),
        'brand': brand.text.trim(),
        'regular_price': regular.text.trim(),
        'sale_price': sale.text.trim(),
        'short_description': shortDescription.text.trim(),
        'description': description.text.trim(),
        'status': forceStatus ?? status,
        'featured': featured,
        'manage_stock': manageStock,
        'stock_quantity': int.tryParse(stock.text.trim()) ?? 0,
        'low_stock_amount': int.tryParse(lowStock.text.trim()) ?? 0,
        'stock_status': stockStatus,
        'backorders': backorders,
        'weight': weight.text.trim(),
        'length': length.text.trim(),
        'width': width.text.trim(),
        'height': height.text.trim(),
        'category_ids': [if (categoryId != null) categoryId],
        'tag_names': _csv(tags.text),
        if (imageId != null) 'image_id': imageId,
        'gallery_image_ids': galleryIds,
        if (type == 'variable') 'attributes': attributes,
        if (type == 'variable') 'variations': _variations(),
      });
      await _clearDraft();
      if (!mounted) return;
      final id = result['id'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('محصول #$id با موفقیت ساخته شد.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (restoring) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final progress = (step + 1) / 4;
    return Scaffold(
      appBar: AppBar(
        title: const Text('محصول جدید'),
        actions: [
          TextButton.icon(onPressed: saving ? null : () => _save(forceStatus: 'draft'), icon: const Icon(Icons.bookmark_add_outlined), label: const Text('ذخیره پیش‌نویس')),
        ],
      ),
      body: Column(
        children: [
          if (saving) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Column(
              children: [
                Row(children: [Expanded(child: Text(_stepTitle(step), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))), Text('${step + 1} از 4')]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 7)),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: ListView(
                key: ValueKey(step),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  if (step == 0) _basicStep(),
                  if (step == 1) _priceStep(),
                  if (step == 2) _shippingStep(),
                  if (step == 3) _reviewStep(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (step > 0) Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => step--), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('قبلی'))),
            if (step > 0) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: saving ? null : () => step < 3 ? setState(() => step++) : _save(),
                icon: Icon(step < 3 ? Icons.arrow_back_rounded : Icons.rocket_launch_outlined),
                label: Text(step < 3 ? 'ادامه' : status == 'publish' ? 'انتشار محصول' : 'ساخت محصول'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(int index) => const ['اطلاعات پایه', 'قیمت و موجودی', 'ارسال و ویژگی‌ها', 'بررسی و انتشار'][index];

  Widget _basicStep() => Column(
        children: [
          _HeroCard(
            title: 'محصولت را معرفی کن',
            subtitle: 'اول تصویر، نام و نوع محصول را مشخص کن. بقیه تنظیمات مرحله‌به‌مرحله نمایش داده می‌شوند.',
            icon: Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                InkWell(
                  onTap: _pickMainImage,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl == null || imageUrl!.isEmpty
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 44), SizedBox(height: 8), Text('انتخاب تصویر اصلی')])
                        : Image.network(imageUrl!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _pickGallery, icon: const Icon(Icons.photo_library_outlined), label: Text('گالری (${galleryIds.length})'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: _scanBarcode, icon: const Icon(Icons.qr_code_scanner_rounded), label: const Text('اسکن بارکد')))]),
                const SizedBox(height: 14),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'نام محصول *', prefixIcon: Icon(Icons.inventory_2_outlined))),
                const SizedBox(height: 10),
                SegmentedButton<String>(segments: const [ButtonSegment(value: 'simple', label: Text('ساده'), icon: Icon(Icons.sell_outlined)), ButtonSegment(value: 'variable', label: Text('متغیر'), icon: Icon(Icons.account_tree_outlined))], selected: {type}, onSelectionChanged: (v) => setState(() => type = v.first)),
                const SizedBox(height: 10),
                ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.category_outlined)), title: Text(categoryName ?? 'دسته‌بندی محصول'), subtitle: const Text('برای انتخاب بزنید'), trailing: const Icon(Icons.chevron_left_rounded), onTap: _pickCategory),
                TextField(controller: shortDescription, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'توضیح کوتاه', alignLabelWithHint: true)),
                const SizedBox(height: 10),
                TextField(controller: description, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'توضیحات کامل', alignLabelWithHint: true)),
              ]),
            ),
          ),
        ],
      );

  Widget _priceStep() => Column(
        children: [
          _HeroCard(title: 'قیمت‌گذاری سریع', subtitle: 'قیمت، موجودی، SKU و هشدار کمبود موجودی را از یکجا تنظیم کن.', icon: Icons.payments_outlined),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [Expanded(child: TextField(controller: regular, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت اصلی'))), const SizedBox(width: 10), Expanded(child: TextField(controller: sale, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت ویژه')))]),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU'))), IconButton.filledTonal(tooltip: 'ساخت SKU خودکار', onPressed: _autoSku, icon: const Icon(Icons.auto_fix_high_outlined))]),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: TextField(controller: barcode, decoration: const InputDecoration(labelText: 'بارکد'))), IconButton.filledTonal(onPressed: _scanBarcode, icon: const Icon(Icons.qr_code_scanner_rounded))]),
                SwitchListTile(contentPadding: EdgeInsets.zero, value: manageStock, onChanged: (v) => setState(() => manageStock = v), title: const Text('مدیریت موجودی'), subtitle: const Text('تعداد موجودی مستقیماً با ووکامرس همگام می‌شود')),
                if (manageStock) ...[
                  Row(children: [Expanded(child: TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'تعداد موجودی'))), const SizedBox(width: 10), Expanded(child: TextField(controller: lowStock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'هشدار موجودی کم')))]),
                  const SizedBox(height: 10),
                ],
                DropdownButtonFormField<String>(value: stockStatus, decoration: const InputDecoration(labelText: 'وضعیت موجودی'), items: const [DropdownMenuItem(value: 'instock', child: Text('موجود')), DropdownMenuItem(value: 'outofstock', child: Text('ناموجود')), DropdownMenuItem(value: 'onbackorder', child: Text('پیش‌خرید'))], onChanged: (v) => setState(() => stockStatus = v!)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(value: backorders, decoration: const InputDecoration(labelText: 'فروش در صورت اتمام موجودی'), items: const [DropdownMenuItem(value: 'no', child: Text('غیرفعال')), DropdownMenuItem(value: 'notify', child: Text('فعال + اطلاع به مشتری')), DropdownMenuItem(value: 'yes', child: Text('فعال'))], onChanged: (v) => setState(() => backorders = v!)),
              ]),
            ),
          ),
        ],
      );

  Widget _shippingStep() => Column(
        children: [
          _HeroCard(title: 'ارسال و ویژگی‌ها', subtitle: 'وزن و ابعاد برای محاسبه ارسال دقیق‌تر؛ رنگ و سایز برای محصول متغیر.', icon: Icons.local_shipping_outlined),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                TextField(controller: weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'وزن محصول')),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: TextField(controller: length, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'طول'))), const SizedBox(width: 8), Expanded(child: TextField(controller: width, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عرض'))), const SizedBox(width: 8), Expanded(child: TextField(controller: height, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ارتفاع')))]),
                const SizedBox(height: 10),
                TextField(controller: brand, decoration: const InputDecoration(labelText: 'برند', prefixIcon: Icon(Icons.verified_outlined))),
                const SizedBox(height: 10),
                TextField(controller: tags, decoration: const InputDecoration(labelText: 'برچسب‌ها', helperText: 'با ویرگول جدا کن؛ مثلاً جدید، پرفروش، تابستانی')),
              ]),
            ),
          ),
          if (type == 'variable') ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Row(children: [Icon(Icons.account_tree_outlined), SizedBox(width: 8), Text('تنوع محصول', style: TextStyle(fontWeight: FontWeight.w900))]),
                  const SizedBox(height: 12),
                  TextField(controller: colors, decoration: const InputDecoration(labelText: 'رنگ‌ها', helperText: 'مثلاً مشکی، سفید، قرمز')),
                  const SizedBox(height: 10),
                  TextField(controller: sizes, decoration: const InputDecoration(labelText: 'سایزها', helperText: 'مثلاً S, M, L یا 36، 38، 40')),
                  const SizedBox(height: 10),
                  Text('${_variations().length} ترکیب به‌صورت خودکار ساخته می‌شود.', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              initiallyExpanded: advancedOpen,
              onExpansionChanged: (v) => advancedOpen = v,
              leading: const Icon(Icons.tune_rounded),
              title: const Text('تنظیمات بیشتر', style: TextStyle(fontWeight: FontWeight.w800)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [SwitchListTile(contentPadding: EdgeInsets.zero, value: featured, onChanged: (v) => setState(() => featured = v), title: const Text('محصول ویژه'))],
            ),
          ),
        ],
      );

  Widget _reviewStep() {
    final discount = _discount();
    return Column(
      children: [
        _HeroCard(title: 'همه‌چیز آماده است', subtitle: 'قبل از انتشار یک نگاه سریع به اطلاعات محصول بنداز.', icon: Icons.task_alt_rounded),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(width: 88, height: 88, child: imageUrl == null || imageUrl!.isEmpty ? const ColoredBox(color: Colors.black12, child: Icon(Icons.inventory_2_outlined)) : Image.network(imageUrl!, fit: BoxFit.cover))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name.text.trim().isEmpty ? 'بدون نام' : name.text.trim(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(type == 'variable' ? 'محصول متغیر • ${_variations().length} تنوع' : 'محصول ساده'), if (categoryName != null) Text(categoryName!, style: Theme.of(context).textTheme.bodySmall)])),
              ]),
              const Divider(height: 28),
              _reviewRow('قیمت اصلی', regular.text.isEmpty ? '-' : regular.text),
              _reviewRow('قیمت ویژه', sale.text.isEmpty ? '-' : sale.text),
              if (discount != null) _reviewRow('درصد تخفیف', '$discount٪'),
              _reviewRow('موجودی', manageStock ? (stock.text.isEmpty ? '0' : stock.text) : 'مدیریت نمی‌شود'),
              _reviewRow('SKU', sku.text.isEmpty ? '-' : sku.text),
              _reviewRow('بارکد', barcode.text.isEmpty ? '-' : barcode.text),
              _reviewRow('وزن', weight.text.isEmpty ? '-' : weight.text),
              _reviewRow('تصاویر گالری', '${galleryIds.length}'),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'وضعیت نهایی'), items: const [DropdownMenuItem(value: 'draft', child: Text('ذخیره به‌عنوان پیش‌نویس')), DropdownMenuItem(value: 'publish', child: Text('انتشار در فروشگاه')), DropdownMenuItem(value: 'pending', child: Text('در انتظار بررسی')), DropdownMenuItem(value: 'private', child: Text('خصوصی'))], onChanged: (v) => setState(() => status = v!)),
              const SizedBox(height: 10),
              Text('Draft این فرم به‌صورت خودکار روی دستگاه ذخیره شده و بعد از ساخت موفق محصول پاک می‌شود.', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      ],
    );
  }

  int? _discount() {
    final r = double.tryParse(regular.text.replaceAll(',', ''));
    final s = double.tryParse(sale.text.replaceAll(',', ''));
    if (r == null || s == null || r <= 0 || s >= r) return null;
    return (((r - s) / r) * 100).round();
  }

  Widget _reviewRow(String title, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Expanded(child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))), Expanded(child: Text(value, textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w800)))]),
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.surfaceContainerHighest]),
        ),
        child: Row(children: [CircleAvatar(radius: 24, backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, child: Icon(icon)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle)]))]),
      );
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final url = '${item['thumbnail'] ?? item['url'] ?? ''}';
              return InkWell(
                onTap: () => Navigator.pop(context, item),
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(borderRadius: BorderRadius.circular(16), child: url.isEmpty ? const ColoredBox(color: Colors.black12, child: Icon(Icons.image_outlined)) : Image.network(url, fit: BoxFit.cover)),
              );
            },
          ),
        ),
      );
}
