/// Library, Privacy, Data & sync, Help and About.
///
/// The five routes that only *describe* — what is saved, what is kept, where
/// it is kept, and what the product is. Nothing here writes an account, which
/// makes the risk a different one: a screen that describes wrongly is harder
/// to notice than a screen that saves wrongly.
///
/// Three claims are watched most closely. **Nothing syncs**, and the screen
/// says why rather than showing an empty card that reads like a loading one.
/// **No private content leaks into a summary**: the library and the storage
/// list name kinds of thing, never a note, a name or a place. And a hidden
/// tool stays hidden — §64 applies to a favourite and a recent exactly as it
/// applies to search.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/lume_build.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/features/account/data/fake_account_repository.dart';
import 'package:lume/features/account/data/notification_prefs_store.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'account_harness.dart';

/// Tall enough that every section of these routes is laid out at once — a row
/// below the fold is still built, but its position is not a fact about order.
const Size kTall = Size(390, 2400);

void main() {
  setUpAll(loadLumeFonts);

  Finder rowTitled(String title) => find.byWidgetPredicate(
    (Widget w) => w is LumeSettingsRow && w.title == title,
    description: 'settings row "$title"',
  );

  // --------------------------------------------------------------- library

  group('the library', () {
    testWidgets('with nothing saved, says so and says how to save', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.library,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(
        find.text('Tap the star on any tool and it lands here.'),
        findsOneWidget,
      );
      // An empty state, not an empty card that reads like a loading one.
      expect(find.byType(LumeToolState), findsOneWidget);
      // And no heading over nothing: the reference titles the section only
      // when it has favourites to put under the title.
      expect(find.text('Your favourites'), findsNothing);
    });

    testWidgets('the empty state counts nothing, because there is nothing', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.library,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.textContaining('0'), findsNothing);
      expect(find.byType(LumeRichRow), findsNothing);
      expect(find.byType(LumeCompactRow), findsNothing);
    });

    testWidgets('a saved tool is named by the catalogue, with its category', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.library,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            favourites: <String>['calculator', 'weather'],
          ),
        ),
        surface: kTall,
      );
      expect(find.text('Nothing saved yet'), findsNothing);
      expect(find.text('Your favourites'), findsOneWidget);
      expect(find.byType(LumeRichRow), findsNWidgets(2));
      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Everyday'), findsOneWidget);
      expect(find.text('Weather'), findsOneWidget);
      expect(find.text('Daily Life'), findsOneWidget);
    });

    testWidgets('saved order is the reader’s order, not the catalogue’s', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.library,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            favourites: <String>['weather', 'calculator'],
          ),
        ),
        surface: kTall,
      );
      expect(
        tester.getTopLeft(find.text('Weather')).dy,
        lessThan(tester.getTopLeft(find.text('Calculator')).dy),
      );
    });

    testWidgets('recents are a second, plainer section under their own head', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.library,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            favourites: <String>['calculator'],
            recents: <String>['notes', 'weather'],
          ),
        ),
        surface: kTall,
      );
      expect(find.text('Recently used'), findsOneWidget);
      // A recent is a `compactRow`: a line and an icon, no category.
      expect(find.byType(LumeCompactRow), findsNWidgets(2));
      expect(find.byType(LumeRichRow), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Your favourites')).dy,
        lessThan(tester.getTopLeft(find.text('Recently used')).dy),
      );
    });

    testWidgets('with only recents, the empty state still stands above them', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.library,
        gate: await bootedGate(
          profile: const LumeProfileRecord(recents: <String>['calculator']),
        ),
        surface: kTall,
      );
      // Saving and opening are different things, and the screen says so:
      // having opened a tool does not make it saved.
      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(find.text('Recently used'), findsOneWidget);
    });

    testWidgets('a hidden tool does not resurface through a favourite', (
      WidgetTester tester,
    ) async {
      // §64. The Islamic experience is off, so the Qur’an is not in this
      // reader's Lume — and a list of *their own saved tools* is exactly the
      // kind of back door that would put it on screen again.
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.library,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            islamic: false,
            favourites: <String>['quran', 'calculator'],
            recents: <String>['quran'],
          ),
        ),
        surface: kTall,
      );
      expect(find.textContaining('Qur'), findsNothing);
      expect(find.byType(LumeRichRow), findsOneWidget);
      expect(find.text('Calculator'), findsOneWidget);
      // The one recent was the hidden one, so that section has nothing to
      // draw and is not drawn at all.
      expect(find.text('Recently used'), findsNothing);
    });

    testWidgets('and it comes back when that reader switches it on', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.library,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            islamic: true,
            favourites: <String>['quran'],
          ),
        ),
        surface: kTall,
      );
      expect(find.byType(LumeRichRow), findsOneWidget);
      expect(find.text('Islamic'), findsOneWidget);
    });

    testWidgets('an id the catalogue no longer knows simply drops', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.library,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            favourites: <String>['calculator', 'a-tool-that-was-removed'],
          ),
        ),
        surface: kTall,
      );
      // Not a broken row and not a leaked key: the reference's own bug here
      // was a literal "cat.undefined" on screen, and dropping is what it
      // settled on instead.
      expect(find.byType(LumeRichRow), findsOneWidget);
      expect(find.textContaining('a-tool-that-was-removed'), findsNothing);
      expect(find.textContaining('undefined'), findsNothing);
      expect(find.textContaining('cat.'), findsNothing);
    });

    testWidgets('tapping a saved tool opens that tool', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.library,
        profile: const LumeProfileRecord(favourites: <String>['calculator']),
      );
      await tester.tap(find.text('Calculator'));
      await tester.pumpAndSettle();
      expect(locationOf(router), contains('calculator'));
    });
  });

  // --------------------------------------------------------------- privacy

  group('privacy', () {
    testWidgets('three switches and a way on, and nothing else', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.privacy,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(rowTitled('Notification previews'), findsOneWidget);
      expect(rowTitled('Sensitive content in previews'), findsOneWidget);
      expect(rowTitled('Personalisation'), findsOneWidget);
      expect(find.byType(LumeSettingsRow), findsNWidgets(4));
    });

    testWidgets('and says which surface each one is about', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.privacy,
        gate: await bootedGate(),
        surface: kTall,
      );
      // Previews are a *lock screen* question — this device. Sensitive
      // content is about what those previews may contain. Personalisation is
      // about what Lume does with what the reader does.
      expect(
        find.text('Show the content of an alert on the lock screen'),
        findsOneWidget,
      );
      expect(
        find.text('Health, money and documents stay hidden until opened'),
        findsOneWidget,
      );
      expect(
        find.text('Use what you do in Lume to order what you see'),
        findsOneWidget,
      );
    });

    testWidgets('a switch with nothing behind it is a note, not a switch', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.privacy,
        gate: await bootedGate(),
        surface: kTall,
      );
      // Analytics is drawn as a note because there is nothing to switch. A
      // switch reading "off" would advertise a collection that never happens.
      expect(find.byType(LumeNoteCard), findsOneWidget);
      expect(find.text('Usage analytics'), findsOneWidget);
      expect(
        find.text('Lume collects none. There is nothing to turn off.'),
        findsOneWidget,
      );
      expect(rowTitled('Usage analytics'), findsNothing);
    });

    testWidgets('personalisation writes to the record every screen reads', (
      WidgetTester tester,
    ) async {
      final LumeStartupController gate = await bootedGate();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.privacy,
        gate: gate,
        surface: kTall,
      );
      final bool before = gate.state.profile.prefs.recommendations;
      expect(
        tester.widget<LumeSettingsRow>(rowTitled('Personalisation')).toggle,
        before,
      );

      await tester.tap(rowTitled('Personalisation'));
      await tester.pumpAndSettle();

      expect(gate.state.profile.prefs.recommendations, !before);
      expect(
        tester.widget<LumeSettingsRow>(rowTitled('Personalisation')).toggle,
        !before,
      );
    });

    testWidgets('the sensitive switch asks the opposite question, and flips', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = LumeMemoryNotificationPrefs();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.privacy,
        notify: store,
        gate: await bootedGate(),
        surface: kTall,
      );
      // "Sensitive content stays hidden" reads *on* while the preference to
      // preview it is off. The sentence is inverted; the write is not.
      expect(store.prefs.sensitivePreview, isFalse);
      expect(
        tester
            .widget<LumeSettingsRow>(rowTitled('Sensitive content in previews'))
            .toggle,
        isTrue,
      );

      await tester.tap(rowTitled('Sensitive content in previews'));
      await tester.pumpAndSettle();

      expect(store.prefs.sensitivePreview, isTrue);
      expect(
        tester
            .widget<LumeSettingsRow>(rowTitled('Sensitive content in previews'))
            .toggle,
        isFalse,
      );
    });

    testWidgets('the two preview switches share one store with Notifications', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = LumeMemoryNotificationPrefs();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.privacy,
        notify: store,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.tap(rowTitled('Notification previews'));
      await tester.pumpAndSettle();
      expect(store.prefs.preview, isFalse);

      // The same preference, seen from the other door.
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        notify: store,
        gate: await bootedGate(),
        surface: const Size(390, 6000),
      );
      expect(
        tester.widget<LumeSettingsRow>(rowTitled('Show previews')).toggle,
        isFalse,
      );
    });

    testWidgets('and it leads on to where the data actually lives', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.privacy,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(rowTitled('Data & sync'), findsOneWidget);
      expect(
        tester.widget<LumeSettingsRow>(rowTitled('Data & sync')).onTap,
        isNotNull,
      );
    });

    testWidgets('a guest gets the same three, because they are this device’s', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.privacy,
        account: LumeFakeAccountRepository.guest(),
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(rowTitled('Notification previews'), findsOneWidget);
      expect(rowTitled('Personalisation'), findsOneWidget);
      expect(find.byType(LumeNoteCard), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ sync

  group('data and sync', () {
    testWidgets('names the five kinds of thing kept on this device', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sync,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Stored on this device'), findsOneWidget);
      for (final String kind in <String>[
        'Preferences, region and language',
        'Tools, favourites and recent screens',
        'Notes, tasks, expenses and trackers',
        'Notification settings and history',
        'Your account and sessions',
      ]) {
        expect(rowTitled(kind), findsOneWidget, reason: kind);
      }
    });

    testWidgets('kinds, never contents', (WidgetTester tester) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sync,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            displayName: 'Sara',
            city: 'Lahore',
            favourites: <String>['calculator'],
          ),
        ),
        surface: kTall,
      );
      // The screen says *what kinds* of thing are here. It never lists a
      // note, a task, a favourite, a name or a place.
      expect(find.textContaining('Sara'), findsNothing);
      expect(find.textContaining('Lahore'), findsNothing);
      expect(find.textContaining('Calculator'), findsNothing);
    });

    testWidgets('none of the rows goes anywhere', (WidgetTester tester) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sync,
        gate: await bootedGate(),
        surface: kTall,
      );
      for (final LumeSettingsRow row in tester.widgetList<LumeSettingsRow>(
        find.byType(LumeSettingsRow),
      )) {
        expect(row.onTap, isNull, reason: row.title);
        expect(row.chevron, isFalse, reason: row.title);
      }
    });

    testWidgets('nothing syncs, and the screen says why', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sync,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Synced to your account'), findsNWidgets(2));
      expect(find.textContaining('no server in this build'), findsOneWidget);
      // An empty state rather than an empty card: an empty card reads like
      // something that has not loaded.
      expect(find.byType(LumeToolState), findsOneWidget);
    });

    testWidgets('no backup is claimed, and no last-sync time is invented', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sync,
        gate: await bootedGate(),
        surface: kTall,
      );
      // A "last synced" line with nothing behind it is the exact class of
      // claim §125 forbids.
      for (final String never in <String>[
        'Last synced',
        'Backed up',
        'Up to date',
        'ago',
      ]) {
        expect(find.textContaining(never), findsNothing, reason: never);
      }
    });

    testWidgets('a store that has not answered yet claims nothing at all', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sync,
        account: LumeFakeAccountRepository(
          delay: const Duration(milliseconds: 300),
        ),
        gate: await bootedGate(),
        surface: kTall,
      );
      // Before the answer arrives the list is empty — and an empty list is
      // not drawn as "nothing is stored on this device", which would be a
      // false statement rather than a missing one.
      expect(rowTitled('Preferences, region and language'), findsNothing);
      expect(find.text('Stored on this device'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(rowTitled('Preferences, region and language'), findsOneWidget);
    });

    testWidgets('a guest sees the same device list', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sync,
        account: LumeFakeAccountRepository.guest(),
        gate: await bootedGate(),
        surface: kTall,
      );
      // The route describes this device, which is as true for a guest.
      expect(find.text('Stored on this device'), findsOneWidget);
      expect(rowTitled('Preferences, region and language'), findsOneWidget);
    });

    testWidgets('and the repository behind it says it is not durable', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      expect(repo.isDurable, isFalse);
      final LumeStoredData stored = await repo.stored();
      expect(stored.synced, isEmpty);
      expect(stored.onDevice, hasLength(5));
    });
  });

  // ------------------------------------------------------------------ help

  group('help', () {
    testWidgets('says what the product is, then what to do next', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.help,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(
        find.textContaining('everything is one or two taps from Home'),
        findsOneWidget,
      );
      expect(rowTitled('Replay the welcome tour'), findsOneWidget);
      expect(rowTitled('Privacy'), findsOneWidget);
      expect(rowTitled('Data & sync'), findsOneWidget);
      expect(find.text('Send feedback'), findsOneWidget);
    });

    testWidgets('the note comes before the rows it introduces', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.help,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(
        tester.getTopLeft(find.byType(LumeNoteCard)).dy,
        lessThan(tester.getTopLeft(rowTitled('Privacy')).dy),
      );
      expect(
        tester.getTopLeft(rowTitled('Data & sync')).dy,
        lessThan(tester.getTopLeft(find.text('Send feedback')).dy),
      );
    });

    testWidgets('the two rows go to the two routes they name', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.help,
        surface: kTall,
      );
      await tester.tap(rowTitled('Privacy'));
      await tester.pumpAndSettle();
      expect(locationOf(router), endsWith('/privacy'));
      expect(rowTitled('Notification previews'), findsOneWidget);
    });

    testWidgets('feedback reports an outcome instead of opening anything', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.help,
        gate: await bootedGate(),
        surface: kTall,
      );
      // Nothing here opens a browser, a mail client or a store page: there is
      // no address to open in this build, and a control that silently opened
      // nothing would be the claim §125 forbids. It says what happened.
      expect(find.byType(LumeToast), findsNothing);
      await tester.tap(find.text('Send feedback'));
      await tester.pump();
      expect(find.byType(LumeToast), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('so does replaying the tour', (WidgetTester tester) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.help,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.tap(rowTitled('Replay the welcome tour'));
      await tester.pump();
      expect(find.byType(LumeToast), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ----------------------------------------------------------------- about

  group('about', () {
    testWidgets('names the product and says what it is for', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.about,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Lume'), findsOneWidget);
      expect(
        find.textContaining('A global daily-life super-app'),
        findsOneWidget,
      );
    });

    testWidgets('and three facts, none of which leads anywhere', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.about,
        gate: await bootedGate(),
        surface: kTall,
      );
      // Three facts, and — in the reference build — the fourth saying its data
      // is sample data (F6B decision 5).
      expect(find.byType(LumeSettingsRow), findsNWidgets(4));
      final LumeSettingsRow data = tester.widget<LumeSettingsRow>(
        rowTitled('Data'),
      );
      expect(
        data.subtitle,
        'Sample data — nothing is saved, synced or encrypted in this build',
      );
      expect(data.onTap, isNull);
      for (final String title in <String>[
        'Version',
        'Language',
        'Region & currency',
      ]) {
        final LumeSettingsRow row = tester.widget<LumeSettingsRow>(
          rowTitled(title),
        );
        // A fact is not a setting: no chevron, no destination, and a value it
        // actually has.
        expect(row.chevron, isFalse, reason: title);
        expect(row.onTap, isNull, reason: title);
        expect(row.value, isNotNull, reason: title);
        expect(row.value, isNotEmpty, reason: title);
      }
    });

    testWidgets('the version is this build’s, not the prototype’s', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.about,
        gate: await bootedGate(),
        surface: kTall,
      );
      // D40. A version number is a claim about which code is running.
      expect(
        tester.widget<LumeSettingsRow>(rowTitled('Version')).value,
        kLumeVersion,
      );
      expect(find.text('4.1.0'), findsNothing);
    });

    testWidgets('the facts are the reader’s own, and follow them', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.about,
        gate: await bootedGate(
          profile: const LumeProfileRecord(country: 'GB', city: 'London'),
        ),
        surface: kTall,
      );
      expect(
        tester.widget<LumeSettingsRow>(rowTitled('Region & currency')).value,
        contains('London'),
      );
      expect(
        tester.widget<LumeSettingsRow>(rowTitled('Language')).value,
        'English',
      );
    });

    testWidgets('a row reads as one fact to a screen reader', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.about,
        gate: await bootedGate(),
        surface: kTall,
      );
      // "Version, 0.1.0" — not two unrelated fragments.
      expect(find.bySemanticsLabel('Version, $kLumeVersion'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('nothing on either route opens an external application', (
      WidgetTester tester,
    ) async {
      // This build ships no external destination — no launcher plugin, no URI
      // handed to the platform — so there is nothing a test could open by
      // accident. What the two routes do instead is asserted above.
      for (final LumeAccountRoute route in <LumeAccountRoute>[
        LumeAccountRoute.help,
        LumeAccountRoute.about,
      ]) {
        await pumpAccountHost(
          tester,
          route: route,
          gate: await bootedGate(),
          surface: kTall,
        );
        expect(
          find.textContaining('http'),
          findsNothing,
          reason: route.segment,
        );
        expect(tester.takeException(), isNull, reason: route.segment);
      }
    });
  });
}
