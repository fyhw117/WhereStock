import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Palette
  static const Color primaryLight = Color(0xFF1F4E5B);
  static const Color secondaryLight = Color(0xFF439A86);
  static const Color accentLight = Color(0xFFE56B70);
  static const Color backgroundLight = Color(0xFFF6F8F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  // Dark Theme Palette
  static const Color primaryDark = Color(0xFF86C5D8);
  static const Color secondaryDark = Color(0xFF6BC8B3);
  static const Color accentDark = Color(0xFFFF8B90);
  static const Color backgroundDark = Color(0xFF0F171A);
  static const Color surfaceDark = Color(0xFF192529);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        error: accentLight,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A252C),
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryLight,
        ),
        iconTheme: IconThemeData(color: primaryLight),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        error: accentDark,
        surface: surfaceDark,
        onPrimary: Color(0xFF0F171A),
        onSecondary: Color(0xFF0F171A),
        onSurface: Color(0xFFECEFF1),
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800.withOpacity(0.5), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryDark,
        ),
        iconTheme: IconThemeData(color: primaryDark),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Color(0xFF0F171A),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF212E35),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceDark,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
