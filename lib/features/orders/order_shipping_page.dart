import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class OrderShippingPage extends StatefulWidget {
  const OrderShippingPage({super.key, required this.client, required this.orderId});
  final ApiClient client;
  final int orderId;

  @override
  State<OrderShippingPage> createState() => _OrderShippingPageState();
}

class _OrderShippingPageState extends State<OrderShippingPage> {
  late Future<Map<String, dynamic>> _future;
  final weight = TextEditingController();
  final province = TextEditingController();
  final city = TextEditingController();
  final boxId = TextEditingController();
  bool initialized = false;
  bool busy = false;
  int payType = 1;
  int orderType = 1;
  int contentType = 1;
  Map<String, dynamic>? quote;

  @override
  void initState() {
    super.initState();
    _future = widget.client.tapinOptions(widget.orderId);
  }

  @override
  void dispose() {
    weight.dispose();
    province.dispose();
    city.dispose();
    boxId.dispose();
    super.dispose();
  }

  String _error(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] != null) return '${data['message']}';
    }
    return '$e';
  }

  int _int(dynamic value, [int fallback = 0]) => value is num ? value.toInt() : int.tryParse('${value ?? ''}') ?? fallback;
  Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  void _fill(Map<String, dynamic> data) {
    if (initialized) return;
    initialized = true;
    final defaults = _map(data['defaults']);
    weight.text = '${defaults['package_weight'] ?? 100}';
    province.text = '${defaults['province_code'] ?? ''}';
    city.text = '${defaults['city_code'] ?? ''}';
    boxId.text = '${defaults['box_id'] ?? ''}';
    payType = _int(defaults['pay_type'], 1);
    orderType = _int(defaults['order_type'], 1);
    contentType = _int(defaults['content_type'], 1);
  }

  Map<String, dynamic> _options() => {
        'package_weight': _int(weight.text, 100),
        'province_code': _int(province.text),
        'city_code': _int(city.text),
        'pay_type': payType,
        'order_type': orderType,
        'content_type': contentType,
        if (boxId.text.trim().isNotEmpty) 'box_id': _int(boxId.text),
      };

  Future<void> _quote() async {
    if (_int(weight.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وزن مرسوله را به گرم وارد کنید.')));
      return;
    }
    setState(() => busy = true);
    try {
      final result = await widget.client.tapinQuote(widget.orderId, _options());
      if (!mounted) return;
      setState(() => quote = result);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('استعلام هزینه تاپین انجام شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _register() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ثبت مرسوله در تاپین'),
        content: const Text('مرسوله با اطلاعات انتخاب‌شده در تاپین ثبت شود؟ پس از ثبت، در صورت دریافت بارکد، کد رهگیری ذخیره و پیامک رهگیری طبق تنظیمات افزونه ارسال می‌شود.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ثبت نهایی')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => busy = true);
    try {
      final result = await widget.client.registerShipment(widget.orderId, _options());
      if (!mounted) return;
      final entries = _map(result['entries']);
      final tracking = '${entries['barcode'] ?? ''}'.trim();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tracking.isEmpty ? 'مرسوله در تاپین ثبت شد.' : 'مرسوله ثبت شد؛ کد رهگیری: $tracking')));
      setState(() {
        quote = null;
        _future = widget.client.tapinOptions(widget.orderId);
        initialized = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _row(String title, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Expanded(child: Text(title, style: const TextStyle(color: Colors.grey))), Expanded(flex: 2, child: Text('${value ?? '-'}'))]),
      );

  Widget _quoteCard() {
    if (quote == null) return const SizedBox.shrink();
    final entries = _map(quote!['entries']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('نتیجه استعلام', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _row('هزینه ارسال', entries['send_price'] ?? entries['total_send_price'] ?? '-'),
          _row('مالیات', entries['send_tax'] ?? '-'),
          _row('مبلغ کل ارسال', entries['total_send_price'] ?? entries['total_receive_price'] ?? '-'),
          _row('وزن محاسبه‌شده', entries['total_weight'] ?? weight.text),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('ارسال سفارش #${widget.orderId}')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error(snapshot.error!))));
            final data = snapshot.data ?? <String, dynamic>{};
            _fill(data);
            final destination = _map(data['destination']);
            final shipment = _map(data['shipment']);
            final registered = data['registered'] == true;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (busy) const LinearProgressIndicator(),
                if (registered)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping_outlined),
                      title: const Text('مرسوله قبلاً در تاپین ثبت شده'),
                      subtitle: Text('شناسه: ${data['tapin_order_id'] ?? '-'}\nکد رهگیری: ${data['tracking_number'] ?? shipment['barcode'] ?? '-'}'),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('مقصد', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _row('استان', destination['province']),
                      _row('شهر', destination['city']),
                      _row('کد پستی', destination['postal_code']),
                      _row('آدرس', destination['address']),
                      const SizedBox(height: 8),
                      Row(children: [Expanded(child: TextField(controller: province, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کد استان تاپین'))), const SizedBox(width: 10), Expanded(child: TextField(controller: city, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کد شهر تاپین')))]),
                    ]),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      TextField(controller: weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'وزن کل مرسوله (گرم)')),
                      DropdownButtonFormField<int>(value: orderType, decoration: const InputDecoration(labelText: 'نوع ارسال پستی'), items: const [DropdownMenuItem(value: 0, child: Text('پست سفارشی')), DropdownMenuItem(value: 1, child: Text('پست پیشتاز'))], onChanged: busy ? null : (v) => setState(() => orderType = v ?? 1)),
                      DropdownButtonFormField<int>(value: payType, decoration: const InputDecoration(labelText: 'نوع پرداخت ارسال'), items: const [DropdownMenuItem(value: 0, child: Text('پرداخت در محل')), DropdownMenuItem(value: 1, child: Text('پرداخت از اعتبار')), DropdownMenuItem(value: 2, child: Text('پس‌کرایه')), DropdownMenuItem(value: 3, child: Text('ارسال رایگان'))], onChanged: busy ? null : (v) => setState(() => payType = v ?? 1)),
                      DropdownButtonFormField<int>(value: contentType, decoration: const InputDecoration(labelText: 'نوع محتوا'), items: const [DropdownMenuItem(value: 1, child: Text('عادی')), DropdownMenuItem(value: 2, child: Text('شکستنی')), DropdownMenuItem(value: 3, child: Text('مایعات')), DropdownMenuItem(value: 4, child: Text('غیراستاندارد'))], onChanged: busy ? null : (v) => setState(() => contentType = v ?? 1)),
                      TextField(controller: boxId, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'شناسه بسته‌بندی تاپین', helperText: 'اختیاری؛ در صورت تنظیم در افزونه همان مقدار پیش‌فرض نمایش داده می‌شود.')),
                    ]),
                  ),
                ),
                _quoteCard(),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: busy ? null : _quote, icon: const Icon(Icons.calculate_outlined), label: const Text('استعلام هزینه'))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton.icon(onPressed: busy || registered ? null : _register, icon: const Icon(Icons.local_shipping_rounded), label: const Text('ثبت در تاپین'))),
                ]),
              ],
            );
          },
        ),
      );
}
