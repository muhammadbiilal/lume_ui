/// Golden coverage for the shell and its navigation.
///
/// Same division of labour as the component goldens: `navigation_parity_test`
/// and `shell_test` prove the surfaces match Lume and behave; these freeze what
/// they agreed, so a later edit that quietly moves a pill or drops a wordmark
/// is caught by an image rather than by someone noticing.
///
/// The matrix is the one the F3 scope asks for — 390×844, 700×900, 1100×900 and
/// 852×393, in light, dark and Urdu — because a shell is exactly the thing that
/// looks right in one of those and wrong in another.
///
/// Run `flutter test --update-goldens` only when a change to the design is
/// intended and approved.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/core/navigation/lume_shell.dart';
import 'package:lume/core/theme/lume/lume_colors.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/theme/lume/lume_theme.dart';
import 'package:lume/core/widgets/lume/lume.dart';

import '../helpers/load_fonts.dart';
import '../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// Labels are the destination ids, so a golden does not move when a
  /// translation is edited. The layout is what these images are about.
  String label(LumeDestinationId id) => switch (id) {
    LumeDestinationId.home => 'Home',
    LumeDestinationId.tools => 'Tools',
    LumeDestinationId.trains => 'Trains',
    LumeDestinationId.today => 'Today',
    LumeDestinationId.explore => 'Explore',
    LumeDestinationId.profile => 'Profile',
  };

  List<LumeDestination> destinations({
    String country = 'PK',
    Map<LumeDestinationId, int> badges = const <LumeDestinationId, int>{},
    Set<LumeDestinationId> dots = const <LumeDestinationId>{},
  }) => LumeDestinations.build(
    countryCode: country,
    label: label,
    badges: badges,
    dots: dots,
  );

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Size surface,
    int selectedIndex = 0,
    ThemeMode theme = ThemeMode.light,
    Locale locale = const Locale('en'),
    List<LumeDestination>? set,
  }) async {
    await pumpLume(
      tester,
      LumeShell(
        destinations: set ?? destinations(),
        selectedIndex: selectedIndex,
        onSelected: (_) {},
        clock: '9:41',
        navigationLabel: 'Main',
        child: const _Content(),
      ),
      theme: theme,
      locale: locale,
      surface: surface,
    );
    await expectLater(
      find.byType(LumeShell),
      matchesGoldenFile('images/$name.png'),
    );
  }

  group('the three presentations', () {
    testWidgets('compact', (WidgetTester tester) async {
      await golden(tester, 'shell_compact', surface: const Size(390, 844));
    });

    testWidgets('medium', (WidgetTester tester) async {
      await golden(tester, 'shell_medium', surface: const Size(700, 900));
    });

    testWidgets('expanded', (WidgetTester tester) async {
      await golden(tester, 'shell_expanded', surface: const Size(1100, 900));
    });

    testWidgets('landscape phone keeps the phone presentation', (
      WidgetTester tester,
    ) async {
      await golden(tester, 'shell_landscape', surface: const Size(852, 393));
    });
  });

  group('dark', () {
    testWidgets('compact', (WidgetTester tester) async {
      await golden(
        tester,
        'shell_compact_dark',
        surface: const Size(390, 844),
        theme: ThemeMode.dark,
      );
    });

    testWidgets('expanded', (WidgetTester tester) async {
      await golden(
        tester,
        'shell_expanded_dark',
        surface: const Size(1100, 900),
        theme: ThemeMode.dark,
      );
    });
  });

  group('Urdu, right to left', () {
    testWidgets('compact', (WidgetTester tester) async {
      await golden(
        tester,
        'shell_compact_ur',
        surface: const Size(390, 844),
        locale: const Locale('ur'),
      );
    });

    testWidgets('expanded', (WidgetTester tester) async {
      await golden(
        tester,
        'shell_expanded_ur',
        surface: const Size(1100, 900),
        locale: const Locale('ur'),
      );
    });
  });

  group('the states the router can put it in', () {
    testWidgets('no destination selected', (WidgetTester tester) async {
      await golden(
        tester,
        'shell_no_selection',
        surface: const Size(390, 844),
        selectedIndex: -1,
      );
    });

    testWidgets('a badge and a dot', (WidgetTester tester) async {
      await golden(
        tester,
        'shell_badges',
        surface: const Size(390, 844),
        set: destinations(
          badges: const <LumeDestinationId, int>{LumeDestinationId.today: 3},
          dots: const <LumeDestinationId>{LumeDestinationId.profile},
        ),
      );
    });

    testWidgets('a country whose tab set has Explore', (
      WidgetTester tester,
    ) async {
      await golden(
        tester,
        'shell_global_set',
        surface: const Size(390, 844),
        set: destinations(country: 'GB'),
      );
    });
  });
}

/// Something in the outlet, so the goldens show what a screen sits inside
/// rather than an empty box.
class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      children: <Widget>[
        const LumeToolbar(title: 'Good morning', subtitle: 'Monday, 7 Sept'),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LumeSpace.pageCompact,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LumeCard(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < 4; i++)
                      LumeCompactRow(
                        label: 'Row ${i + 1}',
                        value: '${(i + 1) * 12}',
                        chevron: false,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: LumeSpace.gapCard),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: lume.card2,
                  borderRadius: LumeRadius.brLg,
                  border: Border.all(
                    color: lume.border,
                    width: LumeSpace.border,
                  ),
                ),
                child: const SizedBox(height: 160, width: double.infinity),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
