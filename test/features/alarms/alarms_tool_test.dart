/// Alarms on screen: opened directly for a reader ([pumpLume]), not through
/// the real router — `tool_registry.dart` is out of scope for this change,
/// wired up in the integration pass that follows, the same approach
/// `parcel_tool_test.dart` and `markets_tool_test.dart` take for their own
/// waves.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/alarms/presentation/alarms_tool.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

final LumeFeature _alarmsFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeAlarmsTool.id,
);

Future<void> pumpAlarms(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 2200),
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
    LumeAlarmsTool(
      request: LumeToolRequest(
        feature: _alarmsFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

void main() {
  setUpAll(loadLumeFonts);

  group('the catalogue entry', () {
    test('is a general daily-life utility, not gated to the Islamic '
        'experience', () {
      expect(_alarmsFeature.faith, isFalse);
      expect(_alarmsFeature.category, LumeToolCategory.personal);
    });
  });

  group('what it draws', () {
    testWidgets('the three fixture alarms, in the reference’s own order', (
      WidgetTester tester,
    ) async {
      await pumpAlarms(tester);

      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            inKey(LumeAlarmsTool.listKey, find.byType(LumeRichRow)),
          )
          .toList();
      expect(rows.map((LumeRichRow r) => r.subtitle), <String>[
        'Work',
        'Lie-in',
        'Wind down',
      ]);
      expect(rows.map((LumeRichRow r) => r.meta), <List<String>>[
        <String>['Weekdays'],
        <String>['Weekends'],
        <String>['Every day'],
      ]);
      final List<LumeSwitch> switches = rows
          .map((LumeRichRow r) => r.trailing)
          .whereType<LumeSwitch>()
          .toList();
      expect(switches.map((LumeSwitch s) => s.value), <bool>[
        true,
        false,
        true,
      ]);
    });

    testWidgets('the summary card names the first armed alarm, not a real '
        'countdown', (WidgetTester tester) async {
      await pumpAlarms(tester);

      final LumeSummaryCard card = tester.widget<LumeSummaryCard>(
        find.byKey(LumeAlarmsTool.summaryKey),
      );
      expect(card.value, '6:30 am');
      expect(card.caption, 'Work · in about 8 hours');
    });
  });

  group('used', () {
    testWidgets('the switch flips, but only on screen — it does not move '
        'the summary card, the same as the reference’s own DOM-only class '
        'toggle', (WidgetTester tester) async {
      await pumpAlarms(tester);

      final Finder firstToggle = inKey(
        LumeAlarmsTool.toggleKey('a1'),
        find.byType(LumeSwitch),
      );
      expect(tester.widget<LumeSwitch>(firstToggle).value, isTrue);

      await tester.tap(firstToggle);
      await tester.pump();

      expect(tester.widget<LumeSwitch>(firstToggle).value, isFalse);
      // The reference's own summary card is worked out once, before any
      // toggle, and never revisited — so this port pins it the same way.
      final LumeSummaryCard card = tester.widget<LumeSummaryCard>(
        find.byKey(LumeAlarmsTool.summaryKey),
      );
      expect(card.caption, 'Work · in about 8 hours');

      // Flipping it back is just as inert.
      await tester.tap(firstToggle);
      await tester.pump();
      expect(tester.widget<LumeSwitch>(firstToggle).value, isTrue);
    });

    testWidgets('Add is a toast, not a new alarm — the reference has no '
        'reader-added alarm to build one for', (WidgetTester tester) async {
      await pumpAlarms(tester);

      await tester.tap(find.byKey(LumeAlarmsTool.addKey));
      await tester.pump();

      expect(find.text('New alarm'), findsOneWidget);
      // No fourth row appeared.
      expect(
        inKey(LumeAlarmsTool.listKey, find.byType(LumeRichRow)),
        findsNWidgets(3),
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('in Urdu the row runs right to left, without overflow', (
      WidgetTester tester,
    ) async {
      await pumpAlarms(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(
          tester.element(
            inKey(LumeAlarmsTool.listKey, find.byType(LumeRichRow)).first,
          ),
        ),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('in Arabic, without overflow', (WidgetTester tester) async {
      await pumpAlarms(tester, locale: const Locale('ar'));
      expectNoOverflow(tester);
    });

    testWidgets('at 200%, without overflow', (WidgetTester tester) async {
      await pumpAlarms(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
