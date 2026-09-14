/// A bill, a tip and a split, as `context.js` `tipSplit()` works them out.
library;

import 'package:flutter/foundation.dart';

@immutable
class LumeTipSplit {
  const LumeTipSplit._({
    required this.bill,
    required this.tip,
    required this.people,
  });

  /// `tipSplit()` — a bill of forty dollars in the reader's currency, a tip
  /// of 10 % and two people.
  factory LumeTipSplit.of({
    required double bill,
    required int tip,
    required int people,
  }) => LumeTipSplit._(
    bill: bill < 0 ? 0 : bill,
    tip: tip,
    people: people < minPeople ? minPeople : people,
  );

  /// The chips `[0, 5, 10, 15, 20]`.
  static const List<int> tips = <int>[0, 5, 10, 15, 20];
  static const int defaultTip = 10;
  static const int defaultPeople = 2;

  /// The reference lets the stepper reach 0 people and then charges the one
  /// person nobody is; Lume stops at one.
  static const int minPeople = 1;
  static const int maxPeople = 99;

  /// `Math.round(40 * rate)`.
  static double openingBill(double ratePerUsd) =>
      (40 * ratePerUsd).round() * 1.0;

  final double bill;
  final int tip;
  final int people;

  double get tipAmount => bill * tip / 100;
  double get total => bill + tipAmount;
  double get each => total / people;
}
