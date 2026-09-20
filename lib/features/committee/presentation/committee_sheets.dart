/// Committee's sheets: a decision, a destructive confirmation, and the two
/// records the reader makes — a contribution and a payout
/// (`COMMITTEE_PROPOSAL.md` §15).
///
/// A date sheet never offers a day that has not arrived: a cycle may be
/// paid early, but not on a future day (correction 2.3).
library;

import 'package:flutter/material.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';

abstract final class CommitteeSheetKeys {
  static const Key confirm = ValueKey<String>('comm.sheet.confirm');
  static const Key cancel = ValueKey<String>('comm.sheet.cancel');
  static const Key payDate = ValueKey<String>('comm.pay.date');
  static const Key payGo = ValueKey<String>('comm.pay.go');
}

TextStyle _body(BuildContext context) => LumeType.natural(
  context,
  context.lumeType.body,
).copyWith(color: context.lume.text2);

/// A question with one answer and a way out: `true` for confirm, `null`
/// for the way out.
Future<bool?> committeeDecide(
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
                key: CommitteeSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              )
            else
              LumeButton.accent(
                key: CommitteeSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            const SizedBox(height: 8),
            LumeButton(
              key: CommitteeSheetKeys.cancel,
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

/// The destructive confirmation for deleting a committee: it says exactly
/// what would go.
Future<bool> committeeConfirmDelete(
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
          key: CommitteeSheetKeys.confirm,
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

/// The day a contribution or a payout happened.
///
/// [today] is the reader's own day where it is known; the picker will not
/// go past it, because a payment cannot have happened tomorrow.
class CommitteeDateSheet extends StatefulWidget {
  const CommitteeDateSheet({
    super.key,
    required this.title,
    required this.text,
    required this.detail,
    required this.action,
    required this.initial,
    required this.today,
    required this.dateText,
  });

  final String title;
  final String text;

  /// A second line — how many shares are recorded together, say.
  final String? detail;
  final String action;
  final LumeDate? initial;
  final LumeDate? today;
  final String Function(LumeDate) dateText;

  static Future<LumeDate?> show(
    BuildContext context, {
    required String title,
    required String text,
    String? detail,
    required String action,
    required LumeDate? initial,
    required LumeDate? today,
    required String Function(LumeDate) dateText,
  }) => showLumeSheet<LumeDate>(
    context: context,
    barrierLabel: title,
    child: CommitteeDateSheet(
      title: title,
      text: text,
      detail: detail,
      action: action,
      initial: initial,
      today: today,
      dateText: dateText,
    ),
  );

  @override
  State<CommitteeDateSheet> createState() => _CommitteeDateSheetState();
}

class _CommitteeDateSheetState extends State<CommitteeDateSheet> {
  LumeDate? _on;

  @override
  void initState() {
    super.initState();
    _on = widget.initial;
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
      // A payment cannot be dated after the reader's own day.
      lastDate: last ?? DateTime(base.year + 30),
      helpText: l.commPaidOnLabel,
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
          if (widget.detail case final String detail) ...<Widget>[
            const SizedBox(height: 6),
            Text(detail, style: _body(context)),
          ],
          const SizedBox(height: 14),
          LumeFormPicker(
            key: CommitteeSheetKeys.payDate,
            label: l.commPaidOnLabel,
            value: on == null ? l.commErrDate : widget.dateText(on),
            onTap: () => _pick(),
          ),
          const SizedBox(height: 14),
          LumeButton.accent(
            key: CommitteeSheetKeys.payGo,
            label: widget.action,
            block: true,
            onPressed: on == null ? null : () => Navigator.of(context).pop(on),
          ),
        ],
      ),
    );
  }
}
