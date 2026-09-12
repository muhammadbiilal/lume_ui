/// The header's unread marker, in every state it can be handed (D27).
///
/// The reference emits `.iconbtn__badge` as a 7 × 7 disc and then writes the
/// count into it with `overflow: visible`, so the digits render outside the
/// disc in the button's own inherited text, across the bell (C16). The repair
/// was approved as a correctness and accessibility one, on conditions: the
/// marker keeps Lume's position and tone, it is the smallest pill the number
/// fits in, the count is in the accessible name, and a large text scale
/// neither clips it nor buries the control underneath it.
///
/// This is those conditions, one test each.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/widgets/lume/lume_destination.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  // The pill's width is the width of the real digits in the real face.
  setUpAll(loadLumeFonts);

  Future<void> pumpBadge(
    WidgetTester tester, {
    int? count,
    bool dot = false,
    double textScale = 1.0,
    Locale locale = const Locale('en'),
  }) => pumpLume(
    tester,
    Directionality(
      textDirection: locale.languageCode == 'en'
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: LumeHeaderButton(
            icon: LumeIcons.bell,
            semanticLabel: 'Notifications',
            badgeCount: count,
            showDot: dot,
            onTap: () {},
          ),
        ),
      ),
    ),
    textScale: textScale,
    locale: locale,
  );

  /// The accent shape, whatever is inside it. The ring is a shadow, so the
  /// box is the fill and nothing else.
  Finder badge(WidgetTester tester) => find.descendant(
    of: find.byType(LumeHeaderButton),
    matching: find.byWidgetPredicate((Widget w) {
      if (w is! Container) return false;
      final Decoration? d = w.decoration;
      return d is BoxDecoration && d.boxShadow != null && d.color != null;
    }),
  );

  Rect? badgeRect(WidgetTester tester) {
    final Finder f = badge(tester);
    if (f.evaluate().isEmpty) return null;
    return tester.getRect(f.first);
  }

  group('what the badge draws', () {
    testWidgets('nothing at all for zero', (WidgetTester tester) async {
      await pumpBadge(tester, count: 0);
      expect(badgeRect(tester), isNull);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('nothing at all for null', (WidgetTester tester) async {
      await pumpBadge(tester);
      expect(badgeRect(tester), isNull);
    });

    testWidgets('the reference dot when there is no number', (
      WidgetTester tester,
    ) async {
      await pumpBadge(tester, dot: true);
      final Rect r = badgeRect(tester)!;
      expect(r.width, LumeHeaderButton.dotSize);
      expect(r.height, LumeHeaderButton.dotSize);
    });

    testWidgets('one digit as a disc', (WidgetTester tester) async {
      await pumpBadge(tester, count: 3);
      expect(find.text('3'), findsOneWidget);
      final Rect r = badgeRect(tester)!;
      expect(
        r.width,
        r.height,
        reason: 'a single digit is round, not a stubby pill',
      );
    });

    testWidgets('two digits as a pill, wider than it is tall', (
      WidgetTester tester,
    ) async {
      await pumpBadge(tester, count: 13);
      expect(find.text('13'), findsOneWidget);
      final Rect r = badgeRect(tester)!;
      expect(r.width, greaterThan(r.height));
    });

    testWidgets('a hundred and over as 99+', (WidgetTester tester) async {
      await pumpBadge(tester, count: 128);
      expect(find.text('99+'), findsOneWidget);
      expect(LumeHeaderButton.formatCount(100), '99+');
      expect(LumeHeaderButton.formatCount(99), '99');
    });

    testWidgets('each one wider than the last, and none of them clipped', (
      WidgetTester tester,
    ) async {
      double widthFor(int n) => badgeRect(tester)!.width;
      final List<double> widths = <double>[];
      for (final int n in <int>[3, 13, 128]) {
        await pumpBadge(tester, count: n);
        widths.add(widthFor(n));
        // The text is laid out inside the shape, not painted over its edge.
        final Rect shape = badgeRect(tester)!;
        final Rect text = tester.getRect(
          find.descendant(
            of: find.byType(LumeHeaderButton),
            matching: find.byType(Text),
          ),
        );
        expect(
          shape.inflate(0.5).contains(text.topLeft),
          isTrue,
          reason: '$n starts outside its badge',
        );
        expect(
          shape.inflate(0.5).contains(text.bottomRight),
          isTrue,
          reason: '$n ends outside its badge',
        );
      }
      expect(widths[1], greaterThan(widths[0]));
      expect(widths[2], greaterThan(widths[1]));
    });
  });

  group('where the badge sits', () {
    testWidgets('on the reference disc\'s own centre', (
      WidgetTester tester,
    ) async {
      await pumpBadge(tester, dot: true);
      final Rect button = tester.getRect(find.byType(LumeHeaderButton));
      final Rect dot = badgeRect(tester)!;
      // `.iconbtn__badge { top: 7px; right: 8px; width: 7px; height: 7px }`.
      expect(dot.top - button.top, closeTo(7, 0.01));
      expect(button.right - dot.right, closeTo(8, 0.01));

      await pumpBadge(tester, count: 13);
      final Rect pill = badgeRect(tester)!;
      expect(
        pill.center.dy - button.top,
        closeTo(LumeHeaderButton.badgeCentre.dy, 0.01),
      );
      expect(
        button.right - pill.center.dx,
        closeTo(LumeHeaderButton.badgeCentre.dx, 0.01),
      );
    });

    testWidgets('and mirrors to the leading corner in Arabic', (
      WidgetTester tester,
    ) async {
      await pumpBadge(tester, count: 13, locale: const Locale('ar'));
      final Rect button = tester.getRect(find.byType(LumeHeaderButton));
      final Rect pill = badgeRect(tester)!;
      expect(
        pill.center.dx - button.left,
        closeTo(LumeHeaderButton.badgeCentre.dx, 0.01),
      );
    });
  });

  group('the count is information, so it is in the name', () {
    testWidgets('however the marker is drawn', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      for (final double scale in <double>[1.0, 1.3, 2.0]) {
        await pumpBadge(tester, count: 13, textScale: scale);
        expect(
          find.bySemanticsLabel('Notifications, 13'),
          findsOneWidget,
          reason: 'at $scale',
        );
      }

      await pumpBadge(tester, count: 0);
      expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('and the badge itself is never read out twice', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpBadge(tester, count: 13);
      expect(find.bySemanticsLabel('13'), findsNothing);
      handle.dispose();
    });
  });

  group('a large text scale', () {
    testWidgets('never pushes the badge outside the control\'s reach', (
      WidgetTester tester,
    ) async {
      for (final double scale in <double>[1.0, 1.15, 1.3, 1.6, 2.0]) {
        await pumpBadge(tester, count: 128, textScale: scale);
        final Rect button = tester.getRect(find.byType(LumeHeaderButton));
        final Rect r = badgeRect(tester)!;
        // The fill plus its two-point ring, against the control and the four
        // points of overhang the header's 10-point gap can spare.
        final Rect allowed = button.inflate(
          LumeHeaderButton.badgeOverhang + LumeHeaderButton.badgeRing,
        );
        expect(
          r.left >= allowed.left - 0.01 &&
              r.top >= allowed.top - 0.01 &&
              r.right <= allowed.right + 0.01 &&
              r.bottom <= allowed.bottom + 0.01,
          isTrue,
          reason: 'at $scale the badge is $r against $button',
        );
        expect(tester.takeException(), isNull, reason: 'at $scale');
      }
    });

    testWidgets('drops the number for the dot rather than clipping it', (
      WidgetTester tester,
    ) async {
      await pumpBadge(tester, count: 128, textScale: 1.0);
      expect(find.text('99+'), findsOneWidget);

      await pumpBadge(tester, count: 128, textScale: 2.0);
      expect(
        find.text('99+'),
        findsNothing,
        reason: 'a number this size would cover the bell it belongs to',
      );
      final Rect r = badgeRect(tester)!;
      expect(r.width, LumeHeaderButton.dotSize);
    });

    testWidgets('still shows a short count while it fits', (
      WidgetTester tester,
    ) async {
      await pumpBadge(tester, count: 3, textScale: 1.3);
      expect(find.text('3'), findsOneWidget);
    });
  });
}
