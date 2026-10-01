import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../content/content_page.dart';
import '../customers/customers_page.dart';
import '../inventory/inventory_page.dart';
import '../messages/customer_messages_page.dart';
import '../operations/attention_center_page.dart';
import '../operations/operations_page.dart';
import '../operations/workflow_center_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import '../shipping/shipping_center_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.client});
  final ApiClient client;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('بیشتر')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _tile(context, Icons.priority_high_rounded, 'نیازمند اقدام', 'هشدارهای قابل اقدام سفارش و موجودی', () => AttentionCenterPage(client: client)),
            _tile(context, Icons.local_shipping_outlined, 'مرکز ارسال', 'تاپین، استعلام هزینه، رهگیری و مرسوله‌ها', () => ShippingCenterPage(client: client)),
            _tile(context, Icons.inventory_outlined, 'انبار', 'کم‌موجودی، ناموجودها و اسکن بارکد', () => InventoryPage(client: client)),
            _tile(context, Icons.sms_outlined, 'پیام به مشتری', 'قالب‌های آماده و پیام سفارشی برای سفارش', () => CustomerMessagesPage(client: client)),
            _tile(context, Icons.bar_chart_rounded, 'گزارش‌ها', 'فروش، میانگین سفارش، پرفروش‌ها و سود', () => ReportsPage(client: client)),
            _tile(context, Icons.people_outline_rounded, 'مشتریان', 'پروفایل، خریدها، آدرس‌ها و سفارش‌ها', () => CustomersPage(client: client)),
            _tile(context, Icons.notifications_active_outlined, 'مرکز مدیریت', 'اعلان‌ها، کوپن‌ها و دیدگاه‌ها', () => OperationsPage(client: client)),
            _tile(context, Icons.hub_outlined, 'Workflow Center', 'مرجوعی، صف خطا، تیم، تاریخچه و سود', () => WorkflowCenterPage(client: client)),
            _tile(context, Icons.perm_media_outlined, 'رسانه و محتوا', 'تصاویر و محتوای سایت', () => ContentPage(client: client)),
            _tile(context, Icons.settings_outlined, 'تنظیمات و اتصال', 'سلامت سرویس‌ها، تاپین، SMS و امنیت', () => SettingsPage(client: client)),
          ],
        ),
      );

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, Widget Function() page) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page())),
        ),
      );
}
