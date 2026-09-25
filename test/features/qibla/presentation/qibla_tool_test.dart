/// Qibla Compass on screen: opened directly for a reader
/// ([pumpLume]), not through the real router.
///
/// Unlike most converted tools, this pumps [LumeQiblaTool] directly rather
/// than through `LumeRoutes.tool(...)`: Qibla's wave lands in parallel with
/// nine other tools, and the shared `tool_registry.dart` this repository
/// routes through is out of scope for this change — it is wired up in the
/// integration pass that follows (the same approach Daily Streak's own
/// harness takes, `streak_screen_harness.dart`). The screen itself is
/// exercised exactly as the router would host it, with the same provider
/// overrides and the same clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/qibla/domain/qibla_bearing.dart';
import 'package:lume/features/qibla/presentation/qibla_dial.dart';
import 'package:lume/features/qibla/presentation/qibla_tool.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../../helpers/lume_harness.dart';

final LumeFeature _qiblaFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeQiblaTool.id,
);

Future<void> pumpQibla(
  WidgetTester tester, {
  // Qibla is faith-gated (`faith: true`): the frame itself blocks the body
  // for a non-Muslim reader, so every test here that expects to see the
  // reading needs a Muslim context — Muslim + Pakistan + Islamabad is the
  // brief's own first baseline scenario (§18).
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
    LumeQiblaTool(
      request: LumeToolRequest(
        feature: _qiblaFeature,
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

void main() {
  group('the catalogue entry', () {
    test('is faith-gated, city-aware and computed — not this widget\'s job '
        'to re-decide', () {
      expect(_qiblaFeature.faith, isTrue);
      expect(_qiblaFeature.requiresCity, isTrue);
    });
  });

  group('a city Lume has coordinates for', () {
    // Islamabad: the default LumeUserContext.
    testWidgets('draws a bearing, a distance and the dial — never a fixed '
        'example angle', (WidgetTester tester) async {
      await pumpQibla(tester);

      expect(find.byKey(LumeQiblaTool.missingKey), findsNothing);
      expect(find.byKey(LumeQiblaTool.dialKey), findsOneWidget);

      final LumeQiblaDial dial = tester.widget(
        find.byKey(LumeQiblaTool.dialKey),
      );
      final double expected = LumeQiblaMath.bearing(33.69, 73.05);
      expect(dial.bearing, closeTo(expected, 0.001));

      final LumeSummaryCard summary = tester.widget(
        find.byKey(LumeQiblaTool.summaryKey),
      );
      expect(summary.value, '${expected.round()}°');
      expect(summary.unit, LumeQiblaMath.compassPoint(expected));
      expect(summary.stats, hasLength(2));

      final LumeRows reference = tester.widget(
        find.byKey(LumeQiblaTool.referenceKey),
      );
      expect(reference.children, hasLength(2));

      // The context bar names the city and the country, not just the city.
      expect(find.textContaining('Islamabad'), findsWidgets);
    });

    testWidgets('a different city changes the bearing — it is worked out, '
        'not hard-coded', (WidgetTester tester) async {
      await pumpQibla(
        tester,
        user: const LumeUserContext(country: 'GB', city: 'London', islamic: true),
      );
      final LumeQiblaDial dial = tester.widget(
        find.byKey(LumeQiblaTool.dialKey),
      );
      final double expected = LumeQiblaMath.bearing(51.51, -0.13);
      expect(dial.bearing, closeTo(expected, 0.001));
      // London's qibla is nowhere near Islamabad's.
      expect(
        (dial.bearing - LumeQiblaMath.bearing(33.69, 73.05)).abs(),
        greaterThan(50),
      );
    });
  });

  group('a non-Muslim reader', () {
    testWidgets('never sees the reading — the frame itself blocks a '
        'faith-gated tool\'s body, defence in depth over the catalogue gate '
        'alone (§64)', (WidgetTester tester) async {
      await pumpQibla(tester, user: const LumeUserContext(islamic: false));
      expect(find.byKey(LumeQiblaTool.dialKey), findsNothing);
      expect(find.byKey(LumeQiblaTool.summaryKey), findsNothing);
      expect(find.byKey(LumeQiblaTool.missingKey), findsNothing);
    });
  });

  group('a city Lume has no coordinates for', () {
    testWidgets('says so plainly, and shows no dial, no summary and no '
        'reference card', (WidgetTester tester) async {
      await pumpQibla(
        tester,
        user: const LumeUserContext(country: 'PK', city: 'Chitral', islamic: true),
      );
      expect(find.byKey(LumeQiblaTool.missingKey), findsOneWidget);
      expect(find.byKey(LumeQiblaTool.dialKey), findsNothing);
      expect(find.byKey(LumeQiblaTool.summaryKey), findsNothing);
      expect(find.byKey(LumeQiblaTool.referenceKey), findsNothing);

      final LumeToolState state = tester.widget(
        find.byKey(LumeQiblaTool.missingKey),
      );
      expect(state.title, contains('Chitral'));
    });
  });

  group('a non-English locale', () {
    testWidgets('still renders the computed reading, in Arabic', (
      WidgetTester tester,
    ) async {
      await pumpQibla(tester, locale: const Locale('ar'));
      expect(find.byKey(LumeQiblaTool.dialKey), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeQiblaTool.summaryKey)),
        ),
        TextDirection.rtl,
      );
      // The dial's own cardinal letters stay Latin in every language (D22),
      // matching how the reference's compassPoint() is never translated.
      final LumeQiblaDial dial = tester.widget(
        find.byKey(LumeQiblaTool.dialKey),
      );
      expect(
        LumeQiblaMath.compassPoint(dial.bearing),
        matches(RegExp(r'^[NESW]{1,2}$')),
      );
    });
  });
}
