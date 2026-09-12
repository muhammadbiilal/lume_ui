/// The Tools hub: what it lists, what narrows it, and the two kinds of
/// nothing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/catalogue/presentation/feature_strings.dart';
import 'package:lume/features/tools/domain/tools_filter.dart';
import 'package:lume/features/tools/presentation/tools_screen.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/l10n/app_localizations_en.dart';

import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';

final AppLocalizations en = AppLocalizationsEn();

LumeToolsView view(
  LumeUserContext user, {
  LumeToolsFilter filter = LumeToolsFilter.forYou,
  String query = '',
}) => LumeToolsQuery.build(
  eligibility: kEligibility,
  user: user,
  filter: filter,
  query: query,
  haystack: (LumeFeature f) => LumeFeatureStrings.haystack(en, f),
);

List<String> ids(LumeToolsView v) => <String>[
  for (final LumeToolGroup g in v.groups)
    for (final LumeFeature f in g.tools) f.id,
];

void main() {
  group('the catalogue the user actually has', () {
    test('the heading counts what is reachable, not what is shown', () {
      // 68 in Pakistan without the Islamic experience, 85 with it — and the
      // "For you" chip is showing far fewer than either.
      expect(view(LumeUsers.defaultPk).catalogueCount, 68);
      expect(view(LumeUsers.muslimPk).catalogueCount, 85);
      expect(
        view(LumeUsers.defaultPk).shownCount,
        lessThan(view(LumeUsers.defaultPk).catalogueCount),
      );
    });

    test('the chips are For you, All, then the visible categories', () {
      expect(
        view(LumeUsers.defaultPk).chips.map((LumeToolsFilter f) => f.id),
        <String>[
          'foryou',
          'all',
          'everyday',
          'planning',
          'money',
          'daily',
          'personal',
        ],
      );
    });

    test('the Islamic chip appears with the experience, in place', () {
      expect(
        view(LumeUsers.muslimPk).chips.map((LumeToolsFilter f) => f.id),
        <String>[
          'foryou',
          'all',
          'everyday',
          'planning',
          'islamic',
          'money',
          'daily',
          'personal',
        ],
      );
    });

    test('"All" lists every reachable tool, in catalogue order', () {
      final LumeToolsView v = view(
        LumeUsers.defaultPk,
        filter: LumeToolsFilter.all,
      );
      expect(ids(v), hasLength(68));
      expect(v.groups.first.tools.first.id, 'calculator');
      expect(v.groups.map((LumeToolGroup g) => g.category.id.name), <String>[
        'everyday',
        'planning',
        'money',
        'daily',
        'personal',
      ]);
    });

    test('"All" in Pakistan with the experience is the whole catalogue', () {
      expect(
        ids(view(LumeUsers.muslimPk, filter: LumeToolsFilter.all)),
        hasLength(85),
      );
    });

    test('the category counts match the prototype', () {
      final LumeToolsView v = view(
        LumeUsers.muslimPk,
        filter: LumeToolsFilter.all,
      );
      expect(
        <String, int>{
          for (final LumeToolGroup g in v.groups)
            g.category.id.name: g.tools.length,
        },
        <String, int>{
          'everyday': 8,
          'planning': 5,
          'islamic': 17,
          'money': 15,
          'daily': 18,
          'personal': 22,
        },
      );
    });
  });

  group('"For you" is a shortlist, not a straitjacket', () {
    test('it keeps the staples, the interests and the recents', () {
      final LumeToolsView v = view(LumeUsers.defaultPk);
      expect(v.groups.first.tools.map((LumeFeature f) => f.id), <String>[
        'calculator',
        'converter',
        'currency',
        'timer',
        'age',
        'datecalc',
      ]);
      // Stopwatch and Focus match no chosen interest and are not staples.
      expect(ids(v), isNot(contains('stopwatch')));
      expect(ids(v), isNot(contains('focus')));
    });

    test('a recent tool survives it even without a matching interest', () {
      final LumeUserContext user = LumeUsers.defaultPk.copyWith(
        recents: <String>['stopwatch', 'focus'],
      );
      expect(ids(view(user)), contains('stopwatch'));
    });

    test('with nothing chosen there is nothing to shortlist *from*', () {
      // The prototype's own rule: "For you" with no interests matches no
      // category at all, and the empty state says to add some. It is only
      // reachable for a user who deselected everything, because onboarding
      // gives anyone who skips the seven defaults.
      final LumeToolsView v = view(LumeUsers.noInterestsPk);
      expect(ids(v), isEmpty);
      expect(v.empty, LumeToolsEmpty.shortlistEmpty);
      // And "All" is one tap away and shows the lot.
      expect(
        ids(view(LumeUsers.noInterestsPk, filter: LumeToolsFilter.all)),
        hasLength(68),
      );
    });

    test('the prototype\'s five blocks, at the prototype\'s sizes', () {
      final LumeToolsView v = view(LumeUsers.defaultPk);
      expect(
        <String, int>{
          for (final LumeToolGroup g in v.groups)
            g.category.id.name: g.tools.length,
        },
        <String, int>{
          'everyday': 6,
          'planning': 5,
          'money': 5,
          'daily': 8,
          'personal': 6,
        },
      );
    });
  });

  group('a category chip', () {
    test('shows one block and hides the rest', () {
      final LumeToolsView v = view(
        LumeUsers.defaultPk,
        filter: const LumeToolsFilter.category(LumeToolCategory.money),
      );
      expect(v.groups, hasLength(1));
      expect(v.groups.single.category.id, LumeToolCategory.money);
    });

    test('a chip that disappears takes its selection back to For you', () {
      // Switching the Islamic experience off removes the category under the
      // chip that selected it; a filter nothing can satisfy would be an empty
      // screen with no way out.
      final LumeToolsView v = view(
        LumeUsers.defaultPk,
        filter: const LumeToolsFilter.category(LumeToolCategory.islamic),
      );
      expect(v.filter, LumeToolsFilter.forYou);
      expect(v.groups, isNotEmpty);
    });
  });

  group('search', () {
    test('looks across the whole catalogue, whatever chip is on', () {
      // Being on "For you" must never stop someone finding a tool by name.
      for (final LumeToolsFilter f in <LumeToolsFilter>[
        LumeToolsFilter.forYou,
        LumeToolsFilter.all,
        const LumeToolsFilter.category(LumeToolCategory.personal),
      ]) {
        expect(
          ids(view(LumeUsers.defaultPk, filter: f, query: 'petrol')),
          <String>['fuel', 'fuelcost'],
        );
      }
    });

    test('matches a keyword nobody would guess from the name', () {
      expect(ids(view(LumeUsers.defaultPk, query: 'bijli')), <String>[
        'loadshed',
      ]);
      expect(ids(view(LumeUsers.muslimPk, query: 'namaz')), <String>['prayer']);
    });

    test('cannot reach a hidden tool', () {
      expect(ids(view(LumeUsers.defaultPk, query: 'namaz')), isEmpty);
      expect(ids(view(LumeUsers.defaultUs, query: 'bijli')), isEmpty);
    });

    test('is case- and space-insensitive at the edges', () {
      expect(ids(view(LumeUsers.defaultPk, query: '  PETROL ')), <String>[
        'fuel',
        'fuelcost',
      ]);
    });
  });

  group('the two kinds of nothing', () {
    test('a search that matched nothing', () {
      final LumeToolsView v = view(LumeUsers.defaultPk, query: 'zzzzz');
      expect(v.groups, isEmpty);
      expect(v.empty, LumeToolsEmpty.noMatch);
    });

    test('a shortlist with nothing in it says something different', () {
      final LumeToolsView v = view(LumeUsers.noInterestsPk);
      expect(v.empty, LumeToolsEmpty.shortlistEmpty);
      // A search over the same user is the other kind of nothing.
      expect(
        view(LumeUsers.noInterestsPk, query: 'zzzz').empty,
        LumeToolsEmpty.noMatch,
      );
    });

    test('an interest nothing declares still leaves the staples', () {
      final LumeUserContext odd = LumeUsers.defaultPk.copyWith(
        interests: const <String>{'sleep'},
      );
      expect(view(odd).empty, isNull, reason: 'the staples still qualify');
    });

    test('and nothing is empty when something matches', () {
      expect(view(LumeUsers.defaultPk).empty, isNull);
    });
  });

  group('recently used', () {
    test('hidden below two, because one pill is not a history', () {
      expect(view(LumeUsers.defaultPk).recents, isEmpty);
      expect(
        view(LumeUsers.defaultPk.copyWith(recents: <String>['notes'])).recents,
        isEmpty,
      );
      expect(
        view(LumeUsers.namedPk).recents.map((LumeFeature f) => f.id),
        <String>['calculator', 'weather', 'todos'],
      );
    });

    test('a hidden tool does not resurface through it', () {
      final LumeUserContext user = LumeUsers.defaultPk.copyWith(
        recents: <String>['quran', 'notes', 'calculator'],
      );
      expect(view(user).recents.map((LumeFeature f) => f.id), <String>[
        'notes',
        'calculator',
      ]);
    });
  });

  group('the hub on screen', () {
    testWidgets('renders the head, the chips and the first category', (
      WidgetTester tester,
    ) async {
      await pumpTools(tester, LumeUsers.defaultPk, surface: LumeViewport.tall);
      expect(find.text('Tools'), findsWidgets);
      expect(find.text('68 utilities, neatly sorted'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('tools.chip.foryou')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('tools.tile.calculator')),
        findsOneWidget,
      );
    });

    testWidgets('a chip narrows the catalogue', (WidgetTester tester) async {
      await pumpTools(tester, LumeUsers.defaultPk, surface: LumeViewport.tall);
      expect(
        find.byKey(const ValueKey<String>('tools.tile.stopwatch')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey<String>('tools.chip.all')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('tools.tile.stopwatch')),
        findsOneWidget,
      );
    });

    testWidgets('typing filters, and clearing restores', (
      WidgetTester tester,
    ) async {
      await pumpTools(tester, LumeUsers.defaultPk, surface: LumeViewport.tall);
      await tester.enterText(find.byType(TextField), 'petrol');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('tools.tile.fuel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('tools.tile.calculator')),
        findsNothing,
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('tools.tile.calculator')),
        findsOneWidget,
      );
    });

    testWidgets('a search with no matches says so', (
      WidgetTester tester,
    ) async {
      await pumpTools(tester, LumeUsers.defaultPk, surface: LumeViewport.tall);
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pumpAndSettle();

      expect(find.text('No tools match'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>(LumeToolsScreen.catalogueKey)),
        findsNothing,
      );
    });

    testWidgets('a tool opens itself, and only itself', (
      WidgetTester tester,
    ) async {
      final LumeRecordedActions actions = LumeRecordedActions();
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        actions: actions,
        surface: LumeViewport.tall,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('tools.tile.calculator')),
      );
      await tester.pumpAndSettle();
      expect(actions.tools, <String>['calculator']);
      expect(actions.destinations, isEmpty);
    });

    testWidgets('a sensitive tool wears a lock, a local one wears a dot', (
      WidgetTester tester,
    ) async {
      await pumpTools(
        tester,
        LumeUsers.defaultPk.copyWith(interests: const <String>{}),
        surface: LumeViewport.tall,
      );
      await tester.tap(find.byKey(const ValueKey<String>('tools.chip.all')));
      await tester.pumpAndSettle();

      LumeCatalogueTile tileOf(String id) => tester.widget<LumeCatalogueTile>(
        find.byKey(ValueKey<String>('tools.tile.$id')),
      );

      expect(tileOf('documents').marker, LumeTileMarker.private);
      expect(tileOf('loadshed').marker, LumeTileMarker.local);
      expect(tileOf('bills').marker, LumeTileMarker.count);
      expect(tileOf('calculator').marker, LumeTileMarker.none);
    });

    testWidgets('privacy outranks a count on the same corner', (
      WidgetTester tester,
    ) async {
      // Documents is sensitive *and* has two expiring records. The lock wins:
      // it is a promise, and the count can wait for the tool itself.
      await pumpTools(
        tester,
        LumeUsers.defaultPk.copyWith(interests: const <String>{}),
        surface: LumeViewport.tall,
      );
      await tester.tap(find.byKey(const ValueKey<String>('tools.chip.all')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeCatalogueTile>(
              find.byKey(const ValueKey<String>('tools.tile.documents')),
            )
            .marker,
        LumeTileMarker.private,
      );
    });
  });
}
