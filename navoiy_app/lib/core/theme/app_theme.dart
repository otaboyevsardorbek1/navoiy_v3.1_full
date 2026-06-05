// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

// ─── Color Palettes ──────────────────────────────────────────────────────────

class ClassicColors {
  static const background = Color(0xFFFDF6E3);
  static const surface = Color(0xFFF5E6C8);
  static const primary = Color(0xFF8B5E3C);
  static const primaryDark = Color(0xFF5C3D1E);
  static const accent = Color(0xFFD4A843);
  static const accentLight = Color(0xFFEDD07A);
  static const text = Color(0xFF2C1A0E);
  static const textSecondary = Color(0xFF7A5C3C);
  static const textHint = Color(0xFFB89B78);
  static const divider = Color(0xFFD4B896);
  static const error = Color(0xFFC0392B);
  static const success = Color(0xFF27AE60);
  static const cardShadow = Color(0x33000000);
}

class ModernColors {
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1A56DB);
  static const primaryDark = Color(0xFF0F3AB0);
  static const accent = Color(0xFF00C9A7);
  static const accentLight = Color(0xFFB2F0E8);
  static const text = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5E7EB);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const cardShadow = Color(0x1A000000);
}

class DarkColors {
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surfaceVariant = Color(0xFF21262D);
  static const primary = Color(0xFFD4A843);
  static const primaryDark = Color(0xFFB8860B);
  static const accent = Color(0xFF58A6FF);
  static const accentLight = Color(0xFF1F4E8C);
  static const text = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textHint = Color(0xFF484F58);
  static const divider = Color(0xFF30363D);
  static const error = Color(0xFFF85149);
  static const success = Color(0xFF3FB950);
  static const cardShadow = Color(0x33000000);
}

// ─── Theme Data ───────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData classic() {
    final base = ThemeData.light();
    return base.copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        background: ClassicColors.background,
        surface: ClassicColors.surface,
        primary: ClassicColors.primary,
        secondary: ClassicColors.accent,
        error: ClassicColors.error,
        onBackground: ClassicColors.text,
        onSurface: ClassicColors.text,
        onPrimary: Colors.white,
        onSecondary: ClassicColors.text,
      ),
      scaffoldBackgroundColor: ClassicColors.background,
      textTheme: _classicTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: ClassicColors.primaryDark,
        foregroundColor: ClassicColors.accentLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.amiri(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: ClassicColors.accentLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: ClassicColors.surface,
        elevation: 3,
        shadowColor: ClassicColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: ClassicColors.divider, width: 1),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fillColor: Colors.white,
        borderColor: ClassicColors.divider,
        focusColor: ClassicColors.primary,
        labelColor: ClassicColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ClassicColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.amiri(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      dividerTheme: DividerThemeData(color: ClassicColors.divider, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ClassicColors.surface,
        selectedItemColor: ClassicColors.primary,
        unselectedItemColor: ClassicColors.textHint,
        selectedLabelStyle: GoogleFonts.amiri(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.amiri(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      extensions: const [AppThemeExtension(themeName: AppConstants.themeClassic)],
    );
  }

  static ThemeData modern() {
    final base = ThemeData.light();
    return base.copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        background: ModernColors.background,
        surface: ModernColors.surface,
        primary: ModernColors.primary,
        secondary: ModernColors.accent,
        error: ModernColors.error,
        onBackground: ModernColors.text,
        onSurface: ModernColors.text,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: ModernColors.background,
      textTheme: _modernTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: ModernColors.surface,
        foregroundColor: ModernColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ModernColors.text,
        ),
        shadowColor: ModernColors.cardShadow,
      ),
      cardTheme: CardThemeData(
        color: ModernColors.surface,
        elevation: 2,
        shadowColor: ModernColors.cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: _inputTheme(
        fillColor: ModernColors.surface,
        borderColor: ModernColors.divider,
        focusColor: ModernColors.primary,
        labelColor: ModernColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ModernColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: ModernColors.divider, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ModernColors.surface,
        selectedItemColor: ModernColors.primary,
        unselectedItemColor: ModernColors.textHint,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      extensions: const [AppThemeExtension(themeName: AppConstants.themeModern)],
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        background: DarkColors.background,
        surface: DarkColors.surface,
        primary: DarkColors.primary,
        secondary: DarkColors.accent,
        error: DarkColors.error,
        onBackground: DarkColors.text,
        onSurface: DarkColors.text,
        onPrimary: DarkColors.background,
        onSecondary: DarkColors.background,
      ),
      scaffoldBackgroundColor: DarkColors.background,
      textTheme: _darkTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: DarkColors.surface,
        foregroundColor: DarkColors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.firaCode(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: DarkColors.primary,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: DarkColors.text),
      ),
      cardTheme: CardThemeData(
        color: DarkColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: DarkColors.divider, width: 1),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fillColor: DarkColors.surfaceVariant,
        borderColor: DarkColors.divider,
        focusColor: DarkColors.primary,
        labelColor: DarkColors.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkColors.primary,
          foregroundColor: DarkColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      dividerTheme: DividerThemeData(color: DarkColors.divider, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DarkColors.surface,
        selectedItemColor: DarkColors.primary,
        unselectedItemColor: DarkColors.textHint,
        selectedLabelStyle: GoogleFonts.firaCode(fontSize: 11),
        unselectedLabelStyle: GoogleFonts.firaCode(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: const [AppThemeExtension(themeName: AppConstants.themeDark)],
    );
  }

  // ─── Text Themes ───────────────────────────────────────────────────────────

  static TextTheme _classicTextTheme() => TextTheme(
    displayLarge: GoogleFonts.amiri(fontSize: 32, fontWeight: FontWeight.bold, color: ClassicColors.text),
    displayMedium: GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.bold, color: ClassicColors.text),
    headlineLarge: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: ClassicColors.text),
    headlineMedium: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold, color: ClassicColors.text),
    titleLarge: GoogleFonts.amiri(fontSize: 16, fontWeight: FontWeight.bold, color: ClassicColors.text),
    titleMedium: GoogleFonts.amiri(fontSize: 15, fontWeight: FontWeight.w600, color: ClassicColors.text),
    bodyLarge: GoogleFonts.amiri(fontSize: 16, color: ClassicColors.text, height: 1.7),
    bodyMedium: GoogleFonts.amiri(fontSize: 14, color: ClassicColors.text, height: 1.6),
    bodySmall: GoogleFonts.amiri(fontSize: 12, color: ClassicColors.textSecondary),
    labelLarge: GoogleFonts.amiri(fontSize: 14, fontWeight: FontWeight.bold, color: ClassicColors.primary),
  );

  static TextTheme _modernTextTheme() => TextTheme(
    displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: ModernColors.text),
    displayMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: ModernColors.text),
    headlineLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: ModernColors.text),
    headlineMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: ModernColors.text),
    titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: ModernColors.text),
    titleMedium: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: ModernColors.text),
    bodyLarge: GoogleFonts.lato(fontSize: 16, color: ModernColors.text, height: 1.6),
    bodyMedium: GoogleFonts.lato(fontSize: 14, color: ModernColors.text, height: 1.5),
    bodySmall: GoogleFonts.lato(fontSize: 12, color: ModernColors.textSecondary),
    labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: ModernColors.primary),
  );

  static TextTheme _darkTextTheme() => TextTheme(
    displayLarge: GoogleFonts.firaCode(fontSize: 32, fontWeight: FontWeight.bold, color: DarkColors.text),
    displayMedium: GoogleFonts.firaCode(fontSize: 26, fontWeight: FontWeight.bold, color: DarkColors.text),
    headlineLarge: GoogleFonts.firaCode(fontSize: 22, fontWeight: FontWeight.bold, color: DarkColors.text),
    headlineMedium: GoogleFonts.firaCode(fontSize: 18, fontWeight: FontWeight.bold, color: DarkColors.text),
    titleLarge: GoogleFonts.firaCode(fontSize: 16, fontWeight: FontWeight.bold, color: DarkColors.text),
    titleMedium: GoogleFonts.firaCode(fontSize: 15, color: DarkColors.text),
    bodyLarge: GoogleFonts.sourceCodePro(fontSize: 15, color: DarkColors.text, height: 1.7),
    bodyMedium: GoogleFonts.sourceCodePro(fontSize: 13, color: DarkColors.text, height: 1.6),
    bodySmall: GoogleFonts.sourceCodePro(fontSize: 11, color: DarkColors.textSecondary),
    labelLarge: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: DarkColors.primary),
  );

  static InputDecorationTheme _inputTheme({
    required Color fillColor,
    required Color borderColor,
    required Color focusColor,
    required Color labelColor,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: focusColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        labelStyle: TextStyle(color: labelColor),
        hintStyle: TextStyle(color: labelColor.withOpacity(0.6)),
      );

  static ThemeData fromString(String name) {
    switch (name) {
      case AppConstants.themeModern:
        return modern();
      case AppConstants.themeDark:
        return dark();
      default:
        return classic();
    }
  }
}

// ─── Theme Extension ──────────────────────────────────────────────────────────

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final String themeName;
  const AppThemeExtension({required this.themeName});

  @override
  AppThemeExtension copyWith({String? themeName}) =>
      AppThemeExtension(themeName: themeName ?? this.themeName);

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) => this;
}
