import 'package:flutter/material.dart';
import '../dashboard/dashboard_page.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});
  @override State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final site = TextEditingController();
  final code = TextEditingController();
  @override void dispose() { site.dispose(); code.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(width: 64,height: 64,decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary,borderRadius: BorderRadius.circular(20)),child: const Icon(Icons.storefront_rounded,color: Colors.white,size: 32)),
      const SizedBox(height: 28), Text('فروشگاهت همیشه همراهته',style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), Text('برای اتصال امن، آدرس سایت و کد یک‌بارمصرف ساخته‌شده در افزونه را وارد کن.',style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 28), TextField(controller: site,keyboardType: TextInputType.url,textDirection: TextDirection.ltr,decoration: const InputDecoration(labelText:'آدرس فروشگاه',hintText:'https://example.com',prefixIcon:Icon(Icons.language_rounded))),
      const SizedBox(height: 14), TextField(controller: code,keyboardType: TextInputType.number,textDirection: TextDirection.ltr,decoration: const InputDecoration(labelText:'کد اتصال',hintText:'۱۲۳۴۵۶',prefixIcon:Icon(Icons.password_rounded))),
      const SizedBox(height: 22), FilledButton.icon(onPressed:(){Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>DashboardPage(storeName: Uri.tryParse(site.text)?.host ?? 'فروشگاه من')));},icon:const Icon(Icons.link_rounded),label:const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text('اتصال به فروشگاه'))),
      const SizedBox(height: 14), const Text('در نسخه بعد اسکن QR و تبادل توکن رمزنگاری‌شده فعال می‌شود.',textAlign:TextAlign.center),
    ]))))),
  );
}
