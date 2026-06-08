import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Hamsa Color Palette ──────────────────────────────────────
abstract class HamsaColors {
  // Backgrounds — derived from brand green #124734
  static const bgDeep    = Color(0xFF0A2A1D);
  static const bgSurface = Color(0xFF0E3325);
  static const bgElevated= Color(0xFF124734);
  static const bgCard    = Color(0xFF103B2A);

  // Greens
  static const greenBrand  = Color(0xFF124734);
  static const greenLight  = Color(0xFF1E6B4A);
  static const greenAccent = Color(0xFF52B788);
  static const greenGlow   = Color(0xFF40916C);

  // Creams & Golds
  static const cream = Color(0xFFF5EDD6);
  static const creamMuted = Color(0xFFC8B99A);
  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8C56A);

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFE8F5EE);
  static const muted = Color(0x8DFFFFFF);
  static const subtle = Color(0x40FFFFFF);

  // Borders
  static const border = Color(0x1AFFFFFF);
  static const borderStrong = Color(0x38FFFFFF);

  // Input
  static const inputBg = Color(0x12FFFFFF);

  // Status
  static const statusReceived = Color(0xFF74C0FC);
  static const statusInProgress = Color(0xFFFFB347);
  static const statusReady = Color(0xFF52B788);
  static const statusPickedUp = Color(0x66FFFFFF);

  // Semantic
  static const error = Color(0xFFFF6B6B);
  static const success = Color(0xFF52B788);
  static const warning = Color(0xFFFFB347);
}

// ─── Hamsa Typography ─────────────────────────────────────────
abstract class HamsaText {
  /// Hero/display titles — Peignot LT Std Demi
  static TextStyle display({
    double size = 52,
    FontWeight weight = FontWeight.w600,
    Color color = HamsaColors.cream,
    FontStyle style = FontStyle.normal,
    double? height,
    double letterSpacing = -0.5,
  }) =>
      TextStyle(
        fontFamily: 'Peignot',
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontStyle: style,
        height: height ?? 1.1,
        letterSpacing: letterSpacing,
      );

  /// Section headers, screen titles — Peignot LT Std Demi
  static TextStyle heading({
    double size = 28,
    FontWeight weight = FontWeight.w600,
    Color color = HamsaColors.cream,
    double? height,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: 'Peignot',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.2,
        letterSpacing: letterSpacing,
      );

  /// Body text, labels — Peignot LT Std Demi
  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color color = HamsaColors.offWhite,
    double? height,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: 'Peignot',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.5,
        letterSpacing: letterSpacing,
      );

  /// Caption / small labels — Peignot
  static TextStyle caption({
    double size = 11,
    FontWeight weight = FontWeight.w600,
    Color color = HamsaColors.muted,
    double letterSpacing = 1.2,
  }) =>
      TextStyle(
        fontFamily: 'Peignot',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Arabic text — Noor
  static TextStyle arabic({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = HamsaColors.cream,
    double? height,
  }) =>
      TextStyle(
        fontFamily: 'Noor',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.6,
      );

  /// Price tag — gold, Peignot
  static TextStyle price({
    double size = 20,
    Color color = HamsaColors.gold,
  }) =>
      TextStyle(
        fontFamily: 'Peignot',
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0,
      );
}

// ─── Hamsa Theme ──────────────────────────────────────────────
ThemeData buildHamsaTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: HamsaColors.bgDeep,
    colorScheme: const ColorScheme.dark(
      primary: HamsaColors.greenAccent,
      secondary: HamsaColors.gold,
      surface: HamsaColors.bgSurface,
      error: HamsaColors.error,
      onPrimary: HamsaColors.bgDeep,
      onSecondary: HamsaColors.bgDeep,
      onSurface: HamsaColors.offWhite,
    ),
    textTheme: TextTheme(
      displayLarge: HamsaText.display(size: 52),
      displayMedium: HamsaText.display(size: 40),
      displaySmall: HamsaText.display(size: 32),
      headlineLarge: HamsaText.heading(size: 28),
      headlineMedium: HamsaText.heading(size: 24),
      headlineSmall: HamsaText.heading(size: 20),
      bodyLarge: HamsaText.body(size: 16),
      bodyMedium: HamsaText.body(size: 14),
      bodySmall: HamsaText.body(size: 12),
      labelLarge: HamsaText.body(size: 14, weight: FontWeight.w600),
      labelSmall: HamsaText.caption(),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: HamsaText.heading(size: 18),
      iconTheme: const IconThemeData(color: HamsaColors.cream),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HamsaColors.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: HamsaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: HamsaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: HamsaColors.greenAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: HamsaColors.error),
      ),
      hintStyle: HamsaText.body(color: HamsaColors.muted),
      labelStyle: HamsaText.body(color: HamsaColors.muted, size: 13),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HamsaColors.greenAccent,
        foregroundColor: HamsaColors.bgDeep,
        minimumSize: const Size(double.infinity, 54),
        shape: const StadiumBorder(),
        textStyle: HamsaText.body(size: 15, weight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: HamsaColors.bgElevated,
      selectedColor: HamsaColors.greenAccent,
      labelStyle: HamsaText.body(size: 13),
      side: const BorderSide(color: HamsaColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: const StadiumBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: HamsaColors.border,
      thickness: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
