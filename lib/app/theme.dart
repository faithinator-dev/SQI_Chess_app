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
  static const background = Color(0xFF0A1428); // deep navy
  static const surface = Color(0xFF13233F); // card
  static const elevated = Color(0xFF16263F);
  static const divider = Color(0xFF1E3352);
  static const blue = Color(0xFF2D8DFF); // main button
  static const blueLight = Color(0xFF4DA6FF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8C6D9);
  static const textMuted = Color(0xFF8A9BB0);
  static const gold = Color(0xFFD9A441); // streak only
  static const textPrimaryOld = textPrimary;

  static Color? get errorColor => null;
}
