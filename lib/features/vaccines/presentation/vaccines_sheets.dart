/// Vaccinations' sheets: leaving a changed form, and deleting a record.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';

abstract final class VaccinesSheetKeys {
  static const Key confirm = ValueKey<String>('vaccines.sheet.confirm');
  static const Key cancel = ValueKey<String>('vaccines.sheet.cancel');
}

TextStyle _body(BuildContext context) => LumeType.natural(
  context,
  context.lumeType.body,
).copyWith(color: context.lume.text2);

/// Leaving a form with unsaved changes — recoverable (nothing has been
/// written yet), unlike deleting a saved record.
Future<bool> vaccinesConfirmDiscard(BuildContext context) async {
  final AppLocalizations l = AppLocalizations.of(context);
  final bool? answer = await showLumeSheet<bool>(
    context: context,
    barrierLabel: l.recDiscardAsk,
    child: Builder(
      builder: (BuildContext sheet) => LumeSheet(
        title: l.recDiscardAsk,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l.recDiscardText, style: _body(sheet)),
            const SizedBox(height: 18),
            LumeButton.dangerGhost(
              key: VaccinesSheetKeys.confirm,
              label: l.recDiscard,
              block: true,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
            const SizedBox(height: 8),
            LumeButton(
              key: VaccinesSheetKeys.cancel,
              label: l.recKeepEditing,
              block: true,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return answer ?? false;
}

/// Deleting a vaccination — always [LumeDeleteKind.irreversible] (a health
/// record, `vaccines_repository.dart`'s own library doc): the sheet says the
/// record cannot be recovered, and nothing offered afterwards contradicts
/// that by arming an Undo.
Future<bool> vaccinesConfirmDelete(
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
          key: VaccinesSheetKeys.confirm,
          title: title,
          consequence: text,
          confirmLabel: l.actionDelete,
          cancelLabel: l.actionCancel,
          kind: LumeDeleteKind.irreversible,
          onConfirm: () => Navigator.of(sheet).pop(true),
          onCancel: () => Navigator.of(sheet).pop(false),
        ),
      ),
    ),
  );
  return answer ?? false;
}
