import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light and dark themes ported from exodus.css.
///
/// The two `ColorScheme`s are authored separately, not derived from one seed:
/// `primary` is blue by day and orange by night on purpose (decision 0011).
/// Tokens the mockup never uses (`--secondary`, `--accent`, `--chart-*`,
/// `--sidebar-*`, the serif and mono fonts) are deliberately not ported.
abstract final class AppTheme {
  static final ThemeData light = _build(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0284C7),
      onPrimary: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1C1917),
      error: Color(0xFFB91C1C),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFFE7E5E4),
    ),
    background: const Color(0xFFF5F5F4),
    appColors: AppColors.light,
  );

  static final ThemeData dark = _build(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF97316),
      onPrimary: Color(0xFF0C0A09),
      surface: Color(0xFF0C0A09),
      onSurface: Color(0xFFFAFAF9),
      error: Color(0xFFEF4444),
      onError: Color(0xFFFAFAF9),
      outline: Color(0xFF44403C),
    ),
    background: const Color(0xFF1C1917),
    appColors: AppColors.dark,
  );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color background,
    required AppColors appColors,
  }) {
    // Inter is the default (task titles, times, descriptions, placeholders).
    // DM Sans is for chrome and actions: titles and button labels.
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      extensions: [appColors],
    );
    // Tight tracking on every style; raw TextStyles inherit it via DefaultTextStyle.
    const tight = TextStyle(letterSpacing: -.8);
    final text = base.textTheme.merge(
      const TextTheme(
        displayLarge: tight,
        displayMedium: tight,
        displaySmall: tight,
        headlineLarge: tight,
        headlineMedium: tight,
        headlineSmall: tight,
        titleLarge: tight,
        titleMedium: tight,
        titleSmall: tight,
        bodyLarge: tight,
        bodyMedium: tight,
        bodySmall: tight,
        labelLarge: tight,
        labelMedium: tight,
        labelSmall: tight,
      ),
    );
    return base.copyWith(
      textTheme: text.copyWith(
        titleLarge: text.titleLarge?.copyWith(fontFamily: 'DMSans'),
        labelLarge: text.labelLarge?.copyWith(fontFamily: 'DMSans'),
      ),
    );
  }
}
