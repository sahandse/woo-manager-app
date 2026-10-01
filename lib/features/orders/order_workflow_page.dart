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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => future = widget.client.order(widget.orderId));

  int _stage(Map<String, dynamic> o) {
    final status = '${o['status'] ?? ''}';
    final shipment = o['shipment'] is Map ? Map<String, dynamic>.from(o['shipment'] as Map) : <String, dynamic>{};
    if (status == 'completed') return 5;
    if ('${shipment['tracking_number'] ?? ''}'.trim().isNotEmpty) return 4;
    if ('${shipment['tapin_order_id'] ?? ''}'.trim().isNotEmpty) return 3;
    if (['processing', 'on-hold'].contains(status)) return 1;
    if (['pending', 'failed'].contains(status)) return 0;
    return 1;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('فرآیند سفارش #${widget.orderId}'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
        body: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
            final o = snapshot.data!;
            final stage = _stage(o);
            const labels = ['پرداخت', 'آماده‌سازی', 'بسته‌بندی', 'ثبت تاپین', 'رهگیری', 'تکمیل'];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('وضعیت سفارش', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      ...List.generate(labels.length, (i) {
                        final done = i <= stage;
                        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Column(children: [
                            CircleAvatar(radius: 15, backgroundColor: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest, child: Icon(done ? Icons.check_rounded : Icons.circle_outlined, size: 17, color: done ? Theme.of(context).colorScheme.onPrimary : null)),
                            if (i < labels.length - 1) Container(width: 2, height: 32, color: done ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
                          ]),
                          const SizedBox(width: 12),
                          Padding(padding: const EdgeInsets.only(top: 5), child: Text(labels[i], style: TextStyle(fontWeight: done ? FontWeight.w800 : FontWeight.w500))),
                        ]);
                      }),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: [
                    _Action(Icons.qr_code_scanner_rounded, 'بسته‌بندی', () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => PackingPage(client: widget.client, orderId: widget.orderId)));
                      if (mounted) _load();
                    }),
                    _Action(Icons.local_shipping_outlined, 'ارسال و تاپین', () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderShippingPage(client: widget.client, orderId: widget.orderId)));
                      if (mounted) _load();
                    }),
                    _Action(Icons.sms_outlined, 'پیام مشتری', () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerMessagesPage(client: widget.client, orderId: widget.orderId)))),
                    _Action(Icons.note_add_outlined, 'یادداشت داخلی', () => _note()),
                  ],
                ),
              ],
            );
          },
        ),
      );

  Future<void> _note() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('یادداشت سفارش'), content: TextField(controller: c, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'متن یادداشت')), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ثبت'))]));
    if (ok == true && c.text.trim().isNotEmpty) {
      await widget.client.addOrderNote(widget.orderId, c.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('یادداشت ثبت شد.')));
    }
    c.dispose();
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon), const SizedBox(width: 8), Flexible(child: Text(label, textAlign: TextAlign.center))]),
        ),
      );
}
