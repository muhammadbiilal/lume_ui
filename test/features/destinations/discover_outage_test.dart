/// The Discover strip's outage card, and the sixteen points it costs (D23).
///
/// The reference writes `<span class="minicard__title">Next outage 14:00`
/// into fixed markup — an untranslated literal, and one its own schedule
/// contradicts: that slot ends at 16:00 and the card was still naming it at
/// 16:41 (C17). Flutter names the next slot, in the user's own clock, which is
/// the whole point of the correction. The cost is that "7:00 pm" is longer
/// than "14:00" and the title takes a second line.
///
/// The card's text region is not the cause, and this proves it: the region is
/// 124 points wide on both sides, `.minicard__title` has no clamp and no
/// `nowrap`, and the reference's own card would wrap on the same string. So
/// the growth is the string's, and it is bounded — one line, never two.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/features/home/presentation/home_screen.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// `.minicard` measured in the reference: 148 wide, 140.25 tall with a
  /// one-line title, its body `padding: 10px 11px 12px`.
  const double referenceHeight = 140.25;

  /// `.minicard__title { font-size: 13px; line-height: 1.25 }`.
  const double titleLine = 16.25;

  /// 148 less two borders and two 11-point paddings.
  const double titleRegion = 124;

  Future<double> cardHeight(
    WidgetTester tester,
    String title,
    String meta, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) async {
    await pumpLume(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: LumeMiniCard(title: title, meta: meta, art: const SizedBox()),
      ),
      locale: locale,
      textScale: textScale,
    );
    expect(tester.takeException(), isNull);
    return tester.getSize(find.byType(LumeMiniCard)).height;
  }

  /// The title and meta the screen would actually build, for a clock.
  Future<(String, String)> outageText(
    WidgetTester tester, {
    required bool hour12,
    Locale locale = const Locale('en'),
  }) async {
    late String title;
    late String meta;
    await pumpLume(
      tester,
      Builder(
        builder: (BuildContext c) {
          final AppLocalizations l = AppLocalizations.of(c);
          final LumeFormatting f = LumeFormatting(
            locale: locale,
            hour12: hour12,
          );
          title = l.homeNextOutage(f.time(DateTime(2026, 9, 7, 19)));
          meta = l.homeOutageArea('Gulshan', 2);
          return const SizedBox();
        },
      ),
      locale: locale,
    );
    return (title, meta);
  }

  group('the card the reference draws', () {
    testWidgets('is 140.25 tall, and so is ours on the same string', (
      WidgetTester tester,
    ) async {
      final double h = await cardHeight(
        tester,
        'Next outage 14:00',
        'Gulshan · 2 hours',
      );
      expect(h, closeTo(referenceHeight, 1));
    });

    testWidgets('and stays that way for a 24-hour clock', (
      WidgetTester tester,
    ) async {
      final (String title, String meta) = await outageText(
        tester,
        hour12: false,
      );
      expect(title, 'Next outage 19:00');
      expect(
        await cardHeight(tester, title, meta),
        closeTo(referenceHeight, 1),
        reason: 'the truthful 24-hour value fits, so nothing may grow',
      );
    });
  });

  group('the twelve-hour clock', () {
    testWidgets('is four points too wide for one line, and no more', (
      WidgetTester tester,
    ) async {
      final (String title, String meta) = await outageText(
        tester,
        hour12: true,
      );
      expect(title, 'Next outage 7:00 pm');

      await cardHeight(tester, title, meta);
      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(LumeMiniCard),
          matching: find.text(title),
        ),
      );
      final double natural = p.getMaxIntrinsicWidth(double.infinity);
      expect(
        natural,
        greaterThan(titleRegion),
        reason: 'if it fits, it must not be wrapping',
      );
      expect(
        natural - titleRegion,
        lessThan(6),
        reason:
            'four points over a 124-point region. Anything larger means the '
            'region is wrong, not the string',
      );
    });

    testWidgets('costs exactly one line, and the card exactly one line', (
      WidgetTester tester,
    ) async {
      final (String title, String meta) = await outageText(
        tester,
        hour12: true,
      );
      final double h = await cardHeight(tester, title, meta);
      expect(h, closeTo(referenceHeight + titleLine, 1));
      expect(
        h,
        lessThan(referenceHeight + titleLine * 2),
        reason: 'two lines is the cap; a third would be a layout fault',
      );
    });

    testWidgets('and never truncates the time it just worked out', (
      WidgetTester tester,
    ) async {
      final (String title, String meta) = await outageText(
        tester,
        hour12: true,
      );
      await cardHeight(tester, title, meta);
      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(LumeMiniCard),
          matching: find.text(title),
        ),
      );
      expect(p.didExceedMaxLines, isFalse, reason: 'the time is ellipsised');
    });
  });

  group('every language and every scale', () {
    testWidgets('wraps to two lines at most and never overflows', (
      WidgetTester tester,
    ) async {
      final List<String> report = <String>[];
      for (final Locale locale in <Locale>[
        const Locale('en'),
        const Locale('ur'),
        const Locale('ar'),
      ]) {
        for (final bool hour12 in <bool>[false, true]) {
          final (String title, String meta) = await outageText(
            tester,
            hour12: hour12,
            locale: locale,
          );
          final double h = await cardHeight(
            tester,
            title,
            meta,
            locale: locale,
          );
          report.add(
            '${locale.languageCode} ${hour12 ? "12h" : "24h"} '
            '${h.toStringAsFixed(2)} "$title"',
          );
          expect(
            h,
            lessThanOrEqualTo(referenceHeight + titleLine * 2 + 6),
            reason: 'at $locale, hour12 $hour12: $title',
          );
        }
      }
      // A tall script sets on a taller line, so the two RTL languages are
      // allowed to be taller than English on the same number of lines.
      expect(report, hasLength(6));
    });

    testWidgets('and grows rather than clipping at 200 per cent', (
      WidgetTester tester,
    ) async {
      final (String title, String meta) = await outageText(
        tester,
        hour12: true,
      );
      final double normal = await cardHeight(tester, title, meta);
      final double large = await cardHeight(
        tester,
        title,
        meta,
        textScale: 2.0,
      );
      expect(large, greaterThan(normal));
      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(LumeMiniCard),
          matching: find.text(title),
        ),
      );
      expect(
        p.didExceedMaxLines,
        isTrue,
        reason:
            'two lines is the cap, so at 200 per cent it ellipsises rather '
            'than pushing the strip off the page — recorded, not silent',
      );
    });
  });

  group('the strip they sit in', () {
    testWidgets('stretches every card to the tallest, as the flex does', (
      WidgetTester tester,
    ) async {
      await pumpHome(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 5000),
      );

      final Finder strip = find.descendant(
        of: find.byKey(const ValueKey<String>(LumeHomeScreen.discoverKey)),
        matching: find.byType(LumeMiniCard),
      );
      expect(strip, findsWidgets);

      final List<double> heights = strip
          .evaluate()
          .map((Element e) => (e.renderObject! as RenderBox).size.height)
          .toList();
      expect(
        heights.toSet(),
        hasLength(1),
        reason:
            '`.hscroll` is a flex with the default `align-items: stretch`, so '
            'one two-line card raises every card beside it. A Row centres '
            'instead, and left a ragged strip.',
      );
    });
  });
}
