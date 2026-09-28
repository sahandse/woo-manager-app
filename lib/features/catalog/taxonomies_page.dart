import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class TaxonomiesPage extends StatefulWidget {
  const TaxonomiesPage({super.key,required this.client});
  final ApiClient client;
  @override State<TaxonomiesPage> createState()=>_TaxonomiesPageState();
}

class _TaxonomiesPageState extends State<TaxonomiesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<List<dynamic>> _attributes;
  late Future<Map<String,dynamic>> _brands;
  bool _busy=false;
  @override void initState(){super.initState();_tabs=TabController(length:2,vsync:this);_load();}
  @override void dispose(){_tabs.dispose();super.dispose();}
  void _load(){_attributes=widget.client.attributes();_brands=widget.client.brands();}

  Future<Map<String,dynamic>?> _termDialog(String title,{Map<String,dynamic>? item})async{
    final name=TextEditingController(text:'${item?['name']??''}');
    final description=TextEditingController(text:'${item?['description']??''}');
    final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:Text(title),content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,autofocus:true,decoration:const InputDecoration(labelText:'نام')),const SizedBox(height:12),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'توضیحات'))])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ذخیره در ووکامرس'))]));
    final result=ok==true&&name.text.trim().isNotEmpty?{'name':name.text.trim(),'description':description.text.trim()}:null;
    name.dispose();description.dispose();return result;
  }

  Future<void> _attribute([Map<String,dynamic>? item])async{
    final name=TextEditingController(text:'${item?['name']??''}');
    String order='${item?['order_by']??'menu_order'}';bool archive=item?['has_archives']==true;
    final ok=await showDialog<bool>(context:context,builder:(context)=>StatefulBuilder(builder:(context,setModal)=>AlertDialog(title:Text(item==null?'ویژگی جدید':'ویرایش ویژگی'),content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,autofocus:true,decoration:const InputDecoration(labelText:'نام؛ مانند رنگ یا سایز')),const SizedBox(height:12),DropdownButtonFormField<String>(value:order,decoration:const InputDecoration(labelText:'ترتیب مقادیر'),items:const [DropdownMenuItem(value:'menu_order',child:Text('ترتیب سفارشی')),DropdownMenuItem(value:'name',child:Text('نام')),DropdownMenuItem(value:'name_num',child:Text('نام عددی')),DropdownMenuItem(value:'id',child:Text('شناسه'))],onChanged:(v)=>setModal(()=>order=v??'menu_order')),SwitchListTile(contentPadding:EdgeInsets.zero,value:archive,onChanged:(v)=>setModal(()=>archive=v),title:const Text('آرشیو عمومی ویژگی'))])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ذخیره'))])));
    if(ok==true&&name.text.trim().isNotEmpty){await _run(()async{final data={'name':name.text.trim(),'order_by':order,'has_archives':archive,if(item!=null)'slug':item['slug']};if(item==null){await widget.client.createAttribute(data);}else{await widget.client.updateAttribute((item['id'] as num).toInt(),data);}setState(()=>_attributes=widget.client.attributes());},'ویژگی ذخیره شد.');}
    name.dispose();
  }

  Future<void> _brand([Map<String,dynamic>? item])async{final current=await _brands;if(current['supported']!=true){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('قابلیت رسمی برند در این فروشگاه فعال نیست.')));return;}final data=await _termDialog(item==null?'برند جدید':'ویرایش برند',item:item);if(data==null)return;await _run(()async{if(item==null){await widget.client.createBrand(data);}else{await widget.client.updateBrand((item['id'] as num).toInt(),data);}setState(()=>_brands=widget.client.brands());},'برند ذخیره شد.');}
  Future<void> _run(Future<void> Function() action,String success)async{setState(()=>_busy=true);try{await action();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(success)));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('عملیات انجام نشد: $e')));}finally{if(mounted)setState(()=>_busy=false);}}

  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('ویژگی‌ها و برندها'),bottom:TabBar(controller:_tabs,tabs:const [Tab(text:'ویژگی‌ها',icon:Icon(Icons.tune_rounded)),Tab(text:'برندها',icon:Icon(Icons.sell_outlined))])),floatingActionButton:AnimatedBuilder(animation:_tabs,builder:(context,_)=>FloatingActionButton.extended(onPressed:_busy?null:()=>_tabs.index==0?_attribute():_brand(),icon:const Icon(Icons.add_rounded),label:Text(_tabs.index==0?'ویژگی جدید':'برند جدید'))),body:Stack(children:[TabBarView(controller:_tabs,children:[_attributeList(),_brandList()]),if(_busy)const LinearProgressIndicator()]));

  Widget _attributeList()=>FutureBuilder<List<dynamic>>(future:_attributes,builder:(context,snapshot){if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(snapshot.hasError)return _retry();final items=snapshot.data??const [];if(items.isEmpty)return const Center(child:Text('هنوز ویژگی‌ای در ووکامرس ثبت نشده است.'));return RefreshIndicator(onRefresh:()async=>setState(()=>_attributes=widget.client.attributes()),child:ListView.builder(padding:const EdgeInsets.all(16),itemCount:items.length,itemBuilder:(context,index){final a=Map<String,dynamic>.from(items[index] as Map);return Card(child:ListTile(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AttributeTermsPage(client:widget.client,attribute:a))),onLongPress:_busy?null:()=>_attribute(a),leading:const CircleAvatar(child:Icon(Icons.tune_rounded)),title:Text('${a['name']}'),subtitle:Text('${a['terms_count']} مقدار  •  ${a['taxonomy']}'),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')_attribute(a);if(v=='terms')Navigator.push(context,MaterialPageRoute(builder:(_)=>AttributeTermsPage(client:widget.client,attribute:a)));},itemBuilder:(_)=>const [PopupMenuItem(value:'terms',child:Text('مدیریت مقادیر')),PopupMenuItem(value:'edit',child:Text('ویرایش ویژگی'))])));}));});

  Widget _brandList()=>FutureBuilder<Map<String,dynamic>>(future:_brands,builder:(context,snapshot){if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(snapshot.hasError)return _retry();final data=snapshot.data??const {};if(data['supported']!=true)return const Center(child:Padding(padding:EdgeInsets.all(32),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.info_outline_rounded,size:42),SizedBox(height:12),Text('برند محصولات در این فروشگاه فعال نیست.',textAlign:TextAlign.center),SizedBox(height:6),Text('پس از فعال‌سازی قابلیت رسمی برند ووکامرس، برندهای واقعی اینجا نمایش داده می‌شوند.',textAlign:TextAlign.center)])));final items=data['items'] as List? ?? const [];if(items.isEmpty)return const Center(child:Text('هنوز برندی در ووکامرس ثبت نشده است.'));return RefreshIndicator(onRefresh:()async=>setState(()=>_brands=widget.client.brands()),child:ListView.builder(padding:const EdgeInsets.all(16),itemCount:items.length,itemBuilder:(context,index){final b=Map<String,dynamic>.from(items[index] as Map);return Card(child:ListTile(onTap:_busy?null:()=>_brand(b),leading:const CircleAvatar(child:Icon(Icons.sell_outlined)),title:Text('${b['name']}'),subtitle:Text('${b['count']} محصول${(b['description']??'').toString().isEmpty?'':'  •  ${b['description']}'}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.edit_outlined)));}));});
  Widget _retry()=>Center(child:FilledButton.icon(onPressed:()=>setState(_load),icon:const Icon(Icons.refresh_rounded),label:const Text('تلاش دوباره')));
}

class AttributeTermsPage extends StatefulWidget{
  const AttributeTermsPage({super.key,required this.client,required this.attribute});
  final ApiClient client;final Map<String,dynamic> attribute;
  @override State<AttributeTermsPage> createState()=>_AttributeTermsPageState();
}
class _AttributeTermsPageState extends State<AttributeTermsPage>{
  late Future<List<dynamic>> _future;bool _busy=false;
  @override void initState(){super.initState();_future=widget.client.attributeTerms((widget.attribute['id'] as num).toInt());}
  Future<void> _edit([Map<String,dynamic>? item])async{final name=TextEditingController(text:'${item?['name']??''}'),description=TextEditingController(text:'${item?['description']??''}');final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:Text(item==null?'مقدار جدید':'ویرایش مقدار'),content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,autofocus:true,decoration:const InputDecoration(labelText:'نام مقدار')),const SizedBox(height:12),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'توضیحات'))])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ذخیره'))]));if(ok==true&&name.text.trim().isNotEmpty){setState(()=>_busy=true);try{final id=(widget.attribute['id'] as num).toInt(),data={'name':name.text.trim(),'description':description.text.trim()};if(item==null){await widget.client.createAttributeTerm(id,data);}else{await widget.client.updateAttributeTerm(id,(item['id'] as num).toInt(),data);}if(mounted){setState(()=>_future=widget.client.attributeTerms(id));ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('مقدار ویژگی ذخیره شد.')));}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره انجام نشد: $e')));}finally{if(mounted)setState(()=>_busy=false);}}name.dispose();description.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('مقادیر ${widget.attribute['name']}')),floatingActionButton:FloatingActionButton.extended(onPressed:_busy?null:()=>_edit(),icon:const Icon(Icons.add_rounded),label:const Text('مقدار جدید')),body:Stack(children:[FutureBuilder<List<dynamic>>(future:_future,builder:(context,snapshot){if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(snapshot.hasError)return Center(child:Text('${snapshot.error}'));final items=snapshot.data??const [];if(items.isEmpty)return const Center(child:Text('هنوز مقداری ثبت نشده است.'));return ListView.builder(padding:const EdgeInsets.all(16),itemCount:items.length,itemBuilder:(context,index){final t=Map<String,dynamic>.from(items[index] as Map);return Card(child:ListTile(onTap:_busy?null:()=>_edit(t),title:Text('${t['name']}'),subtitle:Text('${t['count']} محصول${(t['description']??'').toString().isEmpty?'':'  •  ${t['description']}'}'),trailing:const Icon(Icons.edit_outlined)));});}),if(_busy)const LinearProgressIndicator()]));
}
