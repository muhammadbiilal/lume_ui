/// Recipes — the reference tool for the visual-library archetype.
///
/// `tools/personal/recipes.tool.js`: a search field, the cuisines as chips,
/// the reader's favourites as a strip of image cards, every recipe as a rich
/// row with its art, and two links onward. Filtering is live: the cuisine and
/// the query live in the tool session, so leaving and coming back finds the
/// library as it was left.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/widgets/lume/lume_art.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../../tools/presentation/tool_strings.dart';
import '../data/recipe_fixtures.dart';
import 'recipes_strings.dart';

class LumeRecipesTool extends ConsumerStatefulWidget {
  const LumeRecipesTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeRecipesTool(request: request);

  static const String id = 'recipes';

  static const Key searchKey = ValueKey<String>('recipes.search');
  static const Key chipsKey = ValueKey<String>('recipes.cuisines');
  static const Key favouritesKey = ValueKey<String>('recipes.favourites');
  static const Key listKey = ValueKey<String>('recipes.list');
  static const Key emptyKey = ValueKey<String>('recipes.empty');
  static const Key linksKey = ValueKey<String>('recipes.links');

  /// `['all'].concat(cuisines in order of first appearance)`.
  static List<LumeRecipeCuisine> get cuisines => <LumeRecipeCuisine>{
    for (final LumeRecipe r in kReferenceRecipes) r.cuisine,
  }.toList();

  /// The recipes a cuisine and a query leave, in library order.
  ///
  /// `(name + cuisine + tags).toLowerCase().indexOf(query)` — matched in the
  /// reader's language and in English, so "oats" finds Overnight Oats on an
  /// Urdu screen as it does on an English one (§47).
  static List<LumeRecipe> filter({
    required LumeRecipeCuisine? cuisine,
    required String query,
    required List<AppLocalizations> languages,
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeRecipe>[
      for (final LumeRecipe r in kReferenceRecipes)
        if (cuisine == null || r.cuisine == cuisine)
          if (q.isEmpty ||
              languages.any(
                (AppLocalizations l) => <String>[
                  LumeRecipesStrings.name(l, r.id),
                  LumeRecipesStrings.cuisine(l, r.cuisine),
                  for (final LumeRecipeTag t in r.tags)
                    LumeRecipesStrings.tag(l, t),
                ].join(' ').toLowerCase().contains(q),
              ))
            r,
    ];
  }

  @override
  ConsumerState<LumeRecipesTool> createState() => _LumeRecipesToolState();
}

class _LumeRecipesToolState extends ConsumerState<LumeRecipesTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeRecipesTool.id, 'q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  LumeRecipeCuisine? get _cuisine {
    final String? saved = _session.read(LumeRecipesTool.id, 'cuisine');
    for (final LumeRecipeCuisine c in LumeRecipeCuisine.values) {
      if (c.name == saved) return c;
    }
    return null;
  }

  void _setCuisine(LumeRecipeCuisine? c) => setState(
    () => _session.write(LumeRecipesTool.id, 'cuisine', c?.name ?? 'all'),
  );

  void _search(String q) =>
      setState(() => _session.write(LumeRecipesTool.id, 'q', q));

  /// `toast:<name>` — the reference opens nothing yet; it names the recipe.
  /// **Dayroz:** open the recipe — its ingredients and method, from the owned
  /// library `recipe_fixtures.dart` asks for.
  void _open(AppLocalizations l, LumeRecipe r) =>
      _host.currentState?.say(LumeRecipesStrings.name(l, r.id));

  /// The library as the screen shows it (C68): how many recipes, and which
  /// are the reader's favourites. The reference shares an unrelated quote.
  LumeShareCard? _shareCard(AppLocalizations l) {
    final List<String> favourites = <String>[
      for (final LumeRecipe r in kReferenceRecipes)
        if (r.favourite) LumeRecipesStrings.name(l, r.id),
    ];
    return LumeShareCard.forFeature(
      sensitive: widget.request.feature.sensitive,
      kind: LumeShareKind.quote,
      text: l.recipesShareText(kReferenceRecipes.length, favourites.join(', ')),
      source: LumeToolStrings.source(l, widget.request.feature),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    final LumeRecipeCuisine? cuisine = _cuisine;
    final List<LumeRecipe> list = LumeRecipesTool.filter(
      cuisine: cuisine,
      query: _query.text,
      languages: <AppLocalizations>{
        l,
        lookupAppLocalizations(const Locale('en')),
      }.toList(),
    );

    String minutes(int n) => l.unitMinutesCount(f.integer(n));

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // `toolsearch:recipes` — the tool bar's Search focuses this field.
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      shareCard: () => _shareCard(l),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // `.tsearch .search { margin: 0 var(--pad) }` inside a section that
          // already has its gutter — the field sits a second gutter in (C69).
          LumeToolSection(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: LumeSearchField(
                key: LumeRecipesTool.searchKey,
                controller: _query,
                focusNode: _searchFocus,
                placeholder: l.recipesSearch,
                onChanged: _search,
              ),
            ),
          ),
          LumeToolSection(
            flush: true,
            child: LumeHorizontalStrip.chips(
              key: LumeRecipesTool.chipsKey,
              children: <Widget>[
                LumeChoiceChip(
                  label: l.commonAll,
                  selected: cuisine == null,
                  onTap: () => _setCuisine(null),
                ),
                for (final LumeRecipeCuisine c in LumeRecipesTool.cuisines)
                  LumeChoiceChip(
                    label: LumeRecipesStrings.cuisine(l, c),
                    selected: cuisine == c,
                    onTap: () => _setCuisine(c),
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.recipesFavourites,
            flush: true,
            child: LumeHorizontalStrip(
              key: LumeRecipesTool.favouritesKey,
              gap: 11,
              padding: const EdgeInsets.only(bottom: 4),
              bleed: true,
              children: <Widget>[
                for (final LumeRecipe x in kReferenceRecipes)
                  if (x.favourite)
                    LumeImageCard(
                      tone: x.tone,
                      seed: x.seed,
                      glyph: x.glyph,
                      kicker: LumeRecipesStrings.cuisine(l, x.cuisine),
                      title: LumeRecipesStrings.name(l, x.id),
                      meta:
                          '${minutes(x.minutes)} · ${l.recipesServes(x.serves)}',
                      onTap: () => _open(l, x),
                    ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.recipesAll,
            child: list.isEmpty
                ? LumeToolState(
                    key: LumeRecipesTool.emptyKey,
                    icon: LumeIcons.utensils,
                    title: l.recipesNoMatch,
                    text: l.recipesNoMatchText,
                  )
                : LumeRows(
                    key: LumeRecipesTool.listKey,
                    children: <Widget>[
                      for (final LumeRecipe x in list)
                        LumeRichRow(
                          thumb: LumeArt(
                            tone: x.tone,
                            seed: x.seed,
                            glyph: x.glyph,
                          ),
                          title: LumeRecipesStrings.name(l, x.id),
                          subtitle: LumeRecipesStrings.cuisine(l, x.cuisine),
                          meta: <String>[
                            l.recipesPrepCook(
                              f.integer(x.prep),
                              f.integer(x.cook),
                            ),
                            l.recipesServes(x.serves),
                            l.unitKcalCount(f.integer(x.kcal)),
                            l.recipesSteps(x.steps),
                            l.recipesIngredients(x.ingredients),
                            <String>[
                              for (final LumeRecipeTag t in x.tags)
                                LumeRecipesStrings.tag(l, t),
                            ].join(' · '),
                          ],
                          badge: x.favourite
                              ? LumeBadge(
                                  label: l.commonSaved,
                                  tone: LumeBadgeTone.ok,
                                )
                              : null,
                          chevron: true,
                          onTap: () => _open(l, x),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.recipesRelated,
            child: LumeRows(
              key: LumeRecipesTool.linksKey,
              children: <Widget>[
                LumeCompactRow(
                  icon: LumeIcons.calendar,
                  label: LumeFeatureStrings.name(l, 'mealplan'),
                  onTap: () => r.onOpenRelated?.call('mealplan'),
                ),
                LumeCompactRow(
                  icon: LumeIcons.cart,
                  label: LumeFeatureStrings.name(l, 'shopping'),
                  onTap: () => r.onOpenRelated?.call('shopping'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
