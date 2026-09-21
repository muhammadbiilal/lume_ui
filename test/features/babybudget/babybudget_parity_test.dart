/// Baby Budget against the running reference, value by value: for each
/// of the eleven cells the browser measured
/// (`tool_babybudget_*.json`), the header, the summary's headline figure
/// and caption, the ring, every donut slice and its share, the six bars
/// and their labels, and every planned row in "Coming up" and "One-off
/// purchases".
///
/// The reference is a static poster over one USD fixture, so the figures
/// it prints are not a reader's. Where it cannot hold together, this
/// names the difference rather than hiding it in a tolerance (D-B20):
///
/// * its donut reads 38 + 25 + 22 + 16 = 101%. The same four amounts,
///   shared out by largest remainder over minor units, read 37 + 25 +
///   22 + 16 = 100 (defect 2, correction 5);
/// * its "82% of plan" is the constant `ratio: 0.82` over a plan that
///   does not exist. Here it is Rs 90,600 against a plan of Rs 110,500,
///   which the reader entered (defect 1);
/// * its months are the hard-coded English strings Apr…Sep whatever the
///   language; here they are the six months ending with the reader's
///   own, in their language (defect 3);
/// * its "Coming up" prints weekday names off the device clock —
///   "Sunday", "Monday" — so the same poster says something different
///   tomorrow. Here each row carries the stored date (defect 6);
/// * every string in it is English under Urdu and Arabic (defect 13);
/// * outside Pakistan it converts the one fixture into the market's
///   currency and rounds it twice. A budget has one currency, the one
///   the reader chose, and the market never converts it (defect 16).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/babybudget/domain/babybudget_book.dart';
import 'package:lume/features/babybudget/domain/babybudget_model.dart';
import 'package:lume/features/babybudget/presentation/babybudget_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import 'babybudget_screen_harness.dart';

/// The spaces and bidi marks the browser's own text carries.
String n(String s) => s
    .replaceAll(String.fromCharCode(0x00a0), ' ')
    .replaceAll(String.fromCharCode(0x202f), ' ')
    .replaceAll(
      RegExp(
        '[${String.fromCharCode(0x2066)}-${String.fromCharCode(0x2069)}'
        '${String.fromCharCode(0x200e)}${String.fromCharCode(0x200f)}]',
      ),
      '',
    );

String digits(String s) => s.replaceAll(RegExp('[^0-9]'), '');

/// One measured cell.
@immutable
class _Cell {
  const _Cell(this.file, this.size, this.theme, this.locale, this.state);

  final String file;
  final Size size;
  final ThemeMode theme;
  final Locale locale;
  final String state;

  /// Whether the reference is showing Pakistan's own figures, which are
  /// the ones this reproduces to the rupee.
  bool get pk => state == 'default_pk';
}

void main() {
  setUpAll(loadLumeFonts);

  const List<_Cell> cells = <_Cell>[
    _Cell(
      'default_pk_390x844_light_en',
      Size(390, 844),
      ThemeMode.light,
      Locale('en'),
      'default_pk',
    ),
    _Cell(
      'default_pk_390x844_dark_en',
      Size(390, 844),
      ThemeMode.dark,
      Locale('en'),
      'default_pk',
    ),
    _Cell(
      'default_pk_390x844_light_ur',
      Size(390, 844),
      ThemeMode.light,
      Locale('ur'),
      'default_pk',
    ),
    _Cell(
      'default_pk_390x844_light_ar',
      Size(390, 844),
      ThemeMode.light,
      Locale('ar'),
      'default_pk',
    ),
    _Cell(
      'default_pk_700x900_light_en',
      Size(700, 900),
      ThemeMode.light,
      Locale('en'),
      'default_pk',
    ),
    _Cell(
      'default_pk_1100x900_light_en',
      Size(1100, 900),
      ThemeMode.light,
      Locale('en'),
      'default_pk',
    ),
    _Cell(
      'default_pk_852x393_light_en',
      Size(852, 393),
      ThemeMode.light,
      Locale('en'),
      'default_pk',
    ),
    _Cell(
      'default_us_390x844_light_en',
      Size(390, 844),
      ThemeMode.light,
      Locale('en'),
      'default_us',
    ),
    _Cell(
      'muslim_gb_390x844_light_en',
      Size(390, 844),
      ThemeMode.light,
      Locale('en'),
      'muslim_gb',
    ),
    _Cell(
      'default_ae_390x844_light_en',
      Size(390, 844),
      ThemeMode.light,
      Locale('en'),
      'default_ae',
    ),
    _Cell(
      'default_jp_390x844_light_en',
      Size(390, 844),
      ThemeMode.light,
      Locale('en'),
      'default_jp',
    ),
  ];

  int compared = 0;
  int corrected = 0;

  for (final _Cell cell in cells) {
    testWidgets('${cell.file}: the reference\'s values, and its order', (
      WidgetTester t,
    ) async {
      final Map<String, Object?> web =
          jsonDecode(
                File(
                  'docs/conversion_archive/measurements/'
                  'tool_babybudget_${cell.file}.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final Map<String, Object?> c =
          web['composition']! as Map<String, Object?>;
      final Map<String, Object?> header = c['header']! as Map<String, Object?>;
      final Map<String, Object?> summary =
          c['summary']! as Map<String, Object?>;
      final Map<String, Object?> bounds =
          web['bounds']! as Map<String, Object?>;
      String sect(String k) =>
          n((bounds[k]! as Map<String, Object?>)['text']! as String);

      final BabyBudgetWorld w = BabyBudgetWorld().parity_();
      final AppLocalizations l = lookupAppLocalizations(cell.locale);

      // ---- the list's own header, as the reference's is the tool's.
      await pumpBabyBudget(
        t,
        w,
        state: cell.state,
        surface: cell.size,
        theme: cell.theme,
        locale: cell.locale,
      );
      final LumeToolbar bar = t.widget<LumeToolbar>(
        find.byType(LumeToolbar).first,
      );
      if (cell.locale.languageCode == 'en') {
        expect(bar.title, header['title']);
      } else {
        // The reference's defect (§16, 13): English under Urdu and Arabic.
        expect(header['title'], 'Baby Budget');
        expect(bar.title, l.featureBabybudget);
        expect(bar.title, isNot(header['title']));
        corrected++;
      }
      compared += 1;

      // Export is the one action the reference offers, and it is real
      // here rather than a stub that says "Saved" (defect 9).
      expect(
        (header['actions']! as List<Object?>)
            .map((Object? a) => (a! as Map<String, Object?>)['id'])
            .toList(),
        <String>['export'],
      );
      compared += 1;

      // ---- the dashboard the reference actually draws.
      await pumpBabyBudget(
        t,
        w,
        state: cell.state,
        surface: cell.size,
        theme: cell.theme,
        locale: cell.locale,
        query: 'budget=${w.budgets['The baby']!.value}',
      );
      final BabyBudgetView v = w.view(w.budgets['The baby']!);
      final LumeSummaryCard card = t.widget<LumeSummaryCard>(
        find.byKey(LumeBabyBudgetTool.summaryKey),
      );

      // 1. The summary. In Pakistan the figure is the reference's own,
      //    Rs 90,600 — here it is what the reader recorded, to the paisa.
      if (cell.pk) {
        expect(digits(n(summary['value']! as String)), '90600');
        expect(digits(card.value), '90600');
        expect(v.thisMonth!.minor, 9060000);
      } else {
        // Elsewhere the reference converts one USD fixture into the
        // market's currency and rounds it twice; a budget keeps the
        // currency the reader chose, whatever market they are in.
        expect(digits(n(summary['value']! as String)), isNot('90600'));
        expect(digits(card.value), '90600');
        expect(v.currency.code, 'PKR');
        corrected++;
      }
      compared += 1;

      // 2. The caption and the ring: 82%, but of a plan that exists.
      expect(n(summary['caption']! as String), '82% of plan');
      expect(v.ratio, 82);
      expect(v.plan!.minor, 11050000);
      final LumeProgressRing ring = t.widget<LumeProgressRing>(
        find.byType(LumeProgressRing).first,
      );
      expect(ring.value, closeTo(0.82, 0.0001));
      expect(digits(ring.centreValue!), '82');
      if (cell.locale.languageCode == 'en') {
        expect(n(card.caption!), '82% of plan');
      }
      corrected++;
      compared += 2;

      // 3. "Where it goes": the same four categories, in the same order,
      //    with the same shares except the one that made 101.
      final String donutText = sect('sect2');
      for (final String name in BabyBudgetWorld.categoryNames) {
        expect(donutText, contains(name));
      }
      final LumeDonut donut = t.widget<LumeDonut>(find.byType(LumeDonut));
      expect(<String>[
        for (final LumeDonutSlice s in donut.slices) s.label,
      ], BabyBudgetWorld.categoryNames);
      final List<int> mine = <int>[
        for (final LumeDonutSlice s in donut.slices)
          int.parse(digits(s.display!)),
      ];
      expect(<int>[38, 25, 22, 16].reduce((int a, int b) => a + b), 101);
      expect(mine, <int>[37, 25, 22, 16]);
      expect(mine.reduce((int a, int b) => a + b), 100);
      // The reference's own legend, read back from the poster.
      expect(donutText, contains('38%'));
      expect(donutText, contains('25%'));
      expect(donutText, contains('22%'));
      expect(donutText, contains('16%'));
      corrected++;
      compared += 5;

      // The hole says the month and the word under it.
      expect(digits(n(donut.centre)), '90600');
      expect(donut.centreSub, l.babyAMonth);
      compared += 2;

      // 4. "Six months": six bars, the reader's own month last.
      final String barsText = sect('sect3');
      final LumeBarChart chart = t.widget<LumeBarChart>(
        find.byType(LumeBarChart),
      );
      expect(chart.values, hasLength(6));
      expect(chart.highlight, 5);
      for (final String month in <String>[
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
      ]) {
        expect(barsText, contains(month));
      }
      if (cell.locale.languageCode == 'en') {
        const List<String> web = <String>[
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
        ];
        for (final (int i, String label) in chart.labels.indexed) {
          expect(label, startsWith(web[i]));
          if (label != web[i]) {
            // The reference's own strings are hard-coded. These come
            // from the locale's data, where British and Pakistani
            // English abbreviate September as "Sept".
            corrected++;
          }
        }
      } else {
        // Hard-coded English under Urdu and Arabic (defect 3).
        expect(chart.labels.join(), isNot(contains('Apr')));
        corrected++;
      }
      // The reference's bars sit at a 3-point floor whatever the value
      // (defect 5, C64); these grow with theirs, and July is the tallest.
      expect(chart.fillOf(3), 100);
      expect(chart.fillOf(0), lessThan(chart.fillOf(3)));
      corrected++;
      compared += 8;

      // 5. "Coming up": the same two purchases, to the rupee — but with
      //    the stored date, not a weekday off the device clock.
      final String comingText = sect('sect4');
      expect(comingText, contains('Nappy restock'));
      expect(comingText, contains('Cot mattress'));
      expect(comingText, contains('Sunday'));
      expect(comingText, contains('Monday'));
      final List<BabySpend> coming = v.comingUp;
      expect(
        <String>[for (final BabySpend s in coming) s.label!],
        <String>['Nappy restock', 'Cot mattress'],
      );
      expect(
        <int>[for (final BabySpend s in coming) s.amount.minor],
        <int>[1840000, 3960000],
      );
      if (cell.pk) {
        expect(digits(comingText), contains('18400'));
      }
      final List<LumeRichRow> comingRows = t
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumeBabyBudgetTool.comingUpKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      expect(comingRows, hasLength(2));
      expect(comingRows.first.title, 'Nappy restock');
      expect(comingRows.last.title, 'Cot mattress');
      for (final LumeRichRow row in comingRows) {
        expect(
          row.meta!.join().toLowerCase(),
          isNot(contains('sunday')),
          reason: 'a stored date, not a weekday off the clock',
        );
      }
      corrected++;
      compared += 6;

      // 6. "One-off purchases": the same two, undated, marked Planned.
      final String oneOffText = sect('sect5');
      expect(oneOffText, contains('Cot and mattress'));
      expect(oneOffText, contains('Pram'));
      expect(oneOffText, contains('Planned'));
      final List<BabySpend> oneOff = v.oneOff;
      expect(
        <int>{for (final BabySpend s in oneOff) s.amount.minor},
        <int>{11900000, 7360000},
      );
      final List<LumeRichRow> oneOffRows = t
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumeBabyBudgetTool.oneOffKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      expect(oneOffRows, hasLength(2));
      expect(<String>[
        for (final LumeRichRow r in oneOffRows) r.title,
      ], containsAll(<String>['Cot and mattress', 'Pram']));
      for (final LumeRichRow row in oneOffRows) {
        expect(row.valueSub, l.babyPlannedBadge);
      }
      compared += 6;

      w.dispose();
    });
  }

  testWidgets('the reference has no total anywhere, and this does', (
    WidgetTester t,
  ) async {
    // Defect 8: the month, the planned purchases and the one-offs never
    // meet. Here they do, per currency and on the card itself.
    final BabyBudgetWorld w = BabyBudgetWorld().parity_();
    final BabyBudgetView v = w.view(w.budgets['The baby']!);
    expect(v.thisMonth!.minor, 9060000);
    expect(v.plannedTotal.minor, 1840000 + 3960000 + 11900000 + 7360000);
    expect(
      v.spentToDate.minor,
      9060000 + 7927500 + 8635313 + 8210625 + 9626250 + 8776875,
    );
    final BabyBudgetSummary s = w.book().summary(babyPkr);
    expect(s.thisMonth!.minor, v.thisMonth!.minor);
    expect(s.spentToDate.minor, v.spentToDate.minor);
    expect(s.plannedTotal.minor, v.plannedTotal.minor);
    w.dispose();
  });

  tearDownAll(() {
    // ignore: avoid_print
    print(
      'baby budget parity: $compared values compared, '
      '$corrected named as corrected',
    );
  });
}
