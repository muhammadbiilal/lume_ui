/// The editorial feed — `tool-data.js` `NEWS`, typed.
///
/// Two editions, as the reference has two: Pakistan's, and the global one
/// every other country reads (`newsFor(code)`). The first story of a list is
/// its lead. Headlines and categories are keys, so a story reads in the
/// reader's language; publishers are the names they publish under, which are
/// not translated.
///
/// **Dayroz obligation:** fixture content. A real feed needs licensed
/// publisher sources, dated items, the reader's region, and editorial review
/// of every headline's translation before it ships.
library;

import 'package:flutter/foundation.dart';

import '../../../core/widgets/lume/lume_art.dart';

/// `NEWS_CATEGORIES`, in the order the chips draw them.
enum LumeNewsCategory {
  top,
  business,
  world,
  technology,
  sport,
  health,
  lifestyle,
}

@immutable
class LumeNewsStory {
  const LumeNewsStory({
    required this.id,
    required this.category,
    required this.publisher,
    required this.minutes,
    required this.minutesAgo,
    required this.tone,
  });

  /// Stable, and the key its headline is written under.
  final String id;
  final LumeNewsCategory category;

  /// `src` — the publisher's own name.
  final String publisher;

  /// `mins` — reading time.
  final int minutes;

  /// `ago`, as a number: "18 min" is 18, "2 hr" is 120.
  final int minutesAgo;
  final LumeArtTone tone;
}

abstract final class LumeNewsEditions {
  static const List<LumeNewsStory> pakistan = <LumeNewsStory>[
    LumeNewsStory(
      id: 'pkRupee',
      category: LumeNewsCategory.business,
      publisher: 'Business Recorder',
      minutes: 4,
      minutesAgo: 18,
      tone: LumeArtTone.accent,
    ),
    LumeNewsStory(
      id: 'pkLoadshedding',
      category: LumeNewsCategory.top,
      publisher: 'Dawn',
      minutes: 3,
      minutesAgo: 42,
      tone: LumeArtTone.amber,
    ),
    LumeNewsStory(
      id: 'pkSquad',
      category: LumeNewsCategory.sport,
      publisher: 'Geo Super',
      minutes: 5,
      minutesAgo: 60,
      tone: LumeArtTone.violet,
    ),
    LumeNewsStory(
      id: 'pkStartups',
      category: LumeNewsCategory.technology,
      publisher: 'Profit',
      minutes: 7,
      minutesAgo: 120,
      tone: LumeArtTone.sky,
    ),
    LumeNewsStory(
      id: 'pkTrade',
      category: LumeNewsCategory.world,
      publisher: 'The News',
      minutes: 6,
      minutesAgo: 180,
      tone: LumeArtTone.indigo,
    ),
    LumeNewsStory(
      id: 'pkDengue',
      category: LumeNewsCategory.health,
      publisher: 'Express Tribune',
      minutes: 4,
      minutesAgo: 240,
      tone: LumeArtTone.green,
    ),
  ];

  static const List<LumeNewsStory> global = <LumeNewsStory>[
    LumeNewsStory(
      id: 'globalRates',
      category: LumeNewsCategory.business,
      publisher: 'Reuters',
      minutes: 5,
      minutesAgo: 22,
      tone: LumeArtTone.accent,
    ),
    LumeNewsStory(
      id: 'globalOnDevice',
      category: LumeNewsCategory.technology,
      publisher: 'The Verge',
      minutes: 8,
      minutesAgo: 60,
      tone: LumeArtTone.violet,
    ),
    LumeNewsStory(
      id: 'globalCoastal',
      category: LumeNewsCategory.world,
      publisher: 'AP',
      minutes: 6,
      minutesAgo: 120,
      tone: LumeArtTone.sky,
    ),
    LumeNewsStory(
      id: 'globalWalk',
      category: LumeNewsCategory.health,
      publisher: 'BBC',
      minutes: 4,
      minutesAgo: 180,
      tone: LumeArtTone.green,
    ),
    LumeNewsStory(
      id: 'globalTodo',
      category: LumeNewsCategory.lifestyle,
      publisher: 'Lume Editorial',
      minutes: 6,
      minutesAgo: 300,
      tone: LumeArtTone.amber,
    ),
    LumeNewsStory(
      id: 'globalTactics',
      category: LumeNewsCategory.sport,
      publisher: 'Guardian',
      minutes: 7,
      minutesAgo: 360,
      tone: LumeArtTone.rose,
    ),
  ];

  /// `newsFor(code)` — the country's edition, or the global one.
  static List<LumeNewsStory> forCountry(String code) =>
      code.toUpperCase() == 'PK' ? pakistan : global;
}
