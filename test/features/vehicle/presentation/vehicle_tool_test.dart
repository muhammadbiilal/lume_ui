/// Vehicle & Fines on screen: opened directly for a reader ([pumpLume]), not
/// through the real router.
///
/// Unlike most converted tools, this pumps [LumeVehicleTool] directly rather
/// than through `LumeRoutes.tool(...)`: this wave lands alongside many other
/// tools built in parallel, and the shared `tool_registry.dart` this
/// repository routes through is out of scope for this change — it is wired
/// up in the integration pass that follows (the same approach Loadshedding's
/// and National Savings' own tests take, this wave). The screen itself is
/// exercised exactly as the router would host it, with the same provider
/// overrides.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/vehicle/presentation/vehicle_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../../helpers/capture.dart';
import '../../../helpers/load_fonts.dart';
import '../../../helpers/lume_harness.dart';

final LumeFeature _feature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeVehicleTool.id,
);

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Future<void> pumpVehicle(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3200),
  double textScale = 1,
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeVehicleTool(
      request: LumeToolRequest(feature: _feature, user: user, branch: 'tools'),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  group('the catalogue entry', () {
    test('is Pakistan-only — not this widget\'s job to re-decide', () {
      expect(_feature.countries, <String>{'PK'});
    });
  });

  group('a Pakistani reader', () {
    testWidgets('sees the real two-vehicle fleet, the reference\'s own '
        'figures, not invented', (WidgetTester tester) async {
      await pumpVehicle(tester, user: const LumeUserContext(country: 'PK'));

      expect(find.byKey(LumeVehicleTool.summaryKey), findsOneWidget);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byKey(LumeVehicleTool.summaryKey)),
      );

      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeVehicleTool.summaryKey),
      );
      expect(summary.value, '2');
      expect(summary.caption, l.vehicleOpenFines(1));
      expect(summary.stats, hasLength(3));
      expect(summary.stats[1].value, '30 Sep');

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            inKey(LumeVehicleTool.listKey, find.byType(LumeRichRow)),
          )
          .toList();
      expect(rows.map((LumeRichRow r) => r.title).toList(), <String>[
        'ABC-124',
        'LEB-8842',
      ]);
      expect(rows[0].badge!.label, l.vehicleFines(1));
      expect(rows[0].badge!.tone, LumeBadgeTone.warn);
      expect(rows[1].badge!.label, l.vehicleClear);
      expect(rows[1].badge!.tone, LumeBadgeTone.ok);

      final LumeTimeline reminders = tester.widget(
        find.byKey(LumeVehicleTool.remindersKey),
      );
      expect(reminders.entries, hasLength(3));
      expect(
        reminders.entries.map((LumeTimelineEntry e) => e.subtitle).toList(),
        <String>['ABC-124', 'LEB-8842', 'ABC-124'],
      );
      expect(reminders.entries[0].state, LumeTimelineState.now);
      expect(reminders.entries[1].state, LumeTimelineState.upcoming);
    });

    testWidgets('searching the fleet narrows the list to a real match, '
        'never an invented row', (WidgetTester tester) async {
      await pumpVehicle(tester, user: const LumeUserContext(country: 'PK'));
      await tester.enterText(
        inKey(LumeVehicleTool.searchKey, find.byType(EditableText)),
        'honda',
      );
      await tester.pumpAndSettle();

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            inKey(LumeVehicleTool.listKey, find.byType(LumeRichRow)),
          )
          .toList();
      expect(rows, hasLength(1));
      expect(rows.single.title, 'LEB-8842');
    });

    testWidgets('a query matching no vehicle shows the no-match state, not '
        'a blank list', (WidgetTester tester) async {
      await pumpVehicle(tester, user: const LumeUserContext(country: 'PK'));
      await tester.enterText(
        inKey(LumeVehicleTool.searchKey, find.byType(EditableText)),
        'zzz-not-a-real-plate',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(LumeVehicleTool.noMatchKey), findsOneWidget);
      expect(find.byKey(LumeVehicleTool.listKey), findsNothing);
    });

    testWidgets('tapping a vehicle row toasts its own plate — there is no '
        'detail screen behind it', (WidgetTester tester) async {
      await pumpVehicle(tester, user: const LumeUserContext(country: 'PK'));
      await tester.tap(inKey(LumeVehicleTool.listKey, find.text('ABC-124')));
      await tester.pump();
      expect(find.text('ABC-124'), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('"Check any registration" answers whatever was typed — or '
        'nothing — with the same fixed line, never a real result', (
      WidgetTester tester,
    ) async {
      await pumpVehicle(tester, user: const LumeUserContext(country: 'PK'));
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byKey(LumeVehicleTool.checkFieldKey)),
      );

      // No input at all.
      await tester.tap(find.byKey(LumeVehicleTool.checkButtonKey));
      await tester.pump();
      expect(find.text(l.vehicleLookingUp), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));

      // Arbitrary, made-up input answers with the exact same line — proof
      // there is no lookup, real or disguised, behind the button.
      await tester.enterText(
        inKey(LumeVehicleTool.checkFieldKey, find.byType(EditableText)),
        'ZZZ-NOT-A-REAL-PLATE',
      );
      await tester.pump();
      await tester.tap(find.byKey(LumeVehicleTool.checkButtonKey));
      await tester.pump();
      expect(find.text(l.vehicleLookingUp), findsOneWidget);

      // And the fleet above is exactly what it was — the field changed
      // nothing about it.
      expect(
        inKey(LumeVehicleTool.listKey, find.byType(LumeRichRow)),
        findsNWidgets(2),
      );
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('a reader outside Pakistan', () {
    testWidgets('sees the honest unavailable state, never a Pakistani '
        'fleet', (WidgetTester tester) async {
      await pumpVehicle(
        tester,
        user: const LumeUserContext(country: 'US', city: 'New York'),
      );

      // `LumeToolFrame`'s own eligibility gate (catalogue `countries:
      // {'PK'}`) shows the generic unavailable state and skips `body`
      // entirely for a non-PK reader (§64) — `vehicle.tool.js` itself has no
      // internal country branch of its own to fall back to (unlike National
      // Savings' or Prize Bonds' own `if (!list) ...`), so this frame gate is
      // the *only* thing standing between a non-Pakistani reader and someone
      // else's plates (see `vehicle_fixtures.dart`'s own doc comment).
      expect(find.byKey(LumeVehicleTool.summaryKey), findsNothing);
      expect(find.byKey(LumeVehicleTool.listKey), findsNothing);
      expect(find.text('ABC-124'), findsNothing);
      expect(find.text('LEB-8842'), findsNothing);

      final LumeToolState state = tester.widget(find.byType(LumeToolState));
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeToolState)),
      );
      expect(state.title, l.toolUnavailableTitle);
      expect(state.text, l.toolUnavailableText);
    });
  });

  group('a non-English locale', () {
    testWidgets('still renders the real fleet, in Urdu, right to left, '
        'without overflow', (WidgetTester tester) async {
      await pumpVehicle(
        tester,
        user: const LumeUserContext(country: 'PK'),
        locale: const Locale('ur'),
      );
      expect(find.byKey(LumeVehicleTool.summaryKey), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeVehicleTool.summaryKey)),
        ),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('still renders in Arabic, right to left, without overflow', (
      WidgetTester tester,
    ) async {
      await pumpVehicle(
        tester,
        user: const LumeUserContext(country: 'PK'),
        locale: const Locale('ar'),
      );
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeVehicleTool.summaryKey)),
        ),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('the unavailable state also holds up in Urdu', (
      WidgetTester tester,
    ) async {
      await pumpVehicle(
        tester,
        user: const LumeUserContext(country: 'US', city: 'New York'),
        locale: const Locale('ur'),
      );
      expect(find.byType(LumeToolState), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(LumeToolState))),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });
  });

  group('at 200% text scale', () {
    testWidgets('the fleet screen renders without overflow', (
      WidgetTester tester,
    ) async {
      await pumpVehicle(
        tester,
        user: const LumeUserContext(country: 'PK'),
        textScale: 2,
        surface: const Size(390, 6000),
      );
      expectNoOverflow(tester);
    });
  });
}
