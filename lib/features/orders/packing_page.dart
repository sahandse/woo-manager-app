import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/network/api_client.dart';

class PackingPage extends StatefulWidget {
  const PackingPage({super.key, required this.client, required this.orderId});
  final ApiClient client;
  final int orderId;
  @override State<PackingPage> createState()=>_PackingPageState();
}
class _PackingPageState extends State<PackingPage>{
  late Future<Map<String,dynamic>> future;
  final code=TextEditingController();
  bool camera=false,busy=false;
  String? lastCode;
  @override void initState(){super.initState();load();}
  void load()=>setState(()=>future=widget.client.packing(widget.orderId));
  Future<void> scan(String value)async{
    if(busy||value.isEmpty||value==lastCode)return;setState(()=>busy=true);lastCode=value;
    try{await widget.client.scanPacking(widget.orderId,value);code.clear();load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('مغایرت کالا: $e'),backgroundColor:Theme.of(context).colorScheme.error));}
    finally{if(mounted)setState(()=>busy=false);Future.delayed(const Duration(seconds:2),()=>lastCode=null);}
  }
  Future<void> completeOrder()async{setState(()=>busy=true);try{await widget.client.completePacking(widget.orderId);load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('بسته‌بندی سفارش با موفقیت تکمیل شد.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}finally{if(mounted)setState(()=>busy=false);}}
  @override void dispose(){code.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text('آماده‌سازی سفارش #${widget.orderId}'),actions:[IconButton(onPressed:()=>setState(()=>camera=!camera),icon:Icon(camera?Icons.close:Icons.qr_code_scanner_rounded))]),
    body:FutureBuilder<Map<String,dynamic>>(future:future,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:FilledButton.icon(onPressed:load,icon:const Icon(Icons.refresh),label:const Text('تلاش دوباره')));
      final data=s.data!,items=data['items'] as List? ?? const [],allDone=data['complete']==true;
      return ListView(padding:const EdgeInsets.all(16),children:[
        if(camera)ClipRRect(borderRadius:BorderRadius.circular(22),child:SizedBox(height:230,child:MobileScanner(onDetect:(capture){final value=capture.barcodes.firstOrNull?.rawValue;if(value!=null)scan(value);}))),
        if(camera)const SizedBox(height:12),
        Row(children:[Expanded(child:TextField(controller:code,textDirection:TextDirection.ltr,onSubmitted:scan,decoration:const InputDecoration(labelText:'بارکد، SKU یا شناسه مدل',prefixIcon:Icon(Icons.barcode_reader)))),const SizedBox(width:8),FilledButton(onPressed:busy?null:()=>scan(code.text.trim()),child:const Icon(Icons.add))]),
        const SizedBox(height:16),
        ...items.map((raw){final item=Map<String,dynamic>.from(raw as Map),required=(item['required'] as num).toInt(),scanned=(item['scanned'] as num).toInt(),ok=scanned==required;final meta=item['meta'] as List? ?? const [];return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[CircleAvatar(backgroundColor:(ok?Colors.green:Colors.orange).withValues(alpha:.12),child:Icon(ok?Icons.check_rounded:Icons.inventory_2_outlined,color:ok?Colors.green:Colors.orange)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${item['name']}',style:const TextStyle(fontWeight:FontWeight.w800)),Text('SKU: ${item['sku']?.toString().isEmpty==true?'—':item['sku']}')]))]),const SizedBox(height:10),...meta.map((m)=>Text('${m['key']}: ${m['value']}',style:Theme.of(context).textTheme.bodySmall)),const SizedBox(height:10),LinearProgressIndicator(value:required==0?0:scanned/required),const SizedBox(height:6),Text('$scanned از $required عدد',textAlign:TextAlign.left)])));}),
        const SizedBox(height:12),FilledButton.icon(onPressed:allDone&&!busy?completeOrder:null,icon:const Icon(Icons.verified_rounded),label:Padding(padding:const EdgeInsets.all(14),child:Text(allDone?'تأیید نهایی بسته‌بندی':'ابتدا همه کالاها را تطبیق بده'))),
      ]);
    }),
  );
}
