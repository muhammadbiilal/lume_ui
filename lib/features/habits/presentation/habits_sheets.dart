/// Habits' sheets: each decision shown before anything is written —
/// deleting a habit, and leaving a changed form.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';

abstract final class HabitsSheetKeys {
  static const Key confirm = ValueKey<String>('habits.sheet.confirm');
  static const Key cancel = ValueKey<String>('habits.sheet.cancel');
}

TextStyle _body(BuildContext context) =>
    LumeType.natural(context, context.lumeType.body).copyWith(color: context.lume.text2);

Future<bool?> habitsDecide(
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
                key: HabitsSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              )
            else
              LumeButton.accent(
                key: HabitsSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            const SizedBox(height: 8),
            LumeButton(
              key: HabitsSheetKeys.cancel,
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

Future<bool> habitsConfirmDelete(
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
          key: HabitsSheetKeys.confirm,
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
