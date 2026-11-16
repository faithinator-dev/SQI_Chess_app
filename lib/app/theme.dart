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
  // ── Brand Primary Palette ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF1E293B); // Clean modern Slate / Charcoal
  static const Color primaryDark = Color(0xFF0F172A); // Deeper state
  static const Color primaryLight = Color(0xFF334155);

  // ── Light Theme Palette ────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightForeground = Color(0xFF0F172A);
  static const Color lightMuted = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // ── Premium Dark Theme Palette (Sleek Obsidian / Deep Midnight) ────────────
  // Avoids murky muddy blue-green shades; uses crisp OLED-friendly neutral depth
  static const Color darkBg = Color(0xFF0A0F1D); // Deep Obsidian Canvas
  static const Color darkSurface = Color(0xFF131B2E); // Elevated Card Surface
  static const Color darkSurfaceElevated = Color(0xFF1B243B); // Secondary / Input Fill
  static const Color darkForeground = Color(0xFFF1F5F9); // Crisp High-Contrast White
  static const Color darkForegroundMuted = Color(0xFF94A3B8); // Soft Slate Gray
  static const Color darkBorder = Color(0xFF243048); // Subtle Refined Border
  static const Color darkAccent = Color(0xFF38BDF8); // Electric Sky Accent (Pawn/Knight highlights)

  static final ThemeData lightTheme = _createTheme(Brightness.light);
  static final ThemeData darkTheme = _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final canvas = isLight ? lightBg : darkBg;
    final surface = isLight ? lightSurface : darkSurface;
    final foreground = isLight ? lightForeground : darkForeground;
    final muted = isLight ? lightMuted : darkForegroundMuted;
    final border = isLight ? lightBorder : darkBorder;
    final brandAction = isLight ? primary : const Color(0xFF38BDF8);
    final buttonForeground = isLight ? Colors.white : const Color(0xFF0A0F1D);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: brandAction,
      onPrimary: buttonForeground,
      secondary: isLight ? const Color(0xFF475569) : darkAccent,
      onSecondary: isLight ? Colors.white : const Color(0xFF0A0F1D),
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      surface: surface,
      onSurface: foreground,
      surfaceContainerHighest: isLight ? const Color(0xFFF1F5F9) : darkSurfaceElevated,
      outline: border,
    );

    final textTheme = TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.w800, color: foreground),
      displayMedium: TextStyle(fontWeight: FontWeight.w800, color: foreground),
      displaySmall: TextStyle(fontWeight: FontWeight.w800, color: foreground),
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: foreground),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: foreground),
      headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: foreground),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: foreground),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: foreground),
      titleSmall: TextStyle(fontWeight: FontWeight.w600, color: foreground),
      bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: foreground),
      bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: foreground),
      bodySmall: TextStyle(fontWeight: FontWeight.w400, color: muted),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, color: foreground),
      labelMedium: TextStyle(fontWeight: FontWeight.w500, color: muted),
      labelSmall: TextStyle(fontWeight: FontWeight.w600, color: muted),
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
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: foreground),
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      dividerColor: border,
      hintColor: muted,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : darkSurfaceElevated,
        labelStyle: TextStyle(color: muted, fontSize: 14),
        hintStyle: TextStyle(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brandAction, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLight ? primary : const Color(0xFF38BDF8),
          foregroundColor: buttonForeground,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border, width: 1.2),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: isLight
            ? primary.withValues(alpha: .1)
            : darkAccent.withValues(alpha: .18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: isLight ? primary : darkAccent);
          }
          return IconThemeData(color: muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? (isLight ? primary : darkAccent)
                : muted,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: foreground,
        iconColor: muted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? const Color(0xFF1E293B) : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
