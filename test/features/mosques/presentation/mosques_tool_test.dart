/// Nearby Mosques on screen: opened directly for a reader ([pumpLume]), not
/// through the real router.
///
/// Unlike most converted tools, this pumps [LumeMosquesTool] directly rather
/// than through `LumeRoutes.tool(...)`: the shared `tool_registry.dart` this
/// repository routes through is out of scope for this change — it is wired up
/// in the integration pass that follows (the same approach Prize Bonds',
/// Qibla's and Public Holidays' own tests take).
///
/// The literal English strings this file asserts against (`mosques*`) are
/// exactly what the tool report hands to whoever adds them to `app_en.arb` —
/// a mismatch there is a mismatch here too.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_link_opener.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/mosques/domain/mosques_search.dart';
import 'package:lume/features/mosques/presentation/mosques_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _feature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeMosquesTool.id,
);

Future<LumeRecordingLinkOpener> pumpMosques(
  WidgetTester tester, {
  // Mosques is faith-gated (`faith: true`): the frame itself blocks the body
  // for a non-Muslim reader, so every test here that expects to see the
  // honest state needs a Muslim context — Muslim + Pakistan + Islamabad is
  // the brief's own first baseline scenario (§18).
  LumeUserContext user = const LumeUserContext(islamic: true),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 2000),
  double textScale = 1,
  LumeOpenOutcome outcome = LumeOpenOutcome.opened,
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  final LumeRecordingLinkOpener opener = LumeRecordingLinkOpener(
    outcome: outcome,
  );
  await pumpLume(
    tester,
    LumeMosquesTool(
      request: LumeToolRequest(feature: _feature, user: user, branch: 'tools'),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[
      startupControllerProvider.overrideWithValue(gate),
      linkOpenerProvider.overrideWithValue(opener),
    ],
  );
  await tester.pumpAndSettle();
  return opener;
}

void main() {
  group('the catalogue entry', () {
    test('is faith-gated and city-aware — not this widget\'s job to '
        're-decide', () {
      expect(_feature.faith, isTrue);
      expect(_feature.requiresCity, isTrue);
      expect(_feature.fallbackSource, 'Places directory');
    });
  });

  group('a Muslim reader in Pakistan', () {
    testWidgets('sees their place, and the honest state — never an invented '
        'mosque row', (WidgetTester tester) async {
      await pumpMosques(tester);

      expect(
        find.descendant(
          of: find.byKey(LumeMosquesTool.contextKey),
          matching: find.text('Islamabad, Pakistan'),
        ),
        findsOneWidget,
      );

      expect(find.byKey(LumeMosquesTool.unavailableKey), findsOneWidget);
      final LumeCollectionState state = tester.widget(
        find.byKey(LumeMosquesTool.unavailableKey),
      );
      expect(state.title, 'No live mosque search yet');
      expect(
        state.text,
        "Lume doesn't have a live places directory yet, so a nearby list "
        'here would mean inventing mosque names and distances. Open Maps '
        'for a real search near you.',
      );

      final LumeButton action = tester.widget(
        find.descendant(
          of: find.byKey(LumeMosquesTool.unavailableKey),
          matching: find.byType(LumeButton),
        ),
      );
      expect(action.label, 'Open in Maps');
    });
  });

  group('opening Maps', () {
    testWidgets('hands over a real search for mosques near the reader\'s own '
        'place — never a name or a distance this app made up', (
      WidgetTester tester,
    ) async {
      final LumeRecordingLinkOpener opener = await pumpMosques(tester);
      await tester.tap(find.widgetWithText(LumeButton, 'Open in Maps'));
      await tester.pumpAndSettle();

      expect(opener.opened, hasLength(1));
      expect(
        opener.opened.single,
        LumeMosquesSearch.mapsUri('Islamabad, Pakistan'),
      );
      expect(find.byType(LumeToast), findsNothing);
    });

    testWidgets('a different city and country changes the real search, not '
        'a hard-coded one', (WidgetTester tester) async {
      final LumeRecordingLinkOpener opener = await pumpMosques(
        tester,
        user: const LumeUserContext(
          country: 'GB',
          city: 'London',
          islamic: true,
        ),
      );
      await tester.tap(find.widgetWithText(LumeButton, 'Open in Maps'));
      await tester.pumpAndSettle();

      expect(
        opener.opened.single,
        LumeMosquesSearch.mapsUri('London, United Kingdom'),
      );
    });

    testWidgets('says so plainly when nothing on the device can open Maps', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester, outcome: LumeOpenOutcome.unavailable);
      await tester.tap(find.widgetWithText(LumeButton, 'Open in Maps'));
      await tester.pump();
      expect(find.text("This device can't open Maps."), findsOneWidget);
    });

    testWidgets('says so plainly when the platform refuses to open it', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester, outcome: LumeOpenOutcome.failed);
      await tester.tap(find.widgetWithText(LumeButton, 'Open in Maps'));
      await tester.pump();
      expect(find.text("Couldn't open Maps. Try again."), findsOneWidget);
    });
  });

  group('a non-Muslim reader', () {
    testWidgets('never sees the tool\'s body — the frame itself blocks a '
        'faith-gated tool, defence in depth over the catalogue gate alone '
        '(§64)', (WidgetTester tester) async {
      await pumpMosques(tester, user: const LumeUserContext(islamic: false));
      expect(find.byKey(LumeMosquesTool.contextKey), findsNothing);
      expect(find.byKey(LumeMosquesTool.unavailableKey), findsNothing);
    });
  });

  group('right to left and scale', () {
    testWidgets('Urdu renders the same honest state, right to left', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expect(find.byKey(LumeMosquesTool.unavailableKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic, right to left, without overflow', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester, locale: const Locale('ar'));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('at 200%, without overflow', (WidgetTester tester) async {
      await pumpMosques(tester, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
