/// The five phrases the reference counts, exactly as it holds them.
///
/// `assets/js/data/tool-data.js:678-684` — `DHIKR`. Each entry carries four
/// things and only those four: the Arabic, a transliteration, a plain English
/// gloss, and the conventional number in one round.
///
/// **This list is reproduced, not extended.** No sixth phrase is added, no
/// commentary, no virtue, no ruling, no source citation and no scripture: the
/// repository has no verified licensed religious text behind this tool, so
/// nothing is asserted that a source would have to stand behind. The gloss is
/// the reference's own content, which is why it lives here as data rather
/// than in the ARBs — like `LumeHadithFixtures`, content is carried as a
/// source gives it and the interface around it is translated (C77). It is
/// labelled on screen with `l.tasbihMeaning`, so it reads as a gloss rather
/// than as a translation of record.
///
/// [target] is a fact about the round, stated as "Round of 33"
/// (`l.tasbihTargetLabel`). It is never presented as required, recommended or
/// rewarded. Tasbih counts and resets; that is all it does.
library;

import 'package:flutter/foundation.dart';

/// One phrase, as `DHIKR` gives it.
@immutable
class LumeTasbihPhrase {
  const LumeTasbihPhrase({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.target,
  });

  /// `ar` — Arabic script, as the source holds it. Data, not a string to be
  /// translated: it is the same in every interface language.
  final String arabic;

  /// `tl` — how the phrase is written in Latin script. The chip's label.
  final String transliteration;

  /// `tr` — a plain gloss of what the words mean, shown under
  /// `l.tasbihMeaning`.
  final String meaning;

  /// The conventional number in one round: 33, 33, 34, 100, 100.
  final int target;
}

/// `DHIKR`, in the reference's order.
abstract final class LumeTasbihPhrases {
  static const List<LumeTasbihPhrase> all = <LumeTasbihPhrase>[
    LumeTasbihPhrase(
      arabic: 'سُبْحَانَ اللَّه',
      transliteration: 'SubhanAllah',
      meaning: 'Glory be to God',
      target: 33,
    ),
    LumeTasbihPhrase(
      arabic: 'الْحَمْدُ لِلَّه',
      transliteration: 'Alhamdulillah',
      meaning: 'All praise is for God',
      target: 33,
    ),
    LumeTasbihPhrase(
      arabic: 'اللَّهُ أَكْبَر',
      transliteration: 'Allahu Akbar',
      meaning: 'God is the greatest',
      target: 34,
    ),
    LumeTasbihPhrase(
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّه',
      transliteration: 'La ilaha illallah',
      meaning: 'There is no god but God',
      target: 100,
    ),
    LumeTasbihPhrase(
      arabic: 'أَسْتَغْفِرُ اللَّه',
      transliteration: 'Astaghfirullah',
      meaning: 'I seek God’s forgiveness',
      target: 100,
    ),
  ];

  /// The first phrase, which is where a fresh counter starts.
  static const int first = 0;

  /// Whether [index] names a phrase this list holds.
  static bool holds(int index) => index >= 0 && index < all.length;
}
