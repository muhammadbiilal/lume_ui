/// The calculator's arithmetic, away from any screen.
///
/// Three of these are the reference's own failing cases, written as the
/// reference fails them and asserted as Lume answers them.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/calculator/domain/calculator_engine.dart';
import 'package:lume/features/calculator/domain/lume_decimal.dart';

LumeDecimal d(String text) => LumeDecimal.parse(text);

LumeDecimalFailure failureOf(void Function() body) {
  try {
    body();
  } on LumeDecimalException catch (e) {
    return e.failure;
  }
  fail('expected a LumeDecimalException');
}

/// Run a sequence of key presses over a fresh engine.
LumeCalcEngine keys(List<Object> presses, [LumeCalcEngine? from]) {
  LumeCalcEngine e = from ?? const LumeCalcEngine();
  for (final Object p in presses) {
    e = switch (p) {
      final int n => e.digit(n),
      final LumeCalcOp op => e.operate(op),
      '=' => e.equals(),
      '.' => e.dot(),
      '%' => e.perCent(),
      'C' => e.clear(),
      '<' => e.backspace(),
      _ => throw ArgumentError('unknown press $p'),
    };
  }
  return e;
}

void main() {
  group('the decimal is exact', () {
    test('0.1 + 0.2 is 0.3, and not 0.30000000000000004', () {
      expect((d('0.1') + d('0.2')).toDecimalString(), '0.3');
      expect(d('0.1') + d('0.2'), d('0.3'));
      // The double the reference works in does not manage it.
      expect(0.1 + 0.2 == 0.3, isFalse);
    });

    test('1.1 per cent is 0.011 — the reference renders '
        '0.011000000000000001 (defect 2)', () {
      expect(d('1.1').perCent.toDecimalString(), '0.011');
      expect((1.1 / 100).toString(), '0.011000000000000001');
    });

    test('a hundred hundredths add to exactly one', () {
      LumeDecimal total = LumeDecimal.zero;
      for (int i = 0; i < 100; i++) {
        total += d('0.01');
      }
      expect(total, LumeDecimal.one);
    });

    test('trailing zeros do not change a value or its hash', () {
      expect(LumeDecimal.of(300, 3), d('0.3'));
      expect(LumeDecimal.of(300, 3).hashCode, d('0.3').hashCode);
      expect(LumeDecimal.of(300, 3).toDecimalString(), '0.3');
    });

    test('values of different scales order correctly', () {
      expect(d('0.1').compareTo(d('0.09')), 1);
      expect(d('-2').compareTo(d('0.000000000001')), -1);
      expect(d('1.000').compareTo(d('1')), 0);
    });

    test('a machine decimal survives the round trip', () {
      for (final String text in <String>[
        '0',
        '-12',
        '0.011',
        '123456789.123',
        '-0.000000000001',
      ]) {
        expect(d(text).toDecimalString(), text);
      }
    });

    test('a half-typed point parses as the number before it', () {
      expect(d('1.').toDecimalString(), '1');
    });
  });

  group('division says what it can and cannot do', () {
    test('by zero refuses — the reference returns 0 (defect 1)', () {
      expect(
        failureOf(() => d('5').divide(LumeDecimal.zero)),
        LumeDecimalFailure.divideByZero,
      );
      // `:913` — `b === 0 ? 0 : a / b`.
      expect(5 == 0 ? 0 : 5 / 0, double.infinity);
    });

    test('terminating quotients are exact', () {
      expect(d('1').divide(d('8')).toDecimalString(), '0.125');
      expect(d('1').divide(d('4')).toDecimalString(), '0.25');
      expect(d('10').divide(d('4')).toDecimalString(), '2.5');
      expect(d('-1').divide(d('8')).toDecimalString(), '-0.125');
      expect(d('0.3').divide(d('0.1')).toDecimalString(), '3');
      expect(d('1').divide(d('1024')).toDecimalString(), '0.0009765625');
    });

    test('10000000 ÷ 3 does not end, and is said so — the reference '
        'displays 3333333.3333333335 (defect 3)', () {
      expect(
        failureOf(() => d('10000000').divide(d('3'))),
        LumeDecimalFailure.precision,
      );
      // The reference's own trim, at that magnitude.
      expect(((10000000 / 3) * 1e10).round() / 1e10, 3333333.3333333335);
    });

    test('a quotient that terminates past twelve places refuses too', () {
      // 1 / 8192 is 0.0001220703125 — thirteen places.
      expect(
        failureOf(() => d('1').divide(d('8192'))),
        LumeDecimalFailure.precision,
      );
      expect(d('1').divide(d('4096')).toDecimalString(), '0.000244140625');
    });
  });

  group('the bounds are typed, never clamped', () {
    test('a product past 2^53 − 1 overflows', () {
      expect(
        failureOf(() => d('999999999999') * d('999999999999')),
        LumeDecimalFailure.overflow,
      );
      expect(
        failureOf(
          () => LumeDecimal.of(LumeDecimal.maxSignificand, 0) + LumeDecimal.one,
        ),
        LumeDecimalFailure.overflow,
      );
    });

    test('a product needing more than twelve places refuses', () {
      expect(
        failureOf(() => d('0.0000001') * d('0.0000001')),
        LumeDecimalFailure.precision,
      );
      expect(
        (d('0.000001') * d('0.000001')).toDecimalString(),
        '0.000000000001',
      );
    });

    test('a scale past the model is refused at construction', () {
      expect(
        failureOf(() => LumeDecimal.of(1, LumeDecimal.maxScale + 1)),
        LumeDecimalFailure.precision,
      );
      expect(
        failureOf(() => d('0.0000000000001')),
        LumeDecimalFailure.precision,
      );
    });

    test('more digits than an int holds exactly is refused, not rounded', () {
      expect(
        failureOf(() => d('12345678901234567')),
        LumeDecimalFailure.overflow,
      );
    });
  });

  group('precedence — algebraic, not the reference\'s immediate execution', () {
    test('2 + 3 × 4 = is 14; the reference gives 20', () {
      expect(
        keys(<Object>[
          2,
          LumeCalcOp.add,
          3,
          LumeCalcOp.multiply,
          4,
          '=',
        ]).display,
        '14',
      );
    });

    test('a low-precedence operator collapses what is pending', () {
      final LumeCalcEngine e = keys(<Object>[
        2,
        LumeCalcOp.add,
        3,
        LumeCalcOp.multiply,
        4,
        LumeCalcOp.add,
      ]);
      expect(e.display, '14');
      expect(keys(<Object>[1, '='], e).display, '15');
    });

    test('a high-precedence operator leaves the sum pending', () {
      expect(
        keys(<Object>[2, LumeCalcOp.add, 3, LumeCalcOp.multiply]).display,
        '3',
      );
    });

    test('each level runs left to right', () {
      expect(
        keys(<Object>[
          8,
          LumeCalcOp.divide,
          4,
          LumeCalcOp.divide,
          2,
          '=',
        ]).display,
        '1',
      );
      expect(
        keys(<Object>[
          1,
          0,
          LumeCalcOp.subtract,
          3,
          LumeCalcOp.subtract,
          2,
          '=',
        ]).display,
        '5',
      );
    });

    test('an operator pressed twice replaces the first', () {
      expect(
        keys(<Object>[2, LumeCalcOp.add, LumeCalcOp.subtract, 3, '=']).display,
        '-1',
      );
    });
  });

  group('the keys', () {
    test('a leading zero is replaced, not extended', () {
      expect(keys(<Object>[0, 0, 5]).display, '5');
      expect(keys(<Object>[0, '.', 5]).display, '0.5');
    });

    test('a point is accepted once', () {
      expect(keys(<Object>[1, '.', '.', 5]).display, '1.5');
      expect(keys(<Object>['.', 5]).display, '0.5');
    });

    test('an entry past twelve digits is refused and says so', () {
      final LumeCalcEngine full = keys(<Object>[
        1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, //
      ]);
      expect(full.display, '123456789123');
      expect(full.error, isNull);
      final LumeCalcEngine over = full.digit(4);
      expect(over.error, LumeCalcError.tooLong);
      expect(over.display, '123456789123');
      expect(over.halted, isFalse, reason: 'too long is a notice, not a stop');
      // A keypress that does something clears the notice.
      expect(over.backspace().error, isNull);
      expect(over.operate(LumeCalcOp.add).error, isNull);
    });

    test('backspace drops one digit, then settles on zero', () {
      expect(keys(<Object>[1, 2, 3, '<']).display, '12');
      expect(keys(<Object>[1, '<']).display, '0');
      expect(keys(<Object>[1, '<', '<']).display, '0');
    });

    test('clear clears the entry first, then everything', () {
      LumeCalcEngine e = keys(<Object>[2, LumeCalcOp.add, 3]);
      expect(e.clearsEntryOnly, isTrue);
      e = e.clear();
      expect(e.display, '0');
      expect(e.ops, <LumeCalcOp>[LumeCalcOp.add], reason: 'the sum is kept');
      expect(keys(<Object>[5, '='], e).display, '7');

      // With nothing left in the entry, the same key clears the sum.
      final LumeCalcEngine all = keys(<Object>[
        2,
        LumeCalcOp.add,
        3,
      ]).clear().clear();
      expect(all.clearsEntryOnly, isFalse);
      expect(all.ops, isEmpty);
      expect(all.operands, isEmpty);
      expect(all.display, '0');
    });

    test('clearing keeps the history', () {
      final LumeCalcEngine e = keys(<Object>[
        2,
        LumeCalcOp.add,
        3,
        '=',
      ]).clear().clear();
      expect(e.history, hasLength(1));
    });

    test('per cent is exact and replaces the entry', () {
      final LumeCalcEngine e = keys(<Object>[1, '.', 1, '%']);
      expect(e.display, '0.011');
      expect(
        keys(<Object>[5], e).display,
        '5',
        reason: 'the next digit is new',
      );
    });

    test('per cent of a pending term applies to that term only', () {
      expect(
        keys(<Object>[5, 0, LumeCalcOp.add, 1, 0, '%', '=']).display,
        '50.1',
      );
    });
  });

  group('repeated equals — the reference has none (`:953`)', () {
    test('= repeats the last operator and operand', () {
      LumeCalcEngine e = keys(<Object>[2, LumeCalcOp.add, 3, '=']);
      expect(e.display, '5');
      e = e.equals();
      expect(e.display, '8');
      e = e.equals();
      expect(e.display, '11');
    });

    test('after a sum with precedence, = repeats the last operator', () {
      final LumeCalcEngine e = keys(<Object>[
        2,
        LumeCalcOp.add,
        3,
        LumeCalcOp.multiply,
        4,
        '=',
      ]);
      expect(e.display, '14');
      expect(e.equals().display, '56');
    });

    test('= with nothing entered and nothing to repeat does nothing', () {
      final LumeCalcEngine e = const LumeCalcEngine().equals();
      expect(e.display, '0');
      expect(e.history, isEmpty);
    });
  });

  group('failures reach the reader as themselves', () {
    test('divide by zero stops the engine and shows no number', () {
      final LumeCalcEngine e = keys(<Object>[5, LumeCalcOp.divide, 0, '=']);
      expect(e.error, LumeCalcError.divideByZero);
      expect(e.halted, isTrue);
      expect(e.history, isEmpty, reason: 'a refused sum is not a sum');
      // Nothing but clear and backspace answers.
      expect(e.digit(7).error, LumeCalcError.divideByZero);
      expect(e.backspace().error, isNull);
      expect(e.clear().error, isNull);
    });

    test('a division that does not end is named as such', () {
      final LumeCalcEngine e = keys(<Object>[
        1,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        LumeCalcOp.divide,
        3,
        '=',
      ]);
      expect(e.error, LumeCalcError.precision);
      expect(e.display, '3', reason: 'the divisor is left as it was typed');
    });

    test('an overflow is named as such', () {
      final LumeCalcEngine e = keys(<Object>[
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, //
        LumeCalcOp.multiply,
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, //
        '=',
      ]);
      expect(e.error, LumeCalcError.overflow);
    });
  });

  group('history', () {
    test('holds finished sums, newest first, and nothing else', () {
      LumeCalcEngine e = keys(<Object>[2, LumeCalcOp.add, 3]);
      expect(e.history, isEmpty, reason: 'an unfinished sum is not one');
      e = e.equals();
      expect(e.history, hasLength(1));
      expect(e.history.first.result.toDecimalString(), '5');
      e = keys(<Object>[4, LumeCalcOp.multiply, 5, '='], e);
      expect(e.history.first.result.toDecimalString(), '20');
      expect(e.history.last.result.toDecimalString(), '5');
    });

    test('keeps the reference\'s six rows', () {
      LumeCalcEngine e = const LumeCalcEngine();
      for (int i = 1; i <= 8; i++) {
        e = keys(<Object>[i, LumeCalcOp.add, 1, '='], e.clear().clear());
      }
      expect(e.history, hasLength(LumeCalcEngine.historyLimit));
      expect(e.history.first.result.toDecimalString(), '9');
    });

    test('a repeated = records the sum it worked out', () {
      final LumeCalcEngine e = keys(<Object>[
        2,
        LumeCalcOp.add,
        3,
        '=',
      ]).equals();
      expect(e.history, hasLength(2));
      expect(e.history.first.result.toDecimalString(), '8');
    });
  });

  group('the session text', () {
    test('carries the whole engine back', () {
      final LumeCalcEngine e = keys(<Object>[
        2,
        LumeCalcOp.add,
        3,
        '=',
        4,
        LumeCalcOp.multiply,
      ]);
      final LumeCalcEngine back = LumeCalcEngine.decode(e.encode());
      expect(back.display, e.display);
      expect(back.ops, e.ops);
      expect(
        back.operands.map((LumeDecimal x) => x.toDecimalString()),
        <String>['4'],
      );
      expect(back.history, hasLength(1));
      expect(back.history.first.result.toDecimalString(), '5');
      expect(keys(<Object>[5, '='], back).display, '20');
    });

    test('an entry in progress survives', () {
      final LumeCalcEngine back = LumeCalcEngine.decode(
        keys(<Object>[1, '.', 5, 0]).encode(),
      );
      expect(back.display, '1.50');
    });

    test('anything else is a fresh engine, never a half-restored one', () {
      for (final String? text in <String?>[null, '', 'nonsense', '1\u001e2']) {
        final LumeCalcEngine e = LumeCalcEngine.decode(text);
        expect(e.display, '0');
        expect(e.history, isEmpty);
        expect(e.ops, isEmpty);
      }
    });
  });

  group('the expression line', () {
    test('shows the sum as it is written, then with its =', () {
      String line(LumeCalcEngine e) => e.expression
          .map(
            (LumeCalcToken t) => t.equals
                ? '='
                : t.op != null
                ? t.op!.name
                : t.number!,
          )
          .join(' ');

      expect(line(const LumeCalcEngine()), '');
      expect(line(keys(<Object>[2, LumeCalcOp.add])), '2 add');
      expect(line(keys(<Object>[2, LumeCalcOp.add, 3])), '2 add 3');
      expect(
        line(keys(<Object>[2, LumeCalcOp.add, 3, LumeCalcOp.multiply, 4, '='])),
        '2 add 3 multiply 4 =',
      );
      expect(line(keys(<Object>[2, LumeCalcOp.add, 3, '=', 7])), '');
    });
  });
}
