/// What Home shows, and in what order.
///
/// The compositions here were read out of the running prototype by
/// `measure_destinations.mjs` — the hero order, the eight tiles, the live
/// cards, the upcoming rows and the Discover strip, for each of seven users —
/// so these are not assertions about what the code does but about what the
/// design does.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/home/data/home_fixtures.dart';
import 'package:lume/features/home/domain/home_composer.dart';
import 'package:lume/features/home/domain/home_model.dart';
import 'package:lume/features/home/domain/home_content.dart';

import 'destination_harness.dart';

List<String> idsOf(List<LumeFeature> fs) =>
    fs.map((LumeFeature f) => f.id).toList();

void main() {
  group('the hero carousel', () {
    List<String> heroFor(LumeUserContext user) => LumeHomeComposer.hero(
      user: user,
      eligibility: kEligibility,
      todayPath: LumeRoutes.today,
      toolsPath: LumeRoutes.tools,
      trainsPath: LumeRoutes.trains,
    ).map((LumeHeroCard c) => c.id.name).toList();

    test('not Muslim, Pakistan — the prototype keeps four', () {
      expect(heroFor(LumeUsers.defaultPk), <String>[
        'plan',
        'trains',
        'money',
        'tools',
      ]);
    });

    test('Muslim, Pakistan — prayer and reading push tools out', () {
      expect(heroFor(LumeUsers.muslimPk), <String>[
        'prayer',
        'plan',
        'trains',
        'read',
      ]);
    });

    test('Muslim, United Kingdom — no trains', () {
      expect(heroFor(LumeUsers.muslimGb), <String>[
        'prayer',
        'plan',
        'read',
        'money',
      ]);
    });

    test('not Muslim, United States — three, because trains is Pakistani', () {
      expect(heroFor(LumeUsers.defaultUs), <String>['plan', 'money', 'tools']);
    });

    test('with the money switch off, the money slide goes', () {
      expect(heroFor(LumeUsers.prefsOffPk), <String>[
        'plan',
        'trains',
        'tools',
      ]);
    });

    test('never more than four (§26)', () async {
      for (final LumeUserContext u in LumeUsers.all.values) {
        expect(heroFor(u).length, lessThanOrEqualTo(4));
        expect(heroFor(u).length, greaterThanOrEqualTo(2));
      }
    });

    test('an interest lifts the ranking without changing the set', () async {
      final LumeUserContext traveller = LumeUsers.defaultPk.copyWith(
        interests: <String>{...LumeUsers.defaultPk.interests, 'trains'},
      );
      expect(
        LumeHomeComposer.heroScore(
          LumeHeroSlideId.trains,
          traveller,
          kEligibility,
        ),
        78,
      );
      expect(
        LumeHomeComposer.heroScore(
          LumeHeroSlideId.trains,
          LumeUsers.defaultPk,
          kEligibility,
        ),
        74,
      );
    });

    test('the gate on a slide is the gate on what it opens', () async {
      // §63: the prototype marks the slides with `data-faith` and `data-loc`;
      // every one of those restates the gate on the feature the slide opens,
      // so the composer asks the catalogue instead. These are the same answer.
      for (final MapEntry<LumeHeroSlideId, String?> e
          in LumeHomeComposer.heroGate.entries) {
        if (e.value == null) continue;
        for (final LumeUserContext u in LumeUsers.all.values) {
          final bool gateOpen = kEligibility.visibleById(e.value!, u) != null;
          final bool offered =
              LumeHomeComposer.heroScore(e.key, u, kEligibility) > 0;
          expect(offered, gateOpen, reason: '${e.key.name} for ${u.country}');
        }
      }
    });

    test('the ranking is stable across runs', () {
      for (int i = 0; i < 5; i++) {
        expect(heroFor(LumeUsers.muslimPk), heroFor(LumeUsers.muslimPk));
      }
    });
  });

  group('the quick-tool grid', () {
    List<String> gridFor(LumeUserContext user) => idsOf(
      LumeHomeComposer.quickTools(user: user, eligibility: kEligibility),
    );

    test('the default seven interests fill it by round-robin', () {
      expect(gridFor(LumeUsers.defaultPk), <String>[
        'aqi',
        'datecalc',
        'reminders',
        'notes',
        'calculator',
        'tax',
        'news',
        'sunmoon',
      ]);
    });

    test('a faith interest reaches the eighth tile', () {
      expect(gridFor(LumeUsers.muslimPk).last, 'prayer');
    });

    test('favourites come first, and a hidden favourite is skipped', () async {
      // `qibla` is a favourite and is faith-gated off, so it is not a tile —
      // and it does not leave a gap either.
      expect(gridFor(LumeUsers.namedPk), <String>[
        'currency',
        'notes',
        'calculator',
        'weather',
        'aqi',
        'datecalc',
        'reminders',
        'docscan',
      ]);
    });

    test('a switched-off interest\'s tool is replaced, not left blank', () {
      expect(gridFor(LumeUsers.prefsOffPk), hasLength(8));
      expect(gridFor(LumeUsers.prefsOffPk), isNot(contains('news')));
    });

    test('one interest does not drain the grid', () async {
      // The whole reason for the round-robin: without it, a user who chose
      // only "prayer" would get eight Islamic tiles.
      final LumeUserContext oneThing = LumeUsers.muslimPk.copyWith(
        interests: const <String>{'prayer'},
      );
      final List<String> grid = gridFor(oneThing);
      final int faith = grid
          .where((String id) => kEligibility.byId(id)!.faith)
          .length;
      // Four passes, one tool per interest per pass — so a single interest
      // takes at most half the grid and the fallbacks fill the rest. Without
      // the round-robin it would take all eight.
      expect(faith, 4);
      expect(grid, hasLength(8));
      expect(grid.sublist(4), LumeHomeComposer.quickFallback.take(4));
    });

    test('nothing sensitive is ever promoted (§61)', () async {
      for (final LumeUserContext u in LumeUsers.all.values) {
        for (final String id in gridFor(u)) {
          expect(kEligibility.byId(id)!.sensitive, isFalse, reason: id);
        }
      }
    });

    test('nothing hidden ever appears (§64)', () async {
      for (final LumeUserContext u in LumeUsers.all.values) {
        for (final String id in gridFor(u)) {
          expect(kEligibility.visibleById(id, u), isNotNull, reason: id);
        }
      }
    });

    test('with no interests at all it still fills, from the fallbacks', () {
      final List<String> grid = gridFor(LumeUsers.noInterestsPk);
      expect(grid, hasLength(8));
      expect(grid.take(4), LumeHomeComposer.quickFallback.take(4));
    });
  });

  group('quick actions', () {
    test('five, and a sensitive tool is allowed among them (§118)', () {
      final List<LumeQuickAction> a = LumeHomeComposer.quickActions(
        user: LumeUsers.defaultPk,
        eligibility: kEligibility,
      );
      expect(a.map((LumeQuickAction x) => x.featureId), <String>[
        'expenses',
        'todos',
        'qr',
        'notes',
        'water',
      ]);
      // Adding an expense is a task; the pill says so and discloses nothing.
      expect(kEligibility.byId('expenses')!.sensitive, isTrue);
    });
  });

  group('Right now', () {
    Future<List<String>> liveFor(LumeUserContext user, {DateTime? now}) async =>
        LumeHomeComposer.live(
          user: user,
          eligibility: kEligibility,
          content: await _content(user, now ?? kFixtureInstant),
          now: now ?? kFixtureInstant,
        ).map((LumeLiveCard c) => c.featureId).toList();

    test('weather, the market and the bills, in that order', () async {
      expect(await liveFor(LumeUsers.defaultPk), <String>[
        'weather',
        'markets',
        'bills',
      ]);
    });

    test('the money switch takes the market card with it', () async {
      expect(await liveFor(LumeUsers.prefsOffPk), <String>['weather', 'bills']);
    });

    test('a live outage goes to the front', () async {
      // 14:30 is inside the 14:00–16:00 slot.
      final DateTime duringOutage = DateTime(2026, 9, 7, 14, 30);
      expect(
        (await liveFor(LumeUsers.defaultPk, now: duringOutage)).first,
        'loadshed',
      );
    });

    test('and is not there when the power is on', () async {
      expect(await liveFor(LumeUsers.defaultPk), isNot(contains('loadshed')));
    });

    test('never more than three', () async {
      final DateTime duringOutage = DateTime(2026, 9, 7, 14, 30);
      expect(
        await liveFor(LumeUsers.defaultPk, now: duringOutage),
        hasLength(3),
      );
    });

    test(
      'after seven in the evening the weather card is tomorrow\'s',
      () async {
        final List<LumeLiveCard> cards = LumeHomeComposer.live(
          user: LumeUsers.defaultPk,
          eligibility: kEligibility,
          content: await _content(
            LumeUsers.defaultPk,
            DateTime(2026, 9, 7, 20),
          ),
          now: DateTime(2026, 9, 7, 20),
        );
        expect((cards.first as LumeWeatherLive).forTomorrow, isTrue);
      },
    );

    test(
      'before eight, with the market shut, there is no market card',
      () async {
        // Nothing has happened yet, and the previous close is not "right now".
        //
        // Sunday, so the exchange is shut whatever zone the *host* is in. The
        // rule is `open || hour >= 8`, and picking a weekday would have made the
        // test pass only on a machine set to Pakistan — which is the class of
        // bug the market session exists to correct.
        expect(
          await liveFor(LumeUsers.defaultPk, now: DateTime(2026, 9, 6, 7)),
          isNot(contains('markets')),
        );
      },
    );

    test('and from eight it is there even though the market is shut', () async {
      expect(
        await liveFor(LumeUsers.defaultPk, now: DateTime(2026, 9, 6, 9)),
        contains('markets'),
      );
    });
  });

  group('At a glance', () {
    Future<List<String>> glanceFor(LumeUserContext user) async =>
        LumeHomeComposer.glance(
          user: user,
          eligibility: kEligibility,
          content: await _content(user, kFixtureInstant),
          todayPath: LumeRoutes.today,
        ).map((LumeGlanceCard c) => c.runtimeType.toString()).toList();

    test('Pakistan, not Muslim: the pump price and the tasks', () async {
      expect(await glanceFor(LumeUsers.defaultPk), <String>[
        'LumeFuelGlance',
        'LumeTasksGlance',
      ]);
    });

    test('Pakistan, Muslim: the reading card joins them, first', () async {
      expect(await glanceFor(LumeUsers.muslimPk), <String>[
        'LumeReadingGlance',
        'LumeFuelGlance',
        'LumeTasksGlance',
      ]);
    });

    test('United Kingdom, Muslim: no pump price', () async {
      expect(await glanceFor(LumeUsers.muslimGb), <String>[
        'LumeReadingGlance',
        'LumeTasksGlance',
      ]);
    });

    test('United States: the tasks alone', () async {
      expect(await glanceFor(LumeUsers.defaultUs), <String>['LumeTasksGlance']);
    });
  });

  group('Coming up', () {
    Future<List<String>> upcomingFor(LumeUserContext user) async =>
        LumeHomeComposer.upcoming(
          user: user,
          eligibility: kEligibility,
          content: await _content(user, kFixtureInstant),
          now: kFixtureInstant,
        ).map((LumeUpcomingItem i) => i.featureId).toList();

    test('the two bills, the subscription and the birthday', () async {
      expect(await upcomingFor(LumeUsers.defaultPk), <String>[
        'bills',
        'bills',
        'subs',
        'birthdays',
      ]);
    });

    test(
      'the next prayer takes the first row and the birthday drops off',
      () async {
        expect(await upcomingFor(LumeUsers.muslimPk), <String>[
          'prayer',
          'bills',
          'bills',
          'subs',
        ]);
      },
    );

    test('never more than four', () async {
      for (final LumeUserContext u in LumeUsers.all.values) {
        expect((await upcomingFor(u)).length, lessThanOrEqualTo(4));
      }
    });

    test('the two bills keep the order the repository gave them', () async {
      // Both sit on the same sort key, so only a stable sort keeps them in
      // the order they were listed.
      final List<LumeUpcomingItem> items = LumeHomeComposer.upcoming(
        user: LumeUsers.defaultPk,
        eligibility: kEligibility,
        content: await _content(LumeUsers.defaultPk, kFixtureInstant),
        now: kFixtureInstant,
      );
      expect(
        items.whereType<LumeBillUpcoming>().map(
          (LumeBillUpcoming b) => b.bill.name,
        ),
        <String>['Electricity', 'Internet'],
      );
    });
  });

  group('Discover', () {
    Future<List<String>> discoverFor(LumeUserContext user) async =>
        LumeHomeComposer.discover(
          user: user,
          eligibility: kEligibility,
          content: await _content(user, kFixtureInstant),
          explorePath: LumeRoutes.explore,
        ).map((LumeDiscoverCard c) => c.id.name).toList();

    test('Pakistan, not Muslim: four cards', () async {
      expect(await discoverFor(LumeUsers.defaultPk), <String>[
        'cricket',
        'weather',
        'outage',
        'parcel',
      ]);
    });

    test('Muslim: the duas card joins them, in place', () async {
      expect(await discoverFor(LumeUsers.muslimPk), <String>[
        'cricket',
        'weather',
        'outage',
        'duas',
        'parcel',
      ]);
    });

    test('United States: the weather card alone', () async {
      expect(await discoverFor(LumeUsers.defaultUs), <String>['weather']);
    });

    test('switching cricket off removes the cricket card', () async {
      // The prototype gates this strip on `data-loc` only, so a user who
      // switched cricket off still saw a cricket score (C12).
      expect(
        await discoverFor(LumeUsers.prefsOffPk),
        isNot(contains('cricket')),
      );
    });
  });

  group('the header', () {
    test('a greeting for each part of the day', () {
      expect(LumeGreeting.forHour(2), LumeGreeting.late);
      expect(LumeGreeting.forHour(9), LumeGreeting.morning);
      expect(LumeGreeting.forHour(16), LumeGreeting.afternoon);
      expect(LumeGreeting.forHour(20), LumeGreeting.evening);
      expect(LumeGreeting.forHour(22), LumeGreeting.windDown);
    });

    test('initials come from a real name, or there are none', () {
      final LumeHomeHeader anon = LumeHomeHeader(
        greeting: LumeGreeting.morning,
        date: kFixtureInstant,
        city: 'Islamabad',
      );
      expect(anon.initials, '');
      expect(anon.isNamed, isFalse);
      expect(
        LumeHomeHeader(
          greeting: LumeGreeting.morning,
          date: kFixtureInstant,
          city: 'Islamabad',
          displayName: 'Amina Tariq',
        ).initials,
        'AT',
      );
      expect(
        LumeHomeHeader(
          greeting: LumeGreeting.morning,
          date: kFixtureInstant,
          city: 'Islamabad',
          displayName: 'Amina',
        ).initials,
        'A',
      );
    });
  });

  group('the context strip', () {
    test('the faith dimension swaps it, and nothing else does', () async {
      for (final LumeUserContext u in LumeUsers.all.values) {
        final LumeContextCard? card = LumeHomeComposer.contextCard(
          user: u,
          content: await _content(u, kFixtureInstant),
          now: kFixtureInstant,
        );
        expect(
          card is LumePrayerContext,
          u.islamic,
          reason: '${u.country} islamic=${u.islamic}',
        );
      }
    });

    test('it names the next prayer, not a passed one', () async {
      final LumePrayerContext card =
          LumeHomeComposer.contextCard(
                user: LumeUsers.muslimPk,
                content: await _content(LumeUsers.muslimPk, kFixtureInstant),
                now: kFixtureInstant,
              )!
              as LumePrayerContext;
      // 16:41 is after Asr (15:53) and before Maghrib (18:27).
      expect(card.next.key, 'maghrib');
      expect(
        card.remaining,
        const Duration(hours: 1, minutes: 45, seconds: 28),
      );
    });

    test('after the last prayer it rolls to tomorrow\'s first', () async {
      final LumePrayerContext card =
          LumeHomeComposer.contextCard(
                user: LumeUsers.muslimPk,
                content: await _content(
                  LumeUsers.muslimPk,
                  DateTime(2026, 9, 7, 23),
                ),
                now: DateTime(2026, 9, 7, 23),
              )!
              as LumePrayerContext;
      expect(card.next.key, 'fajr');
      expect(card.next.at.day, 8);
    });
  });
}

/// The fixture's content for a user at a moment.
Future<LumeHomeContent> _content(LumeUserContext user, DateTime now) async =>
    (await LumeFakeHomeRepository().load(user, now: now)).content;
