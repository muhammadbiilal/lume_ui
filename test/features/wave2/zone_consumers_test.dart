/// The IANA foundation's other consumers: Events, Sun & Moon and Weather,
/// held to the zone they are given and to nothing guessed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/time/lume_sky.dart';
import 'package:lume/core/time/lume_solar.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/events/domain/event_family.dart';
import 'package:lume/features/events/presentation/events_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/records/presentation/record_tool.dart';
import 'package:lume/features/sunmoon/presentation/sunmoon_tool.dart';
import 'package:lume/features/weather/data/weather_fixtures.dart' as wx;
import 'package:lume/features/weather/presentation/weather_tool.dart';

import '../../helpers/load_fonts.dart';
import '../tax/tax_harness.dart';
import 'wave2_harness.dart';

final LumeTimeZoneService zones = LumeTimeZoneService.shared;

LumeProfileRepository reader({
  String? zone,
  String country = 'PK',
  String city = 'Islamabad',
}) => LumeMemoryProfileRepository(
  initial: taxReader(country: country, city: city).copyWith(timeZone: zone),
);

List<String> factsOf(WidgetTester t) => <String>[
  for (final LumeFact f
      in t
          .widget<LumeFactCard>(
            find.descendant(
              of: find.byKey(LumeEventsTool.keys.facts),
              matching: find.byType(LumeFactCard),
            ),
          )
          .facts)
    '${f.label}: ${f.value}',
];

void main() {
  setUpAll(loadLumeFonts);

  group('Events', () {
    const LumeRecordKeys k = LumeEventsTool.keys;

    testWidgets('a renamed zone is read, and shown by its CLDR name, '
        'isolated', (WidgetTester t) async {
      await pumpWave2(t, 'events', profile: reader(zone: 'Europe/Kiev'));
      await tapVisible(t, find.byType(LumeRecordRow).first);
      expect(factsOf(t), contains('Timezone: \u2068Ukraine Time\u2069'));
    });

    testWidgets('an event is a date and a wall time; the reader\'s zone '
        'changes how it is placed, never what it says', (WidgetTester t) async {
      for (final (String zone, String name) in <(String, String)>[
        ('Asia/Karachi', 'Pakistan Time'),
        ('America/New_York', 'New York Time'),
      ]) {
        await pumpWave2(t, 'events', profile: reader(zone: zone));
        await tapVisible(t, find.byType(LumeRecordRow).first);
        expect(factsOf(t), containsAll(<String>['Time: 7:00 pm']));
        expect(factsOf(t), contains('Timezone: \u2068$name\u2069'));
      }
      // Nothing about an event stores a zone or an instant.
      expect(
        LumeEventFamily.kSchema.fields.map((f) => f.name),
        isNot(anyElement(anyOf('zone', 'tz', 'timezone', 'instant'))),
      );
    });

    testWidgets('editing keeps the date and time it holds', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository s = wave2Store();
      await pumpWave2(
        t,
        'events',
        store: s,
        profile: reader(zone: 'Europe/Kiev'),
      );
      final LumeRecord before = s.view('events').items.first;
      await tapVisible(t, find.byType(LumeRecordRow).first);
      await tapVisible(t, find.text('Edit event').last);
      await t.enterText(
        find.descendant(
          of: find.byKey(k.field('title')),
          matching: find.byType(EditableText),
        ),
        'Team lunch, moved room',
      );
      await tapVisible(t, find.text('Save changes'));
      await settleSave(t);
      final LumeRecord after = s.get('events', before.id)!;
      expect(after['date'], before['date']);
      expect(after['at'], before['at']);
    });

    testWidgets('a wall time New York skips is kept as written', (
      WidgetTester t,
    ) async {
      // 02:30 on 8 March 2026 does not happen in New York; an event holds a
      // wall time, not an instant, so it reads as it was written.
      final LumeMemoryRecordRepository s = wave2Store()..open('events');
      s.create('events', <String, Object?>{
        'title': 'Night shift',
        'date': '2026-03-08',
        'at': '02:30',
      });
      await pumpWave2(
        t,
        'events',
        store: s,
        profile: reader(zone: 'America/New_York'),
      );
      await tapVisible(t, find.text('Night shift').first);
      expect(factsOf(t), contains('Time: 2:30 am'));
    });

    testWidgets('an unreadable zone: no upcoming list, dates not "in 2 days", '
        'and a new event opens without a guessed day', (WidgetTester t) async {
      await pumpWave2(t, 'events', profile: reader(zone: 'Mars/Olympus_Mons'));
      expect(find.byKey(LumeEventsTool.dayUnknownKey), findsOneWidget);
      expect(find.byKey(LumeEventsTool.upcomingKey), findsNothing);
      final LumeRecordRow first = t.widget(find.byType(LumeRecordRow).first);
      expect(first.subtitle, isNot(contains('in 2 days')));
      await tapVisible(t, find.byKey(k.add));
      await t.enterText(
        find.descendant(
          of: find.byKey(k.field('title')),
          matching: find.byType(EditableText),
        ),
        'Standup',
      );
      await tapVisible(t, find.text('Save event'));
      expect(find.text('Date is required'), findsOneWidget);
    });
  });

  group('Sun & Moon', () {
    const (double, double) islamabad = (33.69, 73.05);

    test('the date is the selected zone\'s, at the city\'s coordinates — two '
        'separate inputs', () {
      // 16:00 UTC is still the 7th in Islamabad and already the 8th in Tokyo.
      final DateTime instant = DateTime.utc(2026, 9, 7, 16);
      final (LumeSkyBoard? b, _) = LumeSkyBoard.at(
        now: instant,
        country: 'PK',
        city: 'Islamabad',
        zone: zones.resolveId('Asia/Tokyo'),
      );
      final LumeSunDay want = LumeSky.sun(
        date: DateTime(2026, 9, 8),
        lat: islamabad.$1,
        lon: islamabad.$2,
        offsetHours: 9,
      );
      expect(b!.sun.sunrise, want.sunrise);
      expect(b.sun.sunset, want.sunset);
      expect(b.minute, 1, reason: '01:00 in Tokyo');
    });

    test('across the date line, one instant is two different days', () {
      final DateTime instant = DateTime.utc(2026, 9, 7, 10);
      double noon(String zone) => LumeSkyBoard.at(
        now: instant,
        country: 'GB',
        city: 'London',
        zone: zones.resolveId(zone),
      ).$1!.sun.noon;
      // London's noon read on +14 and on −11: 25 hours apart on the clock,
      // and on dates two days apart.
      expect(
        noon('Pacific/Kiritimati') - noon('Pacific/Pago_Pago'),
        closeTo(25, 0.1),
      );
    });

    test('across London\'s spring change, the offset follows the instant', () {
      double offsetAt(DateTime t) =>
          zones.resolveId('Europe/London').zone!.offsetAt(t).inMinutes / 60;
      expect(offsetAt(DateTime.utc(2026, 3, 29, 0, 30)), 0);
      expect(offsetAt(DateTime.utc(2026, 3, 29, 1, 30)), 1);
      final LumeSkyBoard after = LumeSkyBoard.at(
        now: DateTime.utc(2026, 3, 29, 12),
        country: 'GB',
        city: 'London',
        zone: zones.resolveId('Europe/London'),
      ).$1!;
      // Sunrise on summer time: after 06:00 on the clock.
      expect(after.sun.sunrise!, greaterThan(6));
    });

    testWidgets('the zone comes from the reader\'s setting, not their '
        'language or country', (WidgetTester t) async {
      Future<List<String?>> times(
        Locale locale,
        LumeProfileRepository p,
      ) async {
        await pumpWave2(t, 'sunmoon', locale: locale, profile: p);
        return <String?>[
          for (final LumeTimelineEntry e
              in t
                  .widget<LumeTimeline>(find.byKey(LumeSunmoonTool.timelineKey))
                  .entries)
            e.time?.replaceAll(RegExp(r'[^0-9:]'), ''),
        ];
      }

      final List<String?> en = await times(const Locale('en'), reader());
      final List<String?> ar = await times(const Locale('ar'), reader());
      expect(ar, en, reason: 'Arabic reads the same clock');
      // A reader in Pakistan who set London's zone sees Islamabad's sun on
      // London's clock: the city decides the sky, the zone the clock.
      final List<String?> london = await times(
        const Locale('en'),
        reader(zone: 'Europe/London'),
      );
      expect(london, isNot(en));
    });

    testWidgets('an unknown place is said, not computed', (
      WidgetTester t,
    ) async {
      await pumpWave2(
        t,
        'sunmoon',
        profile: reader(city: 'Hunza', zone: 'Asia/Karachi'),
      );
      expect(find.byKey(LumeSunmoonTool.missingKey), findsOneWidget);
      expect(find.byKey(LumeSunmoonTool.summaryKey), findsNothing);
    });
  });

  group('Weather', () {
    test('sunrise is worked out for the zone\'s own date', () {
      final DateTime instant = DateTime.utc(2026, 12, 31, 20);
      // 1 January in Tokyo, still 31 December on most devices.
      final wx.LumeSunDay day = LumeWeatherTool.sunDay(
        now: instant,
        country: 'JP',
        city: 'Tokyo',
        zone: LumeTimeZoneService.shared.zoneFor('Asia/Tokyo'),
      );
      final List<LumeSolarTime> want = LumeSolar.prayerTimes(
        date: DateTime(2027, 1, 1),
        lat: 35.68,
        lon: 139.69,
        offsetHours: 9,
      );
      expect(
        day.riseMinute,
        want.firstWhere((LumeSolarTime x) => x.key == 'sunrise').minutes,
      );
    });

    test('an unreadable zone falls to the reference\'s own fallback, never '
        'the device\'s zone', () {
      expect(
        LumeWeatherTool.sunDay(
          now: kFixtureInstant,
          country: 'JP',
          city: 'Tokyo',
          zone: LumeTimeZoneService.shared.zoneFor('Mars/Olympus_Mons'),
        ),
        LumeWeatherTool.fallbackSun,
      );
    });
  });
}
