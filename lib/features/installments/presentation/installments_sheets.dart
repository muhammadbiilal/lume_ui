/// Installments' sheets: each decision shown before anything is written —
/// a payment, cancelling a plan, deleting one, voiding a payment, leaving a
/// changed form.
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

/// Keys the sheets' tests reach for.
abstract final class InstallmentsSheetKeys {
  static const Key confirm = ValueKey<String>('inst.sheet.confirm');
  static const Key cancel = ValueKey<String>('inst.sheet.cancel');
  static const Key payDate = ValueKey<String>('inst.pay.date');
  static const Key payGo = ValueKey<String>('inst.pay.go');
}

TextStyle _body(BuildContext context) => LumeType.natural(
  context,
  context.lumeType.body,
).copyWith(color: context.lume.text2);

/// A decision with a confirm and a way out. `true` for confirm, `null` for
/// the way out.
Future<bool?> installmentsDecide(
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
                key: InstallmentsSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              )
            else
              LumeButton.accent(
                key: InstallmentsSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            const SizedBox(height: 8),
            LumeButton(
              key: InstallmentsSheetKeys.cancel,
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
Future<bool> installmentsConfirmDelete(
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
          key: InstallmentsSheetKeys.confirm,
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

/// Recording one payment: what it pays, exactly, and the day it was paid —
/// the reader's today by default, or a date they choose. Without the
/// reader's day there is no default, and a date must be chosen.
class InstallmentsPaySheet extends StatefulWidget {
  const InstallmentsPaySheet({
    super.key,
    required this.text,
    required this.initial,
    required this.dateText,
  });

  /// What will be recorded, worded.
  final String text;

  /// The reader's today, or `null`.
  final LumeDate? initial;

  /// How a date is written.
  final String Function(LumeDate) dateText;

  static Future<LumeDate?> show(
    BuildContext context, {
    required String text,
    required LumeDate? initial,
    required String Function(LumeDate) dateText,
  }) => showLumeSheet<LumeDate>(
    context: context,
    barrierLabel: AppLocalizations.of(context).instPayTitle,
    child: InstallmentsPaySheet(
      text: text,
      initial: initial,
      dateText: dateText,
    ),
  );

  @override
  State<InstallmentsPaySheet> createState() => _InstallmentsPaySheetState();
}

class _InstallmentsPaySheetState extends State<InstallmentsPaySheet> {
  late LumeDate? _on = widget.initial;

  Future<void> _pick() async {
    final DateTime base =
        _on?.toCalendarDateTime() ?? LumeClockScope.of(context).now();
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeDate? on = _on;
    return LumeSheet(
      title: l.instPayTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.text, style: _body(context)),
          const SizedBox(height: 14),
          LumeFormPicker(
            key: InstallmentsSheetKeys.payDate,
            label: l.instPaidOnLabel,
            value: on == null ? l.instErrDate : widget.dateText(on),
            onTap: () => _pick(),
          ),
          const SizedBox(height: 18),
          LumeButton.accent(
            key: InstallmentsSheetKeys.payGo,
            label: l.instPayConfirm,
            block: true,
            onPressed: on == null ? null : () => Navigator.of(context).pop(on),
          ),
          const SizedBox(height: 8),
          LumeButton(
            key: InstallmentsSheetKeys.cancel,
            label: l.actionCancel,
            block: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
