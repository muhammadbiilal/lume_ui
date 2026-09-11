/// The password rules, and the strength advice that sits on top of them.
///
/// **One array, read twice.** The checklist the screen draws is the rule the
/// repository enforces — `LumePasswordPolicy.checks` is what `pwrules` renders
/// *and* what a sign-up tests. A screen that showed one list while the engine
/// applied another would refuse a password that looked, on screen, entirely
/// acceptable.
///
/// Strength is advice, never a substitute for the rules: a password that fails
/// a displayed rule can never read better than "Fair", because
/// `aaaaaaaaaaaa!` scoring "Good" beside two unticked rows — and then being
/// refused — is a screen arguing with itself.
library;

import 'package:flutter/foundation.dart';

/// One rule, and whether this password meets it.
@immutable
class LumePasswordCheck {
  const LumePasswordCheck(this.rule, {required this.met});

  final LumePasswordRule rule;
  final bool met;
}

/// The four rules, in the order they are drawn.
enum LumePasswordRule { length, upper, lower, digit }

/// How strong a password reads. `none` is the empty field.
enum LumePasswordStrength { none, weak, fair, good, strong }

/// The rules, as a function of a string.
abstract final class LumePasswordPolicy {
  /// The shortest password the product accepts.
  static const int minLength = 8;

  /// Every rule, with its verdict. The order is the rendering order.
  static List<LumePasswordCheck> checks(String password) => <LumePasswordCheck>[
    LumePasswordCheck(
      LumePasswordRule.length,
      met: password.length >= minLength,
    ),
    LumePasswordCheck(
      LumePasswordRule.upper,
      met: password.contains(RegExp(r'[A-Z]')),
    ),
    LumePasswordCheck(
      LumePasswordRule.lower,
      met: password.contains(RegExp(r'[a-z]')),
    ),
    LumePasswordCheck(
      LumePasswordRule.digit,
      met: password.contains(RegExp(r'[0-9]')),
    ),
  ];

  /// Whether every rule is met. The only test a submission makes.
  static bool isAcceptable(String password) =>
      checks(password).every((LumePasswordCheck c) => c.met);

  /// The advice. Capped at [LumePasswordStrength.fair] while any rule is
  /// unmet, so the meter can never contradict the checklist beside it.
  static LumePasswordStrength strength(String password) {
    if (password.isEmpty) return LumePasswordStrength.none;

    final List<LumePasswordCheck> rules = checks(password);
    final int met = rules.where((LumePasswordCheck c) => c.met).length;
    final int bonus =
        (password.length >= 12 ? 1 : 0) +
        (password.contains(RegExp(r'[^A-Za-z0-9]')) ? 1 : 0);

    int score = (((met + bonus) * 4) / 6).round().clamp(1, 4);
    if (met < rules.length) score = score.clamp(1, 2);

    return switch (score) {
      1 => LumePasswordStrength.weak,
      2 => LumePasswordStrength.fair,
      3 => LumePasswordStrength.good,
      _ => LumePasswordStrength.strong,
    };
  }

  /// How many of the meter's four segments are lit.
  static int segments(LumePasswordStrength s) => switch (s) {
    LumePasswordStrength.none => 0,
    LumePasswordStrength.weak => 1,
    LumePasswordStrength.fair => 2,
    LumePasswordStrength.good => 3,
    LumePasswordStrength.strong => 4,
  };
}

/// Whether a string is an address Lume will try to send to.
///
/// Deliberately permissive about what an address may contain and strict about
/// the two lengths that are actually specified, because the only authority on
/// whether an address exists is the mail that reaches it.
abstract final class LumeEmailPolicy {
  static final RegExp _shape = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9]"
    r'(?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  static bool isValid(String value) {
    final String s = value.trim();
    if (s.isEmpty || s.length > 254) return false;
    if (s.split('@').first.length > 64) return false;
    return _shape.hasMatch(s);
  }

  /// The form an address is stored and compared in.
  static String normalise(String value) => value.trim().toLowerCase();

  /// Enough of the address to recognise, not enough to hand to whoever is
  /// looking over the shoulder.
  ///
  /// The first character, then between one and five bullets, then the domain —
  /// the bullet count does not give the length away beyond five.
  static String mask(String value) {
    final String s = value.trim();
    final int at = s.indexOf('@');
    if (at < 1) return s;
    final String head = s.substring(0, at);
    final int dots = (head.length - 1).clamp(1, 5);
    return '${head[0]}${'•' * dots}${s.substring(at)}';
  }
}
