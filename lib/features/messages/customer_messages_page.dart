import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class CustomerMessagesPage extends StatefulWidget {
  const CustomerMessagesPage({super.key, required this.client, this.orderId});
  final ApiClient client;
  final int? orderId;

  @override
  State<CustomerMessagesPage> createState() => _CustomerMessagesPageState();
}

class _CustomerMessagesPageState extends State<CustomerMessagesPage> {
  late final TextEditingController order;
  final message = TextEditingController();
  bool busy = false;

  static const templates = <String, String>{
    'دریافت سفارش': 'سفارش شما با موفقیت دریافت شد و در صف بررسی قرار گرفت.',
    'در حال آماده‌سازی': 'سفارش شما در حال آماده‌سازی و بسته‌بندی است.',
    'تحویل به پست': 'سفارش شما آماده ارسال است و به فرایند پستی تحویل داده می‌شود.',
    'کد رهگیری': 'سفارش شما ارسال شد. کد رهگیری در اطلاعات سفارش ثبت شده است.',
    'مشکل آدرس': 'برای ارسال سفارش، اطلاعات آدرس یا کدپستی نیاز به بررسی دارد. لطفاً با فروشگاه در تماس باشید.',
    'نیاز به تماس': 'برای تکمیل سفارش نیاز است با شما هماهنگ کنیم. لطفاً با فروشگاه تماس بگیرید.',
  };

  @override
  void initState() {
    super.initState();
    order = TextEditingController(text: widget.orderId?.toString() ?? '');
  }

  @override
  void dispose() {
    order.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final id = int.tryParse(order.text.trim());
    if (id == null || message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شماره سفارش و متن پیام الزامی است.')));
      return;
    }
    setState(() => busy = true);
    try {
      await widget.client.sendOrderMessage(id, message.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پیام برای مشتری ارسال شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ارسال پیام انجام نشد: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('پیام به مشتری')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (busy) const LinearProgressIndicator(),
            TextField(controller: order, enabled: widget.orderId == null, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'شماره سفارش')),
            const SizedBox(height: 14),
            Text('پیام‌های آماده', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: templates.entries.map((e) => ActionChip(label: Text(e.key), onPressed: () => setState(() => message.text = e.value))).toList(),
            ),
            const SizedBox(height: 14),
            TextField(controller: message, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'متن پیام', alignLabelWithHint: true)),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: busy ? null : _send, icon: const Icon(Icons.send_rounded), label: const Text('ارسال پیامک')),
          ],
        ),
      );
}
