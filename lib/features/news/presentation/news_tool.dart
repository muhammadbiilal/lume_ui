/// News — the reference tool for the editorial-reader archetype.
///
/// `tools/daily/news.tool.js`: the edition, a search field, the categories,
/// the top story, the latest, and the reader's own reading. The category and
/// the query live in the tool session.
///
/// Two reference behaviours are kept as written (C70): "Top" is every story,
/// not the stories filed under Top; and a search that finds nothing is told
/// "Nothing in this category yet", the category's own sentence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/widgets/lume/lume_art.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_lead_card.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/news_fixtures.dart';
import 'news_strings.dart';

class LumeNewsTool extends ConsumerStatefulWidget {
  const LumeNewsTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) => LumeNewsTool(request: request);

  static const String id = 'news';

  static const Key searchKey = ValueKey<String>('news.search');
  static const Key chipsKey = ValueKey<String>('news.categories');
  static const Key leadKey = ValueKey<String>('news.lead');
  static const Key listKey = ValueKey<String>('news.latest');
  static const Key emptyKey = ValueKey<String>('news.empty');
  static const Key readingKey = ValueKey<String>('news.reading');

  /// `news.savedCount` and `news.sourcesValue` — the reference's own figures.
  static const int savedStories = 4;
  static const int followedSources = 8;

  /// What a category and a query leave, in edition order.
  ///
  /// `(title + src + cat).toLowerCase().indexOf(query)`, matched in the
  /// reader's language and in English (§47).
  static List<LumeNewsStory> filter(
    List<LumeNewsStory> edition, {
    required LumeNewsCategory category,
    required String query,
    required List<AppLocalizations> languages,
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeNewsStory>[
      for (final LumeNewsStory s in edition)
        if (category == LumeNewsCategory.top || s.category == category)
          if (q.isEmpty ||
              languages.any(
                (AppLocalizations l) => <String>[
                  LumeNewsStrings.headline(l, s.id),
                  s.publisher,
                  LumeNewsStrings.category(l, s.category),
                ].join(' ').toLowerCase().contains(q),
              ))
            s,
    ];
  }

  /// `seed: title.length` — the English headline's length, so the art does
  /// not change with the reader's language.
  static int seed(LumeNewsStory s) => LumeNewsStrings.headline(
    lookupAppLocalizations(const Locale('en')),
    s.id,
  ).length;

  @override
  ConsumerState<LumeNewsTool> createState() => _LumeNewsToolState();
}

class _LumeNewsToolState extends ConsumerState<LumeNewsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeNewsTool.id, 'q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  LumeNewsCategory get _category {
    final String? saved = _session.read(LumeNewsTool.id, 'cat');
    for (final LumeNewsCategory c in LumeNewsCategory.values) {
      if (c.name == saved) return c;
    }
    return LumeNewsCategory.top;
  }

  void _setCategory(LumeNewsCategory c) =>
      setState(() => _session.write(LumeNewsTool.id, 'cat', c.name));

  void _search(String q) =>
      setState(() => _session.write(LumeNewsTool.id, 'q', q));

  void _say(String message) => _host.currentState?.say(message);

  String _meta(AppLocalizations l, LumeNewsStory s) =>
      '${s.publisher} · ${LumeNewsStrings.ago(l, s.minutesAgo)} · '
      '${l.newsReadTime(s.minutes)}';

  /// The top story, as the screen shows it. The reference shares an
  /// unrelated quote (C68); with no top story there is nothing to share.
  LumeShareCard? _shareCard(AppLocalizations l, LumeNewsStory? lead) =>
      lead == null
      ? null
      : LumeShareCard.forFeature(
          sensitive: widget.request.feature.sensitive,
          kind: LumeShareKind.quote,
          text: LumeNewsStrings.headline(l, lead.id),
          source: l.newsShareSource(
            lead.publisher,
            LumeNewsStrings.ago(l, lead.minutesAgo),
          ),
        );

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    final LumeNewsCategory category = _category;
    final List<LumeNewsStory> list = LumeNewsTool.filter(
      LumeNewsEditions.forCountry(r.user.country),
      category: category,
      query: _query.text,
      languages: <AppLocalizations>{
        l,
        lookupAppLocalizations(const Locale('en')),
      }.toList(),
    );
    final LumeNewsStory? lead = list.isEmpty ? null : list.first;
    final List<LumeNewsStory> rest = list.skip(1).toList();

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      shareCard: () => _shareCard(l, lead),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              items: <LumeContextItem>[
                LumeContextItem(
                  label: LumeToolScreen.countryName(
                    context,
                    ref,
                    r.user.country,
                  ),
                  icon: LumeIcons.globe,
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: l.newsEdition),
              ],
            ),
          ),
          // The same second gutter as Recipes' field (C69).
          LumeToolSection(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: LumeSearchField(
                key: LumeNewsTool.searchKey,
                controller: _query,
                focusNode: _searchFocus,
                placeholder: l.newsSearch,
                onChanged: _search,
              ),
            ),
          ),
          LumeToolSection(
            flush: true,
            child: LumeHorizontalStrip.chips(
              key: LumeNewsTool.chipsKey,
              children: <Widget>[
                for (final LumeNewsCategory c in LumeNewsCategory.values)
                  LumeChoiceChip(
                    label: LumeNewsStrings.category(l, c),
                    selected: category == c,
                    onTap: () => _setCategory(c),
                  ),
              ],
            ),
          ),
          if (lead != null)
            LumeToolSection(
              title: l.newsTop,
              child: LumeLeadCard(
                key: LumeNewsTool.leadKey,
                tone: lead.tone,
                seed: LumeNewsTool.seed(lead),
                category: LumeNewsStrings.category(l, lead.category),
                title: LumeNewsStrings.headline(l, lead.id),
                meta: _meta(l, lead),
                onTap: () => _say(LumeNewsStrings.headline(l, lead.id)),
              ),
            ),
          LumeToolSection(
            title: l.newsLatest,
            child: rest.isEmpty
                ? LumeToolState(
                    key: LumeNewsTool.emptyKey,
                    icon: LumeIcons.news,
                    title: l.newsEmptyTitle,
                    text: l.newsEmptyText,
                  )
                : LumeRows(
                    key: LumeNewsTool.listKey,
                    children: <Widget>[
                      for (final LumeNewsStory s in rest)
                        LumeRichRow(
                          thumb: LumeArt(
                            tone: s.tone,
                            seed: LumeNewsTool.seed(s) + s.minutes,
                          ),
                          title: LumeNewsStrings.headline(l, s.id),
                          subtitle: s.publisher,
                          meta: <String>[
                            LumeNewsStrings.category(l, s.category),
                            LumeNewsStrings.ago(l, s.minutesAgo),
                            l.newsReadTime(s.minutes),
                          ],
                          chevron: true,
                          onTap: () => _say(LumeNewsStrings.headline(l, s.id)),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.newsSaved,
            child: LumeRows(
              key: LumeNewsTool.readingKey,
              children: <Widget>[
                LumeCompactRow(
                  icon: LumeIcons.bookmark,
                  label: l.newsSavedCount(LumeNewsTool.savedStories),
                  // The reference's own toast. **Dayroz:** open the
                  // reader's saved stories.
                  onTap: () => _say(l.newsSavedOpen),
                ),
                LumeCompactRow(
                  icon: LumeIcons.sliders,
                  label: l.newsSources,
                  value: l.newsSourcesValue(
                    f.integer(LumeNewsTool.followedSources),
                  ),
                  onTap: () => _say(l.newsSourcesEdit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
