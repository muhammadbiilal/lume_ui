/// The themes as the tree actually sees them.
///
/// The token tests prove the values; these prove the wiring — that a widget
/// asking `context.lume` in a dark tree gets the dark palette, that Material's
/// own surfaces were configured rather than left at their defaults, and that
/// nothing falls back to Roboto.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume/lume_colors.dart';
import 'package:lume/core/theme/lume/lume_elevation.dart';
import 'package:lume/core/theme/lume/lume_gradients.dart';
import 'package:lume/core/theme/lume/lume_theme.dart';
import 'package:lume/core/theme/lume/lume_type.dart';

import '../../helpers/lume_harness.dart';

void main() {
  group('the extensions are installed', () {
    testWidgets('light resolves to the light tokens', (WidgetTester t) async {
      late LumeColors c;
      late LumeShadows s;
      late LumeGradients g;
      await pumpLume(
        t,
        LumeProbe(
          onBuild: (BuildContext ctx) {
            c = ctx.lume;
            s = ctx.lumeShadows;
            g = ctx.lumeGradients;
          },
        ),
      );
      expect(c.bg, LumeColors.light.bg);
      expect(s.sm, LumeShadows.light.sm);
      expect(g.accent.a, LumeGradients.light.accent.a);
    });

    testWidgets('dark resolves to the dark tokens', (WidgetTester t) async {
      late LumeColors c;
      late LumeShadows s;
      late LumeGradients g;
      await pumpLume(
        t,
        LumeProbe(
          onBuild: (BuildContext ctx) {
            c = ctx.lume;
            s = ctx.lumeShadows;
            g = ctx.lumeGradients;
          },
        ),
        theme: ThemeMode.dark,
      );
      expect(c.bg, LumeColors.dark.bg);
      expect(s.sm, LumeShadows.dark.sm);
      expect(g.accent.a, LumeGradients.dark.accent.a);
    });

    testWidgets('isDark reports the brightness', (WidgetTester t) async {
      late bool light;
      late bool dark;
      await pumpLume(
        t,
        LumeProbe(onBuild: (BuildContext c) => light = c.isDark),
      );
      await pumpLume(
        t,
        LumeProbe(onBuild: (BuildContext c) => dark = c.isDark),
        theme: ThemeMode.dark,
      );
      expect(light, isFalse);
      expect(dark, isTrue);
    });
  });

  group('Material is configured, not left at its defaults', () {
    test('the scaffold ground is the Lume page ground', () {
      expect(LumeTheme.light().scaffoldBackgroundColor, LumeColors.light.bg);
      expect(LumeTheme.dark().scaffoldBackgroundColor, LumeColors.dark.bg);
    });

    test('the colour scheme carries the accent and its ink', () {
      final ColorScheme s = LumeTheme.light().colorScheme;
      expect(s.primary, LumeColors.light.accent);
      expect(s.onPrimary, LumeColors.light.onAccent);
      expect(s.surface, LumeColors.light.card);
      expect(s.onSurface, LumeColors.light.text);
    });

    test('the error role uses the ink token, not the surface token', () {
      // Error *text* is roseInk; rose is the surface. Wiring the surface into
      // onError would put a 3.2:1 pink on white.
      expect(LumeTheme.light().colorScheme.error, LumeColors.light.roseInk);
    });

    test('nothing falls back to Roboto', () {
      final TextTheme t = LumeTheme.light().textTheme;
      for (final TextStyle? s in <TextStyle?>[
        t.displayLarge,
        t.titleLarge,
        t.bodyMedium,
        t.labelSmall,
      ]) {
        expect(s?.fontFamily, LumeType.family);
      }
    });

    test('Material ink splashes are off — Lume draws its own feedback', () {
      expect(LumeTheme.light().splashColor, Colors.transparent);
      expect(LumeTheme.light().highlightColor, Colors.transparent);
    });

    test('the divider is the hairline token', () {
      expect(LumeTheme.light().dividerTheme.color, LumeColors.light.border);
      expect(LumeTheme.light().dividerTheme.thickness, 1);
    });
  });

  group('theme interpolation does not crash', () {
    test('lerping light to dark produces a whole palette', () {
      final LumeColors mid = LumeColors.light.lerp(LumeColors.dark, 0.5);
      expect(mid.bg, isNot(LumeColors.light.bg));
      expect(mid.bg, isNot(LumeColors.dark.bg));
    });

    test('lerping shadows and gradients works too', () {
      expect(LumeShadows.light.lerp(LumeShadows.dark, 0.5), isA<LumeShadows>());
      expect(
        LumeGradients.light.lerp(LumeGradients.dark, 0.5),
        isA<LumeGradients>(),
      );
      expect(LumeType.standard.lerp(LumeType.standard, 0.5), isA<LumeType>());
    });

    test('copyWith keeps what it is not given', () {
      final LumeColors c = LumeColors.light.copyWith(
        bg: const Color(0xFF123456),
      );
      expect(c.bg, const Color(0xFF123456));
      expect(c.card, LumeColors.light.card);
    });
  });
}
