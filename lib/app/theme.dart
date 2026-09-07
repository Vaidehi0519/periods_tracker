import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    const seed = Color(0xFFE07A9A);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        surface: const Color(0xFFFFFBFD),
        secondary: const Color(0xFF6FC2B5),
        tertiary: const Color(0xFFF3B562),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF7FB),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        headlineSmall: GoogleFonts.dmSerifDisplay(fontSize: 31, fontWeight: FontWeight.w400),
        headlineMedium: GoogleFonts.dmSerifDisplay(fontWeight: FontWeight.w400),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Colors.transparent),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 12);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const seed = Color(0xFFE5A0B6);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        surface: const Color(0xFF26222C),
        secondary: const Color(0xFF7ECBC0),
        tertiary: const Color(0xFFF3B562),
      ),
      scaffoldBackgroundColor: const Color(0xFF151318),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineSmall: GoogleFonts.dmSerifDisplay(
          textStyle: ThemeData.dark().textTheme.headlineSmall,
          fontSize: 31,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          textStyle: ThemeData.dark().textTheme.headlineMedium,
          fontWeight: FontWeight.w400,
        ),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Colors.transparent),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: const Color(0xFF26222C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
        selectedColor: scheme.primary.withValues(alpha: 0.26),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF211C27).withValues(alpha: 0.94),
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 12);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1A24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
