/// The interests sheet (`sheet:personalise`), opened the ways the reference
/// opens it: it draws the catalogue's interests, and a choice is saved as it
/// is made.
///
/// There was no test that opened this sheet, and it never drew an interest:
/// its controller was given a `const` set that the load then added to, so the
/// load threw and the sheet showed its spinner for ever.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/account/presentation/personalise_sheet.dart';
import 'package:lume/features/account/presentation/profile_screen.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

import '../../helpers/capture.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

void main() {
  Finder inSheet(Finder f) =>
      find.descendant(of: find.byType(LumeSheet), matching: f);

  /// The asset read is real I/O, which the test's fake clock never finishes.
  Future<void> settleSheet(WidgetTester tester) async {
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  void expectInterestsDrawn(WidgetTester tester) {
    expect(find.byType(LumeSheet), findsOneWidget);
    expect(inSheet(find.byType(CircularProgressIndicator)), findsNothing);
    expect(inSheet(find.text('7 of 10 selected')), findsOneWidget);
    expect(inSheet(find.text('Weather')), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  testWidgets('from Profile, "Your interests" opens it, with the interests', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(
      tester,
      initialLocation: LumeRoutes.profile,
      profile: taxProfile('default_pk'),
      surface: const Size(390, 3000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your interests'));
    await settleSheet(tester);
    expectInterestsDrawn(tester);
  });

  testWidgets('from Tools, the header button opens it over Tools', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(
      tester,
      initialLocation: LumeRoutes.tools,
      profile: taxProfile('default_pk'),
      surface: const Size(390, 6000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Personalise').first);
    await settleSheet(tester);
    expectInterestsDrawn(tester);
  });

  testWidgets('from a tool, its place chip opens it', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(
      tester,
      initialLocation: LumeRoutes.tool(LumeRoutes.tools, 'weather'),
      profile: taxProfile('default_pk'),
      surface: const Size(390, 6000),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(LumeContextBar),
            matching: find.textContaining('Islamabad'),
          )
          .first,
    );
    await settleSheet(tester);
    expectInterestsDrawn(tester);
  });

  Future<LumeStartupController> openFromProfile(WidgetTester tester) async {
    await pumpLumeRouter(
      tester,
      initialLocation: LumeRoutes.profile,
      profile: taxProfile('default_pk'),
      surface: const Size(390, 6000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your interests'));
    await settleSheet(tester);
    return ProviderScope.containerOf(
      tester.element(find.byType(LumeSheet)),
    ).read(startupControllerProvider);
  }

  testWidgets('the reference’s sections, in its order', (
    WidgetTester tester,
  ) async {
    await openFromProfile(tester);
    expect(
      inSheet(find.text('Change any of this whenever you like')),
      findsOneWidget,
    );
    double last = -1;
    for (final Key k in <Key>[
      LumePersonaliseKeys.country,
      LumePersonaliseKeys.city,
      LumePersonaliseKeys.language,
      LumePersonaliseKeys.units,
      LumePersonaliseKeys.currency,
      LumePersonaliseKeys.clock,
      LumePersonaliseKeys.islamic,
      LumePersonaliseKeys.news,
      LumePersonaliseKeys.sport,
      LumePersonaliseKeys.finance,
      LumePersonaliseKeys.recos,
      LumePersonaliseKeys.save,
    ]) {
      final double y = tester.getTopLeft(find.byKey(k)).dy;
      expect(y, greaterThan(last), reason: '$k');
      last = y;
    }
  });

  testWidgets('interests wait for Save, which writes them and says so', (
    WidgetTester tester,
  ) async {
    final LumeStartupController gate = await openFromProfile(tester);
    expect(gate.state.profile.interests, contains('weather'));

    await tester.tap(inSheet(find.text('Weather')));
    await tester.pump();
    expect(inSheet(find.text('6 of 10 selected')), findsOneWidget);
    // A draft: nothing is written until Save.
    expect(gate.state.profile.interests, contains('weather'));

    await tester.ensureVisible(find.byKey(LumePersonaliseKeys.save));
    await tester.tap(find.byKey(LumePersonaliseKeys.save));
    await tester.pump();
    expect(gate.state.profile.interests, isNot(contains('weather')));
    expect(find.text('Your app has been updated'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(LumeSheet), findsNothing);
  });

  testWidgets('closing without Save keeps nothing', (
    WidgetTester tester,
  ) async {
    final LumeStartupController gate = await openFromProfile(tester);
    await tester.tap(find.byKey(LumePersonaliseKeys.units));
    await tester.pump();
    await tester.tap(inSheet(find.text('Weather')));
    await tester.pump();
    Navigator.of(tester.element(find.byType(LumeSheet))).pop();
    await tester.pumpAndSettle();
    expect(gate.state.profile.interests, contains('weather'));
    expect(gate.state.profile.units, LumeUnitsPreference.auto);
  });

  testWidgets('Save waits for the minimum of five', (
    WidgetTester tester,
  ) async {
    await openFromProfile(tester);
    await tester.tap(inSheet(find.text('Clear')));
    await tester.pump();
    final LumeButton save = tester.widget<LumeButton>(
      find.byKey(LumePersonaliseKeys.save),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('units cycle Automatic → Metric → Imperial, saved on Save', (
    WidgetTester tester,
  ) async {
    final LumeStartupController gate = await openFromProfile(tester);
    await tester.tap(find.byKey(LumePersonaliseKeys.units));
    await tester.pump();
    await tester.tap(find.byKey(LumePersonaliseKeys.units));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(LumePersonaliseKeys.units),
        matching: find.text('Imperial'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(LumePersonaliseKeys.save));
    await tester.tap(find.byKey(LumePersonaliseKeys.save));
    await tester.pump();
    expect(gate.state.profile.units, LumeUnitsPreference.imperial);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a content switch is written at once, as the reference’s is', (
    WidgetTester tester,
  ) async {
    final LumeStartupController gate = await openFromProfile(tester);
    expect(gate.state.profile.prefs.news, isTrue);
    await tester.tap(find.byKey(LumePersonaliseKeys.news));
    await tester.pump();
    expect(gate.state.profile.prefs.news, isFalse);
  });

  testWidgets('the Islamic switch and the faith card are one choice', (
    WidgetTester tester,
  ) async {
    await openFromProfile(tester);
    await tester.tap(find.byKey(LumePersonaliseKeys.islamic));
    await tester.pump();
    final LumeSettingsRow row = tester.widget<LumeSettingsRow>(
      find.byKey(LumePersonaliseKeys.islamic),
    );
    expect(row.toggle, isTrue);
  });

  for (final (String name, Locale locale, double scale)
      in <(String, Locale, double)>[
        ('Urdu', const Locale('ur'), 1),
        ('Arabic', const Locale('ar'), 1),
        ('200 %', const Locale('en'), 2),
      ]) {
    testWidgets('$name, without overflow', (WidgetTester tester) async {
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.profile,
        profile: taxProfile('default_pk'),
        surface: const Size(390, 9000),
        locale: locale,
        textScale: scale,
      );
      await tester.pumpAndSettle();
      // Opened as the row opens it: its own label is translated here.
      unawaited(
        showLumePersonalise(tester.element(find.byType(LumeProfileScreen))),
      );
      await settleSheet(tester);
      expect(find.byKey(LumePersonaliseKeys.save), findsOneWidget);
      expectNoOverflow(tester);
    });
  }
}
