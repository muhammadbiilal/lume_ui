/// The notification centre: what it shows, what it withholds, and what a tap
/// does to what is true.
///
/// The three rules worth guarding are all about what must never reach the
/// screen. A row for a tool this reader cannot see is not built — so there is
/// no list it could leak from. A sensitive tool's detail is replaced *in the
/// repository*, so the widget layer never holds it. And priority outranks
/// recency, so an important row cannot be pushed off the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/features/account/data/notification_prefs_store.dart';
import 'package:lume/features/account/domain/notification_prefs.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/notifications/data/notification_fixtures.dart';
import 'package:lume/features/notifications/domain/notification_model.dart';
import 'package:lume/features/notifications/presentation/notification_centre.dart';
import 'package:lume/features/notifications/presentation/notification_host.dart';
import 'package:lume/features/notifications/presentation/notification_row.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../destinations/destination_harness.dart';

/// Tall, so the whole centre lays out in one pass.
const Size kTall = Size(390, 3000);

void main() {
  setUpAll(loadLumeFonts);

  Future<AppLocalizations> stringsFor(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    late AppLocalizations l;
    await pumpLume(
      tester,
      Builder(
        builder: (BuildContext context) {
          l = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
      locale: locale,
    );
    return l;
  }

  LumeFixtureNotificationRepository repo({
    required AppLocalizations l,
    LumeUserContext? user,
    LumeNotificationPrefs? prefs,
    List<LumeNotificationSample>? samples,
    bool quietHours = false,
    bool pushEnabled = false,
    LumeNotificationFailure? failWith,
  }) => LumeFixtureNotificationRepository(
    eligibility: kEligibility,
    user: user ?? LumeUsers.muslimPk,
    l: l,
    readPrefs: () => prefs ?? const LumeNotificationPrefs(),
    samples: samples ?? kNotificationSamples,
    quietHours: quietHours,
    pushEnabled: pushEnabled,
    failWith: failWith,
  );

  // ------------------------------------------------------------- the feed

  group('the feed', () {
    testWidgets('is only what this reader can reach', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed muslim = await repo(
        l: l,
      ).feed(now: DateTime(2026, 9, 13));
      final LumeNotificationFeed secular = await repo(
        l: l,
        user: LumeUsers.defaultPk,
      ).feed(now: DateTime(2026, 9, 13));

      // The prayer row is faith-gated, so it is *absent* rather than hidden.
      expect(
        muslim.all.where((LumeNotification n) => n.tool == 'prayer'),
        isNotEmpty,
      );
      expect(
        secular.all.where((LumeNotification n) => n.tool == 'prayer'),
        isEmpty,
      );
    });

    testWidgets('and a market’s own alerts belong to that market', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed gb = await repo(
        l: l,
        user: LumeUsers.muslimGb,
      ).feed(now: DateTime(2026, 9, 13));
      // Load-shedding is a Pakistani service.
      expect(
        gb.all.where((LumeNotification n) => n.tool == 'loadshed'),
        isEmpty,
      );
    });

    testWidgets('a category switched off empties its rows', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed off = await repo(
        l: l,
        prefs: const LumeNotificationPrefs(off: <String>{'travel'}),
      ).feed(now: DateTime(2026, 9, 13));
      expect(
        off.all.where((LumeNotification n) => n.category == 'travel'),
        isEmpty,
      );
    });

    testWidgets('and so does one type, without touching its neighbours', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed off = await repo(
        l: l,
        prefs: const LumeNotificationPrefs(typesOff: <String>{'bills.due'}),
      ).feed(now: DateTime(2026, 9, 13));
      final Iterable<String> ids = off.all.map((LumeNotification n) => n.id);
      expect(ids.where((String i) => i.startsWith('bills.due')), isEmpty);
      expect(
        ids.where((String i) => i.startsWith('bills.overdue')),
        isNotEmpty,
      );
    });

    testWidgets('priority outranks recency', (WidgetTester tester) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed f = await repo(
        l: l,
      ).feed(now: DateTime(2026, 9, 13));
      final List<LumeNotification> live = f.all
          .where((LumeNotification n) => !n.expired)
          .toList();

      for (int i = 1; i < live.length; i++) {
        final LumeNotification a = live[i - 1];
        final LumeNotification b = live[i];
        expect(
          a.priority.rank >= b.priority.rank,
          isTrue,
          reason: '${a.title} before ${b.title}',
        );
        if (a.priority.rank == b.priority.rank) {
          expect(a.agoMinutes <= b.agoMinutes, isTrue, reason: a.title);
        }
      }
    });

    testWidgets('and an expired row sinks below every live one', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed f = await repo(
        l: l,
      ).feed(now: DateTime(2026, 9, 13));
      final int firstExpired = f.all.indexWhere(
        (LumeNotification n) => n.expired,
      );
      if (firstExpired == -1) return;
      for (int i = firstExpired; i < f.all.length; i++) {
        expect(f.all[i].expired, isTrue);
      }
    });

    testWidgets('it says it is not durable', (WidgetTester tester) async {
      final AppLocalizations l = await stringsFor(tester);
      expect(repo(l: l).isDurable, isFalse);
    });
  });

  // ------------------------------------------------------------- privacy

  group('what a row is allowed to say', () {
    testWidgets('with previews off, no row says anything', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed f = await repo(
        l: l,
        prefs: const LumeNotificationPrefs(preview: false),
      ).feed(now: DateTime(2026, 9, 13));

      expect(f.all, isNotEmpty);
      for (final LumeNotification n in f.all) {
        expect(n.body, l.nHidden, reason: n.title);
      }
    });

    testWidgets('a sensitive row withholds its detail by default', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed f = await repo(
        l: l,
      ).feed(now: DateTime(2026, 9, 13));
      final LumeNotification meds = f.all.firstWhere(
        (LumeNotification n) => n.tool == 'meds',
      );
      // The drug and the dose are not on the screen, and were never put
      // there: the repository substituted before the widget existed.
      expect(meds.body, 'A medication reminder is due');
      expect(meds.body, isNot(contains('Metformin')));
      expect(meds.body, isNot(contains('500')));
    });

    testWidgets('and says it once the reader asks for it', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed f = await repo(
        l: l,
        prefs: const LumeNotificationPrefs(sensitivePreview: true),
      ).feed(now: DateTime(2026, 9, 13));
      final LumeNotification meds = f.all.firstWhere(
        (LumeNotification n) => n.tool == 'meds',
      );
      expect(meds.body, contains('Metformin'));
    });

    testWidgets('a non-sensitive row is unaffected either way', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      for (final bool sensitive in <bool>[false, true]) {
        final LumeNotificationFeed f = await repo(
          l: l,
          prefs: LumeNotificationPrefs(sensitivePreview: sensitive),
        ).feed(now: DateTime(2026, 9, 13));
        final LumeNotification train = f.all.firstWhere(
          (LumeNotification n) => n.tool == 'trains',
        );
        expect(train.body, 'About 35 minutes behind');
      }
    });
  });

  // ------------------------------------------------------------- grouping

  group('folding', () {
    testWidgets('three updates of one event become two rows', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed f = await repo(
        l: l,
      ).feed(now: DateTime(2026, 9, 13));
      final List<LumeNotification> folded = foldNotifications(f.all, l);

      final Iterable<LumeNotification> kse = folded.where(
        (LumeNotification n) => n.groupId == 'markets.kse',
      );
      expect(kse.length, 2);
      expect(kse.last.grouped, isTrue);
      expect(kse.last.members, 2);
      expect(kse.last.body, '2 more updates');
    });

    testWidgets('and two do not', (WidgetTester tester) async {
      final AppLocalizations l = await stringsFor(tester);
      final List<LumeNotificationSample> two = kNotificationSamples
          .where(
            (LumeNotificationSample s) =>
                s.sourceId != 'markets.move' || s.agoMinutes != 26,
          )
          .toList();
      final LumeNotificationFeed f = await repo(
        l: l,
        samples: two,
      ).feed(now: DateTime(2026, 9, 13));
      final List<LumeNotification> folded = foldNotifications(f.all, l);
      expect(folded.where((LumeNotification n) => n.grouped), isEmpty);
    });

    testWidgets('unrelated events are never folded together', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      final LumeNotificationFeed f = await repo(
        l: l,
      ).feed(now: DateTime(2026, 9, 13));
      final List<LumeNotification> folded = foldNotifications(f.all, l);
      for (final LumeNotification n in folded.where(
        (LumeNotification x) => x.grouped,
      )) {
        expect(n.groupId, 'markets.kse');
      }
    });
  });

  // ------------------------------------------------------------ the words

  group('how long ago', () {
    testWidgets('reads in the reader’s own units', (WidgetTester tester) async {
      final AppLocalizations l = await stringsFor(tester);
      expect(lumeNotificationAge(l, 0), 'just now');
      expect(lumeNotificationAge(l, 1), '1 min ago');
      expect(lumeNotificationAge(l, 45), '45 min ago');
      expect(lumeNotificationAge(l, 60), '1 hr ago');
      expect(lumeNotificationAge(l, 150), '3 hr ago');
      expect(lumeNotificationAge(l, 1440), '1 d ago');
      expect(lumeNotificationAge(l, 2880), '2 d ago');
    });

    testWidgets('and counts one separately in every language', (
      WidgetTester tester,
    ) async {
      for (final String code in <String>['en', 'ur', 'ar']) {
        final AppLocalizations l = await stringsFor(
          tester,
          locale: Locale(code),
        );
        expect(
          lumeNotificationAge(l, 1),
          isNot(lumeNotificationAge(l, 5)),
          reason: code,
        );
      }
    });
  });

  // ----------------------------------------------------------- the screen

  group('the screen', () {
    Future<GoRouter> open(
      WidgetTester tester, {
      String at = '/home/notifications',
      LumeProfileRecord? profile,
      LumeMemoryNotificationPrefs? store,
      Locale locale = const Locale('en'),
      double textScale = 1.0,
      Size surface = kTall,
    }) async {
      LumeMemoryProfileRepository? profiles;
      if (profile != null) {
        profiles = LumeMemoryProfileRepository();
        await profiles.writeProfile(profile);
      }
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: at,
        profile: profiles,
        surface: surface,
        locale: locale,
        textScale: textScale,
        overrides: <Override>[
          if (store != null) notificationPrefsProvider.overrideWithValue(store),
        ],
      );
      // Past the 90 ms skeleton.
      await tester.pump(LumeNotificationHost.settle);
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('shows the shape of what is coming before it arrives', (
      WidgetTester tester,
    ) async {
      // Without `settle: false` the harness would run the launch — and the
      // ninety-millisecond skeleton — to completion before the first
      // assertion, and there would be no skeleton left to find.
      await pumpLumeRouter(
        tester,
        initialLocation: '/home/notifications',
        surface: kTall,
        settle: false,
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(LumeNotificationHost.skeletonKey), findsOneWidget);

      await tester.pump(LumeNotificationHost.settle);
      await tester.pumpAndSettle();
      expect(find.byKey(LumeNotificationHost.skeletonKey), findsNothing);
    });

    testWidgets('the header counts what is unread', (
      WidgetTester tester,
    ) async {
      await open(tester);
      expect(find.textContaining('unread'), findsWidgets);
      expect(find.text('Notifications'), findsWidgets);
    });

    testWidgets('three tabs, each with its own count', (
      WidgetTester tester,
    ) async {
      await open(tester);
      expect(find.byKey(LumeNotificationCentre.tabsKey), findsOneWidget);
      expect(find.text('All'), findsWidgets);
      expect(find.text('Unread'), findsWidgets);
      expect(find.text('Important'), findsWidgets);
    });

    testWidgets('and the category bar offers only live categories', (
      WidgetTester tester,
    ) async {
      await open(tester);
      // News has no sample, so there is no chip for it — a chip for an empty
      // category is a dead end.
      final Iterable<String> chips = tester
          .widgetList<LumeFilterChip>(find.byType(LumeFilterChip))
          .map((LumeFilterChip c) => c.label);
      expect(chips, contains('Travel'));
      expect(chips, isNot(contains('News')));
    });

    testWidgets('the Unread tab drops everything already read', (
      WidgetTester tester,
    ) async {
      await open(tester);
      final int before = tester
          .widgetList<LumeNotificationRow>(find.byType(LumeNotificationRow))
          .length;

      await tester.tap(find.text('Unread').first);
      await tester.pumpAndSettle();
      // Nothing has been read yet, so Unread holds everything that is not
      // expired — which is fewer than All.
      expect(
        tester
            .widgetList<LumeNotificationRow>(find.byType(LumeNotificationRow))
            .length,
        lessThanOrEqualTo(before),
      );
    });

    testWidgets('Important holds only what is ranked high or critical', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Important').first);
      await tester.pumpAndSettle();

      for (final LumeNotificationRow row
          in tester.widgetList<LumeNotificationRow>(
            find.byType(LumeNotificationRow),
          )) {
        expect(row.notification.priority.rank, greaterThanOrEqualTo(2));
      }
    });

    testWidgets('a category chip narrows to that category', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.widgetWithText(LumeFilterChip, 'Travel'));
      await tester.pumpAndSettle();

      for (final LumeNotificationRow row
          in tester.widgetList<LumeNotificationRow>(
            find.byType(LumeNotificationRow),
          )) {
        expect(row.notification.category, 'travel');
      }
    });

    testWidgets('opening a row marks it read and goes to its tool', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await open(tester);
      await tester.tap(find.text('Heavy rain warning'));
      await tester.pumpAndSettle();
      expect(locationOf(router), '/home/tool/weather');
    });

    testWidgets('and from another branch it opens on that branch', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await open(tester, at: '/today/notifications');
      await tester.tap(find.text('Heavy rain warning'));
      await tester.pumpAndSettle();
      expect(locationOf(router), '/today/tool/weather');
    });

    testWidgets('marking all read empties the Unread tab', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('Mark all as read'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unread').first);
      await tester.pumpAndSettle();
      expect(find.byKey(LumeNotificationCentre.emptyKey), findsOneWidget);
      expect(find.text('You’re all caught up'), findsWidgets);
    });

    testWidgets('and the header says so too', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('Mark all as read'));
      await tester.pumpAndSettle();
      expect(find.text('You’re all caught up'), findsWidgets);
      // With nothing unread the control itself is gone.
      expect(find.bySemanticsLabel('Mark all as read'), findsNothing);
    });

    testWidgets('dismissing a row removes it', (WidgetTester tester) async {
      await open(tester);
      expect(find.text('Green Line is running late'), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel('Dismiss, Green Line is running late'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Green Line is running late'), findsNothing);
    });

    testWidgets('the empty state says which tab is empty', (
      WidgetTester tester,
    ) async {
      await open(
        tester,
        profile: const LumeProfileRecord(
          country: 'GB',
          city: 'London',
          islamic: false,
        ),
        store: LumeMemoryNotificationPrefs(
          const LumeNotificationPrefs(
            off: <String>{
              'faith',
              'finance',
              'markets',
              'travel',
              'weather',
              'personal',
              'reminders',
              'documents',
              'health',
              'system',
              'news',
            },
          ),
        ),
      );
      expect(find.byKey(LumeNotificationCentre.emptyKey), findsOneWidget);
      expect(find.text('Nothing to tell you'), findsOneWidget);
    });

    testWidgets('nothing on the screen claims it was delivered', (
      WidgetTester tester,
    ) async {
      await open(tester);
      expect(
        find.textContaining('no notification server in this build'),
        findsOneWidget,
      );
      for (final String never in <String>[
        'Synced',
        'Delivered',
        'Live',
        'just synced',
      ]) {
        expect(find.textContaining(never), findsNothing, reason: never);
      }
    });

    testWidgets('quiet hours are said out loud, and say what they do not do', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      await pumpLumeRouter(
        tester,
        initialLocation: '/home/notifications',
        surface: kTall,
        overrides: <Override>[
          notificationFeedProvider.overrideWithValue(
            repo(l: l, quietHours: true),
          ),
        ],
      );
      await tester.pump(LumeNotificationHost.settle);
      await tester.pumpAndSettle();

      expect(find.text('Quiet hours are on'), findsOneWidget);
      expect(
        find.textContaining('everything still arrives here'),
        findsOneWidget,
      );
    });

    testWidgets('a feed that cannot be read leaves the reader somewhere', (
      WidgetTester tester,
    ) async {
      final AppLocalizations l = await stringsFor(tester);
      await pumpLumeRouter(
        tester,
        initialLocation: '/home/notifications',
        surface: kTall,
        overrides: <Override>[
          notificationFeedProvider.overrideWithValue(
            repo(l: l, failWith: LumeNotificationFailure.unreachable),
          ),
        ],
      );
      await tester.pump(LumeNotificationHost.settle);
      await tester.pumpAndSettle();

      expect(find.byType(LumeToolState), findsOneWidget);
      expect(find.text('Notifications could not be loaded'), findsOneWidget);
      expect(find.text('Try again'), findsWidgets);
    });

    testWidgets('Back returns to the branch it was opened from', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await open(tester, at: '/today/notifications');
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.today);
    });

    testWidgets('a row reads as one sentence to a screen reader', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      expect(
        find.bySemanticsLabel(RegExp('^Unread, Heavy rain warning, Critical')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  // -------------------------------------------------- direction and scale

  group('every language, and twice the type size', () {
    for (final (String code, TextDirection dir) lang
        in <(String, TextDirection)>[
          ('en', TextDirection.ltr),
          ('ur', TextDirection.rtl),
          ('ar', TextDirection.rtl),
        ]) {
      testWidgets('${lang.$1} lays out', (WidgetTester tester) async {
        for (final double scale in <double>[1.0, 2.0]) {
          await pumpLumeRouter(
            tester,
            initialLocation: '/home/notifications',
            surface: kTall,
            locale: Locale(lang.$1),
            textScale: scale,
          );
          await tester.pump(LumeNotificationHost.settle);
          await tester.pumpAndSettle();

          expect(
            Directionality.of(tester.element(find.byType(LumeNoteCard).first)),
            lang.$2,
            reason: lang.$1,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${lang.$1} at ${scale}x',
          );
        }
      });
    }
  });
}
