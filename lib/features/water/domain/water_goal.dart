/// The daily goal — one record, in the tool's own store.
///
/// **What the figure is, and what it is not.** `water.tool.js` reads its
/// target from `var target = 2000;` (`context.js:1624`): one number, the same
/// for every reader on earth, baked into the build. Here 2000 ml is the
/// *default goal* and nothing else. It is not a recommendation, not a
/// requirement, not a healthy amount, and nothing in this tool claims it
/// suits anybody. It is never adjusted from age, sex, pregnancy, weather,
/// exercise or any condition — none of those are read, asked for or stored —
/// and the reader can change it whenever they like. Until they do, the goal
/// row says "Default goal" beside it, so the figure never passes itself off
/// as a decision somebody made for them.
///
/// **Where it lives.** With the drinks, not in a constant: a second
/// collection, [kLumeWaterGoalCollection], holding at most one record with a
/// single `ml` field. Empty means the reader has not chosen, and the default
/// stands. Setting a goal creates that record, or updates it; there is never
/// a second. Every figure the tool shows — what is left, how full the ring
/// is, the caption under the total — is computed against whatever that record
/// currently says, so an old target cannot survive anywhere on the screen.
///
/// **Why there is an upper bound.** A typed goal is a positive whole number
/// of millilitres up to [kLumeWaterMaxGoalMl], ten litres. Ten is an order of
/// magnitude above the default and far past anything a person would set, so
/// the bound turns a slipped extra zero (2000 → 20000) into a visible
/// rejection rather than a ring that can never move. Nothing is clamped
/// quietly: a figure outside the range is refused in the form's own error
/// style and the reader types another.
library;

import 'package:flutter/foundation.dart';

import '../../records/domain/record_model.dart';

/// The reference's `target` (`context.js:1624`), kept as the goal a reader
/// starts on and can change in two taps.
const int kLumeWaterDefaultGoalMl = 2000;

/// The largest goal that can be typed — see the library comment.
const int kLumeWaterMaxGoalMl = 10000;

/// The collection the one goal record lives in, beside `water`.
const String kLumeWaterGoalCollection = 'watergoal';

/// The goal as it currently stands, and whether anybody chose it.
@immutable
class LumeWaterGoal {
  const LumeWaterGoal({
    required this.ml,
    required this.chosen,
    this.recordId,
    this.version,
  });

  /// The default, with no record behind it.
  static const LumeWaterGoal fallback = LumeWaterGoal(
    ml: kLumeWaterDefaultGoalMl,
    chosen: false,
  );

  /// The millilitres every figure is measured against.
  final int ml;

  /// Whether [ml] is the reader's own. `false` is the default, and the UI
  /// marks it as one.
  final bool chosen;

  /// The record holding it, where there is one — kept even when what it
  /// stores cannot be read, so setting a goal updates that record instead of
  /// leaving an unreadable one behind a second.
  final String? recordId;
  final int? version;

  /// What a collection's contents mean.
  ///
  /// A collection that is still loading, has failed, or is empty is the
  /// default. More than one record should not happen — nothing here writes a
  /// second — and if one ever did, the first is the goal and the rest are
  /// ignored rather than added up.
  factory LumeWaterGoal.from(LumeCollectionView view) {
    if (view.status == LumeCollectionStatus.loading ||
        view.status == LumeCollectionStatus.error ||
        view.items.isEmpty) {
      return fallback;
    }
    final LumeRecord r = view.items.first;
    final int? ml = readGoalMl(r['ml']);
    return LumeWaterGoal(
      ml: ml ?? kLumeWaterDefaultGoalMl,
      chosen: ml != null,
      recordId: r.id,
      version: r.version,
    );
  }

  /// A stored goal that is a whole number of millilitres inside the allowed
  /// range, or `null`. A stored figure outside it is not honoured — the
  /// default stands and the row says so — because a ring drawn against a
  /// number the form would refuse is a figure the reader cannot have meant.
  static int? readGoalMl(Object? v) {
    final num? n = v is num ? v : num.tryParse('${v ?? ''}'.trim());
    if (n == null || !n.isFinite || n != n.roundToDouble()) return null;
    final int ml = n.toInt();
    return ml >= 1 && ml <= kLumeWaterMaxGoalMl ? ml : null;
  }
}

/// Why a typed goal was refused.
enum LumeWaterGoalProblem {
  /// Nothing was typed.
  missing,

  /// Not a whole number greater than zero.
  notPositive,

  /// Past [kLumeWaterMaxGoalMl].
  tooLarge,
}

/// What the goal field currently holds: a goal, or a reason it is not one.
@immutable
class LumeWaterGoalEntry {
  const LumeWaterGoalEntry._(this.ml, this.problem);

  /// Read [typed] as a goal.
  ///
  /// The field takes the reader's own digits as well as Latin ones (§13), so
  /// those are folded first; nothing else about the text is guessed at.
  factory LumeWaterGoalEntry.parse(String typed) {
    final String s = lumeLatinDigits(typed).trim();
    if (s.isEmpty) {
      return const LumeWaterGoalEntry._(null, LumeWaterGoalProblem.missing);
    }
    // Plain digits, and nothing else. `num.tryParse` would take `2e3` as two
    // thousand and `1.5` as a millilitre and a half; a goal is a count of
    // millilitres, and the field only lets digits be typed in the first
    // place.
    if (!_digits.hasMatch(s)) {
      return const LumeWaterGoalEntry._(null, LumeWaterGoalProblem.notPositive);
    }
    final int? n = int.tryParse(s);
    if (n == null || n <= 0) {
      return const LumeWaterGoalEntry._(null, LumeWaterGoalProblem.notPositive);
    }
    if (n > kLumeWaterMaxGoalMl) {
      return const LumeWaterGoalEntry._(null, LumeWaterGoalProblem.tooLarge);
    }
    return LumeWaterGoalEntry._(n, null);
  }

  static final RegExp _digits = RegExp(r'^[0-9]+$');

  /// The goal, when there is one.
  final int? ml;

  final LumeWaterGoalProblem? problem;

  bool get ok => ml != null;
}

/// Arabic-Indic and extended Arabic-Indic digits as Latin ones; everything
/// else is left exactly as typed, so a stray letter is still a stray letter.
String lumeLatinDigits(String s) {
  final StringBuffer out = StringBuffer();
  for (final int code in s.runes) {
    if (code >= 0x0660 && code <= 0x0669) {
      out.writeCharCode(0x30 + code - 0x0660);
    } else if (code >= 0x06F0 && code <= 0x06F9) {
      out.writeCharCode(0x30 + code - 0x06F0);
    } else {
      out.writeCharCode(code);
    }
  }
  return out.toString();
}
