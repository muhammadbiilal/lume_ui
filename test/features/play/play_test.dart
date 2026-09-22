/// Play, against the running reference, and used.
///
/// The reference's own `sect2` — "Recently played", three rows carrying
/// `38 plays`, `21 plays`, `14 plays` — and the `best` figure on each tile
/// (`01:42`, `182 pts`, `24 moves`, `96%`) are gone, because nothing stores a
/// game history and a record nobody set is not a record. They are therefore
/// not in `elements()`: a subtraction is not a tolerance. What remains — the
/// tool bar, the Games section and its head — is compared to the point, and
/// the source bar and the related tools, which the removed section used to
/// push down the page, are checked for content rather than position.
///
/// `nothing here is anyone's record` is the test that matters. It checks each
/// dropped figure by name against every string on the screen, and then walks
/// the tool's own two sections failing on anything merely *shaped* like a
/// score, a best time, a count of plays or a heading about recency — so a
/// later hand that restored the fixture, or invented its own figure, would
/// fail it on the first tile rather than on a literal it happened to match.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icon.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/play/data/play_fixtures.dart';
import 'package:lume/features/play/presentation/play_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/lifecycle.dart';
import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tools/tool_parity.dart';
import 'play_harness.dart';

/// The localisations the pumped screen resolved.
AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(lumeContext(tester, find.byType(LumePlayTool)));

/// Every string the screen draws, in paint order.
List<String> allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((Text t) => (t.data ?? t.textSpan!.toPlainText()).trim())
    .where((String s) => s.isNotEmpty)
    .toList();

/// Every string **the tool itself** draws. The frame around it belongs to
/// the app, not to Play: on the real router a notification banner can
/// arrive while a test is pumping, and that is the shell doing its job,
/// not the screen changing. Anything asserting that Play did not move
/// compares this, not [allText].
List<String> toolText(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(LumePlayTool),
        matching: find.byType(Text),
      ),
    )
    .map((Text t) => (t.data ?? t.textSpan!.toPlainText()).trim())
    .where((String s) => s.isNotEmpty)
    .toList();

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('play');
  tearDownAll(parity.write);

  /// `sect1` is the `<section>` box — the head and the grid, without the
  /// margin above it, which is what `getBoundingClientRect` reports.
  Finder sectionBox(int i) => find
      .descendant(
        of: find.byType(LumeToolSection).at(i),
        matching: find.byType(Column),
      )
      .first;

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'toolbar.title': find.text('Play'),
    'toolbar.sub': find.text('Library'),
    'sect1': sectionBox(0),
    'sect.title': find.text('Games'),
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_play_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_play_default_pk_390x844_dark_en', const Size(390, 5000)),
      ('tool_play_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_play_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      final bool phone = size.width == 390;
      testWidgets(cell, (WidgetTester tester) async {
        await pumpPlay(
          tester,
          surface: size,
          theme: cell.contains('_dark_') ? ThemeMode.dark : ThemeMode.light,
        );
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: <String>{
            // Chrome lays the title out in fractional pixels.
            'toolbar.title', 'toolbar.sub',
            // On the tablet and desktop stages the reference reserves a
            // navigation rail beside the column that the test surface does
            // not; the column's *gutters* still compare, which is what the
            // width class actually decides.
            if (!phone) ...<String>['toolbar', 'sect1'],
          },
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }
  });

  group('what it draws', () {
    testWidgets('the four games, in the reference order, with their kinds', (
      WidgetTester tester,
    ) async {
      await pumpPlay(tester);
      final AppLocalizations l = strings(tester);

      expect(kReferencePlayGames, <LumePlayGame>[
        LumePlayGame.numberGrid,
        LumePlayGame.wordChain,
        LumePlayGame.memoryMatch,
        LumePlayGame.quickMaths,
      ]);

      expect(
        textsUnder(tester, find.byKey(LumePlayTool.gridKey)),
        <String>[
          for (final LumePlayGame g in kReferencePlayGames) ...<String>[
            LumePlayTool.nameOf(l, g),
            LumePlayTool.kindOf(l, g),
          ],
        ],
        reason: 'name over kind, four times, in the fixture order',
      );

      // The reference's own words, from the capture.
      expect(find.text('Number Grid'), findsOneWidget);
      expect(find.text('Puzzle'), findsOneWidget);
      expect(find.text('Word Chain'), findsOneWidget);
      expect(find.text('Word'), findsOneWidget);
      expect(find.text('Memory Match'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Quick Maths'), findsOneWidget);
      expect(find.text('Arithmetic'), findsOneWidget);
    });

    testWidgets('an icon from the app set, never an emoji', (
      WidgetTester tester,
    ) async {
      await pumpPlay(tester);
      expect(
        tester
            .widgetList<LumeIcon>(
              find.descendant(
                of: find.byKey(LumePlayTool.gridKey),
                matching: find.byType(LumeIcon),
              ),
            )
            .map((LumeIcon i) => i.name),
        <String>[
          LumeIcons.grid,
          LumeIcons.book,
          LumeIcons.swap,
          LumeIcons.divide,
        ],
      );
      for (final String emoji in <String>['🔢', '🔤', '🧠', '➗']) {
        expect(
          allText(tester).where((String s) => s.contains(emoji)),
          isEmpty,
          reason: '$emoji must not survive the conversion',
        );
      }
    });

    testWidgets('the source bar and the related tools the reference lists', (
      WidgetTester tester,
    ) async {
      await pumpPlay(tester);
      expect(find.byType(LumeSourceBar), findsOneWidget);
      expect(referenceSourceLine(tester), <String>['On device']);
      expect(find.byType(LumeRelatedTools), findsOneWidget);
      expect(find.text('Related tools'), findsOneWidget);
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), <String>[
        'Daily Streak',
        'Focus Timer',
        'Learning & Growth',
      ]);
    });
  });

  group('nothing opens, and the screen says so', () {
    for (final (String locale, String Function(AppLocalizations) of)
        in <(String, String Function(AppLocalizations))>[
          ('en', (AppLocalizations l) => l.playNotYet),
          ('ur', (AppLocalizations l) => l.playNotYet),
          ('ar', (AppLocalizations l) => l.playNotYet),
        ]) {
      testWidgets('the statement is drawn in $locale', (
        WidgetTester tester,
      ) async {
        await pumpPlay(tester, locale: Locale(locale));
        final AppLocalizations l = strings(tester);
        expect(find.byKey(LumePlayTool.noticeKey), findsOneWidget);
        expect(textsUnder(tester, find.byKey(LumePlayTool.noticeKey)), <String>[
          of(l),
          l.playNotYetText,
        ]);
        // Not the English string in another language's column.
        if (locale != 'en') {
          expect(find.text('Not playable yet'), findsNothing);
        }
      });
    }

    testWidgets('a tile is not a control and offers no action', (
      WidgetTester tester,
    ) async {
      await pumpPlay(tester);
      final SemanticsHandle handle = tester.ensureSemantics();

      expect(
        find.descendant(
          of: find.byKey(LumePlayTool.gridKey),
          matching: find.byType(LumePressable),
        ),
        findsNothing,
        reason:
            'the reference makes each tile a <button>; there is nothing '
            'behind it, so this one is text',
      );
      for (final LumePlayGame g in kReferencePlayGames) {
        final SemanticsNode node = tester.getSemantics(
          find.byKey(LumePlayTool.tileKey(g)),
        );
        final SemanticsData d = node.getSemanticsData();
        expect(
          d.flagsCollection.isButton,
          isFalse,
          reason: '${g.name} must not announce a press it cannot answer',
        );
        expect(d.hasAction(SemanticsAction.tap), isFalse);
      }
      // Nothing in either of the tool's own two sections can be pressed.
      // (The host's related-tools rail below them is its own affair.)
      for (int i = 0; i < 2; i++) {
        expect(
          find.descendant(
            of: find.byType(LumeToolSection).at(i),
            matching: find.byType(LumePressable),
          ),
          findsNothing,
        );
      }
      handle.dispose();
    });

    testWidgets('pressing a tile navigates nowhere and claims nothing', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpPlay(tester);
      final List<String> before = toolText(tester);

      for (final LumePlayGame g in kReferencePlayGames) {
        await tester.tap(find.byKey(LumePlayTool.tileKey(g)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        // The reference answers with `toast:<its own name>`. Nothing here.
        expect(
          find.byType(LumeToast),
          findsNothing,
          reason: 'pressing ${g.name} must not echo its own title back',
        );
      }
      await tester.pump(const Duration(seconds: 6));
      // The route is what a press would have moved: `onOpenRelated` replaces
      // the location, `onBack` goes to the branch root. Neither happened.
      expect(
        locationOf(router),
        kPlayLocation,
        reason: 'no tool was opened, and nothing went back',
      );
      expect(toolText(tester), before, reason: 'the screen is unchanged');
    });

    testWidgets('no restart is offered, because nothing is restartable', (
      WidgetTester tester,
    ) async {
      await pumpPlay(tester);
      for (final String word in <String>[
        'Restart',
        'Play again',
        'Start',
        'Resume',
        'Pause',
        'Reset',
      ]) {
        expect(
          allText(tester).where((String s) => s == word),
          isEmpty,
          reason: '"$word" would promise a session that does not exist',
        );
      }
    });
  });

  group('nothing here is anyone\'s record', () {
    /// The reference's own figures, verbatim.
    const List<String> dropped = <String>[
      '01:42',
      '182 pts',
      '24 moves',
      '96%',
      '38 plays',
      '21 plays',
      '14 plays',
      'Recently played',
    ];

    /// Anything shaped like a score, a best time, or a count of plays.
    final RegExp recordShaped = RegExp(
      r'\d+\s*(plays?|pts?|points?|moves?|games? played)'
      r'|\b\d{1,3}:\d{2}\b'
      r'|\d+\s*%'
      r'|\b(best|high score|streak|record|last played|recently played)\b',
      caseSensitive: false,
    );

    for (final String locale in <String>['en', 'ur', 'ar']) {
      testWidgets('no score, no play count, no history in $locale', (
        WidgetTester tester,
      ) async {
        await pumpPlay(tester, locale: Locale(locale));
        final List<String> drawn = allText(tester);

        for (final String figure in dropped) {
          expect(
            drawn.where((String s) => s.contains(figure)),
            isEmpty,
            reason: '"$figure" is a record nobody set',
          );
        }
        // The shape test reads the tool's own two sections. The host's
        // related-tools rail below them names another tool called "Daily
        // Streak", which is a destination, not a figure about this reader.
        final List<String> own = <String>[
          ...textsUnder(tester, find.byType(LumeToolSection).at(0)),
          ...textsUnder(tester, find.byType(LumeToolSection).at(1)),
        ];
        expect(own, isNotEmpty);
        for (final String s in own) {
          expect(
            recordShaped.hasMatch(s),
            isFalse,
            reason: '"$s" reads as a score, a time or a play count',
          );
        }
      });
    }

    testWidgets('the fixture itself carries no figure to restore', (
      WidgetTester tester,
    ) async {
      // A scalar field on the enum is the only way one could come back.
      expect(
        LumePlayGame.values.map((LumePlayGame g) => g.icon).toSet().length,
        LumePlayGame.values.length,
        reason: 'four games, four distinct icons, and nothing else on them',
      );
    });

    testWidgets('the removed section is gone, not retitled', (
      WidgetTester tester,
    ) async {
      await pumpPlay(tester);
      final AppLocalizations l = strings(tester);
      // The tool contributes two sections: the grid, and the statement.
      // Not three, and the second carries no heading at all — there is no
      // truthful heading for what the reference called "Recently played".
      final List<LumeToolSection> mine = tester
          .widgetList<LumeToolSection>(find.byType(LumeToolSection))
          .take(2)
          .toList();
      expect(mine.map((LumeToolSection s) => s.title), <String?>[
        l.playGames,
        null,
      ]);
      expect(find.byType(LumeToolSection).at(1), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LumeToolSection).at(1),
          matching: find.byKey(LumePlayTool.noticeKey),
        ),
        findsOneWidget,
      );
      // Not retitled anywhere, in any casing.
      expect(
        allText(tester).where((String t) => t.toLowerCase().contains('recent')),
        isEmpty,
      );
    });
  });

  group('lifecycle', () {
    testWidgets('pausing and resuming changes nothing, because nothing runs', (
      WidgetTester tester,
    ) async {
      await pumpPlay(tester);
      final List<String> before = toolText(tester);
      // Its size, not its origin: a notification banner arriving in
      // the shell moves the whole column down, and that is the app
      // working, not Play reflowing.
      final Size grid = tester.getSize(find.byKey(LumePlayTool.gridKey));

      await lumeRoundTrip(tester);
      await tester.pump(const Duration(minutes: 5));

      expect(toolText(tester), before);
      expect(tester.getSize(find.byKey(LumePlayTool.gridKey)), grid);
      expectNoOverflow(tester);
    });

    testWidgets('no timer is left running', (WidgetTester tester) async {
      await pumpPlay(tester);
      // `pumpAndSettle` returns rather than timing out only when nothing is
      // scheduling frames — no ticker, no repeating animation, no clock.
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('everyone can read it', () {
    for (final String locale in <String>['ur', 'ar']) {
      testWidgets('$locale reads right to left without reordering the games', (
        WidgetTester tester,
      ) async {
        await pumpPlay(tester, locale: Locale(locale));
        final AppLocalizations l = strings(tester);
        expect(
          Directionality.of(
            lumeContext(tester, find.byKey(LumePlayTool.gridKey)),
          ),
          TextDirection.rtl,
        );

        // The grid still reads in the fixture's order — first game first.
        expect(
          textsUnder(tester, find.byKey(LumePlayTool.gridKey)).first,
          LumePlayTool.nameOf(l, LumePlayGame.numberGrid),
        );
        // ...and the first game is now on the right of the row.
        final double first = tester
            .getRect(find.byKey(LumePlayTool.tileKey(LumePlayGame.numberGrid)))
            .center
            .dx;
        final double second = tester
            .getRect(find.byKey(LumePlayTool.tileKey(LumePlayGame.wordChain)))
            .center
            .dx;
        expect(first, greaterThan(second));

        // §17: a picture of a thing is not a statement about reading order.
        for (final LumePlayGame g in kReferencePlayGames) {
          expect(
            LumeIcons.mirrors(g.icon),
            isFalse,
            reason: '${g.icon} must not flip in an RTL column',
          );
        }
        expectNoOverflow(tester);
      });
    }

    testWidgets('200 % text still fits', (WidgetTester tester) async {
      await pumpPlay(tester, textScale: 2, surface: const Size(390, 6000));
      expectNoOverflow(tester);
      expect(find.byKey(LumePlayTool.gridKey), findsOneWidget);
      expect(find.byKey(LumePlayTool.noticeKey), findsOneWidget);
      for (final LumePlayGame g in kReferencePlayGames) {
        final Rect r = tester.getRect(find.byKey(LumePlayTool.tileKey(g)));
        expect(
          r.height,
          greaterThanOrEqualTo(96),
          reason: 'the tile grows past its floor rather than clipping',
        );
      }
    });

    testWidgets('a narrow column still fits', (WidgetTester tester) async {
      await pumpPlay(tester, surface: const Size(320, 5000));
      expectNoOverflow(tester);
      expect(find.byKey(LumePlayTool.gridKey), findsOneWidget);
    });

    testWidgets('reduced motion leaves it whole', (WidgetTester tester) async {
      // `animate: false` is `disableAnimations: true` on the MediaQuery.
      await pumpPlay(tester);
      expect(
        MediaQuery.of(
          lumeContext(tester, find.byType(LumePlayTool)),
        ).disableAnimations,
        isTrue,
      );
      expect(find.byKey(LumePlayTool.gridKey), findsOneWidget);
      expect(find.byKey(LumePlayTool.noticeKey), findsOneWidget);
      expect(allText(tester), contains('Number Grid'));
      expectNoOverflow(tester);
    });

    testWidgets('dark mode draws the same screen', (WidgetTester tester) async {
      await pumpPlay(tester, theme: ThemeMode.dark);
      expect(allText(tester), contains('Number Grid'));
      expect(find.byKey(LumePlayTool.noticeKey), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('a screen reader hears how many, then each with its kind', (
      WidgetTester tester,
    ) async {
      await pumpPlay(tester);
      final SemanticsHandle handle = tester.ensureSemantics();
      final AppLocalizations l = strings(tester);

      // The group says what it is before the reader walks it.
      expect(
        find.bySemanticsLabel(l.playCount(kReferencePlayGames.length)),
        findsOneWidget,
      );

      // Each tile is one node carrying both of its lines.
      for (final LumePlayGame g in kReferencePlayGames) {
        final SemanticsData d = tester
            .getSemantics(find.byKey(LumePlayTool.tileKey(g)))
            .getSemanticsData();
        expect(d.label, contains(LumePlayTool.nameOf(l, g)));
        expect(d.label, contains(LumePlayTool.kindOf(l, g)));
      }

      // The statement is a node of its own, not decoration.
      expect(
        tester
            .getSemantics(find.byKey(LumePlayTool.noticeKey))
            .getSemanticsData()
            .label,
        contains(l.playNotYet),
      );
      handle.dispose();
    });

    testWidgets('the keyboard reaches everything that can be operated', (
      WidgetTester tester,
    ) async {
      await pumpPlay(tester, surface: const Size(390, 900));

      // Everything pressable on the screen is pressable: no inert control is
      // put in a keyboard user's path.
      final Iterable<LumePressable> pressables = tester
          .widgetList<LumePressable>(find.byType(LumePressable));
      expect(pressables, isNotEmpty, reason: 'Back and Save to favourites');
      for (final LumePressable p in pressables) {
        expect(p.onTap, isNotNull);
      }

      // Tab lands on one of them and stays inside the screen.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(primaryFocus?.context, isNotNull);
      expect(
        find
                .descendant(
                  of: find.byType(LumePlayTool),
                  matching: find.byWidgetPredicate(
                    (Widget w) => identical(w, primaryFocus?.context?.widget),
                  ),
                )
                .evaluate()
                .isNotEmpty ||
            primaryFocus!.context!
                    .findAncestorWidgetOfExactType<LumePlayTool>() !=
                null,
        isTrue,
        reason: 'focus is inside the tool, not lost to the page',
      );
    });
  });

  group('the same screen wherever the reader is', () {
    for (final String state in <String>[
      'default_pk',
      'default_us',
      'muslim_gb',
      'default_jp',
    ]) {
      testWidgets('$state sees the four games and the statement', (
        WidgetTester tester,
      ) async {
        await pumpPlay(tester, state: state);
        final AppLocalizations l = strings(tester);
        expect(
          textsUnder(tester, find.byKey(LumePlayTool.gridKey)).length,
          kReferencePlayGames.length * 2,
        );
        expect(find.text(l.playNotYet), findsOneWidget);
        // Play carries no country figure, so nothing about it moves.
        expect(find.byKey(LumePlayTool.noticeKey), findsOneWidget);
      });
    }
  });
}
