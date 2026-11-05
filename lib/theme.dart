import 'package:flutter/material.dart';

/// Genius dizayn tizimi: "Tungi osmon".
///
/// Ranglar: chuqur to'q ko'k fon, qatlamli yuzalar, bitta yorqin asosiy rang (ko'k),
/// olov uchun amber, to'g'ri/xato uchun yalpiz va marjon. Har bir rang bitta ma'noga ega.
class C {
  /// Yorug' (kunduzgi) rejim yoqilganmi. Ilova [GeniusApp] da o'rnatadi.
  static bool light = false;
  static Color _p(int dark, int day) => Color(light ? day : dark);

  // Fon va yuzalar (pastdan yuqoriga: bg → sf → sf2 → sf3).
  static Color get bg => _p(0xFF090E1C, 0xFFF3F5FB);
  static Color get sf => _p(0xFF111831, 0xFFFFFFFF);
  static Color get sf2 => _p(0xFF19223F, 0xFFEDF0F7);
  static Color get sf3 => _p(0xFF232E52, 0xFFDFE4EF);
  static Color get ln => _p(0xFF212B49, 0xFFE2E7F1);

  // Matn.
  static Color get fg => _p(0xFFF3F6FF, 0xFF101631);
  static Color get mut => _p(0xFF8E99B9, 0xFF5D6886);
  static Color get dim => _p(0xFF5E6A8C, 0xFF9AA3BB);

  // Asosiy rang va urg'ular (kunduzi oq fonda o'qilishi uchun biroz to'qroq).
  static Color get ac => _p(0xFF5B83FF, 0xFF3D68F5);
  static const acDeep = Color(0xFF3557E6);
  static const onAc = Colors.white;
  static Color get violet => _p(0xFF9D7BFF, 0xFF7656EC);
  static Color get teal => _p(0xFF34C7D9, 0xFF0B9DB2);
  static Color get gold => _p(0xFFFFB84D, 0xFFF0A21C);
  static const onGold = Color(0xFF2B1700);
  static Color get good => _p(0xFF2FD38A, 0xFF10A463);
  static Color get bad => _p(0xFFFF6672, 0xFFE5484D);
  static const tg = Color(0xFF2AA3DF);
  static List<Color> get heat => light
      ? const [Color(0xFFE6EAF3), Color(0xFFB9EBD2), Color(0xFF7DD8AA), Color(0xFF35BF80), Color(0xFF10A463)]
      : const [Color(0xFF19223F), Color(0xFF0F4A35), Color(0xFF13734C), Color(0xFF1FA567), Color(0xFF2FD38A)];

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
TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w800}) => TextStyle(
    fontFamily: fontFamily, fontFamilyFallback: fontFallback, fontSize: size, fontWeight: weight, color: color ?? C.fg, height: 1.18, letterSpacing: -.3);

ThemeData buildTheme() {
  final base = ThemeData(
      brightness: C.light ? Brightness.light : Brightness.dark, useMaterial3: true, fontFamily: fontFamily, fontFamilyFallback: fontFallback);
  final text = base.textTheme.apply(bodyColor: C.fg, displayColor: C.fg);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: (C.light ? ColorScheme.light : ColorScheme.dark)(
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
    dividerTheme: DividerThemeData(color: C.ln, thickness: 1, space: 1),
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
      labelStyle: TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFallback, fontWeight: FontWeight.w700, color: C.fg),
      secondaryLabelStyle: const TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFallback, fontWeight: FontWeight.w800, color: Colors.white),
      checkmarkColor: Colors.white,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: C.sf,
      showDragHandle: true,
      dragHandleColor: C.sf3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.sf,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.xl)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: C.ac, linearTrackColor: C.sf2),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.sf2,
      hintStyle: TextStyle(color: C.mut, fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide.none),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: BorderSide(color: C.ac, width: 2)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.sf3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
      contentTextStyle: TextStyle(fontFamily: fontFamily, fontFamilyFallback: fontFallback, color: C.fg, fontWeight: FontWeight.w700),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
