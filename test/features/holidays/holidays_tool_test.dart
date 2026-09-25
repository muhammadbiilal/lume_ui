/// Public Holidays on screen: opened directly for a reader ([pumpLume]),
/// not through the real router.
///
/// Unlike most converted tools, this pumps [LumeHolidaysTool] directly
/// rather than through `LumeRoutes.tool(...)`: this wave lands alongside many
/// other tools built in parallel, and the shared `tool_registry.dart` this
/// repository routes through is out of scope for this change — it is wired
/// up in the integration pass that follows (the same approach Prize Bonds'
/// and Qibla's own tests take, `prizebonds_tool_test.dart`,
/// `qibla_tool_test.dart`). The screen itself is exercised exactly as the
/// router would host it, with the same provider overrides and the same
/// clock.
///
/// The literal English strings this file asserts against
/// (`holidaysNoteTitle`, `holidaysNoteText`, and the rest of the new
/// `holidays*` keys) are exactly what the tool report hands to whoever adds
/// them to `app_en.arb` — a mismatch there is a mismatch here too.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/holidays/data/holidays_fixtures.dart';
import 'package:lume/features/holidays/presentation/holidays_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature _feature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeHolidaysTool.id,
);

Future<void> pumpHolidays(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3000),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeHolidaysTool(
      request: LumeToolRequest(feature: _feature, user: user, branch: 'tools'),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[
      startupControllerProvider.overrideWithValue(gate),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == label,
  ),
);

List<LumeRichRow> rowsOf(WidgetTester tester) => tester
    .widgetList<LumeRichRow>(
      find.descendant(
        of: find.byKey(LumeHolidaysTool.listKey),
        matching: find.byType(LumeRichRow),
      ),
    )
    .toList();

// A Pakistani reader's date tag resolves to `LumeFormatting.worldEnglish`
// ('en_IN'), not bare 'en' — CLDR's world-English order is day-before-month
// ("9 Nov"), not the American "Nov 9" (`lume_format.dart`'s `dateLocale`).
String medium(int month, int day) => intl.DateFormat.MMMd(
  LumeFormatting.worldEnglish,
).format(DateTime(2026, month, day));

void main() {
  group('the pure "next" computation (no year on the fixture, so no year '
      'assumed)', () {
    test('carries a passed holiday forward a year, picks the nearest', () {
      // Today is 7 September; the reference's own `list[0]` for Pakistan is
      // Iqbal Day (9 Nov) regardless of the date, which is coincidentally
      // also nearest today. Kashmir Day (5 Feb) has already passed this year
      // and must roll to next February, not win by being "first" in table
      // order.
      final (LumeHoliday next, DateTime at) = LumeHolidaysTool.next(
        LumeHolidaysFixtures.holidaysFor('PK'),
        DateTime(2026, 9, 7),
      );
      expect(next.name, LumeHolidayName.iqbalDay);
      expect(at, DateTime(2026, 11, 9));
    });

    test('the fallback table\'s nearest holiday from 7 September is '
        'Christmas, not New Year\'s (table order isn\'t date order)', () {
      final (LumeHoliday next, DateTime at) = LumeHolidaysTool.next(
        LumeHolidaysFixtures.fallback,
        DateTime(2026, 9, 7),
      );
      expect(next.name, LumeHolidayName.christmasDay);
      expect(at, DateTime(2026, 12, 25));
    });
  });

  group('a Pakistani reader', () {
    testWidgets('sees all six of Pakistan\'s real national holidays', (
      WidgetTester tester,
    ) async {
      await pumpHolidays(
        tester,
        user: const LumeUserContext(country: 'PK', city: 'Islamabad'),
      );

      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeHolidaysTool.summaryKey),
      );
      expect(summary.value, 'Iqbal Day');
      expect(summary.caption, '${medium(11, 9)} · National');
      expect(summary.stats.single.value, '6');

      final List<LumeRichRow> rows = rowsOf(tester);
      expect(rows, hasLength(6));
      expect(rows.map((LumeRichRow r) => r.title), <String>[
        'Iqbal Day',
        'Quaid-e-Azam Day',
        'Kashmir Day',
        'Pakistan Day',
        'Labour Day',
        'Independence Day',
      ]);
      expect(rows.every((LumeRichRow r) => r.subtitle == 'National'), isTrue);
      expect(rows.first.value, medium(11, 9));
      expect(find.byKey(LumeHolidaysTool.emptyKey), findsNothing);
    });
  });

  group('a reader in a country with no table of its own', () {
    testWidgets('sees the reference\'s three-holiday global fallback, not '
        'an empty screen or an invented country table', (
      WidgetTester tester,
    ) async {
      await pumpHolidays(
        tester,
        user: const LumeUserContext(country: 'FR', city: 'Paris'),
      );

      final List<LumeRichRow> rows = rowsOf(tester);
      expect(rows, hasLength(3));
      expect(rows.map((LumeRichRow r) => r.title), <String>[
        'New Year’s Day',
        'Christmas Day',
        'Labour Day',
      ]);
      expect(rows.every((LumeRichRow r) => r.subtitle == 'Public'), isTrue);

      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeHolidaysTool.summaryKey),
      );
      expect(summary.value, 'Christmas Day');
    });
  });

  group('the honesty note', () {
    testWidgets('is genuinely on screen, not just in a tooltip or a11y '
        'label', (WidgetTester tester) async {
      await pumpHolidays(tester);

      final Finder note = find.byKey(LumeHolidaysTool.noteKey);
      expect(note, findsOneWidget);
      final LumeNoteCard card = tester.widget(note);
      expect(card.title, 'Reference dates, not this year’s calendar');
      expect(
        card.text,
        'These are illustrative dates, not drawn from a live calendar, and '
        'movable dates like Eid shift every year. Check an official source '
        'for this year’s actual holidays.',
      );
      // Not just held on the widget — actually painted.
      expect(find.text(card.title), findsOneWidget);
      expect(find.text(card.text!), findsOneWidget);
    });
  });

  group('search and the kind filter', () {
    testWidgets('a search narrows the list to the matching holidays', (
      WidgetTester tester,
    ) async {
      await pumpHolidays(
        tester,
        user: const LumeUserContext(country: 'AE', city: 'Dubai'),
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(LumeHolidaysTool.searchKey),
          matching: find.byType(EditableText),
        ),
        'eid',
      );
      await tester.pumpAndSettle();
      expect(rowsOf(tester).map((LumeRichRow r) => r.title), <String>[
        'Eid al-Fitr',
        'Eid al-Adha',
      ]);
    });

    testWidgets('no match shows the empty state, not a blank list', (
      WidgetTester tester,
    ) async {
      await pumpHolidays(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(LumeHolidaysTool.searchKey),
          matching: find.byType(EditableText),
        ),
        'zzz-no-such-holiday',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeHolidaysTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeHolidaysTool.listKey), findsNothing);
    });

    testWidgets('the kind filter offers All plus every kind on the table', (
      WidgetTester tester,
    ) async {
      await pumpHolidays(
        tester,
        user: const LumeUserContext(country: 'PK', city: 'Islamabad'),
      );
      final List<LumeFilterChip> chips = tester
          .widgetList<LumeFilterChip>(
            find.descendant(
              of: find.byKey(LumeHolidaysTool.filterKey),
              matching: find.byType(LumeFilterChip),
            ),
          )
          .toList();
      expect(chips.map((LumeFilterChip c) => c.label), <String>[
        'All',
        'National',
      ]);
      expect(chips.first.selected, isTrue);
    });
  });

  group('export', () {
    testWidgets('writes the visible rows, not the whole table', (
      WidgetTester tester,
    ) async {
      final LumeRecordingExporter exporter = LumeRecordingExporter();
      await pumpHolidays(
        tester,
        user: const LumeUserContext(country: 'PK', city: 'Islamabad'),
        overrides: <Override>[exporterProvider.overrideWithValue(exporter)],
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(LumeHolidaysTool.searchKey),
          matching: find.byType(EditableText),
        ),
        'iqbal',
      );
      await tester.pumpAndSettle();
      await tester.tap(toolbarAction('Export'));
      await tester.pump();

      final LumeExportFile file = exporter.exported.single;
      expect(file.fileName, 'lume-holidays-2026-09-07.csv');
      expect(file.text, contains('Iqbal Day'));
      expect(file.text, isNot(contains('Quaid-e-Azam Day')));
    });
  });

  group('right to left', () {
    testWidgets('Urdu renders the same holidays, right to left', (
      WidgetTester tester,
    ) async {
      await pumpHolidays(
        tester,
        user: const LumeUserContext(country: 'PK', city: 'Islamabad'),
        locale: const Locale('ur'),
      );
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expect(rowsOf(tester), hasLength(6));
      expect(find.byKey(LumeHolidaysTool.noteKey), findsOneWidget);
    });

    testWidgets('at 200%, without overflow', (WidgetTester tester) async {
      await pumpHolidays(tester, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
