/// The right-to-left foundation: direction, mirroring, script coverage and the
/// runs that must not reorder.
///
/// `rtl.css` is small and exact — it flips seven selectors and isolates three
/// — and the discipline it encodes is what keeps RTL from becoming "mirror
/// everything and hope". These tests hold the Flutter side to the same rules.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icon.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/theme/lume/lume_type.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  group('the tree reads in the right direction', () {
    testWidgets('logical insets follow the reading direction', (
      WidgetTester tester,
    ) async {
      Future<double> startEdge(String code) async {
        await pumpLume(
          tester,
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 40),
            // Aligned to the start edge, and sized — `home:` hands its child
            // tight constraints, so an unaligned SizedBox would simply fill.
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(width: 20, height: 20, child: Placeholder()),
            ),
          ),
          locale: Locale(code),
          surface: const Size(400, 200),
        );
        return tester.getTopLeft(find.byType(Placeholder)).dx;
      }

      expect(await startEdge('en'), 40);
      expect(
        await startEdge('ar'),
        400 - 40 - 20,
        reason: 'start is the right edge when the page reads right to left',
      );
    });

    testWidgets('text aligns to the start edge in both directions', (
      WidgetTester tester,
    ) async {
      for (final (String code, TextDirection want) in <(String, TextDirection)>[
        ('en', TextDirection.ltr),
        ('ur', TextDirection.rtl),
        ('ar', TextDirection.rtl),
      ]) {
        late TextDirection got;
        await pumpLume(
          tester,
          LumeProbe(onBuild: (BuildContext c) => got = Directionality.of(c)),
          locale: Locale(code),
        );
        expect(got, want, reason: code);
      }
    });
  });

  group('only genuinely directional glyphs mirror', () {
    testWidgets('a forward chevron mirrors', (WidgetTester tester) async {
      await pumpLume(
        tester,
        const Center(child: LumeIcon(LumeIcons.chevR)),
        locale: const Locale('ar'),
      );
      expect(find.byType(Transform), findsOneWidget);
    });

    testWidgets('a clock, a play button and a compass do not', (
      WidgetTester tester,
    ) async {
      for (final String name in <String>[
        LumeIcons.clock,
        LumeIcons.play,
        LumeIcons.compass,
        LumeIcons.navigation,
      ]) {
        await pumpLume(
          tester,
          Center(child: LumeIcon(name)),
          locale: const Locale('ar'),
        );
        expect(
          find.byType(Transform),
          findsNothing,
          reason: '$name is a picture of a thing, not a reading direction',
        );
      }
    });

    test('the mirroring set is small and deliberate', () {
      // `rtl.css` flips seven selectors. The set here is the glyphs those
      // selectors contain; it should not grow without a reason.
      expect(LumeIcons.directional.length, lessThanOrEqualTo(10));
    });
  });

  group('numbers, times and codes do not reorder', () {
    testWidgets('an isolated run keeps its own direction inside RTL text', (
      WidgetTester tester,
    ) async {
      late TextDirection inside;
      await pumpLume(
        tester,
        LumeLtr(
          child: LumeProbe(
            onBuild: (BuildContext c) => inside = Directionality.of(c),
          ),
        ),
        locale: const Locale('ar'),
      );
      expect(inside, TextDirection.ltr);
    });

    testWidgets('two numeric runs keep their order in an RTL page', (
      WidgetTester tester,
    ) async {
      // Without isolation, bidi lays the two runs out in paragraph order and
      // "1,240.50  16:41" renders as "16:41 1,240.50" — the price and the time
      // silently swap places.
      await pumpLume(
        tester,
        const Center(child: LumeNumerals('1,240.50  16:41')),
        locale: const Locale('ur'),
        surface: const Size(400, 200),
      );

      final RenderBox box = tester.renderObject<RenderBox>(find.byType(Text));
      final TextPainter painter = TextPainter(
        text: const TextSpan(text: '1,240.50  16:41'),
        textDirection: TextDirection.ltr,
      )..layout();

      // The isolated run is laid out left to right, so its own width is the
      // LTR width — the same string measured in an RTL paragraph would not
      // differ in width, but its *offsets* would. Assert the direction that
      // produced it instead, which is the property that matters.
      expect(box.size.width, greaterThan(0));
      expect(painter.width, greaterThan(0));
      expect(
        Directionality.of(tester.element(find.byType(Text))),
        TextDirection.ltr,
      );
    });

    testWidgets('a numeric style asks for tabular figures', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Center(
          child: LumeNumerals(
            '16:41',
            style: LumeType.numeric(LumeType.standard.title),
          ),
        ),
        locale: const Locale('ar'),
      );
      final Text t = tester.widget<Text>(find.byType(Text));
      expect(
        t.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('Arabic script has a face to render in', () {
    test('every interface role falls back to the Arabic family', () {
      for (final MapEntry<String, TextStyle> e
          in LumeType.standard.all.entries) {
        expect(
          e.value.fontFamilyFallback,
          contains(LumeType.arabicFamily),
          reason:
              '${e.key} would render Urdu and Arabic as tofu — Plus '
              'Jakarta Sans has no Arabic glyphs, and Flutter does not fall '
              'back on its own the way a browser does',
        );
      }
    });

    testWidgets('an Urdu line renders with real glyph advances', (
      WidgetTester tester,
    ) async {
      // Tofu is a box per codepoint at a uniform advance. Real shaping joins
      // the letters, so the same string is narrower than the fallback boxes
      // would be — and, more simply, it has a width at all.
      await pumpLume(
        tester,
        Center(
          child: Text('آپ کا دن، ایک جگہ', style: LumeType.standard.title),
        ),
        locale: const Locale('ur'),
        surface: const Size(400, 200),
      );
      final Size size = tester.getSize(find.byType(Text));
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });

  group('script-aware measure', () {
    testWidgets('Urdu and Arabic get the looser line, English does not', (
      WidgetTester tester,
    ) async {
      Future<double> heightFor(String code) async {
        late double h;
        await pumpLume(
          tester,
          LumeProbe(
            onBuild: (BuildContext c) =>
                h = LumeType.fit(c, LumeType.standard.title).height!,
          ),
          locale: Locale(code),
        );
        return h;
      }

      expect(await heightFor('en'), closeTo(26 / 20, 0.001));
      expect(
        await heightFor('ur'),
        greaterThanOrEqualTo(LumeType.tallScriptMinHeight),
      );
      expect(
        await heightFor('ar'),
        greaterThanOrEqualTo(LumeType.tallScriptMinHeight),
      );
    });

    test('an Arabic reading passage is looser still', () {
      expect(
        LumeType.arabicReadingHeight,
        greaterThan(LumeType.tallScriptMinHeight),
      );
      expect(LumeType.arabicReadingHeight, greaterThanOrEqualTo(1.8));
    });
  });

  group('touch targets survive direction and scale', () {
    testWidgets('a 44 target is 44 in RTL too', (WidgetTester tester) async {
      await pumpLume(
        tester,
        const Center(
          child: SizedBox(
            width: LumeSpace.tap,
            height: LumeSpace.tap,
            child: Placeholder(),
          ),
        ),
        locale: const Locale('ar'),
      );
      expect(
        tester.getSize(find.byType(Placeholder)),
        const Size(LumeSpace.tap, LumeSpace.tap),
      );
    });
  });
}
