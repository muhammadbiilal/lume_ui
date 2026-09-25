/// Search the Qur'an — a search over what this build actually holds.
///
/// `tools/islamic/quransearch.tool.js` and its `c.quranSearch()`: with
/// nothing typed, the three ayat; with a query, every ayah whose translation
/// or surah name matches, then every surah whose name or meaning matches.
/// The reference draws a scope filter bar (all/Arabic/translation) and a
/// revealed-in filter bar (Meccan/Medinan) alongside the results, but neither
/// one is wired to `quranSearch` at all — pressing them changes nothing the
/// reference computes. A control that cannot do what it looks like it does is
/// not reproduced here (the same rule the tool frame states for its own
/// header actions); this screen searches, and says plainly, near the results,
/// how much it is searching.
///
/// Not faith-gated for sharing (the catalogue gives this tool no
/// `shareable`): there is no card to hand over, only a place to look.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/quran_fixtures.dart';
import '../domain/quran_model.dart';

class LumeQuranSearchTool extends ConsumerStatefulWidget {
  const LumeQuranSearchTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeQuranSearchTool(request: request);

  static const String id = 'quransearch';

  static const Key searchKey = ValueKey<String>('quransearch.search');
  static const Key resultsKey = ValueKey<String>('quransearch.results');
  static const Key emptyKey = ValueKey<String>('quransearch.empty');
  static const Key suggestedKey = ValueKey<String>('quransearch.suggested');
  static const Key scopeNoteKey = ValueKey<String>('quransearch.scopenote');

  @override
  ConsumerState<LumeQuranSearchTool> createState() =>
      _LumeQuranSearchToolState();
}

class _LumeQuranSearchToolState extends ConsumerState<LumeQuranSearchTool> {
  static const String _id = LumeQuranSearchTool.id;

  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(_id, 'q') ?? '',
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    setState(() {
      _query.text = q;
      _query.selection = TextSelection.collapsed(offset: q.length);
      _session.write(_id, 'q', q);
    });
  }

  String _place(AppLocalizations l, LumeSurahPlace p) => switch (p) {
    LumeSurahPlace.meccan => l.quranMeccan,
    LumeSurahPlace.medinan => l.quranMedinan,
  };

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
    final List<LumeQuranSearchHit> results = LumeQuranFixtures.search(
      _query.text,
    );

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                LumeSearchField(
                  key: LumeQuranSearchTool.searchKey,
                  controller: _query,
                  placeholder: l.quransearchPlaceholder,
                  onChanged: (String q) =>
                      setState(() => _session.write(_id, 'q', q)),
                ),
                const SizedBox(height: 8),
                // Honest, not an overclaim: three ayat and twelve surahs are
                // what this build actually searches, and the reader is told
                // so beside the results rather than left to assume a full
                // mushaf sits behind this box.
                Text(
                  l.quransearchScopeNote,
                  key: LumeQuranSearchTool.scopeNoteKey,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: lume.text3),
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: results.isEmpty
                ? null
                : l.quransearchResultsTitle(results.length),
            child: results.isEmpty
                ? LumeToolState(
                    key: LumeQuranSearchTool.emptyKey,
                    icon: LumeIcons.search,
                    title: l.quransearchEmptyTitle,
                    text: l.quransearchEmptyText,
                  )
                : LumeRows(
                    key: LumeQuranSearchTool.resultsKey,
                    children: <Widget>[
                      for (final LumeQuranSearchHit hit in results)
                        LumeRichRow(
                          logo: '${hit.surahNumber}:${hit.ayahNumber}',
                          title: hit.surahName,
                          subtitle: hit.text,
                          meta: <String>[
                            l.quranAyahNumber(hit.ayahNumber),
                            if (hit.place != null) _place(l, hit.place!),
                          ],
                          chevron: true,
                          onTap: () => r.onOpenRelated?.call('quran'),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.quransearchSuggestedTitle,
            flush: true,
            child: LumeFilterBar(
              key: LumeQuranSearchTool.suggestedKey,
              children: <Widget>[
                for (final String s in LumeQuranFixtures.suggestedSearches)
                  LumeFilterChip(label: s, onTap: () => _setQuery(s)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
