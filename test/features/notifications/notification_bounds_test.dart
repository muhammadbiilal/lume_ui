/// Where the notification centre's parts are, against where the running
/// reference puts them.
///
/// `measure_destinations.mjs --screen notifications --state muslim_pk` opens
/// `#screen-notifications` by its tab id and writes `getBoundingClientRect`
/// for the toolbar, the tabs, the category bar, the list and the parts of its
/// first rows. This opens the same centre through `/home/notifications` and
/// asserts the numbers agree.
///
/// **Positions are the screen's own.** The prototype draws a 28-point
/// simulated status bar above `.screen` (P1) and Flutter has none, so every
/// `y` is measured from the screen's top.
///
/// **A shrink-wrapped text's width is not compared** where the reference's
/// element is a block: `.nrow__text` fills the body column, and a Flutter
/// `Text` is as wide as its longest line. Both start at the same x on the
/// same line box, which is what the row is about.
///
/// The tolerance is one logical pixel, and every difference is collected
/// before failing.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/features/notifications/presentation/notification_centre.dart';
import 'package:lume/features/notifications/presentation/notification_host.dart';
import 'package:lume/features/notifications/presentation/notification_row.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

/// One logical pixel.
const double kTolerance = 1.0;

/// Three, for an element several rows down.
///
/// Chrome keeps each row's fractional line boxes — a 14 px title on 1.3 is
/// 18.19, a 12 px body on 1.45 is 17.39 — and Flutter rounds them to whole
/// points, so each row is about 0.7 shorter and the fifth row starts 2.89
/// higher. That is D20: the content, the line count and the clipping are the
/// same, and the difference is rounding accumulated row by row.
const double kDrift = 3.0;

void main() {
  setUpAll(loadLumeFonts);

  Map<String, dynamic> measured() {
    final File f = File(
      'docs/conversion_archive/measurements/notif_centre_390x844_light_en.json',
    );
    final Map<String, dynamic> j =
        jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    return j['bounds'] as Map<String, dynamic>;
  }

  List<String> compare(
    WidgetTester tester,
    Map<String, dynamic> bounds,
    String name,
    Finder finder, {
    bool checkX = true,
    bool checkWidth = true,
    bool checkHeight = true,
    double tolerance = kTolerance,
  }) {
    final Map<String, dynamic>? b = bounds[name] as Map<String, dynamic>?;
    if (b == null) return <String>['$name was not measured'];
    if (finder.evaluate().isEmpty) return <String>['$name is not on screen'];
    final Rect r = tester.getRect(finder.first);
    final double origin =
        ((bounds['screen'] as Map<String, dynamic>)['y'] as num).toDouble();
    final List<String> out = <String>[];
    void check(String what, double wanted, double got) {
      if ((got - wanted).abs() > tolerance) {
        out.add(
          '$name $what — reference ${wanted.toStringAsFixed(2)}, '
          'Flutter ${got.toStringAsFixed(2)}',
        );
      }
    }

    check('y', (b['y'] as num).toDouble() - origin, r.top);
    if (checkX) check('x', (b['x'] as num).toDouble(), r.left);
    if (checkWidth) check('width', (b['width'] as num).toDouble(), r.width);
    if (checkHeight) {
      check('height', (b['height'] as num).toDouble(), r.height);
    }
    return out;
  }

  Finder sized(double w, double h) => find.byWidgetPredicate(
    (Widget x) =>
        (x is SizedBox && x.width == w && x.height == h) ||
        (x is Container &&
            x.constraints?.maxWidth == w &&
            x.constraints?.maxHeight == h),
  );

  testWidgets('the centre, measured against the reference', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(
      tester,
      initialLocation: '/home/notifications',
      surface: const Size(390, 844),
    );
    await tester.pump(LumeNotificationHost.settle);
    await tester.pumpAndSettle();

    final Map<String, dynamic> b = measured();
    final Finder row = find.byType(LumeNotificationRow).first;
    Finder inRow(Finder f) => find.descendant(of: row, matching: f);

    final List<String> misses = <String>[
      ...compare(
        tester,
        b,
        'toolbar',
        find.byKey(LumeNotificationHost.headerKey),
      ),
      ...compare(tester, b, 'tabs', find.byKey(LumeNotificationCentre.tabsKey)),
      // The category bar is laid out at its chips' 44-point targets, so
      // what is compared is where the first chip is *drawn*, against the
      // group the reference measures: the same top and the same start. The
      // group is two taller than its chips (`padding-bottom: 2px`).
      ...compare(
        tester,
        b,
        'filterbar',
        find
            .descendant(
              of: find.byType(LumeFilterChip).first,
              matching: find.byType(Container),
            )
            .first,
        checkWidth: false,
        checkHeight: false,
      ),
      // The list's top and width are asserted; its height is thirteen rows
      // of D20 and is reported by the rows below instead.
      ...compare(
        tester,
        b,
        'list',
        find.byKey(LumeNotificationCentre.listKey),
        checkHeight: false,
      ),
      ...compare(tester, b, 'row', row),
      // `.nrow__titleline` — as tall as the title's own line; the badge
      // beside it is shorter and does not grow it.
      ...compare(
        tester,
        b,
        'row.titleline',
        find
            .ancestor(
              of: find.text('Time for your medication'),
              matching: find.byType(Row),
            )
            .first,
        checkWidth: false,
      ),
      ...compare(
        tester,
        b,
        'row.badge',
        inRow(find.byType(LumeBadge)),
        checkX: false,
        checkWidth: false,
      ),
      // A row whose body wraps, and its action strip; and the fifth row,
      // so a per-row difference shows as a sum.
      ...compare(tester, b, 'row2', find.byType(LumeNotificationRow).at(1)),
      ...compare(
        tester,
        b,
        'row2.main',
        find
            .descendant(
              of: find.byType(LumeNotificationRow).at(1),
              matching: find.byType(LumePressable),
            )
            .first,
      ),
      ...compare(
        tester,
        b,
        'row5',
        find.byType(LumeNotificationRow).at(4),
        tolerance: kDrift,
      ),
      ...compare(
        tester,
        b,
        'row.icon',
        inRow(
          sized(LumeNotificationRow.iconSize, LumeNotificationRow.iconSize),
        ),
      ),
      ...compare(
        tester,
        b,
        'row.title',
        inRow(find.text('Time for your medication')),
        checkWidth: false,
      ),
      ...compare(
        tester,
        b,
        'row.text',
        inRow(find.text('You have a dose due.')),
        checkWidth: false,
      ),
      ...compare(
        tester,
        b,
        'row.meta',
        inRow(find.text('8 min ago · Health')),
        checkWidth: false,
      ),
      ...compare(
        tester,
        b,
        'row.dot',
        // The dot's drawn box, not its margin: `margin-top: 6px` is outside
        // what the reference measures.
        find
            .descendant(
              of: inRow(
                find.byWidgetPredicate(
                  (Widget x) =>
                      x is Container &&
                      x.margin == const EdgeInsets.only(top: 6),
                ),
              ),
              matching: find.byType(DecoratedBox),
            )
            .first,
      ),
      ...compare(
        tester,
        b,
        'row.dismiss',
        inRow(
          sized(
            LumeNotificationRow.dismissSize,
            LumeNotificationRow.dismissSize,
          ),
        ),
      ),
      // `.nrow__act` is measured on the second row, the first with a verb.
      ...compare(
        tester,
        b,
        'row.act',
        find
            .ancestor(
              of: find.text('View flight'),
              matching: find.byType(Container),
            )
            .first,
        tolerance: kDrift,
      ),
    ];
    expect(misses, isEmpty, reason: misses.join('\n'));
  });
}
