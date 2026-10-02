import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const seed = Color(0xFF087F5B);
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: dark ? const Color(0xFF101113) : const Color(0xFFFCFDFC),
    );
    final baseText = GoogleFonts.vazirmatnTextTheme(ThemeData(brightness: brightness).textTheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: dark ? const Color(0xFF090A0B) : const Color(0xFFF5F7F6),
      textTheme: baseText.copyWith(
        headlineSmall: baseText.headlineSmall?.copyWith(letterSpacing: -.4),
        titleLarge: baseText.titleLarge?.copyWith(letterSpacing: -.2),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.vazirmatn(fontSize: 20, fontWeight: FontWeight.w900, color: dark ? Colors.white : const Color(0xFF111413)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF17191A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        prefixIconColor: colors.primary,
        labelStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: dark ? const Color(0xFF232627) : const Color(0xFFE9ECEA))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: colors.primary, width: 1.4)),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF121415) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: dark ? const Color(0xFF242728) : const Color(0xFFE8ECEA))),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? const Color(0xFF101213) : const Color(0xFFF8FAF9),
        modalBackgroundColor: dark ? const Color(0xFF101213) : const Color(0xFFF8FAF9),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: dark ? const Color(0xFF101213) : Colors.white,
        indicatorColor: colors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: states.contains(WidgetState.selected) ? colors.primary : colors.onSurfaceVariant)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => GoogleFonts.vazirmatn(fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          side: BorderSide(color: colors.outlineVariant),
          textStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
        labelStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(dark ? const Color(0xFF17191A) : Colors.white),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: dark ? const Color(0xFF242728) : const Color(0xFFE8ECEA)))),
      ),
      dividerTheme: DividerThemeData(color: dark ? const Color(0xFF272A2B) : const Color(0xFFE7EBE9), space: 1),
    );
  }
}
