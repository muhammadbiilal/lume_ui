/// "Use my current location" on screen: in onboarding the place found is
/// offered as the city step's selection; in the location sheet it is saved,
/// as a tapped city is. Every refusal says why and changes nothing.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/platform/lume_locator.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/presentation/account_host.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';
import 'package:lume/features/onboarding/data/interests_fixture.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/presentation/onboarding_flow.dart';
import 'package:lume/features/onboarding/presentation/onboarding_chrome.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../account/account_harness.dart';

const LumeLocateResult _london = LumeLocateResult.located(51.50, -0.12);

void main() {
  setUpAll(loadLumeFonts);

  final LumeCountryFixture countries = LumeCountryFixture.parse(
    File('assets/data/countries.json').readAsStringSync(),
  );
  final LumeInterestsFixture catalogue = LumeInterestsFixture.parse(
    File('assets/data/interests.json').readAsStringSync(),
  );

  group('onboarding — the city step', () {
    late LumeMemoryOnboardingStore store;

    Future<LumeRecordingLocator> pumpCity(
      WidgetTester tester, {
      required LumeLocateResult result,
      Locale locale = const Locale('en'),
      double textScale = 1.0,
    }) async {
      store = LumeMemoryOnboardingStore();
      final LumeRecordingLocator locator = LumeRecordingLocator(result: result);
      await pumpLume(
        tester,
        LumeOnboardingFlow(
          countries: countries,
          catalogue: catalogue,
          store: store,
          initialStep: LumeOnboardingStep.city,
          locator: locator,
        ),
        surface: LumeViewport.tall,
        locale: locale,
        textScale: textScale,
      );
      return locator;
    }

    LumeOnboardingFlowState flow(WidgetTester tester) =>
        tester.state<LumeOnboardingFlowState>(find.byType(LumeOnboardingFlow));

    testWidgets('a position is offered as the selection, in its own country, '
        'and Continue saves it', (WidgetTester tester) async {
      final LumeRecordingLocator locator = await pumpCity(
        tester,
        result: _london,
      );
      expect(flow(tester).draft.country, 'PK');

      await tester.tap(find.text('Use my current location'));
      await tester.pumpAndSettle();

      expect(locator.requests, 1);
      expect(flow(tester).draft.country, 'GB');
      expect(flow(tester).draft.city, 'London');
      expect(flow(tester).draft.region, 'England');
      // The step now shows the country found, not the one chosen before.
      // (The kicker is drawn uppercase, as `.onb__kicker` is.)
      expect(find.text('UNITED KINGDOM'), findsOneWidget);
      // Offered, not committed: nothing is stored until Continue.
      expect(store.read().country, 'PK');

      await tester.tap(find.byType(LumeOnboardingContinue));
      await tester.pumpAndSettle();
      expect(
        (store.read().country, store.read().city, store.read().region),
        ('GB', 'London', 'England'),
      );
    });

    final Map<LumeLocateOutcome, String> said = <LumeLocateOutcome, String>{
      LumeLocateOutcome.denied:
          "Location wasn't allowed — choose your city by hand.",
      LumeLocateOutcome.blocked:
          "Location is off for Lume in your phone's Settings — choose your "
          'city by hand.',
      LumeLocateOutcome.serviceOff:
          'Location is switched off on this device — choose your city by '
          'hand.',
      LumeLocateOutcome.failed:
          'Location unavailable — choose your city by hand.',
    };
    said.forEach((LumeLocateOutcome outcome, String text) {
      testWidgets('${outcome.name}: says so, and changes nothing', (
        WidgetTester tester,
      ) async {
        await pumpCity(tester, result: LumeLocateResult.refused(outcome));
        await tester.tap(find.text('Use my current location'));
        await tester.pumpAndSettle();

        expect(find.text(text), findsOneWidget);
        expect(flow(tester).draft.country, 'PK');
        expect(flow(tester).draft.city, 'Islamabad');
      });
    });

    testWidgets('without a locator the offer stays inert', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        LumeOnboardingFlow(
          countries: countries,
          catalogue: catalogue,
          store: LumeMemoryOnboardingStore(),
          initialStep: LumeOnboardingStep.city,
        ),
        surface: LumeViewport.tall,
      );
      await tester.tap(find.text('Use my current location'));
      await tester.pumpAndSettle();
      expect(find.textContaining('choose your city by hand'), findsNothing);
    });

    testWidgets('the refusal reads right to left in Urdu, at 200 %', (
      WidgetTester tester,
    ) async {
      await pumpCity(
        tester,
        result: const LumeLocateResult.refused(LumeLocateOutcome.denied),
        locale: const Locale('ur'),
        textScale: 2,
      );
      await tester.tap(find.text('میرا موجودہ مقام استعمال کریں'));
      await tester.pumpAndSettle();
      expect(
        find.text('مقام کی اجازت نہیں دی گئی — اپنا شہر خود منتخب کریں۔'),
        findsOneWidget,
      );
      expectNoOverflow(tester);
    });
  });

  group('the location sheet — Region, Change', () {
    Future<LumeStartupController> pumpRegion(
      WidgetTester tester,
      LumeRecordingLocator locator,
    ) async {
      final LumeStartupController gate = await bootedGate();
      await pumpLume(
        tester,
        LumeAccountHost(
          branch: LumeRoutes.profile,
          route: LumeAccountRoute.region,
        ),
        overrides: <Override>[
          ...accountOverrides(gate: gate),
          locatorProvider.overrideWithValue(locator),
        ],
        surface: const Size(390, 4000),
      );
      return gate;
    }

    Future<void> openCitySheet(WidgetTester tester) async {
      await tester.tap(find.text('City'));
      await tester.pumpAndSettle();
      // Country first, then its cities — the location row is on the second.
      await tester.tap(
        find
            .descendant(
              of: find.byType(LumeSheet),
              matching: find.text('Pakistan'),
            )
            .first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a position is saved, as a tapped city is', (
      WidgetTester tester,
    ) async {
      final LumeRecordingLocator locator = LumeRecordingLocator(
        result: _london,
      );
      final LumeStartupController gate = await pumpRegion(tester, locator);

      await openCitySheet(tester);
      await tester.tap(find.text('Use my current location'));
      await tester.pumpAndSettle();

      expect(locator.requests, 1);
      final LumeProfileRecord p = gate.state.profile;
      expect((p.country, p.city, p.region), ('GB', 'London', 'England'));
      expect(find.text('London'), findsOneWidget);
    });

    testWidgets('a refusal says so and keeps the sheet open', (
      WidgetTester tester,
    ) async {
      final LumeRecordingLocator locator = LumeRecordingLocator(
        result: const LumeLocateResult.refused(LumeLocateOutcome.blocked),
      );
      final LumeStartupController gate = await pumpRegion(tester, locator);

      await openCitySheet(tester);
      await tester.tap(find.text('Use my current location'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("Location is off for Lume in your phone's"),
        findsOneWidget,
      );
      expect(gate.state.profile.country, 'PK');
    });
  });
}
