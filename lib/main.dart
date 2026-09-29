import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/connection/bootstrap_page.dart';

void main() => runApp(const WooManagerApp());

class WooManagerApp extends StatelessWidget {
  const WooManagerApp({super.key});
  @override
  Widget build(BuildContext context)=>ValueListenableBuilder<ThemeMode>(
    valueListenable:ThemeController.mode,
    builder:(context,mode,_)=>MaterialApp(
      debugShowCheckedModeBanner:false,
      title:'مدیر فروشگاه',
      theme:AppTheme.light,
      darkTheme:AppTheme.dark,
      themeMode:mode,
      locale:const Locale('fa'),
      builder:(context,child)=>Directionality(textDirection:TextDirection.rtl,child:child!),
      home:const BootstrapPage(),
    ),
  );
}
