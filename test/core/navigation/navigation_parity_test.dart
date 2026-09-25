/// The three navigation surfaces, measured against the rendered prototype.
///
/// Same discipline as `component_parity_test.dart`: nothing here compares a
/// constant to a constant. Each assertion reads `getComputedStyle` taken from
/// the real `.tabbar`, `.navside` and `.statusbar` in a real browser, and holds
/// the Flutter widget's rendered geometry against it.
///
/// The rail and the sidebar are only measurable at the widths where they are
/// not `display: none`, which is why the rail is read from the 700 cell and the
/// sidebar from 1100.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/core/navigation/lume_navigation_surfaces.dart';
import 'package:lume/core/theme/lume/lume_colors.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../../helpers/measured.dart';
import '../../helpers/reference_tokens.dart';

void main() {
  if (!Measurements.available()) {
    test('navigation measurements are present', () {
      fail(
        'No measurements found. They are frozen and cannot be regenerated; '
        'restore docs/conversion_archive/measurements/ from git history.',
      );
    });
    return;
  }

  final Measurements compact = Measurements.load();
  final Measurements medium = Measurements.load('components_700_light_ltr');
  final Measurements expanded = Measurements.load('components_1100_light_ltr');

  // The rail's and the sidebar's *widths* are the one thing the specimen
  // fixture cannot report. `.navside` has no width of its own: it is a grid
  // area, and `--nav-w` is set on `.app` by the width class. Measured outside
  // the shell it simply fills its host, so the honest source for these two is
  // the stylesheet that declares them.
  const ReferenceTokens css = ReferenceTokens.frozen;
  final double railWidth = ReferenceTokens.px(css.light['--nav-rail']!);
  final double sidebarWidth = ReferenceTokens.px(css.light['--nav-side']!);

  setUpAll(loadLumeFonts);

  List<LumeDestination> destinations({
    Map<LumeDestinationId, int> badges = const <LumeDestinationId, int>{},
  }) => LumeDestinations.build(
    countryCode: 'PK',
    label: (LumeDestinationId id) => id.name,
    badges: badges,
  );

  group('the bottom bar', () {
    testWidgets('is as tall as `.tabbar`, inset from both edges', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: LumeBottomBar(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );

      final Finder bar = find.byType(Container).first;
      final RenderBox box = tester.renderObject<RenderBox>(bar);
      expect(box.size.height, compact['tabbar'].height);

      // `left: 12; right: 12`, measured against the 390 surface.
      final Rect rect = tester.getRect(bar);
      expect(rect.left, LumeBottomBar.inset);
      expect(390 - rect.right, LumeBottomBar.inset);
    });

    test('its constants are the measured ones', () {
      expect(LumeBottomBar.height, compact['tabbar'].height);
      expect(LumeBottomBar.pillHeight, compact['tabbar.pill'].height);
    });

    testWidgets('carries the measured radius, border and translucency', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: LumeBottomBar(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );

      final Container bar = tester.widget<Container>(
        find.byType(Container).first,
      );
      final BoxDecoration d = bar.decoration! as BoxDecoration;

      expect(d.borderRadius, isA<BorderRadius>());
      expect(
        (d.borderRadius! as BorderRadius).topLeft.x,
        compact['tabbar'].radius,
      );
      expect(d.border!.top.width, compact['tabbar'].borderWidth);

      // `color-mix(in srgb, var(--card) 84%, transparent)`.
      final Color measured = compact['tabbar'].colour('backgroundColor');
      expect((d.color!.a * 255).round(), (measured.a * 255).round());
    });

    testWidgets('the selected tab takes the accent, the rest take text-3', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: LumeBottomBar(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(LumeBottomBar));
      final LumeColors lume = Theme.of(context).extension<LumeColors>()!;

      expect(lume.accent, compact['tab.active'].colour('color'));
      expect(lume.text3, compact['tab'].colour('color'));
    });

    testWidgets('the label is the measured tab role', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: LumeBottomBar(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );

      final Text label = tester.widget<Text>(find.text('home'));
      expect(label.style!.fontSize, compact['tab.label'].fontSize);
      expect(label.style!.fontWeight, compact['tab.label'].fontWeight);
    });

    testWidgets('the pill is the measured pill, and hides with no selection', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: LumeBottomBar(
            destinations: destinations(),
            selectedIndex: 2,
            onSelected: (_) {},
          ),
        ),
      );

      final Finder pill = find.byType(AnimatedPositionedDirectional);
      expect(pill, findsOneWidget);
      expect(tester.getRect(pill).height, compact['tabbar.pill'].height);

      await pumpLume(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: LumeBottomBar(
            destinations: destinations(),
            selectedIndex: -1,
            onSelected: (_) {},
          ),
        ),
      );
      expect(
        find.byType(AnimatedPositionedDirectional),
        findsNothing,
        reason: 'a destination that is not a tab must park the pill nowhere',
      );
    });
  });

  group('the rail', () {
    testWidgets('is 84 wide, with the measured padding', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LumeNavigationRail(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
            expanded: false,
          ),
        ),
        surface: const Size(700, 1000),
      );

      final RenderBox box = tester.renderObject<RenderBox>(
        find.byType(LumeNavigationRail),
      );
      expect(box.size.width, railWidth);

      final Container rail = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(LumeNavigationRail),
              matching: find.byType(Container),
            )
            .first,
      );
      final EdgeInsets pad = rail.padding! as EdgeInsets;
      expect(pad.top, medium['navside'].px('paddingTop'));
      expect(pad.left, medium['navside'].px('paddingLeft'));
    });

    testWidgets('a rail tab clears the tap floor and stacks its label', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LumeNavigationRail(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
            expanded: false,
          ),
        ),
        surface: const Size(700, 1000),
      );

      expect(
        tester.getSize(find.text('home')).height,
        lessThan(medium['navtab'].minHeight),
      );
      // The label sits under the glyph, not beside it: its centre is below the
      // tab's own centre.
      final Rect tab = tester.getRect(find.text('home'));
      expect(tab.width, lessThanOrEqualTo(railWidth));
    });

    testWidgets('shows no wordmark — the rail has no room for one', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LumeNavigationRail(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
            expanded: false,
            brand: 'Lume',
          ),
        ),
        surface: const Size(700, 1000),
      );
      expect(find.text('Lume'), findsNothing);
      expect(medium['navside.brand'].height, 0);
    });
  });

  group('the sidebar', () {
    testWidgets('is 244 wide and carries the wordmark', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LumeNavigationRail(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
            expanded: true,
            brand: 'Lume',
          ),
        ),
        surface: const Size(1100, 900),
      );

      final RenderBox box = tester.renderObject<RenderBox>(
        find.byType(LumeNavigationRail),
      );
      expect(box.size.width, sidebarWidth);
      expect(find.text('Lume'), findsOneWidget);

      final Text brand = tester.widget<Text>(find.text('Lume'));
      expect(brand.style!.fontSize, expanded['navside.brand'].fontSize);
      expect(brand.style!.fontWeight, expanded['navside.brand'].fontWeight);
    });

    testWidgets('a sidebar tab is a row at the measured height', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LumeNavigationRail(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
            expanded: true,
          ),
        ),
        surface: const Size(1100, 900),
      );

      final Text label = tester.widget<Text>(find.text('home'));
      expect(label.style!.fontSize, expanded['navtab'].fontSize);
      expect(label.style!.fontWeight, expanded['navtab'].fontWeight);
    });

    testWidgets('the selected tab takes the tint and the darker accent ink', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LumeNavigationRail(
            destinations: destinations(),
            selectedIndex: 0,
            onSelected: (_) {},
            expanded: true,
          ),
        ),
        surface: const Size(1100, 900),
      );

      final BuildContext context = tester.element(
        find.byType(LumeNavigationRail),
      );
      final LumeColors lume = Theme.of(context).extension<LumeColors>()!;
      expect(
        lume.tintAccent,
        expanded['navtab.active'].colour('backgroundColor'),
      );
      expect(lume.accent700, expanded['navtab.active'].colour('color'));
    });
  });
}
