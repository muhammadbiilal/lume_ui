/// National Savings on screen: opened directly for a reader ([pumpLume]),
/// not through the real router.
///
/// Unlike most converted tools, this pumps [LumeNatSavingsTool] directly
/// rather than through `LumeRoutes.tool(...)`: this wave lands alongside many
/// other tools built in parallel, and the shared `tool_registry.dart` this
/// repository routes through is out of scope for this change — it is wired
/// up in the integration pass that follows (the same approach Prize Bonds'
/// own test takes, `prizebonds_tool_test.dart`). The screen itself is
/// exercised exactly as the router would host it, with the same provider
/// overrides and the same clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/natsavings/data/natsavings_fixtures.dart';
import 'package:lume/features/natsavings/presentation/natsavings_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature _feature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeNatSavingsTool.id,
);

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Future<void> pumpNatSavings(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
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
    LumeNatSavingsTool(
      request: LumeToolRequest(feature: _feature, user: user, branch: 'tools'),
    ),
    locale: locale,
    surface: surface,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the catalogue entry', () {
    test('is Pakistan-only — not this widget\'s job to re-decide', () {
      expect(_feature.countries, <String>{'PK'});
    });
  });

  group('a Pakistani reader', () {
    testWidgets('sees the real certificates — the reference\'s own hardcoded '
        'figures, not invented ones', (WidgetTester tester) async {
      await pumpNatSavings(tester, user: const LumeUserContext(country: 'PK'));

      expect(find.byKey(LumeNatSavingsTool.unavailableKey), findsNothing);

      final LumeNatSavingsScheme pk = LumeNatSavingsScheme.forCountry('PK')!;

      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeNatSavingsTool.summaryKey),
      );
      expect(summary.caption, pk.best.name);
      expect(summary.value, '15.36%');

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumeNatSavingsTool.listKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      expect(rows, hasLength(5));
      expect(rows.map((LumeRichRow r) => r.title).toSet(), <String>{
        for (final LumeSavingsInstrument p in pk.instruments) p.name,
      });

      // Default sort is by rate, descending — Behbood (15.36) leads.
      expect(rows.first.title, 'Behbood Savings Certificate');
    });

    testWidgets('searching narrows the list to a real match, never an empty '
        'or invented row', (WidgetTester tester) async {
      await pumpNatSavings(tester, user: const LumeUserContext(country: 'PK'));
      await tester.enterText(
        inKey(LumeNatSavingsTool.searchKey, find.byType(EditableText)),
        'pensioners',
      );
      await tester.pumpAndSettle();

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumeNatSavingsTool.listKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      expect(rows, hasLength(1));
      expect(rows.single.title, 'Pensioners’ Benefit Account');
    });

    testWidgets('a query matching nothing shows the no-match state, not a '
        'blank list', (WidgetTester tester) async {
      await pumpNatSavings(tester, user: const LumeUserContext(country: 'PK'));
      await tester.enterText(
        inKey(LumeNatSavingsTool.searchKey, find.byType(EditableText)),
        'zzz',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeNatSavingsTool.noMatchKey), findsOneWidget);
      expect(find.byKey(LumeNatSavingsTool.listKey), findsNothing);
    });

    testWidgets('the sort bar reorders the real rows, by a real dimension', (
      WidgetTester tester,
    ) async {
      await pumpNatSavings(tester, user: const LumeUserContext(country: 'PK'));
      // 'Minimum' also names a stat label on every row — tap the sort bar's
      // own chip, by scoping to its key.
      await tester.tap(
        inKey(LumeNatSavingsTool.sortKey, find.text('Minimum')),
      );
      await tester.pumpAndSettle();

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumeNatSavingsTool.listKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      // Minimum, descending on first press (a fresh dimension starts there):
      // Regular Income (50,000) leads.
      expect(rows.first.title, 'Regular Income Certificate');
    });

    testWidgets('picking a product changes the estimate\'s figures', (
      WidgetTester tester,
    ) async {
      await pumpNatSavings(
        tester,
        user: const LumeUserContext(country: 'PK'),
        surface: const Size(390, 5000),
      );
      final LumeSegmented seg = tester.widget(
        find.byKey(LumeNatSavingsTool.productKey),
      );
      // Starts on the best rate, exactly as the reference's own
      // `value: best.name` default does.
      expect(seg.value, 'Behbood Savings Certificate');

      await tester.ensureVisible(find.byKey(LumeNatSavingsTool.productKey));
      // The same name also titles the row in the products list above — tap
      // the segmented picker's own option, by scoping to its key.
      await tester.tap(
        inKey(LumeNatSavingsTool.productKey, find.text('Special Savings Certificate')),
      );
      await tester.pumpAndSettle();

      final LumeSegmented after = tester.widget(
        find.byKey(LumeNatSavingsTool.productKey),
      );
      expect(after.value, 'Special Savings Certificate');
    });
  });

  group('a reader outside Pakistan', () {
    testWidgets('sees the honest unavailable state, never an invented '
        'equivalent scheme', (WidgetTester tester) async {
      await pumpNatSavings(
        tester,
        user: const LumeUserContext(country: 'US', city: 'New York'),
      );

      // `LumeToolFrame`'s own eligibility gate (catalogue `countries:
      // {'PK'}`) shows the generic unavailable state and skips `body`
      // entirely for a non-PK reader (§64) — the tool's own internal
      // `unavailableKey` widget is defence-in-depth for a future catalogue
      // change, never reached here (same finding as Loadshedding/Prize
      // Bonds, wave 9).
      expect(find.byKey(LumeNatSavingsTool.unavailableKey), findsNothing);
      expect(find.byKey(LumeNatSavingsTool.summaryKey), findsNothing);
      expect(find.byKey(LumeNatSavingsTool.listKey), findsNothing);
      expect(find.text('Behbood Savings Certificate'), findsNothing);

      final LumeToolState state = tester.widget(find.byType(LumeToolState));
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeToolState)),
      );
      expect(state.title, l.toolUnavailableTitle);
      expect(state.text, l.toolUnavailableText);
    });

    testWidgets('a UK reader sees no Pakistani certificate either', (
      WidgetTester tester,
    ) async {
      await pumpNatSavings(
        tester,
        user: const LumeUserContext(country: 'GB', city: 'London'),
      );
      expect(find.byType(LumeToolState), findsOneWidget);
      for (final String name in <String>[
        'Behbood Savings Certificate',
        'Defence Savings Certificate',
        'Regular Income Certificate',
        'Special Savings Certificate',
      ]) {
        expect(find.text(name), findsNothing);
      }
    });
  });

  group('a non-English locale', () {
    testWidgets('still renders the real data, in Urdu, right to left', (
      WidgetTester tester,
    ) async {
      await pumpNatSavings(
        tester,
        user: const LumeUserContext(country: 'PK'),
        locale: const Locale('ur'),
      );
      expect(find.byKey(LumeNatSavingsTool.summaryKey), findsOneWidget);
      expect(find.byKey(LumeNatSavingsTool.unavailableKey), findsNothing);
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeNatSavingsTool.summaryKey)),
        ),
        TextDirection.rtl,
      );
      // The certificate's own name is never translated by the reference —
      // it still reads in English inside an RTL frame.
      expect(find.text('Behbood Savings Certificate'), findsWidgets);
    });

    testWidgets('the unavailable state also holds up in Urdu', (
      WidgetTester tester,
    ) async {
      await pumpNatSavings(
        tester,
        user: const LumeUserContext(country: 'US', city: 'New York'),
        locale: const Locale('ur'),
      );
      expect(find.byType(LumeToolState), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(LumeToolState))),
        TextDirection.rtl,
      );
    });
  });
}
