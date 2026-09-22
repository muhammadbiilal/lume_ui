/// The counter's behaviour, without a screen.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/tasbih/domain/tasbih_count.dart';
import 'package:lume/features/tasbih/domain/tasbih_phrase.dart';

/// A counter at [rounds] rounds and [count] into the current one.
LumeTasbihCount at({int phrase = 0, int count = 0, int rounds = 0}) =>
    LumeTasbihCount(phrase: phrase, count: count, rounds: rounds);

/// [taps] taps from [start].
LumeTasbihCount tapped(LumeTasbihCount start, int taps) {
  LumeTasbihCount c = start;
  for (int i = 0; i < taps; i++) {
    c = c.tap().count;
  }
  return c;
}

void main() {
  group('the five phrases are the reference\'s, unchanged', () {
    test('there are five, in the reference\'s order', () {
      expect(
        LumeTasbihPhrases.all
            .map((LumeTasbihPhrase p) => p.transliteration)
            .toList(),
        <String>[
          'SubhanAllah',
          'Alhamdulillah',
          'Allahu Akbar',
          'La ilaha illallah',
          'Astaghfirullah',
        ],
      );
    });

    test('their rounds are 33, 33, 34, 100, 100', () {
      expect(
        LumeTasbihPhrases.all.map((LumeTasbihPhrase p) => p.target).toList(),
        <int>[33, 33, 34, 100, 100],
      );
    });

    test('each carries Arabic, a transliteration and a gloss', () {
      for (final LumeTasbihPhrase p in LumeTasbihPhrases.all) {
        expect(p.arabic, isNotEmpty);
        expect(p.transliteration, isNotEmpty);
        expect(p.meaning, isNotEmpty);
        // The Arabic is Arabic script, not a transliteration of it.
        expect(p.arabic.codeUnits.first, greaterThan(0x0600));
      }
    });
  });

  group('counting', () {
    test('a tap counts one', () {
      expect(at().tap().count.count, 1);
    });

    test('taps do not lose or double', () {
      expect(tapped(at(), 20).count, 20);
      expect(tapped(at(), 20).rounds, 0);
    });

    test('the round finishes at the phrase\'s target and starts again', () {
      final LumeTasbihTap last = at(count: 32).tap();
      expect(last.finishedRound, isTrue);
      expect(last.count.count, 0);
      expect(last.count.rounds, 1);
    });

    test('33 taps of SubhanAllah is one round', () {
      expect(tapped(at(), 33), at(rounds: 1));
    });

    test('a round of 34 takes 34 taps', () {
      expect(tapped(at(phrase: 2), 33), at(phrase: 2, count: 33));
      expect(tapped(at(phrase: 2), 34), at(phrase: 2, rounds: 1));
    });

    test('the count is never at or past the target', () {
      LumeTasbihCount c = at();
      for (int i = 0; i < 200; i++) {
        c = c.tap().count;
        expect(c.count, lessThan(c.target));
        expect(c.count, greaterThanOrEqualTo(0));
      }
      expect(c.rounds, 6);
    });

    test(
      'there is no decrement — the reference has none, and nor has this',
      () {
        // The reference's only handlers are the tap, the reset and the phrase
        // switch (`tool.screen.js:764-801`). Counting down is not among them,
        // and a counter that can be quietly wound back is not a counter.
        expect(
          const LumeTasbihCount().tap().count.count,
          greaterThan(const LumeTasbihCount().count),
        );
      },
    );
  });

  group('the ring', () {
    test('is empty at zero and never negative', () {
      expect(at().progress, 0);
      expect(
        LumeTasbihCount.restored(phrase: 0, count: -9, rounds: 0).progress,
        0,
      );
    });

    test('never runs past a full circle', () {
      expect(
        LumeTasbihCount.restored(phrase: 0, count: 900, rounds: 0).progress,
        lessThanOrEqualTo(1),
      );
    });

    test('is the fraction of the round', () {
      expect(at(count: 11).progress, closeTo(1 / 3, 1e-9));
    });
  });

  group('the ceiling', () {
    test('is 9,999 rounds', () {
      expect(LumeTasbihCount.maxRounds, 9999);
    });

    test('a counter short of it still counts', () {
      final LumeTasbihCount nearly = at(count: 32, rounds: 9998);
      expect(nearly.isFull, isFalse);
      final LumeTasbihTap last = nearly.tap();
      expect(last.count.rounds, 9999);
      expect(last.count.isFull, isTrue);
    });

    test('at the ceiling a tap is refused and changes nothing', () {
      final LumeTasbihCount full = at(count: 4, rounds: 9999);
      final LumeTasbihTap refused = full.tap();
      expect(refused.refused, isTrue);
      expect(refused.count, full);
    });

    test('a reset clears it', () {
      expect(at(count: 4, rounds: 9999).reset(), at());
    });
  });

  group('reset and switching', () {
    test('reset zeroes the count and the rounds, and keeps the phrase', () {
      expect(at(phrase: 3, count: 40, rounds: 2).reset(), at(phrase: 3));
    });

    test('switching zeroes the count and keeps the finished rounds', () {
      expect(at(count: 12, rounds: 3).switchTo(4), at(phrase: 4, rounds: 3));
    });

    test('switching to a phrase that does not exist changes nothing', () {
      expect(at(phrase: 1, count: 5).switchTo(99), at(phrase: 1, count: 5));
    });
  });

  group('what comes back from the session', () {
    test('a phrase the list no longer holds falls back to the first', () {
      expect(
        LumeTasbihCount.restored(phrase: 42, count: 3, rounds: 1).phrase,
        LumeTasbihPhrases.first,
      );
    });

    test('a negative count is zero', () {
      expect(LumeTasbihCount.restored(phrase: 0, count: -4, rounds: -2), at());
    });

    test('a count at or past the target is pulled inside the round', () {
      expect(
        LumeTasbihCount.restored(phrase: 0, count: 33, rounds: 0).count,
        32,
      );
    });

    test('rounds past the ceiling are held at it', () {
      expect(
        LumeTasbihCount.restored(phrase: 0, count: 0, rounds: 50000).rounds,
        LumeTasbihCount.maxRounds,
      );
    });
  });
}
