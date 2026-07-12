import 'package:flutter/material.dart';

// ─── Theme Definitions ────────────────────────────────────────────────────────
class AppThemeOption {
  final String id;
  final String name;
  final String emoji;
  final Color primary;
  final Color background;
  final Color surface;
  final Color accent;
  final Color textHigh;
  final Color textLow;
  final Color cardColor;
  final Color danger;
  final bool isDark;

  const AppThemeOption({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.background,
    required this.surface,
    required this.accent,
    required this.textHigh,
    required this.textLow,
    required this.cardColor,
    required this.danger,
    required this.isDark,
  });
}

const List<AppThemeOption> appThemes = [
  // ── Dark Forest (Default) ──────────────────────────────────────────────────
  AppThemeOption(
    id: 'dark',
    name: 'Dark Forest',
    emoji: '🌿',
    primary:    Color(0xFF4CAF82),
    background: Color(0xFF013220),
    surface:    Color(0xFF0D2E1C),
    accent:     Color(0xFF4CAF82),
    textHigh:   Color(0xFFE8F5EC),
    textLow:    Color(0xFF7BAF92),
    cardColor:  Color(0xFF0A3D25),
    danger:     Color(0xFFE0715A),
    isDark: true,
  ),

  // ── Midnight Blue ─────────────────────────────────────────────────────────
  AppThemeOption(
    id: 'midnight',
    name: 'Midnight Blue',
    emoji: '🌙',
    primary:    Color(0xFF5B8DEF),
    background: Color(0xFF020B1A),
    surface:    Color(0xFF0D1B2E),
    accent:     Color(0xFF5B8DEF),
    textHigh:   Color(0xFFE8EFF8),
    textLow:    Color(0xFF7BA0C0),
    cardColor:  Color(0xFF0A213A),
    danger:     Color(0xFFEF5350),
    isDark: true,
  ),

  // ── Desert Gold ───────────────────────────────────────────────────────────
  AppThemeOption(
    id: 'desert',
    name: 'Desert Gold',
    emoji: '🏜️',
    primary:    Color(0xFFD4AF37),
    background: Color(0xFF1A1200),
    surface:    Color(0xFF2A1E00),
    accent:     Color(0xFFD4AF37),
    textHigh:   Color(0xFFF5EDD4),
    textLow:    Color(0xFFB8A060),
    cardColor:  Color(0xFF221900),
    danger:     Color(0xFFD9663B),
    isDark: true,
  ),

  // ── Rose Dusk ─────────────────────────────────────────────────────────────
  AppThemeOption(
    id: 'rose',
    name: 'Rose Dusk',
    emoji: '🌹',
    primary:    Color(0xFFE07A8F),
    background: Color(0xFF1A0A10),
    surface:    Color(0xFF2E1020),
    accent:     Color(0xFFE07A8F),
    textHigh:   Color(0xFFF5E0E7),
    textLow:    Color(0xFFB07080),
    cardColor:  Color(0xFF240D18),
    danger:     Color(0xFFE04B5C),
    isDark: true,
  ),

  // ── Light Ivory ───────────────────────────────────────────────────────────
  AppThemeOption(
    id: 'light',
    name: 'Light Ivory',
    emoji: '☀️',
    primary:    Color(0xFF2E7D5A),
    background: Color(0xFFF5F5F0),
    surface:    Color(0xFFFFFFFF),
    accent:     Color(0xFF4CAF82),
    textHigh:   Color(0xFF1A2D22),
    textLow:    Color(0xFF5A7A66),
    cardColor:  Color(0xFFEEF5F0),
    danger:     Color(0xFFC0392B),
    isDark: false,
  ),

  // ── Ocean Teal ────────────────────────────────────────────────────────────
  AppThemeOption(
    id: 'ocean',
    name: 'Ocean Teal',
    emoji: '🌊',
    primary:    Color(0xFF26C6DA),
    background: Color(0xFF011520),
    surface:    Color(0xFF082030),
    accent:     Color(0xFF26C6DA),
    textHigh:   Color(0xFFDDF5F8),
    textLow:    Color(0xFF60A0B0),
    cardColor:  Color(0xFF0A2535),
    danger:     Color(0xFFE0645A),
    isDark: true,
  ),
];

AppThemeOption getThemeById(String id) {
  return appThemes.firstWhere((t) => t.id == id,
      orElse: () => appThemes.first);
}

ThemeData buildThemeData(AppThemeOption theme) {
  return ThemeData(
    brightness: theme.isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: theme.background,
    primaryColor: theme.primary,
    colorScheme: ColorScheme(
      brightness: theme.isDark ? Brightness.dark : Brightness.light,
      primary:    theme.primary,
      onPrimary:  Colors.white,
      secondary:  theme.accent,
      onSecondary:Colors.white,
      error:      theme.danger,
      onError:    Colors.white,
      background: theme.background,
      onBackground: theme.textHigh,
      surface:    theme.surface,
      onSurface:  theme.textHigh,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: theme.surface,
      foregroundColor: theme.textHigh,
      elevation: 0,
    ),
    cardColor: theme.cardColor,
    dividerColor: theme.textLow.withOpacity(0.2),
    textTheme: TextTheme(
      bodyLarge:  TextStyle(color: theme.textHigh),
      bodyMedium: TextStyle(color: theme.textHigh),
      bodySmall:  TextStyle(color: theme.textLow),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
            ? theme.accent : theme.textLow,
      ),
      trackColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
            ? theme.accent.withOpacity(0.4) : theme.textLow.withOpacity(0.2),
      ),
    ),
  );
}