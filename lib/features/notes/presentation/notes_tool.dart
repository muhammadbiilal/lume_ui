/// Notes — `tools/planning/notes.tool.js` under `crud-engine.js`.
///
/// The reader's notes lead — search and the records — and the tool's own
/// composition follows: three metrics, the pinned notes as cards, the
/// folders with their counts, and the recent notes. The reference draws that
/// composition from four fixture notes and folder counts that never change
/// (5, 4, 3 beside four notes); here it reads the same records the list
/// does, so adding, pinning or deleting a note changes every figure (C86).
/// A card or a row opens its note; New note opens the form.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../records/presentation/record_family.dart';
import '../../records/presentation/record_tool.dart';
import '../../tools/application/tool_request.dart';
import '../domain/note_family.dart';

abstract final class LumeNotesTool {
  static const String id = 'notes';
  static const LumeRecordKeys keys = LumeRecordKeys(id);

  static const Key metricsKey = ValueKey<String>('notes.metrics');
  static const Key pinnedKey = ValueKey<String>('notes.pinned');
  static const Key foldersKey = ValueKey<String>('notes.folders');
  static const Key recentKey = ValueKey<String>('notes.recent');
  static const Key emptyKey = ValueKey<String>('notes.empty');
  static const Key fabKey = ValueKey<String>('notes.fab');

  static Key cardKey(String id) => ValueKey<String>('notes.card.$id');

  static Widget open(LumeToolRequest request) => LumeRecordTool<LumeNote>(
    request: request,
    family: const LumeNoteFamily(),
    compose: _compose,
    floating: (BuildContext context, LumeRecordScope<LumeNote> s) => LumeFab(
      key: fabKey,
      label: s.c.l.notesNew,
      icon: LumeIcons.plus,
      onPressed: s.create,
    ),
  );

  /// `notesShown` — the reference searches title, excerpt and folder.
  static bool shown(LumeNote x, String query, LumeRecordContext c) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return <String>[
      x.title,
      x.excerpt,
      x.folder?.label(c.l) ?? '',
    ].join(' ').toLowerCase().contains(q);
  }

  static List<Widget> _compose(
    BuildContext context,
    LumeRecordScope<LumeNote> s,
  ) {
    final LumeRecordContext c = s.c;
    final List<LumeNote> all = s.items;
    final List<LumeNote> pinned = <LumeNote>[
      for (final LumeNote x in all)
        if (x.pinned) x,
    ];
    // Newest change first, as the reference's recent list reads.
    final List<LumeNote> recent = <LumeNote>[
      for (final LumeNote x in all)
        if (shown(x, s.query, c)) x,
    ]..sort((LumeNote a, LumeNote b) => b.modified.compareTo(a.modified));

    return <Widget>[
      LumeToolSection(
        child: LumeMetrics(
          key: metricsKey,
          columns: 3,
          children: <LumeMetric>[
            LumeMetric(value: c.f.integer(all.length), label: c.l.notesTotal),
            LumeMetric(
              value: c.f.integer(pinned.length),
              label: c.l.notesPinned,
            ),
            LumeMetric(
              value: c.f.integer(LumeNoteFolder.values.length),
              label: c.l.notesFolders,
            ),
          ],
        ),
      ),
      if (pinned.isNotEmpty)
        LumeToolSection(
          title: c.l.notesPinned,
          flush: true,
          // The reference's strip bleeds twice — a flush section and the
          // strip's own negative margin — so its first card touches the
          // screen's edge. Here it starts at the gutter, as every other
          // strip does (C86).
          child: LumeHorizontalStrip(
            key: pinnedKey,
            gap: 11,
            padding: const EdgeInsets.fromLTRB(
              LumeSpace.pageCompact,
              0,
              LumeSpace.pageCompact,
              4,
            ),
            bleed: true,
            children: <Widget>[
              for (final LumeNote x in pinned)
                LumeNoteTile(
                  key: cardKey(x.id),
                  title: x.title,
                  body: x.excerpt,
                  meta: LumeFamilyText.when(c, x.modified),
                  onTap: () => s.open(x.id),
                ),
            ],
          ),
        ),
      LumeToolSection(
        title: c.l.notesFolders,
        child: LumeRows(
          key: foldersKey,
          children: <Widget>[
            for (final LumeNoteFolder f in LumeNoteFolder.values)
              LumeCompactRow(
                icon: LumeIcons.folder,
                label: f.label(c.l),
                value: c.f.integer(
                  all.where((LumeNote x) => x.folder == f).length,
                ),
                chevron: false,
              ),
          ],
        ),
      ),
      LumeToolSection(
        title: c.l.notesRecent,
        child: recent.isEmpty
            ? LumeToolState(
                key: emptyKey,
                icon: LumeIcons.note,
                title: c.l.notesNoMatch,
                text: c.l.notesNoMatchText,
              )
            : LumeRows(
                key: recentKey,
                children: <Widget>[
                  for (final LumeNote x in recent)
                    LumeRichRow(
                      icon: LumeIcons.note,
                      title: x.title,
                      subtitle: x.excerpt,
                      meta: <String>[
                        if (x.folder != null) x.folder!.label(c.l),
                        LumeFamilyText.when(c, x.modified),
                      ],
                      chevron: true,
                      onTap: () => s.open(x.id),
                    ),
                ],
              ),
      ),
    ];
  }
}

/// `.notecardx` — a pinned note: 168 wide, at least 116 tall, title, three
/// lines of body and when it was changed.
class LumeNoteTile extends StatelessWidget {
  const LumeNoteTile({
    super.key,
    required this.title,
    required this.body,
    required this.meta,
    this.onTap,
  });

  final String title;
  final String body;
  final String meta;
  final VoidCallback? onTap;

  static const double width = 168;
  static const double minHeight = 116;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return LumePressable(
      onTap: onTap,
      semanticLabel: '$title, $meta',
      borderRadius: LumeRadius.brSm,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brSm,
          border: Border.all(color: lume.border, width: LumeSpace.border),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LumeType.tracked(
                  LumeType.natural(context, context.lumeType.meta, size: 13),
                  -0.024,
                ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: LumeType.natural(
                  context,
                  context.lumeType.metaSmall,
                  size: 11,
                ).copyWith(color: lume.text3, height: 1.45),
              ),
              const SizedBox(height: 5),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LumeType.natural(
                  context,
                  context.lumeType.metaSmall,
                  size: 10,
                ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
