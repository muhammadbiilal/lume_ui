/// The "Right now" cards, and the 22 points the reference spills (D25).
///
/// `#liveNow .livecard` measures 372.31 wide at x 20 in a 390 viewport: the
/// card is 2.31 points wider than the screen and 22.31 wider than the column
/// it sits in (C20). The trailing figure and the market pill cannot shrink, so
/// the row grows instead of wrapping, and the right-hand edge of every live
/// card is off the side of the phone.
///
/// Correcting it was approved as a responsive repair. This is the condition
/// attached to that approval: the hierarchy, density and geometry are Lume's,
/// and the card is inside its column at every width the product supports, in
/// both directions, at any text scale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/layout/lume_breakpoint.dart';
import 'package:lume/core/layout/lume_measure.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';

import '../../helpers/load_fonts.dart';
import 'destination_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// The column a section's content sits in, computed the way the page does.
  double column(double width) {
    final LumeWidthClass measure = LumeBreakpoints.classFor(width);
    final double gutter = LumeLayout.pageGutter(measure);
    final double cap = measure == LumeWidthClass.compact
        ? width
        : (width < LumeLayout.contentCap(measure)
              ? width
              : LumeLayout.contentCap(measure));
    return cap - gutter * 2;
  }

  /// Every width the brief names, including the two breakpoint edges.
  const List<double> widths = <double>[359, 360, 390, 600, 700, 840, 1100];

  Future<void> check(
    WidgetTester tester,
    double width, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) async {
    await pumpHome(
      tester,
      LumeUsers.muslimPk,
      surface: Size(width, 4000),
      locale: locale,
      textScale: textScale,
    );
    expect(
      tester.takeException(),
      isNull,
      reason: '$width ${locale.languageCode} x$textScale overflowed',
    );

    final Finder cards = find.byType(LumeLiveRow);
    expect(cards, findsWidgets, reason: 'no live cards at $width');
    final double wanted = column(width);
    for (final Element e in cards.evaluate()) {
      final Size size = (e.renderObject! as RenderBox).size;
      expect(
        size.width,
        lessThanOrEqualTo(wanted + 0.5),
        reason:
            'a live card is ${size.width} in a $wanted column at $width '
            '(${locale.languageCode}, x$textScale)',
      );
      expect(
        size.width,
        greaterThanOrEqualTo(wanted - 0.5),
        reason: 'a live card should fill its column, not sit inside it',
      );
    }
  }

  group('a live card fits its column', () {
    for (final double w in widths) {
      testWidgets('at $w', (WidgetTester tester) async {
        await check(tester, w);
      });
    }
  });

  group('and still fits it', () {
    testWidgets('reading right to left', (WidgetTester tester) async {
      for (final double w in <double>[359, 390, 700, 1100]) {
        await check(tester, w, locale: const Locale('ur'));
        await check(tester, w, locale: const Locale('ar'));
      }
    });

    testWidgets('at 200 per cent text', (WidgetTester tester) async {
      for (final double w in <double>[359, 390, 700, 1100]) {
        await check(tester, w, textScale: 2.0);
      }
    });

    testWidgets('at 200 per cent text, right to left', (
      WidgetTester tester,
    ) async {
      await check(tester, 359, locale: const Locale('ur'), textScale: 2.0);
      await check(tester, 390, locale: const Locale('ar'), textScale: 2.0);
    });
  });

  group('and keeps the reference geometry while it does', () {
    testWidgets('70 tall, 20 in from the edge, at the reference cell', (
      WidgetTester tester,
    ) async {
      await pumpHome(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      final Rect r = tester.getRect(find.byType(LumeLiveRow).first);
      // `.livecard { padding: 14px 15px }` with a 40-point disc inside it.
      expect(r.height, closeTo(70, 1));
      expect(r.left, closeTo(20, 0.5));
      expect(r.width, closeTo(350, 0.5));
    });
  });
}
