import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const seed = Color(0xFF111827);
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(seedColor: seed, brightness: brightness, surface: dark ? const Color(0xFF111113) : Colors.white);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: dark ? const Color(0xFF08080A) : const Color(0xFFF5F5F4),
      textTheme: GoogleFonts.vazirmatnTextTheme(ThemeData(brightness: brightness).textTheme),
      appBarTheme: AppBarTheme(centerTitle:false,elevation:0,scrolledUnderElevation:0,backgroundColor:Colors.transparent,titleTextStyle:GoogleFonts.vazirmatn(fontSize:20,fontWeight:FontWeight.w800,color:dark?Colors.white:const Color(0xFF111113))),
      inputDecorationTheme: InputDecorationTheme(filled:true,fillColor:dark?const Color(0xFF18181B):Colors.white,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:14),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none)),
      cardTheme: CardThemeData(color:dark?const Color(0xFF131316):Colors.white,elevation:0,margin:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22),side:BorderSide(color:dark?const Color(0xFF27272A):const Color(0xFFE7E5E4)))),
      navigationBarTheme:NavigationBarThemeData(height:70,elevation:0,backgroundColor:dark?const Color(0xFF101012):Colors.white,indicatorColor:dark?Colors.white:const Color(0xFF111113),iconTheme:WidgetStateProperty.resolveWith((states)=>IconThemeData(color:states.contains(WidgetState.selected)?(dark?Colors.black:Colors.white):colors.onSurfaceVariant)),labelTextStyle:WidgetStateProperty.all(GoogleFonts.vazirmatn(fontSize:11,fontWeight:FontWeight.w600))),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),padding:const EdgeInsets.symmetric(horizontal:18,vertical:13))),
      chipTheme:ChipThemeData(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),side:BorderSide.none),
      dividerTheme:DividerThemeData(color:dark?const Color(0xFF27272A):const Color(0xFFE7E5E4),space:1),
    );
  }
}
