/// Medication's sheets: the schedule chooser, and the decisions shown
/// before anything is written — deleting, and leaving a changed form.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/meds_model.dart';
import 'meds_text.dart';

abstract final class MedsSheetKeys {
  static const Key confirm = ValueKey<String>('meds.sheet.confirm');
  static const Key cancel = ValueKey<String>('meds.sheet.cancel');
  static Key scheduleOption(MedsSchedule s) =>
      ValueKey<String>('meds.sheet.schedule.${s.name}');
}

TextStyle _body(BuildContext context) =>
    LumeType.natural(context, context.lumeType.body).copyWith(color: context.lume.text2);

Future<bool?> medsDecide(
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
                key: MedsSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              )
            else
              LumeButton.accent(
                key: MedsSheetKeys.confirm,
                label: confirm,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            const SizedBox(height: 8),
            LumeButton(
              key: MedsSheetKeys.cancel,
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

Future<bool> medsConfirmDelete(
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
          key: MedsSheetKeys.confirm,
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

/// The four schedules, as a single choice — a picker sheet rather than a
/// four-way segmented control, since "Once a week" and "As needed" are not
/// the same width in every language (§60: no assumed text length).
Future<MedsSchedule?> medsChooseSchedule(
  BuildContext context, {
  required MedsSchedule current,
}) {
  final AppLocalizations l = AppLocalizations.of(context);
  return showLumeSheet<MedsSchedule>(
    context: context,
    barrierLabel: l.medsFieldSchedule,
    child: Builder(
      builder: (BuildContext sheet) => LumeSheet(
        title: l.medsFieldSchedule,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final MedsSchedule s in MedsSchedule.values)
              LumeRadioRow(
                key: MedsSheetKeys.scheduleOption(s),
                label: MedsText.schedule(l, s),
                selected: s == current,
                onTap: () => Navigator.of(sheet).pop(s),
              ),
          ],
        ),
      ),
    ),
  );
}
