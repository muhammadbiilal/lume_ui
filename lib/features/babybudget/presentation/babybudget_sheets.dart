/// Baby Budget's sheets: a decision, a destructive confirmation, a date,
/// and the two that move a record between planned and spent
/// (`BABY_BUDGET_PROPOSAL.md` §15).
///
/// The date sheet will not offer a day that has not arrived when it is
/// picking the day money went; a planned purchase may be expected in the
/// future, and then it will (D-B5, correction 1).
library;

import 'package:flutter/material.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';

abstract final class BabyBudgetSheetKeys {
  static const Key confirm = ValueKey<String>('baby.sheet.confirm');
  static const Key cancel = ValueKey<String>('baby.sheet.cancel');
  static const Key date = ValueKey<String>('baby.sheet.date');
  static const Key amount = ValueKey<String>('baby.sheet.amount');
  static const Key go = ValueKey<String>('baby.sheet.go');
}

TextStyle _body(BuildContext context) => LumeType.natural(
  context,
  context.lumeType.body,
).copyWith(color: context.lume.text2);

/// A question with one answer and a way out: `true` for confirm, `null`
/// for the way out.
Future<bool?> babyDecide(
  BuildContext context, {
  required String title,
  required String text,
  required String confirm,
  String? cancel,
  bool destructive = false,
}) => showLumeSheet<bool>(
  context: context,
  barrierLabel: title,
  child: Builder(
    builder: (BuildContext sheet) {
      final AppLocalizations l = AppLocalizations.of(sheet);
      return LumeSheet(
        title: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(text, style: _body(sheet)),
            const SizedBox(height: 18),
            if (destructive)
              LumeButton.danger(
                key: BabyBudgetSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              )
            else
              LumeButton.accent(
                key: BabyBudgetSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            const SizedBox(height: 8),
            LumeButton(
              key: BabyBudgetSheetKeys.cancel,
              label: cancel ?? l.actionCancel,
              block: true,
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        ),
      );
    },
  ),
);

/// The destructive confirmation: it says exactly what would go.
Future<bool> babyConfirmDelete(
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
          key: BabyBudgetSheetKeys.confirm,
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

/// What a "mark as bought" sheet came back with: the day the money went,
/// and what it actually cost when that is not what was planned.
@immutable
class BabyBoughtAnswer {
  const BabyBoughtAnswer(this.on, this.amount);

  final LumeDate on;

  /// The reader's text, still unparsed — the tool parses it in their own
  /// digits and separators, and shows the error in place.
  final String amount;
}

/// The sheet that turns a planned purchase into a spend.
///
/// It asks for both halves of that single write at once (correction 1):
/// the day it happened, and what it actually cost. [today] bounds the
/// picker — nothing was bought tomorrow.
class BabyBoughtSheet extends StatefulWidget {
  const BabyBoughtSheet({
    super.key,
    required this.title,
    required this.text,
    required this.action,
    required this.amountLabel,
    required this.amount,
    required this.currencyCode,
    required this.initial,
    required this.today,
    required this.dateText,
  });

  final String title;
  final String text;
  final String action;
  final String amountLabel;

  /// What was planned, in the reader's own digits, ready to be kept or
  /// replaced.
  final String amount;
  final String currencyCode;
  final LumeDate? initial;
  final LumeDate? today;
  final String Function(LumeDate) dateText;

  static Future<BabyBoughtAnswer?> show(
    BuildContext context, {
    required String title,
    required String text,
    required String action,
    required String amountLabel,
    required String amount,
    required String currencyCode,
    required LumeDate? initial,
    required LumeDate? today,
    required String Function(LumeDate) dateText,
  }) => showLumeSheet<BabyBoughtAnswer>(
    context: context,
    barrierLabel: title,
    child: BabyBoughtSheet(
      title: title,
      text: text,
      action: action,
      amountLabel: amountLabel,
      amount: amount,
      currencyCode: currencyCode,
      initial: initial,
      today: today,
      dateText: dateText,
    ),
  );

  @override
  State<BabyBoughtSheet> createState() => _BabyBoughtSheetState();
}

class _BabyBoughtSheetState extends State<BabyBoughtSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.amount,
  );
  LumeDate? _on;

  @override
  void initState() {
    super.initState();
    _on = widget.initial;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final DateTime base =
        _on?.toCalendarDateTime() ?? LumeClockScope.of(context).now();
    final DateTime? last = widget.today?.toCalendarDateTime();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 30),
      // Money did not go on a day that has not arrived (D-B5).
      lastDate: last ?? DateTime(base.year + 30),
      helpText: l.babyFieldDay,
    );
    if (picked != null && mounted) {
      setState(() => _on = LumeDate.ofWallClock(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeDate? on = _on;
    return LumeSheet(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.text, style: _body(context)),
          const SizedBox(height: 14),
          LumeFormPicker(
            key: BabyBudgetSheetKeys.date,
            label: l.babyFieldDay,
            value: on == null ? l.babyErrDate : widget.dateText(on),
            onTap: () => _pick(),
          ),
          const SizedBox(height: 10),
          LumeFormField(
            key: BabyBudgetSheetKeys.amount,
            label: widget.amountLabel,
            controller: _amount,
            kind: LumeFieldKind.money,
            prefix: widget.currencyCode,
            required: true,
          ),
          const SizedBox(height: 14),
          LumeButton.accent(
            key: BabyBudgetSheetKeys.go,
            label: widget.action,
            block: true,
            onPressed: on == null
                ? null
                : () => Navigator.of(
                    context,
                  ).pop(BabyBoughtAnswer(on, _amount.text)),
          ),
        ],
      ),
    );
  }
}

/// A day on its own — the expected day of a planned purchase, or the day
/// a spend is moved to. [today] bounds it only when [future] is false.
class BabyDateSheet extends StatefulWidget {
  const BabyDateSheet({
    super.key,
    required this.title,
    required this.label,
    required this.action,
    required this.initial,
    required this.today,
    required this.future,
    required this.clearLabel,
    required this.dateText,
  });

  final String title;
  final String label;
  final String action;
  final LumeDate? initial;
  final LumeDate? today;

  /// Whether a day that has not arrived is allowed.
  final bool future;

  /// Offered when the day may be dropped altogether; `null` when it may
  /// not. Choosing it pops [BabyDateChoice.none].
  final String? clearLabel;
  final String Function(LumeDate) dateText;

  static Future<BabyDateChoice?> show(
    BuildContext context, {
    required String title,
    required String label,
    required String action,
    required LumeDate? initial,
    required LumeDate? today,
    required bool future,
    String? clearLabel,
    required String Function(LumeDate) dateText,
  }) => showLumeSheet<BabyDateChoice>(
    context: context,
    barrierLabel: title,
    child: BabyDateSheet(
      title: title,
      label: label,
      action: action,
      initial: initial,
      today: today,
      future: future,
      clearLabel: clearLabel,
      dateText: dateText,
    ),
  );

  @override
  State<BabyDateSheet> createState() => _BabyDateSheetState();
}

/// A day, or the deliberate absence of one.
@immutable
class BabyDateChoice {
  const BabyDateChoice(this.day);
  const BabyDateChoice.none() : day = null;

  final LumeDate? day;
}

class _BabyDateSheetState extends State<BabyDateSheet> {
  LumeDate? _on;

  @override
  void initState() {
    super.initState();
    _on = widget.initial;
  }

  Future<void> _pick() async {
    final DateTime base =
        _on?.toCalendarDateTime() ?? LumeClockScope.of(context).now();
    final DateTime? last = widget.future
        ? null
        : widget.today?.toCalendarDateTime();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 30),
      lastDate: last ?? DateTime(base.year + 30),
      helpText: widget.label,
    );
    if (picked != null && mounted) {
      setState(() => _on = LumeDate.ofWallClock(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeDate? on = _on;
    return LumeSheet(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeFormPicker(
            key: BabyBudgetSheetKeys.date,
            label: widget.label,
            value: on == null ? l.babyNoDate : widget.dateText(on),
            onTap: () => _pick(),
          ),
          const SizedBox(height: 14),
          LumeButton.accent(
            key: BabyBudgetSheetKeys.go,
            label: widget.action,
            block: true,
            onPressed: on == null
                ? null
                : () => Navigator.of(context).pop(BabyDateChoice(on)),
          ),
          if (widget.clearLabel case final String clear) ...<Widget>[
            const SizedBox(height: 8),
            LumeButton(
              key: BabyBudgetSheetKeys.cancel,
              label: clear,
              block: true,
              onPressed: () =>
                  Navigator.of(context).pop(const BabyDateChoice.none()),
            ),
          ],
        ],
      ),
    );
  }
}
