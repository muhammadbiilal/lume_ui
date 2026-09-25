/// The sheet for filling in, editing or clearing one meal slot.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';

abstract final class MealPlanSheetKeys {
  static const Key text = ValueKey<String>('mealplan.sheet.text');
  static const Key save = ValueKey<String>('mealplan.sheet.save');
  static const Key clear = ValueKey<String>('mealplan.sheet.clear');
  static const Key cancel = ValueKey<String>('mealplan.sheet.cancel');
}

TextStyle _body(BuildContext context) => LumeType.natural(
  context,
  context.lumeType.body,
).copyWith(color: context.lume.text2);

/// `null` for cancelled, `''` for "clear this slot", anything else for the
/// text to save.
Future<String?> mealPlanEditSlot(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String initial,
}) {
  final AppLocalizations l = AppLocalizations.of(context);
  final TextEditingController c = TextEditingController(text: initial);
  return showLumeSheet<String>(
    context: context,
    barrierLabel: title,
    child: Builder(
      builder: (BuildContext sheet) => LumeSheet(
        title: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(subtitle, style: _body(sheet)),
            const SizedBox(height: 14),
            LumeFormField(
              key: MealPlanSheetKeys.text,
              label: l.mealFieldText,
              controller: c,
              autofocus: true,
              required: true,
            ),
            const SizedBox(height: 18),
            LumeButton.accent(
              key: MealPlanSheetKeys.save,
              label: l.actionSave,
              block: true,
              onPressed: () => Navigator.of(sheet).pop(c.text),
            ),
            if (initial.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              LumeButton.dangerGhost(
                key: MealPlanSheetKeys.clear,
                label: l.mealClearSlot,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(''),
              ),
            ],
            const SizedBox(height: 8),
            LumeButton(
              key: MealPlanSheetKeys.cancel,
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
