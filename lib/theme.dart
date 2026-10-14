import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// To'q ko'k mavzu ranglari (prototipdagi bilan bir xil).
class C {
  static const bg = Color(0xFF08101F);
  static const fg = Color(0xFFEEF3FF);
  static const mut = Color(0xFF8B97B3);
  static const sf = Color(0xFF101B31);
  static const sf2 = Color(0xFF18263F);
  static const ln = Color(0xFF22324F);
  static const ac = Color(0xFF4C8DFF);
  static const onAc = Color(0xFF03112B);
  static const gold = Color(0xFFFFD166);
  static const good = Color(0xFF3FCA6B);
  static const bad = Color(0xFFFF5D5D);
  static const tg = Color(0xFF2AA3DF);
  static const heat = [Color(0xFF17233A), Color(0xFF0E4429), Color(0xFF006D32), Color(0xFF26A641), Color(0xFF39D353)];

  static const grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F6BFF), Color(0xFF1A3F9E), Color(0xFF0B1F4D)],
    stops: [0, .55, 1],
  );
  static const premiumGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6C453), Color(0xFFE38A2E), Color(0xFFC0561E)],
  );
}

TextStyle display(double size, {Color color = C.fg, FontWeight weight = FontWeight.w600}) =>
    GoogleFonts.unbounded(fontSize: size, fontWeight: weight, color: color, height: 1.15);

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final text = base.textTheme.apply(fontFamily: GoogleFonts.manrope().fontFamily, bodyColor: C.fg, displayColor: C.fg);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.ac,
      onPrimary: C.onAc,
      surface: C.sf,
      onSurface: C.fg,
      error: C.bad,
    ),
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.sf2,
      hintStyle: const TextStyle(color: C.mut),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.ln, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.ln, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: C.ac, width: 2)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.fg,
      contentTextStyle: TextStyle(color: C.bg, fontWeight: FontWeight.w800),
    ),
  );
}
