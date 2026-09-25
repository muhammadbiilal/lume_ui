/// Mobile Packages on screen: opened directly for a reader ([pumpPackages]),
/// not through the real router.
///
/// Unlike most converted tools, this pumps [LumePackagesTool] directly rather
/// than through `LumeRoutes.tool(...)`: the shared `tool_registry.dart` this
/// repository routes through is out of scope for this change (the same
/// approach Qibla's own harness takes, `qibla_tool_test.dart`). The screen
/// itself is exercised exactly as the router would host it, with the same
/// provider overrides and the same clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/packages/data/packages_fixtures.dart';
import 'package:lume/features/packages/presentation/packages_tool.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature _packagesFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumePackagesTool.id,
);

/// The catalogue entry with its `countries: {'PK'}` gate lifted.
///
/// Every real reader is refused this tool by [_packagesFeature]'s own
/// eligibility before the widget's body is ever built (§64's frame gate,
/// exactly as Qibla's faith gate refuses a non-Muslim reader) — a test that
/// pumps the real feature for a US reader would only be exercising that
/// shared, already-tested gate. This copy exists to reach the tool's *own*
/// defensive fallback instead: what it draws if it were ever reached for a
/// market its fixture data does not cover (`LumeMobilePackages.forCountry`
/// returning `null`), which is the scenario the reference itself guards
/// against (`if (!list) return … emptyState`).
final LumeFeature _globalPackagesFeature = LumeFeature(
  id: _packagesFeature.id,
  fallbackName: _packagesFeature.fallbackName,
  icon: _packagesFeature.icon,
  category: _packagesFeature.category,
  group: _packagesFeature.group,
);

Future<void> pumpPackages(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  LumeFeature? feature,
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
    LumePackagesTool(
      request: LumeToolRequest(
        feature: feature ?? _packagesFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

List<String> _tableFirstColumn(WidgetTester tester) => tester
    .widget<LumeTable>(find.byKey(LumePackagesTool.tableKey))
    .rows
    .map((List<String> r) => r.first)
    .toList();

void main() {
  group('the catalogue entry', () {
    test('is Pakistan-only, not a global feature', () {
      expect(_packagesFeature.countries, <String>{'PK'});
      expect(_packagesFeature.faith, isFalse);
    });
  });

  group('a Pakistani reader', () {
    testWidgets('sees the real, named carrier bundles — never placeholder '
        'data', (WidgetTester tester) async {
      await pumpPackages(tester);

      expect(find.byKey(LumePackagesTool.unavailableKey), findsNothing);
      expect(find.byKey(LumePackagesTool.tableKey), findsOneWidget);
      // Sorted by price, ascending, by default — the reference's own
      // `c.sortBy(shown, {...}, 'price', 'asc')` — not the fixture's order.
      expect(
        _tableFirstColumn(tester),
        <String>[
          'Telenor · Super Card',
          'Ufone · Super Card Plus',
          'Jazz · Super Duper Card',
          'Zong · Super Card Max',
        ],
      );

      // One filter chip for "All" plus one per named carrier.
      final LumeFilterBar bar = tester.widget(
        find.byKey(LumePackagesTool.filterKey),
      );
      expect(bar.children, hasLength(5));

      expect(find.byKey(LumePackagesTool.detailKey), findsOneWidget);
      expect(
        tester.widgetList<LumeExpandRow>(find.byType(LumeExpandRow)),
        hasLength(4),
      );
    });

    testWidgets('sorts by price, ascending, by default — the cheapest bundle '
        'first', (WidgetTester tester) async {
      await pumpPackages(tester);
      final List<LumeMobilePackage> pk = LumeMobilePackages.forCountry('PK')!;
      final int cheapest = pk
          .map((LumeMobilePackage p) => p.price)
          .reduce((int a, int b) => a < b ? a : b);
      expect(cheapest, 1000); // Telenor
      expect(_tableFirstColumn(tester).first, contains('Telenor'));
    });

    testWidgets('a query narrows both the compare table and the detail list',
        (WidgetTester tester) async {
      await pumpPackages(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(LumePackagesTool.searchKey),
          matching: find.byType(EditableText),
        ),
        'zong',
      );
      await tester.pumpAndSettle();
      expect(_tableFirstColumn(tester), <String>['Zong · Super Card Max']);
      expect(
        tester.widgetList<LumeExpandRow>(find.byType(LumeExpandRow)),
        hasLength(1),
      );
    });

    testWidgets('a query that matches nothing shows the honest no-match '
        'state, not an empty table', (WidgetTester tester) async {
      await pumpPackages(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(LumePackagesTool.searchKey),
          matching: find.byType(EditableText),
        ),
        'zzz-no-such-carrier',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumePackagesTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumePackagesTool.tableKey), findsNothing);
      expect(find.byKey(LumePackagesTool.detailKey), findsNothing);
    });
  });

  group('a reader outside Pakistan', () {
    testWidgets('never sees the tool at all — the frame itself blocks a '
        "country-gated tool's body, defence in depth over the catalogue "
        'gate alone (§64)', (WidgetTester tester) async {
      await pumpPackages(
        tester,
        user: const LumeUserContext(country: 'US', city: 'New York'),
      );
      // The catalogue's own gate already refuses this reader, so the tool's
      // body — search, filters, table, detail, and even its own internal
      // unavailable state — is never built into the tree.
      expect(find.byKey(LumePackagesTool.searchKey), findsNothing);
      expect(find.byKey(LumePackagesTool.filterKey), findsNothing);
      expect(find.byKey(LumePackagesTool.sortKey), findsNothing);
      expect(find.byKey(LumePackagesTool.tableKey), findsNothing);
      expect(find.byKey(LumePackagesTool.detailKey), findsNothing);
      expect(find.byKey(LumePackagesTool.unavailableKey), findsNothing);
      // The frame draws its own generic refusal instead.
      expect(find.byType(LumeToolState), findsOneWidget);
    });

    testWidgets("the tool's own fallback still holds if it were ever "
        'reached for a market its fixture data does not cover — it draws '
        'the honest unavailable state rather than crash or invent data '
        '(the same guard the reference itself keeps)', (
      WidgetTester tester,
    ) async {
      await pumpPackages(
        tester,
        user: const LumeUserContext(country: 'US', city: 'New York'),
        feature: _globalPackagesFeature,
      );
      expect(find.byKey(LumePackagesTool.unavailableKey), findsOneWidget);
      expect(find.byKey(LumePackagesTool.tableKey), findsNothing);
      expect(find.byKey(LumePackagesTool.detailKey), findsNothing);
      expect(find.byKey(LumePackagesTool.searchKey), findsNothing);

      final LumeToolState state = tester.widget(
        find.byKey(LumePackagesTool.unavailableKey),
      );
      expect(state.title, isNotEmpty);
      expect(state.text, isNotEmpty);

      // Leaving, and coming back, does not crash — the regression this test
      // was written for (a `late final` touched for the first time inside
      // `dispose`, after the widget can no longer read its providers).
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('a non-English locale', () {
    testWidgets('still renders the real bundles, in Urdu, right to left', (
      WidgetTester tester,
    ) async {
      await pumpPackages(tester, locale: const Locale('ur'));
      expect(find.byKey(LumePackagesTool.tableKey), findsOneWidget);
      // Carrier and bundle names are proper nouns — never translated.
      expect(find.textContaining('Jazz'), findsWidgets);
      expect(
        Directionality.of(tester.element(find.byKey(LumePackagesTool.tableKey))),
        TextDirection.rtl,
      );
    });
  });
}
