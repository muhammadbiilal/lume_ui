/// The seven routes that change a preference, and what changes with them.
///
/// A chooser is the simplest kind of screen and the easiest to get quietly
/// wrong: it can show the wrong current value, write a different one, write
/// twice, or write something a later screen disagrees with. Every one of the
/// seven is checked for the same four things — what it says is chosen, that
/// exactly one thing is, that choosing writes the value it names, and that
/// what it wrote reaches the store every other screen reads.
///
/// **A chooser has no draft.** The reference's `.optrow` writes on the tap and
/// has no Save, so there is nothing to cancel and nothing to roll back; what
/// there is instead is a store that can refuse, and a screen that does not
/// pretend otherwise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/locale_provider.dart';
import 'package:lume/app/providers/theme_provider.dart';
import 'package:lume/features/onboarding/presentation/country_screen.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/presentation/account_host.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

import '../../helpers/load_fonts.dart';
import 'account_harness.dart';

const Size kTall = Size(390, 4000);

void main() {
  setUpAll(loadLumeFonts);

  /// Which option row is marked as the chosen one.
  List<String> chosen(WidgetTester tester) => <String>[
    for (final LumeOptionRow row in tester.widgetList<LumeOptionRow>(
      find.byType(LumeOptionRow),
    ))
      if (row.selected) row.title,
  ];

  /// One option row, by the title it carries. Finding it by its glyphs would
  /// not work: C41 draws the title and its description as one rich run, so
  /// neither string is a `Text` of its own.
  Finder rowTitled(String title) => find.byWidgetPredicate(
    (Widget w) => w is LumeOptionRow && w.title == title,
    description: 'option row "$title"',
  );

  Future<void> choose(WidgetTester tester, String title) async {
    await tester.tap(rowTitled(title), warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// The scope the host is living in.
  ///
  /// Two of the seven write to a provider rather than to the profile record —
  /// the language and the appearance — and the application root reads those
  /// same two providers to build its `MaterialApp`. So reading them here is
  /// reading what the whole app would render with, not a test-only channel.
  ProviderContainer scopeOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(LumeAccountHost)));

  // --------------------------------------------------------------- prefs

  group('the preferences index', () {
    testWidgets('reads every value from the store it will change', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.prefs,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Pakistan · Islamabad · PKR'), findsOneWidget);
      expect(find.text('Automatic (PKR)'), findsOneWidget);
      // Units and Time both read "Automatic" — the same word for the same
      // idea, from the same record.
      expect(find.text('Automatic'), findsNWidgets(2));
      expect(find.text('Follow the system'), findsOneWidget);
    });

    testWidgets('every row leads to the route it names', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.prefs,
        gate: await bootedGate(),
        surface: kTall,
      );
      for (final String title in <String>[
        'Language',
        'Region & currency',
        'Currency',
        'Units',
        'Time',
        'Appearance',
        'Notifications',
      ]) {
        expect(
          find.widgetWithText(LumeSettingsRow, title),
          findsOneWidget,
          reason: title,
        );
      }
    });
  });

  // ------------------------------------------------------------ language

  group('language', () {
    testWidgets('offers the three Lume ships, and marks the reading one', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.language,
        gate: await bootedGate(),
        surface: kTall,
      );
      // Each in its own name: somebody looking for Urdu is looking for اردو.
      // Read from the rows rather than from the glyphs, because C41 draws a
      // title and its description as one rich run.
      final List<String> titles = <String>[
        for (final LumeOptionRow row in tester.widgetList<LumeOptionRow>(
          find.byType(LumeOptionRow),
        ))
          row.title,
      ];
      expect(titles, <String>['English', 'اردو', 'العربية']);
      expect(chosen(tester), <String>['English']);
    });

    testWidgets('the reading language is the one that is marked', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.language,
        gate: await bootedGate(),
        locale: const Locale('ar'),
        surface: kTall,
      );
      expect(chosen(tester), <String>['العربية']);
    });

    testWidgets('and language says nothing about faith or country', (
      WidgetTester tester,
    ) async {
      // §12 and §66: the three are independent. An Arabic reader in the
      // United States who has not asked for the Islamic experience gets the
      // Arabic list and nothing else changes.
      final LumeStartupController gate = await bootedGate(
        profile: const LumeProfileRecord(
          country: 'US',
          city: 'New York',
          region: 'New York',
          islamic: false,
        ),
      );
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.language,
        gate: gate,
        locale: const Locale('ar'),
        surface: kTall,
      );
      expect(chosen(tester), <String>['العربية']);
      expect(gate.state.profile.islamic, isFalse);
      expect(gate.state.profile.country, 'US');
    });

    testWidgets('choosing one changes the language the app reads in', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.language,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(scopeOf(tester).read(localeProvider), isNull);

      await choose(tester, 'اردو');

      // `null` was "follow the device". It is a choice now, and it is the
      // one that was tapped.
      expect(scopeOf(tester).read(localeProvider), const Locale('ur'));
    });

    testWidgets('and changing it resets nothing the reader owns', (
      WidgetTester tester,
    ) async {
      // §37: changing language changes what things are called, and nothing
      // else. Not the country, not the city, not what they saved.
      final LumeStartupController gate = await bootedGate(
        profile: const LumeProfileRecord(
          country: 'GB',
          city: 'London',
          islamic: true,
          favourites: <String>['calculator'],
        ),
      );
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.language,
        gate: gate,
        surface: kTall,
      );
      await choose(tester, 'العربية');

      expect(scopeOf(tester).read(localeProvider), const Locale('ar'));
      expect(gate.state.profile.country, 'GB');
      expect(gate.state.profile.city, 'London');
      expect(gate.state.profile.islamic, isTrue);
      expect(gate.state.profile.favourites, <String>['calculator']);
    });
  });

  // -------------------------------------------------------------- currency

  group('currency', () {
    testWidgets('offers the reader’s own market first, then the rest', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.currency,
        gate: await bootedGate(),
        surface: kTall,
      );
      final List<String> titles = <String>[
        for (final LumeOptionRow row in tester.widgetList<LumeOptionRow>(
          find.byType(LumeOptionRow),
        ))
          row.title,
      ];
      expect(titles.first, 'Follow my region');
      expect(titles[1], 'PKR', reason: 'the reader’s own market comes first');
      expect(titles, containsAll(<String>['USD', 'EUR', 'GBP', 'JPY']));
      // No code twice, however the list was assembled.
      expect(titles.toSet(), hasLength(titles.length));
    });

    testWidgets('automatic names the market it follows', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.currency,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.textContaining('Automatic (PKR)'), findsWidgets);
      expect(chosen(tester), <String>['Follow my region']);
    });

    testWidgets('choosing one writes it, and only it', (
      WidgetTester tester,
    ) async {
      final LumeStartupController gate = await bootedGate();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.currency,
        gate: gate,
        surface: kTall,
      );
      await choose(tester, 'USD');

      expect(gate.state.profile.currency, 'USD');
      expect(chosen(tester), <String>['USD']);
      // Nothing else on the record moved.
      expect(gate.state.profile.country, 'PK');
      expect(gate.state.profile.units, LumeUnitsPreference.auto);
      expect(gate.state.profile.clock, LumePreference.auto);
    });

    testWidgets('a reader in another market is offered that market', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.currency,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            country: 'GB',
            city: 'London',
            region: 'England',
          ),
        ),
        surface: kTall,
      );
      final List<String> titles = <String>[
        for (final LumeOptionRow row in tester.widgetList<LumeOptionRow>(
          find.byType(LumeOptionRow),
        ))
          row.title,
      ];
      expect(titles[1], 'GBP');
      expect(titles.toSet(), hasLength(titles.length));
    });
  });

  // ----------------------------------------------------------------- units

  group('units', () {
    testWidgets('three choices, one marked, each with its own examples', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.units,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.byType(LumeOptionRow), findsNWidgets(3));
      expect(chosen(tester), <String>['Follow my region']);
      // C41: the description runs on from the title, as the reference draws
      // it. The examples are still there to read.
      expect(find.textContaining('km · °C · kg'), findsOneWidget);
      expect(find.textContaining('mi · °F · lb'), findsOneWidget);
    });

    testWidgets('choosing metric writes metric', (WidgetTester tester) async {
      final LumeStartupController gate = await bootedGate();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.units,
        gate: gate,
        surface: kTall,
      );
      await choose(tester, 'Metric');
      expect(gate.state.profile.units, LumeUnitsPreference.metric);
      expect(chosen(tester), <String>['Metric']);

      await choose(tester, 'Imperial');
      expect(gate.state.profile.units, LumeUnitsPreference.imperial);
      // Still exactly one.
      expect(chosen(tester), hasLength(1));
    });
  });

  // ------------------------------------------------------------------ time

  group('time', () {
    testWidgets('the clock and the zone are two groups, each with a head', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.time,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Clock'), findsWidgets);
      expect(find.text('Time'), findsWidgets);
      expect(find.byType(LumeOptionList), findsNWidgets(2));
    });

    testWidgets('the zones offered are the ones near the reader', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.time,
        gate: await bootedGate(),
        surface: kTall,
      );
      // `zonesNear`: every distinct zone in the table whose *area* matches.
      // A list of every zone on earth would be a search problem.
      expect(find.textContaining('Asia/Karachi'), findsWidgets);
      expect(find.textContaining('Europe/'), findsNothing);
      expect(find.textContaining('America/'), findsNothing);
    });

    testWidgets('choosing a clock writes it and leaves the zone alone', (
      WidgetTester tester,
    ) async {
      final LumeStartupController gate = await bootedGate();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.time,
        gate: gate,
        surface: kTall,
      );
      await choose(tester, '24-hour');
      expect(gate.state.profile.clock, '24');
      expect(gate.state.profile.timeZone, isNull);
    });

    testWidgets('choosing a zone writes it and leaves the clock alone', (
      WidgetTester tester,
    ) async {
      final LumeStartupController gate = await bootedGate();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.time,
        gate: gate,
        surface: kTall,
      );
      // Shown by CLDR's name for it, stored by its canonical identifier.
      await choose(tester, 'United Arab Emirates Time');
      expect(gate.state.profile.timeZone, 'Asia/Dubai');
      expect(gate.state.profile.clock, LumePreference.auto);
    });

    testWidgets('and says what a market’s own clock does regardless', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.time,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(
        find.text('Markets, flights and trains always use their own timezone.'),
        findsOneWidget,
      );
    });
  });

  // ------------------------------------------------------------ appearance

  group('appearance', () {
    testWidgets('three choices, and the one in force is marked', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.appearance,
        gate: await bootedGate(),
        surface: kTall,
      );
      final List<String> titles = <String>[
        for (final LumeOptionRow row in tester.widgetList<LumeOptionRow>(
          find.byType(LumeOptionRow),
        ))
          row.title,
      ];
      expect(titles, <String>['Follow the system', 'Light', 'Dark']);
      expect(chosen(tester), <String>['Follow the system']);
    });

    testWidgets('choosing dark writes dark, and the mark moves with it', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.appearance,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(scopeOf(tester).read(themeModeProvider), ThemeMode.system);

      await choose(tester, 'Dark');

      // The provider the application root builds its `MaterialApp` from —
      // so this is the mode the whole product is now in, not a mode this
      // screen remembers.
      expect(scopeOf(tester).read(themeModeProvider), ThemeMode.dark);
      expect(chosen(tester), <String>['Dark']);
    });

    testWidgets('and back to following the system', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.appearance,
        gate: await bootedGate(),
        surface: kTall,
      );
      await choose(tester, 'Light');
      expect(scopeOf(tester).read(themeModeProvider), ThemeMode.light);

      await choose(tester, 'Follow the system');
      expect(scopeOf(tester).read(themeModeProvider), ThemeMode.system);
      // Exactly one, always: "follow the system" is a choice, not the
      // absence of one.
      expect(chosen(tester), hasLength(1));
    });
  });

  // ---------------------------------------------------------------- region

  group('region', () {
    testWidgets('warns what changing it changes, before it changes', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.region,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(
        find.textContaining('currency, markets, holidays'),
        findsOneWidget,
      );
      // And the warning is above the rows it is about.
      expect(
        tester.getTopLeft(find.textContaining('currency, markets')).dy,
        lessThan(tester.getTopLeft(find.text('Country')).dy),
      );
    });

    testWidgets('shows the country, the city and the currency it implies', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.region,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Pakistan'), findsWidgets);
      expect(find.text('Islamabad'), findsOneWidget);
      expect(find.text('PKR'), findsWidgets);
    });

    testWidgets('a city that was never chosen says so rather than nothing', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.region,
        gate: await bootedGate(
          profile: const LumeProfileRecord(country: 'PK', city: ''),
        ),
        surface: kTall,
      );
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('a different market names itself, and its own currency', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.region,
        gate: await bootedGate(
          profile: const LumeProfileRecord(
            country: 'GB',
            city: 'London',
            region: 'England',
          ),
        ),
        surface: kTall,
      );
      expect(find.text('United Kingdom'), findsWidgets);
      expect(find.text('London'), findsOneWidget);
      expect(find.text('GBP'), findsWidgets);
    });

    testWidgets('a country the table does not carry falls back to its code', (
      WidgetTester tester,
    ) async {
      // Honest rather than blank: `XK` is true, and an empty row is not.
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.region,
        gate: await bootedGate(
          profile: const LumeProfileRecord(country: 'ZZ', city: 'Nowhere'),
        ),
        surface: kTall,
      );
      expect(find.text('ZZ'), findsWidgets);
    });

    testWidgets('it changes nothing itself — it opens the thing that does', (
      WidgetTester tester,
    ) async {
      final LumeStartupController gate = await bootedGate();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.region,
        gate: gate,
        surface: kTall,
      );
      // Country, city and region move together or not at all, so this route
      // has no chooser of its own: all three rows and the button open the
      // one editor that can change them consistently.
      await tester.tap(find.text('Change country or city'));
      await tester.pumpAndSettle();

      // Country first, then the cities in it — the same two steps
      // onboarding walks, because there is only one location editor.
      expect(find.byType(LumeSheet), findsOneWidget);
      expect(find.byType(LumeCountryPickerView), findsOneWidget);
      // And nothing was written on the way there.
      expect(gate.state.profile.country, 'PK');
      expect(gate.state.profile.city, 'Islamabad');
    });
  });

  // ---------------------------------------------- what a market decides

  group('country decides which destinations exist, and nothing else', () {
    testWidgets('a Pakistani reader keeps Trains; a British one does not', (
      WidgetTester tester,
    ) async {
      // The tab set is the router's question, answered from the profile —
      // the same record these routes write. Changing country here is what
      // makes Trains appear and disappear, and it is the *only* thing it
      // decides about the reader.
      final LumeStartupController pk = await bootedGate();
      expect(pk.state.profile.country, 'PK');

      final LumeStartupController gb = await bootedGate(
        profile: const LumeProfileRecord(
          country: 'GB',
          city: 'London',
          region: 'England',
        ),
      );
      expect(gb.state.profile.country, 'GB');
      // And neither one has been given a faith by its country.
      // Neither was given a faith by its country: the two records say the
      // same thing about the Islamic experience, in two different markets.
      expect(pk.state.profile.islamic, gb.state.profile.islamic);
    });

    testWidgets('changing the country leaves the reader’s own things alone', (
      WidgetTester tester,
    ) async {
      final LumeStartupController gate = await bootedGate(
        profile: const LumeProfileRecord(
          country: 'PK',
          city: 'Islamabad',
          favourites: <String>['calculator', 'weather'],
          recents: <String>['notes'],
          displayName: 'Sara',
          islamic: true,
        ),
      );
      gate.profileChanged(
        gate.state.profile.copyWith(country: 'GB', city: 'London'),
      );

      // §37 — changing country changes which local services apply. It does
      // not delete a note, a favourite, a name or a faith preference.
      expect(gate.state.profile.favourites, <String>['calculator', 'weather']);
      expect(gate.state.profile.recents, <String>['notes']);
      expect(gate.state.profile.displayName, 'Sara');
      expect(gate.state.profile.islamic, isTrue);
    });
  });

  // --------------------------------------------------- what the store is

  group('the store behind all of them', () {
    testWidgets('is one record, and every route writes to it', (
      WidgetTester tester,
    ) async {
      final LumeStartupController gate = await bootedGate();

      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.units,
        gate: gate,
        surface: kTall,
      );
      await choose(tester, 'Imperial');

      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.currency,
        gate: gate,
        surface: kTall,
      );
      await choose(tester, 'USD');

      // Both are on the same record, and neither overwrote the other. One
      // canonical preference model, which is why a settings screen does not
      // keep its own copy.
      expect(gate.state.profile.units, LumeUnitsPreference.imperial);
      expect(gate.state.profile.currency, 'USD');
    });

    testWidgets('and says out loud that it does not survive the process', (
      WidgetTester tester,
    ) async {
      final LumeStartupController gate = await bootedGate();
      // `LumeMemoryProfileRepository` reports this, and the launch carries
      // it — which is what stops the first-run gate believing an onboarding
      // that was never really stored.
      expect(gate.state.profileIsDurable, isFalse);
    });
  });
}
