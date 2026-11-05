import 'package:flutter/material.dart';

/// Genius dizayn tizimi: "Tungi osmon".
///
/// Ranglar: chuqur to'q ko'k fon, qatlamli yuzalar, bitta yorqin asosiy rang (ko'k),
/// olov uchun amber, to'g'ri/xato uchun yalpiz va marjon. Har bir rang bitta ma'noga ega.
class C {
  // Fon va yuzalar (pastdan yuqoriga: bg → sf → sf2 → sf3).
  static const bg = Color(0xFF090E1C);
  static const sf = Color(0xFF111831);
  static const sf2 = Color(0xFF19223F);
  static const sf3 = Color(0xFF232E52);
  static const ln = Color(0xFF212B49);

  // Matn.
  static const fg = Color(0xFFF3F6FF);
  static const mut = Color(0xFF8E99B9);
  static const dim = Color(0xFF5E6A8C);

  // Asosiy rang va urg'ular.
  static const ac = Color(0xFF5B83FF);
  static const acDeep = Color(0xFF3557E6);
  static const onAc = Colors.white;
  static const violet = Color(0xFF9D7BFF);
  static const teal = Color(0xFF34C7D9);
  static const gold = Color(0xFFFFB84D);
  static const onGold = Color(0xFF2B1700);
  static const good = Color(0xFF2FD38A);
  static const bad = Color(0xFFFF6672);
  static const tg = Color(0xFF2AA3DF);
  static const heat = [Color(0xFF19223F), Color(0xFF0F4A35), Color(0xFF13734C), Color(0xFF1FA567), Color(0xFF2FD38A)];

  /// Asosiy gradient: ko'kdan indigoga.
  static const grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B83FF), Color(0xFF3F52E3), Color(0xFF2B2A9E)],
    stops: [0, .55, 1],
  );

  /// Mashq kartasi uchun yumshoqroq gradient.
  static const cardGrad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2C3D86), Color(0xFF1B2556)],
  );

  static const premiumGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD27A), Color(0xFFFFA53D), Color(0xFFE5732A)],
  );

  /// Ikonka idishlari uchun yumshoq fon (rangning 16%i).
  static Color tint(Color c, [double a = .16]) => Color.alphaBlend(c.withValues(alpha: a), sf);
}

/// O'lchamlar: 4 ga karrali bo'shliqlar va burchaklar.
class R {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

const fontFamily = 'Jakarta';

/// Jakarta'da yo'q harflar (talaffuz belgilari) shu shriftlardan olinadi.
const fontFallback = ['Ipa', 'Roboto'];

/// Sarlavha shrifti (Plus Jakarta Sans, qalin).
TextStyle display(double size, {Color color = C.fg, FontWeight weight = FontWeight.w800}) => TextStyle(
    fontFamily: fontFamily, fontFamilyFallback: fontFallback, fontSize: size, fontWeight: weight, color: color, height: 1.18, letterSpacing: -.3);

ThemeData buildTheme() {
  final base = ThemeData(
      brightness: Brightness.dark, useMaterial3: true, fontFamily: fontFamily, fontFamilyFallback: fontFallback);
  final text = base.textTheme.apply(bodyColor: C.fg, displayColor: C.fg);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.ac,
      onPrimary: C.onAc,
      secondary: C.violet,
      surface: C.sf,
      onSurface: C.fg,
      surfaceContainerHighest: C.sf2,
      outline: C.ln,
      error: C.bad,
    ),
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
      bodyLarge: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    ),
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: const DividerThemeData(color: C.ln, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : C.mut),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.ac : C.sf3),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: C.sf2,
      selectedColor: C.ac,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFallback, fontWeight: FontWeight.w700, color: C.fg),
      secondaryLabelStyle: const TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFallback, fontWeight: FontWeight.w800, color: Colors.white),
      checkmarkColor: Colors.white,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.sf,
      showDragHandle: true,
      dragHandleColor: C.sf3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.sf,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.xl)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.ac, linearTrackColor: C.sf2),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.sf2,
      hintStyle: const TextStyle(color: C.mut, fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide.none),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: const BorderSide(color: C.ac, width: 2)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.sf3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
      contentTextStyle: const TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFallback, color: C.fg, fontWeight: FontWeight.w700),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
