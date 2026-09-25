/// Daily Duas — the reference tool for a scripture library with a real
/// original (F6B, following Hadith's F6A-D5 reader).
///
/// `tools/islamic/duas.tool.js`: the day's dua to read and share, a search, the
/// categories as tiles with their own (real, computed) counts, and every dua
/// filtered by category and query. The tool is faith-gated in the catalogue,
/// so a reader who has not turned the Islamic experience on never reaches it
/// (the gate, not this screen, decides).
///
/// The reference draws its categories as tiles holding an inflated,
/// hand-written count (`DUA_CATEGORIES[].n`); its own `build()` never reads
/// that figure, computing the real one from `DUAS` itself instead (see
/// `duas_model.dart`). This build keeps the reference's live behaviour — the
/// computed count — over its dead, inflated one, drawn as filter chips the
/// way Hadith's collections are, rather than as tiles: the reference's own
/// tile and Hadith's own filter chip carry the same two facts, a label and a
/// count, and this build already has one component for that shape.
///
/// The reference's row action shares a *different*, disconnected fixed dua
/// (`SHARE_CONTENT.duas`, cited "Al-Baqarah 2:201" — not one of the five in
/// `DUAS` at all) rather than the dua the row is showing. Corrected here the
/// same way Hadith's Share was (C68): a row opens the dua actually being
/// looked at, in a detail sheet, whose own Share hands over that dua.
///
/// A dua's Arabic, its rendering into English and its citation are kept as
/// the reference gives them in every language; the interface around them is
/// translated (C77). Arabic renders right to left because
/// `LumeResolvedPassage.language` says so, never because the interface does
/// (C82).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_reader.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../hadith/domain/religious_content.dart';
import '../../share/presentation/share_sheet.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/duas_fixtures.dart';
import '../domain/duas_model.dart';
import 'duas_text.dart';

class LumeDuasTool extends ConsumerStatefulWidget {
  const LumeDuasTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) => LumeDuasTool(request: request);

  static const String id = 'duas';

  static const Key readerKey = ValueKey<String>('duas.reader');
  static const Key shareKey = ValueKey<String>('duas.share');
  static const Key listenKey = ValueKey<String>('duas.listen');
  static const Key searchKey = ValueKey<String>('duas.search');
  static const Key filterKey = ValueKey<String>('duas.filter');
  static const Key browseKey = ValueKey<String>('duas.browse');
  static const Key emptyKey = ValueKey<String>('duas.empty');
  static const Key detailKey = ValueKey<String>('duas.detail');
  static const Key detailShareKey = ValueKey<String>('duas.detail.share');

  @override
  ConsumerState<LumeDuasTool> createState() => _LumeDuasToolState();
}

class _LumeDuasToolState extends ConsumerState<LumeDuasTool> {
  static const String _id = LumeDuasTool.id;

  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(_id, 'q') ?? '',
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String? _read(String k) => _session.read(_id, k);
  void _write(String k, String v) => _session.write(_id, k, v);

  LumeDuaCategory? get _category {
    final String saved = _read('category') ?? 'all';
    for (final LumeDuaCategory c in LumeDuaCategory.values) {
      if (c.name == saved) return c;
    }
    return null;
  }

  /// The card this dua shares (C77, C68): the dua actually shown, never the
  /// reference's disconnected fixed one.
  LumeShareCard? _shareCard(
    AppLocalizations l,
    LumeDua d,
    LumeResolvedPassage passage,
  ) => LumeShareCard.forFeature(
    sensitive: widget.request.feature.sensitive,
    kind: LumeShareKind.dua,
    text: passage.text,
    source: d.citation,
    arabic: passage.language == LumeContentLanguage.arabic ? null : d.arabic,
  );

  Future<void> _openDetail(
    BuildContext context,
    AppLocalizations l,
    LumeDua d,
  ) async {
    final LumeContentLanguage lang = LumeContentLanguage(
      Localizations.localeOf(context).languageCode,
    );
    final LumeResolvedPassage passage = d.record.resolve(lang)!;

    await showLumeSheet<void>(
      context: context,
      barrierLabel: l.actionClose,
      child: LumeSheet(
        title: LumeDuasStrings.title(l, d.id),
        subtitle: LumeDuasStrings.category(l, d.category),
        onClose: () => Navigator.of(context).pop(),
        closeLabel: l.actionClose,
        child: SingleChildScrollView(
          child: LumeReaderCard(
            key: LumeDuasTool.detailKey,
            reference: d.citation,
            body: passage.text,
            bodyDirection: passage.language.isRightToLeft
                ? TextDirection.rtl
                : TextDirection.ltr,
            bodyLocale: passage.language.locale,
            note: passage.isFallback ? l.readerFallbackEnglish : null,
            actions: <Widget>[
              LumeButton.accent(
                key: LumeDuasTool.detailShareKey,
                label: l.commonShare,
                icon: LumeIcons.share,
                onPressed: () {
                  final LumeShareCard? card = _shareCard(l, d, passage);
                  if (card == null) return;
                  showLumeShareSheet(context: context, card: card);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final DateTime now = LumeClockScope.of(context).now();
    final LumeDua day = LumeDuaFixtures.of(now);
    final LumeContentLanguage lang = LumeContentLanguage(
      Localizations.localeOf(context).languageCode,
    );
    // The passage in the reader's language only if a verified one exists —
    // the real Arabic for an Arabic reader, otherwise the reference's
    // English, labelled when it stands in for the reader's own (C82).
    final LumeResolvedPassage passage = day.record.resolve(lang)!;
    final double gutter = LumeLayout.pageGutter(context.measureClass);

    final LumeDuaCategory? category = _category;
    final List<LumeDua> shown = LumeDuaFixtures.shown(
      category: category,
      query: _query.text,
    );

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // Shares the dua actually shown above, never the reference's
      // disconnected fixed card (C68, C77).
      shareCard: () => _shareCard(l, day, passage),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeReaderCard(
              key: LumeDuasTool.readerKey,
              reference: '${l.duasToday} · ${LumeDuasStrings.title(l, day.id)}',
              body: passage.text,
              bodyDirection: passage.language.isRightToLeft
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              bodyLocale: passage.language.locale,
              note: passage.isFallback ? l.readerFallbackEnglish : null,
              byline: day.citation,
              actions: <Widget>[
                LumeButton.accent(
                  key: LumeDuasTool.shareKey,
                  label: l.commonShare,
                  icon: LumeIcons.share,
                  onPressed: () {
                    final LumeShareCard? card = _shareCard(l, day, passage);
                    if (card == null) return;
                    showLumeShareSheet(context: context, card: card);
                  },
                ),
                LumeButton(
                  key: LumeDuasTool.listenKey,
                  label: l.readerListen,
                  icon: LumeIcons.play,
                  // The reference's Listen plays nothing either — it only
                  // toasts. Reproduced as the same live-but-inert control.
                  onPressed: () => showLumeToast(
                    context,
                    LumeToastData(message: l.readerPlaying),
                  ),
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: LumeSearchField(
                key: LumeDuasTool.searchKey,
                controller: _query,
                placeholder: l.duasSearch,
                onChanged: (String q) => setState(() => _write('q', q)),
              ),
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            title: l.duasCategories,
            child: LumeFilterBar(
              key: LumeDuasTool.filterKey,
              gutters: false,
              children: <Widget>[
                LumeFilterChip(
                  label: l.commonAll,
                  selected: category == null,
                  onTap: () => setState(() => _write('category', 'all')),
                ),
                for (final LumeDuaCategory c in LumeDuaCategory.values)
                  LumeFilterChip(
                    label: LumeDuasStrings.category(l, c),
                    count: LumeDuaFixtures.countOf(c),
                    selected: category == c,
                    onTap: () => setState(() => _write('category', c.name)),
                  ),
              ],
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            title: category == null
                ? l.duasAll
                : l.duasInCategory(LumeDuasStrings.category(l, category)),
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeDuasTool.emptyKey,
                    icon: LumeIcons.heart,
                    title: l.duasNoMatch,
                    text: l.duasNoMatchText,
                    action: LumeButton(
                      label: l.commonAll,
                      icon: LumeIcons.refresh,
                      onPressed: () =>
                          setState(() => _write('category', 'all')),
                    ),
                  )
                : LumeRows(
                    key: LumeDuasTool.browseKey,
                    children: <Widget>[
                      for (final LumeDua d in shown)
                        LumeRichRow(
                          icon: LumeIcons.heart,
                          title: LumeDuasStrings.title(l, d.id),
                          subtitle: d.record.resolve(lang)!.text,
                          meta: <String>[
                            d.citation,
                            LumeDuasStrings.category(l, d.category),
                          ],
                          chevron: true,
                          onTap: () => _openDetail(context, l, d),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
