/// Global search: what it finds, what it must not find, and where it goes.
///
/// The index is the part worth guarding. It is built from `visibleFeatures`,
/// so a faith-gated or country-gated tool is *absent* from it rather than
/// filtered out of a list it is already in — and that difference is the whole
/// of §64 on this surface. A test that only checked the results could pass
/// against an index that had the Qur'an in it all along.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/search/data/search_index.dart';
import 'package:lume/features/search/domain/search_model.dart';
import 'package:lume/features/search/presentation/search_sheet.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../destinations/destination_harness.dart';

/// Tall, so the sheet's own list is laid out rather than clipped.
const Size kTall = Size(390, 1400);

void main() {
  setUpAll(loadLumeFonts);

  /// A repository for [user], with English strings.
  Future<LumeFixtureSearchRepository> repoFor(
    WidgetTester tester,
    LumeUserContext user, {
    List<String> recents = const <String>[],
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
    );
    return LumeFixtureSearchRepository(
      eligibility: kEligibility,
      l: l,
      user: user,
      recents: recents,
    );
  }

  // ------------------------------------------------------------- the index

  group('the index', () {
    testWidgets('is the catalogue this reader can actually reach', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository muslim = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      final LumeFixtureSearchRepository secular = await repoFor(
        tester,
        LumeUsers.defaultPk,
      );
      // Faith adds seventeen tools and three surahs and a mosque; the two
      // indexes differ by exactly what the reader asked for.
      expect(muslim.indexSize, greaterThan(secular.indexSize));
    });

    testWidgets('a faith-gated tool is not in it, not merely filtered out', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.defaultPk,
      );
      // Every word that would reach the Qur'an, asked directly.
      for (final String q in <String>[
        'quran',
        'qur',
        'surah',
        'rahman',
        'qibla',
        'tasbih',
        'mosque',
      ]) {
        final LumeSearchResults r = await repo.search(q);
        expect(r.hits, isEmpty, reason: q);
      }
    });

    testWidgets('and is there for a reader who asked for it', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      expect((await repo.search('surah rahman')).hits, isNotEmpty);
      expect((await repo.search('qibla')).hits, isNotEmpty);
    });

    testWidgets('a market’s own entry belongs to that market', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository pk = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      final LumeFixtureSearchRepository uk = await repoFor(
        tester,
        LumeUsers.muslimGb,
      );
      expect((await pk.search('karachi cantt')).hits, isNotEmpty);
      expect((await uk.search('karachi cantt')).hits, isEmpty);
    });

    testWidgets('a country-gated tool goes with it', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository uk = await repoFor(
        tester,
        LumeUsers.muslimGb,
      );
      for (final String q in <String>['loadshedding', 'prize bond']) {
        expect((await uk.search(q)).hits, isEmpty, reason: q);
      }
    });
  });

  // ------------------------------------------------------------- matching

  group('matching', () {
    testWidgets('finds a tool by a word nobody would guess from its name', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      final LumeSearchResults r = await repo.search('petrol');
      expect(r.hits.first.target, 'fuel');
    });

    testWidgets('and by its English name in any language', (
      WidgetTester tester,
    ) async {
      // C18: somebody who learned a tool's English name should not lose it
      // by switching language.
      late AppLocalizations urdu;
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) {
            urdu = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
        locale: const Locale('ur'),
      );
      final LumeFixtureSearchRepository repo = LumeFixtureSearchRepository(
        eligibility: kEligibility,
        l: urdu,
        user: LumeUsers.muslimPk,
        recents: const <String>[],
      );
      expect((await repo.search('calculator')).hits, isNotEmpty);
    });

    testWidgets('every word has to appear, not just one of them', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      expect((await repo.search('calculator weather')).hits, isEmpty);
    });

    testWidgets('a word at the start outranks the same word buried', (
      WidgetTester tester,
    ) async {
      expect(
        LumeFixtureSearchRepository.scoreOf('calculator', <String>['cal']),
        6,
      );
      expect(
        LumeFixtureSearchRepository.scoreOf('unit calculator', <String>['cal']),
        4,
      );
      expect(
        LumeFixtureSearchRepository.scoreOf('uncalculated', <String>['cal']),
        2,
      );
      expect(
        LumeFixtureSearchRepository.scoreOf('weather', <String>['cal']),
        -99,
      );
    });

    testWidgets('and never returns more than fourteen', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      // A letter most tools carry somewhere.
      final LumeSearchResults r = await repo.search('a');
      expect(r.hits.length, LumeFixtureSearchRepository.limit);
    });

    testWidgets('an empty query answers with nothing rather than everything', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      for (final String q in <String>['', '   ', '\t']) {
        expect((await repo.search(q)).hits, isEmpty, reason: '"$q"');
      }
    });
  });

  // ----------------------------------------------------------------- idle

  group('before anything is typed', () {
    testWidgets('the chips are this reader’s, in the reference’s order', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository pk = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      expect((await pk.idle()).suggestions, <String>[
        'petrol',
        'trains',
        'bills',
        'qibla',
        'surah rahman',
        'currency',
      ]);
    });

    testWidgets('and a reader elsewhere is not offered another market’s', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository uk = await repoFor(
        tester,
        LumeUsers.defaultUs,
      );
      final List<String> picks = (await uk.idle()).suggestions;
      expect(picks, isNot(contains('petrol')));
      expect(picks, isNot(contains('qibla')));
      expect(picks, <String>['currency', 'calculator', 'weather']);
    });

    testWidgets('recents are the reader’s own, newest first', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.muslimPk,
        recents: <String>['weather', 'calculator'],
      );
      final List<LumeSearchHit> recent = (await repo.idle()).recent;
      expect(recent.map((LumeSearchHit h) => h.target), <String>[
        'weather',
        'calculator',
      ]);
    });

    testWidgets('a hidden tool does not come back through them', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.defaultPk,
        recents: <String>['quran', 'calculator'],
      );
      expect(
        (await repo.idle()).recent.map((LumeSearchHit h) => h.target),
        <String>['calculator'],
      );
    });

    testWidgets('with nothing opened yet there is still somewhere to go', (
      WidgetTester tester,
    ) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      expect(
        (await repo.idle()).recent.map((LumeSearchHit h) => h.target),
        LumeFixtureSearchRepository.fallbackRecents,
      );
    });

    testWidgets('and never more than four', (WidgetTester tester) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.muslimPk,
        recents: <String>[
          'weather',
          'calculator',
          'calendar',
          'notes',
          'currency',
          'todo',
        ],
      );
      expect(
        (await repo.idle()).recent.length,
        LumeFixtureSearchRepository.recentLimit,
      );
    });
  });

  // ---------------------------------------------------------------- durability

  group('what is behind it', () {
    testWidgets('says it is not durable', (WidgetTester tester) async {
      final LumeFixtureSearchRepository repo = await repoFor(
        tester,
        LumeUsers.muslimPk,
      );
      expect(repo.isDurable, isFalse);
    });
  });

  // --------------------------------------------------------------- the sheet

  group('the sheet', () {
    Future<GoRouter> open(
      WidgetTester tester, {
      String at = '/home/search',
      LumeProfileRecord? profile,
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
      );
      // The sheet rises on the first frame after the route builds.
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('rises over the destination rather than replacing it', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await open(tester);
      expect(find.byType(LumeSearchSheet), findsOneWidget);
      expect(locationOf(router), '/home/search');
      // Home is still there, behind it.
      expect(find.text('Quick tools'), findsOneWidget);
    });

    testWidgets('opens on the idle blocks, not on a blank body', (
      WidgetTester tester,
    ) async {
      await open(tester);
      expect(find.byKey(LumeSearchSheet.idleKey), findsOneWidget);
      expect(find.byKey(LumeSearchSheet.resultsKey), findsNothing);
      // `.group-label { text-transform: uppercase }` — styling, not a
      // different string.
      expect(find.text('TRY SEARCHING FOR'), findsOneWidget);
      expect(find.text('JUMP BACK IN'), findsOneWidget);
      // `.chip`, not `.fchip` — measured against the reference.
      expect(find.byType(LumeChoiceChip), findsNWidgets(6));
    });

    testWidgets('typing replaces the idle blocks with results', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.enterText(find.byType(LumeSearchField), 'petrol');
      await tester.pumpAndSettle();

      expect(find.byKey(LumeSearchSheet.idleKey), findsNothing);
      expect(find.byKey(LumeSearchSheet.resultsKey), findsOneWidget);
      expect(find.text('Fuel Prices'), findsOneWidget);
    });

    testWidgets('and clearing it brings them back', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.enterText(find.byType(LumeSearchField), 'petrol');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(LumeSearchField), '');
      await tester.pumpAndSettle();
      expect(find.byKey(LumeSearchSheet.idleKey), findsOneWidget);
    });

    testWidgets('a word that finds nothing says so, and says what to try', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.enterText(
        find.byType(LumeSearchField),
        'zzzzz nothing here',
      );
      await tester.pumpAndSettle();

      // `.empty`, not `.state` — no surface of its own, and its own drawing.
      expect(find.byType(LumeEmptyState), findsOneWidget);
      expect(find.text('Nothing found'), findsOneWidget);
      expect(
        find.text(
          'Try another word, or turn on more interests in Personalisation.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a chip puts its word in the field and searches it', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.widgetWithText(LumeChoiceChip, 'calculator'));
      await tester.pumpAndSettle();

      expect(find.byKey(LumeSearchSheet.resultsKey), findsOneWidget);
      expect(find.text('Calculator'), findsWidgets);
    });

    testWidgets('choosing a tool opens it on the branch search came from', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await open(tester, at: '/today/search');
      await tester.enterText(find.byType(LumeSearchField), 'petrol');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fuel Prices'));
      await tester.pumpAndSettle();

      // Today's branch, not Home's — so Back returns to Today.
      expect(locationOf(router), '/today/tool/fuel');
      expect(find.byType(LumeSearchSheet), findsNothing);
    });

    testWidgets('and is remembered as a tool the reader opened', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.enterText(find.byType(LumeSearchField), 'petrol');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fuel Prices'));
      await tester.pumpAndSettle();

      final ProviderContainer scope = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      expect(
        scope.read(startupControllerProvider).state.profile.recents.first,
        'fuel',
      );
    });

    testWidgets('a recent opens without anything being typed', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await open(tester);
      await tester.tap(find.byType(LumeSettingsRow).first);
      await tester.pumpAndSettle();
      expect(locationOf(router), startsWith('/home/tool/'));
    });

    testWidgets('the scrim dismisses it, and the address follows', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await open(tester);
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();

      expect(find.byType(LumeSearchSheet), findsNothing);
      // The URL and what is on screen agree again.
      expect(locationOf(router), LumeRoutes.home);
    });

    testWidgets('and so does system Back', (WidgetTester tester) async {
      final GoRouter router = await open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(LumeSearchSheet), findsNothing);
      expect(locationOf(router), LumeRoutes.home);
    });

    testWidgets('a reader without the Islamic experience cannot type to it', (
      WidgetTester tester,
    ) async {
      await open(
        tester,
        profile: const LumeProfileRecord(country: 'PK', islamic: false),
      );
      await tester.enterText(find.byType(LumeSearchField), 'surah');
      await tester.pumpAndSettle();
      expect(find.byType(LumeEmptyState), findsOneWidget);
      expect(find.textContaining('Surah'), findsNothing);
    });
  });

  // ------------------------------------------------------ direction and scale

  group('every language, and twice the type size', () {
    for (final (String code, TextDirection dir) lang
        in <(String, TextDirection)>[
          ('en', TextDirection.ltr),
          ('ur', TextDirection.rtl),
          ('ar', TextDirection.rtl),
        ]) {
      testWidgets('${lang.$1} lays out, idle and with results', (
        WidgetTester tester,
      ) async {
        for (final double scale in <double>[1.0, 2.0]) {
          await pumpLumeRouter(
            tester,
            initialLocation: '/home/search',
            surface: kTall,
            locale: Locale(lang.$1),
            textScale: scale,
          );
          await tester.pumpAndSettle();

          expect(
            Directionality.of(tester.element(find.byType(LumeSearchSheet))),
            lang.$2,
            reason: lang.$1,
          );

          await tester.enterText(find.byType(LumeSearchField), 'a');
          await tester.pumpAndSettle();
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
