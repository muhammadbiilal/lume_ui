/// Baby Budget's export and import sheets
/// (`BABY_BUDGET_PROPOSAL.md` §12).
///
/// Export asks two things: the format, and whether the file may carry the
/// names the reader chose — the budget's own name, its categories, its
/// notes and its labels. They are off by default, and the sheet says in
/// plain words what turning them on means: a record of what a family
/// spends on a baby is not something to hand over by accident.
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
import '../domain/babybudget_transfer.dart';

abstract final class BabyBudgetTransferKeys {
  static const Key json = ValueKey<String>('baby.export.json');
  static const Key csv = ValueKey<String>('baby.export.csv');
  static const Key names = ValueKey<String>('baby.export.names');
  static const Key go = ValueKey<String>('baby.export.go');
  static const Key importOpen = ValueKey<String>('baby.import.open');
  static const Key importText = ValueKey<String>('baby.import.text');
  static const Key importCheck = ValueKey<String>('baby.import.check');
  static const Key importGo = ValueKey<String>('baby.import.go');
  static const Key importReport = ValueKey<String>('baby.import.report');
}

/// What the reader chose to export.
@immutable
class BabyBudgetExportChoice {
  const BabyBudgetExportChoice({
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

class BabyBudgetExportSheet extends StatefulWidget {
  const BabyBudgetExportSheet({super.key, required this.onImport});

  final VoidCallback onImport;

  @override
  State<BabyBudgetExportSheet> createState() => _BabyBudgetExportSheetState();
}

class _BabyBudgetExportSheetState extends State<BabyBudgetExportSheet> {
  bool _json = true;
  bool _names = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return LumeSheet(
      title: l.babyExportTitle,
      subtitle: l.babyExportText,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeRadioRow(
            key: BabyBudgetTransferKeys.json,
            label: l.babyExportJson,
            subtitle: l.babyExportJsonText,
            selected: _json,
            onTap: () => setState(() => _json = true),
          ),
          LumeRadioRow(
            key: BabyBudgetTransferKeys.csv,
            label: l.babyExportCsv,
            subtitle: l.babyExportCsvText,
            selected: !_json,
            onTap: () => setState(() => _json = false),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.babyKeepNames,
                  style: LumeType.natural(
                    context,
                    context.lumeType.body,
                  ).copyWith(color: context.lume.text),
                ),
              ),
              LumeSwitch(
                key: BabyBudgetTransferKeys.names,
                value: _names,
                semanticLabel: l.babyKeepNames,
                onChanged: (bool v) => setState(() => _names = v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l.babyKeepNamesText, style: _body(context)),
          const SizedBox(height: 16),
          LumeButton.accent(
            key: BabyBudgetTransferKeys.go,
            label: l.babyExportGo,
            icon: LumeIcons.download,
            block: true,
            onPressed: () => Navigator.of(
              context,
            ).pop(BabyBudgetExportChoice(json: _json, includeNames: _names)),
          ),
          const SizedBox(height: 8),
          LumeButton(
            key: BabyBudgetTransferKeys.importOpen,
            label: l.babyImport,
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

/// Import: paste a `lume.babybudget/1` backup, check it — nothing is
/// written — read the report, then import all of it in one transaction.
class BabyBudgetImportSheet extends StatefulWidget {
  const BabyBudgetImportSheet({
    super.key,
    required this.store,
    required this.f,
  });

  final LumeRecordRepository store;
  final LumeFormatting f;

  @override
  State<BabyBudgetImportSheet> createState() => _BabyBudgetImportSheetState();
}

class _BabyBudgetImportSheetState extends State<BabyBudgetImportSheet> {
  final TextEditingController _text = TextEditingController();
  BabyBudgetImportReport? _report;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final BabyBudgetImportReport? r = _report;
    return LumeSheet(
      title: l.babyImport,
      tall: true,
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LumeFormField(
              key: BabyBudgetTransferKeys.importText,
              label: l.babyImportText,
              controller: _text,
              kind: LumeFieldKind.multiline,
              rows: 5,
              maxRows: 5,
              onChanged: (_) => setState(() => _report = null),
            ),
            const SizedBox(height: 12),
            LumeButton(
              key: BabyBudgetTransferKeys.importCheck,
              label: l.babyImportCheck,
              block: true,
              onPressed: () => setState(
                () => _report = babyBudgetImportCheck(_text.text, widget.store),
              ),
            ),
            if (r != null) ...<Widget>[
              const SizedBox(height: 12),
              KeyedSubtree(
                key: BabyBudgetTransferKeys.importReport,
                child: r.ok
                    ? LumeNotice(
                        kind: LumeNoticeKind.info,
                        title: l.babyImportReady(
                          widget.f.integer(r.create),
                          widget.f.integer(r.update),
                          widget.f.integer(r.unchanged),
                        ),
                        text: r.namesIncluded ? '' : l.babyImportNoNames,
                      )
                    : LumeNotice(
                        kind: LumeNoticeKind.error,
                        title: l.babyImportIssues(r.issues.length),
                        text: r.issues
                            .take(12)
                            .map(
                              (BabyBudgetImportIssue i) =>
                                  '${i.path}: ${i.reason}',
                            )
                            .join('\n'),
                      ),
              ),
            ],
            const SizedBox(height: 12),
            LumeButton.accent(
              key: BabyBudgetTransferKeys.importGo,
              label: l.babyImportAction,
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
