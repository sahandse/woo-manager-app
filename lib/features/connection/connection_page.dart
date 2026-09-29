import 'package:flutter/material.dart';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import '../dashboard/dashboard_page.dart';
import 'qr_scanner_page.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});
  @override State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final site = TextEditingController();
  final code = TextEditingController();
  bool loading = false;
  String? error;
  static const storage = FlutterSecureStorage();
  Future<String> _deviceId() async {
    final current = await storage.read(key: 'device_id'); if (current != null) return current;
    final random = Random.secure(); final id = List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await storage.write(key: 'device_id', value: id); return id;
  }
  Future<void> _connect() async {
    final url=site.text.trim().replaceAll(RegExp(r'/$'),'');final uri=Uri.tryParse(url);final secure=uri?.scheme=='https'||(uri?.scheme=='http'&&(uri?.host=='localhost'||uri?.host=='127.0.0.1'));if(uri==null||!uri.hasScheme||uri.host.isEmpty||!secure||code.text.trim().length!=6){setState(()=>error='آدرس HTTPS معتبر و کد شش‌رقمی را وارد کنید.');return;}
    setState((){loading=true;error=null;});
    try { final result=await ApiClient.pair(url,code.text.trim(),await _deviceId());if(result['api_version']!=2)throw const FormatException();final token=result['token'] as String,storeName=(result['site_name']??Uri.parse(url).host).toString(); await storage.write(key:'site_url',value:url); await storage.write(key:'token',value:token);await storage.write(key:'store_name',value:storeName); if(!mounted)return; Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>DashboardPage(storeName:storeName,client:ApiClient(url,token)))); }
    on DioException catch(e){setState(()=>error=(e.response?.data is Map?(e.response?.data['message']??'خطا در اتصال'): 'ارتباط با سایت برقرار نشد.').toString());}
    on FormatException{setState(()=>error='نسخه افزونه با اپ سازگار نیست؛ افزونه Woo Manager ۱.۱.۰ را نصب کن.');}
    catch(_){setState(()=>error='اتصال انجام نشد. تنظیمات افزونه و اینترنت را بررسی کنید.');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override void dispose() { site.dispose(); code.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child:ClipRRect(borderRadius:BorderRadius.circular(24),child:Image.asset('assets/woo_manager_logo.png',width:88,height:88,fit:BoxFit.cover))),
      const SizedBox(height: 28), Text('فروشگاهت همیشه همراهته',style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), Text('برای اتصال امن، آدرس سایت و کد یک‌بارمصرف ساخته‌شده در افزونه را وارد کن.',style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 28), TextField(controller: site,keyboardType: TextInputType.url,textDirection: TextDirection.ltr,decoration: const InputDecoration(labelText:'آدرس فروشگاه',hintText:'https://example.com',prefixIcon:Icon(Icons.language_rounded))),
      const SizedBox(height:10),OutlinedButton.icon(onPressed:()async{final value=await Navigator.push<String>(context,MaterialPageRoute(builder:(_)=>const QrScannerPage()));if(value!=null)site.text=value;},icon:const Icon(Icons.qr_code_scanner_rounded),label:const Text('اسکن QR فروشگاه')),
      const SizedBox(height: 14), TextField(controller: code,keyboardType: TextInputType.number,textDirection: TextDirection.ltr,decoration: const InputDecoration(labelText:'کد اتصال',hintText:'۱۲۳۴۵۶',prefixIcon:Icon(Icons.password_rounded))),
      if(error!=null)...[const SizedBox(height:14),Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))],
      const SizedBox(height: 22), FilledButton.icon(onPressed:loading?null:_connect,icon:loading?const SizedBox.square(dimension:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.link_rounded),label:const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text('اتصال امن به فروشگاه'))),
    ]))))),
  );
}
