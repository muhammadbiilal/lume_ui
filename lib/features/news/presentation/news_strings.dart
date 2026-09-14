/// The editorial feed, in the reader's language.
library;

import '../../../l10n/app_localizations.dart';
import '../data/news_fixtures.dart';

abstract final class LumeNewsStrings {
  static String category(AppLocalizations l, LumeNewsCategory c) => switch (c) {
    LumeNewsCategory.top => l.newsCatTop,
    LumeNewsCategory.business => l.newsCatBusiness,
    LumeNewsCategory.world => l.newsCatWorld,
    LumeNewsCategory.technology => l.newsCatTechnology,
    LumeNewsCategory.sport => l.newsCatSport,
    LumeNewsCategory.health => l.newsCatHealth,
    LumeNewsCategory.lifestyle => l.newsCatLifestyle,
  };

  /// Home and Explore already carry three of these headlines word for word;
  /// those keys are shared rather than written twice.
  static String headline(AppLocalizations l, String id) => switch (id) {
    'pkRupee' => l.newsRupee,
    'pkLoadshedding' => l.newsLoadshed,
    'pkSquad' => l.newsHeadlinePkSquad,
    'pkStartups' => l.newsHeadlinePkStartups,
    'pkTrade' => l.newsHeadlinePkTrade,
    'pkDengue' => l.newsHeadlinePkDengue,
    'globalRates' => l.newsHeadlineGlobalRates,
    'globalOnDevice' => l.newsHeadlineGlobalOnDevice,
    'globalCoastal' => l.newsHeadlineGlobalCoastal,
    'globalWalk' => l.newsHeadlineGlobalWalk,
    'globalTodo' => l.newsShortList,
    'globalTactics' => l.newsHeadlineGlobalTactics,
    _ => id,
  };

  /// `ago` — "18 min" under an hour, "2 hr" from one.
  static String ago(AppLocalizations l, int minutes) =>
      minutes < 60 ? l.newsAgoMinutes(minutes) : l.newsAgoHours(minutes ~/ 60);
}
