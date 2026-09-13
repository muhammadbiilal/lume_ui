/// The Notifications route, and the table behind it.
///
/// One preference store with two doors, and no engine behind either. The
/// tests are in two halves: what the *table* says — fifteen sources, eleven
/// categories, two filters asked in one place — and what the *screen* does
/// with it.
///
/// **Nothing here sends a notification.** `kNotificationSources` is
/// `notify-engine.js`'s `SOURCES` with its build functions left behind: an id,
/// a tool, a category and a type. There is no scheduler, no delivery and no
/// permission request, and the screen says "Not asked yet" rather than
/// claiming one was granted. C44.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/features/account/data/fake_account_repository.dart';
import 'package:lume/features/account/data/notification_prefs_store.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/domain/notification_prefs.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';

import '../../helpers/load_fonts.dart';
import 'account_harness.dart';

const Size kTall = Size(390, 6000);

void main() {
  setUpAll(loadLumeFonts);

  /// One settings row, by the title it carries rather than by its glyphs —
  /// a row's own text and its description are two `Text`s, and which one a
  /// finder lands on is not something a test should depend on.
  Finder rowTitled(String title) => find.byWidgetPredicate(
    (Widget w) => w is LumeSettingsRow && w.title == title,
    description: 'settings row "$title"',
  );

  // ------------------------------------------------------------- the table

  group('the SOURCES fixture', () {
    test('is the engine’s fifteen, in its own order', () {
      expect(kNotificationSources, hasLength(15));
      expect(
        kNotificationSources.map((LumeNotificationSource s) => s.id).toList(),
        <String>[
          'prayer.next',
          'bills.overdue',
          'bills.due',
          'markets.move',
          'parcel.transit',
          'flights.delay',
          'trains.delay',
          'weather.alert',
          'weather.tomorrow',
          'loadshed.next',
          'documents.expiring',
          'subs.renewal',
          'todos.today',
          'meds.dose',
          'habits.streak',
        ],
      );
    });

    test('every id is unique, and every field is filled', () {
      expect(
        kNotificationSources.map((LumeNotificationSource s) => s.id).toSet(),
        hasLength(15),
      );
      for (final LumeNotificationSource s in kNotificationSources) {
        expect(s.tool, isNotEmpty, reason: s.id);
        expect(s.category, isNotEmpty, reason: s.id);
        expect(s.type, isNotEmpty, reason: s.id);
      }
    });

    test('every source names a category the table declares', () {
      final Set<String> categories = kNotificationCategories
          .map((LumeNotificationCategory c) => c.id)
          .toSet();
      for (final LumeNotificationSource s in kNotificationSources) {
        expect(categories, contains(s.category), reason: s.id);
      }
    });

    test('and the categories are the engine’s eleven, in its order', () {
      expect(
        kNotificationCategories
            .map((LumeNotificationCategory c) => c.id)
            .toList(),
        <String>[
          'faith',
          'finance',
          'markets',
          'travel',
          'weather',
          'news',
          'personal',
          'reminders',
          'documents',
          'health',
          'system',
        ],
      );
      // Exactly one is faith-gated and one is sensitive.
      expect(
        kNotificationCategories
            .where((LumeNotificationCategory c) => c.faith)
            .map((LumeNotificationCategory c) => c.id),
        <String>['faith'],
      );
      expect(
        kNotificationCategories
            .where((LumeNotificationCategory c) => c.sensitive)
            .map((LumeNotificationCategory c) => c.id),
        <String>['health'],
      );
    });

    test('it carries no behaviour — only what a preference screen needs', () {
      // A source is four strings. If a build function, a schedule or a
      // delivery ever appears here, this fixture has become an engine and
      // C44's obligation has been quietly discharged the wrong way.
      const LumeNotificationSource one = LumeNotificationSource(
        id: 'x',
        tool: 'y',
        category: 'z',
        type: 'w',
      );
      expect(one.id, 'x');
      expect(one.tool, 'y');
    });
  });

  // ----------------------------------------------------------- the filters

  group('the two filters, asked in one place', () {
    test('faith alone hides one category', () {
      expect(LumeNotificationPrefs.visible(islamic: false), hasLength(10));
      expect(LumeNotificationPrefs.visible(islamic: true), hasLength(11));
      expect(
        LumeNotificationPrefs.visible(
          islamic: false,
        ).map((LumeNotificationCategory c) => c.id),
        isNot(contains('faith')),
      );
    });

    test('a category with no visible source behind it is not offered', () {
      // `NOTIFY.SOURCES.some(src => src.cat === c.id && visible(src.tool))`.
      // Nothing visible at all means nothing to switch.
      expect(
        LumeNotificationPrefs.visible(
          islamic: true,
          isToolVisible: (String _) => false,
        ),
        isEmpty,
      );
      // `news` has no source in the table at all, so it is never offered
      // once the second filter is asked.
      expect(
        LumeNotificationPrefs.visible(
          islamic: true,
          isToolVisible: (String _) => true,
        ).map((LumeNotificationCategory c) => c.id),
        isNot(contains('news')),
      );
    });

    test('a country-gated tool takes its category with it', () {
      // `loadshed` is the only source behind `system`, and it is a Pakistani
      // service. A reader in a market without it has nothing to switch.
      final List<String> withLoadshed = LumeNotificationPrefs.visible(
        islamic: false,
        isToolVisible: (String _) => true,
      ).map((LumeNotificationCategory c) => c.id).toList();
      final List<String> withoutLoadshed = LumeNotificationPrefs.visible(
        islamic: false,
        isToolVisible: (String tool) => tool != 'loadshed',
      ).map((LumeNotificationCategory c) => c.id).toList();

      expect(withLoadshed, contains('system'));
      expect(withoutLoadshed, isNot(contains('system')));
    });

    test('the count and the list are the same question', () {
      // C34: in the reference they disagree — the row counts eleven and the
      // screen shows fewer. Here one function answers both.
      const LumeNotificationPrefs prefs = LumeNotificationPrefs(
        off: <String>{'weather'},
      );
      bool visible(String _) => true;

      final int listed = LumeNotificationPrefs.visible(
        islamic: false,
        isToolVisible: visible,
      ).length;
      final int on = prefs.onCount(islamic: false, isToolVisible: visible);
      expect(on, listed - 1);
    });

    test('a switched-off category is an exception, not a whole set', () {
      // A category added later arrives switched **on**, because what is
      // stored is what the reader turned off rather than what they left on.
      const LumeNotificationPrefs prefs = LumeNotificationPrefs();
      expect(prefs.off, isEmpty);
      expect(prefs.isOn('a-category-invented-tomorrow'), isTrue);
      expect(prefs.isTypeOn('a-source-invented-tomorrow'), isTrue);
    });
  });

  // ----------------------------------------------------------- the screen

  group('the screen', () {
    testWidgets('has five sections, in the order the source emits them', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        gate: await bootedGate(),
        surface: kTall,
      );

      double topOf(String heading) =>
          tester.getTopLeft(find.text(heading).first).dy;

      final List<double> tops = <double>[
        topOf('General'),
        topOf('Categories'),
        topOf('By tool'),
        topOf('Quiet hours'),
        topOf('Privacy'),
      ];
      expect(tops, orderedEquals(<double>[...tops]..sort()));
      expect(tops.toSet(), hasLength(5));
    });

    testWidgets('General is the engine’s five switches', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Push notifications'), findsOneWidget);
      expect(find.text('In-app notifications'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('Vibration'), findsOneWidget);
      expect(find.text('Badge count'), findsOneWidget);
    });

    testWidgets('push says it was never asked for, rather than "off"', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        gate: await bootedGate(),
        surface: kTall,
      );
      // There is no permission request in this build. "Off" would imply one
      // was made and refused.
      expect(find.text('Not asked yet'), findsOneWidget);
      expect(find.text('Off'), findsWidgets, reason: 'the header says it too');
    });

    testWidgets('a non-Muslim reader is not offered the faith category', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        gate: await bootedGate(
          profile: const LumeProfileRecord(islamic: false),
        ),
        surface: kTall,
      );
      expect(find.text('Faith'), findsNothing);
      expect(find.text('Money'), findsOneWidget);
    });

    testWidgets('a Muslim reader is', (WidgetTester tester) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        gate: await bootedGate(profile: const LumeProfileRecord(islamic: true)),
        surface: kTall,
      );
      expect(find.text('Faith'), findsOneWidget);
    });

    testWidgets('a category can be switched off, and the store hears it', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = LumeMemoryNotificationPrefs();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        notify: store,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(store.prefs.isOn('weather'), isTrue);

      await tester.tap(rowTitled('Weather'));
      await tester.pumpAndSettle();

      expect(store.prefs.isOn('weather'), isFalse);
      expect(store.writes, 1);
      final LumeSettingsRow row = tester.widget<LumeSettingsRow>(
        rowTitled('Weather'),
      );
      expect(row.toggle, isFalse);
    });

    testWidgets('a General switch can be too, and each is its own', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = LumeMemoryNotificationPrefs();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        notify: store,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.tap(rowTitled('Sound'));
      await tester.pumpAndSettle();

      expect(store.prefs.sound, isFalse);
      // And nothing else moved.
      expect(store.prefs.inApp, isTrue);
      expect(store.prefs.haptics, isTrue);
      expect(store.prefs.badge, isTrue);
    });

    testWidgets('the per-tool section groups the sources by their tool', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        gate: await bootedGate(),
        surface: kTall,
      );
      // Two of the fifteen belong to Bills, two to Weather. Their types are
      // what the reader switches.
      expect(find.text('Overdue bills'), findsOneWidget);
      expect(find.text('Bills due soon'), findsOneWidget);
      expect(find.text('Severe weather'), findsOneWidget);
      expect(find.text('Daily forecast'), findsOneWidget);
    });

    testWidgets('one source can be switched without its neighbours', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = LumeMemoryNotificationPrefs();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        notify: store,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.tap(rowTitled('Daily forecast'));
      await tester.pumpAndSettle();

      expect(store.prefs.isTypeOn('weather.tomorrow'), isFalse);
      expect(store.prefs.isTypeOn('weather.alert'), isTrue);
      // The category is untouched: a type is not a category.
      expect(store.prefs.isOn('weather'), isTrue);
    });

    testWidgets('the two privacy switches say what they promise', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = LumeMemoryNotificationPrefs();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        notify: store,
        gate: await bootedGate(),
        surface: kTall,
      );
      // Here the switch asks whether to *show* a preview of sensitive
      // content, so it is off by default. The Privacy route asks the
      // opposite question about the same preference, in its own words —
      // which is what the reference does.
      final LumeSettingsRow sensitive = tester.widget<LumeSettingsRow>(
        rowTitled('Preview sensitive content'),
      );
      expect(store.prefs.sensitivePreview, isFalse);
      expect(sensitive.toggle, isFalse);

      await tester.tap(rowTitled('Preview sensitive content'));
      await tester.pumpAndSettle();
      expect(store.prefs.sensitivePreview, isTrue);
      expect(
        tester.widget<LumeSettingsRow>(rowTitled('Show previews')).toggle,
        isTrue,
      );
    });

    testWidgets('a guest is told whose notifications these are', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        account: LumeFakeAccountRepository.guest(),
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Notifications on this device'), findsOneWidget);
      expect(
        find.textContaining('another account’s notifications'),
        findsOneWidget,
      );
    });

    testWidgets('and the restore control is there, and says what it does', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Restore dismissed'), findsOneWidget);
    });

    testWidgets('a hidden category cannot be switched through a stale tap', (
      WidgetTester tester,
    ) async {
      // The faith category is not drawn for a non-Muslim reader, so there is
      // no row to tap — and the store is only ever written by a row. §64: a
      // hidden thing must not be reachable indirectly.
      final LumeMemoryNotificationPrefs store = LumeMemoryNotificationPrefs();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        notify: store,
        gate: await bootedGate(
          profile: const LumeProfileRecord(islamic: false),
        ),
        surface: kTall,
      );
      expect(find.text('Faith'), findsNothing);
      expect(store.writes, 0);

      // And even if something wrote it, the *count* would not move, because
      // the count asks the same two filters the list does.
      await store.write(store.prefs.toggled('faith', on: false));
      expect(
        store.prefs.onCount(islamic: false, isToolVisible: (String _) => true),
        LumeNotificationPrefs.visible(
          islamic: false,
          isToolVisible: (String _) => true,
        ).length,
      );
    });

    testWidgets('the store does not survive the process, and says so', (
      WidgetTester tester,
    ) async {
      expect(LumeMemoryNotificationPrefs().isDurable, isFalse);
    });

    testWidgets('nothing on the screen claims an engine', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.notifications,
        gate: await bootedGate(),
        surface: kTall,
      );
      // No "delivered", no "last sent", no count of anything that arrived.
      expect(find.textContaining('delivered'), findsNothing);
      expect(find.textContaining('last sent'), findsNothing);
      expect(find.byType(LumeNoteCard), findsNothing);
    });
  });
}
