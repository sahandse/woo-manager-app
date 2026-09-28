import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/network/api_client.dart';

class MaintenancePage extends StatefulWidget{
  const MaintenancePage({super.key,required this.client});
  final ApiClient client;
  @override State<MaintenancePage> createState()=>_MaintenancePageState();
}
class _MaintenancePageState extends State<MaintenancePage>{
  late Future<Map<String,dynamic>> future;bool busy=false;
  @override void initState(){super.initState();load();}
  void load()=>setState(()=>future=widget.client.maintenance());
  Future<void> share(Future<Map<String,dynamic>> Function() action)async{setState(()=>busy=true);try{final file=await action(),bytes=base64Decode(file['content_base64'] as String);await Share.shareXFiles([XFile.fromData(bytes,mimeType:file['mime_type'] as String,name:file['filename'] as String)]);}finally{if(mounted)setState(()=>busy=false);}}
  Future<void> restore()async{final result=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:['json'],withData:true);if(result==null||result.files.single.bytes==null)return;final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('بازیابی تنظیمات'),content:const Text('تنظیمات فعلی سرویس‌ها با فایل پشتیبان جایگزین شود؟'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('تأیید بازیابی'))]));if(ok==true){setState(()=>busy=true);try{final response=await widget.client.restoreBackup(base64Encode(result.files.single.bytes!));if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${response['message']}')));}finally{if(mounted)setState(()=>busy=false);}}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('نگهداری و خروجی')),body:FutureBuilder<Map<String,dynamic>>(future:future,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text(s.error.toString()));final checks=s.data!['checks'] as List? ?? const [];return ListView(padding:const EdgeInsets.all(16),children:[
    if(busy)const LinearProgressIndicator(),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('سلامت فروشگاه',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:10),...checks.map((raw){final c=Map<String,dynamic>.from(raw as Map);return ListTile(contentPadding:EdgeInsets.zero,leading:Icon(c['ok']==true?Icons.check_circle_rounded:Icons.warning_amber_rounded,color:c['ok']==true?Colors.green:Colors.orange),title:Text('${c['label']}'));})]))),
    const SizedBox(height:12),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Wrap(spacing:8,runSpacing:8,children:[FilledButton.icon(onPressed:busy?null:()=>share(()=>widget.client.exportSales(30,'pdf')),icon:const Icon(Icons.picture_as_pdf_outlined),label:const Text('گزارش PDF')),OutlinedButton.icon(onPressed:busy?null:()=>share(()=>widget.client.exportSales(30,'csv')),icon:const Icon(Icons.table_view_outlined),label:const Text('گزارش CSV')),OutlinedButton.icon(onPressed:busy?null:()=>share(widget.client.backup),icon:const Icon(Icons.backup_outlined),label:const Text('پشتیبان تنظیمات')),OutlinedButton.icon(onPressed:busy?null:restore,icon:const Icon(Icons.restore_rounded),label:const Text('بازیابی'))])))
  ]);}));
}
