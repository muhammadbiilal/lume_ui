/// The Tools hub.
///
/// One searchable catalogue of every utility this user can actually reach.
/// Which tools those are is not decided here: the screen asks the same
/// [LumeEligibility] every other surface asks, so a hidden feature cannot
/// reappear through the catalogue, its category counts, its search or its
/// recents (§64).
///
/// Five blocks, in order:
///
/// 1. the page head — "Tools", the count, and Personalise
/// 2. the search field
/// 3. the category chips
/// 4. "Recently used" — hidden below two
/// 5. the catalogue, or one of the two empty states
///
/// The count in the heading is the count of what is *reachable*, so it agrees
/// with the catalogue below it in every market. The count on a category head is
/// the count of what is *shown*, which is a different number the moment a chip
/// or a query narrows the view — and conflating the two is the defect the
/// registry tests exist to catch.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../home/domain/home_repository.dart';
import '../domain/tools_filter.dart';
import 'tools_art.dart';

/// What the hub does when something is tapped.
@immutable
class LumeToolsActions {
  const LumeToolsActions({
    required this.openTool,
    required this.openPersonalise,
  });

  final void Function(String featureId) openTool;
  final VoidCallback openPersonalise;
}

/// The screen.
class LumeToolsScreen extends StatefulWidget {
  const LumeToolsScreen({
    super.key,
    required this.eligibility,
    required this.user,
    required this.actions,
    this.attention = const <String, int>{},
    this.live = LumeToolStatuses.none,
    this.initialFilter = LumeToolsFilter.forYou,
    this.initialQuery = '',
  });

  final LumeEligibility eligibility;
  final LumeUserContext user;
  final LumeToolsActions actions;

  /// How many things a tool needs attention for. Only the tools that can
  /// honestly report one appear here — `badgeCount` in the reference, which
  /// answers for bills and documents and nothing else.
  final Map<String, int> attention;

  /// The handful of status lines the device can answer live. Home reads the
  /// same ones, so a tile cannot name one prayer here and another there.
  final LumeToolStatuses live;

  final LumeToolsFilter initialFilter;
  final String initialQuery;

  /// Keys the tests and the bounds comparison address elements by.
  static const String headKey = 'tools.head';
  static const String searchKey = 'tools.search';
  static const String chipsKey = 'tools.chips';
  static const String recentsKey = 'tools.recents';
  static const String catalogueKey = 'tools.catalogue';
  static const String emptyKey = 'tools.empty';

  @override
  State<LumeToolsScreen> createState() => _LumeToolsScreenState();
}

class _LumeToolsScreenState extends State<LumeToolsScreen> {
  late LumeToolsFilter _filter = widget.initialFilter;
  late final TextEditingController _query = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: widget.user.country,
    );

    final LumeToolsView view = LumeToolsQuery.build(
      eligibility: widget.eligibility,
      user: widget.user,
      filter: _filter,
      query: _query.text,
      haystack: (LumeFeature f) => LumeFeatureStrings.haystack(l, f),
    );

    return LumeDestinationPage(
      storageId: 'tools',
      semanticLabel: l.navTools,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: const ValueKey<String>(LumeToolsScreen.headKey),
            child: LumePageHead(
              title: l.toolsTitle,
              subtitle: l.toolsSub(view.catalogueCount),
              action: LumeHeaderButton(
                icon: LumeIcons.sliders,
                semanticLabel: l.toolsPersonalise,
                onTap: widget.actions.openPersonalise,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: const ValueKey<String>(LumeToolsScreen.searchKey),
            child: LumePageSection(
              topGap: LumeSpace.x4,
              child: LumeMeasure(
                child: LumeSearchField(
                  controller: _query,
                  placeholder: l.toolsSearchHint(
                    widget.user.country == 'PK'
                        ? l.toolsSearchExamplePk
                        : l.toolsSearchExample,
                  ),
                  semanticLabel: l.toolsSearchLabel,
                  onChanged: (_) => setState(() {}),
                  onClear: () => setState(_query.clear),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: const ValueKey<String>(LumeToolsScreen.chipsKey),
            child: LumePageSection(
              topGap: 14,
              child: LumeHorizontalStrip.chips(
                semanticLabel: l.toolsTitle,
                children: <Widget>[
                  for (final LumeToolsFilter chip in view.chips)
                    LumeChoiceChip(
                      key: ValueKey<String>('tools.chip.${chip.id}'),
                      label: _chipLabel(l, chip),
                      selected: chip == view.filter,
                      icon: chip is LumeForYouFilter
                          ? LumeIcons.sparkles
                          : null,
                      onTap: () => setState(() => _filter = chip),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Opening a tool anywhere in the app writes it to recents, and every
        // arrival on this screen re-reads it — being shown is the notification.
        if (view.recents.isNotEmpty)
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: const ValueKey<String>(LumeToolsScreen.recentsKey),
              child: LumePageSection(
                title: l.toolsRecent,
                subtitle: l.toolsRecentSub,
                child: LumeHorizontalStrip(
                  padding: const EdgeInsets.only(bottom: 6),
                  children: <Widget>[
                    for (final LumeFeature f in view.recents)
                      LumeRecentPill(
                        key: ValueKey<String>('tools.recent.${f.id}'),
                        icon: f.icon,
                        label: LumeFeatureStrings.name(l, f.id),
                        onTap: () => widget.actions.openTool(f.id),
                      ),
                  ],
                ),
              ),
            ),
          ),

        if (view.empty == null)
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: const ValueKey<String>(LumeToolsScreen.catalogueKey),
              child: Semantics(
                container: true,
                label: l.toolsResultCount(view.shownCount),
                child: Column(
                  children: <Widget>[
                    for (final LumeToolGroup g in view.groups)
                      _group(context, l, f, g),
                  ],
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: const ValueKey<String>(LumeToolsScreen.emptyKey),
              child: Padding(
                padding: const EdgeInsets.only(top: LumeSpace.x6),
                child: LumeEmptyState(
                  art: const LumeToolsEmptyArt(),
                  title: view.empty == LumeToolsEmpty.noMatch
                      ? l.toolsNoMatch
                      : l.toolsNothingYet,
                  text: view.empty == LumeToolsEmpty.noMatch
                      ? l.toolsNoMatchSub
                      : l.toolsNothingYetSub,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _chipLabel(AppLocalizations l, LumeToolsFilter chip) => switch (chip) {
    LumeForYouFilter() => l.toolsForYou,
    LumeAllFilter() => l.actionAll,
    LumeCategoryFilter(:final LumeToolCategory category) =>
      LumeFeatureStrings.category(l, category),
  };

  /// One category: its heading, then its grid.
  ///
  /// `.cat { margin-top: 24px }` and `.cat__head { margin-bottom: 12px }` —
  /// twelve, which is one less than a `.section__head`'s thirteen.
  Widget _group(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeToolGroup g,
  ) => Padding(
    // `.cat { margin-top: 24px }` is the page's gap, so the keyed block is the
    // category itself and a measurement of it is a measurement of `.cat`.
    padding: const EdgeInsets.only(top: LumeSpace.gapSection),
    child: Column(
      key: ValueKey<String>('tools.cat.${g.category.id.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LumeMeasure(
          child: Padding(
            padding: const EdgeInsets.only(bottom: LumeSpace.x3),
            child: LumeCategoryHeading(
              icon: g.category.icon,
              title: LumeFeatureStrings.category(l, g.category.id),
              subtitle: LumeFeatureStrings.categorySub(l, g.category.id),
              // The count of what is *shown*, which a chip or a query
              // changes; the heading above carries the catalogue's.
              count: '${g.tools.length}',
              accent: g.category.faith,
            ),
          ),
        ),
        LumeMeasure(
          child: LumeTileGrid(
            columns: _columns(context),
            children: <Widget>[
              for (final LumeFeature t in g.tools)
                _tile(context, l, f, t, g.category),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tile(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeFeature t,
    LumeCategory category,
  ) {
    final int count = widget.attention[t.id] ?? 0;

    // One corner, three possible markers, so the precedence is declared.
    // Privacy wins over a number: a lock is a promise, and a count is
    // information that can wait for the tool itself.
    final (LumeTileMarker marker, String? label) = t.sensitive
        ? (LumeTileMarker.private, l.toolPrivate)
        : count > 0
        ? (LumeTileMarker.count, l.toolNeedsAttention(count))
        : t.isCountryRestricted
        ? (LumeTileMarker.local, l.toolLocalService)
        : (LumeTileMarker.none, null);

    return LumeCatalogueTile(
      key: ValueKey<String>('tools.tile.${t.id}'),
      icon: t.icon,
      label: LumeFeatureStrings.name(l, t.id),
      status: LumeFeatureStrings.tileStatus(l, f, t.id, widget.live),
      marker: marker,
      count: count,
      markerLabel: label,
      accent: category.faith,
      onTap: () => widget.actions.openTool(t.id),
    );
  }

  /// `.cat-grid { grid-template-columns: repeat(3, 1fr) }`, two below 360, and
  /// more once the page is wider than a phone.
  static int _columns(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 2;
    return switch (context.measureClass) {
      LumeWidthClass.compact => 3,
      LumeWidthClass.medium => 4,
      LumeWidthClass.expanded => 5,
    };
  }
}
