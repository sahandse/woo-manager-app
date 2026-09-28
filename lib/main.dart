import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/connection/bootstrap_page.dart';

void main() => runApp(const WooManagerApp());

class WooManagerApp extends StatelessWidget {
  const WooManagerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'مدیر فروشگاه',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        locale: const Locale('fa'),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const BootstrapPage(),
      );
}
