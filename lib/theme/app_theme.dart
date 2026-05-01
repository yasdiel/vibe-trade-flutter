import 'package:flutter/material.dart';

enum AppThemeMode { light, dark }

class AppTheme {
  static final ValueNotifier<AppThemeMode> modeNotifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.light);

  static AppThemeMode get mode => modeNotifier.value;
  static bool get isDark => mode == AppThemeMode.dark;

  // ---- Light palette ----
  static const Color _lightPrimary = Colors.red;
  static const Color _lightForeground = Colors.white;
  static final Color _lightSelected = Colors.red.shade50;
  static const Color _lightAccentGreen = Color.fromARGB(255, 198, 255, 236);
  static const Color _lightAccentGreenSurface = Color.fromARGB(255, 63, 7, 7);
  static const Color _lightAppBg = Color.fromARGB(255, 235, 231, 231);

  static const Color _lightTextPrimary = Color(0xDD000000);
  static const Color _lightTextSecondary = Color(0xFF555555);
  static const Color _lightTextMuted = Color(0xFF888888);
  static const Color _lightDivider = Color(0x1F000000);
  static const Color _lightInputFill = Color(0xFFF2F2F4);
  static const Color _lightSubtleSurface = Color(0xFFFAFAFA);
  static const Color _lightSurfaceMuted = Color(0xFFEFEFF1);
  static const Color _lightHint = Color(0xFF8A8A8E);
  static const Color _lightOverlayHigh = Color(0x14000000);
  static const Color _lightSuccess = Color(0xFF15803D);
  static const Color _lightSuccessSurface = Color(0xFFE7F8EE);
  static const Color _lightWarning = Color(0xFFB45309);
  static const Color _lightWarningSurface = Color(0xFFFFF4E0);
  static const Color _lightError = Color(0xFFDC2626);
  static const Color _lightErrorSurface = Color(0xFFFDECEC);

  // ---- Dark palette ----
  static const Color _darkPrimary = Color(0xFFFF6B6B);
  static const Color _darkForeground = Color(0xFF1A1A1D);
  static const Color _darkSelected = Color(0xFF3A2326);
  static const Color _darkAccentGreen = Color(0xFFB7F5DD);
  static const Color _darkAccentGreenSurface = Color(0xFF1B3A33);
  static const Color _darkAppBg = Color(0xFF0E0E11);

  static const Color _darkTextPrimary = Color(0xFFF1F1F4);
  static const Color _darkTextSecondary = Color(0xFFAEAEB5);
  static const Color _darkTextMuted = Color(0xFF7A7A82);
  static const Color _darkDivider = Color(0x33FFFFFF);
  static const Color _darkInputFill = Color(0xFF26262A);
  static const Color _darkSubtleSurface = Color(0xFF18181B);
  static const Color _darkSurfaceMuted = Color(0xFF1F1F22);
  static const Color _darkHint = Color(0xFF80808A);
  static const Color _darkOverlayHigh = Color(0x33FFFFFF);
  static const Color _darkSuccess = Color(0xFF4ADE80);
  static const Color _darkSuccessSurface = Color(0xFF14352A);
  static const Color _darkWarning = Color(0xFFF59E0B);
  static const Color _darkWarningSurface = Color(0xFF3A2A12);
  static const Color _darkError = Color(0xFFF87171);
  static const Color _darkErrorSurface = Color(0xFF3A1F22);

  // ---- Reactive getters ----
  static Color get primaryColor => isDark ? _darkPrimary : _lightPrimary;
  static Color get foregroundColor =>
      isDark ? _darkForeground : _lightForeground;
  static Color get selectedColor => isDark ? _darkSelected : _lightSelected;
  static Color get accentGreenColor =>
      isDark ? _darkAccentGreen : _lightAccentGreen;
  static Color get accentGreenSurfaceColor =>
      isDark ? _darkAccentGreenSurface : _lightAccentGreenSurface;
  static Color get appBgColor => isDark ? _darkAppBg : _lightAppBg;

  static Color get textPrimary =>
      isDark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary =>
      isDark ? _darkTextSecondary : _lightTextSecondary;
  static Color get textMuted => isDark ? _darkTextMuted : _lightTextMuted;
  static Color get hintColor => isDark ? _darkHint : _lightHint;
  static Color get dividerColor => isDark ? _darkDivider : _lightDivider;
  static Color get inputFillColor =>
      isDark ? _darkInputFill : _lightInputFill;
  static Color get subtleSurfaceColor =>
      isDark ? _darkSubtleSurface : _lightSubtleSurface;
  static Color get surfaceMutedColor =>
      isDark ? _darkSurfaceMuted : _lightSurfaceMuted;
  static Color get overlayHighlightColor =>
      isDark ? _darkOverlayHigh : _lightOverlayHigh;

  static Color get successColor => isDark ? _darkSuccess : _lightSuccess;
  static Color get successSurface =>
      isDark ? _darkSuccessSurface : _lightSuccessSurface;
  static Color get warningColor => isDark ? _darkWarning : _lightWarning;
  static Color get warningSurface =>
      isDark ? _darkWarningSurface : _lightWarningSurface;
  static Color get errorColor => isDark ? _darkError : _lightError;
  static Color get errorSurface =>
      isDark ? _darkErrorSurface : _lightErrorSurface;

  // ---- Material ThemeData builders ----
  static ThemeData buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightPrimary,
        brightness: Brightness.light,
        primary: _lightPrimary,
        surface: _lightForeground,
        error: _lightError,
      ),
      scaffoldBackgroundColor: _lightAppBg,
      cardColor: _lightForeground,
      dividerColor: _lightDivider,
      iconTheme: const IconThemeData(color: _lightTextSecondary),
      hintColor: _lightHint,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: _lightTextPrimary,
        displayColor: _lightTextPrimary,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: _lightForeground,
        displayColor: _lightForeground,
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightPrimary,
        brightness: Brightness.dark,
        primary: _darkPrimary,
        surface: _darkForeground,
        error: _darkError,
      ),
      scaffoldBackgroundColor: _darkAppBg,
      cardColor: _darkForeground,
      dividerColor: _darkDivider,
      iconTheme: const IconThemeData(color: _darkTextSecondary),
      hintColor: _darkHint,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: _darkTextPrimary,
        displayColor: _darkTextPrimary,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: _darkTextPrimary,
        displayColor: _darkTextPrimary,
      ),
    );
  }
}
