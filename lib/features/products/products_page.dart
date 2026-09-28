import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../catalog/catalog_page.dart';
import 'product_detail_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.client});
  final ApiClient client;
  @override State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<Map<String, dynamic>> _future;
  final _search = TextEditingController();
  Timer? _timer;
  @override void initState(){super.initState();_load();}
  @override void dispose(){_timer?.cancel();_search.dispose();super.dispose();}
  void _load()=>setState(()=>_future=widget.client.products(search:_search.text.trim()));
  void _changed(String _){_timer?.cancel();_timer=Timer(const Duration(milliseconds:450),_load);}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('محصولات'),actions:[IconButton(tooltip:'مدیریت کاتالوگ',onPressed:()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>CatalogPage(client:widget.client)));_load();},icon:const Icon(Icons.tune_rounded)),IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded))]),body:Column(children:[Padding(padding:const EdgeInsets.all(16),child:SearchBar(controller:_search,hintText:'جست‌وجوی نام یا محصول',leading:const Icon(Icons.search_rounded),onChanged:_changed,trailing:[if(_search.text.isNotEmpty)IconButton(onPressed:(){_search.clear();_load();},icon:const Icon(Icons.close_rounded))])),Expanded(child:FutureBuilder<Map<String,dynamic>>(future:_future,builder:(context,snapshot){if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(snapshot.hasError)return Center(child:FilledButton(onPressed:_load,child:const Text('تلاش دوباره')));final data=snapshot.data!;final items=data['items'] as List? ?? const [];if(items.isEmpty)return const Center(child:Text('محصولی پیدا نشد.'));return RefreshIndicator(onRefresh:()async=>_load(),child:ListView.builder(padding:const EdgeInsets.fromLTRB(16,0,16,24),itemCount:items.length,itemBuilder:(context,index){final p=Map<String,dynamic>.from(items[index] as Map);return Card(child:ListTile(onTap:()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>ProductDetailPage(client:widget.client,productId:(p['id'] as num).toInt())));_load();},leading:ClipRRect(borderRadius:BorderRadius.circular(10),child:p['image']==null?const SizedBox(width:54,height:54,child:Icon(Icons.inventory_2_outlined)):Image.network(p['image'].toString(),width:54,height:54,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox(width:54,height:54,child:Icon(Icons.broken_image_outlined)))),title:Text(p['name'].toString(),maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text('${p['price'].toString().isEmpty?'بدون قیمت':p['price']}  •  ${_stock(p['stock_status'])}\n${p['status']=='publish'?'منتشرشده':'منتشرنشده'}${p['sku'].toString().isEmpty?'':'  •  ${p['sku']}'}'),isThreeLine:true,trailing:const Icon(Icons.chevron_left_rounded)));}));}))]));
  String _stock(dynamic value)=>value=='instock'?'موجود':value=='onbackorder'?'پیش‌خرید':'ناموجود';
}
