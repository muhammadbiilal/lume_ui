/// Installments against the running reference, value by value: for each of
/// the seven cells the browser measured (the `measurements` JSON of
/// `tool_installments_default_pk`), the header, the summary's headline figure, and
/// every plan row's item and merchant, in the reference's order. The
/// figures the reference gets wrong are held to what their rows add to,
/// and named (C94).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/installments/presentation/installments_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import 'installments_screen_harness.dart';

String n(String s) => s
    .replaceAll('\u00a0', ' ')
    .replaceAll('\u202f', ' ')
    .replaceAll(RegExp('[\u2066-\u2069\u200e\u200f]'), '');

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

  for (final (String name, Size size, ThemeMode theme, Locale locale)
      in cells) {
    testWidgets('$name: the reference\'s values, and its order', (
      WidgetTester t,
    ) async {
      final Map<String, Object?> web =
          jsonDecode(
                File(
                  'docs/conversion_archive/measurements/'
                  'tool_installments_default_pk_$name.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final Map<String, Object?> c =
          web['composition']! as Map<String, Object?>;
      final Map<String, Object?> header = c['header']! as Map<String, Object?>;
      final Map<String, Object?> summary =
          c['summary']! as Map<String, Object?>;
      final List<Object?> rows = c['rows']! as List<Object?>;

      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w, surface: size, theme: theme, locale: locale);
      // The reference's default order: payments left, ascending.
      final String label = lookupAppLocalizations(locale).instSortLeft;
      for (int i = 0; i < 2; i++) {
        final Finder f = find.descendant(
          of: find.byKey(LumeInstallmentsTool.sortKey),
          matching: find.text(label),
        );
        await t.ensureVisible(f);
        await t.pumpAndSettle();
        await t.tap(f);
        await t.pumpAndSettle();
      }

      // Header: the tool's name and its archetype line.
      final LumeToolbar bar = t.widget<LumeToolbar>(find.byType(LumeToolbar));
      final AppLocalizations l = lookupAppLocalizations(locale);
      if (locale.languageCode == 'en') {
        expect(bar.title, header['title']);
        expect(bar.subtitle, header['sub']);
      } else {
        // The reference's defect (§38, 12): English under Urdu and Arabic.
        // Lume says it in the reader's language.
        expect(header['title'], 'Installments');
        expect(bar.title, l.featureInstallments);
        expect(bar.title, isNot(header['title']));
      }
      compared += 2;

      // The headline figure: what is due this month is what the reference
      // shows as its monthly commitment — both Rs 58,000.
      final LumeSummaryCard card = t.widget<LumeSummaryCard>(
        find.byKey(LumeInstallmentsTool.summaryKey),
      );
      // Arabic writes the symbol after the figure; the reference writes every
      // language in English order. The amount itself must be the same.
      String digits(String x) => x.replaceAll(RegExp('[^0-9]'), '');
      expect(digits(card.value), digits(summary['value']! as String));
      if (locale.languageCode != 'ar') {
        expect(n(card.value), n(summary['value']! as String));
      }
      compared += 1;

      // Every row: item and merchant, in the reference's order.
      final List<LumeRichRow> mine = t
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumeInstallmentsTool.plansKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      expect(mine, hasLength(rows.length));
      for (int i = 0; i < rows.length; i++) {
        final Map<String, Object?> r = rows[i]! as Map<String, Object?>;
        expect(mine[i].title, r['title'], reason: '$name row $i');
        expect(mine[i].subtitle, r['sub'], reason: '$name row $i');
        compared += 2;
      }

      // Where the reference is wrong, the figure is what the rows add to.
      final List<Object?> stats = summary['stats']! as List<Object?>;
      final String webRemaining = n(
        (stats[0]! as Map<String, Object?>)['value']! as String,
      );
      final String mineRemaining = n(card.stats.first.value);
      if (locale.languageCode == 'en') {
        expect(webRemaining, 'Rs 427,000');
        expect(mineRemaining, 'Rs 427,300');
        compared += 1;
      }
      w.dispose();
    });
  }

  // The Arabic figure is Arabic's own (C95): the symbol after the digits,
  // opened with a right-to-left mark — not the reference's English order.
  // The digits are the same and so is the currency; in a sentence the
  // amount is isolated, and a screen reader hears what the page shows.
  group('the Arabic amount', () {
    testWidgets('placement: the symbol after the figure in Arabic, before '
        'it in English and Urdu', (WidgetTester t) async {
      for (final (Locale locale, bool after) in <(Locale, bool)>[
        (const Locale('ar'), true),
        (const Locale('en'), false),
        (const Locale('ur'), false),
      ]) {
        final InstallmentsWorld w = InstallmentsWorld().reference();
        await pumpInstallments(t, w, locale: locale);
        final String v = t
            .widget<LumeSummaryCard>(
              find.byKey(LumeInstallmentsTool.summaryKey),
            )
            .value;
        final int digits = v.indexOf('58');
        final int symbol = v.indexOf('Rs');
        expect(digits, isNot(-1), reason: '$locale');
        expect(symbol, isNot(-1), reason: '$locale: the currency is named');
        expect(symbol > digits, after, reason: '$locale: $v');
        if (after) expect(v.startsWith('\u200f'), isTrue);
        // The exact figure: 58,000 in minor units' whole part, nothing else.
        expect(v.replaceAll(RegExp('[^0-9]'), ''), '58000');
        w.dispose();
      }
    });

    testWidgets('in a sentence the amount is isolated, and it is heard as '
        'shown', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(
        t,
        w,
        locale: const Locale('ar'),
        query: 'plan=${w.plans['Laptop']!.value}',
      );
      final Finder pay = find.byKey(LumeInstallmentsTool.payKey);
      await t.ensureVisible(pay);
      await t.pumpAndSettle();
      await t.tap(pay);
      await t.pumpAndSettle();
      final Text sentence = t
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (Text x) =>
                (x.data ?? '').contains('26,900') &&
                (x.data ?? '').contains('\u2068'),
          );
      final String text = sentence.data!;
      final int open = text.indexOf('\u2068');
      final int close = text.indexOf('\u2069');
      expect(open, isNot(-1));
      expect(close, greaterThan(open));
      expect(text.substring(open, close), contains('26,900.00'));
      expect(text.substring(open, close), contains('Rs'));
      // A screen reader reads the same sentence, amount included.
      expect(find.bySemanticsLabel(RegExp(r'26,900\.00')), findsWidgets);
      h.dispose();
      w.dispose();
    });
  });

  tearDownAll(() {
    // ignore: avoid_print
    print('installments parity: $compared values compared');
  });
}
