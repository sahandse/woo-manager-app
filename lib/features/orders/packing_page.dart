import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/format/persian_digits.dart';
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

  @override void initState(){super.initState();future=widget.client.packing(widget.orderId);}
  void load()=>setState(()=>future=widget.client.packing(widget.orderId));
  int _int(dynamic value)=>value is num?value.toInt():int.tryParse('$value')??0;
  String _error(Object error){
    if(error is DioException){
      final data=error.response?.data;
      if(data is Map&&data['message']!=null)return '${data['message']}';
      if(error.response?.statusCode==404)return 'API آماده‌سازی سفارش روی افزونه فعال نیست. افزونه Woo Manager را به نسخه ۱.۲.۲ به‌روزرسانی کنید.';
      if(error.response?.statusCode==401||error.response?.statusCode==403)return 'دسترسی این دستگاه معتبر نیست. دوباره به فروشگاه متصل شوید.';
    }
    return error.toString().replaceFirst('DioException [bad response]: ','');
  }

  Future<void> scan(String value)async{
    value=value.trim();
    if(busy||value.isEmpty||value==lastCode)return;
    setState(()=>busy=true);lastCode=value;
    try{
      final data=await widget.client.scanPacking(widget.orderId,value);
      code.clear();
      if(mounted)setState(()=>future=Future.value(data));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_error(e)),backgroundColor:Theme.of(context).colorScheme.error));
    }finally{
      if(mounted)setState(()=>busy=false);
      Future.delayed(const Duration(seconds:2),(){lastCode=null;});
    }
  }

  Future<void> completeOrder()async{
    if(busy)return;
    setState(()=>busy=true);
    try{
      final data=await widget.client.completePacking(widget.orderId);
      if(mounted){
        setState(()=>future=Future.value(data));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('بسته‌بندی سفارش با موفقیت تکمیل شد.')));
      }
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_error(e))));}
    finally{if(mounted)setState(()=>busy=false);}
  }

  @override void dispose(){code.dispose();super.dispose();}

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(
      title:Text('آماده‌سازی سفارش ${widget.orderId.fa}'),
      actions:[
        IconButton(tooltip:'به‌روزرسانی',onPressed:busy?null:load,icon:const Icon(Icons.refresh_rounded)),
        IconButton(tooltip:camera?'بستن دوربین':'اسکن با دوربین',onPressed:busy?null:()=>setState(()=>camera=!camera),icon:Icon(camera?Icons.close:Icons.qr_code_scanner_rounded)),
      ],
    ),
    body:FutureBuilder<Map<String,dynamic>>(future:future,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error(s.error!),textAlign:TextAlign.center),const SizedBox(height:16),FilledButton.icon(onPressed:load,icon:const Icon(Icons.refresh),label:const Text('تلاش دوباره'))])));
      final data=s.data??const <String,dynamic>{};
      final items=(data['items'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
      final allDone=data['complete']==true;
      final packedAt='${data['packed_at']??''}'.trim();
      return ListView(padding:const EdgeInsets.all(16),children:[
        if(busy)const LinearProgressIndicator(),
        if(camera)ClipRRect(borderRadius:BorderRadius.circular(22),child:SizedBox(height:230,child:MobileScanner(onDetect:(capture){if(capture.barcodes.isEmpty)return;final value=capture.barcodes.first.rawValue;if(value!=null)scan(value);}))),
        if(camera)const SizedBox(height:12),
        Row(children:[Expanded(child:TextField(controller:code,textDirection:TextDirection.ltr,onSubmitted:scan,decoration:const InputDecoration(labelText:'بارکد، SKU یا شناسه مدل',prefixIcon:Icon(Icons.barcode_reader)))),const SizedBox(width:8),FilledButton(onPressed:busy?null:()=>scan(code.text),child:const Icon(Icons.add))]),
        const SizedBox(height:16),
        if(items.isEmpty)Card(child:Padding(padding:const EdgeInsets.all(20),child:Text('کالایی برای آماده‌سازی در این سفارش وجود ندارد.',textAlign:TextAlign.center,style:Theme.of(context).textTheme.titleMedium))),
        ...items.map((item){
          final required=_int(item['required']);
          final scanned=_int(item['scanned']).clamp(0,required).toInt();
          final ok=required>0&&scanned>=required;
          final meta=(item['meta'] as List? ?? const []).whereType<Map>();
          final sku='${item['sku']??''}'.trim();
          final progress=required<=0?0.0:(scanned/required).clamp(0,1).toDouble();
          return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Row(children:[CircleAvatar(backgroundColor:(ok?Colors.green:Colors.orange).withValues(alpha:.12),child:Icon(ok?Icons.check_rounded:Icons.inventory_2_outlined,color:ok?Colors.green:Colors.orange)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${item['name']??'کالا'}',style:const TextStyle(fontWeight:FontWeight.w800)),Text('SKU: ${sku.isEmpty?'—':sku}')]))]),
            const SizedBox(height:10),
            ...meta.map((m)=>Text('${m['key']??''}: ${m['value']??''}',style:Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height:10),
            LinearProgressIndicator(value:progress),
            const SizedBox(height:6),
            Text('${scanned.fa} از ${required.fa} عدد',textAlign:TextAlign.left),
          ])));
        }),
        const SizedBox(height:12),
        if(packedAt.isNotEmpty)Padding(padding:const EdgeInsets.only(bottom:10),child:Text('این سفارش قبلاً بسته‌بندی و ثبت نهایی شده است.',textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w700))),
        FilledButton.icon(onPressed:allDone&&!busy?completeOrder:null,icon:const Icon(Icons.verified_rounded),label:Padding(padding:const EdgeInsets.all(14),child:Text(allDone?'تأیید نهایی بسته‌بندی':'ابتدا همه کالاها را تطبیق بده'))),
      ]);
    }),
  );
}
