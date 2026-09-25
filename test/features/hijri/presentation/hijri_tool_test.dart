/// Islamic Calendar on screen: opened directly for a reader ([pumpLume]), not
/// through the real router — the same approach Qibla's own harness takes
/// (`qibla_tool_test.dart`), for the same reason: `tool_registry.dart` does
/// not yet name `hijri`, and wiring it is the integration pass this rollout
/// wave's tools land ahead of. The tool is exercised exactly as the router
/// would host it, over the same fixture clock every other test in the suite
/// reads by default (`kFixtureInstant`, 7 September 2026 — 23 Rabi‘
/// al-Awwal 1448, the same day `lume_hijri_test.dart` anchors the base
/// conversion to).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lume/core/time/lume_hijri.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/hijri/domain/hijri_events.dart';
import 'package:lume/features/hijri/presentation/hijri_tool.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _hijriFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeHijriTool.id,
);

Future<void> pumpHijri(
  WidgetTester tester, {
  // Faith-gated (`faith: true`): the frame blocks the body for a non-Muslim
  // reader before this widget ever draws, exactly as Qibla and Tasbih do —
  // Muslim + Pakistan + Islamabad is the brief's own first baseline (§18).
  LumeUserContext user = const LumeUserContext(islamic: true),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 4200),
  double textScale = 1,
  LumeToolSession? session,
  DateTime? now,
}) async {
  await pumpLume(
    tester,
    LumeHijriTool(
      request: LumeToolRequest(
        feature: _hijriFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    now: now,
    overrides: <Override>[
      toolSessionProvider.overrideWithValue(session ?? LumeToolSession()),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the catalogue entry', () {
    test('is faith-gated and computed, and needs no city — a calendar '
        'conversion is not location-aware, unlike Prayer or Qibla', () {
      expect(_hijriFeature.faith, isTrue);
      expect(_hijriFeature.requiresCity, isFalse);
    });
  });

  group('a Muslim reader', () {
    testWidgets('sees today\'s real Hijri date, worked out for the fixture '
        'day — the same 23 Rabi‘ al-Awwal 1448 lume_hijri_test.dart anchors '
        'the base conversion to', (WidgetTester tester) async {
      await pumpHijri(tester);

      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeHijriTool.summaryKey),
      );
      expect(summary.value, contains('23'));
      expect(summary.value, contains('Rabi'));
      // `f.integer()` groups a four-digit year the same as any other
      // integer this codebase formats — never a bare '1448'.
      expect(summary.unit, contains('1,448'));
    });

    testWidgets('draws the honesty notice, the grid, the events, the '
        'converter and the month list — never an "Islamic features are '
        'disabled" placeholder', (WidgetTester tester) async {
      await pumpHijri(tester);

      expect(find.byKey(LumeHijriTool.noteKey), findsOneWidget);
      expect(find.byKey(LumeHijriTool.gridKey), findsOneWidget);
      expect(find.byKey(LumeHijriTool.eventsKey), findsOneWidget);
      expect(find.byKey(LumeHijriTool.convertKey), findsOneWidget);
      expect(find.byKey(LumeHijriTool.monthsKey), findsOneWidget);

      final LumeNotice note = tester.widget(find.byKey(LumeHijriTool.noteKey));
      expect(note.title, isNotEmpty);
      expect(note.text, isNotEmpty);
    });

    testWidgets('the month grid is this Gregorian month, with the fixture '
        'day\'s own known Hijri day (17) on its first cell', (
      WidgetTester tester,
    ) async {
      await pumpHijri(tester);
      // `lume_hijri_test.dart`: `LumeHijriDate.of(DateTime(2026, 9, 1)).day`
      // is 17 — the grid's own first cell must read the same.
      expect(find.text('17'), findsWidgets);
    });

    testWidgets('lists exactly the six computed transitions, never the '
        'reference\'s five fixed rows for one specific year', (
      WidgetTester tester,
    ) async {
      await pumpHijri(tester);
      final LumeRows events = tester.widget(
        find.byKey(LumeHijriTool.eventsKey),
      );
      expect(events.children, hasLength(LumeHijriEventId.values.length));
    });

    testWidgets('the converter opens on today\'s date and shows the same '
        'Hijri date the summary card does', (WidgetTester tester) async {
      await pumpHijri(tester);
      final LumeToolField result = tester.widget(
        find.byKey(LumeHijriTool.convertResultKey),
      );
      expect(result.value, contains('23'));
      expect(result.value, contains('1,448'));
      expect(result.enabled, isFalse);
    });

    testWidgets('a date already chosen in session converts correctly on '
        'first paint — not just from today', (WidgetTester tester) async {
      final LumeToolSession session = LumeToolSession();
      session.write(LumeHijriTool.id, 'greg', '2026-09-01');
      await pumpHijri(tester, session: session);

      final LumeHijriDate expected = LumeHijriDate.of(DateTime(2026, 9, 1));
      final LumeToolField result = tester.widget(
        find.byKey(LumeHijriTool.convertResultKey),
      );
      expect(result.value, contains('${expected.day}'));
      // `f.integer()` groups the year the same as everywhere else this
      // codebase formats one — never a bare digit run.
      expect(
        result.value,
        contains(intl.NumberFormat.decimalPattern('en').format(expected.year)),
      );
    });

    testWidgets('the twelve Hijri months are all listed, in order', (
      WidgetTester tester,
    ) async {
      await pumpHijri(tester);
      final LumeRows months = tester.widget(
        find.byKey(LumeHijriTool.monthsKey),
      );
      expect(months.children, hasLength(12));
    });
  });

  group('a non-Muslim reader', () {
    testWidgets('never sees the calendar — the frame itself blocks a '
        'faith-gated tool\'s body, defence in depth over the catalogue gate '
        'alone (§64)', (WidgetTester tester) async {
      await pumpHijri(tester, user: const LumeUserContext(islamic: false));
      expect(find.byKey(LumeHijriTool.summaryKey), findsNothing);
      expect(find.byKey(LumeHijriTool.gridKey), findsNothing);
      expect(find.byKey(LumeHijriTool.eventsKey), findsNothing);
    });
  });

  group('RTL and translated locales', () {
    testWidgets('renders right-to-left and without exception in Arabic', (
      WidgetTester tester,
    ) async {
      await pumpHijri(tester, locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
      expect(find.byKey(LumeHijriTool.summaryKey), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byKey(LumeHijriTool.summaryKey))),
        TextDirection.rtl,
      );
    });

    testWidgets('renders right-to-left and without exception in Urdu', (
      WidgetTester tester,
    ) async {
      await pumpHijri(tester, locale: const Locale('ur'));
      expect(tester.takeException(), isNull);
      expect(find.byKey(LumeHijriTool.summaryKey), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byKey(LumeHijriTool.summaryKey))),
        TextDirection.rtl,
      );
    });
  });

  group('accessibility', () {
    testWidgets('at twice the text size, nothing overflows and every '
        'section is still reachable', (WidgetTester tester) async {
      await pumpHijri(tester, textScale: 2, surface: const Size(390, 9000));
      expect(tester.takeException(), isNull);
      expect(find.byKey(LumeHijriTool.summaryKey), findsOneWidget);
      expect(find.byKey(LumeHijriTool.convertKey), findsOneWidget);
      expect(find.byKey(LumeHijriTool.monthsKey), findsOneWidget);
    });
  });
}
