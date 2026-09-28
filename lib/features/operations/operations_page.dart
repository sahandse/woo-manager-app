import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class OperationsPage extends StatelessWidget{const OperationsPage({super.key,required this.client});final ApiClient client;@override Widget build(BuildContext context)=>DefaultTabController(length:3,child:Scaffold(appBar:AppBar(title:const Text('مرکز مدیریت'),bottom:const TabBar(tabs:[Tab(text:'اعلان‌ها'),Tab(text:'کوپن‌ها'),Tab(text:'دیدگاه‌ها')])),body:TabBarView(children:[_Alerts(client),_Coupons(client),_Reviews(client)])));}

class _Alerts extends StatefulWidget{const _Alerts(this.client);final ApiClient client;@override State<_Alerts> createState()=>_AlertsState();}
class _AlertsState extends State<_Alerts>{late Future<Map<String,dynamic>> future;@override void initState(){super.initState();future=widget.client.notifications();}void load()=>setState(()=>future=widget.client.notifications());@override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(future:future,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return _Retry(load);final items=s.data!['items'] as List? ?? const [];return RefreshIndicator(onRefresh:()async=>load(),child:items.isEmpty?ListView(children:const [SizedBox(height:180),Icon(Icons.task_alt_rounded,size:52),SizedBox(height:12),Text('مورد نیازمند توجه وجود ندارد.',textAlign:TextAlign.center)]):ListView.separated(padding:const EdgeInsets.all(16),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(context,i){final n=Map<String,dynamic>.from(items[i] as Map);final error=n['severity']=='error';return Card(child:ListTile(contentPadding:const EdgeInsets.all(14),leading:CircleAvatar(backgroundColor:(error?Colors.red:Colors.amber).withValues(alpha:.12),child:Icon(error?Icons.error_outline:Icons.notifications_none_rounded,color:error?Colors.red:Colors.amber.shade800)),title:Text('${n['title']}',style:const TextStyle(fontWeight:FontWeight.w700)),trailing:Badge(label:Text('${n['count']}'))));}));});}

class _Coupons extends StatefulWidget{const _Coupons(this.client);final ApiClient client;@override State<_Coupons> createState()=>_CouponsState();}
class _CouponsState extends State<_Coupons>{late Future<Map<String,dynamic>> future;@override void initState(){super.initState();load();}void load()=>setState(()=>future=widget.client.coupons());Future<void> edit([Map<String,dynamic>? item])async{final code=TextEditingController(text:'${item?['code']??''}'),amount=TextEditingController(text:'${item?['amount']??''}'),limit=TextEditingController(text:'${item?['usage_limit']??''}');String type='${item?['discount_type']??'percent'}';final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(context)=>StatefulBuilder(builder:(context,setModal)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(context).bottom+20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(item==null?'کوپن جدید':'ویرایش کوپن',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:16),TextField(controller:code,decoration:const InputDecoration(labelText:'کد تخفیف')),const SizedBox(height:10),DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'نوع تخفیف'),items:const [DropdownMenuItem(value:'percent',child:Text('درصدی')),DropdownMenuItem(value:'fixed_cart',child:Text('مبلغ ثابت سبد')),DropdownMenuItem(value:'fixed_product',child:Text('مبلغ ثابت محصول'))],onChanged:(v)=>setModal(()=>type=v!)),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'مقدار'))),const SizedBox(width:10),Expanded(child:TextField(controller:limit,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'محدودیت مصرف')))]),const SizedBox(height:16),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ذخیره در ووکامرس'))]))));if(ok==true&&code.text.trim().isNotEmpty){final data={'code':code.text.trim(),'amount':amount.text.trim(),'usage_limit':int.tryParse(limit.text)??0,'discount_type':type};try{if(item==null){await widget.client.createCoupon(data);}else{await widget.client.updateCoupon((item['id'] as num).toInt(),data);}load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره کوپن انجام نشد: $e')));}}code.dispose();amount.dispose();limit.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(),icon:const Icon(Icons.add_rounded),label:const Text('کوپن جدید')),body:FutureBuilder<Map<String,dynamic>>(future:future,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return _Retry(load);final items=s.data!['items'] as List? ?? const [];return RefreshIndicator(onRefresh:()async=>load(),child:items.isEmpty?ListView(children:const [SizedBox(height:180),Icon(Icons.confirmation_number_outlined,size:52),SizedBox(height:12),Text('کوپن فعالی وجود ندارد.',textAlign:TextAlign.center)]):ListView.separated(padding:const EdgeInsets.all(16),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(context,i){final c=Map<String,dynamic>.from(items[i] as Map);return Card(child:ListTile(onTap:()=>edit(c),contentPadding:const EdgeInsets.all(14),leading:const CircleAvatar(child:Icon(Icons.percent_rounded)),title:Text('${c['code']}',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${c['amount']}  •  ${c['usage_count']} بار استفاده'),trailing:const Icon(Icons.edit_outlined)));}));}));}

class _Reviews extends StatefulWidget{const _Reviews(this.client);final ApiClient client;@override State<_Reviews> createState()=>_ReviewsState();}
class _ReviewsState extends State<_Reviews>{
  late Future<List<dynamic>> future;
  @override void initState(){super.initState();load();}
  void load()=>setState(()=>future=widget.client.reviews());
  Future<void> change(int id,String status)async{
    try{await widget.client.updateReview(id,status);load();}
    catch(error){if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تغییر دیدگاه انجام نشد: '+error.toString())));}}
  }
  @override Widget build(BuildContext context){
    return FutureBuilder<List<dynamic>>(
      future:future,
      builder:(context,snapshot){
        if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
        if(snapshot.hasError)return _Retry(load);
        final items=snapshot.data??const [];
        if(items.isEmpty)return ListView(children:const [SizedBox(height:180),Icon(Icons.rate_review_outlined,size:52),SizedBox(height:12),Text('دیدگاهی وجود ندارد.',textAlign:TextAlign.center)]);
        return ListView.separated(
          padding:const EdgeInsets.all(16),
          itemCount:items.length,
          separatorBuilder:(_,__)=>const SizedBox(height:10),
          itemBuilder:(context,index){
            final review=Map<String,dynamic>.from(items[index] as Map);
            final approved=review['status']=='approved';
            return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              Text(review['author'].toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
              Text(review['product_name'].toString(),style:Theme.of(context).textTheme.bodySmall),
              const SizedBox(height:12),Text(review['content'].toString()),const SizedBox(height:12),
              Wrap(spacing:8,children:[
                FilledButton.tonal(onPressed:()=>change((review['id'] as num).toInt(),approved?'hold':'approve'),child:Text(approved?'لغو تأیید':'تأیید')),
                TextButton(onPressed:()=>change((review['id'] as num).toInt(),'spam'),child:const Text('هرزنامه')),
              ]),
            ])));
          },
        );
      },
    );
  }
}
class _Retry extends StatelessWidget{const _Retry(this.retry);final VoidCallback retry;@override Widget build(BuildContext context)=>Center(child:FilledButton.icon(onPressed:retry,icon:const Icon(Icons.refresh_rounded),label:const Text('تلاش دوباره')));}
