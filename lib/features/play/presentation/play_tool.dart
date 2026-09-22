/// Play — the four games Lume plans to carry, and the plain statement that
/// none of them can be played.
///
/// ## What the reference is
///
/// `tools/personal/play.tool.js` is twenty-six lines and ships no game. Each
/// tile is `<button data-act="toast:' + g.name + '">`, and `shell.js:528`
/// resolves `toast:…` to `toast(arg)` — so pressing **Number Grid** shows a
/// toast reading "Number Grid". There is no engine, no canvas, no route and
/// no asset behind any of the four; `grep -rn GAMES assets/js` finds the
/// fixture, this module, and nothing else.
///
/// ## The four corrections
///
/// 1. **Nothing opens, and the screen says so.** A tile whose only behaviour
///    is to echo its own title back is not a behaviour worth porting — it is
///    a defect that reads as a failed navigation. So the tiles are not
///    buttons at all: they have no `onTap`, announce themselves as text
///    rather than as controls, and a notice beneath the grid states in the
///    reader's own language that these games cannot be played yet
///    (`playNotYet`, `playNotYetText`). A reader who presses a tile and gets
///    nothing has been told, before pressing, that nothing is there.
///
/// 2. **No score and no play count.** `best` and `plays` are dropped; see
///    `play_fixtures.dart` for each figure and why. Lume stores no game
///    history, so a "personal best" on this screen would be a record the
///    reader never set, and labelling it a sample would not help — the
///    labelling is not what the eye reads. Nothing on this screen is, or
///    resembles, the reader's own history.
///
/// 3. **"Recently played" is gone.** The reference's second section is
///    `GAMES.slice(0, 3)` under `play.recent` — "Recently played". Array
///    order is not recency, and the play counts run 38, 21, 14: descending,
///    so it is not "most played" either. The heading is false about its own
///    ordering whichever way you read it, and with `plays` dropped the
///    section has nothing left to say. It is not retitled, because no
///    truthful title for it exists; it is removed, and the notice takes its
///    place in the composition.
///
/// 4. **The emoji are icons.** The four glyphs cannot be recoloured, do not
///    follow the accent, and render as another typeface's artwork in dark
///    mode. Each becomes a [LumeIcons] glyph — the mapping and its reasoning
///    are on [LumePlayGame].
///
/// ## Geometry
///
/// Measured (`tool_play_default_pk_390x844_light_en`): the Games section is
/// 233 tall from its head at y 114 — a 19-point head, 12 below it, then two
/// rows of 96 with 10 between (`.tiles--play` is two columns; `.tile` has a
/// `min-height` of 96). A tile is 14 / 12 padding inside a hairline at radius
/// 12 on the card fill; a 19-point glyph in the accent with 6 under it, the
/// name 12 / 700 / −.022em on 1.25, and the kind 10 / 500 muted pushed to the
/// foot by `margin-top: auto`.
///
/// The stylesheet's `min-width: 1180px` rule would make this five columns; no
/// cell was captured that wide, and the converted `.calls` grid holds its two
/// columns through the same rule, so this holds its two.
///
/// ## State, motion and lifecycle
///
/// There is none. No timer, no ticker, no animation, no random source, no
/// stored value, nothing read and nothing written — which is why this is a
/// [StatelessWidget] and not a `ConsumerStatefulWidget`. Backgrounding,
/// resuming, rotating or reopening the screen therefore changes nothing,
/// because there is nothing running to pause and nothing in flight to lose.
/// Nothing is restartable, so no Restart is offered: a Restart that reset
/// nothing would be the same lie as a score nobody set.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/play_fixtures.dart';

class LumePlayTool extends StatelessWidget {
  const LumePlayTool({
    super.key,
    required this.request,
    this.games = kReferencePlayGames,
  });

  final LumeToolRequest request;

  /// The four rows; the reference's unless a test supplies its own.
  final List<LumePlayGame> games;

  /// The registry's builder.
  static Widget open(LumeToolRequest request) => LumePlayTool(request: request);

  static const String id = 'play';

  static const Key gridKey = ValueKey<String>('play.grid');
  static const Key noticeKey = ValueKey<String>('play.notice');

  /// The tile for [game], for a test that wants one of the four by name.
  static Key tileKey(LumePlayGame game) =>
      ValueKey<String>('play.tile.${game.name}');

  /// The name of [game], in the reader's language.
  static String nameOf(AppLocalizations l, LumePlayGame game) => switch (game) {
    LumePlayGame.numberGrid => l.playGameNumberGrid,
    LumePlayGame.wordChain => l.playGameWordChain,
    LumePlayGame.memoryMatch => l.playGameMemoryMatch,
    LumePlayGame.quickMaths => l.playGameQuickMaths,
  };

  /// What kind of game [game] is, in the reader's language.
  static String kindOf(AppLocalizations l, LumePlayGame game) => switch (game) {
    LumePlayGame.numberGrid => l.playKindPuzzle,
    LumePlayGame.wordChain => l.playKindWord,
    LumePlayGame.memoryMatch => l.playKindMemory,
    LumePlayGame.quickMaths => l.playKindArithmetic,
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    return LumeToolScreen(
      feature: request.feature,
      user: request.user,
      onBack: request.onBack,
      onOpenRelated: request.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            title: l.playGames,
            // How many there are is said to a screen reader on the way into
            // the grid, and not drawn: the reference's head is the one word
            // "Games", and a count under it would be a line the measured
            // composition does not have. `explicitChildNodes` keeps the four
            // tiles as nodes of their own beneath it, so the group is
            // announced and then walked.
            child: Semantics(
              explicitChildNodes: true,
              label: l.playCount(games.length),
              child: _PlayGrid(
                key: gridKey,
                children: <Widget>[
                  for (final LumePlayGame game in games)
                    _PlayTile(key: tileKey(game), game: game, l: l),
                ],
              ),
            ),
          ),
          // The section the reference titled "Recently played". It says the
          // one true thing there is to say about these four games.
          LumeToolSection(
            child: LumeNotice(
              key: noticeKey,
              kind: LumeNoticeKind.info,
              title: l.playNotYet,
              text: l.playNotYetText,
            ),
          ),
        ],
      ),
    );
  }
}

/// The play grid — two columns, 10 apart both ways.
///
/// Rows are laid out by hand rather than by `GridView`, which would need one
/// aspect ratio for every cell and so could not honour a 96-point floor that
/// a long translation or a 200 % text scale has to be able to grow past.
/// `IntrinsicHeight` makes both cells in a row as tall as the taller, which
/// is what the CSS grid does and what keeps the two feet aligned.
class _PlayGrid extends StatelessWidget {
  const _PlayGrid({super.key, required this.children});

  final List<Widget> children;

  static const double gap = 10;
  static const int columns = 2;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (int row = 0; row < children.length; row += columns) ...<Widget>[
        if (row > 0) const SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int col = 0; col < columns; col++) ...<Widget>[
                if (col > 0) const SizedBox(width: gap),
                Expanded(
                  child: row + col < children.length
                      ? children[row + col]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}

/// One game, and not a button.
///
/// The reference makes this a `<button>` whose press shows a toast of the
/// label. There is nothing to press, so there is no button here: no `onTap`,
/// no press feedback, no focus ring and no `button` role. [MergeSemantics]
/// reads the two lines as one thing — "Number Grid, Puzzle" — so a screen
/// reader hears a described item rather than two unlabelled fragments, and
/// hears no affordance it cannot use.
class _PlayTile extends StatelessWidget {
  const _PlayTile({super.key, required this.game, required this.l});

  final LumePlayGame game;
  final AppLocalizations l;

  /// The stylesheet's `min-height: 96px`.
  static const double minHeight = 96;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    TextStyle text(double size, FontWeight weight, double em, Color color) =>
        LumeType.tracked(
          LumeType.natural(context, context.lumeType.body, size: size),
          em,
        ).copyWith(fontWeight: weight, color: color);

    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: lume.card,
            borderRadius: LumeRadius.brSm,
            border: Border.all(color: lume.border, width: LumeSpace.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              12 + LumeSpace.border,
              14 + LumeSpace.border,
              12 + LumeSpace.border,
              14 + LumeSpace.border,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // A 19-point glyph in the accent, with the rule's own 6 on
                // top of the flex gap of 4.
                LumeIcon(game.icon, size: 19, color: lume.accent),
                const SizedBox(height: 4 + 6),
                Text(
                  LumePlayTool.nameOf(l, game),
                  style: text(12, FontWeight.w700, -0.022, lume.text),
                ),
                const SizedBox(height: 4),
                // `margin-top: auto` — the kind sits on the foot of the tile,
                // however tall the tile has had to become.
                const Spacer(),
                Text(
                  LumePlayTool.kindOf(l, game),
                  style: text(10, FontWeight.w500, 0, lume.text3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
