/// Goals' sheets: each decision shown before anything is written — marking
/// a goal completed or abandoned, deleting one, voiding a contribution,
/// leaving a changed form, and adding a contribution.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../ledger/presentation/ledger_text.dart';

/// Keys the sheets' tests reach for.
abstract final class GoalsSheetKeys {
  static const Key confirm = ValueKey<String>('goals.sheet.confirm');
  static const Key cancel = ValueKey<String>('goals.sheet.cancel');
  static const Key contributeAmount = ValueKey<String>(
    'goals.contribute.amount',
  );
  static const Key contributeDate = ValueKey<String>('goals.contribute.date');
  static const Key contributeGo = ValueKey<String>('goals.contribute.go');
}

TextStyle _body(BuildContext context) => LumeType.natural(
  context,
  context.lumeType.body,
).copyWith(color: context.lume.text2);

/// A decision with a confirm and a way out. `true` for confirm, `null` for
/// the way out.
Future<bool?> goalsDecide(
  BuildContext context, {
  required String title,
  required String text,
  required String confirm,
  String? cancel,
  bool destructive = false,
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
            const SizedBox(height: 18),
            if (destructive)
              LumeButton.danger(
                key: GoalsSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              )
            else
              LumeButton.accent(
                key: GoalsSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            const SizedBox(height: 8),
            LumeButton(
              key: GoalsSheetKeys.cancel,
              label: cancel ?? l.actionCancel,
              block: true,
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The destructive confirmation of a hard delete, saying exactly what goes.
Future<bool> goalsConfirmDelete(
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
          key: GoalsSheetKeys.confirm,
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

/// Recording a contribution: an amount, and the day it was made — the
/// reader's today by default, or a date they choose.
class GoalsContributeSheet extends StatefulWidget {
  const GoalsContributeSheet({
    super.key,
    required this.currency,
    required this.initial,
    required this.dateText,
  });

  final LumeCurrency currency;
  final LumeDate? initial;
  final String Function(LumeDate) dateText;

  static Future<(LumeMoney, LumeDate)?> show(
    BuildContext context, {
    required LumeCurrency currency,
    required LumeDate? initial,
    required String Function(LumeDate) dateText,
  }) => showLumeSheet<(LumeMoney, LumeDate)>(
    context: context,
    barrierLabel: AppLocalizations.of(context).goalsAddContribution,
    child: GoalsContributeSheet(
      currency: currency,
      initial: initial,
      dateText: dateText,
    ),
  );

  @override
  State<GoalsContributeSheet> createState() => _GoalsContributeSheetState();
}

class _GoalsContributeSheetState extends State<GoalsContributeSheet> {
  final TextEditingController _amount = TextEditingController();
  late LumeDate? _on = widget.initial;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final DateTime base = _on?.toCalendarDateTime() ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 30),
      lastDate: DateTime(base.year + 30),
    );
    if (picked != null && mounted) {
      setState(() => _on = LumeDate.ofWallClock(picked));
    }
  }

  void _submit(AppLocalizations l) {
    final intl.NumberFormat nf = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
    );
    final LedgerParsedAmount p = ledgerParseAmount(
      l,
      _amount.text,
      widget.currency,
      decimalSeparator: nf.symbols.DECIMAL_SEP,
      groupSeparator: nf.symbols.GROUP_SEP,
    );
    if (p.error != null) {
      setState(() => _error = p.error);
      return;
    }
    final LumeDate? on = _on;
    if (on == null) {
      setState(() => _error = l.goalsErrAmount);
      return;
    }
    Navigator.of(context).pop((p.money!, on));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeDate? on = _on;
    return LumeSheet(
      title: l.goalsAddContribution,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeFormField(
            key: GoalsSheetKeys.contributeAmount,
            label: l.goalsFieldTarget,
            controller: _amount,
            kind: LumeFieldKind.money,
            required: true,
            autofocus: true,
            error: _error,
          ),
          const SizedBox(height: 12),
          LumeFormPicker(
            key: GoalsSheetKeys.contributeDate,
            label: l.commonDate,
            value: on == null ? l.commonDate : widget.dateText(on),
            onTap: () => _pick(),
          ),
          const SizedBox(height: 18),
          LumeButton.accent(
            key: GoalsSheetKeys.contributeGo,
            label: l.goalsAddContribution,
            block: true,
            onPressed: () => _submit(l),
          ),
          const SizedBox(height: 8),
          LumeButton(
            key: GoalsSheetKeys.cancel,
            label: l.actionCancel,
            block: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
