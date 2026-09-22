/// The calculator's keypad, as a state machine over [LumeDecimal].
///
/// `tools/everyday/calculator.tool.js` draws nineteen keys and a History
/// section and contains no arithmetic at all; the engine is
/// `screens/tool.screen.js:894-957`. This is that engine, rewritten on an
/// exact decimal and with each of its seven audited defects corrected. Six of
/// them are named where they are fixed; the seventh is here:
///
/// **Defect 7 — no operator precedence.** The reference evaluates on every
/// operator press (`:938`), so `2 + 3 × 4 =` is 20. **Lume is algebraic:**
/// `×` and `÷` bind tighter than `+` and `−`, so the same keys give 14. This
/// is a deliberate divergence from parity, and the reason is what the screen
/// says: the expression line shows the whole sum as it is being written —
/// `2 + 3 × 4 =` — and a line of written arithmetic means what written
/// arithmetic means. Reproducing immediate execution would have been
/// defensible only with an expression line that showed `5 × 4`, which is not
/// what the reference draws. Reduction is still eager where precedence allows
/// it: pressing `+` after `2 + 3 × 4` collapses the product and shows 14, so
/// the reader is never left guessing what is pending.
///
/// **Repeated equals.** The reference has none: `eq` clears `op` (`:953`), so
/// a second `=` does nothing. Lume repeats the last operator and its right
/// operand — `2 + 3 =` then `=` gives 8 — because every calculator a reader
/// has used does, and because refusing is indistinguishable from a dropped
/// keypress.
///
/// **Parentheses, memory, scientific functions.** None. The reference has no
/// such keys and neither does this.
///
/// Every failure is typed and named: a division by zero, an overflow, a
/// non-terminating division and an over-long entry are four different things
/// the reader is told four different things about. Nothing here builds a
/// sentence; [LumeCalcError] is handed to `AppLocalizations`.
library;

import 'package:flutter/foundation.dart';

import 'lume_decimal.dart';

/// The four operators the pad carries.
enum LumeCalcOp { add, subtract, multiply, divide }

/// The separators the session text is built from: fields, then the tokens of
/// one sum, then the rows of the history.
const String _field = '\u001e';
const String _unit = '\u001f';
const String _row = '\u001d';

String _opCode(LumeCalcOp op) => switch (op) {
  LumeCalcOp.add => '+',
  LumeCalcOp.subtract => '-',
  LumeCalcOp.multiply => '*',
  LumeCalcOp.divide => '/',
};

LumeCalcOp? _opOf(String code) => switch (code) {
  '+' => LumeCalcOp.add,
  '-' => LumeCalcOp.subtract,
  '*' => LumeCalcOp.multiply,
  '/' => LumeCalcOp.divide,
  _ => null,
};

/// What went wrong, for the reader to be told in their own language.
enum LumeCalcError {
  /// `l.calcErrDivZero`. Defect 1: the reference returns `0` (`:913`).
  divideByZero,

  /// `l.calcErrOverflow` — past what the model holds.
  overflow,

  /// `l.calcErrPrecision` — the division does not end.
  precision,

  /// `l.calcErrTooLong` — the entry is as long as it goes. The only *soft*
  /// error: the keypress is refused, nothing else changes, and the next
  /// keypress clears the message.
  tooLong,
}

/// One piece of the expression line: a number, an operator, or the `=`.
@immutable
class LumeCalcToken {
  const LumeCalcToken.number(String this.number) : op = null, equals = false;
  const LumeCalcToken.operator(LumeCalcOp this.op)
    : number = null,
      equals = false;
  const LumeCalcToken.equals() : number = null, op = null, equals = true;

  /// A machine decimal, for the formatter. `null` unless this is a number.
  final String? number;
  final LumeCalcOp? op;
  final bool equals;
}

/// A finished sum: the operands, the operators between them, and the result.
///
/// Held in memory only, and carried between openings as text so that changing
/// language re-renders every row in the new one — a row is a calculation, not
/// a string that was once formatted in English.
@immutable
class LumeCalcSum {
  const LumeCalcSum({
    required this.operands,
    required this.ops,
    required this.result,
  });

  /// One more operand than there are operators.
  final List<LumeDecimal> operands;
  final List<LumeCalcOp> ops;
  final LumeDecimal result;

  /// The expression, without the `=`.
  List<LumeCalcToken> get tokens => <LumeCalcToken>[
    for (int i = 0; i < operands.length; i++) ...<LumeCalcToken>[
      if (i > 0) LumeCalcToken.operator(ops[i - 1]),
      LumeCalcToken.number(operands[i].toDecimalString()),
    ],
  ];

  String encode() => <String>[
    for (int i = 0; i < operands.length; i++) ...<String>[
      if (i > 0) _opCode(ops[i - 1]),
      operands[i].toDecimalString(),
    ],
    '=',
    result.toDecimalString(),
  ].join(_unit);

  /// `null` for anything that is not a sum this wrote.
  static LumeCalcSum? decode(String text) {
    final List<String> parts = text.split(_unit);
    // n operands, n − 1 operators, `=` and the result: always odd, never
    // fewer than five.
    if (parts.length < 5 || parts.length.isEven) return null;
    if (parts[parts.length - 2] != '=') return null;
    try {
      final List<LumeDecimal> operands = <LumeDecimal>[];
      final List<LumeCalcOp> ops = <LumeCalcOp>[];
      for (int i = 0; i < parts.length - 2; i++) {
        if (i.isEven) {
          operands.add(LumeDecimal.parse(parts[i]));
        } else {
          final LumeCalcOp? op = _opOf(parts[i]);
          if (op == null) return null;
          ops.add(op);
        }
      }
      if (operands.length != ops.length + 1) return null;
      return LumeCalcSum(
        operands: operands,
        ops: ops,
        result: LumeDecimal.parse(parts.last),
      );
    } on LumeDecimalException {
      return null;
    }
  }
}

/// The keypad, as one immutable value. Every press returns a new engine.
@immutable
class LumeCalcEngine {
  const LumeCalcEngine({
    this.entry = '',
    this.shown = LumeDecimal.zero,
    this.operands = const <LumeDecimal>[],
    this.ops = const <LumeCalcOp>[],
    this.lastOp,
    this.lastRhs,
    this.awaiting = false,
    this.fresh = true,
    this.error,
    this.done,
    this.history = const <LumeCalcSum>[],
  });

  /// `.slice(0, 6)` — the reference keeps six rows, and so does this.
  static const int historyLimit = 6;

  /// The most digits one entry carries. Twelve keeps every entry inside the
  /// significand's bound with room for the operations that follow, and is
  /// what the readout shows without shrinking at 390 wide.
  static const int maxEntryDigits = 12;

  /// The digits being typed, ASCII, possibly ending in `.`. Empty when the
  /// readout is showing a value rather than an entry.
  final String entry;

  /// The value the readout shows when [entry] is empty.
  final LumeDecimal shown;

  /// The pending left operands and the operators between them.
  final List<LumeDecimal> operands;
  final List<LumeCalcOp> ops;

  /// The last operator and right operand, for a repeated `=`.
  final LumeCalcOp? lastOp;
  final LumeDecimal? lastRhs;

  /// An operator was the last key: the next operator replaces it rather than
  /// starting a term, and `=` reuses the shown value as its right operand.
  final bool awaiting;

  /// The next digit starts a new entry rather than extending one.
  final bool fresh;

  final LumeCalcError? error;

  /// The sum `=` just finished, so the expression line can keep showing it.
  final LumeCalcSum? done;

  /// Newest first.
  final List<LumeCalcSum> history;

  /// Whether the engine is stopped on an error and will answer nothing but
  /// clear and backspace. [LumeCalcError.tooLong] is not one of these.
  bool get halted => error != null && error != LumeCalcError.tooLong;

  /// The value the readout stands for.
  LumeDecimal get value =>
      entry.isEmpty ? shown : LumeDecimal.parse(_settled(entry));

  /// The readout's machine text — the typed digits while typing, so a
  /// half-written `1.50` keeps its zero, and the exact value otherwise.
  ///
  /// Defect 5: `calculator.tool.js:22` emits the readout as a literal `0`
  /// while the model holds the real value, so the first paint of a reopened
  /// calculator lies about what is in it.
  String get display => entry.isEmpty ? shown.toDecimalString() : entry;

  /// Whether the clear key clears the entry (and says so) rather than
  /// everything. Defect: the reference has only `AC` (`:931`), which throws
  /// away a pending sum to correct one mistyped digit.
  bool get clearsEntryOnly =>
      error != null || entry.isNotEmpty || !shown.isZero || done != null;

  /// The expression line, as tokens for the formatter.
  List<LumeCalcToken> get expression {
    final LumeCalcSum? d = done;
    if (d != null) {
      return <LumeCalcToken>[...d.tokens, const LumeCalcToken.equals()];
    }
    if (ops.isEmpty) return const <LumeCalcToken>[];
    return <LumeCalcToken>[
      for (int i = 0; i < ops.length; i++) ...<LumeCalcToken>[
        LumeCalcToken.number(operands[i].toDecimalString()),
        LumeCalcToken.operator(ops[i]),
      ],
      if (!awaiting) LumeCalcToken.number(display),
    ];
  }

  // ---- presses -----------------------------------------------------------

  LumeCalcEngine digit(int n) {
    if (halted) return this;
    final String next = (fresh || entry.isEmpty || entry == '0')
        ? '$n'
        : '$entry$n';
    if (_digits(next) > maxEntryDigits) {
      return _with(error: LumeCalcError.tooLong);
    }
    return _with(
      entry: next,
      fresh: false,
      awaiting: false,
      error: _none,
      done: _none,
    );
  }

  LumeCalcEngine dot() {
    if (halted) return this;
    if (!fresh && entry.contains('.')) return _with(error: _none);
    final String next = (fresh || entry.isEmpty) ? '0.' : '$entry.';
    if (_digits(next) > maxEntryDigits) {
      return _with(error: LumeCalcError.tooLong);
    }
    return _with(
      entry: next,
      fresh: false,
      awaiting: false,
      error: _none,
      done: _none,
    );
  }

  /// `x ÷ 100`, exactly (defect 2).
  LumeCalcEngine perCent() {
    if (halted) return this;
    try {
      return _with(
        entry: '',
        shown: value.perCent,
        fresh: true,
        awaiting: false,
        error: _none,
        done: _none,
      );
    } on LumeDecimalException catch (e) {
      return _with(error: _errorFor(e));
    }
  }

  LumeCalcEngine operate(LumeCalcOp op) {
    if (halted) return this;
    if (awaiting && ops.isNotEmpty) {
      // An operator pressed straight after another replaces it; nothing is
      // evaluated, because nothing new has been entered.
      return _with(
        ops: <LumeCalcOp>[...ops.take(ops.length - 1), op],
        error: _none,
      );
    }
    LumeDecimal cur = value;
    final List<LumeDecimal> os = <LumeDecimal>[...operands];
    final List<LumeCalcOp> ps = <LumeCalcOp>[...ops];
    try {
      while (ps.isNotEmpty && _precedence(ps.last) >= _precedence(op)) {
        cur = _apply(ps.removeLast(), os.removeLast(), cur);
      }
    } on LumeDecimalException catch (e) {
      return _with(error: _errorFor(e));
    }
    return _with(
      entry: '',
      shown: cur,
      operands: <LumeDecimal>[...os, cur],
      ops: <LumeCalcOp>[...ps, op],
      awaiting: true,
      fresh: true,
      error: _none,
      done: _none,
    );
  }

  LumeCalcEngine equals() {
    if (halted) return this;
    final LumeDecimal cur = value;
    final List<LumeDecimal> all;
    final List<LumeCalcOp> os;
    final LumeCalcOp op;
    final LumeDecimal rhs;
    if (ops.isEmpty) {
      final LumeCalcOp? repeat = lastOp;
      final LumeDecimal? last = lastRhs;
      if (repeat == null || last == null) {
        // Nothing to work out and nothing to repeat: the entry settles, and
        // that is all.
        return _with(entry: '', shown: cur, fresh: true, error: _none);
      }
      all = <LumeDecimal>[cur, last];
      os = <LumeCalcOp>[repeat];
      op = repeat;
      rhs = last;
    } else {
      all = <LumeDecimal>[...operands, cur];
      os = ops;
      op = ops.last;
      rhs = cur;
    }
    final LumeDecimal result;
    try {
      result = evaluate(all, os);
    } on LumeDecimalException catch (e) {
      return _with(error: _errorFor(e));
    }
    final LumeCalcSum sum = LumeCalcSum(operands: all, ops: os, result: result);
    return _with(
      entry: '',
      shown: result,
      operands: const <LumeDecimal>[],
      ops: const <LumeCalcOp>[],
      lastOp: op,
      lastRhs: rhs,
      awaiting: false,
      fresh: true,
      error: _none,
      done: sum,
      history: <LumeCalcSum>[sum, ...history].take(historyLimit).toList(),
    );
  }

  /// Clear the entry, or — when there is no entry left to clear — everything
  /// but the history.
  LumeCalcEngine clear() {
    if (clearsEntryOnly) {
      return _with(
        entry: '',
        shown: LumeDecimal.zero,
        fresh: true,
        error: _none,
        done: _none,
      );
    }
    return LumeCalcEngine(history: history);
  }

  LumeCalcEngine backspace() {
    if (error != null) return _with(error: _none);
    if (entry.isEmpty) {
      return _with(shown: LumeDecimal.zero, fresh: true, done: _none);
    }
    final String next = entry.substring(0, entry.length - 1);
    if (next.isEmpty) {
      return _with(
        entry: '',
        shown: LumeDecimal.zero,
        fresh: true,
        done: _none,
      );
    }
    return _with(entry: next, done: _none);
  }

  // ---- arithmetic --------------------------------------------------------

  /// [operands] and the [ops] between them, worked out with `×` and `÷`
  /// before `+` and `−`, each level left to right.
  static LumeDecimal evaluate(
    List<LumeDecimal> operands,
    List<LumeCalcOp> ops,
  ) {
    final List<LumeDecimal> terms = <LumeDecimal>[operands.first];
    final List<LumeCalcOp> between = <LumeCalcOp>[];
    for (int i = 0; i < ops.length; i++) {
      final LumeCalcOp op = ops[i];
      final LumeDecimal next = operands[i + 1];
      if (_precedence(op) == 2) {
        terms[terms.length - 1] = _apply(op, terms.last, next);
      } else {
        between.add(op);
        terms.add(next);
      }
    }
    LumeDecimal total = terms.first;
    for (int i = 0; i < between.length; i++) {
      total = _apply(between[i], total, terms[i + 1]);
    }
    return total;
  }

  static int _precedence(LumeCalcOp op) =>
      op == LumeCalcOp.multiply || op == LumeCalcOp.divide ? 2 : 1;

  static LumeDecimal _apply(LumeCalcOp op, LumeDecimal a, LumeDecimal b) =>
      switch (op) {
        LumeCalcOp.add => a + b,
        LumeCalcOp.subtract => a - b,
        LumeCalcOp.multiply => a * b,
        LumeCalcOp.divide => a.divide(b),
      };

  static LumeCalcError _errorFor(LumeDecimalException e) => switch (e.failure) {
    LumeDecimalFailure.divideByZero => LumeCalcError.divideByZero,
    LumeDecimalFailure.precision => LumeCalcError.precision,
    LumeDecimalFailure.overflow => LumeCalcError.overflow,
    LumeDecimalFailure.malformed => LumeCalcError.overflow,
  };

  static String _settled(String e) =>
      e.endsWith('.') ? e.substring(0, e.length - 1) : e;

  static int _digits(String e) => e.replaceAll('.', '').length;

  // ---- carrying the state between openings -------------------------------

  /// The whole engine as one string, for [LumeToolSession].
  ///
  /// `context.js` keeps the calculator's state in a module object, so leaving
  /// the tool and coming back finds the sum where it was left. This is that,
  /// written as text rather than as a live object — and as *decimals*, not as
  /// formatted rows, so a reader who changes language sees their own history
  /// re-rendered rather than English left behind.
  String encode() => <String>[
    entry,
    shown.toDecimalString(),
    operands.map((LumeDecimal d) => d.toDecimalString()).join(','),
    ops.map(_opCode).join(','),
    lastOp == null ? '' : _opCode(lastOp!),
    lastRhs?.toDecimalString() ?? '',
    '${awaiting ? 'a' : ''}${fresh ? 'f' : ''}',
    error?.name ?? '',
    done?.encode() ?? '',
    history.map((LumeCalcSum s) => s.encode()).join(_row),
  ].join(_field);

  /// [encode]'s inverse. Anything that does not read back cleanly is a fresh
  /// engine, never a half-restored one.
  static LumeCalcEngine decode(String? text) {
    if (text == null || text.isEmpty) return const LumeCalcEngine();
    final List<String> f = text.split(_field);
    if (f.length != 10) return const LumeCalcEngine();
    try {
      final List<LumeDecimal> operands = f[2].isEmpty
          ? <LumeDecimal>[]
          : f[2].split(',').map(LumeDecimal.parse).toList();
      final List<LumeCalcOp> ops = <LumeCalcOp>[];
      if (f[3].isNotEmpty) {
        for (final String c in f[3].split(',')) {
          final LumeCalcOp? op = _opOf(c);
          if (op == null) return const LumeCalcEngine();
          ops.add(op);
        }
      }
      if (operands.length != ops.length) return const LumeCalcEngine();
      return LumeCalcEngine(
        entry: f[0],
        shown: LumeDecimal.parse(f[1]),
        operands: operands,
        ops: ops,
        lastOp: f[4].isEmpty ? null : _opOf(f[4]),
        lastRhs: f[5].isEmpty ? null : LumeDecimal.parse(f[5]),
        awaiting: f[6].contains('a'),
        fresh: f[6].contains('f'),
        error: f[7].isEmpty
            ? null
            : LumeCalcError.values
                  .where((LumeCalcError e) => e.name == f[7])
                  .firstOrNull,
        done: f[8].isEmpty ? null : LumeCalcSum.decode(f[8]),
        history: f[9].isEmpty
            ? const <LumeCalcSum>[]
            : <LumeCalcSum>[
                for (final String r in f[9].split(_row))
                  if (LumeCalcSum.decode(r) case final LumeCalcSum s) s,
              ],
      );
    } on LumeDecimalException {
      return const LumeCalcEngine();
    }
  }

  /// A sentinel, so a copy can set a nullable field back to `null`.
  static const Object _none = Object();

  LumeCalcEngine _with({
    String? entry,
    LumeDecimal? shown,
    List<LumeDecimal>? operands,
    List<LumeCalcOp>? ops,
    Object? lastOp,
    Object? lastRhs,
    bool? awaiting,
    bool? fresh,
    Object? error,
    Object? done,
    List<LumeCalcSum>? history,
  }) => LumeCalcEngine(
    entry: entry ?? this.entry,
    shown: shown ?? this.shown,
    operands: operands ?? this.operands,
    ops: ops ?? this.ops,
    lastOp: identical(lastOp, _none)
        ? null
        : (lastOp as LumeCalcOp?) ?? this.lastOp,
    lastRhs: identical(lastRhs, _none)
        ? null
        : (lastRhs as LumeDecimal?) ?? this.lastRhs,
    awaiting: awaiting ?? this.awaiting,
    fresh: fresh ?? this.fresh,
    error: identical(error, _none)
        ? null
        : (error as LumeCalcError?) ?? this.error,
    done: identical(done, _none) ? null : (done as LumeCalcSum?) ?? this.done,
    history: history ?? this.history,
  );
}
