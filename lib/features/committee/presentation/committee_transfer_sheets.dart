/// Committee's export and import sheets (`COMMITTEE_PROPOSAL.md` §12).
///
/// Export asks two things: the format, and whether the file may carry the
/// names of the people in the committee. Names are off by default, and the
/// sheet says in plain words what turning them on means.
///
/// Import checks the whole file and writes nothing until the reader says
/// so; a file with any problem is refused whole, and every problem is
/// shown by its path.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/domain/record_repository.dart';
import '../domain/committee_transfer.dart';

abstract final class CommitteeTransferKeys {
  static const Key json = ValueKey<String>('comm.export.json');
  static const Key csv = ValueKey<String>('comm.export.csv');
  static const Key names = ValueKey<String>('comm.export.names');
  static const Key go = ValueKey<String>('comm.export.go');
  static const Key importOpen = ValueKey<String>('comm.import.open');
  static const Key importText = ValueKey<String>('comm.import.text');
  static const Key importCheck = ValueKey<String>('comm.import.check');
  static const Key importGo = ValueKey<String>('comm.import.go');
  static const Key importReport = ValueKey<String>('comm.import.report');
}

/// What the reader chose to export.
@immutable
class CommitteeExportChoice {
  const CommitteeExportChoice({required this.json, required this.includeNames});

  final bool json;
  final bool includeNames;
}

TextStyle _body(BuildContext context) => LumeType.natural(
  context,
  context.lumeType.body,
).copyWith(color: context.lume.text2);

class CommitteeExportSheet extends StatefulWidget {
  const CommitteeExportSheet({super.key, required this.onImport});

  final VoidCallback onImport;

  @override
  State<CommitteeExportSheet> createState() => _CommitteeExportSheetState();
}

class _CommitteeExportSheetState extends State<CommitteeExportSheet> {
  bool _json = true;
  bool _names = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return LumeSheet(
      title: l.commExportTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeRadioRow(
            key: CommitteeTransferKeys.json,
            label: l.commExportJson,
            subtitle: l.commExportJsonHelp,
            selected: _json,
            onTap: () => setState(() => _json = true),
          ),
          LumeRadioRow(
            key: CommitteeTransferKeys.csv,
            label: l.commExportCsv,
            subtitle: l.commExportCsvHelp,
            selected: !_json,
            onTap: () => setState(() => _json = false),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.commExportNames,
                  style: LumeType.natural(
                    context,
                    context.lumeType.body,
                  ).copyWith(color: context.lume.text),
                ),
              ),
              LumeSwitch(
                key: CommitteeTransferKeys.names,
                value: _names,
                semanticLabel: l.commExportNames,
                onChanged: (bool v) => setState(() => _names = v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l.commExportNamesHelp, style: _body(context)),
          const SizedBox(height: 16),
          LumeButton.accent(
            key: CommitteeTransferKeys.go,
            label: l.commExportGo,
            icon: LumeIcons.download,
            block: true,
            onPressed: () => Navigator.of(
              context,
            ).pop(CommitteeExportChoice(json: _json, includeNames: _names)),
          ),
          const SizedBox(height: 8),
          LumeButton(
            key: CommitteeTransferKeys.importOpen,
            label: l.commImport,
            icon: LumeIcons.refresh,
            block: true,
            onPressed: () {
              Navigator.of(context).pop();
              widget.onImport();
            },
          ),
        ],
      ),
    );
  }
}

/// Import: paste a `lume.committee/1` backup, check it — nothing is
/// written — read the report, then import all of it in one transaction.
class CommitteeImportSheet extends StatefulWidget {
  const CommitteeImportSheet({super.key, required this.store, required this.f});

  final LumeRecordRepository store;
  final LumeFormatting f;

  @override
  State<CommitteeImportSheet> createState() => _CommitteeImportSheetState();
}

class _CommitteeImportSheetState extends State<CommitteeImportSheet> {
  final TextEditingController _text = TextEditingController();
  CommitteeImportReport? _report;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final CommitteeImportReport? r = _report;
    return LumeSheet(
      title: l.commImport,
      tall: true,
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LumeFormField(
              key: CommitteeTransferKeys.importText,
              label: l.commImportText,
              controller: _text,
              kind: LumeFieldKind.multiline,
              rows: 5,
              maxRows: 5,
              onChanged: (_) => setState(() => _report = null),
            ),
            const SizedBox(height: 12),
            LumeButton(
              key: CommitteeTransferKeys.importCheck,
              label: l.commImportCheck,
              block: true,
              onPressed: () => setState(
                () => _report = committeeImportCheck(_text.text, widget.store),
              ),
            ),
            if (r != null) ...<Widget>[
              const SizedBox(height: 12),
              KeyedSubtree(
                key: CommitteeTransferKeys.importReport,
                child: r.ok
                    ? LumeNotice(
                        kind: LumeNoticeKind.info,
                        title: l.commImportReady(
                          widget.f.integer(r.create),
                          widget.f.integer(r.update),
                          widget.f.integer(r.unchanged),
                        ),
                        text: r.namesIncluded ? '' : l.commImportNoNames,
                      )
                    : LumeNotice(
                        kind: LumeNoticeKind.error,
                        title: l.commImportIssues(r.issues.length),
                        text: r.issues
                            .take(12)
                            .map(
                              (CommitteeImportIssue i) =>
                                  '${i.path}: ${i.reason}',
                            )
                            .join('\n'),
                      ),
              ),
            ],
            const SizedBox(height: 12),
            LumeButton.accent(
              key: CommitteeTransferKeys.importGo,
              label: l.commImportAction,
              block: true,
              onPressed: r != null && r.ok && r.records.isNotEmpty
                  ? () => Navigator.of(context).pop(r)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
