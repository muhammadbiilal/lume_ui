/// The four games Play lists, and nothing else about them.
///
/// `data/tool-data.js:903` holds `GAMES`, four hard-coded rows of
/// `{ name, kind, best, plays, tone, glyph }`. Three of those six fields do
/// not survive the conversion, and the reasons are recorded here rather than
/// in the widget, because they are facts about the *data*:
///
/// * **`best`** — `'01:42'`, `'182 pts'`, `'24 moves'`, `'96%'`. A personal
///   best is the reader's own record. Lume stores no game history, so these
///   are four numbers nobody set. Shown on a tile they are indistinguishable
///   from a real score, and the reader has no way to tell. Dropped.
/// * **`plays`** — `38`, `21`, `14`, `52`. A play count, with the same
///   problem and the same answer. Dropped.
/// * **`tone`** — `violet`, `accent`, `amber`, `sky`. The reference's own
///   stylesheet never reads it: `.tile__icon { color: var(--accent) }` paints
///   every tile's glyph with the one accent, and `.tile` has no tone class at
///   all. Dropped as dead data, not as a correction.
///
/// What is left is a name, a kind and a glyph — and the glyph becomes an icon
/// from Lume's own set (see `play_tool.dart`).
///
/// The names and kinds are not held here: they are localised, and live in the
/// ARB behind `playGame*` and `playKind*`. The identity of a game is its
/// enum value, so a translation cannot change which game is which.
library;

import '../../../core/icons/lume_icons.dart';

/// One of the four games the reference lists.
///
/// Declaration order is the reference's array order, which is the order the
/// grid draws. It is not a ranking, a recency or a popularity — see
/// `play_tool.dart` for why the reference's "Recently played" section is not
/// here at all.
enum LumePlayGame {
  /// 🔢 → [LumeIcons.grid]. A grid of numbers; the app's grid glyph is the
  /// literal picture the emoji was standing in for.
  numberGrid(LumeIcons.grid),

  /// 🔤 → [LumeIcons.book]. Letters and words; `book` is the set's only
  /// glyph about written language.
  wordChain(LumeIcons.book),

  /// 🧠 → [LumeIcons.swap]. The set has no brain. Memory Match is a
  /// pair-matching game, and `swap` — two arrows exchanging — is the
  /// nearest true picture of pairing. A brain glyph would have been a
  /// picture of the *kind*, not of the game.
  memoryMatch(LumeIcons.swap),

  /// ➗ → [LumeIcons.divide]. The same sign, drawn in the app's stroke.
  quickMaths(LumeIcons.divide);

  const LumePlayGame(this.icon);

  /// The name of the SVG this game is drawn with, from [LumeIcons].
  final String icon;
}

/// The reference's four rows, in its own order.
const List<LumePlayGame> kReferencePlayGames = LumePlayGame.values;
