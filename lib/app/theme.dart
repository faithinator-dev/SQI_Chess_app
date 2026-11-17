import 'package:flutter/material.dart';

class AppTypography {
  // Small labels: 14 (absolute minimum) - timestamps and compact badges
  static const double micro = 14.0;

  // Captions / Secondary: 14 - Subtitles, form hints, secondary descriptive text
  static const double caption = 14.0;

  // Body Text: 16 - Standard reading text, chat messages, articles
  static const double body = 16.0;

  // Buttons / Sub-headers: 16 to 18 - Action button labels, card titles, section headers
  static const double button = 16.0;
  static const double subheader = 18.0;

  // Main Headers: 20 to 24 - Page titles, major section headings
  static const double header = 20.0;
  static const double pageTitle = 24.0;

  // Large Displays: 30+ - Large stat counters, timers, or banner numbers
  static const double display = 32.0;
}

class AppTheme {
  // ===== NEW BLUE DESIGN - LOCKED =====
  static const background = Color(0xFF0A1428); // deep navy - main bg
  static const canvas = background;
  static const surface = Color(0xFF13233F); // card
  static const elevated = Color(0xFF16263F);
  static const divider = Color(0xFF1E3352);
  static const blue = Color(0xFF2D8DFF); // main button
  static const blueLight = Color(0xFF4DA6FF);
  static const blueDark = Color(0xFF1A6FD1);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8C6D9);
  static const textMuted = Color(0xFF8A9BB0);
  static const gold = Color(0xFFD9A441); // streak / trophy only
  static const textPrimaryOld = textPrimary;

  // ===== CHESS BOARD - NEW BLUE BOARD =====
  static const boardLight = Color(0xFFD7E6F5);
  static const boardDark = Color(0xFF5A86B8);
  static const boardWhitePiece = Color(0xFFF5F1E7);
  static const boardBlackPiece = Color(0xFF1A2B4A);

  // ===== STATUS =====
  static const success = Color(0xFF2D8DFF);
  static const error = Color(0xFFFF5A5A);
  static const warning = Color(0xFFD9A441);

  static const errorColor = error;

  // ===== MAIN THEMEDATA - THIS IS WHAT MAKES EVERYTHING BLUE =====
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: blue,
    colorScheme: const ColorScheme.dark(
      primary: blue,
      secondary: blueLight,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      error: error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    // --- Buttons ---
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textMuted,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
    // --- Cards ---
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
    ),
    // --- Inputs (for Welcome back / Sign in) ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: blue, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    // --- Bottom Nav ---
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: background,
      selectedItemColor: blue,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    // --- Text ---
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      bodySmall: TextStyle(fontSize: 14, color: textMuted),
    ),
    dividerColor: divider,
    iconTheme: const IconThemeData(color: textSecondary),
  );

  // For backwards compat if your main.dart uses AppTheme.theme
  static ThemeData get theme => darkTheme;
  static ThemeData get lightTheme => darkTheme;
}
