import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.storeName});
  final String storeName;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(storeName),actions:[IconButton(onPressed:(){},icon:const Icon(Icons.notifications_none_rounded))]),
    body: ListView(padding:const EdgeInsets.all(16),children:[
      Text('مرکز عملیات',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:12),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.45,children:const [
        _Stat(title:'سفارش امروز',value:'—',icon:Icons.receipt_long_rounded),_Stat(title:'فروش امروز',value:'—',icon:Icons.trending_up_rounded),_Stat(title:'آماده ارسال',value:'—',icon:Icons.local_shipping_outlined),_Stat(title:'کم‌موجود',value:'—',icon:Icons.inventory_2_outlined),
      ]),const SizedBox(height:22),
      Text('دسترسی سریع',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w700)),const SizedBox(height:10),
      Card(child:Column(children:[_Action(icon:Icons.add_box_outlined,title:'ثبت مرسوله در تاپین'),_Action(icon:Icons.print_outlined,title:'چاپ لیبل و فاکتور پستی'),_Action(icon:Icons.sms_outlined,title:'ارسال پیامک به مشتری')]))
    ]),
    bottomNavigationBar:NavigationBar(selectedIndex:0,destinations:const [NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard_rounded),label:'خانه'),NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'سفارش‌ها'),NavigationDestination(icon:Icon(Icons.inventory_2_outlined),label:'محصولات'),NavigationDestination(icon:Icon(Icons.more_horiz_rounded),label:'بیشتر')]),
  );
}
class _Stat extends StatelessWidget { const _Stat({required this.title,required this.value,required this.icon});final String title,value;final IconData icon;@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(icon),Text(value,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),Text(title)])));}
class _Action extends StatelessWidget { const _Action({required this.icon,required this.title});final IconData icon;final String title;@override Widget build(BuildContext context)=>ListTile(leading:Icon(icon),title:Text(title),trailing:const Icon(Icons.chevron_left_rounded));}
