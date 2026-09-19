/// Ledger's sheets: the reader's decisions, each shown before anything is
/// written — credit, a manual allocation that no longer fits, what deleting
/// a paid loan does, settling up, a reminder, export and import.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/domain/record_repository.dart';
import '../domain/ledger_book.dart';
import '../domain/ledger_model.dart';
import '../domain/ledger_repository.dart';
import '../domain/ledger_transfer.dart';
import 'ledger_text.dart';

/// Keys the sheets' tests reach for.
abstract final class LedgerSheetKeys {
  static const Key confirm = ValueKey<String>('ledger.sheet.confirm');
  static const Key cancel = ValueKey<String>('ledger.sheet.cancel');
  static const Key alternative = ValueKey<String>('ledger.sheet.alternative');
  static const Key reminderText = ValueKey<String>('ledger.remind.text');
  static const Key reminderShare = ValueKey<String>('ledger.remind.share');
  static const Key reminderUnavailable = ValueKey<String>(
    'ledger.remind.unavailable',
  );
  static const Key exportJson = ValueKey<String>('ledger.export.json');
  static const Key exportCsv = ValueKey<String>('ledger.export.csv');
  static const Key exportNames = ValueKey<String>('ledger.export.names');
  static const Key exportGo = ValueKey<String>('ledger.export.go');
  static const Key importOpen = ValueKey<String>('ledger.import.open');
  static const Key importText = ValueKey<String>('ledger.import.text');
  static const Key importCheck = ValueKey<String>('ledger.import.check');
  static const Key importGo = ValueKey<String>('ledger.import.go');
  static const Key importReport = ValueKey<String>('ledger.import.report');
  static Key remindChoice(String id) => ValueKey<String>('ledger.remind.$id');
}

TextStyle _body(BuildContext context) => LumeType.natural(
  context,
  context.lumeType.body,
).copyWith(color: context.lume.text2);

/// A decision with a confirm, an optional second choice, and Cancel.
/// Returns `true` for confirm, `false` for the alternative, `null` for
/// Cancel.
Future<bool?> ledgerDecide(
  BuildContext context, {
  required String title,
  required String text,
  required String confirm,
  String? alternative,
  bool destructive = false,
  List<Widget> body = const <Widget>[],
}) {
  final AppLocalizations l = AppLocalizations.of(context);
  return showLumeSheet<bool>(
    context: context,
    barrierLabel: title,
    child: Builder(
      builder: (BuildContext sheet) => LumeSheet(
        title: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(text, style: _body(sheet)),
            ...body,
            const SizedBox(height: 18),
            if (destructive)
              LumeButton.danger(
                key: LedgerSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              )
            else
              LumeButton.accent(
                key: LedgerSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            if (alternative != null) ...<Widget>[
              const SizedBox(height: 8),
              LumeButton(
                key: LedgerSheetKeys.alternative,
                label: alternative,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(false),
              ),
            ],
            const SizedBox(height: 8),
            LumeButton(
              key: LedgerSheetKeys.cancel,
              label: l.actionCancel,
              block: true,
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The destructive confirmation of a hard delete.
Future<bool> ledgerConfirmDelete(
  BuildContext context, {
  required String title,
  required String text,
}) async {
  final AppLocalizations l = AppLocalizations.of(context);
  final bool? answer = await showLumeSheet<bool>(
    context: context,
    barrierLabel: title,
    child: Builder(
      builder: (BuildContext sheet) => LumeSheet(
        confirm: true,
        child: LumeDeleteConfirmation(
          key: LedgerSheetKeys.confirm,
          title: title,
          consequence: text,
          confirmLabel: l.actionDelete,
          cancelLabel: l.actionCancel,
          onConfirm: () => Navigator.of(sheet).pop(true),
          onCancel: () => Navigator.of(sheet).pop(false),
        ),
      ),
    ),
  );
  return answer ?? false;
}

/// Settling up: the one repayment it would write, and what it clears.
Future<bool> ledgerConfirmSettle(
  BuildContext context, {
  required LumeFormatting f,
  required LedgerSettlePreview preview,
  required LedgerBalance balance,
  required bool withCode,
}) async {
  final AppLocalizations l = AppLocalizations.of(context);
  final String name = LedgerText.isolate(balance.party.name);
  final String amount = f.amount(
    preview.amount,
    withCode: withCode,
    isolate: true,
  );
  final bool? ok = await ledgerDecide(
    context,
    title: preview.kind == LedgerKind.repaidToMe
        ? l.ledgerSettleOwes(name, amount)
        : l.ledgerSettleOwe(name, amount),
    text: l.ledgerSettleText,
    confirm: l.ledgerSettleConfirm,
    body: <Widget>[
      const SizedBox(height: 10),
      LumeRows(
        children: <Widget>[
          for (final LedgerPrincipalState p in preview.principals)
            LumeCompactRow(
              icon: LumeIcons.check,
              label: LedgerText.kind(l, p.entry.kind),
              subtitle: LedgerText.date(f, p.entry.on),
              value: f.amount(p.remaining, withCode: withCode),
              chevron: false,
            ),
        ],
      ),
    ],
  );
  return ok ?? false;
}

/// The reminder: choose an eligible balance, read and edit the exact text,
/// see what is and is not in it, then Share — a second, explicit action.
/// Reports only that the text was handed to the share sheet.
class LedgerReminderSheet extends StatefulWidget {
  const LedgerReminderSheet({
    super.key,
    required this.balances,
    required this.f,
    required this.withCode,
    required this.sharer,
    this.initial,
  });

  /// The eligible balances (owed to the reader on an open loan).
  final List<LedgerBalance> balances;
  final LumeFormatting f;
  final bool withCode;
  final LumeTextSharer sharer;
  final LedgerBalance? initial;

  /// What became of the handoff, when the reader got as far as Share.
  static Future<LumeShareOutcome?> show(
    BuildContext context, {
    required List<LedgerBalance> balances,
    required LumeFormatting f,
    required bool withCode,
    required LumeTextSharer sharer,
    LedgerBalance? initial,
  }) => showLumeSheet<LumeShareOutcome>(
    context: context,
    barrierLabel: AppLocalizations.of(context).ledgerRemindTitle,
    child: LedgerReminderSheet(
      balances: balances,
      f: f,
      withCode: withCode,
      sharer: sharer,
      initial: initial,
    ),
  );

  @override
  State<LedgerReminderSheet> createState() => _LedgerReminderSheetState();
}

class _LedgerReminderSheetState extends State<LedgerReminderSheet> {
  LedgerBalance? _chosen;
  final TextEditingController _text = TextEditingController();
  LumeShareOutcome? _problem;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final LedgerBalance? first =
        widget.initial ??
        (widget.balances.length == 1 ? widget.balances.single : null);
    if (first != null) _chosen = first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chosen != null && _text.text.isEmpty) _fill(_chosen!);
  }

  void _fill(LedgerBalance b) => _text.text = ledgerReminderText(
    AppLocalizations.of(context),
    widget.f,
    b,
    withCode: widget.withCode,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    final LumeShareOutcome outcome = await widget.sharer.shareText(_text.text);
    if (!mounted) return;
    switch (outcome) {
      case LumeShareOutcome.shared:
        Navigator.of(context).pop(outcome);
      case LumeShareOutcome.dismissed:
        // The reader closed the sheet: nothing is said to have happened.
        setState(() => _busy = false);
      case LumeShareOutcome.unavailable:
      case LumeShareOutcome.failed:
        setState(() {
          _busy = false;
          _problem = outcome;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
    final LedgerBalance? b = _chosen;
    if (widget.balances.isEmpty) {
      return LumeSheet(
        title: l.ledgerRemindTitle,
        child: LumeToolState(
          icon: LumeIcons.bell,
          title: l.ledgerRemindTitle,
          text: l.ledgerRemindNone,
        ),
      );
    }
    return LumeSheet(
      title: l.ledgerRemindTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (b == null) ...<Widget>[
            LumeFieldLabel(label: l.ledgerRemindChoose),
            for (final LedgerBalance x in widget.balances)
              LumeRadioRow(
                key: LedgerSheetKeys.remindChoice(
                  '${x.party.id.value}.${x.currency.code}',
                ),
                label: x.party.name,
                subtitle: widget.f.amount(
                  x.balance,
                  compact: true,
                  withCode: widget.withCode,
                ),
                selected: false,
                onTap: () => setState(() {
                  _chosen = x;
                  _fill(x);
                }),
              ),
          ] else ...<Widget>[
            LumeFormField(
              key: LedgerSheetKeys.reminderText,
              label: l.ledgerRemindMessage,
              controller: _text,
              kind: LumeFieldKind.multiline,
              rows: 4,
            ),
            const SizedBox(height: 10),
            Text(
              b
                      .open(LedgerKind.lent)
                      .any((LedgerPrincipalState p) => p.entry.due != null)
                  ? l.ledgerRemindFieldsDue
                  : l.ledgerRemindFields,
              style: _body(context),
            ),
            const SizedBox(height: 4),
            Text(l.ledgerRemindExcluded, style: _body(context)),
            const SizedBox(height: 10),
            Text(
              l.ledgerRemindHow,
              style: _body(context).copyWith(color: lume.text3),
            ),
            if (_problem != null) ...<Widget>[
              const SizedBox(height: 12),
              LumeNotice(
                key: LedgerSheetKeys.reminderUnavailable,
                kind: LumeNoticeKind.warning,
                title: l.ledgerRemindTitle,
                text: _problem == LumeShareOutcome.unavailable
                    ? l.ledgerRemindUnavailable
                    : l.ledgerRemindFailed,
              ),
            ],
            const SizedBox(height: 16),
            LumeButton.accent(
              key: LedgerSheetKeys.reminderShare,
              label: l.ledgerRemindShare,
              icon: LumeIcons.share,
              block: true,
              busy: _busy,
              onPressed: _busy || _problem == LumeShareOutcome.unavailable
                  ? null
                  : _share,
            ),
          ],
        ],
      ),
    );
  }
}

/// What the reader chose to export.
@immutable
class LedgerExportChoice {
  const LedgerExportChoice({required this.json, required this.includePrivate});

  final bool json;
  final bool includePrivate;
}

/// Export: the lossless JSON backup or the CSV view; names and notes left
/// out unless the reader turns them on, with the line that says what that
/// means. Import is offered from here too.
class LedgerExportSheet extends StatefulWidget {
  const LedgerExportSheet({super.key, required this.onImport});

  final VoidCallback onImport;

  @override
  State<LedgerExportSheet> createState() => _LedgerExportSheetState();
}

class _LedgerExportSheetState extends State<LedgerExportSheet> {
  bool _json = true;
  bool _names = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return LumeSheet(
      title: l.ledgerExportTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeRadioRow(
            key: LedgerSheetKeys.exportJson,
            label: l.ledgerExportJson,
            subtitle: l.ledgerExportJsonSub,
            selected: _json,
            onTap: () => setState(() => _json = true),
          ),
          LumeRadioRow(
            key: LedgerSheetKeys.exportCsv,
            label: l.ledgerExportCsv,
            subtitle: l.ledgerExportCsvSub,
            selected: !_json,
            onTap: () => setState(() => _json = false),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.ledgerIncludeNames,
                  style: LumeType.natural(
                    context,
                    context.lumeType.body,
                  ).copyWith(color: context.lume.text),
                ),
              ),
              LumeSwitch(
                key: LedgerSheetKeys.exportNames,
                value: _names,
                semanticLabel: l.ledgerIncludeNames,
                onChanged: (bool v) => setState(() => _names = v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _names ? l.ledgerIncludeNamesOn : l.ledgerIncludeNamesOff,
            style: _body(context),
          ),
          const SizedBox(height: 16),
          LumeButton.accent(
            key: LedgerSheetKeys.exportGo,
            label: l.ledgerExportAction,
            icon: LumeIcons.download,
            block: true,
            onPressed: () => Navigator.of(
              context,
            ).pop(LedgerExportChoice(json: _json, includePrivate: _names)),
          ),
          const SizedBox(height: 8),
          LumeButton(
            key: LedgerSheetKeys.importOpen,
            label: l.ledgerImport,
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

/// Import: paste a `lume.ledger/1` backup, check it — nothing is written —
/// read the report, then import all of it in one transaction, or nothing.
class LedgerImportSheet extends StatefulWidget {
  const LedgerImportSheet({super.key, required this.store});

  final LumeRecordRepository store;

  @override
  State<LedgerImportSheet> createState() => _LedgerImportSheetState();
}

class _LedgerImportSheetState extends State<LedgerImportSheet> {
  final TextEditingController _text = TextEditingController();
  LedgerImportReport? _report;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LedgerImportReport? r = _report;
    return LumeSheet(
      title: l.ledgerImport,
      tall: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeFormField(
            key: LedgerSheetKeys.importText,
            label: l.ledgerImportPaste,
            controller: _text,
            kind: LumeFieldKind.multiline,
            rows: 5,
            onChanged: (_) => setState(() => _report = null),
          ),
          const SizedBox(height: 10),
          LumeButton(
            key: LedgerSheetKeys.importCheck,
            label: l.ledgerImportCheck,
            block: true,
            onPressed: () => setState(
              () => _report = ledgerImportCheck(_text.text, widget.store),
            ),
          ),
          if (r != null) ...<Widget>[
            const SizedBox(height: 12),
            KeyedSubtree(
              key: LedgerSheetKeys.importReport,
              child: r.ok
                  ? LumeNotice(
                      kind: LumeNoticeKind.info,
                      title: l.ledgerImport,
                      text: <String>[
                        l.ledgerImportReady(r.create, r.update, r.unchanged),
                        if (!r.namesIncluded) l.ledgerImportNoNames,
                      ].join('\n'),
                    )
                  : LumeNotice(
                      kind: LumeNoticeKind.error,
                      title: l.ledgerImportIssues(r.issues.length),
                      text: r.issues
                          .take(12)
                          .map(
                            (LedgerImportIssue i) => '${i.path}: ${i.reason}',
                          )
                          .join('\n'),
                    ),
            ),
            const SizedBox(height: 12),
            LumeButton.accent(
              key: LedgerSheetKeys.importGo,
              label: l.ledgerImportAction,
              block: true,
              onPressed: r.ok && r.records.isNotEmpty
                  ? () => Navigator.of(context).pop(r)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// The overpayment question (§5.4), worded for the direction.
Future<bool> ledgerConfirmCredit(
  BuildContext context, {
  required LumeFormatting f,
  required String name,
  required List<LumeMoney> excess,
  required LedgerKind repaymentKind,
  required bool withCode,
}) async {
  final AppLocalizations l = AppLocalizations.of(context);
  final String amount = excess
      .map((LumeMoney m) => f.amount(m, withCode: withCode, isolate: true))
      .join(', ');
  final String who = LedgerText.isolate(name);
  final bool? ok = await ledgerDecide(
    context,
    title: l.ledgerOverpayTitle,
    text: repaymentKind == LedgerKind.repaidByMe
        ? l.ledgerOverpayByMe(who, amount)
        : l.ledgerOverpayToMe(who, amount),
    confirm: l.ledgerKeepCredit,
  );
  return ok ?? false;
}
