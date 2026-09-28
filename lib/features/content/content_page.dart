import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';

class ContentPage extends StatelessWidget{const ContentPage({super.key,required this.client});final ApiClient client;@override Widget build(BuildContext context)=>DefaultTabController(length:3,child:Scaffold(appBar:AppBar(title:const Text('رسانه و محتوا'),bottom:const TabBar(tabs:[Tab(text:'رسانه‌ها'),Tab(text:'نوشته‌ها'),Tab(text:'برگه‌ها')])),body:TabBarView(children:[_Media(client),_ContentList(client:client,type:'post'),_ContentList(client:client,type:'page')])));}
class _Media extends StatefulWidget{const _Media(this.client);final ApiClient client;@override State<_Media> createState()=>_MediaState();}
class _MediaState extends State<_Media>{
  late Future<Map<String,dynamic>> future; bool uploading=false;
  @override void initState(){super.initState();load();}
  void load()=>setState(()=>future=widget.client.media());
  Future<void> upload()async{
    final image=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:92); if(image==null)return;
    setState(()=>uploading=true);
    try{final bytes=await image.readAsBytes();await widget.client.uploadMedia({'filename':image.name,'mime_type':image.mimeType??_mime(image.name),'content_base64':base64Encode(bytes)});load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('بارگذاری انجام نشد: '+e.toString())));}
    finally{if(mounted)setState(()=>uploading=false);}
  }
  String _mime(String name){final lower=name.toLowerCase();if(lower.endsWith('.png'))return'image/png';if(lower.endsWith('.webp'))return'image/webp';return'image/jpeg';}
  @override Widget build(BuildContext context){
    return Scaffold(
      floatingActionButton:FloatingActionButton.extended(onPressed:uploading?null:upload,icon:const Icon(Icons.add_photo_alternate_outlined),label:const Text('آپلود تصویر')),
      body:FutureBuilder<Map<String,dynamic>>(
        future:future,
        builder:(context,snapshot){
          if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
          if(snapshot.hasError)return Center(child:Text(snapshot.error.toString()));
          final items=snapshot.data!['items'] as List? ?? const [];
          if(items.isEmpty)return const Center(child:Text('تصویری در کتابخانه وردپرس وجود ندارد.'));
          return GridView.builder(
            padding:const EdgeInsets.all(16),
            gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.86),
            itemCount:items.length,
            itemBuilder:(context,index){
              final media=Map<String,dynamic>.from(items[index] as Map);
              return Card(child:ClipRRect(borderRadius:BorderRadius.circular(21),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                Expanded(child:Image.network((media['thumbnail']??media['url']).toString(),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image_outlined))),
                Padding(padding:const EdgeInsets.all(10),child:Text(media['title'].toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700))),
              ])));
            },
          );
        },
      ),
    );
  }
}
class _ContentList extends StatefulWidget{const _ContentList({required this.client,required this.type});final ApiClient client;final String type;@override State<_ContentList> createState()=>_ContentListState();}
class _ContentListState extends State<_ContentList>{
  late Future<List<dynamic>> future;
  @override void initState(){super.initState();load();}
  void load()=>setState(()=>future=widget.client.content(widget.type));
  Future<void> edit(Map<String,dynamic> item)async{
    final title=TextEditingController(text:(item['title']??'').toString());
    final excerpt=TextEditingController(text:(item['excerpt']??'').toString());
    var status=(item['status']??'draft').toString();
    final ok=await showModalBottomSheet<bool>(
      context:context,isScrollControlled:true,
      builder:(context)=>StatefulBuilder(builder:(context,setModal)=>Padding(
        padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(context).bottom+20),
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text('ویرایش محتوا',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:14),TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان')),
          const SizedBox(height:10),TextField(controller:excerpt,minLines:3,maxLines:5,decoration:const InputDecoration(labelText:'خلاصه')),
          const SizedBox(height:10),DropdownButtonFormField<String>(value:status,items:const [
            DropdownMenuItem(value:'publish',child:Text('منتشرشده')),DropdownMenuItem(value:'draft',child:Text('پیش‌نویس')),DropdownMenuItem(value:'pending',child:Text('در انتظار بررسی')),DropdownMenuItem(value:'private',child:Text('خصوصی')),
          ],onChanged:(value)=>setModal(()=>status=value!)),
          const SizedBox(height:14),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ذخیره در وردپرس')),
        ]),
      )),
    );
    if(ok==true){try{await widget.client.updateContent((item['id'] as num).toInt(),{'title':title.text.trim(),'excerpt':excerpt.text.trim(),'status':status});load();}catch(error){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ذخیره انجام نشد: '+error.toString())));}}
    title.dispose();excerpt.dispose();
  }
  @override Widget build(BuildContext context){
    return FutureBuilder<List<dynamic>>(
      future:future,
      builder:(context,snapshot){
        if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
        if(snapshot.hasError)return Center(child:Text(snapshot.error.toString()));
        final items=snapshot.data??const []; if(items.isEmpty)return const Center(child:Text('محتوایی وجود ندارد.'));
        return ListView.separated(padding:const EdgeInsets.all(16),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(context,index){
          final item=Map<String,dynamic>.from(items[index] as Map);
          return Card(child:ListTile(onTap:()=>edit(item),contentPadding:const EdgeInsets.all(14),leading:CircleAvatar(child:Icon(widget.type=='page'?Icons.description_outlined:Icons.article_outlined)),title:Text(item['title'].toString(),style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(item['status'].toString()+' • '+item['modified'].toString()),trailing:const Icon(Icons.edit_outlined)));
        });
      },
    );
  }
}
