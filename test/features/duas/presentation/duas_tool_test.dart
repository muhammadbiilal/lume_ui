/// Daily Duas on screen: opened directly for a reader ([pumpLume]), not
/// through the real router — the same approach Qibla's own test takes
/// (`qibla_tool_test.dart`), because `tool_registry.dart` is a shared file
/// this wave leaves for the integration pass that wires every parallel tool
/// up at once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_reader.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/duas/presentation/duas_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _duasFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeDuasTool.id,
);

// `dayIndex` for 25 September 2026 lands on index 0 — `LumeDuaFixtures.all`'s
// first entry, "Morning remembrance" (Sahih Muslim 2723) — computed the same
// way `duas_fixtures_test` checks it, so the featured card in every test
// below is a known, fixed dua rather than whatever day the suite happens to
// run on.
final DateTime _fixtureDay = DateTime(2026, 9, 25);

Future<void> pumpDuas(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(islamic: true),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3000),
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeDuasTool(
      request: LumeToolRequest(
        feature: _duasFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    now: _fixtureDay,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

void main() {
  group('the catalogue entry', () {
    test('is faith-gated, the way every Islamic tool must be', () {
      expect(_duasFeature.faith, isTrue);
    });
  });

  group('a Muslim reader', () {
    testWidgets('sees the day\'s dua, its real Arabic and its citation', (
      WidgetTester tester,
    ) async {
      await pumpDuas(tester);

      expect(find.byKey(LumeDuasTool.readerKey), findsOneWidget);
      final LumeReaderCard card = tester.widget(
        find.byKey(LumeDuasTool.readerKey),
      );
      expect(card.reference, contains('Morning remembrance'));
      expect(
        card.body,
        'We have entered the morning and the dominion belongs to God.',
      );
      expect(card.byline, 'Sahih Muslim 2723');
      // English is the reader's own language: no fallback note.
      expect(find.byKey(LumeReaderCard.noteKey), findsNothing);
    });

    testWidgets('an Arabic reader is shown the real Arabic, not English', (
      WidgetTester tester,
    ) async {
      await pumpDuas(tester, locale: const Locale('ar'));
      final LumeReaderCard card = tester.widget(
        find.byKey(LumeDuasTool.readerKey),
      );
      expect(card.body, 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ');
      expect(card.bodyDirection, TextDirection.rtl);
      expect(
        Directionality.of(tester.element(find.byKey(LumeReaderCard.bodyKey))),
        TextDirection.rtl,
      );
      // Arabic is the reader's own language here too: no fallback note.
      expect(find.byKey(LumeReaderCard.noteKey), findsNothing);
    });

    testWidgets('an Urdu reader is shown the English, labelled as a fallback', (
      WidgetTester tester,
    ) async {
      await pumpDuas(tester, locale: const Locale('ur'));
      final LumeReaderCard card = tester.widget(
        find.byKey(LumeDuasTool.readerKey),
      );
      expect(card.body, contains('We have entered the morning'));
      expect(find.byKey(LumeReaderCard.noteKey), findsOneWidget);
    });

    testWidgets('the categories show their real counts, not the reference\'s '
        'inflated ones — "Daily life" has none of the five duas at all', (
      WidgetTester tester,
    ) async {
      await pumpDuas(tester);
      final List<LumeFilterChip> chips = tester
          .widgetList<LumeFilterChip>(
            inKey(LumeDuasTool.filterKey, find.byType(LumeFilterChip)),
          )
          .toList();
      // "All", then the six categories the reference declares.
      expect(chips, hasLength(7));
      final Map<String, int?> counts = <String, int?>{
        for (final LumeFilterChip c in chips) c.label: c.count,
      };
      expect(counts['Morning & evening'], 1);
      expect(counts['Daily life'], 0);
      expect(counts['Travel'], 1);
      expect(counts['Distress & worry'], 1);
      expect(counts['Food & drink'], 1);
      expect(counts['Sleep'], 1);
    });

    testWidgets('a category narrows the browse list to its real duas', (
      WidgetTester tester,
    ) async {
      await pumpDuas(tester);
      // The filter bar is its own horizontal scroller (`LumeFilterBar`); at
      // 390 points wide, "Travel" starts outside the initial viewport.
      await tester.ensureVisible(
        inKey(LumeDuasTool.filterKey, find.text('Travel')),
      );
      await tester.tap(inKey(LumeDuasTool.filterKey, find.text('Travel')));
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<LumeRichRow>(
          inKey(LumeDuasTool.browseKey, find.byType(LumeRichRow)),
        ),
        hasLength(1),
      );
    });

    testWidgets(
      '"Daily life" narrows to nothing, honestly — the reference has none',
      (WidgetTester tester) async {
        await pumpDuas(tester);
        // Same horizontal-scroller reality as above — "Daily life" also
        // starts outside the initial viewport.
        await tester.ensureVisible(
          inKey(LumeDuasTool.filterKey, find.text('Daily life')),
        );
        await tester.tap(
          inKey(LumeDuasTool.filterKey, find.text('Daily life')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(LumeDuasTool.browseKey), findsNothing);
        expect(find.byKey(LumeDuasTool.emptyKey), findsOneWidget);
      },
    );

    testWidgets('a search finds a dua by its English rendering', (
      WidgetTester tester,
    ) async {
      await pumpDuas(tester);
      await tester.enterText(find.byKey(LumeDuasTool.searchKey), 'anxiety');
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<LumeRichRow>(
          inKey(LumeDuasTool.browseKey, find.byType(LumeRichRow)),
        ),
        hasLength(1),
      );
      await tester.enterText(find.byKey(LumeDuasTool.searchKey), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byKey(LumeDuasTool.emptyKey), findsOneWidget);
    });

    testWidgets('a search finds a dua by its title, as the reference’s '
        '`title + tr` does', (WidgetTester tester) async {
      await pumpDuas(tester);
      // "travel" is only in the title — the translation reads "Glory to Him
      // who has subjected this to us".
      await tester.enterText(find.byKey(LumeDuasTool.searchKey), 'travel');
      await tester.pumpAndSettle();
      expect(
        inKey(LumeDuasTool.browseKey, find.text('Dua for travel')),
        findsOneWidget,
      );
    });

    testWidgets(
      'opening a dua shows its own real Arabic, translation and citation, '
      'and offers to share it',
      (WidgetTester tester) async {
        await pumpDuas(tester);
        await tester.tap(
          inKey(LumeDuasTool.browseKey, find.text('Before eating')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(LumeDuasTool.detailKey), findsOneWidget);
        final LumeReaderCard detail = tester.widget(
          find.byKey(LumeDuasTool.detailKey),
        );
        expect(detail.reference, 'Sunan Abi Dawud 3767');
        expect(detail.body, 'In the name of God.');
        expect(find.byKey(LumeDuasTool.detailShareKey), findsOneWidget);
      },
    );
  });

  group('a non-Muslim reader', () {
    testWidgets(
      'never sees a dua — the frame itself blocks a faith-gated tool\'s '
      'body, defence in depth over the catalogue gate alone (§64)',
      (WidgetTester tester) async {
        await pumpDuas(tester, user: const LumeUserContext(islamic: false));
        expect(find.byKey(LumeDuasTool.readerKey), findsNothing);
        expect(find.byKey(LumeDuasTool.browseKey), findsNothing);
        expect(find.byKey(LumeDuasTool.filterKey), findsNothing);
      },
    );
  });
}
