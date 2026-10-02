import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../messages/customer_messages_page.dart';
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
  late Future<Map<String, dynamic>> future;
  int step = 0;
  bool itemsChecked = false;
  bool addressChecked = false;
  bool packageChecked = false;
  String carrier = 'post';
  String tipaxService = 'standard';
  final tipaxWeight = TextEditingController();
  final tipaxBox = TextEditingController();
  final tipaxTracking = TextEditingController();
  bool tipaxCod = false;
  bool busy = false;

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
    super.dispose();
  }

  void _load() => setState(() => future = widget.client.order(widget.orderId));

  Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  List<Map<String, dynamic>> _maps(dynamic value) => value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
  String _text(dynamic value) => '${value ?? ''}'.trim();

  String _preferred(dynamic a, dynamic b) {
    final first = _text(a);
    return first.isNotEmpty ? first : _text(b);
  }

  Map<String, bool> _automaticChecks(Map<String, dynamic> order) {
    final billing = _map(order['billing']);
    final shipping = _map(order['shipping']);
    final items = _maps(order['items']);
    final phone = _preferred(billing['phone'], order['billing_phone']);
    final postcode = _preferred(shipping['postcode'], billing['postcode']);
    final address = _preferred(shipping['address_1'], billing['address_1']);
    final city = _preferred(shipping['city'], billing['city']);
    return {
      'اقلام سفارش ثبت شده': items.isNotEmpty,
      'آدرس و شهر کامل': address.isNotEmpty && city.isNotEmpty,
      'کدپستی ثبت شده': postcode.replaceAll(RegExp(r'\D'), '').length >= 10,
      'شماره موبایل ثبت شده': phone.replaceAll(RegExp(r'\D'), '').length >= 10,
    };
  }

  bool _canContinueReview(Map<String, dynamic> order) {
    final auto = _automaticChecks(order).values.every((value) => value);
    return auto && itemsChecked && addressChecked && packageChecked;
  }

  int _derivedStep(Map<String, dynamic> order) {
    final status = _text(order['status']);
    final shipment = _map(order['shipment']);
    final tracking = _text(shipment['tracking_number']);
    if (status == 'completed') return 2;
    if (tracking.isNotEmpty || _text(shipment['tapin_order_id']).isNotEmpty) return 2;
    if (['processing', 'on-hold'].contains(status)) return 1;
    return 0;
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  Future<void> _saveTipax() async {
    if (int.tryParse(tipaxWeight.text.trim()) == null || int.parse(tipaxWeight.text.trim()) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وزن مرسوله را به گرم وارد کن.')));
      return;
    }
    setState(() => busy = true);
    try {
      final text = [
        'ارسال تیپاکس',
        'سرویس: ${tipaxService == 'express' ? 'اکسپرس' : 'استاندارد'}',
        'وزن: ${tipaxWeight.text.trim()} گرم',
        'جعبه: ${tipaxBox.text.trim().isEmpty ? 'ثبت نشده' : tipaxBox.text.trim()}',
        'پرداخت: ${tipaxCod ? 'پس‌کرایه / پرداخت در مقصد' : 'پیش‌کرایه'}',
        if (tipaxTracking.text.trim().isNotEmpty) 'کد رهگیری: ${tipaxTracking.text.trim()}',
      ].join(' | ');
      await widget.client.addOrderNote(widget.orderId, text);
      await widget.client.setShippingReady(widget.orderId, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اطلاعات ارسال تیپاکس داخل سفارش ثبت شد.')));
      setState(() => step = 2);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت تیپاکس انجام نشد: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _changeStatus(String status, String label) async {
    setState(() => busy = true);
    try {
      await widget.client.updateOrderStatus(widget.orderId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('وضعیت سفارش به «$label» تغییر کرد.')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تغییر وضعیت انجام نشد: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('آماده‌سازی سفارش #${widget.orderId}'),
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${snapshot.error}')));
            final order = snapshot.data!;
            final suggested = _derivedStep(order);
            final current = step == 0 && suggested > 0 ? suggested : step;
            if (current != step) step = current;
            return Column(
              children: [
                if (busy) const LinearProgressIndicator(),
                _StepHeader(step: step),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (step) {
                      0 => _reviewPage(order),
                      1 => _shippingPage(order),
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
    final checks = _automaticChecks(order);
    final items = _maps(order['items']);
    final billing = _map(order['billing']);
    final shipping = _map(order['shipping']);
    final address = _preferred(shipping['address_1'], billing['address_1']);
    final city = _preferred(shipping['city'], billing['city']);
    final postcode = _preferred(shipping['postcode'], billing['postcode']);
    final phone = _preferred(billing['phone'], order['billing_phone']);
    return ListView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _hero(Icons.fact_check_outlined, '۱. بررسی سفارش', 'قبل از بسته‌بندی، اطلاعات سفارش را یک‌بار کامل کنترل کن.'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('چک خودکار اطلاعات', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...checks.entries.map((e) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(e.value ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: e.value ? Colors.green : Theme.of(context).colorScheme.error),
                    title: Text(e.key),
                    trailing: Text(e.value ? 'تکمیل' : 'ناقص'),
                  )),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('اقلام سفارش', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...items.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_text(item['name']).isEmpty ? 'محصول' : _text(item['name'])),
                    trailing: Text('× ${item['quantity'] ?? 1}'),
                  )),
              const Divider(),
              Text('آدرس: $city، $address'),
              const SizedBox(height: 4),
              Text('کدپستی: ${postcode.isEmpty ? 'ثبت نشده' : postcode}'),
              const SizedBox(height: 4),
              Text('موبایل: ${phone.isEmpty ? 'ثبت نشده' : phone}'),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(children: [
            CheckboxListTile(value: itemsChecked, onChanged: (v) => setState(() => itemsChecked = v ?? false), title: const Text('تعداد و مدل کالاها را با سفارش تطبیق دادم')),
            CheckboxListTile(value: addressChecked, onChanged: (v) => setState(() => addressChecked = v ?? false), title: const Text('نام، موبایل، آدرس و کدپستی را بررسی کردم')),
            CheckboxListTile(value: packageChecked, onChanged: (v) => setState(() => packageChecked = v ?? false), title: const Text('کالا سالم است و آماده بسته‌بندی است')),
          ]),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _canContinueReview(order) ? () => setState(() => step = 1) : null,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('تأیید و رفتن به ارسال'),
        ),
        if (!_canContinueReview(order))
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('برای ادامه، موارد ناقص و سه تأیید بالا باید تکمیل شوند.', textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _shippingPage(Map<String, dynamic> order) {
    final shipment = _map(order['shipment']);
    final tracking = _text(shipment['tracking_number']);
    return ListView(
      key: const ValueKey('shipping'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _hero(Icons.local_shipping_outlined, '۲. ارسال سفارش', 'روش ارسال، وزن، جعبه، نوع پرداخت و رهگیری را ثبت کن.'),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'post', icon: Icon(Icons.local_post_office_outlined), label: Text('پست / تاپین')),
            ButtonSegment(value: 'tipax', icon: Icon(Icons.local_shipping_outlined), label: Text('تیپاکس')),
          ],
          selected: {carrier},
          onSelectionChanged: (value) => setState(() => carrier = value.first),
        ),
        const SizedBox(height: 12),
        if (carrier == 'post') ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('پست از طریق تاپین', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('وزن، استان/شهر، پست پیشتاز یا سفارشی، پس‌کرایه/پیش‌کرایه، نوع محتوا و جعبه در فرم تاپین ثبت می‌شوند.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _open(OrderShippingPage(client: widget.client, orderId: widget.orderId)),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(tracking.isEmpty ? 'باز کردن فرم کامل تاپین' : 'مشاهده ارسال و PDF تاپین'),
                ),
                if (tracking.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('کد رهگیری: $tracking')),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => setState(() => step = 2), icon: const Icon(Icons.arrow_back_rounded), label: const Text('ارسال ثبت شده؛ مرحله بعد')),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                DropdownButtonFormField<String>(
                  initialValue: tipaxService,
                  decoration: const InputDecoration(labelText: 'نوع سرویس تیپاکس'),
                  items: const [DropdownMenuItem(value: 'standard', child: Text('استاندارد')), DropdownMenuItem(value: 'express', child: Text('اکسپرس'))],
                  onChanged: (v) => setState(() => tipaxService = v ?? 'standard'),
                ),
                const SizedBox(height: 10),
                TextField(controller: tipaxWeight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'وزن مرسوله (گرم)')),
                const SizedBox(height: 10),
                TextField(controller: tipaxBox, decoration: const InputDecoration(labelText: 'جعبه / سایز بسته', hintText: 'مثلاً جعبه ۳ یا ۲۰×۱۵×۱۰')),
                SwitchListTile(contentPadding: EdgeInsets.zero, value: tipaxCod, onChanged: (v) => setState(() => tipaxCod = v), title: const Text('پس‌کرایه / پرداخت در مقصد')),
                TextField(controller: tipaxTracking, decoration: const InputDecoration(labelText: 'کد رهگیری تیپاکس', helperText: 'اگر هنوز صادر نشده، بعداً هم می‌توانی ثبت کنی.')),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: busy ? null : _saveTipax, icon: const Icon(Icons.save_outlined), label: const Text('ثبت اطلاعات تیپاکس و آماده ارسال')),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextButton.icon(onPressed: () => setState(() => step = 0), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('بازگشت به بررسی سفارش')),
      ],
    );
  }

  Widget _messagePage(Map<String, dynamic> order) {
    final status = _text(order['status']);
    return ListView(
      key: const ValueKey('messages'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _hero(Icons.mark_chat_read_outlined, '۳. آماده‌سازی و پیام مشتری', 'وضعیت ووکامرس، بسته‌بندی و پیامک مشتری را از یک صفحه انجام بده.'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('وضعیت فعلی: ${status.isEmpty ? '-' : status}', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ActionChip(avatar: const Icon(Icons.inventory_2_outlined, size: 18), label: const Text('در حال آماده‌سازی'), onPressed: busy ? null : () => _changeStatus('processing', 'در حال آماده‌سازی')),
                ActionChip(avatar: const Icon(Icons.pause_circle_outline_rounded, size: 18), label: const Text('در انتظار'), onPressed: busy ? null : () => _changeStatus('on-hold', 'در انتظار')),
                ActionChip(avatar: const Icon(Icons.check_circle_outline_rounded, size: 18), label: const Text('تکمیل سفارش'), onPressed: busy ? null : () => _changeStatus('completed', 'تکمیل شده')),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        _bigAction(Icons.qr_code_scanner_rounded, 'بسته‌بندی و اسکن کالا', 'اقلام را اسکن و بسته‌بندی را تکمیل کن.', () => _open(PackingPage(client: widget.client, orderId: widget.orderId))),
        const SizedBox(height: 10),
        _bigAction(Icons.sms_outlined, 'پیامک و الگوهای سفارش', 'پیام‌های ثبت سفارش، آماده‌سازی، آماده ارسال، رهگیری و تکمیل.', () => _open(CustomerMessagesPage(client: widget.client, orderId: widget.orderId))),
        const SizedBox(height: 10),
        _bigAction(Icons.inventory_rounded, 'علامت آماده برای ارسال', 'وضعیت عملیاتی سفارش را بدون تغییر مرحله پرداخت ثبت کن.', () async {
          await widget.client.setShippingReady(widget.orderId, true);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سفارش آماده برای ارسال شد.')));
        }),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: status == 'completed' ? null : () => _changeStatus('completed', 'تکمیل شده'), icon: const Icon(Icons.done_all_rounded), label: const Text('پایان فرآیند و تکمیل سفارش')),
        TextButton.icon(onPressed: () => setState(() => step = 1), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('بازگشت به ارسال')),
      ],
    );
  }

  Widget _hero(IconData icon, String title, String subtitle) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .65), borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          CircleAvatar(radius: 25, child: Icon(icon)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle)])),
        ]),
      );

  Widget _bigAction(IconData icon, String title, String subtitle, VoidCallback onTap) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: onTap,
        ),
      );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['بررسی', 'ارسال', 'پیام و آماده‌سازی'];
    const icons = [Icons.fact_check_outlined, Icons.local_shipping_outlined, Icons.sms_outlined];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= step;
          return Expanded(
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  CircleAvatar(radius: 18, backgroundColor: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest, child: Icon(icons[i], size: 18, color: active ? Theme.of(context).colorScheme.onPrimary : null)),
                  const SizedBox(height: 4),
                  Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500), textAlign: TextAlign.center),
                ]),
              ),
              if (i < 2) Expanded(child: Container(height: 2, color: i < step ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor)),
            ]),
          );
        }),
      ),
    );
  }
}
