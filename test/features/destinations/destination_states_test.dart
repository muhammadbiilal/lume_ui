/// Every state Home and the Tools hub can be in, and every surface they have
/// to be drawable on.
///
/// Loading, partial, stale, offline, empty and failed are each reachable on
/// their own, because the fixture can be told to fail one section and answer
/// another — which is the only way *partial* is a state rather than a hope.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_destination.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/home/application/home_controller.dart';
import 'package:lume/features/home/data/home_fixtures.dart';
import 'package:lume/features/home/domain/home_repository.dart';

import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';

void main() {
  group('Home while it is still arriving', () {
    testWidgets('draws its own shape, not a spinner', (
      WidgetTester tester,
    ) async {
      final LumeHomeController c = controllerOn(LumeFakeHomeRepository.slow());
      addTearDown(c.dispose);
      unawaited(c.load(LumeUsers.defaultPk));

      await pumpLume(tester, homeScreenFor(c, LumeUsers.defaultPk));
      expect(find.byType(LumeSkeleton), findsWidgets);
      expect(find.text('Quick tools'), findsNothing);
    });

    testWidgets('and never shows the wrong screen first', (
      WidgetTester tester,
    ) async {
      final LumeHomeController c = controllerOn(LumeFakeHomeRepository.slow());
      addTearDown(c.dispose);
      unawaited(c.load(LumeUsers.muslimPk));
      await pumpLume(tester, homeScreenFor(c, LumeUsers.muslimPk));
      // Nothing has been decided, so nothing faith-gated is drawn either way.
      expect(find.text('Next prayer'), findsNothing);
      expect(find.text('Right now'), findsNothing);
    });
  });

  group('a failed load', () {
    testWidgets('says so, and offers the way back', (
      WidgetTester tester,
    ) async {
      final LumeHomeController c = controllerOn(
        const LumeBrokenHomeRepository(),
      );
      addTearDown(c.dispose);
      await c.load(LumeUsers.defaultPk);

      await pumpLume(tester, homeScreenFor(c, LumeUsers.defaultPk));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a failed section is not a failed page', (
      WidgetTester tester,
    ) async {
      final LumeHomeController c = controllerOn(
        LumeFakeHomeRepository(
          failing: const <LumeHomeSection>{LumeHomeSection.live},
        ),
      );
      addTearDown(c.dispose);
      await c.load(LumeUsers.defaultPk);

      await pumpLume(
        tester,
        homeScreenFor(c, LumeUsers.defaultPk),
        surface: LumeViewport.tall,
      );
      // The live row says it could not be fetched…
      expect(find.byType(LumeNotice), findsWidgets);
      // …and everything around it is still there.
      expect(find.text('Quick tools'), findsOneWidget);
      expect(find.text('At a glance'), findsOneWidget);
      expect(find.text('Coming up'), findsOneWidget);
    });
  });

  group('stale and offline are not the same as live (§108)', () {
    Future<void> pumpWith(WidgetTester tester, LumeSourceState state) async {
      final LumeHomeController c = controllerOn(
        LumeFakeHomeRepository(
          sources: <LumeHomeSection, LumeSourceState>{
            LumeHomeSection.live: state,
          },
        ),
      );
      addTearDown(c.dispose);
      await c.load(LumeUsers.defaultPk);
      await pumpLume(
        tester,
        homeScreenFor(c, LumeUsers.defaultPk),
        surface: LumeViewport.tall,
      );
    }

    testWidgets('a cached section says it is cached', (
      WidgetTester tester,
    ) async {
      await pumpWith(tester, LumeSourceState.offline);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Islamabad'), findsWidgets);
    });

    testWidgets('an old section says it is old', (WidgetTester tester) async {
      await pumpWith(tester, LumeSourceState.stale);
      expect(find.text('Not current'), findsOneWidget);
    });

    testWidgets('a live one says nothing at all', (WidgetTester tester) async {
      await pumpWith(tester, LumeSourceState.live);
      expect(find.text('Offline'), findsNothing);
      expect(find.text('Not current'), findsNothing);
    });
  });

  group('a user with nothing recorded', () {
    testWidgets('gets no "Coming up" and no progress cards', (
      WidgetTester tester,
    ) async {
      final LumeHomeController c = controllerOn(
        LumeFakeHomeRepository(empty: true),
      );
      addTearDown(c.dispose);
      await c.load(LumeUsers.defaultPk);

      await pumpLume(
        tester,
        homeScreenFor(c, LumeUsers.defaultPk),
        surface: LumeViewport.tall,
      );
      // No empty section explaining that there is nothing.
      expect(find.text('Coming up'), findsNothing);
      expect(find.byType(LumeProgressCard), findsNothing);
      // And the rest of Home is intact.
      expect(find.text('Quick tools'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('and no badge on a header with nothing to say', (
      WidgetTester tester,
    ) async {
      final LumeHomeController c = controllerOn(
        LumeFakeHomeRepository(empty: true),
      );
      addTearDown(c.dispose);
      await c.load(LumeUsers.defaultPk);
      await pumpLume(tester, homeScreenFor(c, LumeUsers.defaultPk));
      expect(find.text('3'), findsNothing);
    });
  });

  group('a refresh is one fetch', () {
    testWidgets('and arriving twice is not two', (WidgetTester tester) async {
      final LumeFakeHomeRepository repo = LumeFakeHomeRepository();
      final LumeHomeController c = controllerOn(repo);
      addTearDown(c.dispose);

      await c.load(LumeUsers.defaultPk);
      await c.load(LumeUsers.defaultPk);
      expect(repo.loads, 1, reason: 'the same user is not a second fetch');

      await c.refresh();
      expect(repo.loads, 2);

      await c.load(LumeUsers.muslimPk);
      expect(repo.loads, 3, reason: 'a different user is');
    });
  });

  group('every surface', () {
    for (final (String name, Size size) cell in <(String, Size)>[
      ('359 wide', const Size(359, 3000)),
      ('360 wide', const Size(360, 3000)),
      ('390 wide', const Size(390, 3000)),
      ('700 wide', const Size(700, 3000)),
      ('1100 wide', const Size(1100, 3000)),
      ('a phone on its side', const Size(852, 2000)),
    ]) {
      testWidgets('Home draws at ${cell.$1} without overflowing', (
        WidgetTester tester,
      ) async {
        await pumpHome(tester, LumeUsers.muslimPk, surface: cell.$2);
        expect(tester.takeException(), isNull);
        expect(find.text('Quick tools'), findsOneWidget);
      });

      testWidgets('the hub draws at ${cell.$1} without overflowing', (
        WidgetTester tester,
      ) async {
        await pumpTools(tester, LumeUsers.muslimPk, surface: cell.$2);
        expect(tester.takeException(), isNull);
        expect(find.text('Tools'), findsWidgets);
      });
    }

    testWidgets('the narrowest phone drops the grid to two columns', (
      WidgetTester tester,
    ) async {
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(359, 3000),
      );
      final Size tile = tester.getSize(
        find.byKey(const ValueKey<String>('tools.tile.calculator')),
      );
      // 359 − 40 of gutters − 10 of gap, halved.
      expect(tile.width, closeTo(154.5, 1));
    });

    testWidgets('a tablet widens the grid rather than stretching a tile', (
      WidgetTester tester,
    ) async {
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(1100, 3000),
      );
      final Size tile = tester.getSize(
        find.byKey(const ValueKey<String>('tools.tile.calculator')),
      );
      expect(tile.width, lessThan(200), reason: 'five columns, not three wide');
    });
  });

  group('three languages and two directions', () {
    for (final (String code, TextDirection dir) lang
        in <(String, TextDirection)>[
          ('en', TextDirection.ltr),
          ('ur', TextDirection.rtl),
          ('ar', TextDirection.rtl),
        ]) {
      testWidgets('Home in ${lang.$1}', (WidgetTester tester) async {
        await pumpHome(
          tester,
          LumeUsers.muslimPk,
          surface: LumeViewport.tall,
          locale: Locale(lang.$1),
        );
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(LumeToolTile).first)),
          lang.$2,
        );
      });

      testWidgets('the hub in ${lang.$1}', (WidgetTester tester) async {
        await pumpTools(
          tester,
          LumeUsers.muslimPk,
          surface: LumeViewport.tall,
          locale: Locale(lang.$1),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the header runs the other way in Arabic', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, LumeUsers.defaultPk, locale: const Locale('en'));
      final double ltr = tester.getTopLeft(find.byType(LumeAvatarButton)).dx;
      await pumpHome(tester, LumeUsers.defaultPk, locale: const Locale('ar'));
      final double rtl = tester.getTopLeft(find.byType(LumeAvatarButton)).dx;
      expect(ltr, greaterThan(300));
      expect(rtl, lessThan(60), reason: 'the avatar moved to the other edge');
    });
  });

  group('dark, and twice the text', () {
    testWidgets('Home in dark', (WidgetTester tester) async {
      await pumpHome(
        tester,
        LumeUsers.muslimPk,
        surface: LumeViewport.tall,
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home at 200 per cent', (WidgetTester tester) async {
      await pumpHome(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 6000),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Quick tools'), findsOneWidget);
    });

    testWidgets('the hub at 200 per cent', (WidgetTester tester) async {
      await pumpTools(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 9000),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the hero grows rather than clipping its own words', (
      WidgetTester tester,
    ) async {
      await pumpHome(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 6000),
        textScale: 2.0,
      );
      final Size slide = tester.getSize(
        find.byKey(const ValueKey<String>('home.slide.plan')),
      );
      expect(slide.height, greaterThan(194));
    });
  });

  group('what a screen reader is told', () {
    testWidgets('Home names itself, its headings and its badge', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpHome(tester, LumeUsers.muslimPk, surface: LumeViewport.tall);

      expect(find.bySemanticsLabel('Home'), findsWidgets);
      expect(find.bySemanticsLabel('Notifications, 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Search everything'), findsOneWidget);
      expect(find.bySemanticsLabel('Your profile'), findsOneWidget);

      // A heading is a heading, so a reader can jump between sections.
      final SemanticsNode node = tester.getSemantics(find.text('Quick tools'));
      expect(node.flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('a tile says its name and its status, once', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpHome(tester, LumeUsers.defaultPk, surface: LumeViewport.tall);
      expect(find.bySemanticsLabel('Air Quality, AQI'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the hub announces how many tools are showing', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTools(tester, LumeUsers.defaultPk, surface: LumeViewport.tall);
      expect(find.bySemanticsLabel(RegExp('30 tools')), findsWidgets);
      handle.dispose();
    });

    testWidgets('an unavailable tool says why, not just that', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTools(
        tester,
        LumeUsers.defaultPk.copyWith(interests: const <String>{}),
        surface: LumeViewport.tall,
      );
      await tester.tap(find.byKey(const ValueKey<String>('tools.chip.all')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Private')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Local service')), findsWidgets);
      handle.dispose();
    });

    testWidgets('a selected chip says it is selected', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTools(tester, LumeUsers.defaultPk, surface: LumeViewport.tall);
      final SemanticsNode node = tester.getSemantics(
        find.byKey(const ValueKey<String>('tools.chip.foryou')),
      );
      // `isSelected` is a tri-state: unset, true or false. A chip that is on
      // reports the third, and a chip that is off reports the second — both of
      // which are different from saying nothing at all.
      expect(node.flagsCollection.isSelected.name, 'isTrue');
      handle.dispose();
    });
  });
}
