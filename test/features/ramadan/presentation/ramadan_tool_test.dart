/// Ramadan: the countdown before the month is real Hijri-calendar math, not
/// the reference's flat 29-day guess; the day inside it reads real Fajr and
/// Maghrib, not a fixed offset from sunrise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/time/lume_hijri.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/time/lume_solar.dart';
import 'package:lume/core/time/lume_zone.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/ramadan/presentation/ramadan_tool.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/domain/tool_capability.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _ramadanFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeRamadanTool.id,
);

/// Islamabad's own zone: fixed rather than routed through device/profile
/// resolution, since this pumps [LumeRamadanTool] directly ([pumpLume]) —
/// `tool_registry.dart` is out of scope for this wave, exactly as Qibla's own
/// harness explains (`qibla_tool_test.dart`).
LumeZoneResolution _karachi() =>
    LumeZoneResolution.fixed(LumeTimeZoneService.shared.zoneFor('Asia/Karachi')!);

Future<void> pumpRamadan(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(islamic: true),
  DateTime? now,
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3200),
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeRamadanTool(
      request: LumeToolRequest(
        feature: _ramadanFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    now: now,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the catalogue entry', () {
    test('is faith-gated, computed, and points at the tools this dashboard '
        'actually opens', () {
      expect(_ramadanFeature.faith, isTrue);
      expect(_ramadanFeature.related, containsAll(<String>['fasting', 'quran']));
    });
  });

  group('LumeRamadanReading — before Ramadan', () {
    // 7 Sept 2026 is 23 Rabi' al-Awwal 1448 (verified independently against
    // the same tabular conversion this reading uses) — six months before
    // Ramadan, not in it.
    final DateTime before = DateTime(2026, 9, 7, 16, 41, 32);

    test('counts real calendar days, not the reference\'s flat 29-day-a-'
        'month guess (off by 26 days on this date)', () {
      final (LumeRamadanReading? r, _) = LumeRamadanReading.at(
        now: before,
        country: 'PK',
        city: 'Islamabad',
        zone: _karachi(),
      );
      expect(r, isNotNull);
      expect(r!.active, isFalse);
      expect(r.hijri, const LumeHijriDate(1448, 3, 23));
      // The reference's own `monthsAway * 29 + (30 - day)` gives 181 here;
      // walking the real tabular calendar one day at a time gives 155.
      expect(r.daysUntil, 155);
      final DateTime start = DateTime(
        before.year,
        before.month,
        before.day,
      ).add(Duration(days: r.daysUntil!));
      expect(LumeHijriDate.of(start), const LumeHijriDate(1448, 9, 1));
    });

    test('names the Hijri year Ramadan actually falls in this cycle — the '
        'reference\'s own formula names next year\'s for most of the '
        'months leading up to it', () {
      final (LumeRamadanReading? r, _) = LumeRamadanReading.at(
        now: before,
        country: 'PK',
        city: 'Islamabad',
        zone: _karachi(),
      );
      expect(r!.ramadanHijriYear, 1448);
    });

    test('after Ramadan has passed for the cycle, the next one is next '
        'year', () {
      // A date the tabular calendar puts in Shawwal 1448 (month 10), after
      // Ramadan 1448 has already run.
      final DateTime after = DateTime(2027, 4, 20, 12);
      final LumeHijriDate h = LumeHijriDate.of(after);
      expect(h.month, greaterThan(9));
      final (LumeRamadanReading? r, _) = LumeRamadanReading.at(
        now: after,
        country: 'PK',
        city: 'Islamabad',
        zone: _karachi(),
      );
      expect(r!.ramadanHijriYear, h.year + 1);
    });

    test('a city with no coordinates is said, not guessed from the country', () {
      final (LumeRamadanReading? r, LumeRamadanMissing? missing) =
          LumeRamadanReading.at(
            now: before,
            country: 'PK',
            city: 'Nowhereistan',
            zone: _karachi(),
          );
      expect(r, isNull);
      expect(missing, LumeRamadanMissing.city);
    });

    test('a zone this build cannot read is said, not guessed', () {
      final LumeZoneResolution unresolved = LumeTimeZoneService.shared.reader(
        explicit: 'Mars/Olympus_Mons',
        country: 'PK',
        city: 'Islamabad',
      );
      expect(unresolved.zone, isNull);
      final (LumeRamadanReading? r, LumeRamadanMissing? missing) =
          LumeRamadanReading.at(
            now: before,
            country: 'PK',
            city: 'Islamabad',
            zone: unresolved,
          );
      expect(r, isNull);
      expect(missing, LumeRamadanMissing.zone);
    });
  });

  group('LumeRamadanReading — inside Ramadan', () {
    // 9 Feb 2027 is 1 Ramadan 1448 by the same tabular conversion.
    final DateTime day1 = DateTime(2027, 2, 9, 5);
    final DateTime day11 = DateTime(2027, 2, 19, 16, 41, 32);

    test('day 1: the count of what is left includes today', () {
      final (LumeRamadanReading? r, _) = LumeRamadanReading.at(
        now: day1,
        country: 'PK',
        city: 'Islamabad',
        zone: _karachi(),
      );
      expect(r!.active, isTrue);
      expect(r.dayOfRamadan, 1);
      // This cycle's Ramadan runs 30 days on the same tabular calendar.
      expect(r.daysRemaining, 30);
    });

    test('day 11: Suhoor and Iftar are the real Fajr and Maghrib for the '
        'city, not the reference\'s `sunrise - 1:18, minute 42` shortcut', () {
      final (LumeRamadanReading? r, _) = LumeRamadanReading.at(
        now: day11,
        country: 'PK',
        city: 'Islamabad',
        zone: _karachi(),
      );
      expect(r!.active, isTrue);
      expect(r.dayOfRamadan, 11);
      expect(r.daysRemaining, 20);

      final LumeZone karachi = LumeTimeZoneService.shared.zoneFor(
        'Asia/Karachi',
      )!;
      final DateTime local = karachi.wallClockAt(day11);
      final List<LumeSolarTime> expected = LumeSolar.prayerTimes(
        date: local,
        lat: 33.69,
        lon: 73.05,
        offsetHours: karachi.offsetAt(day11).inMinutes / 60,
      );
      final LumeSolarTime expectedFajr = expected.firstWhere(
        (LumeSolarTime t) => t.key == 'fajr',
      );
      final LumeSolarTime expectedMaghrib = expected.firstWhere(
        (LumeSolarTime t) => t.key == 'maghrib',
      );
      expect(r.fajr.hour, expectedFajr.hour);
      expect(r.fajr.minute, expectedFajr.minute);
      expect(r.maghrib.hour, expectedMaghrib.hour);
      expect(r.maghrib.minute, expectedMaghrib.minute);

      // Never the reference's own formula: sunrise's hour minus one, minute
      // fixed at 42.
      expect(r.fajr.minute, isNot(42));
    });

    test('the countdown to Iftar is minutes to the real Maghrib, never '
        'negative', () {
      final (LumeRamadanReading? r, _) = LumeRamadanReading.at(
        now: day11,
        country: 'PK',
        city: 'Islamabad',
        zone: _karachi(),
      );
      expect(r!.iftarInMinutes, greaterThanOrEqualTo(0));
      expect(r.iftarInMinutes, lessThan(24 * 60));
    });
  });

  group('LumeRamadanTool.states', () {
    test('past stops are done, the first still to come is now, the rest '
        'wait', () {
      expect(
        LumeRamadanTool.states(<double>[10, 20, 30], 15),
        <LumeTimelineState>[
          LumeTimelineState.done,
          LumeTimelineState.now,
          LumeTimelineState.upcoming,
        ],
      );
      expect(
        LumeRamadanTool.states(<double>[10, 20, 30], 5),
        <LumeTimelineState>[
          LumeTimelineState.now,
          LumeTimelineState.upcoming,
          LumeTimelineState.upcoming,
        ],
      );
      expect(
        LumeRamadanTool.states(<double>[10, 20, 30], 35),
        <LumeTimelineState>[
          LumeTimelineState.done,
          LumeTimelineState.done,
          LumeTimelineState.done,
        ],
      );
    });
  });

  group('the tool, before Ramadan (2026-09-07, the app\'s own fixture day)', () {
    testWidgets('a countdown in real days, and links to Fasting, Qur\'an and '
        'Zakat — never Hadith, Dua or Tasbih', (WidgetTester tester) async {
      await pumpRamadan(tester);

      expect(find.byKey(LumeRamadanTool.missingKey), findsNothing);
      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeRamadanTool.summaryKey),
      );
      expect(summary.value, '155');
      expect(summary.stats, hasLength(2));

      expect(find.byKey(LumeRamadanTool.prepareKey), findsOneWidget);
      final LumeRows prepare = tester.widget(
        find.byKey(LumeRamadanTool.prepareKey),
      );
      expect(prepare.children, hasLength(3));

      expect(find.byKey(LumeRamadanTool.timelineKey), findsNothing);
      expect(find.byKey(LumeRamadanTool.noteKey), findsOneWidget);
    });

    testWidgets('a non-Muslim reader never sees it — the frame itself '
        'blocks a faith-gated tool\'s body (§64)', (WidgetTester tester) async {
      await pumpRamadan(tester, user: const LumeUserContext(islamic: false));
      expect(find.byKey(LumeRamadanTool.summaryKey), findsNothing);
      expect(find.byKey(LumeRamadanTool.prepareKey), findsNothing);
      expect(find.byKey(LumeRamadanTool.missingKey), findsNothing);
    });

    testWidgets('a city with no coordinates says so plainly', (
      WidgetTester tester,
    ) async {
      await pumpRamadan(
        tester,
        user: const LumeUserContext(
          country: 'PK',
          city: 'Chitral',
          islamic: true,
        ),
      );
      expect(find.byKey(LumeRamadanTool.missingKey), findsOneWidget);
      expect(find.byKey(LumeRamadanTool.summaryKey), findsNothing);
    });

    testWidgets('at 200% text scale, nothing overflows', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        LumeRamadanTool(
          request: LumeToolRequest(
            feature: _ramadanFeature,
            user: const LumeUserContext(islamic: true),
            branch: 'tools',
          ),
        ),
        textScale: 2,
        surface: const Size(390, 4200),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('in Arabic it reads right to left', (
      WidgetTester tester,
    ) async {
      await pumpRamadan(tester, locale: const Locale('ar'));
      expect(find.byKey(LumeRamadanTool.summaryKey), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeRamadanTool.summaryKey)),
        ),
        TextDirection.rtl,
      );
    });

    testWidgets('in Urdu at 200% text scale, still no overflow', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        LumeRamadanTool(
          request: LumeToolRequest(
            feature: _ramadanFeature,
            user: const LumeUserContext(islamic: true),
            branch: 'tools',
          ),
        ),
        locale: const Locale('ur'),
        textScale: 2,
        surface: const Size(390, 4400),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('the tool, inside Ramadan (day 11, 1448)', () {
    testWidgets('the day\'s timeline: Suhoor, five prayers, Iftar — no '
        'fabricated Taraweeh clock time', (WidgetTester tester) async {
      await pumpRamadan(tester, now: DateTime(2027, 2, 19, 16, 41, 32));

      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeRamadanTool.summaryKey),
      );
      expect(summary.stats, hasLength(3));

      expect(find.byKey(LumeRamadanTool.prepareKey), findsNothing);
      final LumeTimeline timeline = tester.widget(
        find.byKey(LumeRamadanTool.timelineKey),
      );
      // Suhoor ends, Fajr, Dhuhr, Asr, Maghrib, Iftar, Isha — never a
      // Taraweeh row with a clock time nothing here measured.
      expect(timeline.entries, hasLength(7));
      expect(
        timeline.entries.map((LumeTimelineEntry e) => e.title),
        isNot(contains(contains('Taraweeh'))),
      );
    });

    test('the data capability this dashboard is given: computed, never '
        'sample — landed in the integration pass, `tool_capability.dart`\'s '
        '`computed` set', () {
      final LumeDataCapability c = LumeDataCapability.fixture('ramadan');
      // Every figure this tool shows is worked out here, from
      // LumeHijriDate and LumeSolar, exactly like `sunmoon` and `qibla`
      // already are.
      expect(c.isSample, isFalse);
      expect(c.computedHere, isTrue);
    });
  });
}
