/// Installments' export and import sheets: the lossless backup or the CSV
/// view, with items, merchants and notes left out unless the reader turns
/// them on; and an import that checks the whole file — writing nothing —
/// before it offers to write all of it, or nothing.
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
import '../domain/installments_transfer.dart';

abstract final class InstallmentsTransferKeys {
  static const Key json = ValueKey<String>('inst.export.json');
  static const Key csv = ValueKey<String>('inst.export.csv');
  static const Key names = ValueKey<String>('inst.export.names');
  static const Key go = ValueKey<String>('inst.export.go');
  static const Key importOpen = ValueKey<String>('inst.import.open');
  static const Key importText = ValueKey<String>('inst.import.text');
  static const Key importCheck = ValueKey<String>('inst.import.check');
  static const Key importGo = ValueKey<String>('inst.import.go');
  static const Key importReport = ValueKey<String>('inst.import.report');
}

/// What the reader chose to export.
@immutable
class InstallmentsExportChoice {
  const InstallmentsExportChoice({
    required this.json,
    required this.includeNames,
  });

  final bool json;
  final bool includeNames;
}

TextStyle _body(BuildContext context) => LumeType.natural(
  context,
  context.lumeType.body,
).copyWith(color: context.lume.text2);

class InstallmentsExportSheet extends StatefulWidget {
  const InstallmentsExportSheet({super.key, required this.onImport});

  final VoidCallback onImport;

  @override
  State<InstallmentsExportSheet> createState() =>
      _InstallmentsExportSheetState();
}

class _InstallmentsExportSheetState extends State<InstallmentsExportSheet> {
  bool _json = true;
  bool _names = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return LumeSheet(
      title: l.instExportTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeRadioRow(
            key: InstallmentsTransferKeys.json,
            label: l.instExportJson,
            subtitle: l.instExportJsonSub,
            selected: _json,
            onTap: () => setState(() => _json = true),
          ),
          LumeRadioRow(
            key: InstallmentsTransferKeys.csv,
            label: l.instExportCsv,
            subtitle: l.instExportCsvSub,
            selected: !_json,
            onTap: () => setState(() => _json = false),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.instIncludeNames,
                  style: LumeType.natural(
                    context,
                    context.lumeType.body,
                  ).copyWith(color: context.lume.text),
                ),
              ),
              LumeSwitch(
                key: InstallmentsTransferKeys.names,
                value: _names,
                semanticLabel: l.instIncludeNames,
                onChanged: (bool v) => setState(() => _names = v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _names ? l.instIncludeNamesOn : l.instIncludeNamesOff,
            style: _body(context),
          ),
          const SizedBox(height: 16),
          LumeButton.accent(
            key: InstallmentsTransferKeys.go,
            label: l.instExportAction,
            icon: LumeIcons.download,
            block: true,
            onPressed: () => Navigator.of(
              context,
            ).pop(InstallmentsExportChoice(json: _json, includeNames: _names)),
          ),
          const SizedBox(height: 8),
          LumeButton(
            key: InstallmentsTransferKeys.importOpen,
            label: l.instImport,
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

/// Import: paste a `lume.installments/1` backup, check it — nothing is
/// written — read the report, then import all of it in one transaction.
class InstallmentsImportSheet extends StatefulWidget {
  const InstallmentsImportSheet({
    super.key,
    required this.store,
    required this.f,
  });

  final LumeRecordRepository store;
  final LumeFormatting f;

  @override
  State<InstallmentsImportSheet> createState() =>
      _InstallmentsImportSheetState();
}

class _InstallmentsImportSheetState extends State<InstallmentsImportSheet> {
  final TextEditingController _text = TextEditingController();
  InstallmentsImportReport? _report;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final InstallmentsImportReport? r = _report;
    final LumeFormatting f = widget.f;
    return LumeSheet(
      title: l.instImport,
      tall: true,
      // A pasted backup is long: the sheet scrolls, so Check and Import are
      // always reachable under it.
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LumeFormField(
              key: InstallmentsTransferKeys.importText,
              label: l.instImportPaste,
              controller: _text,
              kind: LumeFieldKind.multiline,
              rows: 5,
              onChanged: (_) => setState(() => _report = null),
            ),
            const SizedBox(height: 10),
            LumeButton(
              key: InstallmentsTransferKeys.importCheck,
              label: l.instImportCheck,
              block: true,
              onPressed: () => setState(
                () =>
                    _report = installmentsImportCheck(_text.text, widget.store),
              ),
            ),
            if (r != null) ...<Widget>[
              const SizedBox(height: 12),
              KeyedSubtree(
                key: InstallmentsTransferKeys.importReport,
                child: r.ok
                    ? LumeNotice(
                        kind: LumeNoticeKind.info,
                        title: l.instImport,
                        text: <String>[
                          l.instImportReady(
                            f.integer(r.create),
                            f.integer(r.update),
                            f.integer(r.unchanged),
                          ),
                          if (!r.namesIncluded) l.instImportNoNames,
                        ].join('\n'),
                      )
                    : LumeNotice(
                        kind: LumeNoticeKind.error,
                        title: l.instImportIssues(r.issues.length),
                        // Paths and reasons are stable machine words, the
                        // same in every language, so they can be looked up.
                        text: r.issues
                            .take(12)
                            .map(
                              (InstallmentsImportIssue i) =>
                                  '${i.path}: ${i.reason}',
                            )
                            .join('\n'),
                      ),
              ),
              const SizedBox(height: 12),
              LumeButton.accent(
                key: InstallmentsTransferKeys.importGo,
                label: l.instImportAction,
                block: true,
                onPressed: r.ok && r.records.isNotEmpty
                    ? () => Navigator.of(context).pop(r)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
