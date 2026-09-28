import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const seed = Color(0xFF111827);
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: brightness == Brightness.light ? const Color(0xFFF7F7F8) : const Color(0xFF09090B),
      textTheme: GoogleFonts.vazirmatnTextTheme(ThemeData(brightness: brightness).textTheme),
      inputDecorationTheme: InputDecorationTheme(filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
      cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    );
  }
}
