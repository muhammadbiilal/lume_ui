/// Notes on the record layer — `record-schemas.js` `notes`.
///
/// A note is a title, a body, a folder and whether it is pinned; when it was
/// last changed is the store's. Guide: "title, excerpt and modified date" ·
/// "autosave and conflict" — the conflict is the host's version check.
library;

import 'package:flutter/widgets.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_schema.dart';
import '../../records/presentation/record_family.dart';

/// `options.folders`. Stored by name; the reference's own `@notes.fWork`
/// keys are read too, so a record written by the web build migrates.
enum LumeNoteFolder {
  work('@notes.fWork'),
  personal('@notes.fPersonal'),
  ideas('@notes.fIdeas');

  const LumeNoteFolder(this.legacy);

  final String legacy;

  static LumeNoteFolder? byId(Object? v) {
    for (final LumeNoteFolder f in values) {
      if (v == f.name || v == f.legacy) return f;
    }
    return null;
  }

  String label(AppLocalizations l) => switch (this) {
    work => l.notesFolderWork,
    personal => l.notesFolderPersonal,
    ideas => l.notesFolderIdeas,
  };
}

class LumeNote extends LumeFamilyRecord {
  const LumeNote(
    super.record, {
    required this.title,
    required this.body,
    required this.folder,
    required this.pinned,
  });

  final String title;
  final String body;
  final LumeNoteFolder? folder;
  final bool pinned;

  /// `r._up || r._at`.
  DateTime get modified => record.updatedAt;

  /// `row(r).sub` — the body cut at 62 characters.
  String get excerpt {
    final Characters b = body.characters;
    return b.length > 62 ? '${b.take(62)}…' : body;
  }
}

class LumeNoteFamily extends LumeRecordFamily<LumeNote> {
  const LumeNoteFamily();

  static const LumeRecordSchema kSchema = LumeRecordSchema(
    collection: 'notes',
    fields: <LumeRecordField>[
      LumeRecordField(
        name: 'title',
        kind: LumeRecordFieldKind.text,
        required: true,
      ),
      LumeRecordField(
        name: 'body',
        kind: LumeRecordFieldKind.textarea,
        wide: true,
        rows: 6,
      ),
      LumeRecordField(name: 'folder', kind: LumeRecordFieldKind.select),
      LumeRecordField(name: 'pinned', kind: LumeRecordFieldKind.check),
    ],
  );

  @override
  LumeRecordSchema get schema => kSchema;

  @override
  String get icon => LumeIcons.note;

  @override
  String noun(AppLocalizations l) => l.recNotesNoun;
  @override
  String nounPlural(AppLocalizations l) => l.recNotesNounPlural;
  @override
  String emptyTitle(AppLocalizations l) => l.recNotesEmptyTitle;
  @override
  String emptyText(AppLocalizations l) => l.recNotesEmptyText;

  /// A sample note's words.
  static String seeded(AppLocalizations l, String key) => switch (key) {
    'notesSeedN1' => l.notesSeedN1,
    'notesSeedN1x' => l.notesSeedN1x,
    'notesSeedN2' => l.notesSeedN2,
    'notesSeedN2x' => l.notesSeedN2x,
    'notesSeedN3' => l.notesSeedN3,
    'notesSeedN3x' => l.notesSeedN3x,
    'notesSeedN4' => l.notesSeedN4,
    'notesSeedN4x' => l.notesSeedN4x,
    _ => '@$key',
  };

  @override
  LumeNote read(LumeRecord r, LumeRecordContext c) {
    String text(String name) =>
        LumeFamilyText.resolve(r, name, (String k) => seeded(c.l, k));
    return LumeNote(
      r,
      title: text('title'),
      body: text('body'),
      folder: LumeNoteFolder.byId(r['folder']),
      pinned: r['pinned'] == true,
    );
  }

  @override
  Map<String, Object?> defaults(LumeRecordContext c) => <String, Object?>{
    'folder': LumeNoteFolder.values.first.name,
    'pinned': false,
  };

  @override
  Map<String, Object?> editValues(LumeNote x) => <String, Object?>{
    'title': x.title,
    'body': x.body,
    'folder': x.folder?.name ?? '',
    'pinned': x.pinned,
  };

  @override
  LumeFamilyRow row(LumeNote x, LumeRecordContext c) => LumeFamilyRow(
    title: x.title,
    subtitle: x.excerpt,
    meta: <String>[
      if (x.folder != null) x.folder!.label(c.l),
      LumeFamilyText.when(c, x.modified),
    ],
    badge: x.pinned
        ? LumeBadge(label: c.l.recPinned, tone: LumeBadgeTone.info)
        : null,
  );

  @override
  LumeFamilyHero hero(LumeNote x, LumeRecordContext c) => LumeFamilyHero(
    kicker: x.folder?.label(c.l) ?? c.l.recNotesNoun,
    value: x.title,
    caption: c.l.recModified(LumeFamilyText.when(c, x.modified)),
    gradient: (g) => g.night,
  );

  @override
  List<LumeFact> facts(LumeNote x, LumeRecordContext c) => <LumeFact>[
    LumeFact(
      label: c.l.recFieldNote,
      value: x.body.isEmpty ? c.l.recNone : x.body,
      block: true,
    ),
    LumeFact(label: c.l.recFieldFolder, value: x.folder?.label(c.l) ?? '—'),
    LumeFact(
      label: c.l.recFieldPinned,
      value: x.pinned ? c.l.commonYes : c.l.commonNo,
    ),
  ];

  @override
  List<LumeFamilyField> fields(LumeRecordContext c) => <LumeFamilyField>[
    LumeFamilyField(
      name: 'title',
      label: c.l.recFieldTitle,
      placeholder: c.l.recNotesPh,
    ),
    LumeFamilyField(name: 'body', label: c.l.recFieldNote),
    LumeFamilyField(
      name: 'folder',
      label: c.l.recFieldFolder,
      options: <LumeFamilyOption>[
        for (final LumeNoteFolder f in LumeNoteFolder.values)
          LumeFamilyOption(f.name, f.label(c.l)),
      ],
    ),
    LumeFamilyField(name: 'pinned', label: c.l.recFieldPinned),
  ];
}
