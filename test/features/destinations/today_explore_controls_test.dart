/// Today's and Explore's controls that used to do nothing, through the real
/// router: the reflection card's Bookmark and Share, an agenda entry with
/// nowhere to go, a Nearby row, and "Today's reads" behind the news
/// interest.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/explore/presentation/explore_screen.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/share/presentation/share_sheet.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

Future<void> pumpAt(
  WidgetTester tester,
  String at, {
  LumeProfileRepository? profile,
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: at,
    profile: profile ?? taxProfile('muslim_pk'),
    surface: const Size(390, 5000),
  );
  await tester.pumpAndSettle();
}

Finder toast(String text) =>
    find.descendant(of: find.byType(LumeToast), matching: find.text(text));

Finder cardAction(String label) => find.bySemanticsLabel(label);

void main() {
  group('Today', () {
    testWidgets('Bookmark turns on and off and says which', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpAt(tester, LumeRoutes.today);
      await tester.tap(cardAction('Bookmark').first);
      await tester.pump();
      expect(toast('Saved to your bookmarks'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(cardAction('Bookmark').first);
      await tester.pump();
      expect(toast('Removed from bookmarks'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      h.dispose();
    });

    testWidgets('Share opens the share sheet over the day’s card', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpAt(tester, LumeRoutes.today);
      await tester.tap(cardAction('Share').first);
      await tester.pumpAndSettle();
      expect(find.byType(LumeShareSheet), findsOneWidget);
      h.dispose();
    });

    testWidgets('an agenda entry with nowhere to go says its own title', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, LumeRoutes.today);
      final Finder standup = find.byKey(
        const ValueKey<String>('today.agenda.standup'),
      );
      await tester.ensureVisible(standup);
      await tester.pumpAndSettle();
      await tester.tap(standup);
      await tester.pump();
      expect(find.byType(LumeToast), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('Explore', () {
    testWidgets('a Nearby row says its place and its line', (
      WidgetTester tester,
    ) async {
      await pumpAt(tester, LumeRoutes.explore);
      final Finder row = find.byKey(
        const ValueKey<String>('explore.nearby.chaiShai'),
      );
      expect(row, findsOneWidget);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pump();
      expect(find.byType(LumeToast), findsOneWidget);
      expect(find.textContaining('Chai Shai ·'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Today’s reads follows the news interest', (
      WidgetTester tester,
    ) async {
      final LumeMemoryProfileRepository noNews = LumeMemoryProfileRepository(
        initial: taxReader().copyWith(
          interests: const <String>[
            'weather',
            'calendar',
            'tasks',
            'notes',
            'maths',
          ],
        ),
      );
      await pumpAt(tester, LumeRoutes.explore, profile: noNews);
      expect(
        find.byKey(const ValueKey<String>(LumeExploreScreen.newsKey)),
        findsNothing,
      );
    });

    testWidgets('and is there for a reader who has it', (
      WidgetTester tester,
    ) async {
      final LumeMemoryProfileRepository withNews = LumeMemoryProfileRepository(
        initial: taxReader().copyWith(
          interests: LumeOnboardingState.defaultInterests,
        ),
      );
      await pumpAt(tester, LumeRoutes.explore, profile: withNews);
      expect(
        find.byKey(const ValueKey<String>(LumeExploreScreen.newsKey)),
        findsOneWidget,
      );
    });
  });
}
