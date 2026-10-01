import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/format/persian_digits.dart';
import '../../core/network/api_client.dart';
import 'packing_page.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId, required this.client});
  final int orderId;
  final ApiClient client;
  @override State<OrderDetailPage> createState()=>_OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage>{
  late Future<Map<String,dynamic>> _future;
  bool _busy=false;

  @override void initState(){super.initState();_future=widget.client.order(widget.orderId);}
  void _reload()=>setState(()=>_future=widget.client.order(widget.orderId));

  String _error(Object error){
    if(error is DioException){
      final data=error.response?.data;
      if(data is Map&&data['message']!=null)return '${data['message']}';
      if(error.response?.statusCode==404)return 'سفارش پیدا نشد یا API سفارش‌ها روی افزونه در دسترس نیست.';
      if(error.response?.statusCode==401||error.response?.statusCode==403)return 'دسترسی این دستگاه معتبر نیست. دوباره به فروشگاه متصل شوید.';
      if(error.response?.statusCode!=null)return 'خطای ${error.response!.statusCode}: دریافت جزئیات سفارش انجام نشد.';
      return 'ارتباط با فروشگاه انجام نشد. اینترنت، آدرس سایت و افزونه Woo Manager را بررسی کنید.';
    }
    return error.toString().replaceFirst('FormatException: ','');
  }

  List<Map<String,dynamic>> _maps(dynamic value){
    if(value is! List)return const [];
    final out=<Map<String,dynamic>>[];
    for(final entry in value){if(entry is Map)out.add(Map<String,dynamic>.from(entry));}
    return out;
  }

  Map<String,dynamic> _map(dynamic value)=>value is Map?Map<String,dynamic>.from(value):<String,dynamic>{};

  Future<void> _run(Future<Map<String,dynamic>> Function() action,{String? success})async{
    if(_busy)return;
    setState(()=>_busy=true);
    try{
      final data=await action();
      if(mounted){setState(()=>_future=Future.value(data));if(success!=null)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(success)));}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_error(e)),backgroundColor:Theme.of(context).colorScheme.error));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  String _preferred(dynamic primary,dynamic fallback,{String empty='-'}){
    final a='${primary??''}'.trim();if(a.isNotEmpty)return a;
    final b='${fallback??''}'.trim();return b.isNotEmpty?b:empty;
  }

  double _number(dynamic value)=>value is num?value.toDouble():double.tryParse('$value'.replaceAll('۰','0').replaceAll('۱','1').replaceAll('۲','2').replaceAll('۳','3').replaceAll('۴','4').replaceAll('۵','5').replaceAll('۶','6').replaceAll('۷','7').replaceAll('۸','8').replaceAll('۹','9').replaceAll('٫','.').replaceAll('٬',''))??0;

  Future<void> _addNote()async{
    final controller=TextEditingController();bool customer=false;
    final ok=await showDialog<bool>(context:context,builder:(context)=>StatefulBuilder(builder:(context,setModalState)=>AlertDialog(
      title:const Text('یادداشت جدید'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:controller,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'متن یادداشت')),CheckboxListTile(contentPadding:EdgeInsets.zero,value:customer,onChanged:(v)=>setModalState(()=>customer=v??false),title:const Text('برای مشتری قابل مشاهده باشد'))]),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ثبت'))],
    )));
    final text=controller.text.trim();controller.dispose();
    if(ok==true&&text.isNotEmpty)await _run(()=>widget.client.addOrderNote(widget.orderId,text,customerNote:customer),success:'یادداشت سفارش ثبت شد.');
  }

  Future<void> _refund(Map<String,dynamic> order)async{
    final max=_number(order['refundable_amount']);
    final amount=TextEditingController(text:max.toStringAsFixed(max%1==0?0:2));
    final reason=TextEditingController();bool payment=false,restock=false;
    final ok=await showDialog<bool>(context:context,builder:(context)=>StatefulBuilder(builder:(context,setModalState)=>AlertDialog(
      title:const Text('ثبت بازپرداخت'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text('حداکثر مبلغ قابل بازپرداخت: ${max.fa} ${order['currency']??''}'),
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'مبلغ')),
        TextField(controller:reason,decoration:const InputDecoration(labelText:'دلیل بازپرداخت')),
        SwitchListTile(contentPadding:EdgeInsets.zero,value:payment,onChanged:(v)=>setModalState(()=>payment=v),title:const Text('بازپرداخت از درگاه پرداخت')),
        SwitchListTile(contentPadding:EdgeInsets.zero,value:restock,onChanged:(v)=>setModalState(()=>restock=v),title:const Text('بازگرداندن موجودی کالا')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('تأیید نهایی'))],
    )));
    final value=_number(amount.text);final refundReason=reason.text.trim();amount.dispose();reason.dispose();
    if(ok==true){if(value<=0||value>max){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('مبلغ بازپرداخت معتبر نیست.')));return;}await _run(()=>widget.client.refundOrder(widget.orderId,amount:value,reason:refundReason,refundPayment:payment,restockItems:restock),success:'بازپرداخت سفارش ثبت شد.');}
  }

  Widget _render(Map<String,dynamic> o){
    try{
      final items=_maps(o['items']);
      final history=_maps(o['history']);
      final refunds=_maps(o['refunds']);
      final shipping=_map(o['shipping']);
      final billing=_map(o['billing']);
      final shipment=_map(o['shipment']);
      final status='${o['status']??''}';
      final options=_maps(o['status_options']).where((e)=>'${e['value']??''}'.isNotEmpty).toList();
      final optionValues=options.map((e)=>'${e['value']}').toSet();
      final warning='${o['_detail_warning']??''}'.trim();
      final receiver='${_preferred(shipping['first_name'],billing['first_name'],empty:'')} ${_preferred(shipping['last_name'],billing['last_name'],empty:'')}'.trim();
      return ListView(padding:const EdgeInsets.all(16),children:[
        if(_busy)const LinearProgressIndicator(),
        if(warning.isNotEmpty)Card(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[const Icon(Icons.info_outline),const SizedBox(width:8),Expanded(child:Text(warning))]))),
        _Section(title:'وضعیت و مبلغ',child:Column(children:[
          if(options.isNotEmpty)DropdownButtonFormField<String>(value:optionValues.contains(status)?status:null,decoration:const InputDecoration(labelText:'وضعیت سفارش'),items:options.map((m)=>DropdownMenuItem(value:'${m['value']}',child:Text('${m['label']??m['value']}'))).toList(),onChanged:_busy?null:(value){if(value!=null&&value!=status)_run(()=>widget.client.updateOrderStatus(widget.orderId,value),success:'وضعیت سفارش تغییر کرد.');})
          else _row('وضعیت',status.isEmpty?'-':status),
          _row('جمع کل','${o['total'].fa} ${o['currency']??''}'),
          _row('هزینه ارسال','${o['shipping_total'].fa} ${o['currency']??''}'),
          _row('تخفیف','${o['discount_total'].fa} ${o['currency']??''}'),
          _row('بازپرداخت‌شده','${o['total_refunded'].fa} ${o['currency']??''}'),
          _row('روش پرداخت','${o['payment_method']??'-'}')
        ])),
        _Section(title:'محصولات سفارش',child:items.isEmpty?const Text('محصولی در این سفارش ثبت نشده است.'):Column(children:items.map((item){
          final image='${item['image']??''}'.trim();final sku='${item['sku']??''}'.trim();
          return ListTile(contentPadding:EdgeInsets.zero,leading:image.isEmpty?const Icon(Icons.inventory_2_outlined):ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.network(image,width:48,height:48,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox(width:48,height:48,child:Icon(Icons.broken_image_outlined)))),title:Text('${item['name']??'کالا'}'),subtitle:Text('تعداد: ${item['quantity'].fa} • SKU: ${(sku.isEmpty?'-':sku).fa}'),trailing:Text('${item['total'].fa} ${o['currency']??''}'));
        }).toList())),
        _Section(title:'اطلاعات ارسال',child:Column(children:[
          _row('گیرنده',receiver.isEmpty?'-':receiver),_row('تلفن',_preferred(shipping['phone'],billing['phone'])),_row('آدرس',_address(shipping,billing)),_row('روش ارسال','${o['shipping_method']??'-'}'),_row('شناسه تاپین','${shipment['tapin_order_id']??'-'}'),_row('کد رهگیری','${shipment['tracking_number']??'-'}')
        ])),
        _Section(title:'عملیات',child:Wrap(spacing:8,runSpacing:8,children:[
          FilledButton.icon(onPressed:_busy?null:()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>PackingPage(client:widget.client,orderId:widget.orderId)));if(mounted)_reload();},icon:const Icon(Icons.qr_code_scanner_rounded),label:const Text('آماده‌سازی و اسکن')),
          FilledButton.icon(onPressed:_busy?null:_addNote,icon:const Icon(Icons.note_add_outlined),label:const Text('افزودن یادداشت')),
          OutlinedButton.icon(onPressed:_busy||_number(o['refundable_amount'])<=0?null:()=>_refund(o),icon:const Icon(Icons.currency_exchange_rounded),label:const Text('بازپرداخت')),
        ])),
        if(refunds.isNotEmpty)_Section(title:'بازپرداخت‌ها',child:Column(children:refunds.map((r)=>ListTile(contentPadding:EdgeInsets.zero,title:Text('${r['amount'].fa} ${o['currency']??''}'),subtitle:Text('${r['reason']??''}\n${r['date']??''}'))).toList())),
        _Section(title:'تاریخچه عملیات',child:history.isEmpty?const Text('تاریخچه‌ای ثبت نشده است.'):Column(children:history.map((h)=>ListTile(contentPadding:EdgeInsets.zero,leading:Icon(h['customer_note']==true?Icons.person_outline:Icons.settings_outlined),title:Text('${h['content']??''}'),subtitle:Text('${h['date']??''}'))).toList())),
      ]);
    }catch(e){
      return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.error_outline_rounded,size:42),const SizedBox(height:12),const Text('نمایش جزئیات این سفارش با خطا روبه‌رو شد.'),const SizedBox(height:8),Text(_error(e),textAlign:TextAlign.center),const SizedBox(height:16),FilledButton.icon(onPressed:_reload,icon:const Icon(Icons.refresh_rounded),label:const Text('بارگذاری دوباره'))])));
    }
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text('سفارش ${widget.orderId.fa}'),actions:[IconButton(tooltip:'به‌روزرسانی',onPressed:_busy?null:_reload,icon:const Icon(Icons.refresh_rounded))]),
    body:FutureBuilder<Map<String,dynamic>>(future:_future,builder:(context,snapshot){
      if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off_rounded,size:42),const SizedBox(height:12),Text(_error(snapshot.error!),textAlign:TextAlign.center),const SizedBox(height:16),FilledButton.icon(onPressed:_reload,icon:const Icon(Icons.refresh_rounded),label:const Text('تلاش دوباره'))])));
      final data=snapshot.data;
      if(data==null||data.isEmpty)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('اطلاعات این سفارش خالی است.'),const SizedBox(height:16),FilledButton.icon(onPressed:_reload,icon:const Icon(Icons.refresh_rounded),label:const Text('تلاش دوباره'))])));
      return _render(data);
    }),
  );

  Widget _row(String title,String value)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(title,style:const TextStyle(color:Colors.grey))),Expanded(flex:2,child:Text(value.trim().isEmpty?'-':value))]));
  String _address(Map<String,dynamic> shipping,Map<String,dynamic> billing){final useShipping='${shipping['address_1']??''}'.trim().isNotEmpty||'${shipping['city']??''}'.trim().isNotEmpty;final source=useShipping?shipping:billing;final value=[source['state'],source['city'],source['address_1'],source['address_2'],source['postcode']].map((v)=>'${v??''}'.trim()).where((v)=>v.isNotEmpty).join('، ');return value.isEmpty?'-':value;}
}

class _Section extends StatelessWidget{const _Section({required this.title,required this.child});final String title;final Widget child;@override Widget build(BuildContext context)=>Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w700)),const SizedBox(height:12),child])));}
