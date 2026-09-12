/// One eligibility decision, every way in (D30).
///
/// §64 is explicit that hiding the entry point is not enough: *"Also protect:
/// Feature screen, Search, Deep links, Sheets, Modals, Notifications,
/// Recommendations, Quick Tools, Hero, Recent features, Inactive screens,
/// Navigation."* The reference does not manage it — its Discover strip is
/// gated by markup attribute rather than by the eligibility selector, so a
/// content type the user switched off still appears there (C12).
///
/// Correcting that was approved and required. The condition attached was that
/// the correction be verified *independently on every surface*, not asserted
/// once and assumed. So this file walks each surface with the same four users
/// and asks the same question: does what this surface offers match exactly
/// what [LumeEligibility] allows?
///
/// The four dimensions, each with a user who fails it:
///
/// | dimension | who it hides from |
/// |---|---|
/// | faith | a user with the Islamic experience off |
/// | country | a user outside the markets a feature launched in |
/// | content switches | a user who turned news, cricket or finance off |
/// | sensitive | nobody — but never promoted on Home |
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/home/application/home_controller.dart';
import 'package:lume/features/home/domain/home_model.dart';
import 'package:lume/features/tools/domain/tools_filter.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// Faith-gated, country-gated and switched-off ids, so a surface can be
  /// asked about each one by name rather than in aggregate.
  const String faithTool = 'quran';
  const String countryTool = 'loadshed';
  const String sensitiveTool = 'documents';

  final List<(String, LumeUserContext)> users = <(String, LumeUserContext)>[
    ('not Muslim, Pakistan', LumeUsers.defaultPk),
    ('Muslim, Pakistan', LumeUsers.muslimPk),
    ('Muslim, United Kingdom', LumeUsers.muslimGb),
    ('not Muslim, United States', LumeUsers.defaultUs),
    ('the switches off', LumeUsers.prefsOffPk),
  ];

  /// What the selector says, which is the answer every surface must agree
  /// with. Nothing in this file re-implements it; that is the point.
  bool allowed(String id, LumeUserContext user) {
    final LumeFeature? f = kEligibility.byId(id);
    return f != null && kEligibility.isVisible(f, user);
  }

  group('the selector itself', () {
    test('gates on faith, country and the content switches separately', () {
      expect(allowed(faithTool, LumeUsers.muslimPk), isTrue);
      expect(allowed(faithTool, LumeUsers.defaultPk), isFalse);
      expect(
        kEligibility.reasonFor(
          kEligibility.byId(faithTool)!,
          LumeUsers.defaultPk,
        ),
        LumeUnavailableReason.faith,
      );

      expect(allowed(countryTool, LumeUsers.muslimPk), isTrue);
      expect(allowed(countryTool, LumeUsers.muslimGb), isFalse);
      expect(
        kEligibility.reasonFor(
          kEligibility.byId(countryTool)!,
          LumeUsers.muslimGb,
        ),
        LumeUnavailableReason.country,
      );

      // A switch is a preference, not a gate on the tool — it decides what is
      // *promoted*, which is the surface the reference got wrong.
      expect(allowed('news', LumeUsers.prefsOffPk), isFalse);
      expect(
        kEligibility.reasonFor(
          kEligibility.byId('news')!,
          LumeUsers.prefsOffPk,
        ),
        LumeUnavailableReason.preference,
      );
    });

    test('and a sensitive tool is visible, not hidden', () {
      // §61: discoverable without being intrusive. It is the *promotion*
      // surfaces that must not carry it, not the catalogue.
      for (final (String _, LumeUserContext user) in users) {
        expect(allowed(sensitiveTool, user), isTrue, reason: '$user');
      }
      expect(kEligibility.byId(sensitiveTool)!.sensitive, isTrue);
    });
  });

  group('the hub', () {
    for (final (String name, LumeUserContext user) in users) {
      testWidgets('shows exactly what the selector allows · $name', (
        WidgetTester tester,
      ) async {
        await pumpTools(
          tester,
          user,
          surface: const Size(390, 12000),
          filter: LumeToolsFilter.all,
        );

        for (final LumeFeature f in kEligibility.features) {
          final Finder tile = find.byKey(
            ValueKey<String>('tools.tile.${f.id}'),
          );
          final bool drawn = tile.evaluate().isNotEmpty;
          expect(
            drawn,
            kEligibility.isVisible(f, user),
            reason: '${f.id} drawn=$drawn for $name',
          );
        }
      });
    }
  });

  group('search', () {
    for (final (String name, LumeUserContext user) in users) {
      testWidgets('never turns up a tool the hub would not show · $name', (
        WidgetTester tester,
      ) async {
        // A query broad enough to match most of the catalogue, so the test is
        // about the gate rather than about the query.
        for (final String query in <String>['a', 'e', 'prayer', 'tax']) {
          await pumpTools(
            tester,
            user,
            surface: const Size(390, 12000),
            filter: LumeToolsFilter.all,
          );
          await tester.enterText(find.byType(TextField), query);
          await tester.pumpAndSettle();

          for (final LumeFeature f in kEligibility.features) {
            if (kEligibility.isVisible(f, user)) continue;
            expect(
              find.byKey(ValueKey<String>('tools.tile.${f.id}')),
              findsNothing,
              reason: '"$query" surfaced ${f.id} for $name',
            );
          }
        }
      });
    }
  });

  group('Home', () {
    for (final (String name, LumeUserContext user) in users) {
      testWidgets('promotes nothing the selector refuses · $name', (
        WidgetTester tester,
      ) async {
        final LumeHomeController c = await composeHome(user);
        addTearDown(c.dispose);
        final LumeHomeData d = c.state.data!;

        void allowedTarget(LumeHomeTarget target, String where) {
          switch (target) {
            case LumeToolTarget(:final String featureId):
              expect(
                allowed(featureId, user),
                isTrue,
                reason: '$where promotes $featureId to $name',
              );
            case LumeDestinationTarget():
              break;
          }
        }

        for (final LumeFeature t in d.quickTools) {
          allowedTarget(LumeHomeTarget.tool(t.id), 'a quick tool');
          expect(
            t.sensitive,
            isFalse,
            reason: '§61: ${t.id} is sensitive and on Home',
          );
        }
        for (final LumeQuickAction a in d.quickActions) {
          allowedTarget(LumeHomeTarget.tool(a.featureId), 'a quick action');
        }
        for (final LumeHeroCard h in d.hero) {
          allowedTarget(h.target, 'the hero');
        }
        for (final LumeDiscoverCard card in d.discover) {
          allowedTarget(card.target, 'Discover');
        }
        for (final LumeGlanceCard g in d.glance) {
          allowedTarget(g.target, 'At a glance');
        }
      });
    }
  });

  group('Discover, specifically', () {
    testWidgets('drops a card whose content type the user switched off', (
      WidgetTester tester,
    ) async {
      // C12: the reference gates this strip by `data-loc` and `data-int`
      // attributes rather than by the selector, so a switched-off type keeps
      // its card. Here the strip asks the selector, like everything else.
      final LumeHomeController on = await composeHome(LumeUsers.muslimPk);
      addTearDown(on.dispose);
      final LumeHomeController off = await composeHome(LumeUsers.prefsOffPk);
      addTearDown(off.dispose);

      Set<String> idsOf(LumeHomeController c) =>
          c.state.data!.discover.map((LumeDiscoverCard d) => d.id.name).toSet();

      expect(idsOf(on), contains('cricket'));
      expect(
        idsOf(off),
        isNot(contains('cricket')),
        reason: 'the cricket switch is off and the card is still there',
      );
    });

    testWidgets('and never draws one for a faith-gated feature', (
      WidgetTester tester,
    ) async {
      await pumpHome(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 6000),
      );
      expect(
        find.byKey(const ValueKey<String>('home.discover.duas')),
        findsNothing,
      );

      await pumpHome(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 6000),
      );
      expect(
        find.byKey(const ValueKey<String>('home.discover.duas')),
        findsOneWidget,
      );
    });
  });

  group('recents', () {
    testWidgets('cannot carry a tool this user may not have', (
      WidgetTester tester,
    ) async {
      // The named user has a history. Whatever is in it, the hub must filter
      // it through the same gate before drawing it — a profile that moved
      // country, or turned the Islamic experience off, still has the old ids
      // in `recents` and they must not come back.
      for (final (String name, LumeUserContext user) in users) {
        final List<LumeFeature> recents = kEligibility.recentFeatures(
          user.copyWith(
            recents: const <String>[faithTool, countryTool, 'calculator'],
          ),
        );
        for (final LumeFeature f in recents) {
          expect(
            kEligibility.isVisible(f, user),
            isTrue,
            reason: '${f.id} came back from history for $name',
          );
        }
        expect(
          recents.map((LumeFeature f) => f.id),
          contains('calculator'),
          reason: 'a global tool should survive the filter for $name',
        );
      }
    });
  });

  group('a deep link', () {
    Future<LumeToolFrame> open(WidgetTester tester, String path) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
      );
      router.go(path);
      await tester.pumpAndSettle();
      return tester.widget<LumeToolFrame>(find.byType(LumeToolFrame));
    }

    testWidgets('is refused for a faith-gated tool the user cannot have', (
      WidgetTester tester,
    ) async {
      // The launch profile is the default one — not Muslim — so the Quran is
      // not this user's to open, however they arrived at the URL.
      final LumeToolFrame frame = await open(
        tester,
        LumeRoutes.tool(LumeRoutes.home, faithTool),
      );
      expect(frame.eligible, isFalse);
      expect(find.text('Not part of your setup'), findsWidgets);
      expect(find.byType(LumeCatalogueTile), findsNothing);
    });

    testWidgets('and for one that has not launched in this market', (
      WidgetTester tester,
    ) async {
      final LumeToolFrame frame = await open(
        tester,
        LumeRoutes.tool(LumeRoutes.tools, 'natsavings'),
      );
      expect(frame.eligible, isTrue, reason: 'the launch profile is Pakistan');

      // Move the shelf: the same URL, a user in the United Kingdom.
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
        overrides: <Override>[countryOverrideProvider.overrideWithValue('GB')],
      );
      router.go(LumeRoutes.tool(LumeRoutes.tools, 'natsavings'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LumeToolFrame>(find.byType(LumeToolFrame)).eligible,
        isFalse,
      );
    });

    testWidgets('and refuses an unknown id exactly as it refuses a gated one', (
      WidgetTester tester,
    ) async {
      // "You may not have this" and "there is no such thing" must look the
      // same from outside, or the refusal is itself the disclosure.
      final LumeToolFrame unknown = await open(
        tester,
        LumeRoutes.tool(LumeRoutes.home, 'no-such-tool'),
      );
      expect(unknown.eligible, isFalse);
      final String unknownTitle = unknown.title;

      final LumeToolFrame gated = await open(
        tester,
        LumeRoutes.tool(LumeRoutes.home, faithTool),
      );
      expect(gated.title, unknownTitle);
      expect(gated.subtitle, unknown.subtitle);
    });

    testWidgets('but opens one the user is allowed, by name', (
      WidgetTester tester,
    ) async {
      final LumeToolFrame frame = await open(
        tester,
        LumeRoutes.tool(LumeRoutes.home, 'calculator'),
      );
      expect(frame.eligible, isTrue);
      expect(frame.title, 'Calculator');
    });

    testWidgets('and a refused one is never written into the history', (
      WidgetTester tester,
    ) async {
      // Recents are noted where a tile is tapped, which is a surface the gate
      // has already passed. A deep link does not go through it, so a tool the
      // user may not have cannot enter their history by being linked to.
      await open(tester, LumeRoutes.tool(LumeRoutes.home, faithTool));
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
      );
      router.go(LumeRoutes.tools);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('tools.recent.$faithTool')),
        findsNothing,
      );
    });
  });
}
