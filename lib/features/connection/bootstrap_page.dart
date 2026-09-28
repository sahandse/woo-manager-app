import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import '../dashboard/dashboard_page.dart';
import 'connection_page.dart';

class BootstrapPage extends StatefulWidget{
  const BootstrapPage({super.key});
  @override State<BootstrapPage> createState()=>_BootstrapPageState();
}
class _BootstrapPageState extends State<BootstrapPage>{
  static const storage=FlutterSecureStorage();
  String? error;
  @override void initState(){super.initState();_open();}
  Future<void> _open()async{
    setState(()=>error=null);
    final site=await storage.read(key:'site_url'),token=await storage.read(key:'token'),storeName=await storage.read(key:'store_name');
    if(!mounted)return;
    if(site==null||token==null){_connection();return;}
    try{final client=ApiClient(site,token);final health=await client.health();if(health['api_version']!=1)throw const FormatException('نسخه افزونه با اپ سازگار نیست.');if(!mounted)return;Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>DashboardPage(storeName:storeName??Uri.parse(site).host,client:client)));}on FormatException{if(mounted)setState(()=>error='نسخه افزونه Woo Manager را به ۱.۰.۰ ارتقا بده.');}catch(_){if(mounted)setState(()=>error='اتصال ذخیره‌شده بررسی نشد. اینترنت یا وضعیت افزونه را کنترل کنید.');}
  }
  void _connection()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const ConnectionPage()));
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[ClipRRect(borderRadius:BorderRadius.circular(24),child:Image.asset('assets/woo_manager_logo.png',width:88,height:88,fit:BoxFit.cover)),const SizedBox(height:22),Text('مدیر فروشگاه',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:18),if(error==null)const CircularProgressIndicator()else...[Text(error!,textAlign:TextAlign.center),const SizedBox(height:18),FilledButton.icon(onPressed:_open,icon:const Icon(Icons.refresh_rounded),label:const Text('تلاش دوباره')),TextButton(onPressed:_connection,child:const Text('اتصال به فروشگاه دیگر'))]])))));
}
