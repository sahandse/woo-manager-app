import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

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
  final customBoxId = TextEditingController();
  bool initialized = false;
  bool busy = false;
  bool shippingReady = false;
  int payType = 2;
  int orderType = 1;
  int contentType = 1;
  int selectedBoxId = 0;
  Map<String, dynamic>? quote;
  List<Map<String, dynamic>> boxOptions = const [];

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
    customBoxId.dispose();
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
  List<Map<String, dynamic>> _maps(dynamic value) => value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

  void _fill(Map<String, dynamic> data) {
    if (initialized) return;
    initialized = true;
    final defaults = _map(data['defaults']);
    weight.text = '${defaults['package_weight'] ?? 100}';
    province.text = '${defaults['province_code'] ?? ''}';
    city.text = '${defaults['city_code'] ?? ''}';
    final savedBox = _int(defaults['box_id']);
    selectedBoxId = savedBox;
    customBoxId.text = savedBox > 0 ? '$savedBox' : '';
    boxOptions = _maps(data['box_options']);
    shippingReady = data['shipping_ready'] == true;
    final nextPay = _int(defaults['pay_type'], 2);
    final nextOrder = _int(defaults['order_type'], 1);
    final nextContent = _int(defaults['content_type'], 1);
    payType = const {0, 1, 2, 3}.contains(nextPay) ? nextPay : 2;
    orderType = const {0, 1}.contains(nextOrder) ? nextOrder : 1;
    contentType = const {1, 2, 3, 4}.contains(nextContent) ? nextContent : 1;
  }

  int get _boxId {
    if (selectedBoxId > 0) return selectedBoxId;
    return _int(customBoxId.text);
  }

  Map<String, dynamic> _options() => {
        'package_weight': _int(weight.text, 100),
        'province_code': _int(province.text),
        'city_code': _int(city.text),
        'pay_type': payType,
        'order_type': orderType,
        'content_type': contentType,
        if (_boxId > 0) 'box_id': _boxId,
      };

  Future<void> _toggleReady(bool value) async {
    setState(() => busy = true);
    try {
      await widget.client.setShippingReady(widget.orderId, value);
      if (!mounted) return;
      setState(() => shippingReady = value);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'سفارش «آماده برای ارسال» شد.' : 'وضعیت آماده برای ارسال برداشته شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

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

  Future<void> _sharePdf(List<String> ids, String type) async {
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شناسه مرسوله برای PDF در دسترس نیست.')));
      return;
    }
    final result = await widget.client.shipmentPdf(ids, type: type);
    final encoded = '${result['content_base64'] ?? ''}';
    if (encoded.isEmpty) throw const FormatException('فایل PDF از تاپین دریافت نشد.');
    await Printing.sharePdf(bytes: base64Decode(encoded), filename: '${result['filename'] ?? 'tapin.pdf'}');
  }

  Future<void> _askForDocuments(Map<String, dynamic> result) async {
    final entries = _map(result['entries']);
    final labelId = '${entries['id'] ?? ''}'.trim();
    final invoiceId = '${entries['order_id'] ?? ''}'.trim();
    if (!mounted || (labelId.isEmpty && invoiceId.isEmpty)) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مدارک ارسال تاپین'),
        content: const Text('مرسوله ثبت شد. کدام فایل را همین الان دریافت/اشتراک‌گذاری می‌کنی؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'none'), child: const Text('فعلاً نه')),
          if (invoiceId.isNotEmpty) TextButton(onPressed: () => Navigator.pop(context, 'invoice'), child: const Text('فاکتور PDF')),
          if (labelId.isNotEmpty) TextButton(onPressed: () => Navigator.pop(context, 'label'), child: const Text('لیبل PDF')),
          if (labelId.isNotEmpty && invoiceId.isNotEmpty) FilledButton(onPressed: () => Navigator.pop(context, 'both'), child: const Text('هر دو')),
        ],
      ),
    );
    try {
      if (choice == 'invoice') await _sharePdf([invoiceId], 'invoice');
      if (choice == 'label') await _sharePdf([labelId], 'label');
      if (choice == 'both') {
        await _sharePdf([invoiceId], 'invoice');
        await _sharePdf([labelId], 'label');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('دریافت PDF انجام نشد: ${_error(e)}')));
    }
  }

  Future<void> _register() async {
    if (!shippingReady) {
      final markReady = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('سفارش آماده ارسال است؟'),
          content: const Text('قبل از ثبت مرسوله می‌توانی سفارش را به وضعیت «آماده برای ارسال» ببری.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('بدون تغییر ادامه بده')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('آماده برای ارسال')),
          ],
        ),
      );
      if (markReady == true) await _toggleReady(true);
    }

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ثبت مرسوله در تاپین'),
        content: Text(
          'روش: ${orderType == 1 ? 'پست پیشتاز' : 'پست سفارشی'}\n'
          'پرداخت: ${_payLabel(payType)}\n'
          'وزن: ${weight.text} گرم\n'
          'محتوا: ${_contentLabel(contentType)}\n'
          'جعبه: ${_boxId > 0 ? '#$_boxId' : 'بدون جعبه مشخص'}\n\n'
          'با این اطلاعات مرسوله ثبت شود؟',
        ),
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
      await _askForDocuments(result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _payLabel(int value) => value == 0
      ? 'پرداخت در محل'
      : value == 1
          ? 'پیش‌کرایه / اعتبار'
          : value == 2
              ? 'پس‌کرایه'
              : 'ارسال رایگان';

  String _contentLabel(int value) => value == 2
      ? 'شکستنی'
      : value == 3
          ? 'مایعات'
          : value == 4
              ? 'غیراستاندارد'
              : 'عادی';

  Widget _row(String title, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.grey))),
          Expanded(flex: 2, child: Text('${value ?? '-'}')),
        ]),
      );

  Widget _quoteCard() {
    if (quote == null) return const SizedBox.shrink();
    final entries = _map(quote!['entries']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('نتیجه استعلام', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _row('هزینه ارسال', entries['send_price'] ?? entries['total_send_price'] ?? '-'),
          _row('مالیات', entries['send_tax'] ?? '-'),
          _row('مبلغ کل ارسال', entries['total_send_price'] ?? entries['total_receive_price'] ?? '-'),
          _row('وزن محاسبه‌شده', entries['total_weight'] ?? weight.text),
        ]),
      ),
    );
  }

  Widget _boxSelector() {
    final ids = boxOptions.map((e) => _int(e['id'])).where((id) => id > 0).toSet();
    final value = ids.contains(selectedBoxId) ? selectedBoxId : 0;
    return Column(children: [
      DropdownButtonFormField<int>(
        value: value,
        decoration: const InputDecoration(labelText: 'انتخاب جعبه'),
        items: [
          const DropdownMenuItem(value: 0, child: Text('بدون جعبه پیش‌فرض / شناسه دستی')),
          ...boxOptions.where((e) => _int(e['id']) > 0).map((e) => DropdownMenuItem(value: _int(e['id']), child: Text('${e['label'] ?? 'جعبه #${e['id']}'}'))),
        ],
        onChanged: busy ? null : (v) => setState(() => selectedBoxId = v ?? 0),
      ),
      if (value == 0)
        TextField(
          controller: customBoxId,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'شناسه جعبه تاپین', helperText: 'در صورت داشتن شناسه جعبه، وارد کن؛ در غیر این صورت خالی بگذار.'),
        ),
    ]);
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
                Card(
                  child: SwitchListTile(
                    value: shippingReady,
                    onChanged: busy ? null : _toggleReady,
                    secondary: Icon(shippingReady ? Icons.inventory_rounded : Icons.inventory_2_outlined),
                    title: const Text('آماده برای ارسال', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(shippingReady ? 'سفارش آماده تحویل به پست است.' : 'بعد از بسته‌بندی این وضعیت را فعال کن.'),
                  ),
                ),
                if (registered)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping_outlined),
                      title: const Text('مرسوله در تاپین ثبت شده'),
                      subtitle: Text('شناسه: ${data['tapin_order_id'] ?? '-'}\nکد رهگیری: ${data['tracking_number'] ?? shipment['barcode'] ?? '-'}'),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('مقصد', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      _row('استان', destination['province']),
                      _row('شهر', destination['city']),
                      _row('کد پستی', destination['postal_code']),
                      _row('آدرس', destination['address']),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: TextField(controller: province, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کد استان تاپین'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: city, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کد شهر تاپین'))),
                      ]),
                    ]),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('مشخصات ارسال', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: orderType,
                        decoration: const InputDecoration(labelText: 'نحوه ارسال'),
                        items: const [DropdownMenuItem(value: 0, child: Text('پست سفارشی')), DropdownMenuItem(value: 1, child: Text('پست پیشتاز'))],
                        onChanged: busy ? null : (v) => setState(() => orderType = v ?? 1),
                      ),
                      DropdownButtonFormField<int>(
                        value: payType,
                        decoration: const InputDecoration(labelText: 'پرداخت هزینه ارسال'),
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('پس‌کرایه')),
                          DropdownMenuItem(value: 1, child: Text('پیش‌کرایه / پرداخت از اعتبار')),
                          DropdownMenuItem(value: 0, child: Text('پرداخت در محل')),
                          DropdownMenuItem(value: 3, child: Text('ارسال رایگان')),
                        ],
                        onChanged: busy ? null : (v) => setState(() => payType = v ?? 2),
                      ),
                      TextField(controller: weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'وزن مرسوله (گرم)')),
                      DropdownButtonFormField<int>(
                        value: contentType,
                        decoration: const InputDecoration(labelText: 'نوع مرسوله'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('عادی')),
                          DropdownMenuItem(value: 2, child: Text('شکستنی')),
                          DropdownMenuItem(value: 3, child: Text('مایعات')),
                          DropdownMenuItem(value: 4, child: Text('غیراستاندارد')),
                        ],
                        onChanged: busy ? null : (v) => setState(() => contentType = v ?? 1),
                      ),
                      _boxSelector(),
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
