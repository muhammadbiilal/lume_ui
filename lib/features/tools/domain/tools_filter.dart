/// What the Tools hub is showing, and why.
///
/// Three things narrow the catalogue and they compose in a deliberate order:
///
/// 1. **search**, which always looks across the whole visible catalogue —
///    being on "For you" must never stop someone finding a tool by name;
/// 2. **the category chips**;
/// 3. **"For you"**, which is a shortlist rather than a straitjacket: an
///    interest match, something reached for recently, or a tool nearly
///    everyone wants.
///
/// All three are pure functions of the eligible catalogue and the query, so the
/// hub's behaviour can be asserted without a frame — including the two kinds of
/// nothing, which need different words.
library;

import 'package:flutter/foundation.dart';

import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';

/// Which chip is selected.
@immutable
sealed class LumeToolsFilter {
  const LumeToolsFilter();

  /// The shortlist. The opening state.
  static const LumeToolsFilter forYou = LumeForYouFilter();

  /// Everything this user can reach.
  static const LumeToolsFilter all = LumeAllFilter();

  /// One category.
  const factory LumeToolsFilter.category(LumeToolCategory id) =
      LumeCategoryFilter;

  /// A stable identifier, for a key and for a test.
  String get id;
}

final class LumeForYouFilter extends LumeToolsFilter {
  const LumeForYouFilter();
  @override
  String get id => 'foryou';
  @override
  bool operator ==(Object other) => other is LumeForYouFilter;
  @override
  int get hashCode => id.hashCode;
}

final class LumeAllFilter extends LumeToolsFilter {
  const LumeAllFilter();
  @override
  String get id => 'all';
  @override
  bool operator ==(Object other) => other is LumeAllFilter;
  @override
  int get hashCode => id.hashCode;
}

final class LumeCategoryFilter extends LumeToolsFilter {
  const LumeCategoryFilter(this.category);
  final LumeToolCategory category;
  @override
  String get id => category.name;
  @override
  bool operator ==(Object other) =>
      other is LumeCategoryFilter && other.category == category;
  @override
  int get hashCode => category.hashCode;
}

/// One category block, with only the tools that survived the narrowing.
@immutable
class LumeToolGroup {
  const LumeToolGroup({required this.category, required this.tools});

  final LumeCategory category;
  final List<LumeFeature> tools;
}

/// Why the hub is showing nothing.
enum LumeToolsEmpty {
  /// A search that matched nothing.
  noMatch,

  /// A shortlist that is still empty — nobody has chosen an interest yet.
  shortlistEmpty,
}

/// What the hub renders.
@immutable
class LumeToolsView {
  const LumeToolsView({
    required this.chips,
    required this.filter,
    required this.groups,
    required this.recents,
    required this.catalogueCount,
    required this.shownCount,
    this.empty,
  });

  /// "For you", "All", then one per visible category.
  final List<LumeToolsFilter> chips;

  /// The selected chip, already validated against [chips].
  final LumeToolsFilter filter;

  /// Only the categories with something in them.
  final List<LumeToolGroup> groups;

  /// The recently-used strip. Empty below two, which is the reference's rule:
  /// one pill is not a history.
  final List<LumeFeature> recents;

  /// How many tools this user has in total. The heading's count, and
  /// deliberately **not** the number on screen — the chips narrow the view,
  /// not the catalogue.
  final int catalogueCount;

  /// How many are visible after the narrowing.
  final int shownCount;

  /// `null` when something is showing.
  final LumeToolsEmpty? empty;
}

/// The hub's whole selection logic.
abstract final class LumeToolsQuery {
  /// A tool almost everyone wants, so it survives "For you".
  static bool _isShortlisted(LumeFeature f, LumeUserContext user) =>
      f.staple ||
      user.recents.contains(f.id) ||
      f.interests.any(user.hasInterest);

  /// Build the view.
  ///
  /// [haystack] turns a feature into the text a query is matched against. It
  /// is passed rather than computed because the localised name belongs to the
  /// presentation layer and the matching belongs here.
  static LumeToolsView build({
    required LumeEligibility eligibility,
    required LumeUserContext user,
    required LumeToolsFilter filter,
    required String query,
    required String Function(LumeFeature) haystack,
  }) {
    final List<LumeFeature> visible = eligibility.visibleFeatures(user);
    final List<LumeCategory> categories = eligibility.visibleCategories(user);

    final List<LumeToolsFilter> chips = <LumeToolsFilter>[
      LumeToolsFilter.forYou,
      LumeToolsFilter.all,
      for (final LumeCategory c in categories) LumeToolsFilter.category(c.id),
    ];

    // The faith category can disappear underneath the chip that selected it,
    // and a filter nothing can satisfy would show an empty screen.
    final LumeToolsFilter active = chips.contains(filter)
        ? filter
        : LumeToolsFilter.forYou;

    final String q = query.trim().toLowerCase();
    final bool searching = q.isNotEmpty;
    // "For you" only narrows once the user has chosen something. Somebody who
    // has chosen nothing gets the whole catalogue rather than an empty screen.
    final bool shortlisting =
        !searching && active is LumeForYouFilter && user.interests.isNotEmpty;

    final List<LumeToolGroup> groups = <LumeToolGroup>[];
    int shown = 0;

    for (final LumeCategory c in categories) {
      final bool categoryMatches =
          searching ||
          active is LumeAllFilter ||
          shortlisting ||
          (active is LumeCategoryFilter && active.category == c.id);
      if (!categoryMatches) continue;

      final List<LumeFeature> tools = <LumeFeature>[
        for (final LumeFeature f in visible)
          if (f.category == c.id &&
              (!searching || haystack(f).contains(q)) &&
              (!shortlisting || _isShortlisted(f, user)))
            f,
      ];
      if (tools.isEmpty) continue;
      shown += tools.length;
      groups.add(LumeToolGroup(category: c, tools: tools));
    }

    return LumeToolsView(
      chips: chips,
      filter: active,
      groups: groups,
      recents: () {
        final List<LumeFeature> r = eligibility.recentFeatures(user);
        return r.length < 2 ? const <LumeFeature>[] : r;
      }(),
      catalogueCount: visible.length,
      shownCount: shown,
      empty: groups.isNotEmpty
          ? null
          // Two different kinds of nothing, and they need different words.
          : (!searching && active is LumeForYouFilter
                ? LumeToolsEmpty.shortlistEmpty
                : LumeToolsEmpty.noMatch),
    );
  }
}
