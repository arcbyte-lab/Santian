import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/app.dart';
import 'package:santian/core/theme/app_colors.dart';
import 'package:santian/core/theme/app_radius.dart';
import 'package:santian/core/theme/app_shadows.dart';
import 'package:santian/core/theme/app_theme.dart';

Future<ThemeData> _themeUnder(WidgetTester tester, Brightness brightness) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(const SantianApp(home: Scaffold()));
  return Theme.of(tester.element(find.byType(Scaffold)));
}

void main() {
  group('the app follows the system brightness', () {
    testWidgets('light: blue primary', (tester) async {
      final theme = await _themeUnder(tester, Brightness.light);

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF0284C7));
      expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.onSurface, const Color(0xFF1C1917));
      expect(theme.colorScheme.error, const Color(0xFFB91C1C));
      expect(theme.colorScheme.outline, const Color(0xFFE7E5E4));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF5F5F4));
    });

    testWidgets('dark: orange primary', (tester) async {
      final theme = await _themeUnder(tester, Brightness.dark);

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFF97316));
      expect(theme.colorScheme.onPrimary, const Color(0xFF0C0A09));
      expect(theme.colorScheme.surface, const Color(0xFF1C1917));
      expect(theme.colorScheme.onSurface, const Color(0xFFFAFAF9));
      expect(theme.colorScheme.error, const Color(0xFFEF4444));
      expect(theme.colorScheme.outline, const Color(0xFF44403C));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0C0A09));
    });
  });

  test('the two primaries are different hues, not one seed by brightness', () {
    expect(
      AppTheme.light.colorScheme.primary,
      isNot(AppTheme.dark.colorScheme.primary),
    );
  });

  group('muted colours', () {
    test('light and dark values', () {
      final light = AppTheme.light.extension<AppColors>()!;
      final dark = AppTheme.dark.extension<AppColors>()!;

      expect(light.muted, const Color(0xFFE7E5E4));
      expect(light.mutedForeground, const Color(0xFF57534E));
      expect(dark.muted, const Color(0xFF292524));
      expect(dark.mutedForeground, const Color(0xFFA8A29E));
    });

    test('lerp blends between light and dark', () {
      final mid = AppColors.light.lerp(AppColors.dark, 0.5);

      expect(mid.muted, Color.lerp(AppColors.light.muted, AppColors.dark.muted, 0.5));
      expect(AppColors.light.lerp(null, 0.5), AppColors.light);
    });
  });

  group('fonts', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      test('DM Sans for chrome and actions, Inter for the rest (${theme.brightness.name})', () {
        final text = theme.textTheme;

        expect(text.titleLarge!.fontFamily, 'DMSans');
        expect(text.labelLarge!.fontFamily, 'DMSans');
        expect(text.bodyMedium!.fontFamily, 'Inter');
        expect(text.bodySmall!.fontFamily, 'Inter');
      });
    }

    test('every bundled font file loads', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final family in ['DMSans', 'Inter']) {
        for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
          final data = await rootBundle.load('assets/fonts/$family-$weight.ttf');
          expect(data.lengthInBytes, greaterThan(10000), reason: '$family-$weight');
        }
      }
    });
  });

  test('named radii match the mockup', () {
    expect(AppRadius.sheet, 58);
    expect(AppRadius.pill, 100);
    expect(AppRadius.chip, 20);
    expect(AppRadius.fab, 26);
  });

  test('the FAB shadow is the one drawn value, 0 4 16 #00000025', () {
    expect(fabShadow.offset, const Offset(0, 4));
    expect(fabShadow.blurRadius, 16);
    expect(fabShadow.color, const Color(0x25000000));
  });
}
