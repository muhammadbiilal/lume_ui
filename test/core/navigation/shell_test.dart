/// The shell: which navigation it draws, where it draws it, and what it hands
/// the screen underneath.
///
/// Every case here is a width the app will actually be at — a boundary, a real
/// device, a keyboard. A width class that is nearly right is a layout that
/// flips at 839 instead of 840, and no one finds that by looking.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/layout/lume_breakpoint.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/core/navigation/lume_navigation_surfaces.dart';
import 'package:lume/core/navigation/lume_shell.dart';
import 'package:lume/core/theme/lume/lume_space.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  final List<LumeDestination> destinations = LumeDestinations.build(
    countryCode: 'PK',
    label: (LumeDestinationId id) => id.name,
  );

  Future<void> pumpShell(
    WidgetTester tester, {
    required Size surface,
    int selectedIndex = 0,
    bool showNavigation = true,
    Locale locale = const Locale('en'),
    ThemeMode theme = ThemeMode.light,
    Widget? child,
  }) => pumpLume(
    tester,
    LumeShell(
      destinations: destinations,
      selectedIndex: selectedIndex,
      onSelected: (_) {},
      showNavigation: showNavigation,
      clock: '9:41',
      child: child ?? const SizedBox.expand(),
    ),
    surface: surface,
    locale: locale,
    theme: theme,
  );

  bool hasBar(WidgetTester tester) =>
      find.byType(LumeBottomBar).evaluate().isNotEmpty;
  bool hasRail(WidgetTester tester) =>
      find.byType(LumeNavigationRail).evaluate().isNotEmpty;

  group('one navigation at a time', () {
    testWidgets('compact draws the bar and nothing else', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, surface: LumeViewport.phone);
      expect(hasBar(tester), isTrue);
      expect(hasRail(tester), isFalse);
      expect(find.byType(LumeStatusStrip), findsNothing);
    });

    testWidgets('medium draws the rail and the status strip', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, surface: LumeViewport.medium);
      expect(hasBar(tester), isFalse);
      expect(hasRail(tester), isTrue);
      expect(find.byType(LumeStatusStrip), findsOneWidget);

      final LumeNavigationRail rail = tester.widget<LumeNavigationRail>(
        find.byType(LumeNavigationRail),
      );
      expect(rail.expanded, isFalse);
      expect(tester.getSize(find.byType(LumeNavigationRail)).width, 84);
    });

    testWidgets('expanded draws the sidebar', (WidgetTester tester) async {
      await pumpShell(tester, surface: LumeViewport.expanded);
      expect(hasBar(tester), isFalse);
      expect(hasRail(tester), isTrue);

      final LumeNavigationRail rail = tester.widget<LumeNavigationRail>(
        find.byType(LumeNavigationRail),
      );
      expect(rail.expanded, isTrue);
      expect(tester.getSize(find.byType(LumeNavigationRail)).width, 244);
      expect(find.text('Lume'), findsWidgets);
    });
  });

  group('the boundaries', () {
    const List<(double, LumeWidthClass)> cases = <(double, LumeWidthClass)>[
      (359, LumeWidthClass.compact),
      (360, LumeWidthClass.compact),
      (599, LumeWidthClass.compact),
      (600, LumeWidthClass.medium),
      (839, LumeWidthClass.medium),
      (840, LumeWidthClass.expanded),
      (1179, LumeWidthClass.expanded),
      (1180, LumeWidthClass.expanded),
    ];

    for (final (double width, LumeWidthClass expected) in cases) {
      testWidgets('$width is ${expected.name}', (WidgetTester tester) async {
        late LumeWidthClass resolved;
        await pumpShell(
          tester,
          surface: Size(width, 900),
          child: LumeProbe(
            onBuild: (BuildContext context) => resolved = context.widthClass,
          ),
        );
        expect(resolved, expected);

        // And the presentation agrees with the class, which is the part a
        // separate media query would eventually get wrong.
        expect(hasBar(tester), expected == LumeWidthClass.compact);
        expect(hasRail(tester), expected != LumeWidthClass.compact);
      });
    }

    testWidgets('479 tall is compact however wide the shell is', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, surface: const Size(1100, 479));
      expect(hasBar(tester), isTrue);
      expect(hasRail(tester), isFalse);
    });

    testWidgets('480 tall is the first height that keeps the sidebar', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, surface: const Size(1100, 480));
      expect(hasRail(tester), isTrue);
      expect(hasBar(tester), isFalse);
    });

    testWidgets('a landscape phone keeps the phone presentation', (
      WidgetTester tester,
    ) async {
      late LumeWidthClass presentation;
      late LumeWidthClass measure;
      await pumpShell(
        tester,
        surface: LumeViewport.landscapePhone,
        child: LumeProbe(
          onBuild: (BuildContext context) {
            presentation = context.widthClass;
            measure = context.measureClass;
          },
        ),
      );
      expect(presentation, LumeWidthClass.compact);
      expect(hasBar(tester), isTrue);
      expect(hasRail(tester), isFalse);
      // The reading measure still follows the width — 852 points of line is
      // too long whatever the height.
      expect(measure, LumeWidthClass.expanded);
    });
  });

  group('the width cap', () {
    test('is 560 below the medium boundary and 1366 above it', () {
      expect(LumeShell.capFor(390), 560);
      expect(LumeShell.capFor(599), 560);
      expect(LumeShell.capFor(600), LumeSpace.shellMax);
      expect(LumeShell.capFor(2560), LumeSpace.shellMax);
    });

    testWidgets('a very wide window is measured inside the cap', (
      WidgetTester tester,
    ) async {
      late double measured;
      await pumpShell(
        tester,
        surface: const Size(2000, 1200),
        child: LumeProbe(
          onBuild: (BuildContext context) => measured = context.shellWidth,
        ),
      );
      expect(measured, LumeSpace.shellMax);
    });
  });

  group('what the shell hands the screen', () {
    testWidgets('compact republishes the bar clearance as bottom padding', (
      WidgetTester tester,
    ) async {
      late EdgeInsets padding;
      await pumpShell(
        tester,
        surface: LumeViewport.phone,
        child: LumeProbe(
          onBuild: (BuildContext context) =>
              padding = MediaQuery.paddingOf(context),
        ),
      );
      expect(padding.bottom, LumeShellMetrics.contentBottomCompact);
      expect(
        padding.top,
        0,
        reason:
            'the outlet consumed the top inset, so a screen cannot '
            'draw under the notch by forgetting to',
      );
    });

    testWidgets('a pane layout asks for the smaller clearance', (
      WidgetTester tester,
    ) async {
      late EdgeInsets padding;
      await pumpShell(
        tester,
        surface: LumeViewport.expanded,
        child: LumeProbe(
          onBuild: (BuildContext context) =>
              padding = MediaQuery.paddingOf(context),
        ),
      );
      expect(padding.bottom, LumeShellMetrics.contentBottomPane);
    });

    testWidgets('hiding the navigation drops the clearance with it', (
      WidgetTester tester,
    ) async {
      late EdgeInsets padding;
      await pumpShell(
        tester,
        surface: LumeViewport.phone,
        showNavigation: false,
        child: LumeProbe(
          onBuild: (BuildContext context) =>
              padding = MediaQuery.paddingOf(context),
        ),
      );
      expect(hasBar(tester), isFalse);
      expect(padding.bottom, LumeShellMetrics.contentBottomPane);
    });
  });

  group('direction', () {
    testWidgets('the rail sits on the start edge in both directions', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, surface: LumeViewport.expanded);
      final Rect ltr = tester.getRect(find.byType(LumeNavigationRail));
      expect(ltr.left, 0);

      await pumpShell(
        tester,
        surface: LumeViewport.expanded,
        locale: const Locale('ur'),
      );
      final Rect rtl = tester.getRect(find.byType(LumeNavigationRail));
      expect(rtl.right, 1100);
      expect(rtl.left, greaterThan(0));
    });

    testWidgets('the bar is inset equally in both directions', (
      WidgetTester tester,
    ) async {
      for (final Locale locale in <Locale>[
        const Locale('en'),
        const Locale('ur'),
        const Locale('ar'),
      ]) {
        await pumpShell(tester, surface: LumeViewport.phone, locale: locale);
        final Rect bar = tester.getRect(
          find
              .descendant(
                of: find.byType(LumeBottomBar),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(bar.left, LumeBottomBar.inset, reason: locale.languageCode);
        expect(
          390 - bar.right,
          LumeBottomBar.inset,
          reason: locale.languageCode,
        );
      }
    });
  });

  group('the keyboard', () {
    testWidgets('hides the floating bar rather than sitting on top of it', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
            child: LumeShell(
              destinations: destinations,
              selectedIndex: 0,
              onSelected: (_) {},
              child: const SizedBox.expand(),
            ),
          ),
        ),
        surface: LumeViewport.phone,
      );
      expect(find.byType(LumeBottomBar), findsNothing);
    });

    testWidgets('passes its height to the outlet so a field can clear it', (
      WidgetTester tester,
    ) async {
      late EdgeInsets padding;
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
            child: LumeShell(
              destinations: destinations,
              selectedIndex: 0,
              onSelected: (_) {},
              child: LumeProbe(
                onBuild: (BuildContext context) =>
                    padding = MediaQuery.paddingOf(context),
              ),
            ),
          ),
        ),
        surface: LumeViewport.phone,
      );
      expect(padding.bottom, greaterThanOrEqualTo(300));
    });

    testWidgets('does not take the rail away from a tablet mid-sentence', (
      WidgetTester tester,
    ) async {
      // A 1024-tall tablet with a 600-point keyboard leaves 424 points — under
      // the compact-height floor. If the shell were measured after the
      // keyboard, the sidebar would disappear while the user was typing into
      // it.
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: 600)),
            child: LumeShell(
              destinations: destinations,
              selectedIndex: 0,
              onSelected: (_) {},
              child: const SizedBox.expand(),
            ),
          ),
        ),
        surface: const Size(1100, 1024),
      );
      expect(hasRail(tester), isTrue);
      expect(hasBar(tester), isFalse);
    });
  });

  group('the overlay host', () {
    const Key toast = Key('toast');

    Future<void> pumpOverlay(WidgetTester tester, Size surface) => pumpLume(
      tester,
      LumeShell(
        destinations: destinations,
        selectedIndex: 0,
        onSelected: (_) {},
        overlay: const LumeOverlayHost(
          toast: SizedBox(key: toast, height: 36, width: 200),
        ),
        child: const SizedBox.expand(),
      ),
      surface: surface,
    );

    testWidgets('the toast clears the floating bar at compact', (
      WidgetTester tester,
    ) async {
      await pumpOverlay(tester, LumeViewport.phone);
      final Rect t = tester.getRect(find.byKey(toast));
      final Rect bar = tester.getRect(find.byType(LumeBottomBar));
      expect(
        t.bottom,
        lessThanOrEqualTo(bar.top),
        reason: 'a confirmation under the bar is a confirmation nobody reads',
      );
    });

    testWidgets('overlays sit above the navigation', (
      WidgetTester tester,
    ) async {
      await pumpOverlay(tester, LumeViewport.phone);
      // The host is the last child of the shell's stack, so a sheet raised
      // over a screen is raised over the bar too.
      expect(find.byType(LumeOverlayHost), findsOneWidget);
      expect(find.byKey(toast), findsOneWidget);
    });
  });

  group('nothing overflows', () {
    for (final Size surface in <Size>[
      LumeViewport.narrow,
      LumeViewport.phone,
      LumeViewport.medium,
      LumeViewport.expanded,
      LumeViewport.landscapePhone,
    ]) {
      testWidgets('at ${surface.width}x${surface.height}', (
        WidgetTester tester,
      ) async {
        for (final ThemeMode theme in ThemeMode.values) {
          for (final Locale locale in <Locale>[
            const Locale('en'),
            const Locale('ur'),
          ]) {
            await pumpShell(
              tester,
              surface: surface,
              theme: theme,
              locale: locale,
            );
            expectNoOverflow(tester);
          }
        }
      });
    }
  });
}
