/// Sun & Moon — worked out, never fixture astronomy: against published
/// almanac times and phases, at the poles, and when there is no place or no
/// clock to work it out for.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_sky.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/sunmoon/presentation/sunmoon_tool.dart';
import 'package:lume/features/tools/domain/tool_capability.dart';
import 'package:lume/core/routing/lume_routes.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import 'wave2_harness.dart';

/// Hours of the day as `HH:mm`.
String hm(double? hours) {
  if (hours == null) return '—';
  final (int h, int m) = LumeSky.clock(hours);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Minutes between two `HH:mm`.
int apart(String a, String b) {
  int m(String s) =>
      int.parse(s.substring(0, 2)) * 60 + int.parse(s.substring(3));
  return (m(a) - m(b)).abs();
}

void main() {
  setUpAll(loadLumeFonts);

  group('the sun', () {
    // Expected times from NOAA's solar-calculator algorithm (the
    // higher-precision equation of time and declination series, run
    // independently of Lume's code for this table), sunrise and sunset at
    // 90.833° and civil twilight at 96°. Lume's low-precision position is held
    // to three minutes of them, four for twilight.
    for (final (
          String place,
          DateTime day,
          double lat,
          double lon,
          double off,
          String rise,
          String set,
          String? dawn,
          String? dusk,
        )
        in <
          (
            String,
            DateTime,
            double,
            double,
            double,
            String,
            String,
            String?,
            String?,
          )
        >[
          (
            'Islamabad',
            DateTime(2026, 9, 7),
            33.69,
            73.05,
            5,
            '05:46',
            '18:26',
            '05:21',
            '18:51',
          ),
          (
            'London',
            DateTime(2026, 6, 21),
            51.51,
            -0.13,
            1,
            '04:43',
            '21:22',
            '03:55',
            '22:09',
          ),
          (
            'New York',
            DateTime(2026, 12, 21),
            40.71,
            -74.01,
            -5,
            '07:17',
            '16:32',
            '06:46',
            '17:03',
          ),
          (
            'Sydney',
            DateTime(2026, 12, 21),
            -33.87,
            151.21,
            11,
            '05:41',
            '20:05',
            '05:12',
            '20:34',
          ),
        ]) {
      test('$place on $day: rise $rise, set $set', () {
        final LumeSunDay s = LumeSky.sun(
          date: day,
          lat: lat,
          lon: lon,
          offsetHours: off,
        );
        expect(s.kind, LumeSunKind.normal);
        expect(
          apart(hm(s.sunrise), rise),
          lessThanOrEqualTo(3),
          reason: hm(s.sunrise),
        );
        expect(
          apart(hm(s.sunset), set),
          lessThanOrEqualTo(3),
          reason: hm(s.sunset),
        );
        if (dawn != null) {
          expect(
            apart(hm(s.dawn), dawn),
            lessThanOrEqualTo(4),
            reason: hm(s.dawn),
          );
          expect(
            apart(hm(s.dusk), dusk!),
            lessThanOrEqualTo(4),
            reason: hm(s.dusk),
          );
        }
        // Civil twilight, not an hour either side (C86).
        expect(s.sunrise! - s.dawn!, lessThan(1));
      });
    }

    test('above the polar circles the day says so, and invents no rise', () {
      final LumeSunDay midsummer = LumeSky.sun(
        date: DateTime(2026, 6, 21),
        lat: 78.22,
        lon: 15.65,
        offsetHours: 2,
      );
      expect(midsummer.kind, LumeSunKind.polarDay);
      expect(midsummer.sunrise, isNull);
      expect(midsummer.daylight, 24);

      final LumeSunDay midwinter = LumeSky.sun(
        date: DateTime(2026, 12, 21),
        lat: 78.22,
        lon: 15.65,
        offsetHours: 1,
      );
      expect(midwinter.kind, LumeSunKind.polarNight);
      expect(midwinter.sunrise, isNull);
      expect(midwinter.dawn, isNull, reason: 'never 6° from the horizon');
      expect(midwinter.daylight, 0);

      // Tromsø in December: no sunrise, but a civil twilight around noon.
      final LumeSunDay tromso = LumeSky.sun(
        date: DateTime(2026, 12, 21),
        lat: 69.65,
        lon: 18.96,
        offsetHours: 1,
      );
      expect(tromso.kind, LumeSunKind.polarNight);
      expect(tromso.dawn, isNotNull);
      expect(tromso.dawn!, lessThan(tromso.noon));
      expect(tromso.dusk!, greaterThan(tromso.noon));

      // Trondheim at midsummer: the sun sets, but it never gets dark enough
      // for a civil dusk.
      final LumeSunDay trondheim = LumeSky.sun(
        date: DateTime(2026, 6, 21),
        lat: 63.43,
        lon: 10.39,
        offsetHours: 2,
      );
      expect(trondheim.kind, LumeSunKind.normal);
      expect(trondheim.dawn, isNull);
      expect(trondheim.dusk, isNull);
    });

    test('a minute rounds half up and wraps onto the clock', () {
      expect(LumeSky.clock(5.5), (5, 30));
      expect(LumeSky.clock(23.9999), (0, 0));
      expect(LumeSky.clock(-0.5), (23, 30));
      expect(LumeSky.clock(24.25), (0, 15));
    });
  });

  group('the moon', () {
    // Phases as the almanacs publish them (UTC); a mean month is held to
    // the named phase and a band of illumination.
    for (final (String what, DateTime at, LumeMoonPhase phase, int lo, int hi)
        in <(String, DateTime, LumeMoonPhase, int, int)>[
          (
            'full moon',
            DateTime.utc(2025, 9, 7, 18, 9),
            LumeMoonPhase.full,
            97,
            100,
          ),
          (
            'new moon',
            DateTime.utc(2025, 9, 21, 19, 54),
            LumeMoonPhase.newMoon,
            0,
            3,
          ),
          (
            'first quarter',
            DateTime.utc(2025, 9, 29, 23, 54),
            LumeMoonPhase.firstQuarter,
            40,
            60,
          ),
          (
            'last quarter',
            DateTime.utc(2025, 10, 13, 18, 13),
            LumeMoonPhase.lastQuarter,
            40,
            60,
          ),
          (
            'new moon',
            DateTime.utc(2026, 9, 11, 3, 27),
            LumeMoonPhase.newMoon,
            0,
            3,
          ),
        ]) {
      test('$what at $at', () {
        final LumeMoon m = LumeSky.moon(at);
        expect(m.phase, phase);
        expect(m.lit, inInclusiveRange(lo, hi));
      });
    }

    test('before the known new moon the age still wraps into the month', () {
      final LumeMoon m = LumeSky.moon(DateTime.utc(1999, 12, 30));
      expect(m.age, inInclusiveRange(0, LumeSky.synodic));
    });
  });

  group('the tool', () {
    const LumeSunDay day = LumeSunDay(
      kind: LumeSunKind.normal,
      noon: 12,
      sunrise: 6,
      sunset: 18,
      dawn: 5.5,
      dusk: 18.5,
    );

    test('past stops are done, the next is now, and dawn is not done before '
        'it happens (C86)', () {
      expect(
        LumeSunmoonTool.states(LumeSunmoonTool.events(day), 4),
        <LumeTimelineState>[
          LumeTimelineState.now,
          LumeTimelineState.upcoming,
          LumeTimelineState.upcoming,
          LumeTimelineState.upcoming,
          LumeTimelineState.upcoming,
        ],
      );
      expect(
        LumeSunmoonTool.states(LumeSunmoonTool.events(day), 16.7),
        <LumeTimelineState>[
          LumeTimelineState.done,
          LumeTimelineState.done,
          LumeTimelineState.done,
          LumeTimelineState.now,
          LumeTimelineState.upcoming,
        ],
      );
    });

    test('the day length agrees with the times the caption shows', () {
      expect(LumeSunmoonTool.daylightMinutes(day), 12 * 60);
      expect(
        LumeSunmoonTool.daylightMinutes(
          const LumeSunDay(kind: LumeSunKind.polarDay, noon: 12),
        ),
        24 * 60,
      );
    });

    testWidgets('for the reader\'s city: daylight, the moon and the day', (
      WidgetTester tester,
    ) async {
      await pumpWave2(tester, 'sunmoon');
      final LumeSummaryCard s = tester.widget(
        find.byKey(LumeSunmoonTool.summaryKey),
      );
      expect(s.kicker, 'Daylight');
      expect(s.value, matches(RegExp(r'^\d+h \d\dm$')));
      expect(
        s.caption,
        matches(RegExp(r'^\d+:\d\d\s?[ap]m to \d+:\d\d\s?[ap]m$')),
      );
      expect(s.stats.map((LumeStat x) => x.label), <String>[
        'Moon phase',
        'Illuminated',
        'Solar noon',
      ]);
      final LumeTimeline t = tester.widget(
        find.byKey(LumeSunmoonTool.timelineKey),
      );
      expect(t.entries.map((LumeTimelineEntry e) => e.title), <String>[
        'Dawn',
        'Sunrise',
        'Solar noon',
        'Sunset',
        'Dusk',
      ]);
      expect(t.entries.first.subtitle, 'First light');
      expect(find.text('Calculated for your location'), findsOneWidget);
    });

    testWidgets('a zone this build cannot read is said, and nothing is shown '
        'on a guessed clock', (WidgetTester tester) async {
      // Tokyo is read now (the IANA database); an identifier the database
      // does not hold is not.
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.tool(LumeRoutes.tools, 'sunmoon'),
        profile: LumeMemoryProfileRepository(
          initial: taxReader().copyWith(timeZone: 'Mars/Olympus_Mons'),
        ),
        surface: const Size(390, 2000),
      );
      await tester.pumpAndSettle();
      final LumeToolState s = tester.widget(
        find.byKey(LumeSunmoonTool.missingKey),
      );
      expect(s.title, 'No clock for \u2068Mars/Olympus_Mons\u2069');
      expect(find.byKey(LumeSunmoonTool.summaryKey), findsNothing);
    });

    testWidgets('a city with no coordinates is said, not guessed from the '
        'country, language or zone', (WidgetTester tester) async {
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.tool(LumeRoutes.tools, 'sunmoon'),
        profile: LumeMemoryProfileRepository(
          initial: taxReader(region: 'Gilgit-Baltistan', city: 'Hunza'),
        ),
        surface: const Size(390, 2000),
      );
      await tester.pumpAndSettle();
      final LumeToolState s = tester.widget(
        find.byKey(LumeSunmoonTool.missingKey),
      );
      expect(s.title, 'No position for Hunza');
      expect(find.byKey(LumeSunmoonTool.timelineKey), findsNothing);
    });

    testWidgets('in Arabic it reads right to left, in Arabic', (
      WidgetTester tester,
    ) async {
      await pumpWave2(tester, 'sunmoon', locale: const Locale('ar'));
      final LumeSummaryCard s = tester.widget(
        find.byKey(LumeSunmoonTool.summaryKey),
      );
      expect(s.kicker, 'ساعات النهار');
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeSunmoonTool.timelineKey)),
        ),
        TextDirection.rtl,
      );
    });

    test('computed, not sample: the source says it is calculated, and a '
        'release claims no sample it does not have', () {
      final LumeDataCapability c = LumeDataCapability.fixture('sunmoon');
      expect(c.computedHere, isTrue);
      expect(c.isSample, isFalse);
      expect(c.isLive, isFalse);
    });

    test('no wall clock, no position service', () {
      for (final String path in <String>[
        'lib/core/time/lume_sky.dart',
        'lib/features/sunmoon/presentation/sunmoon_tool.dart',
      ]) {
        final String code = File(path)
            .readAsLinesSync()
            .where((String l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        for (final String banned in <String>[
          'DateTime.now',
          'geolocator',
          'location',
          'Geolocation',
        ]) {
          expect(code, isNot(contains(banned)), reason: '$path: $banned');
        }
      }
    });
  });
}
