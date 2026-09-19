/// Initials for a tinted disc — a person in Ledger, a merchant in
/// Installments — by one rule.
///
/// The first grapheme of each word, where a word is also split where a
/// lowercase letter meets an uppercase one: `TechMart` is two words, as the
/// reference writes its logo ("TM"), and `Mobile Hub` is "MH". At most two
/// initials, uppercased. A single plain word gives one initial ("Wheels" →
/// "W"). Scripts without case (Arabic, Urdu) split on spaces only:
/// "محمد علي" → "مع". Graphemes, not code units, so a letter with a
/// combining mark stays whole. `null` when the name has no letters, and the
/// caller draws a neutral icon instead.
library;

import 'package:flutter/widgets.dart' show StringCharacters;

String? lumeInitials(String name) {
  final RegExp letter = RegExp(r'\p{L}', unicode: true);
  bool lower(String g) => g != g.toUpperCase() && g == g.toLowerCase();
  bool upper(String g) => g != g.toLowerCase() && g == g.toUpperCase();

  final List<String> firsts = <String>[];
  for (final String word in name.trim().split(RegExp(r'\s+'))) {
    String? previous;
    bool start = true;
    for (final String g in word.characters) {
      final bool boundary =
          start || (previous != null && lower(previous) && upper(g));
      if (boundary && letter.hasMatch(g)) {
        firsts.add(g);
        if (firsts.length == 2) break;
      }
      start = false;
      previous = g;
    }
    if (firsts.length == 2) break;
  }
  if (firsts.isEmpty) return null;
  return firsts.join().toUpperCase();
}
