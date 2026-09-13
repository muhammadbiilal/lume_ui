/// The search index, as a deterministic fixture.
///
/// It behaves like `services/search.js` — the same index, the same seven
/// extra entries, the same scoring, the same cap — and it reaches nothing
/// beyond the catalogue and the reader's own profile. **Not durable, not
/// remote, and never described as either**: [isDurable] is `false`.
///
/// The one thing it is careful about is what it is allowed to find.
/// `visibleFeatures` is the selector Home and the hub ask, so a faith-gated
/// or country-gated tool is absent from the index rather than filtered out of
/// the results — there is no list it could leak from.
library;

import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../home/domain/home_repository.dart';
import '../domain/search_model.dart';

/// One entry the catalogue does not carry.
///
/// `EXTRA_INDEX` in `services/search.js`. Two are settings, three are
/// chapters of the Qur'an, one is a station and one is a place — all of them
/// things a reader types looking for something the catalogue does not name.
class _Extra {
  const _Extra({
    required this.icon,
    required this.action,
    required this.keywords,
    this.target = '',
    this.name,
    this.subtitle,
    this.faith = false,
    this.country,
  });

  /// A proper noun stays as written; a UI label carries a key instead and is
  /// resolved through [AppLocalizations] (§47, §106).
  final String? name;
  final String? subtitle;
  final String icon;
  final LumeSearchAction action;
  final String target;
  final String keywords;

  /// Part of the Islamic experience. Absent unless the reader asked for it.
  final bool faith;

  /// The one market this entry exists in. `null` means everywhere.
  final String? country;
}

/// The reference's own seven, in its order.
///
/// **Fixture-only.** The three surahs, the station and the mosque are sample
/// data standing in for content Dayroz will index: a Qur'an chapter list, a
/// station table, and a places source. Each is named in
/// `docs/conversion_archive/CROSS_CUTTING_INVENTORY.md` with the obligation
/// that replaces it.
const List<_Extra> _kExtra = <_Extra>[
  _Extra(
    icon: 'moon',
    action: LumeSearchAction.theme,
    keywords: 'theme night light appearance',
  ),
  _Extra(
    icon: 'sliders',
    action: LumeSearchAction.sheet,
    target: 'personalise',
    keywords: 'interests country islamic content preferences religion',
  ),
  _Extra(
    name: 'Surah Ar-Rahman',
    subtitle: 'Qur’an · chapter 55',
    icon: 'book',
    action: LumeSearchAction.tool,
    target: 'quran',
    faith: true,
    keywords: 'surah rahman 55 recite',
  ),
  _Extra(
    name: 'Surah Al-Kahf',
    subtitle: 'Qur’an · chapter 18',
    icon: 'book',
    action: LumeSearchAction.tool,
    target: 'quran',
    faith: true,
    keywords: 'surah kahf 18 friday cave',
  ),
  _Extra(
    name: 'Surah Yaseen',
    subtitle: 'Qur’an · chapter 36',
    icon: 'book',
    action: LumeSearchAction.tool,
    target: 'quran',
    faith: true,
    keywords: 'surah yaseen yasin 36',
  ),
  _Extra(
    name: 'Karachi Cantt',
    subtitle: 'Station · Pakistan Railways',
    icon: 'train',
    action: LumeSearchAction.destination,
    target: 'trains',
    country: 'PK',
    keywords: 'station karachi cantt platform',
  ),
  _Extra(
    name: 'Masjid-e-Tooba',
    subtitle: 'Nearby · 650 m',
    icon: 'mosque',
    action: LumeSearchAction.say,
    target: 'Masjid-e-Tooba · 650 m',
    faith: true,
    keywords: 'mosque masjid nearby',
  ),
];

/// One indexed row and the text it answers to.
class _Indexed {
  const _Indexed(this.hit, this.haystack);

  final LumeSearchHit hit;

  /// Lowercased. The English name, the localised name and the keywords, so a
  /// reader who learned a tool's English name does not lose it by switching
  /// language (C18).
  final String haystack;
}

/// The catalogue, the profile and seven extras — searched.
class LumeFixtureSearchRepository
    implements LumeSearchRepository, LumeSearchDurability {
  LumeFixtureSearchRepository({
    required this.eligibility,
    required this.l,
    required this.user,
    required this.recents,
    this.live = LumeToolStatuses.none,
    this.formatting,
  });

  final LumeEligibility eligibility;
  final AppLocalizations l;
  final LumeUserContext user;

  /// Feature ids, most recent first, as the profile holds them.
  final List<String> recents;

  /// The status lines that would otherwise go stale — the weather's
  /// temperature and sky, the next prayer. `syncFeatureMeta` writes them into
  /// the catalogue in the reference, so a recent under the search field says
  /// what the same tool's tile on Home says. Without [formatting] a recent
  /// falls back to the catalogue's static line.
  final LumeToolStatuses live;
  final LumeFormatting? formatting;

  /// The most hits the reference ever shows.
  static const int limit = 14;

  /// The suggestion chips, capped.
  static const int suggestionLimit = 6;

  /// How many recents the idle sheet lists.
  static const int recentLimit = 4;

  /// What "jump back in" falls back to when nothing has been opened yet.
  static const List<String> fallbackRecents = <String>[
    'calculator',
    'weather',
    'calendar',
  ];

  @override
  bool get isDurable => false;

  List<_Indexed>? _cache;

  /// Built once per repository, because the profile it depends on is what
  /// makes a new one.
  List<_Indexed> get _index => _cache ??= _build();

  /// How many rows this reader's index holds. The only thing outside needs
  /// to know about it, and what a test asserts eligibility against.
  int get indexSize => _index.length;

  List<_Indexed> _build() {
    final List<_Indexed> out = <_Indexed>[];

    for (final LumeFeature f in eligibility.visibleFeatures(user)) {
      final String name = LumeFeatureStrings.name(l, f.id);
      out.add(
        _Indexed(
          LumeSearchHit(
            title: name,
            subtitle: LumeFeatureStrings.category(l, f.category),
            icon: f.icon,
            action: LumeSearchAction.tool,
            target: f.id,
            featureId: f.id,
          ),
          // The English name as well as the localised one, and the keywords.
          '${f.fallbackName.toLowerCase()} ${name.toLowerCase()} '
          '${f.keywords.join(' ')}',
        ),
      );
    }

    for (final _Extra x in _kExtra) {
      if (x.faith && !user.islamic) continue;
      if (x.country != null && x.country != user.country) continue;
      final String name = x.name ?? _extraName(x);
      out.add(
        _Indexed(
          LumeSearchHit(
            title: name,
            subtitle: x.subtitle ?? l.searchInSettings,
            icon: x.icon,
            action: x.action,
            target: x.target,
          ),
          '${name.toLowerCase()} ${x.name?.toLowerCase() ?? ''} ${x.keywords}',
        ),
      );
    }
    return out;
  }

  String _extraName(_Extra x) => switch (x.action) {
    LumeSearchAction.theme => l.searchDarkMode,
    LumeSearchAction.sheet => l.persTitle,
    _ => '',
  };

  /// `runSearch`'s scoring, exactly.
  ///
  /// Every word must appear or the row is dropped. A word at the very start
  /// of the haystack is worth 6, one at the start of any other word 4, one
  /// buried inside a word 2 — so "cal" ranks Calculator above Calendar only
  /// because of where the letters fall, which is what the reference does.
  static int scoreOf(String haystack, List<String> words) {
    int score = 0;
    for (final String w in words) {
      final int at = haystack.indexOf(w);
      if (at == -1) return -99;
      score += at == 0
          ? 6
          : haystack.contains(' $w')
          ? 4
          : 2;
    }
    return score;
  }

  @override
  Future<LumeSearchResults> search(String query) async {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return LumeSearchResults(query: q, hits: const <LumeSearchHit>[]);
    }

    final List<String> words = q
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty)
        .toList(growable: false);

    final List<(int, int, LumeSearchHit)> scored = <(int, int, LumeSearchHit)>[
      for (int i = 0; i < _index.length; i++)
        if (scoreOf(_index[i].haystack, words) case final int s when s > 0)
          (s, i, _index[i].hit),
    ];

    // Descending by score; ties keep index order, because the reference's
    // sort is stable and its index is the catalogue's own order.
    scored.sort(((int, int, LumeSearchHit) a, (int, int, LumeSearchHit) b) {
      final int byScore = b.$1.compareTo(a.$1);
      return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
    });

    return LumeSearchResults(
      query: q,
      hits: <LumeSearchHit>[
        for (final (int, int, LumeSearchHit) row in scored.take(limit)) row.$3,
      ],
    );
  }

  @override
  Future<LumeSearchIdle> idle() async {
    final List<String> picks = <String>[
      if (user.country == 'PK') ...<String>['petrol', 'trains', 'bills'],
      if (user.islamic) ...<String>['qibla', 'surah rahman'],
      'currency',
      'calculator',
      'weather',
    ];

    List<LumeSearchHit> asHits(List<String> ids) => <LumeSearchHit>[
      for (final String id in ids)
        if (eligibility.visibleById(id, user) case final LumeFeature f)
          LumeSearchHit(
            title: LumeFeatureStrings.name(l, f.id),
            // The catalogue's own one-line description, which is what the
            // reference puts under a recent — not its category — and live
            // where the tile's is.
            subtitle:
                (formatting == null
                    ? LumeFeatureStrings.status(l, f.id)
                    : LumeFeatureStrings.tileStatus(
                        l,
                        formatting!,
                        f.id,
                        live,
                      )) ??
                '',
            icon: f.icon,
            action: LumeSearchAction.tool,
            target: f.id,
            featureId: f.id,
          ),
    ];

    List<LumeSearchHit> recent = asHits(recents).take(recentLimit).toList();
    if (recent.isEmpty) recent = asHits(fallbackRecents);

    return LumeSearchIdle(
      suggestions: picks.take(suggestionLimit).toList(growable: false),
      recent: recent,
    );
  }
}
