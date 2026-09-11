/// The 31 interests, their 6 groups, and what makes one reachable.
///
/// `assets/data/interests.json` is generated from the reference's own
/// catalogue by `docs/conversion_archive/tool/gen_interests.mjs`. It carries
/// ids, icons, the group each belongs to, the faith set, the defaults, and the
/// list of interests some feature declares — which is what `liveItems` filters
/// on.
///
/// Labels are not in it. The prototype hard-codes English ones in
/// `INTEREST_GROUPS` and renders them untranslated in every language; the
/// Flutter app translates them instead, so they live in the ARBs and arrive
/// here as a lookup. Recorded as a difference rather than reproduced.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/interests_model.dart';

/// One interest as the asset stores it: an id and a glyph, before a label.
typedef LumeInterestEntry = ({String id, String icon});

/// One group as the asset stores it.
typedef LumeInterestGroupEntry = ({
  String id,
  bool faith,
  List<LumeInterestEntry> items,
});

/// The catalogue, loaded once.
class LumeInterestsFixture {
  LumeInterestsFixture._({
    required this.groups,
    required this.faithInterests,
    required this.referencedByFeatures,
    required this.unreachable,
    required this.defaults,
    required this.minimum,
    required this.maximum,
  });

  /// Group id → the interest ids in it, in catalogue order.
  final List<LumeInterestGroupEntry> groups;

  /// `FAITH_INTERESTS` — what the switch clears when it is turned off.
  final Set<String> faithInterests;

  /// Every interest some feature declares. An ordinary interest is offered
  /// only when it is in here.
  final Set<String> referencedByFeatures;

  /// Declared in a group and referenced by nothing, so never rendered.
  /// Two of them: `sleep` and `quotes`.
  final Set<String> unreachable;

  /// `DEFAULT_INTERESTS` — what a skipped picker falls back to.
  final List<String> defaults;

  final int minimum;
  final int maximum;

  static const String assetPath = 'assets/data/interests.json';

  static LumeInterestsFixture? _cache;

  static Future<LumeInterestsFixture> load() async {
    final LumeInterestsFixture? cached = _cache;
    if (cached != null) return cached;
    final LumeInterestsFixture parsed = parse(
      await rootBundle.loadString(assetPath),
    );
    _cache = parsed;
    return parsed;
  }

  @visibleForTesting
  static LumeInterestsFixture parse(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;

    return LumeInterestsFixture._(
      groups: <LumeInterestGroupEntry>[
        for (final dynamic g in json['groups'] as List<dynamic>)
          (
            id: (g as Map<String, dynamic>)['id'] as String,
            faith: g['faith'] as bool,
            items: <LumeInterestEntry>[
              for (final dynamic i in g['items'] as List<dynamic>)
                (
                  id: (i as Map<String, dynamic>)['id'] as String,
                  icon: i['icon'] as String,
                ),
            ],
          ),
      ],
      faithInterests: (json['faithInterests'] as List<dynamic>)
          .cast<String>()
          .toSet(),
      referencedByFeatures: (json['referencedByFeatures'] as List<dynamic>)
          .cast<String>()
          .toSet(),
      unreachable: (json['unreachable'] as List<dynamic>)
          .cast<String>()
          .toSet(),
      defaults: (json['defaults'] as List<dynamic>).cast<String>(),
      minimum: json['minimum'] as int,
      maximum: json['maximum'] as int,
    );
  }

  @visibleForTesting
  static void reset() => _cache = null;

  /// Every interest id in the catalogue, in order.
  List<String> get allIds => <String>[
    for (final LumeInterestGroupEntry g in groups)
      for (final LumeInterestEntry i in g.items) i.id,
  ];

  int get interestCount => allIds.length;
  int get groupCount => groups.length;

  /// The groups, localised and filtered the way `liveItems` filters them.
  ///
  /// [label] supplies an interest's name and [groupLabel] a group's, so this
  /// layer holds no user-facing text. [visibleFeatureInterests] is the set of
  /// interests some feature *this user can see* declares — the eligibility
  /// engine's answer. Until that engine exists, the fixture passes
  /// [referencedByFeatures], which is the same answer for a user who can see
  /// everything.
  List<LumeInterestGroup> build({
    required String Function(String id) label,
    required String Function(String id) groupLabel,
    Set<String>? visibleFeatureInterests,
  }) {
    final Set<String> reachable =
        visibleFeatureInterests ?? referencedByFeatures;

    return LumeInterests.offer(
      all: <LumeInterestGroup>[
        for (final LumeInterestGroupEntry g in groups)
          LumeInterestGroup(
            id: g.id,
            label: groupLabel(g.id),
            faith: g.faith,
            interests: <LumeInterest>[
              for (final LumeInterestEntry i in g.items)
                LumeInterest(id: i.id, label: label(i.id), icon: i.icon),
            ],
          ),
      ],
      reachable: reachable.contains,
    );
  }
}
