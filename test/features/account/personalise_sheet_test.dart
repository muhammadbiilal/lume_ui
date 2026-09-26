/// The interests sheet (`sheet:personalise`), opened the ways the reference
/// opens it: it draws the catalogue's interests, and a choice is saved as it
/// is made.
///
/// There was no test that opened this sheet, and it never drew an interest:
/// its controller was given a `const` set that the load then added to, so the
/// load threw and the sheet showed its spinner for ever.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

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

  testWidgets('a choice is saved as it is made', (WidgetTester tester) async {
    await pumpLumeRouter(
      tester,
      initialLocation: LumeRoutes.profile,
      profile: taxProfile('default_pk'),
      surface: const Size(390, 3000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your interests'));
    await settleSheet(tester);

    final LumeStartupController gate = ProviderScope.containerOf(
      tester.element(find.byType(LumeSheet)),
    ).read(startupControllerProvider);
    expect(gate.state.profile.interests, contains('weather'));

    await tester.tap(inSheet(find.text('Weather')));
    await tester.pump();
    expect(gate.state.profile.interests, isNot(contains('weather')));
    expect(inSheet(find.text('6 of 10 selected')), findsOneWidget);
  });
}
