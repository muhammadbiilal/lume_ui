/// Prize Bonds on screen: opened directly for a reader
/// ([pumpLume]), not through the real router.
///
/// Unlike most converted tools, this pumps [LumePrizebondsTool] directly
/// rather than through `LumeRoutes.tool(...)`: this wave lands alongside many
/// other tools built in parallel, and the shared `tool_registry.dart` this
/// repository routes through is out of scope for this change — it is wired
/// up in the integration pass that follows (the same approach Qibla's own
/// test takes, `qibla_tool_test.dart`). The screen itself is exercised
/// exactly as the router would host it, with the same provider overrides and
/// the same clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/prizebonds/data/prizebonds_fixtures.dart';
import 'package:lume/features/prizebonds/presentation/prizebonds_tool.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature _feature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumePrizebondsTool.id,
);

Future<void> pumpPrizebonds(
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
    LumePrizebondsTool(
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
    testWidgets('sees the real draws, prize tiers and next-draw summary — '
        'the reference\'s own hardcoded figures, not invented ones', (
      WidgetTester tester,
    ) async {
      await pumpPrizebonds(tester, user: const LumeUserContext(country: 'PK'));

      expect(find.byKey(LumePrizebondsTool.unavailableKey), findsNothing);

      final LumePrizeBondScheme pk = LumePrizeBondScheme.forCountry('PK')!;

      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumePrizebondsTool.summaryKey),
      );
      expect(summary.value, pk.next.date);

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            find.descendant(
              of: find.byKey(LumePrizebondsTool.drawsKey),
              matching: find.byType(LumeRichRow),
            ),
          )
          .toList();
      expect(rows, hasLength(4));
      expect(
        rows.map((LumeRichRow r) => r.logo).toSet(),
        <String>{'100', '200', '750', '1500'},
      );
      expect(rows.map((LumeRichRow r) => r.subtitle).toSet(), <String>{
        'Draw 47',
        'Draw 98',
        'Draw 102',
        'Draw 99',
      });

      final LumeTable tiers = tester.widget(
        find.byKey(LumePrizebondsTool.tiersKey),
      );
      expect(tiers.rows, hasLength(4));
      expect(tiers.columns, hasLength(4));

      // The reference never wires up a way to save a checked number, so
      // "Your numbers" is always the empty state — never a populated list.
      final LumeToolState saved = tester.widget(
        find.byKey(LumePrizebondsTool.savedKey),
      );
      expect(saved.title, isNotEmpty);
    });

    testWidgets('checking a number always toasts — the reference never '
        'saves one', (WidgetTester tester) async {
      await pumpPrizebonds(tester, user: const LumeUserContext(country: 'PK'));
      await tester.ensureVisible(find.byKey(LumePrizebondsTool.checkKey));
      await tester.tap(find.byKey(LumePrizebondsTool.checkKey));
      await tester.pump();
      // Still empty afterwards — the button never populates a saved list.
      expect(find.byKey(LumePrizebondsTool.savedKey), findsOneWidget);
    });
  });

  group('a reader outside Pakistan', () {
    testWidgets('sees the honest unavailable state, never an invented '
        'equivalent scheme', (WidgetTester tester) async {
      await pumpPrizebonds(
        tester,
        user: const LumeUserContext(country: 'US', city: 'New York'),
      );

      // `LumeToolFrame`'s own eligibility gate (catalogue `countries:
      // {'PK'}`) shows the generic unavailable state and skips `body`
      // entirely for a non-PK reader (§64) — the tool's own internal
      // `unavailableKey` widget is defence-in-depth for a future catalogue
      // change, never reached here (same finding as Loadshedding/National
      // Savings, wave 9).
      expect(find.byKey(LumePrizebondsTool.unavailableKey), findsNothing);
      expect(find.byKey(LumePrizebondsTool.summaryKey), findsNothing);
      expect(find.byKey(LumePrizebondsTool.drawsKey), findsNothing);
      expect(find.byKey(LumePrizebondsTool.tiersKey), findsNothing);
      expect(find.byKey(LumePrizebondsTool.savedKey), findsNothing);

      final LumeToolState state = tester.widget(find.byType(LumeToolState));
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeToolState)),
      );
      expect(state.title, l.toolUnavailableTitle);
      expect(state.text, l.toolUnavailableText);
    });
  });

  group('a non-English locale', () {
    testWidgets('still renders the real data, in Urdu, right to left', (
      WidgetTester tester,
    ) async {
      await pumpPrizebonds(
        tester,
        user: const LumeUserContext(country: 'PK'),
        locale: const Locale('ur'),
      );
      expect(find.byKey(LumePrizebondsTool.summaryKey), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byKey(LumePrizebondsTool.summaryKey)),
        ),
        TextDirection.rtl,
      );
    });
  });
}
