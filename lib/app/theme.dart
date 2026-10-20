import 'package:flutter/material.dart';

class AppTypography {
  // Micro Labels: 12 (Absolute Minimum) - Timestamps, copyright text, tiny badges
  static const double micro = 12.0;

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
  // ── Sky / Steel-Blue Palette ──────────────────────────────────────────────
  static const Color primary     = Color(0xFF1A6BB5); // steel-blue brand colour
  static const Color primaryDark = Color(0xFF0D4F8B); // deeper press state
  static const Color background  = Color(0xFFF4F8FD); // very light blue-tinted canvas
  static const Color card        = Color(0xFFFFFFFF);
  static const Color accent      = Color(0xFFE3EEF9); // pale-blue surface tint

  static final ThemeData lightTheme = _createTheme(Brightness.light);
  static final ThemeData darkTheme  = _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final canvas  = isLight ? background              : const Color(0xFF0D1520);
    final surface = isLight ? card                    : const Color(0xFF152032);
    final foreground = isLight ? const Color(0xFF0D1B2E) : const Color(0xFFE8F2FF);
    final muted      = isLight ? const Color(0xFF5E7A99) : const Color(0xFF7FA3C8);
    final border     = isLight ? const Color(0xFFCCDEF0) : const Color(0xFF1E3A57);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
    ).copyWith(primary: primary, onPrimary: Colors.white);

    final textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: foreground),
      displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: foreground),
      displaySmall: TextStyle(fontSize: AppTypography.display, fontWeight: FontWeight.w800, color: foreground),
      headlineLarge: TextStyle(fontSize: AppTypography.pageTitle, fontWeight: FontWeight.w800, color: foreground),
      headlineMedium: TextStyle(fontSize: AppTypography.pageTitle, fontWeight: FontWeight.w700, color: foreground),
      headlineSmall: TextStyle(fontSize: AppTypography.header, fontWeight: FontWeight.w700, color: foreground),
      titleLarge: TextStyle(fontSize: AppTypography.header, fontWeight: FontWeight.w700, color: foreground),
      titleMedium: TextStyle(fontSize: AppTypography.subheader, fontWeight: FontWeight.w600, color: foreground),
      titleSmall: TextStyle(fontSize: AppTypography.button, fontWeight: FontWeight.w600, color: foreground),
      bodyLarge: TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.w500, color: foreground),
      bodyMedium: TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.w400, color: foreground),
      bodySmall: TextStyle(fontSize: AppTypography.caption, fontWeight: FontWeight.w400, color: muted),
      labelLarge: TextStyle(fontSize: AppTypography.button, fontWeight: FontWeight.w700, color: foreground),
      labelMedium: TextStyle(fontSize: AppTypography.caption, fontWeight: FontWeight.w500, color: muted),
      labelSmall: TextStyle(fontSize: AppTypography.micro, fontWeight: FontWeight.w600, color: muted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: canvas,
      colorScheme: scheme,
      fontFamily: 'Inter',
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: AppTypography.header,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: .14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
