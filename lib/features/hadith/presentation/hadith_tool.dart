/// Hadith — the reference tool for scripture readers (F6A-D5).
///
/// `tools/islamic/hadith.tool.js`: the day's hadith to read, share and keep,
/// then a search, the collections, and every hadith to browse. The tool is
/// faith-gated in the catalogue, so a reader who has not turned the Islamic
/// experience on never reaches it (the gate, not this screen, decides).
///
/// A hadith's words, narrator and collection are kept as the reference gives
/// them in every language; the interface around them is translated (C77).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_reader.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/hadith_fixtures.dart';

class LumeHadithTool extends ConsumerStatefulWidget {
  const LumeHadithTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeHadithTool(request: request);

  static const String id = 'hadith';

  static const Key readerKey = ValueKey<String>('hadith.reader');
  static const Key shareKey = ValueKey<String>('hadith.share');
  static const Key saveKey = ValueKey<String>('hadith.save');
  static const Key searchKey = ValueKey<String>('hadith.search');
  static const Key filterKey = ValueKey<String>('hadith.filter');
  static const Key browseKey = ValueKey<String>('hadith.browse');
  static const Key emptyKey = ValueKey<String>('hadith.empty');

  @override
  ConsumerState<LumeHadithTool> createState() => _LumeHadithToolState();
}

class _LumeHadithToolState extends ConsumerState<LumeHadithTool> {
  static const String _id = LumeHadithTool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
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

  String _grade(AppLocalizations l, LumeHadithGrade g) => switch (g) {
    LumeHadithGrade.sahih => l.hadithGradeSahih,
    LumeHadithGrade.hasan => l.hadithGradeHasan,
  };

  LumeBadge _badge(AppLocalizations l, LumeHadithGrade g) => LumeBadge(
    label: _grade(l, g),
    tone: g == LumeHadithGrade.sahih ? LumeBadgeTone.ok : LumeBadgeTone.info,
  );

  String _ref(AppLocalizations l, LumeHadith h) =>
      l.hadithReference(h.source, h.number);

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final DateTime now = LumeClockScope.of(context).now();
    final LumeHadith day = LumeHadithFixtures.of(now);
    final String dayId = '${day.source} ${day.number}';
    final bool saved = _read('saved') == dayId;
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    // The reference's words are English in every language: in a
    // right-to-left interface they still read from the left.
    const TextDirection passage = TextDirection.ltr;

    final String chosen = _read('collection') ?? 'all';
    final LumeHadithCollection? collection = LumeHadithCollection.values
        .where((LumeHadithCollection c) => c.name == chosen)
        .firstOrNull;
    final List<LumeHadith> shown = LumeHadithFixtures.shown(
      collection: collection,
      query: _query.text,
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // The reference shares a fixed hadith whatever is on screen; this
      // shares the one being read (C77).
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.hadith,
        text: day.text,
        source: dayId,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeReaderCard(
              key: LumeHadithTool.readerKey,
              reference: _ref(l, day),
              body: day.text,
              bodyDirection: passage,
              byline: l.hadithNarratedBy(day.narrator),
              badge: _badge(l, day.grade),
              actions: <Widget>[
                LumeButton.accent(
                  key: LumeHadithTool.shareKey,
                  label: l.commonShare,
                  icon: LumeIcons.share,
                  onPressed: () => _host.currentState?.share(),
                ),
                LumeButton(
                  key: LumeHadithTool.saveKey,
                  label: saved ? l.hadithSavedLabel : l.commonSave,
                  icon: LumeIcons.bookmark,
                  // The reference's Save does nothing; this keeps the day's
                  // hadith for the session and says so (C77).
                  onPressed: () {
                    setState(() => _write('saved', saved ? '' : dayId));
                    _host.currentState?.say(
                      saved ? l.hadithUnsaved : l.hadithSaved,
                    );
                  },
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: LumeSearchField(
                key: LumeHadithTool.searchKey,
                controller: _query,
                placeholder: l.hadithSearch,
                onChanged: (String q) => setState(() => _write('q', q)),
              ),
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            child: LumeFilterBar(
              key: LumeHadithTool.filterKey,
              gutters: false,
              children: <Widget>[
                LumeFilterChip(
                  label: l.commonAll,
                  selected: collection == null,
                  onTap: () => setState(() => _write('collection', 'all')),
                ),
                for (final LumeHadithCollection c
                    in LumeHadithCollection.values)
                  LumeFilterChip(
                    label: c.label,
                    count: c.count,
                    selected: collection == c,
                    onTap: () => setState(() => _write('collection', c.name)),
                  ),
              ],
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            title: l.hadithBrowse,
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeHadithTool.emptyKey,
                    icon: LumeIcons.quote,
                    title: l.hadithNoMatch,
                    text: l.hadithNoMatchText,
                    action: LumeButton(
                      label: l.commonAll,
                      icon: LumeIcons.refresh,
                      onPressed: () =>
                          setState(() => _write('collection', 'all')),
                    ),
                  )
                : LumeRows(
                    key: LumeHadithTool.browseKey,
                    children: <Widget>[
                      for (final LumeHadith h in shown)
                        LumeRichRow(
                          icon: LumeIcons.quote,
                          title: h.shortText,
                          subtitle: _ref(l, h),
                          meta: <String>[h.narrator, _grade(l, h.grade)],
                          badge: _badge(l, h.grade),
                          chevron: true,
                          onTap: () => _host.currentState?.say(
                            l.hadithOpened(h.source, h.number),
                            tone: LumeToastTone.info,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: LumeSpace.x1 * 0),
        ],
      ),
    );
  }
}
