import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/network/api_client.dart';
import 'order_shipping_page.dart';
import 'packing_page.dart';

class OrderWorkflowPage extends StatefulWidget {
  const OrderWorkflowPage({super.key, required this.client, required this.orderId});
  final ApiClient client;
  final int orderId;

  @override
  State<OrderWorkflowPage> createState() => _OrderWorkflowPageState();
}

class _OrderWorkflowPageState extends State<OrderWorkflowPage> {
  late Future<List<Map<String, dynamic>>> _future;
  int step = 0;
  bool busy = false;

  final review = <String, bool>{
    'items_checked': false,
    'address_checked': false,
    'phone_checked': false,
    'postcode_checked': false,
    'payment_checked': false,
    'notes_checked': false,
  };
  bool reviewLoaded = false;

  String carrier = 'post';
  final tipaxWeight = TextEditingController(text: '500');
  final tipaxBox = TextEditingController();
  final tipaxTracking = TextEditingController();
  String tipaxPay = 'cod';
  String tipaxContent = 'normal';

  List<Map<String, dynamic>> templates = [];
  String selectedTemplate = '';
  String selectedStatus = '';
  final smsMessage = TextEditingController();
  bool templatesLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    tipaxWeight.dispose();
    tipaxBox.dispose();
    tipaxTracking.dispose();
    smsMessage.dispose();
    super.dispose();
  }

  void _load() {
    reviewLoaded = false;
    templatesLoaded = false;
    setState(() {
      _future = Future.wait([
        widget.client.order(widget.orderId),
        widget.client.preparationState(widget.orderId),
      ]);
    });
  }

  String _error(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] != null) return '${data['message']}';
    }
    return '$e';
  }

  Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  List<Map<String, dynamic>> _maps(dynamic value) => value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

  void _fillReview(Map<String, dynamic> prep) {
    if (reviewLoaded) return;
    reviewLoaded = true;
    final saved = _map(prep['review']);
    for (final key in review.keys) {
      review[key] = saved[key] == true;
    }
    final shipping = _map(prep['shipping']);
    final savedCarrier = '${prep['carrier'] ?? shipping['carrier'] ?? ''}';
    if (savedCarrier == 'tipax' || savedCarrier == 'post') carrier = savedCarrier;
    if (shipping.isNotEmpty) {
      tipaxWeight.text = '${shipping['weight'] ?? tipaxWeight.text}';
      tipaxBox.text = '${shipping['box'] ?? ''}';
      tipaxTracking.text = '${shipping['tracking_number'] ?? prep['tracking_number'] ?? ''}';
      final pay = '${shipping['pay_type'] ?? ''}';
      if (['cod', 'prepaid'].contains(pay)) tipaxPay = pay;
      final content = '${shipping['content_type'] ?? ''}';
      if (['normal', 'fragile', 'liquid'].contains(content)) tipaxContent = content;
    }
  }

  Future<void> _saveReview() async {
    setState(() => busy = true);
    try {
      final result = await widget.client.savePreparationReview(widget.orderId, review);
      final saved = _map(result['review']);
      if (!mounted) return;
      final complete = saved['complete'] == true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(complete ? 'بررسی سفارش کامل شد.' : 'چک‌لیست ذخیره شد؛ چند مورد هنوز باقی مانده.')));
      if (complete) setState(() => step = 1);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _saveTipax() async {
    final weight = int.tryParse(tipaxWeight.text.trim()) ?? 0;
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وزن مرسوله را به گرم وارد کن.')));
      return;
    }
    setState(() => busy = true);
    try {
      await widget.client.saveManualShipment(widget.orderId, {
        'carrier': 'tipax',
        'weight': weight,
        'box': tipaxBox.text.trim(),
        'pay_type': tipaxPay,
        'content_type': tipaxContent,
        'tracking_number': tipaxTracking.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اطلاعات ارسال تیپاکس روی سفارش ذخیره شد.')));
      setState(() => step = 2);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sharePreparationPdf(String type) async {
    setState(() => busy = true);
    try {
      final result = await widget.client.preparationPdf(widget.orderId, type);
      final encoded = '${result['content_base64'] ?? ''}';
      if (encoded.isEmpty) throw const FormatException('PDF دریافت نشد.');
      await Printing.sharePdf(bytes: base64Decode(encoded), filename: '${result['filename'] ?? 'order.pdf'}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF ساخته نشد: ${_error(e)}')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openPostShipping() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderShippingPage(client: widget.client, orderId: widget.orderId)));
    if (!mounted) return;
    setState(() => step = 2);
    _load();
  }

  Future<void> _loadTemplates(Map<String, dynamic> order) async {
    if (templatesLoaded) return;
    templatesLoaded = true;
    try {
      final data = await widget.client.orderMessageTemplates(widget.orderId);
      if (!mounted) return;
      final next = _maps(data['items']);
      setState(() {
        templates = next;
        if (next.isNotEmpty) {
          selectedTemplate = '${next.first['key'] ?? ''}';
          selectedStatus = '${next.first['status'] ?? order['status'] ?? ''}';
          smsMessage.text = '${next.first['message'] ?? ''}';
        }
      });
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _sendSmsAndStatus() async {
    if (smsMessage.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('متن پیامک خالی است.')));
      return;
    }
    setState(() => busy = true);
    try {
      if (selectedStatus.isNotEmpty) await widget.client.updateOrderStatus(widget.orderId, selectedStatus);
      await widget.client.sendOrderMessage(widget.orderId, smsMessage.text.trim());
      await widget.client.setShippingReady(widget.orderId, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وضعیت سفارش و پیامک مشتری انجام شد.')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('آماده‌سازی سفارش #${widget.orderId}'),
          actions: [IconButton(onPressed: busy ? null : _load, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error(snapshot.error!))));
            final order = snapshot.data![0];
            final prep = snapshot.data![1];
            _fillReview(prep);
            if (step == 2 && !templatesLoaded) WidgetsBinding.instance.addPostFrameCallback((_) => _loadTemplates(order));
            return Column(
              children: [
                if (busy) const LinearProgressIndicator(),
                _StepHeader(step: step, onTap: (v) => setState(() => step = v)),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (step) {
                      0 => _reviewPage(order),
                      1 => _shippingPage(order, prep),
                      _ => _messagePage(order),
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _reviewPage(Map<String, dynamic> order) {
    final billing = _map(order['billing']);
    final shipping = _map(order['shipping']);
    final items = _maps(order['items']);
    final address = '${shipping['state'] ?? billing['state'] ?? ''} ${shipping['city'] ?? billing['city'] ?? ''} ${shipping['address_1'] ?? billing['address_1'] ?? ''}'.trim();
    final phone = '${shipping['phone'] ?? billing['phone'] ?? ''}'.trim();
    final postcode = '${shipping['postcode'] ?? billing['postcode'] ?? ''}'.trim();
    return ListView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _Hero(icon: Icons.fact_check_outlined, title: '۱. بررسی سفارش', subtitle: 'قبل از بسته‌بندی، اطلاعات ثبت‌شده را یک‌بار کنترل کن.'),
        const SizedBox(height: 12),
        _ReviewTile(value: review['items_checked']!, onChanged: (v) => setState(() => review['items_checked'] = v), icon: Icons.shopping_bag_outlined, title: 'کالاها و تعداد', subtitle: '${items.length} ردیف کالا • مبلغ ${order['total'] ?? '-'} ${order['currency'] ?? ''}'),
        _ReviewTile(value: review['address_checked']!, onChanged: (v) => setState(() => review['address_checked'] = v), icon: Icons.location_on_outlined, title: 'آدرس گیرنده', subtitle: address.isEmpty ? 'آدرس ثبت نشده' : address),
        _ReviewTile(value: review['phone_checked']!, onChanged: (v) => setState(() => review['phone_checked'] = v), icon: Icons.phone_outlined, title: 'شماره تماس', subtitle: phone.isEmpty ? 'شماره ثبت نشده' : phone),
        _ReviewTile(value: review['postcode_checked']!, onChanged: (v) => setState(() => review['postcode_checked'] = v), icon: Icons.markunread_mailbox_outlined, title: 'کدپستی', subtitle: postcode.isEmpty ? 'کدپستی ثبت نشده' : postcode),
        _ReviewTile(value: review['payment_checked']!, onChanged: (v) => setState(() => review['payment_checked'] = v), icon: Icons.payments_outlined, title: 'پرداخت', subtitle: '${order['payment_method'] ?? 'نامشخص'} • وضعیت ${order['status'] ?? '-'}'),
        _ReviewTile(value: review['notes_checked']!, onChanged: (v) => setState(() => review['notes_checked'] = v), icon: Icons.sticky_note_2_outlined, title: 'یادداشت و توضیحات', subtitle: 'یادداشت‌های سفارش و درخواست مشتری بررسی شد.'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => PackingPage(client: widget.client, orderId: widget.orderId)));
          },
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('اسکن و کنترل بسته‌بندی'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: busy ? null : _saveReview, icon: const Icon(Icons.check_circle_outline_rounded), label: const Text('ثبت بررسی و رفتن به ارسال')),
      ],
    );
  }

  Widget _shippingPage(Map<String, dynamic> order, Map<String, dynamic> prep) {
    return ListView(
      key: const ValueKey('shipping'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _Hero(icon: Icons.local_shipping_outlined, title: '۲. ارسال مرسوله', subtitle: 'روش ارسال، وزن، جعبه و نوع پرداخت را مشخص کن.'),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'post', icon: Icon(Icons.local_post_office_outlined), label: Text('پست / تاپین')),
            ButtonSegment(value: 'tipax', icon: Icon(Icons.local_shipping_outlined), label: Text('تیپاکس')),
          ],
          selected: {carrier},
          onSelectionChanged: (v) => setState(() => carrier = v.first),
        ),
        const SizedBox(height: 14),
        if (carrier == 'post') ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.local_post_office_outlined, size: 42),
                const SizedBox(height: 10),
                Text('ارسال پستی با تاپین', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const Text('پیشتاز یا سفارشی، وزن، جعبه، پس‌کرایه/پیش‌کرایه، استعلام هزینه و ثبت مرسوله داخل تاپین.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: busy ? null : _openPostShipping, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('ورود به فرم کامل تاپین')),
              ]),
            ),
          ),
        ] else ...[
          TextField(controller: tipaxWeight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'وزن بسته (گرم)', prefixIcon: Icon(Icons.scale_outlined))),
          const SizedBox(height: 10),
          TextField(controller: tipaxBox, decoration: const InputDecoration(labelText: 'جعبه / سایز بسته', hintText: 'مثلاً جعبه شماره ۳ یا ۳۰×۲۰×۱۵', prefixIcon: Icon(Icons.inventory_2_outlined))),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: tipaxPay,
            decoration: const InputDecoration(labelText: 'نوع پرداخت'),
            items: const [DropdownMenuItem(value: 'cod', child: Text('پس‌کرایه')), DropdownMenuItem(value: 'prepaid', child: Text('پیش‌کرایه'))],
            onChanged: (v) => setState(() => tipaxPay = v ?? 'cod'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: tipaxContent,
            decoration: const InputDecoration(labelText: 'نوع محتوا'),
            items: const [DropdownMenuItem(value: 'normal', child: Text('عادی')), DropdownMenuItem(value: 'fragile', child: Text('شکستنی')), DropdownMenuItem(value: 'liquid', child: Text('مایعات'))],
            onChanged: (v) => setState(() => tipaxContent = v ?? 'normal'),
          ),
          const SizedBox(height: 10),
          TextField(controller: tipaxTracking, decoration: const InputDecoration(labelText: 'کد رهگیری تیپاکس', helperText: 'اگر هنوز تحویل ندادی می‌توانی بعداً تکمیلش کنی.', prefixIcon: Icon(Icons.qr_code_2_rounded))),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: busy ? null : _saveTipax, icon: const Icon(Icons.save_outlined), label: const Text('ثبت اطلاعات تیپاکس و آماده ارسال')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: busy ? null : () => _sharePreparationPdf('invoice'), icon: const Icon(Icons.receipt_long_outlined), label: const Text('PDF فاکتور'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: busy ? null : () => _sharePreparationPdf('label'), icon: const Icon(Icons.print_outlined), label: const Text('PDF لیبل'))),
          ]),
        ],
      ],
    );
  }

  Widget _messagePage(Map<String, dynamic> order) {
    final statuses = _maps(order['status_options']);
    return ListView(
      key: const ValueKey('message'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _Hero(icon: Icons.sms_outlined, title: '۳. پیامک و آماده‌سازی', subtitle: 'وضعیت ووکامرس و پیام مشتری را از الگوهای سایت انتخاب کن.'),
        const SizedBox(height: 12),
        if (templates.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())))
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: templates.map((t) {
              final key = '${t['key'] ?? ''}';
              return ChoiceChip(
                label: Text('${t['title'] ?? 'الگو'}'),
                selected: selectedTemplate == key,
                onSelected: (_) => setState(() {
                  selectedTemplate = key;
                  smsMessage.text = '${t['message'] ?? ''}';
                  final s = '${t['status'] ?? ''}';
                  if (s.isNotEmpty) selectedStatus = s;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey('status-$selectedStatus'),
            initialValue: statuses.any((e) => '${e['value']}' == selectedStatus) ? selectedStatus : null,
            decoration: const InputDecoration(labelText: 'وضعیت ووکامرس بعد از آماده‌سازی', prefixIcon: Icon(Icons.sync_alt_rounded)),
            items: statuses.map((s) => DropdownMenuItem(value: '${s['value']}', child: Text('${s['label'] ?? s['value']}'))).toList(),
            onChanged: (v) => setState(() => selectedStatus = v ?? ''),
          ),
          const SizedBox(height: 10),
          TextField(controller: smsMessage, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'متن پیامک مشتری', alignLabelWithHint: true, prefixIcon: Icon(Icons.message_outlined))),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: busy ? null : _sendSmsAndStatus, icon: const Icon(Icons.send_rounded), label: const Text('ثبت وضعیت و ارسال پیامک')),
          const SizedBox(height: 8),
          Text('این مرحله از وضعیت‌های خود ووکامرس و الگوهای پیامک ذخیره‌شده در افزونه استفاده می‌کند.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.onTap});
  final int step;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Row(
          children: List.generate(3, (i) {
            final selected = i == step;
            final done = i < step;
            const titles = ['بررسی', 'ارسال', 'پیامک'];
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(left: i < 2 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: [
                    CircleAvatar(radius: 14, backgroundColor: done || selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest, child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: done || selected ? Theme.of(context).colorScheme.onPrimary : null))),
                    const SizedBox(height: 4),
                    Text(titles[i], style: TextStyle(fontWeight: selected ? FontWeight.w900 : FontWeight.w600)),
                  ]),
                ),
              ),
            );
          }),
        ),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .55), borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          CircleAvatar(radius: 26, child: Icon(icon)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle)])),
        ]),
      );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.value, required this.onChanged, required this.icon, required this.title, required this.subtitle});
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: CheckboxListTile(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          secondary: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
          controlAffinity: ListTileControlAffinity.trailing,
        ),
      );
}
