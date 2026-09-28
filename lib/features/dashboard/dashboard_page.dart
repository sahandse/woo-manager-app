import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:printing/printing.dart';
import '../../core/network/api_client.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.storeName, required this.client});
  final String storeName;
  final ApiClient client;
  @override State<DashboardPage> createState()=>_DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage>{ late Future<List<dynamic>> orders; int? busyOrder; @override void initState(){super.initState();orders=widget.client.orders();}
  Future<void> _print(List<String> ids,String type)async{final result=await widget.client.shipmentPdf(ids,type:type);await Printing.sharePdf(bytes:base64Decode(result['content_base64'] as String),filename:result['filename'] as String);}
  Future<void> _ship(int orderId)async{setState(()=>busyOrder=orderId);try{final result=await widget.client.registerShipment(orderId,{});final raw=result['entries'];final entries=raw is Map?Map<String,dynamic>.from(raw):<String,dynamic>{};if(!mounted){return;}await showDialog(context:context,builder:(context)=>AlertDialog(title:const Text('مرسوله ثبت شد'),content:Text('کد رهگیری: ${entries['barcode']??'از تاپین دریافت نشد'}'),actions:[if(entries['id']!=null)TextButton(onPressed:()=>_print([entries['id'].toString()],'label'),child:const Text('لیبل PDF')),if(entries['order_id']!=null)TextButton(onPressed:()=>_print([entries['order_id'].toString()],'invoice'),child:const Text('فاکتور PDF')),TextButton(onPressed:()=>Navigator.pop(context),child:const Text('بستن'))]));setState(()=>orders=widget.client.orders());}catch(e){if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت مرسوله انجام نشد: $e')));}}finally{if(mounted){setState(()=>busyOrder=null);}}}
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.storeName),actions:[IconButton(onPressed:()=>setState(()=>orders=widget.client.orders()),icon:const Icon(Icons.refresh_rounded))]),
    body: FutureBuilder<List<dynamic>>(future:orders,builder:(context,snapshot){if(snapshot.connectionState!=ConnectionState.done){return const Center(child:CircularProgressIndicator());}if(snapshot.hasError){return _Error(message:snapshot.error.toString(),retry:()=>setState(()=>orders=widget.client.orders()));}final list=snapshot.data??[];final processing=list.where((o)=>o['status']=='processing').length;return ListView(padding:const EdgeInsets.all(16),children:[
      Text('مرکز عملیات',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:12),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.45,children:[
        _Stat(title:'آخرین سفارش‌ها',value:'${list.length}',icon:Icons.receipt_long_rounded),_Stat(title:'در حال انجام',value:'$processing',icon:Icons.local_shipping_outlined),
      ]),const SizedBox(height:22),
      Text('سفارش‌های واقعی',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w700)),const SizedBox(height:10),
      if(list.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(24),child:Text('سفارشی در ووکامرس وجود ندارد.',textAlign:TextAlign.center))) else ...list.map((o)=>Card(child:ListTile(title:Text('سفارش #${o['id']}'),subtitle:Text('${o['customer']} • ${o['status']}\n${o['total']} ${o['currency']}'),isThreeLine:true,trailing:busyOrder==o['id']?const SizedBox.square(dimension:22,child:CircularProgressIndicator(strokeWidth:2)):IconButton(tooltip:'ثبت واقعی در تاپین',onPressed:()=>_ship((o['id'] as num).toInt()),icon:const Icon(Icons.local_shipping_outlined))))),
    ]);}),
    bottomNavigationBar:NavigationBar(selectedIndex:0,destinations:const [NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard_rounded),label:'خانه'),NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'سفارش‌ها'),NavigationDestination(icon:Icon(Icons.inventory_2_outlined),label:'محصولات'),NavigationDestination(icon:Icon(Icons.more_horiz_rounded),label:'بیشتر')]),
  );
}
class _Stat extends StatelessWidget { const _Stat({required this.title,required this.value,required this.icon});final String title,value;final IconData icon;@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(icon),Text(value,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),Text(title)])));}
class _Error extends StatelessWidget{const _Error({required this.message,required this.retry});final String message;final VoidCallback retry;@override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off_rounded,size:44),const SizedBox(height:12),Text(message,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton(onPressed:retry,child:const Text('تلاش دوباره'))])));}
