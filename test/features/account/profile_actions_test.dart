/// Profile's Log out and "Replay the welcome tour", through the real router
/// and the real account store — the path a reader takes. Both used to only
/// say their own names; the account store never followed a sign-in, so
/// Profile could not even offer Log out outside a test that seeded it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/onboarding/presentation/onboarding_flow.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

Future<void> pumpProfile(WidgetTester tester, {bool signedIn = true}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: LumeRoutes.profile,
    profile: taxProfile('default_pk'),
    signedIn: signedIn,
    surface: const Size(390, 3000),
  );
  await tester.pumpAndSettle();
}

LumeAccountState storeState(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(MaterialApp)),
).read(accountRepositoryProvider).state;

bool gateSignedIn(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(MaterialApp)),
).read(startupControllerProvider).state.auth.isAuthenticated;

Future<void> tapLogOut(WidgetTester tester) async {
  final Finder row = find.text('Log out').first;
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a signed-in reader’s Profile shows the account', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);
    expect(gateSignedIn(tester), isTrue);
    expect(storeState(tester), LumeAccountState.authed);
    expect(find.text('Log out'), findsWidgets);
  });

  testWidgets('a guest’s Profile offers sign-in, and no Log out', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester, signedIn: false);
    expect(storeState(tester), LumeAccountState.guest);
    expect(find.text('Log out'), findsNothing);
  });

  testWidgets('Log out asks, then signs out and says so', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);
    await tapLogOut(tester);
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(LumeSheet),
        matching: find.text('Log out'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(gateSignedIn(tester), isFalse);
    expect(storeState(tester), LumeAccountState.guest);
    expect(
      find.descendant(
        of: find.byType(LumeToast),
        matching: find.text('Signed out'),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Log out'), findsNothing);
  });

  testWidgets('Cancel keeps the reader signed in', (WidgetTester tester) async {
    await pumpProfile(tester);
    await tapLogOut(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(LumeSheet),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expect(gateSignedIn(tester), isTrue);
    expect(storeState(tester), LumeAccountState.authed);
  });

  testWidgets('"Replay the welcome tour" opens the tour over saved choices', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester, signedIn: false);
    final Finder row = find.text('Replay the welcome tour').first;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(LumeOnboardingFlow), findsOneWidget);
    // Nothing is reset by opening it: the reader is still onboarded, in
    // the same place.
    final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final profile = c.read(startupControllerProvider).state.profile;
    expect(profile.onboarded, isTrue);
    expect(profile.city, 'Islamabad');
  });
}
