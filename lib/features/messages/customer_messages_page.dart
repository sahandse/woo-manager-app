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
  bool changeStatus = false;
  String selectedStatus = '';
  String selectedTitle = '';
  late Future<Map<String, dynamic>?> templatesFuture;

  static const fallbackTemplates = <Map<String, String>>[
    {'title': 'ثبت سفارش', 'status': 'pending', 'message': 'سفارش شما با موفقیت ثبت شد و در انتظار پرداخت/تأیید است.'},
    {'title': 'در حال آماده‌سازی', 'status': 'processing', 'message': 'سفارش شما در حال آماده‌سازی و بسته‌بندی است.'},
    {'title': 'آماده برای ارسال', 'status': 'processing', 'message': 'سفارش شما آماده ارسال است و به‌زودی تحویل پست می‌شود.'},
    {'title': 'تحویل به پست', 'status': 'processing', 'message': 'سفارش شما تحویل پست شد.'},
    {'title': 'تکمیل سفارش', 'status': 'completed', 'message': 'سفارش شما تکمیل شد. از خرید شما سپاسگزاریم.'},
    {'title': 'نیاز به اصلاح آدرس', 'status': '', 'message': 'برای ارسال سفارش، آدرس یا کدپستی نیاز به بررسی دارد. لطفاً با فروشگاه تماس بگیرید.'},
  ];

  @override
  void initState() {
    super.initState();
    order = TextEditingController(text: widget.orderId?.toString() ?? '');
    templatesFuture = _loadTemplates();
  }

  Future<Map<String, dynamic>?> _loadTemplates() async {
    final id = widget.orderId ?? int.tryParse(order.text.trim());
    if (id == null) return null;
    try {
      return await widget.client.orderMessageTemplates(id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    order.dispose();
    message.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _templates(Map<String, dynamic>? data) {
    final raw = data?['items'];
    if (raw is List) {
      final items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (items.isNotEmpty) return items;
    }
    return fallbackTemplates.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _choose(Map<String, dynamic> template) {
    setState(() {
      selectedTitle = '${template['title'] ?? ''}';
      selectedStatus = '${template['status'] ?? ''}';
      message.text = '${template['message'] ?? ''}';
      changeStatus = selectedStatus.isNotEmpty;
    });
  }

  Future<void> _send() async {
    final id = int.tryParse(order.text.trim());
    if (id == null || message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شماره سفارش و متن پیام الزامی است.')));
      return;
    }
    setState(() => busy = true);
    try {
      if (changeStatus && selectedStatus.isNotEmpty) {
        await widget.client.updateOrderStatus(id, selectedStatus);
      }
      await widget.client.sendOrderMessage(id, message.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(changeStatus && selectedStatus.isNotEmpty ? 'وضعیت سفارش تغییر کرد و پیامک ارسال شد.' : 'پیام برای مشتری ارسال شد.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ارسال پیام انجام نشد: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('پیام و تغییر وضعیت سفارش')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (busy) const LinearProgressIndicator(),
            TextField(
              controller: order,
              enabled: widget.orderId == null,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'شماره سفارش'),
              onSubmitted: (_) => setState(() => templatesFuture = _loadTemplates()),
            ),
            const SizedBox(height: 16),
            Text('الگوهای تغییر وضعیت', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('الگو را انتخاب کن؛ متن با اطلاعات واقعی همین سفارش پر می‌شود.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, dynamic>?>(
              future: templatesFuture,
              builder: (context, snapshot) {
                final items = _templates(snapshot.data);
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.map((e) => ChoiceChip(
                    label: Text('${e['title']}'),
                    selected: selectedTitle == '${e['title']}',
                    onSelected: (_) => _choose(e),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: message,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'متن پیامک', alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: changeStatus,
              onChanged: selectedStatus.isEmpty ? null : (v) => setState(() => changeStatus = v),
              title: const Text('تغییر وضعیت سفارش همراه پیامک'),
              subtitle: Text(selectedStatus.isEmpty ? 'این الگو وضعیت سفارش را تغییر نمی‌دهد.' : 'وضعیت مقصد: $selectedStatus'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: busy ? null : _send,
              icon: const Icon(Icons.send_rounded),
              label: const Text('اعمال وضعیت و ارسال پیامک'),
            ),
          ],
        ),
      );
}
