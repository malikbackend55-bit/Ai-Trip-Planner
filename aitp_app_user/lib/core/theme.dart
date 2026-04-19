import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_localization.dart';

class AppColors {
  static const Color g900 = Color(0xff0a2e1a);
  static const Color g800 = Color(0xff14532d);
  static const Color g700 = Color(0xff166534);
  static const Color g600 = Color(0xff16a34a);
  static const Color g500 = Color(0xff22c55e);
  static const Color g400 = Color(0xff4ade80);
  static const Color g300 = Color(0xff86efac);
  static const Color g200 = Color(0xffbbf7d0);
  static const Color g100 = Color(0xffdcfce7);
  static const Color g50 = Color(0xfff0fdf4);

  static const Color sand = Color(0xfffefce8);
  static const Color earth = Color(0xff92400e);
  static const Color sky = Color(0xff0ea5e9);
  static const Color error = Color.fromARGB(255, 250, 71, 0);
  static const Color coral = Color(0xfff97316);
  static const Color black = Color(0xff0f1a0f);
  static const Color white = Colors.white;

  static const Color gray800 = Color(0xff1f2937);
  static const Color gray700 = Color(0xff374151);
  static const Color gray600 = Color(0xff4b5563);
  static const Color gray400 = Color(0xff9ca3af);
  static const Color gray200 = Color(0xffe5e7eb);
  static const Color gray100 = Color(0xfff3f4f6);
  static const Color gray50 = Color(0xfff9fafb);
}

class AppTheme {
  static ThemeData lightTheme(AppLanguage language) {
    final isSorani = language == AppLanguage.sorani;
    final baseTextTheme = isSorani
        ? GoogleFonts.notoSansArabicTextTheme()
        : GoogleFonts.nunitoTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.gray50,
      cardColor: AppColors.white,
      dividerColor: AppColors.gray100,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.g600,
        primary: AppColors.g600,
        secondary: AppColors.g700,
        surface: AppColors.white,
      ),
      fontFamily: isSorani
          ? GoogleFonts.notoSansArabic().fontFamily
          : GoogleFonts.nunito().fontFamily,
      textTheme: baseTextTheme.copyWith(
        displayLarge:
            (isSorani ? GoogleFonts.notoKufiArabic : GoogleFonts.fraunces)(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.g900,
            ),
        displayMedium:
            (isSorani ? GoogleFonts.notoKufiArabic : GoogleFonts.fraunces)(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.g900,
            ),
        titleLarge:
            (isSorani ? GoogleFonts.notoSansArabic : GoogleFonts.nunito)(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.gray800,
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.g600,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.g500),
        ),
      ),
    );
  }

  static ThemeData darkTheme(AppLanguage language) {
    final isSorani = language == AppLanguage.sorani;
    final baseTextTheme = isSorani
        ? GoogleFonts.notoSansArabicTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          )
        : GoogleFonts.nunitoTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.g400,
        primary: AppColors.g300,
        secondary: AppColors.sky,
        surface: const Color(0xff101717),
      ),
      scaffoldBackgroundColor: const Color(0xff07110c),
      cardColor: const Color(0xff101717),
      dividerColor: AppColors.white.withValues(alpha: 0.08),
      fontFamily: isSorani
          ? GoogleFonts.notoSansArabic().fontFamily
          : GoogleFonts.nunito().fontFamily,
      textTheme: baseTextTheme.copyWith(
        displayLarge:
            (isSorani ? GoogleFonts.notoKufiArabic : GoogleFonts.fraunces)(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
        displayMedium:
            (isSorani ? GoogleFonts.notoKufiArabic : GoogleFonts.fraunces)(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
        titleLarge:
            (isSorani ? GoogleFonts.notoSansArabic : GoogleFonts.nunito)(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.g500,
          foregroundColor: AppColors.black,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff121c18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.white.withValues(alpha: 0.10),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.white.withValues(alpha: 0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.g300),
        ),
      ),
    );
  }
}

extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appScaffoldColor => Theme.of(this).scaffoldBackgroundColor;

  Color get appSurfaceColor =>
      isDarkMode ? const Color(0xff101717) : AppColors.white;

  Color get appSurfaceAltColor =>
      isDarkMode ? const Color(0xff15211c) : AppColors.gray50;

  Color get appBorderColor =>
      isDarkMode ? AppColors.white.withValues(alpha: 0.08) : AppColors.gray100;

  Color get appBorderStrongColor =>
      isDarkMode ? AppColors.white.withValues(alpha: 0.12) : AppColors.gray200;

  Color get appTextColor => Theme.of(this).colorScheme.onSurface;

  Color get appSubtextColor => isDarkMode ? AppColors.g200 : AppColors.gray600;

  Color get appMutedTextColor =>
      isDarkMode ? AppColors.white.withValues(alpha: 0.66) : AppColors.gray400;

  Color get appNavBarColor =>
      isDarkMode ? const Color(0xff0d1511) : AppColors.white;

  Color get appShadowColor =>
      Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.05);
}
