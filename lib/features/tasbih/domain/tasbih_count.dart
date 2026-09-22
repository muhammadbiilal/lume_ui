/// Where the counter stands: which phrase, how far into the round, how many
/// rounds finished.
///
/// The whole of the tool's behaviour is here, so that counting, finishing a
/// round, switching phrase, resetting and reaching the ceiling can be
/// reasoned about — and tested — without a screen.
///
/// **One clamped path.** `tasbih.tool.js:33` draws the ring from
/// `(1 - count / target)` with no floor, while the live handler at
/// `tool.screen.js:792` wraps the same arithmetic in `Math.max(0, …)`: two
/// expressions for one geometry, one of which can go negative. [progress] is
/// the only expression, and it is clamped.
library;

import 'package:flutter/foundation.dart';

import 'tasbih_phrase.dart';

@immutable
class LumeTasbihCount {
  const LumeTasbihCount({
    this.phrase = LumeTasbihPhrases.first,
    this.count = 0,
    this.rounds = 0,
  });

  /// What a value read back from the session means, whatever it says.
  ///
  /// The session is a map of strings and nothing validates what goes into it,
  /// so a phrase that no longer exists, a negative count or a count past this
  /// phrase's target resolves to something the screen can draw rather than to
  /// a crash or a ring drawn past its own circumference.
  factory LumeTasbihCount.restored({
    required int phrase,
    required int count,
    required int rounds,
  }) {
    final int p = LumeTasbihPhrases.holds(phrase)
        ? phrase
        : LumeTasbihPhrases.first;
    final int r = rounds.clamp(0, maxRounds);
    final int target = LumeTasbihPhrases.all[p].target;
    return LumeTasbihCount(
      phrase: p,
      // A full round is never a resting state: it becomes a finished round
      // the moment it completes, so the count is always short of the target.
      count: count.clamp(0, target - 1),
      rounds: r,
    );
  }

  /// Which of [LumeTasbihPhrases.all] is being counted.
  final int phrase;

  /// How far into the current round, always `0 <= count < target`.
  final int count;

  /// How many rounds have been finished since the last reset.
  final int rounds;

  /// The ceiling, in finished rounds.
  ///
  /// The count inside a round cannot run away — it turns into a finished
  /// round at the phrase's target — so the only figure that grows without
  /// bound is [rounds], and this is where it stops. 9,999 is four digits, the
  /// most the counter's face can hold at 200 % text without the figure
  /// leaving the ring; a reader who reaches it is told (`l.tasbihMax`) rather
  /// than silently counting into a number the screen cannot show.
  static const int maxRounds = 9999;

  LumeTasbihPhrase get spoken => LumeTasbihPhrases.all[phrase];

  /// The conventional number in this phrase's round.
  int get target => spoken.target;

  /// How far round the ring is drawn. One expression, clamped, for both the
  /// geometry and the semantics.
  double get progress => (count / target).clamp(0.0, 1.0);

  /// The ceiling has been reached and nothing more will be counted.
  bool get isFull => rounds >= maxRounds;

  /// Nothing has been counted and no round has been finished.
  bool get isEmpty => count == 0 && rounds == 0;

  /// One tap.
  LumeTasbihTap tap() {
    if (isFull) return LumeTasbihTap(this, refused: true);
    final int next = count + 1;
    if (next < target) {
      return LumeTasbihTap(
        LumeTasbihCount(phrase: phrase, count: next, rounds: rounds),
      );
    }
    return LumeTasbihTap(
      LumeTasbihCount(phrase: phrase, count: 0, rounds: rounds + 1),
      finishedRound: true,
    );
  }

  /// Back to zero, rounds included — what `l.tasbihResetText` says happens.
  LumeTasbihCount reset() => LumeTasbihCount(phrase: phrase);

  /// A different phrase.
  ///
  /// `tool.screen.js:775-780` zeroes `count` here and leaves `sets` alone,
  /// but does it without asking. The count still goes — a part-finished round
  /// of one phrase is not a part-finished round of another — and the finished
  /// rounds are still kept, which is what `l.tasbihSwitchText` says; the
  /// asking is the screen's job.
  ///
  /// A phrase this list does not hold is not a switch, so nothing moves —
  /// least of all a part-finished round.
  LumeTasbihCount switchTo(int next) => LumeTasbihPhrases.holds(next)
      ? LumeTasbihCount(phrase: next, rounds: rounds)
      : this;

  @override
  bool operator ==(Object other) =>
      other is LumeTasbihCount &&
      other.phrase == phrase &&
      other.count == count &&
      other.rounds == rounds;

  @override
  int get hashCode => Object.hash(phrase, count, rounds);

  @override
  String toString() =>
      'LumeTasbihCount(phrase: $phrase, count: $count, rounds: $rounds)';
}

/// What one tap did.
@immutable
class LumeTasbihTap {
  const LumeTasbihTap(
    this.count, {
    this.finishedRound = false,
    this.refused = false,
  });

  /// Where the counter stands after the tap.
  final LumeTasbihCount count;

  /// The tap completed a round, so [count] starts the next one.
  final bool finishedRound;

  /// The ceiling was already reached: nothing was counted.
  final bool refused;
}
