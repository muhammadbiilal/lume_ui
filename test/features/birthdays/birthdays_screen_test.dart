/// Birthdays on screen: every figure read back off the records that
/// produced it.
///
/// The reference's own measurement
/// (`measurements/tool_birthdays_default_pk_390x844_light_en.json`) is the
/// comparison. Where it and these differ, the difference is asserted rather
/// than papered over: its "Tracked 4" counts a fourth person who is not a
/// record, and its record list says three on the same screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/time_zone_provider.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/birthdays/presentation/birthdays_tool.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/records/presentation/record_tool.dart';
import 'package:lume/l10n/app_localizations_ar.dart';
import 'package:lume/l10n/app_localizations_en.dart';
import 'package:lume/l10n/app_localizations_ur.dart';

import '../../helpers/load_fonts.dart';
import 'birthdays_harness.dart';

const LumeRecordKeys keys = LumeBirthdaysTool.keys;

/// The names on the record list, in the order it draws them.
List<String> recordTitles(WidgetTester tester) => <String>[
  for (final LumeRecordRow r in tester.widgetList<LumeRecordRow>(
    find.byType(LumeRecordRow),
  ))
    r.title,
];

/// The names in Coming up, in order.
List<String> upcomingTitles(WidgetTester tester) => <String>[
  for (final LumeRichRow r in tester.widgetList<LumeRichRow>(
    inKey(LumeBirthdaysTool.upcomingKey, find.byType(LumeRichRow)),
  ))
    r.title,
];

LumeSummaryCard summary(WidgetTester tester) =>
    tester.widget<LumeSummaryCard>(find.byKey(LumeBirthdaysTool.summaryKey));

LumeRichRow upcomingRow(WidgetTester tester, int at) => tester
    .widgetList<LumeRichRow>(
      inKey(LumeBirthdaysTool.upcomingKey, find.byType(LumeRichRow)),
    )
    .elementAt(at);

void main() {
  setUpAll(loadLumeFonts);

  group('the parity seeds, on the fixture day', () {
    testWidgets('the summary names the soonest, and every figure under it is '
        'counted from the records', (WidgetTester t) async {
      await pumpBirthdays(t);
      final LumeSummaryCard card = summary(t);
      expect(card.kicker, 'Next up');
      expect(card.value, 'Ayesha');
      // Measured: "in 4 days · 11 Sept" — the date here without a weekday,
      // where the record row's carries one.
      expect(card.caption, 'in 4 days · 11 Sept');
      expect(
        card.stats.map((LumeStat s) => '${s.value} ${s.label}'),
        // The reference says "4 Tracked" from a constant, on a screen whose
        // own record list says three. Three is what there is.
        <String>['3 Tracked', '2 This month', '29 Turning'],
      );
      expect(find.text('3 records'), findsOneWidget);
    });

    testWidgets('Coming up is soonest first, and each row carries the date, '
        'the years and the countdown', (WidgetTester t) async {
      await pumpBirthdays(t);
      expect(upcomingTitles(t), <String>['Ayesha', 'Our anniversary', 'Musa']);
      final LumeRichRow first = upcomingRow(t, 0);
      expect(first.logo, 'A');
      expect(first.subtitle, 'Birthday');
      expect(first.meta, <String>['11 Sept', 'turns 29']);
      expect(first.value, 'in 4 days');
      expect(first.chevron, isTrue);
      expect(upcomingRow(t, 2).value, 'in 51 days');
    });

    testWidgets('an anniversary counts years; it does not turn an age', (
      WidgetTester t,
    ) async {
      await pumpBirthdays(t);
      final LumeRichRow anniversary = upcomingRow(t, 1);
      expect(anniversary.subtitle, 'Anniversary');
      expect(anniversary.meta, <String>['25 Sept', '6 years']);
      expect(anniversary.meta, isNot(contains('turns 6')));
    });

    testWidgets('the record list reads the same three, with the same '
        'countdowns', (WidgetTester t) async {
      await pumpBirthdays(t);
      expect(recordTitles(t), <String>['Ayesha', 'Our anniversary', 'Musa']);
      expect(find.text('Birthday · Fri, 11 Sept'), findsOneWidget);
      // One countdown per row and one in Coming up: the same reading twice,
      // never two readings.
      expect(find.text('in 4 days'), findsNWidgets(2));
    });

    testWidgets('a row opens its date, and the detail carries the '
        'reference\'s five facts — with the year it drops', (
      WidgetTester t,
    ) async {
      await pumpBirthdays(t);
      await tapVisible(t, find.byType(LumeRecordRow).first);
      expect(find.byKey(keys.hero), findsOneWidget);
      expect(find.text('Ayesha'), findsWidgets);
      // Measured hero: kicker "Birthday", caption "Friday, 11 September".
      expect(find.text('Friday, 11 September'), findsWidgets);
      final List<String> facts = textsIn(t, find.byKey(keys.facts));
      expect(facts, <String>[
        'Occasion', 'Birthday',
        // The reference shows "Thu, 11 Sept" — the weekday of 1997, and no
        // year at all, beside a Next one that is the same day and month.
        'Date', '11 Sept 1997',
        'Next one', 'Friday, 11 September',
        'Turning', '29',
        'Notes', 'None',
      ]);
    });

    testWidgets('a row in Coming up opens the same record', (
      WidgetTester t,
    ) async {
      await pumpBirthdays(t);
      await tapVisible(
        t,
        inKey(LumeBirthdaysTool.upcomingKey, find.byType(LumeRichRow)).at(2),
      );
      expect(find.byKey(keys.hero), findsOneWidget);
      expect(find.text('Musa'), findsWidgets);
      expect(find.text('Wednesday, 28 October'), findsWidgets);
    });

    testWidgets('an anniversary\'s detail counts years there too', (
      WidgetTester t,
    ) async {
      await pumpBirthdays(t);
      await tapVisible(t, find.byType(LumeRecordRow).at(1));
      expect(
        textsIn(t, find.byKey(keys.facts)),
        containsAllInOrder(<String>['Turning', '6 years']),
      );
    });

    testWidgets('the search the list shares narrows Coming up too', (
      WidgetTester t,
    ) async {
      await pumpBirthdays(t);
      await t.enterText(find.byKey(keys.search), 'musa');
      await t.pumpAndSettle();
      expect(upcomingTitles(t), <String>['Musa']);
      // The summary is of the reader's dates, not of the search.
      expect(summary(t).value, 'Ayesha');
      await t.enterText(find.byKey(keys.search), 'zzz');
      await t.pumpAndSettle();
      expect(find.byKey(LumeBirthdaysTool.upcomingKey), findsNothing);
      expect(find.byKey(LumeBirthdaysTool.nothingKey), findsOneWidget);
      // A search that matched none of three is not an empty collection, and
      // is not told it is.
      expect(find.text('Nothing coming up'), findsOneWidget);
      expect(
        find.text('Dates you add appear here, soonest first.'),
        findsNothing,
      );
    });
  });

  group('adding, saving and deleting', () {
    testWidgets('the add action opens the form the reference measures, and '
        'the date is required', (WidgetTester t) async {
      await pumpBirthdays(t);
      await tapVisible(t, find.byKey(LumeBirthdaysTool.fabKey));
      expect(find.byKey(keys.form), findsOneWidget);
      // Measured: Name, Occasion (Birthday/Anniversary), Date, Notes
      // (Optional); the button "Save date".
      expect(
        textsIn(t, find.byKey(keys.form)),
        containsAllInOrder(<String>[
          'Name',
          'Occasion',
          'Birthday',
          'Date',
          'Notes',
        ]),
      );
      expect(find.text('Whose day is it?'), findsOneWidget);
      await tapVisible(t, find.text('Save date'));
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Date is required'), findsOneWidget);
    });

    testWidgets('the toolbar Add opens the same form', (WidgetTester t) async {
      await pumpBirthdays(t);
      await tapVisible(t, find.byKey(keys.add));
      expect(find.byKey(keys.form), findsOneWidget);
    });

    testWidgets('a saved date appears, sorts into place and is counted', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = birthdaysStore();
      await pumpBirthdays(t, store: store);
      await tapVisible(t, find.byKey(LumeBirthdaysTool.fabKey));
      await t.enterText(
        find.descendant(
          of: find.byKey(keys.field('name')),
          matching: find.byType(EditableText),
        ),
        'Zoya',
      );
      await t.pumpAndSettle();
      // The picker opens on the fixture day, September 2026.
      await tapVisible(t, find.byKey(keys.field('date')));
      await tapVisible(
        t,
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('15'),
        ),
      );
      await tapVisible(t, find.text('OK'));
      await tapVisible(t, find.text('Save date'));
      await settleSave(t);
      // The host opens what was just saved; the list is one Back away.
      expect(find.text('Tuesday, 15 September'), findsWidgets);
      await tapVisible(t, find.byType(LumeBackButton));

      final LumeRecord saved = store
          .view('birthdays')
          .items
          .firstWhere((LumeRecord r) => r['name'] == 'Zoya');
      expect(saved['date'], '2026-09-15');
      expect(saved['kind'], 'birthday');
      expect(saved.seeded, isFalse);

      // 8 days out: after Ayesha's 4 and before the anniversary's 18.
      expect(upcomingTitles(t), <String>[
        'Ayesha',
        'Zoya',
        'Our anniversary',
        'Musa',
      ]);
      expect(summary(t).stats.map((LumeStat s) => s.value), <String>[
        '4',
        '3',
        '29',
      ]);
      // Born this year, so there is no age to announce and none is.
      expect(upcomingRow(t, 1).meta, <String>['15 Sept']);
    });

    testWidgets('a deleted date leaves both the list and Coming up', (
      WidgetTester t,
    ) async {
      await pumpBirthdays(t);
      await tapVisible(t, find.byType(LumeRecordRow).first);
      await tapVisible(t, find.text('Delete date'));
      await tapVisible(t, find.text('Delete date').last);
      expect(recordTitles(t), isNot(contains('Ayesha')));
      expect(upcomingTitles(t), <String>['Our anniversary', 'Musa']);
      expect(summary(t).value, 'Our anniversary');
      expect(
        summary(t).stats.map((LumeStat s) => '${s.value} ${s.label}'),
        <String>['2 Tracked', '1 This month', '6 years Turning'],
      );
    });
  });

  group('the states the reference cannot reach', () {
    testWidgets('a build that is not the parity one opens empty: the nothing '
        'state, and no card of noughts', (WidgetTester t) async {
      await pumpBirthdays(t, store: birthdaysStore(parity: false));
      expect(find.byKey(LumeBirthdaysTool.nothingKey), findsOneWidget);
      expect(find.text('Nothing coming up'), findsOneWidget);
      expect(find.byKey(LumeBirthdaysTool.summaryKey), findsNothing);
      expect(find.byKey(LumeBirthdaysTool.upcomingKey), findsNothing);
      // Nothing anywhere on the screen is a nought presented as a reading.
      for (final String digit in <String>[
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
      ]) {
        expect(find.text(digit), findsNothing, reason: 'a bare "$digit"');
      }
      expect(find.text('Next up'), findsNothing);
      expect(find.text('Tracked'), findsNothing);
      // The record list says its own piece, and the add action still works.
      expect(find.text('No dates saved'), findsOneWidget);
      expect(find.byKey(LumeBirthdaysTool.fabKey), findsOneWidget);
    });

    testWidgets('a date whose stored day cannot be read is listed, not '
        'counted, and breaks nothing', (WidgetTester t) async {
      final LumeMemoryRecordRepository store = birthdaysStore(parity: false)
        ..open('birthdays');
      store.create('birthdays', <String, Object?>{
        'name': 'Broken',
        'kind': 'birthday',
        'date': 'not a day',
      });
      store.create('birthdays', <String, Object?>{
        'name': 'Hana',
        'kind': 'birthday',
        'date': '1990-09-20',
      });
      await pumpBirthdays(t, store: store);
      expect(t.takeException(), isNull);
      expect(recordTitles(t), containsAll(<String>['Broken', 'Hana']));
      expect(upcomingTitles(t), <String>['Hana']);
      expect(summary(t).stats.map((LumeStat s) => s.value), <String>[
        '1',
        '1',
        '36',
      ]);
      // Its row still reads, with no countdown to give.
      await tapVisible(t, find.text('Broken'));
      expect(
        textsIn(t, find.byKey(keys.facts)),
        containsAllInOrder(<String>['Date', '—', 'Next one', '—']),
      );
    });

    testWidgets('with no reader\'s day, nothing that counts days is drawn', (
      WidgetTester t,
    ) async {
      await pumpBirthdays(
        t,
        overrides: <Override>[
          timeZoneServiceProvider.overrideWithValue(
            LumeTimeZoneService.detached(),
          ),
        ],
      );
      expect(find.byKey(LumeBirthdaysTool.dayUnknownKey), findsOneWidget);
      expect(find.byKey(LumeBirthdaysTool.summaryKey), findsNothing);
      expect(find.byKey(LumeBirthdaysTool.upcomingKey), findsNothing);
      expect(find.byKey(LumeBirthdaysTool.nothingKey), findsNothing);
      // The records are still listed, on the day they store rather than on
      // some other zone's.
      expect(recordTitles(t), hasLength(3));
      expect(find.text('Birthday · 11 Sept 1997'), findsOneWidget);
      expect(find.text('in 4 days'), findsNothing);
    });

    testWidgets('and the detail says the same', (WidgetTester t) async {
      await pumpBirthdays(
        t,
        overrides: <Override>[
          timeZoneServiceProvider.overrideWithValue(
            LumeTimeZoneService.detached(),
          ),
        ],
      );
      await tapVisible(t, find.byType(LumeRecordRow).first);
      expect(
        textsIn(t, find.byKey(keys.facts)),
        containsAllInOrder(<String>[
          'Date',
          '11 Sept 1997',
          'Next one',
          '—',
          'Turning',
          '—',
        ]),
      );
    });
  });

  group('language, direction and scale', () {
    for (final (Locale locale, String upcoming, String tracked, String add)
        in <(Locale, String, String, String)>[
          (const Locale('ur'), 'آنے والے', 'محفوظ', 'تاریخ شامل کریں'),
          (const Locale('ar'), 'قادم', 'محفوظة', 'أضف تاريخًا'),
        ]) {
      testWidgets('${locale.languageCode}: the words are translated and the '
          'page is right to left', (WidgetTester t) async {
        await pumpBirthdays(t, locale: locale);
        expect(find.text(upcoming), findsOneWidget);
        expect(summary(t).stats.first.label, tracked);
        expect(
          tester2Direction(t, find.byKey(LumeBirthdaysTool.summaryKey)),
          TextDirection.rtl,
        );
        // `i18n/tools.js:957-960` falls back to English; nothing here does.
        expect(find.text('Coming up'), findsNothing);
        expect(find.text('Tracked'), findsNothing);
        expect(tester2Fab(t).label, add);
        expect(t.takeException(), isNull);
      });
    }

    test('every string the screen draws is translated in all three', () {
      for (final dynamic l in <dynamic>[
        AppLocalizationsEn(),
        AppLocalizationsUr(),
        AppLocalizationsAr(),
      ]) {
        for (final String s in <String>[
          l.birthdaysNext as String,
          l.birthdaysTracked as String,
          l.birthdaysThisMonth as String,
          l.birthdaysTurning as String,
          l.birthdaysUpcoming as String,
          l.birthdaysBirthday as String,
          l.birthdaysAnniversary as String,
          l.birthdaysAdd as String,
          l.birthdaysNothingTitle as String,
          l.birthdaysNothingText as String,
          l.recBirthdaysNoun as String,
          l.recBirthdaysNounPlural as String,
          l.recBirthdaysPh as String,
          l.recFieldOccasion as String,
          l.recNextOne as String,
          l.recTurning as String,
          l.recSeedOurAnniversary as String,
          l.birthdaysTurns(3) as String,
          l.birthdaysYears(3) as String,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      }
      expect(
        AppLocalizationsUr().birthdaysUpcoming,
        isNot(AppLocalizationsEn().birthdaysUpcoming),
      );
      expect(
        AppLocalizationsAr().birthdaysUpcoming,
        isNot(AppLocalizationsEn().birthdaysUpcoming),
      );
    });

    for (final (String name, Size surface) in <(String, Size)>[
      ('the phone', const Size(390, 844)),
      ('landscape', const Size(852, 393)),
      ('wide, where a detail sits beside the list', const Size(1100, 900)),
    ]) {
      testWidgets('$name draws without overflow', (WidgetTester t) async {
        await pumpBirthdays(t, surface: surface);
        expect(t.takeException(), isNull);
        await tapVisible(t, find.byType(LumeRecordRow).first);
        expect(find.byKey(keys.hero), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }

    for (final Locale locale in <Locale>[
      const Locale('en'),
      const Locale('ur'),
      const Locale('ar'),
    ]) {
      testWidgets('at 200 % text scale (${locale.languageCode}) nothing '
          'overflows', (WidgetTester t) async {
        await pumpBirthdays(
          t,
          locale: locale,
          textScale: 2,
          surface: const Size(390, 12000),
        );
        expect(t.takeException(), isNull);
        expect(find.byKey(LumeBirthdaysTool.summaryKey), findsOneWidget);
        expect(find.byKey(LumeBirthdaysTool.upcomingKey), findsOneWidget);
      });
    }
  });

  group('reachable and labelled', () {
    testWidgets('the add action, every row and the chevrons carry names a '
        'screen reader can read', (WidgetTester t) async {
      final SemanticsHandle handle = t.ensureSemantics();
      await pumpBirthdays(t);
      expect(find.bySemanticsLabel('Add date'), findsWidgets);
      expect(find.bySemanticsLabel('Add a date'), findsOneWidget);
      // A Coming up row is announced as what it says.
      expect(
        find.bySemanticsLabel(RegExp(r'^Ayesha, Birthday, in 4 days$')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}

/// The direction the subtree under [of] resolved to.
TextDirection tester2Direction(WidgetTester tester, Finder of) =>
    Directionality.of(tester.element(of));

/// The floating action, whichever locale drew it.
LumeFab tester2Fab(WidgetTester tester) =>
    tester.widget<LumeFab>(find.byKey(LumeBirthdaysTool.fabKey));
