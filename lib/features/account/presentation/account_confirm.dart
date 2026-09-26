/// The account section's one confirmation question — the reference's
/// `askConfirm` (`services/account-forms.js`), used for discarding an edit,
/// signing out, signing out other devices and deleting the account.
library;

import 'package:flutter/material.dart';

import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';

/// `true` when the reader confirms; `false` for Cancel; `null` when the
/// sheet is dismissed.
Future<bool?> askLumeConfirm(
  BuildContext context, {
  required String title,
  required String text,
  required String confirm,
  LumeDeleteKind kind = LumeDeleteKind.recoverable,
}) {
  final AppLocalizations l = AppLocalizations.of(context);
  return showLumeSheet<bool>(
    context: context,
    barrierLabel: title,
    // The buttons pop the *sheet's* route, which is why they take their
    // context from inside it. Closing over the caller's `context` would find
    // the navigator the caller is on — and a sheet raised on the root
    // navigator is not on that one, so Cancel would dismiss the screen
    // underneath instead of the question.
    child: Builder(
      builder: (BuildContext sheetContext) => LumeSheet(
        child: LumeDeleteConfirmation(
          title: title,
          consequence: text,
          confirmLabel: confirm,
          cancelLabel: l.actionCancel,
          kind: kind,
          onConfirm: () => Navigator.of(sheetContext).pop(true),
          onCancel: () => Navigator.of(sheetContext).pop(false),
        ),
      ),
    ),
  );
}
