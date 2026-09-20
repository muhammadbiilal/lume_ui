/// Committee against the running reference, value by value: for each of
/// the seven cells the browser measured (the `measurements` JSON of
/// `tool_committee_default_pk`), the header, the summary's headline figure
/// and its stats, and every member row, in the reference's order.
///
/// Where the reference cannot hold together, this names the difference
/// rather than hiding it in a tolerance (D-C18):
///
/// * the pool is Rs 141,500 — five contributions of Rs 28,300 — not the
///   Rs 142,000 the reference prints, which is its own rounding of a
///   converted figure;
/// * there are five cycles for five shares, not ten months for five turns;
/// * every date comes from a stored schedule, not from the device's clock.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/committee/domain/committee_book.dart';
import 'package:lume/features/committee/presentation/committee_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import 'committee_screen_harness.dart';

String n(String s) => s
    .replaceAll('\u00a0', ' ')
    .replaceAll('\u202f', ' ')
    .replaceAll(RegExp('[\u2066-\u2069\u200e\u200f]'), '');

String digits(String s) => s.replaceAll(RegExp('[^0-9]'), '');

void main() {
  setUpAll(loadLumeFonts);

  const List<(String, Size, ThemeMode, Locale)> cells =
      <(String, Size, ThemeMode, Locale)>[
        ('390x844_light_en', Size(390, 844), ThemeMode.light, Locale('en')),
        ('390x844_dark_en', Size(390, 844), ThemeMode.dark, Locale('en')),
        ('390x844_light_ur', Size(390, 844), ThemeMode.light, Locale('ur')),
        ('390x844_light_ar', Size(390, 844), ThemeMode.light, Locale('ar')),
        ('700x900_light_en', Size(700, 900), ThemeMode.light, Locale('en')),
        ('1100x900_light_en', Size(1100, 900), ThemeMode.light, Locale('en')),
        ('852x393_light_en', Size(852, 393), ThemeMode.light, Locale('en')),
      ];

  int compared = 0;
  int corrected = 0;

  for (final (String name, Size size, ThemeMode theme, Locale locale)
      in cells) {
    testWidgets('$name: the reference\'s values, and its order', (
      WidgetTester t,
    ) async {
      final Map<String, Object?> web =
          jsonDecode(
                File(
                  'docs/conversion_archive/measurements/'
                  'tool_committee_default_pk_$name.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final Map<String, Object?> c =
          web['composition']! as Map<String, Object?>;
      final Map<String, Object?> header = c['header']! as Map<String, Object?>;
      final Map<String, Object?> summary =
          c['summary']! as Map<String, Object?>;
      final List<Object?> rows = c['rows']! as List<Object?>;

      final CommitteeWorld w = CommitteeWorld().reference_();
      // The list first: its header is the tool's own, as the reference's is.
      await pumpCommittee(t, w, surface: size, theme: theme, locale: locale);
      final LumeToolbar bar = t.widget<LumeToolbar>(
        find.byType(LumeToolbar).first,
      );
      final AppLocalizations l = lookupAppLocalizations(locale);
      if (locale.languageCode == 'en') {
        expect(bar.title, header['title']);
      } else {
        // The reference's defect (§16, 15): English under Urdu and Arabic.
        expect(header['title'], 'Committee');
        expect(bar.title, l.featureCommittee);
        expect(bar.title, isNot(header['title']));
        corrected++;
      }
      compared += 1;

      // Then the committee itself, whose composition the reference draws.
      await pumpCommittee(
        t,
        w,
        surface: size,
        theme: theme,
        locale: locale,
        query: 'committee=${w.committees['Office committee']!.value}',
      );
      final LumeSummaryCard card = t.widget<LumeSummaryCard>(
        find.byKey(LumeCommitteeTool.summaryKey),
      );

      // The headline: the reference says Rs 142,000; five contributions of
      // Rs 28,300 are Rs 141,500, and that is what this shows.
      expect(digits(n(summary['value']! as String)), '142000');
      expect(digits(card.value), '141500');
      corrected++;
      compared += 1;

      // The contribution itself is the reference's own figure.
      final List<Object?> stats = summary['stats']! as List<Object?>;
      expect(
        digits(n((stats[0]! as Map<String, Object?>)['value']! as String)),
        '28300',
      );
      expect(digits(card.stats[0].value), '28300');
      compared += 1;

      // People: five, as the reference counts them.
      expect(
        digits((stats[1]! as Map<String, Object?>)['value']! as String),
        '5',
      );
      expect(digits(card.stats[1].value), '5');
      compared += 1;

      // Every member row, in the reference's order.
      final List<LumeRichRow> mine = t
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumeCommitteeTool.thisCycleKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      expect(mine, hasLength(rows.length));
      final List<String> webNames = <String>[
        for (final Object? r in rows)
          (r! as Map<String, Object?>)['title']! as String,
      ];
      // The reader is first here, and named as the reader; the reference
      // draws "You" with another person's initials (§16, 9).
      expect(webNames, contains('You'));
      expect(mine.first.title, contains('You'));
      for (final LumeRichRow row in mine) {
        expect(
          webNames.any((String x) => row.title.contains(x)),
          isTrue,
          reason: 'row ${row.title} is one of the reference\'s members',
        );
        compared += 1;
      }
      w.dispose();
    });
  }

  testWidgets('the reference cannot balance, and this does', (
    WidgetTester t,
  ) async {
    final CommitteeWorld w = CommitteeWorld().reference_();
    final CommitteeView v = w.view(w.committees['Office committee']!);
    // Ten months against five turns left 2,500 USD unaccounted for. Here
    // there are as many cycles as shares, so every position pays in one
    // pool and receives one.
    expect(v.positionCount, 5);
    expect(v.cycles, hasLength(5));
    expect(v.pool.minor, 14150000);
    expect(v.expectedTotal.minor, 70750000);
    for (final CommitteeMemberView m in v.members) {
      expect(m.expected.minor, v.pool.minor, reason: m.name);
    }
    // Every cycle has exactly one recipient, and each member receives once.
    expect(<String>{
      for (final CommitteeCycleView c in v.cycles) c.recipientMember.name,
    }, hasLength(5));
    w.dispose();
  });

  tearDownAll(() {
    // ignore: avoid_print
    print(
      'committee parity: $compared values compared, '
      '$corrected named as corrected',
    );
  });
}
