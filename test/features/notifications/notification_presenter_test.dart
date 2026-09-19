/// When the banner comes, against the running shell.
///
/// The reference's `notifyTick` runs two and a half seconds after launch and
/// every forty-five after that, and asks the engine for the next thing nobody
/// has been told about. These tests drive that schedule on a fake clock
/// through the real router, and hold it to the rule that makes the banner a
/// surface: **an event reaches the reader through exactly one**.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/locale_provider.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/navigation/lume_shell.dart';
import 'package:lume/features/account/data/notification_prefs_store.dart';
import 'package:lume/features/account/domain/notification_prefs.dart';
import 'package:lume/features/notifications/data/notification_fixtures.dart';
import 'package:lume/features/notifications/domain/notification_model.dart';
import 'package:lume/features/notifications/presentation/notification_banner.dart';
import 'package:lume/features/notifications/presentation/notification_presenter.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../destinations/destination_harness.dart';

/// The fixture instant, for reading the repository back.
final DateTime kNow = DateTime(2026, 9, 7, 16, 41);

void main() {
  setUpAll(loadLumeFonts);

  Finder banner() => find.byType(LumeNotificationBanner);

  Finder inBanner(String text) =>
      find.descendant(of: banner(), matching: find.text(text));

  /// Past a tick and the reads it awaits.
  Future<void> past(WidgetTester tester, Duration d) async {
    await tester.pump(d);
    await tester.pump();
    await tester.pump();
  }

  LumeFixtureNotificationRepository repo({
    LumeNotificationPrefs prefs = const LumeNotificationPrefs(),
    bool quietHours = false,
  }) => LumeFixtureNotificationRepository(
    eligibility: kEligibility,
    user: LumeUsers.defaultPk,
    l: lookupAppLocalizations(const Locale('en')),
    readPrefs: () => prefs,
    quietHours: quietHours,
  );

  List<Override> withFeed(
    LumeFixtureNotificationRepository feed, {
    LumeNotificationPrefs prefs = const LumeNotificationPrefs(),
  }) => <Override>[
    notificationFeedProvider.overrideWithValue(feed),
    notificationPrefsProvider.overrideWithValue(
      LumeMemoryNotificationPrefs(prefs),
    ),
  ];

  testWidgets('nothing at launch, then the first thing worth interrupting '
      'for', (WidgetTester tester) async {
    await pumpLumeRouter(tester, initialLocation: '/home');
    expect(banner(), findsNothing);

    await past(tester, LumeNotificationPresenter.firstTick);
    // The top of the ordered list: high, eight minutes old — and its dose
    // withheld, exactly as the centre's row withholds it.
    expect(inBanner('Time for your medication'), findsOneWidget);
    expect(inBanner('You have a dose due.'), findsOneWidget);
  });

  testWidgets('it withdraws on its own', (WidgetTester tester) async {
    await pumpLumeRouter(tester, initialLocation: '/home');
    await past(tester, LumeNotificationPresenter.firstTick);
    expect(banner(), findsOneWidget);

    await past(tester, LumeNotificationBanner.life);
    expect(banner(), findsNothing);
  });

  testWidgets('each event once: the next tick brings the next one', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(tester, initialLocation: '/home');
    await past(tester, LumeNotificationPresenter.firstTick);
    await past(tester, LumeNotificationBanner.life);

    await past(tester, LumeNotificationPresenter.interval);
    expect(inBanner('Time for your medication'), findsNothing);
    expect(inBanner('EK 624 is delayed'), findsOneWidget);
  });

  testWidgets('never over the centre — and the centre was its surface', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpLumeRouter(
      tester,
      initialLocation: '/home/notifications',
    );
    await past(tester, LumeNotificationPresenter.firstTick);
    expect(banner(), findsNothing);

    router.go('/home');
    await tester.pumpAndSettle();
    await past(tester, LumeNotificationPresenter.interval);
    // The medication row was taken by the tick on the centre, so leaving
    // does not banner it after the fact.
    expect(inBanner('Time for your medication'), findsNothing);
    expect(inBanner('EK 624 is delayed'), findsOneWidget);
  });

  testWidgets('nothing, and nothing taken, while in-app and push are off', (
    WidgetTester tester,
  ) async {
    const LumeNotificationPrefs off = LumeNotificationPrefs(inApp: false);
    final LumeFixtureNotificationRepository feed = repo(prefs: off);
    await pumpLumeRouter(
      tester,
      initialLocation: '/home',
      overrides: withFeed(feed, prefs: off),
    );
    await past(tester, LumeNotificationPresenter.firstTick);
    expect(banner(), findsNothing);

    final LumeNotification? next = await feed.nextToPresent(now: kNow);
    expect(next?.title, 'Time for your medication');
  });

  testWidgets('inside quiet hours only critical interrupts', (
    WidgetTester tester,
  ) async {
    final LumeFixtureNotificationRepository feed = repo(quietHours: true);
    await pumpLumeRouter(
      tester,
      initialLocation: '/home',
      overrides: withFeed(feed),
    );
    await past(tester, LumeNotificationPresenter.firstTick);
    // High is not critical: it waits in the centre, and is marked as having
    // gone there.
    expect(banner(), findsNothing);
    final LumeNotification? next = await feed.nextToPresent(now: kNow);
    expect(next?.title, 'EK 624 is delayed');
  });

  testWidgets('never over a sheet', (WidgetTester tester) async {
    await pumpLumeRouter(tester, initialLocation: '/home/search');
    await past(tester, LumeNotificationPresenter.firstTick);
    expect(banner(), findsNothing);
  });

  testWidgets('while the app is away the event waits, untaken', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(tester, initialLocation: '/home');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await past(tester, LumeNotificationPresenter.firstTick);
    expect(banner(), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await past(tester, LumeNotificationPresenter.interval);
    expect(inBanner('Time for your medication'), findsOneWidget);
  });

  testWidgets('opening it reads it and goes to its tool on this branch', (
    WidgetTester tester,
  ) async {
    final LumeFixtureNotificationRepository feed = repo();
    final GoRouter router = await pumpLumeRouter(
      tester,
      initialLocation: '/today',
      overrides: withFeed(feed),
    );
    await past(tester, LumeNotificationPresenter.firstTick);
    await tester.tap(inBanner('Time for your medication'));
    await tester.pumpAndSettle();

    expect(locationOf(router), '/today/tool/meds');
    final LumeNotificationFeed after = await feed.feed(now: kNow);
    expect(
      after.all.firstWhere((LumeNotification n) => n.tool == 'meds').read,
      isTrue,
    );
  });

  testWidgets('on a phone it drops in from the top, and the shell moves '
      'down for it', (WidgetTester tester) async {
    await pumpLumeRouter(tester, initialLocation: '/home');
    await past(tester, LumeNotificationPresenter.firstTick);
    await tester.pumpAndSettle();
    final Rect r = tester.getRect(banner());
    // `inset-inline: 12px; top: 8px`.
    expect(r.left, 12);
    expect(r.right, 390 - 12);
    expect(r.top, 8);
    // Its own slot (C92): the shell starts 8 below it, never under it.
    expect(tester.getRect(find.byType(LumeShell)).top, r.bottom + 8);
  });

  testWidgets('at tablet width it keeps the reference size at the end of '
      'its own slot', (WidgetTester tester) async {
    await pumpLumeRouter(
      tester,
      initialLocation: '/home',
      surface: const Size(1100, 900),
    );
    await past(tester, LumeNotificationPresenter.firstTick);
    await tester.pumpAndSettle();
    final Rect r = tester.getRect(banner());
    // `inset-inline-end: 24px; width: min(400px, …)` — and above the shell,
    // not over the pane's bottom corner, where a form's Save sits (C92).
    expect(r.right, 1100 - 24);
    expect(r.width, 400);
    expect(r.top, 8);
    expect(tester.getRect(find.byType(LumeShell)).top, r.bottom + 8);
  });

  // F6B — the banner the Android walk found over every tool header. The walk
  // opened each tool in a fresh process and captured it inside the first
  // banner's life; these hold the rules that make that the only way to see it.

  group('it is not brought back', () {
    Future<void> seenAndGone(WidgetTester tester) async {
      await past(tester, LumeNotificationPresenter.firstTick);
      expect(inBanner('Time for your medication'), findsOneWidget);
      await past(tester, LumeNotificationBanner.life);
      expect(banner(), findsNothing);
    }

    testWidgets('by going into a tool, and it does not outlive its life '
        'there', (WidgetTester tester) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/home',
      );
      await past(tester, LumeNotificationPresenter.firstTick);
      expect(inBanner('Time for your medication'), findsOneWidget);

      // Into a tool while the banner is up: its life is not restarted.
      router.go('/tools/tool/weather');
      await past(tester, const Duration(seconds: 3));
      router.go('/tools/tool/expenses');
      await past(
        tester,
        LumeNotificationBanner.life - const Duration(seconds: 3),
      );
      expect(banner(), findsNothing);

      // Around the tools for a whole tick: the medication never returns.
      router.go('/tools/tool/documents');
      await past(tester, LumeNotificationPresenter.interval);
      expect(inBanner('Time for your medication'), findsNothing);
    });

    testWidgets('by leaving the app and coming back', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, initialLocation: '/home');
      await seenAndGone(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await past(tester, const Duration(seconds: 10));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await past(tester, LumeNotificationPresenter.interval);
      expect(inBanner('Time for your medication'), findsNothing);
    });

    testWidgets('by changing the language', (WidgetTester tester) async {
      await pumpLumeRouter(tester, initialLocation: '/home');
      await seenAndGone(tester);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(LumeNotificationPresenter)),
      );
      container.read(localeProvider.notifier).state = const Locale('ur');
      await tester.pumpAndSettle();
      container.read(localeProvider.notifier).state = const Locale('en');
      await tester.pumpAndSettle();

      await past(tester, LumeNotificationPresenter.interval);
      expect(inBanner('Time for your medication'), findsNothing);
    });
  });
}
