/// Choosing what Home shows — the whole of it, as pure functions.
///
/// Every list on Home is a *selection*, and the selections are the part that
/// goes wrong: a carousel that opens on a hidden slide, a grid that one
/// interest fills on its own, a live row that promotes a private tool. So they
/// live here, take their inputs as arguments, and return data — no widgets, no
/// clock, no locale, no repository.
///
/// Two things the reference does implicitly are made explicit:
///
/// **Gating is eligibility, not an attribute.** The prototype marks its slides
/// and cards with `data-faith="islamic"` and `data-loc="PK"` and has the shell
/// resolve them. Every one of those attributes turns out to restate the gate on
/// the feature the element opens — the prayer slide is faith-gated and opens a
/// faith-gated tool, the trains slide is `PK` and opens a `PK` feature. So this
/// asks [LumeEligibility] about the target instead, which is §63's "use
/// centralized capability metadata" and cannot drift out of step with the
/// catalogue. `home_composition_test.dart` asserts the two agree on every slide.
///
/// **Sorting is stable.** `Array.prototype.sort` has been stable since ES2019,
/// and the hero ranking and the upcoming ordering both rely on it — two slides
/// on 74, two bills both on 500. Dart's `List.sort` is *not* stable, so every
/// comparison here falls back to declaration order.
library;

import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import 'home_content.dart';
import 'home_model.dart';

/// The pure selectors behind Home.
abstract final class LumeHomeComposer {
  // -- Hero ---------------------------------------------------------------

  /// §26 caps the carousel at four, so eligibility alone is not enough: the
  /// slides compete and the most relevant four win.
  static const int maxHeroSlides = 4;

  /// The feature whose eligibility gates each slide. `null` — plan and tools —
  /// is a slide nothing can hide.
  static const Map<LumeHeroSlideId, String?> heroGate =
      <LumeHeroSlideId, String?>{
        LumeHeroSlideId.prayer: 'prayer',
        LumeHeroSlideId.plan: null,
        LumeHeroSlideId.read: 'quran',
        LumeHeroSlideId.money: 'goldrates',
        LumeHeroSlideId.trains: 'trains',
        LumeHeroSlideId.tools: null,
      };

  /// The interests that lift the money slide from "worth showing" to "worth
  /// showing first".
  static const Set<String> moneyInterests = <String>{
    'rates',
    'expenses',
    'bills',
    'savings',
  };

  /// What a slide is worth to this user. Negative means it is not offered.
  ///
  /// The numbers are the reference's, unchanged — they encode a judgement
  /// about relevance and changing them would change the product.
  static int heroScore(
    LumeHeroSlideId slide,
    LumeUserContext user,
    LumeEligibility eligibility,
  ) {
    final String? gate = heroGate[slide];
    if (gate != null && eligibility.visibleById(gate, user) == null) return -1;

    return switch (slide) {
      LumeHeroSlideId.prayer => 100,
      LumeHeroSlideId.plan => 80,
      LumeHeroSlideId.trains => user.hasInterest('trains') ? 78 : 74,
      LumeHeroSlideId.read => 70,
      LumeHeroSlideId.money => moneyInterests.any(user.hasInterest) ? 62 : 45,
      LumeHeroSlideId.tools => 40,
    };
  }

  /// The carousel, ranked and capped.
  static List<LumeHeroCard> hero({
    required LumeUserContext user,
    required LumeEligibility eligibility,
    required String todayPath,
    required String toolsPath,
    required String trainsPath,
  }) {
    final List<LumeHeroCard> scored = <LumeHeroCard>[];
    for (final LumeHeroSlideId slide in LumeHeroSlideId.values) {
      final int score = heroScore(slide, user, eligibility);
      if (score <= 0) continue;
      scored.add(
        LumeHeroCard(
          id: slide,
          score: score,
          target: switch (slide) {
            LumeHeroSlideId.prayer => const LumeHomeTarget.tool('prayer'),
            LumeHeroSlideId.plan => LumeHomeTarget.destination(todayPath),
            LumeHeroSlideId.read => const LumeHomeTarget.tool('quran'),
            LumeHeroSlideId.money => const LumeHomeTarget.tool('goldrates'),
            LumeHeroSlideId.trains => LumeHomeTarget.destination(trainsPath),
            LumeHeroSlideId.tools => LumeHomeTarget.destination(toolsPath),
          },
        ),
      );
    }
    _stableSortBy<LumeHeroCard>(scored, (LumeHeroCard c) => -c.score);
    return scored.take(maxHeroSlides).toList();
  }

  // -- Quick tools --------------------------------------------------------

  static const int quickToolCount = 8;

  /// The last resort, in the reference's order.
  static const List<String> quickFallback = <String>[
    'calculator',
    'weather',
    'calendar',
    'todos',
    'currency',
    'notes',
    'timer',
    'converter',
  ];

  /// Eight tiles, round-robined across the interests rather than drained in
  /// order.
  ///
  /// *"Without that, a single interest fills all eight tiles on its own."* The
  /// pass structure is the reference's: favourites, then recents, then one
  /// tool per interest per pass for four passes, then the fallbacks, then
  /// anything Home-eligible, then anything at all.
  ///
  /// **Sensitive tools are never promoted here** (§61) — at every stage,
  /// including the last-resort sweep.
  static List<LumeFeature> quickTools({
    required LumeUserContext user,
    required LumeEligibility eligibility,
  }) {
    final List<LumeFeature> picked = <LumeFeature>[];
    final Set<String> seen = <String>{};

    void add(LumeFeature? f) {
      if (f == null || picked.length >= quickToolCount) return;
      if (seen.contains(f.id)) return;
      if (f.sensitive || !eligibility.isVisible(f, user)) return;
      seen.add(f.id);
      picked.add(f);
    }

    for (final String id in user.favourites.take(3)) {
      add(eligibility.byId(id));
    }
    for (final String id in user.recents.take(2)) {
      add(eligibility.byId(id));
    }

    final List<LumeFeature> visible = eligibility.visibleFeatures(user);

    if (user.interests.isNotEmpty) {
      // One pool per interest, in the order the user chose them, so the
      // round-robin is over *their* priorities and not the catalogue's.
      final List<List<LumeFeature>> pools = <List<LumeFeature>>[
        for (final String interest in user.interests)
          visible
              .where(
                (LumeFeature f) =>
                    f.interests.contains(interest) && !f.sensitive,
              )
              .toList(),
      ];
      for (
        int round = 0;
        round < 4 && picked.length < quickToolCount;
        round++
      ) {
        for (
          int p = 0;
          p < pools.length && picked.length < quickToolCount;
          p++
        ) {
          for (final LumeFeature f in pools[p]) {
            if (seen.contains(f.id)) continue;
            add(f);
            break;
          }
        }
      }
    }

    for (final String id in quickFallback) {
      add(eligibility.byId(id));
    }
    // The last resort still respects the contract: a tool that never declared
    // itself Home-eligible does not get to fill the grid first.
    for (final LumeFeature f in visible) {
      if (f.homeEligible) add(f);
    }
    for (final LumeFeature f in visible) {
      add(f);
    }

    return picked;
  }

  // -- Quick actions ------------------------------------------------------

  static const int maxQuickActions = 5;

  /// §118, in the reference's order. Each one performs a task.
  static const List<LumeQuickAction> quickActionCatalogue = <LumeQuickAction>[
    LumeQuickAction(id: 'expense', featureId: 'expenses', icon: 'plus'),
    LumeQuickAction(id: 'task', featureId: 'todos', icon: 'check-square'),
    LumeQuickAction(id: 'scan', featureId: 'qr', icon: 'qr'),
    LumeQuickAction(id: 'note', featureId: 'notes', icon: 'note'),
    LumeQuickAction(id: 'water', featureId: 'water', icon: 'droplet'),
    LumeQuickAction(id: 'tasbih', featureId: 'tasbih', icon: 'beads'),
    LumeQuickAction(id: 'timer', featureId: 'timer', icon: 'timer'),
    LumeQuickAction(id: 'shop', featureId: 'shopping', icon: 'cart'),
    LumeQuickAction(id: 'parcel', featureId: 'parcel', icon: 'package'),
    LumeQuickAction(id: 'docscan', featureId: 'docscan', icon: 'scan'),
  ];

  /// The five actions this user gets.
  ///
  /// A sensitive tool **is** allowed here — adding an expense is a task, and
  /// the pill says "Add expense", not what is in the ledger. That is the one
  /// place §61 and §118 pull in different directions, and the reference is
  /// explicit about which wins.
  static List<LumeQuickAction> quickActions({
    required LumeUserContext user,
    required LumeEligibility eligibility,
  }) => quickActionCatalogue
      .where((LumeQuickAction a) {
        final LumeFeature? f = eligibility.visibleById(a.featureId, user);
        return f != null && f.quickEligible;
      })
      .take(maxQuickActions)
      .toList();

  // -- Live now -----------------------------------------------------------

  static const int maxLiveCards = 3;

  /// What is true right now, at most three of it.
  ///
  /// Built in the reference's order — weather, market, then an outage pushed
  /// to the *front* because a power cut outranks both, then bills — and then
  /// cut to three.
  static List<LumeLiveCard> live({
    required LumeUserContext user,
    required LumeEligibility eligibility,
    required LumeHomeContent content,
    required DateTime now,
  }) {
    final List<LumeLiveCard> cards = <LumeLiveCard>[];

    final LumeWeatherNow? weather = content.weather;
    if (weather != null && eligibility.visibleById('weather', user) != null) {
      // Weather is relevant all day; before bed it flips to tomorrow.
      final bool evening = now.hour >= 19 || now.hour < 5;
      cards.add(
        LumeWeatherLive(
          weather: weather,
          city: user.city,
          forTomorrow: evening,
        ),
      );
    }

    final LumeMarketSnapshot? market = content.market;
    if (market != null && eligibility.visibleById('markets', user) != null) {
      // While it is open, or from 08:00, so an early riser sees where it
      // closed rather than nothing at all.
      if (market.state.isOpen || now.hour >= 8) {
        cards.add(LumeMarketLive(market: market));
      }
    }

    final LumeOutage? outage = content.outage;
    if (outage != null && eligibility.visibleById('loadshed', user) != null) {
      final LumeOutageSlot? live = outage.activeAt(now);
      // A live outage outranks both, so it goes to the front.
      if (live != null) {
        cards.insert(
          0,
          LumeOutageLive(
            outage: outage,
            slot: live,
            remaining: live.to.difference(now),
          ),
        );
      }
    }

    final LumeBillsSummary? bills = content.bills;
    if (bills != null &&
        bills.overdueCount > 0 &&
        eligibility.visibleById('bills', user) != null) {
      cards.add(
        LumeBillsLive(bills: bills, currency: _currencyFor(user.country)),
      );
    }

    return cards.take(maxLiveCards).toList();
  }

  // -- At a glance --------------------------------------------------------

  /// The three cards, each admitted by its own gate.
  static List<LumeGlanceCard> glance({
    required LumeUserContext user,
    required LumeEligibility eligibility,
    required LumeHomeContent content,
    required String todayPath,
  }) => <LumeGlanceCard>[
    if (content.reading case final LumeReadingProgress r)
      if (eligibility.visibleById('quran', user) != null) LumeReadingGlance(r),
    if (content.fuel case final LumeFuelPrice f)
      if (eligibility.visibleById('fuel', user) != null)
        LumeFuelGlance(f, countryCode: user.country),
    if (content.tasks case final LumeTaskSummary t)
      LumeTasksGlance(t, todayPath: todayPath),
  ];

  // -- Coming up ----------------------------------------------------------

  static const int maxUpcoming = 4;

  /// Drawn from whatever the user actually has, soonest first.
  static List<LumeUpcomingItem> upcoming({
    required LumeUserContext user,
    required LumeEligibility eligibility,
    required LumeHomeContent content,
    required DateTime now,
  }) {
    final List<LumeUpcomingItem> out = <LumeUpcomingItem>[];

    final LumePrayerTimetable? prayer = content.prayer;
    if (prayer != null && eligibility.visibleById('prayer', user) != null) {
      final LumePrayerTime next = prayer.nextAt(now);
      out.add(
        LumePrayerUpcoming(next, minutes: next.at.difference(now).inMinutes),
      );
    }

    final LumeBillsSummary? bills = content.bills;
    if (bills != null && eligibility.visibleById('bills', user) != null) {
      for (final LumeBillDue b in bills.due.take(2)) {
        out.add(LumeBillUpcoming(b, currency: _currencyFor(user.country)));
      }
    }

    if (content.subscription case final LumeSubscriptionRenewal s) {
      if (eligibility.visibleById('subs', user) != null) {
        out.add(LumeSubscriptionUpcoming(s));
      }
    }

    if (content.birthday case final LumeBirthdayNext b) {
      if (eligibility.visibleById('birthdays', user) != null) {
        out.add(LumeBirthdayUpcoming(b));
      }
    }

    if (content.document case final LumeDocumentRenewal d) {
      if (d.days >= 0 &&
          d.days < 45 &&
          eligibility.visibleById('documents', user) != null) {
        out.add(LumeDocumentUpcoming(d));
      }
    }

    _stableSortBy<LumeUpcomingItem>(out, (LumeUpcomingItem i) => i.order);
    return out.take(maxUpcoming).toList();
  }

  // -- Discover -----------------------------------------------------------

  /// The strip, in the reference's order, each card gated by what it opens.
  static List<LumeDiscoverCard> discover({
    required LumeUserContext user,
    required LumeEligibility eligibility,
    required LumeHomeContent content,
    required String explorePath,
  }) => <LumeDiscoverCard>[
    if (content.cricket != null &&
        eligibility.visibleById('cricket', user) != null)
      const LumeDiscoverCard(
        id: LumeDiscoverId.cricket,
        target: LumeHomeTarget.tool('cricket'),
      ),
    LumeDiscoverCard(
      id: LumeDiscoverId.weather,
      target: LumeHomeTarget.destination(explorePath),
    ),
    if (content.outage != null &&
        eligibility.visibleById('loadshed', user) != null)
      const LumeDiscoverCard(
        id: LumeDiscoverId.outage,
        target: LumeHomeTarget.tool('loadshed'),
      ),
    if (eligibility.visibleById('duas', user) != null)
      const LumeDiscoverCard(
        id: LumeDiscoverId.duas,
        target: LumeHomeTarget.tool('duas'),
      ),
    if (content.parcel != null &&
        eligibility.visibleById('parcel', user) != null)
      const LumeDiscoverCard(
        id: LumeDiscoverId.parcel,
        target: LumeHomeTarget.tool('parcel'),
      ),
  ];

  // -- Header -------------------------------------------------------------

  static LumeHomeHeader header({
    required LumeUserContext user,
    required LumeHomeContent content,
    required DateTime now,
  }) => LumeHomeHeader(
    greeting: LumeGreeting.forHour(now.hour),
    date: now,
    city: user.city,
    displayName: user.displayName,
    notificationCount: content.notificationCount,
  );

  /// The strip under the header. One or the other, decided by the faith
  /// dimension and by nothing else.
  static LumeContextCard? contextCard({
    required LumeUserContext user,
    required LumeHomeContent content,
    required DateTime now,
  }) {
    if (user.islamic) {
      final LumePrayerTimetable? p = content.prayer;
      if (p == null) return null;
      final LumePrayerTime next = p.nextAt(now);
      return LumePrayerContext(next: next, remaining: next.at.difference(now));
    }
    final LumeWeatherNow? w = content.weather;
    if (w == null) return null;
    return LumeWeatherContext(
      weather: w,
      // The reference prints a fixed 14:00 here. The next thing on the day is
      // the next thing on the day, so it is read from the agenda instead.
      nextAt: content.nextEventAt ?? content.tasks?.nextAt ?? now,
    );
  }

  // -- helpers ------------------------------------------------------------

  /// The currency a market spends in. A localisation fact, not a visibility
  /// one, which is why it is not on the feature.
  static String _currencyFor(String country) => switch (country) {
    'PK' => 'PKR',
    'IN' => 'INR',
    'GB' => 'GBP',
    'US' => 'USD',
    'AE' => 'AED',
    'SA' => 'SAR',
    _ => 'USD',
  };

  /// Currency for a market, for callers outside this file.
  static String currencyFor(String country) => _currencyFor(country);

  /// Sort by a key, keeping equal elements in the order they arrived.
  ///
  /// `List.sort` uses an introsort that is not stable, so two slides on 74 or
  /// two bills on 500 would swap between runs and between platforms — and a
  /// golden would flake rather than fail.
  static void _stableSortBy<T>(List<T> items, num Function(T) key) {
    final List<(num, int, T)> keyed = <(num, int, T)>[
      for (int i = 0; i < items.length; i++) (key(items[i]), i, items[i]),
    ];
    keyed.sort(((num, int, T) a, (num, int, T) b) {
      final int byKey = a.$1.compareTo(b.$1);
      return byKey != 0 ? byKey : a.$2.compareTo(b.$2);
    });
    for (int i = 0; i < items.length; i++) {
      items[i] = keyed[i].$3;
    }
  }
}
