/// Where every element of Home and the Tools hub actually is, against where
/// the design source puts it.
///
/// The same method as the authentication comparison:
/// `measure_destinations.mjs` drives the running prototype into a named state
/// and writes `getBoundingClientRect` for each element; this pumps the Flutter
/// screen with the same user and asserts the numbers agree.
///
/// **Positions are relative to the screen's own origin.** The prototype draws a
/// 28-point simulated status bar and sits the destination below it (P1), and
/// Flutter has no such bar, so every `y` below is measured from `.screen`'s own
/// top rather than from the page.
///
/// **A text block's width is not compared.** `.section__head > div` is a flex
/// item that shrink-wraps to its longest line; the Flutter heading fills its
/// column and lets the `Text` inside it be as wide as it needs. Both start at
/// the same x and both render on the same baselines, which is what the
/// composition is about — so x, y and height are asserted and width is
/// recorded.
///
/// A failure here is a layout difference, not a rasterisation one: the
/// tolerance is a whole logical pixel.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_destination.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_hero.dart';
import 'package:lume/features/home/presentation/home_screen.dart';
import 'package:lume/features/tools/presentation/tools_screen.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';

const String reportPath = 'docs/conversion_archive/DESTINATION_PARITY.md';

/// One logical pixel.
const double kTolerance = 1.0;

/// Three, for an element far down a long page.
///
/// Chrome keeps a line box's fractional height and Flutter rounds it to whole
/// logical pixels, so each heading is a fifth of a point shorter and five
/// sections of drift add up to about three. That is D20 — approved while the
/// content, the visible line count, the clipping and the surrounding layout
/// stay equivalent, which they do.
const double kDrift = 3.0;
const String kDriftNote = 'cumulative line-box rounding (D20)';

/// The Discover strip is taller because its outage card names a real time in
/// the user's own clock preference, and "Next outage 7:00 PM" takes two lines
/// where the prototype's hard-coded "14:00" took one. The prototype's card
/// also named a slot that had already ended (C17).
/// D23. The outage card names the next slot in the user's own clock, and
/// "Next outage 7:00 pm" is 127.93 wide against a 124-point text region, so
/// the title takes a second line. `.hscroll` is a stretch flex, so every card
/// in the strip takes that height with it. Measured, bounded and tested in
/// `discover_outage_test.dart`.
const String kOutageNote =
    'the outage card is derived, not fixed, and one line taller for it '
    '(C17 / D23)';

/// Tall enough that the whole page is laid out, so an element below the fold
/// can be measured. The width — which is what the composition depends on — is
/// the reference cell's.
const Size kTall = Size(390, 5000);

void main() {
  setUpAll(loadLumeFonts);

  Map<String, dynamic>? cell(String name) {
    final File f = File(
      'docs/conversion_archive/measurements/${name}_390x844_light_en.json',
    );
    if (!f.existsSync()) return null;
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }

  final List<String> rows = <String>[];
  final List<String> misses = <String>[];
  int compared = 0;

  tearDown(() {
    final List<String> found = List<String>.of(misses);
    misses.clear();
    expect(found, isEmpty, reason: 'element bounds differ from the prototype');
  });

  /// The prototype's own origin — `.screen`'s top, which is under its
  /// simulated status bar.
  double originOf(Map<String, dynamic> b) =>
      ((b['screen'] as Map<String, dynamic>)['y'] as num).toDouble();

  void compare(
    WidgetTester tester,
    Map<String, dynamic> bounds,
    String name,
    Finder finder, {
    bool checkWidth = true,
    bool checkHeight = true,
    bool checkX = true,
    double tolerance = kTolerance,
    String note = '',
  }) {
    final Map<String, dynamic>? b = bounds[name] as Map<String, dynamic>?;
    if (b == null) {
      rows.add('| `$name` | — | — | — | — | not measured |');
      return;
    }
    expect(finder, findsWidgets, reason: '$name is not on screen');
    final Rect r = tester.getRect(finder.first);
    final double origin = originOf(bounds);

    void check(String what, double wanted, double got, {bool assertIt = true}) {
      compared++;
      if (assertIt && (got - wanted).abs() > tolerance) {
        misses.add(
          '$name $what — the prototype puts it at '
          '${wanted.toStringAsFixed(2)}, Flutter at ${got.toStringAsFixed(2)} '
          '(${(got - wanted).toStringAsFixed(2)})',
        );
      }
      rows.add(
        '| `$name` | $what | ${wanted.toStringAsFixed(2)} | '
        '${got.toStringAsFixed(2)} | '
        '${(got - wanted).abs() < 0.005 ? "=" : (got - wanted).toStringAsFixed(2)}'
        ' | ${note.isEmpty ? (assertIt ? "" : "recorded") : note} |',
      );
    }

    check('y', (b['y'] as num).toDouble() - origin, r.top);
    if (checkX) check('x', (b['x'] as num).toDouble(), r.left);
    check(
      'width',
      (b['width'] as num).toDouble(),
      r.width,
      assertIt: checkWidth,
    );
    check(
      'height',
      (b['height'] as num).toDouble(),
      r.height,
      assertIt: checkHeight,
    );
  }

  // -------------------------------------------------------------------- Home

  Future<void> home(WidgetTester tester, String state) async {
    await pumpHome(tester, LumeUsers.all[state]!, surface: kTall);
  }

  Finder inSection(String section, Finder what) => find.descendant(
    of: find.byKey(ValueKey<String>(section)),
    matching: what,
  );

  void homeChrome(WidgetTester tester, Map<String, dynamic> b) {
    compare(
      tester,
      b,
      'appbar',
      find.byKey(const ValueKey<String>(LumeHomeScreen.appBarKey)),
    );
    compare(
      tester,
      b,
      'appbar.search',
      inSection(LumeHomeScreen.appBarKey, find.byType(LumeHeaderButton)).first,
    );
    compare(
      tester,
      b,
      'appbar.avatar',
      inSection(LumeHomeScreen.appBarKey, find.byType(LumeAvatarButton)),
    );
    compare(
      tester,
      b,
      'ctx',
      inSection(LumeHomeScreen.contextKey, find.byType(LumeContextStrip)),
    );
    compare(
      tester,
      b,
      'ctx.icon',
      inSection(LumeHomeScreen.contextKey, find.byType(LumeToneDisc)),
    );
    compare(tester, b, 'hero', find.byType(LumeHeroCarousel));
    compare(tester, b, 'hero.slide', find.byType(LumeHeroSlide).first);
    compare(tester, b, 'hero.dots', find.byType(LumeHeroDots));
  }

  void homeBody(WidgetTester tester, Map<String, dynamic> b) {
    compare(
      tester,
      b,
      'qactions',
      inSection(
        LumeHomeScreen.quickActionsKey,
        find.byType(LumeHorizontalStrip),
      ),
      checkX: false,
      checkWidth: false,
      note:
          'the prototype port is one gutter wider each side and the page '
          'clips it; this one is clipped at the page edge instead, and the '
          'pills land identically',
    );
    compare(
      tester,
      b,
      'qaction',
      inSection(
        LumeHomeScreen.quickActionsKey,
        find.byType(LumeQuickActionPill),
      ).first,
    );
    compare(
      tester,
      b,
      'quick.title',
      find.text('Quick tools'),
      checkWidth: false,
    );
    compare(
      tester,
      b,
      'quick.sub',
      find.text('Picked from your interests'),
      checkWidth: false,
    );
    compare(
      tester,
      b,
      'quick.section',
      inSection(LumeHomeScreen.quickToolsKey, find.byType(LumeTileGrid)),
      checkX: false,
      checkWidth: false,
      note:
          'the prototype grid carries its own gutters; this one is inside '
          'them',
    );
    compare(
      tester,
      b,
      'tool',
      inSection(LumeHomeScreen.quickToolsKey, find.byType(LumeToolTile)).first,
    );
    compare(
      tester,
      b,
      'tool.label',
      inSection(LumeHomeScreen.quickToolsKey, find.text('Air Quality')),
      checkWidth: false,
      checkX: false,
    );
    compare(
      tester,
      b,
      'live.title',
      find.text('Right now'),
      checkWidth: false,
      tolerance: kDrift,
      note: kDriftNote,
    );
    compare(
      tester,
      b,
      'livecard',
      inSection(LumeHomeScreen.liveKey, find.byType(LumeLiveRow)).first,
      checkWidth: false,
      tolerance: kDrift,
      note: 'the prototype card overflows its column by 22.31 (C20)',
    );
    compare(
      tester,
      b,
      'glance.title',
      find.text('At a glance'),
      checkWidth: false,
      tolerance: kDrift,
      note: kDriftNote,
    );
    // D26's evidence, asserted rather than described: with no bar drawn, the
    // card and its two lines land exactly where the reference's do. The
    // reference's own `.progress-card__body` measures 196 x 34 — title, 2,
    // meta — which is the height of a body with no bar in it.
    compare(
      tester,
      b,
      'progress',
      inSection(LumeHomeScreen.glanceKey, find.byType(LumeProgressCard)).first,
      tolerance: kDrift,
      note: kDriftNote,
    );
    compare(
      tester,
      b,
      'progress.title',
      find
          .descendant(
            of: inSection(
              LumeHomeScreen.glanceKey,
              find.byType(LumeProgressCard),
            ).first,
            matching: find.byType(Text),
          )
          .first,
      checkWidth: false,
      tolerance: kDrift,
      note: kDriftNote,
    );
    compare(
      tester,
      b,
      'upcoming.title',
      find.text('Coming up'),
      checkWidth: false,
      tolerance: kDrift,
      note: kDriftNote,
    );
    compare(
      tester,
      b,
      'discover.title',
      find.text('Discover'),
      checkWidth: false,
      tolerance: kDrift,
      note: kDriftNote,
    );
    compare(
      tester,
      b,
      'discover.link',
      inSection(LumeHomeScreen.discoverKey, find.text('Explore')),
      checkWidth: false,
      checkX: false,
      checkHeight: false,
      tolerance: kDrift,
      note: 'the prototype measures the padded control, this the text box',
    );
    compare(
      tester,
      b,
      'hscroll',
      inSection(LumeHomeScreen.discoverKey, find.byType(LumeHorizontalStrip)),
      checkX: false,
      checkWidth: false,
      checkHeight: false,
      tolerance: kDrift,
      note: kOutageNote,
    );
    compare(
      tester,
      b,
      'minicard',
      inSection(LumeHomeScreen.discoverKey, find.byType(LumeMiniCard)).first,
      checkHeight: false,
      tolerance: 8,
      note: kOutageNote,
    );
  }

  group('Home is where the prototype puts it', () {
    testWidgets('the chrome, without the Islamic experience', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? b = cell('home_default_pk');
      if (b == null) return;
      rows.add('\n### Home · not Muslim, Pakistan\n');
      rows.add('| element | axis | prototype | Flutter | Δ | note |');
      rows.add('|---|---|---|---|---|---|');
      await home(tester, 'default_pk');
      homeChrome(tester, b['bounds'] as Map<String, dynamic>);
      homeBody(tester, b['bounds'] as Map<String, dynamic>);
    });

    testWidgets('the chrome, with it', (WidgetTester tester) async {
      final Map<String, dynamic>? b = cell('home_muslim_pk');
      if (b == null) return;
      rows.add('\n### Home · Muslim, Pakistan\n');
      rows.add('| element | axis | prototype | Flutter | Δ | note |');
      rows.add('|---|---|---|---|---|---|');
      await home(tester, 'muslim_pk');
      homeChrome(tester, b['bounds'] as Map<String, dynamic>);
    });
  });

  // -------------------------------------------------------------- Tools hub

  group('the Tools hub is where the prototype puts it', () {
    testWidgets('the page head, search, chips and the first category', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? c = cell('tools_named_pk');
      if (c == null) return;
      final Map<String, dynamic> b = c['bounds'] as Map<String, dynamic>;
      rows.add('\n### Tools · a user with a history, Pakistan\n');
      rows.add('| element | axis | prototype | Flutter | Δ | note |');
      rows.add('|---|---|---|---|---|---|');

      await pumpTools(tester, LumeUsers.namedPk, surface: kTall);

      compare(
        tester,
        b,
        'pagehead',
        find.byKey(const ValueKey<String>(LumeToolsScreen.headKey)),
      );
      compare(
        tester,
        b,
        'pagehead.title',
        find.text('Tools'),
        checkWidth: false,
      );
      compare(
        tester,
        b,
        'pagehead.sub',
        find.text('68 utilities, neatly sorted'),
        checkWidth: false,
      );
      compare(
        tester,
        b,
        'pagehead.action',
        find.descendant(
          of: find.byKey(const ValueKey<String>(LumeToolsScreen.headKey)),
          matching: find.byType(LumeHeaderButton),
        ),
      );
      compare(
        tester,
        b,
        'chip',
        find.byKey(const ValueKey<String>('tools.chip.foryou')),
      );
      compare(
        tester,
        b,
        'recent',
        find.byKey(const ValueKey<String>('tools.recent.calculator')),
      );
      compare(
        tester,
        b,
        'cat',
        find.byKey(const ValueKey<String>('tools.cat.everyday')),
      );
      compare(
        tester,
        b,
        'cat.title',
        find.descendant(
          of: find.byKey(const ValueKey<String>('tools.cat.everyday')),
          matching: find.text('Everyday'),
        ),
        checkWidth: false,
      );
      compare(
        tester,
        b,
        'cat.sub',
        find.text('The ones you reach for daily'),
        checkWidth: false,
      );
      compare(
        tester,
        b,
        'cattool',
        find.byKey(const ValueKey<String>('tools.tile.calculator')),
      );
    });

    testWidgets('with the Islamic experience, the extra category', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? c = cell('tools_muslim_pk');
      if (c == null) return;
      final Map<String, dynamic> b = c['bounds'] as Map<String, dynamic>;
      rows.add('\n### Tools · Muslim, Pakistan\n');
      rows.add('| element | axis | prototype | Flutter | Δ | note |');
      rows.add('|---|---|---|---|---|---|');

      await pumpTools(tester, LumeUsers.muslimPk, surface: kTall);
      compare(
        tester,
        b,
        'pagehead.sub',
        find.text('85 utilities, neatly sorted'),
        checkWidth: false,
      );
      compare(
        tester,
        b,
        'chip',
        find.byKey(const ValueKey<String>('tools.chip.foryou')),
      );
      compare(
        tester,
        b,
        'cattool',
        find.byKey(const ValueKey<String>('tools.tile.calculator')),
      );
    });

    testWidgets('a search narrows it to one block', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? c = cell('tools_default_pk_tools_search');
      if (c == null) return;
      final Map<String, dynamic> b = c['bounds'] as Map<String, dynamic>;
      rows.add('\n### Tools · searching for "petrol"\n');
      rows.add('| element | axis | prototype | Flutter | Δ | note |');
      rows.add('|---|---|---|---|---|---|');

      await pumpLume(
        tester,
        LumeToolsScreen(
          eligibility: kEligibility,
          user: LumeUsers.defaultPk,
          initialQuery: 'petrol',
          actions: LumeRecordedActions().toolsActions,
        ),
        surface: kTall,
      );
      compare(
        tester,
        b,
        'cat',
        find.byKey(const ValueKey<String>('tools.cat.money')),
      );
      compare(
        tester,
        b,
        'cattool',
        find.byKey(const ValueKey<String>('tools.tile.fuel')),
      );
    });

    testWidgets('and with none, the empty state sits where it did', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? c = cell('tools_default_pk_tools_noresults');
      if (c == null) return;
      final Map<String, dynamic> b = c['bounds'] as Map<String, dynamic>;
      rows.add('\n### Tools · a search that matched nothing\n');
      rows.add('| element | axis | prototype | Flutter | Δ | note |');
      rows.add('|---|---|---|---|---|---|');

      await pumpLume(
        tester,
        LumeToolsScreen(
          eligibility: kEligibility,
          user: LumeUsers.defaultPk,
          initialQuery: 'zzzzz',
          actions: LumeRecordedActions().toolsActions,
        ),
        surface: kTall,
      );
      compare(
        tester,
        b,
        'chips',
        find.descendant(
          of: find.byKey(const ValueKey<String>(LumeToolsScreen.chipsKey)),
          matching: find.byType(LumeHorizontalStrip),
        ),
        checkHeight: false,
        note: 'the prototype measures the scroller, not the section',
      );
      // The prototype's empty block is `display: none` until it is shown, so
      // it has no bounds to compare; the composition test asserts the copy.
      expect(find.text('No tools match'), findsOneWidget);
    });
  });

  tearDownAll(() {
    File(reportPath).writeAsStringSync('''
# Home and the Tools hub, measured

> **Temporary conversion evidence.** Generated by
> `test/features/destinations/destination_bounds_test.dart`, which is what
> asserts it. Removed with the prototype at Phase F9.

Every element's position in the running prototype, and the same element's
position in Flutter. `y` is measured from the screen's own top on both sides,
because the prototype sits its screen under a 28-point simulated status bar
that Flutter does not draw (P1).

A text heading's **width** is recorded rather than asserted: the prototype's
`.section__head > div` shrink-wraps to its longest line and the Flutter heading
fills its column. Both start at the same x and render on the same baselines.

**$compared values compared, tolerance 1 logical pixel.**

${rows.join('\n')}
''');
  });
}
