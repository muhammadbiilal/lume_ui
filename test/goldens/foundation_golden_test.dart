/// The golden harness, proved on the foundation itself.
///
/// A golden proves Flutter has not changed. It does **not** prove Flutter
/// matches Lume — that is what the side-by-side comparison against the
/// reference does, and a golden is only written once its cell has been
/// compared and signed off. So these are deliberately narrow: they freeze the
/// tokens, which have already been checked against `tokens.css` value by value
/// by `token_parity_test.dart`.
///
/// Run `flutter test --update-goldens` only when a change to the design is
/// intended and approved.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icon.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/core/theme/lume/lume_gradients.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/theme/lume/lume_theme.dart';
import 'package:lume/core/theme/lume/lume_type.dart';

import '../helpers/load_fonts.dart';
import '../helpers/lume_harness.dart';

void main() {
  // Without the real faces, every glyph renders as a filled box and the type
  // goldens freeze a picture of rectangles.
  setUpAll(loadLumeFonts);

  group('palette', () {
    for (final (String label, ThemeMode mode) in <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      testWidgets('$label palette', (WidgetTester tester) async {
        await pumpLume(
          tester,
          const _PaletteSheet(),
          theme: mode,
          surface: const Size(420, 300),
        );
        await expectLater(
          find.byType(_PaletteSheet),
          matchesGoldenFile('images/palette_$label.png'),
        );
      });
    }
  });

  group('type scale', () {
    for (final (String label, String code) in <(String, String)>[
      ('en', 'en'),
      ('ur', 'ur'),
      ('ar', 'ar'),
    ]) {
      testWidgets('type scale — $label', (WidgetTester tester) async {
        await pumpLume(
          tester,
          const _TypeSheet(),
          locale: Locale(code),
          surface: const Size(420, 560),
        );
        await expectLater(
          find.byType(_TypeSheet),
          matchesGoldenFile('images/type_$label.png'),
        );
      });
    }

    testWidgets('type scale at 200 per cent', (WidgetTester tester) async {
      await pumpLume(
        tester,
        const _TypeSheet(),
        textScale: 2.0,
        surface: const Size(420, 1100),
      );
      await expectLater(
        find.byType(_TypeSheet),
        matchesGoldenFile('images/type_en_x2.png'),
      );
    });
  });

  group('gradients', () {
    for (final (String label, ThemeMode mode) in <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      testWidgets('gradient colourways — $label', (WidgetTester tester) async {
        await pumpLume(
          tester,
          const _GradientSheet(),
          theme: mode,
          surface: const Size(420, 300),
        );
        await expectLater(
          find.byType(_GradientSheet),
          matchesGoldenFile('images/gradients_$label.png'),
        );
      });
    }
  });

  group('icons', () {
    testWidgets('the whole set renders', (WidgetTester tester) async {
      await pumpLume(tester, const _IconSheet(), surface: const Size(420, 700));
      await expectLater(
        find.byType(_IconSheet),
        matchesGoldenFile('images/icons.png'),
      );
    });

    testWidgets('directional icons in RTL', (WidgetTester tester) async {
      await pumpLume(
        tester,
        const _DirectionSheet(),
        locale: const Locale('ar'),
        surface: const Size(420, 120),
      );
      await expectLater(
        find.byType(_DirectionSheet),
        matchesGoldenFile('images/icons_rtl.png'),
      );
    });
  });
}

class _PaletteSheet extends StatelessWidget {
  const _PaletteSheet();

  @override
  Widget build(BuildContext context) {
    final List<Color> row1 = <Color>[
      context.lume.accent50,
      context.lume.accent100,
      context.lume.accent200,
      context.lume.accent400,
      context.lume.accent,
      context.lume.accent600,
      context.lume.accent700,
    ];
    final List<Color> row2 = <Color>[
      context.lume.violet,
      context.lume.indigo,
      context.lume.amber,
      context.lume.rose,
      context.lume.sky,
    ];
    final List<Color> row3 = <Color>[
      context.lume.bg,
      context.lume.bgSunk,
      context.lume.card,
      context.lume.card2,
      context.lume.cardHover,
      context.lume.tintAccent,
      context.lume.tintNeutral,
    ];
    final List<Color> row4 = <Color>[
      context.lume.text,
      context.lume.text2,
      context.lume.text3,
      context.lume.accentInk,
      context.lume.roseInk,
      context.lume.amberInk,
    ];

    Widget band(List<Color> colours) => Row(
      children: <Widget>[
        for (final Color c in colours)
          Expanded(child: Container(height: 56, color: c)),
      ],
    );

    return Container(
      color: context.lume.bg,
      padding: const EdgeInsets.all(LumeSpace.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          band(row1),
          const SizedBox(height: LumeSpace.x2),
          band(row2),
          const SizedBox(height: LumeSpace.x2),
          band(row3),
          const SizedBox(height: LumeSpace.x2),
          band(row4),
        ],
      ),
    );
  }
}

class _TypeSheet extends StatelessWidget {
  const _TypeSheet();

  @override
  Widget build(BuildContext context) {
    final LumeType t = context.lumeType;
    return Container(
      color: context.lume.bg,
      padding: const EdgeInsets.all(LumeSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final MapEntry<String, TextStyle> e in t.all.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: LumeSpace.x2),
              child: Text(
                _sample(Localizations.localeOf(context).languageCode, e.key),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LumeType.fit(
                  context,
                  e.value,
                ).copyWith(color: context.lume.text),
              ),
            ),
          LumeNumerals(
            '1,240.50  16:41',
            style: LumeType.numeric(t.title).copyWith(color: context.lume.text),
          ),
        ],
      ),
    );
  }
}

/// A specimen in the locale's own script, so the ur and ar goldens exercise
/// the shaping and the looser line height rather than rendering English twice.
String _sample(String code, String role) => switch (code) {
  'ur' => 'آپ کا دن، ایک جگہ',
  'ar' => 'يومك في مكان واحد',
  _ => role,
};

class _GradientSheet extends StatelessWidget {
  const _GradientSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.lume.bg,
      padding: const EdgeInsets.all(LumeSpace.x4),
      child: Wrap(
        spacing: LumeSpace.x2,
        runSpacing: LumeSpace.x2,
        children: <Widget>[
          for (final MapEntry<String, LumeGradient> g
              in context.lumeGradients.all.entries)
            Container(
              width: 84,
              height: 56,
              decoration: BoxDecoration(
                gradient: g.value.linear,
                borderRadius: LumeRadius.brMd,
              ),
            ),
        ],
      ),
    );
  }
}

class _IconSheet extends StatelessWidget {
  const _IconSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.lume.bg,
      padding: const EdgeInsets.all(LumeSpace.x4),
      child: Wrap(
        spacing: LumeSpace.x3,
        runSpacing: LumeSpace.x3,
        children: <Widget>[
          for (final String n in LumeIcons.all)
            LumeIcon.large(n, color: context.lume.text2),
        ],
      ),
    );
  }
}

class _DirectionSheet extends StatelessWidget {
  const _DirectionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.lume.bg,
      padding: const EdgeInsets.all(LumeSpace.x4),
      child: Row(
        children: <Widget>[
          // These mirror.
          LumeIcon.large(LumeIcons.chevR, color: context.lume.text2),
          LumeIcon.large(LumeIcons.arrowR, color: context.lume.text2),
          const SizedBox(width: LumeSpace.x6),
          // These must not.
          LumeIcon.large(LumeIcons.clock, color: context.lume.text2),
          LumeIcon.large(LumeIcons.play, color: context.lume.text2),
          LumeIcon.large(LumeIcons.arrowUp, color: context.lume.text2),
        ],
      ),
    );
  }
}
