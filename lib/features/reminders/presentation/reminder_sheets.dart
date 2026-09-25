/// The sheet for adding or editing one reminder.
library;

import 'package:flutter/material.dart';

import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/reminder_model.dart';
import 'reminder_text.dart';

abstract final class ReminderSheetKeys {
  static const Key label = ValueKey<String>('rem.sheet.label');
  static const Key time = ValueKey<String>('rem.sheet.time');
  static const Key repeat = ValueKey<String>('rem.sheet.repeat');
  static const Key notes = ValueKey<String>('rem.sheet.notes');
  static const Key save = ValueKey<String>('rem.sheet.save');
  static const Key delete = ValueKey<String>('rem.sheet.delete');
  static const Key cancel = ValueKey<String>('rem.sheet.cancel');
}

@immutable
class ReminderDraftResult {
  const ReminderDraftResult({
    required this.label,
    required this.atHour,
    required this.atMinute,
    required this.repeat,
    this.notes,
  });

  final String label;
  final int atHour;
  final int atMinute;
  final ReminderRepeat repeat;
  final String? notes;
}

TextStyle _label(BuildContext context) =>
    LumeType.natural(context, context.lumeType.label).copyWith(color: context.lume.text2);

/// `null` for cancelled, [_deleted] for "delete this reminder", otherwise the
/// filled-in draft.
const ReminderDraftResult _deleted = ReminderDraftResult(
  label: '',
  atHour: 0,
  atMinute: 0,
  repeat: ReminderRepeat.once,
);

Future<ReminderDraftResult?> reminderEditSheet(
  BuildContext context, {
  required String title,
  required ReminderEntry? existing,
}) {
  final AppLocalizations l = AppLocalizations.of(context);
  final TextEditingController label = TextEditingController(text: existing?.label ?? '');
  final TextEditingController notes = TextEditingController(text: existing?.notes ?? '');
  int hour = existing?.atHour ?? 9;
  int minute = existing?.atMinute ?? 0;
  ReminderRepeat repeat = existing?.repeat ?? ReminderRepeat.once;
  String? labelError;

  return showLumeSheet<ReminderDraftResult>(
    context: context,
    barrierLabel: title,
    child: StatefulBuilder(
      builder: (BuildContext sheet, StateSetter setSheetState) {
        final LumeFormatting f = LumeFormatting.of(sheet);
        return LumeSheet(
          title: title,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LumeFormField(
                key: ReminderSheetKeys.label,
                label: l.remFieldLabel,
                controller: label,
                autofocus: existing == null,
                required: true,
                error: labelError,
              ),
              const SizedBox(height: 14),
              LumeFormPicker(
                key: ReminderSheetKeys.time,
                label: l.recFieldTime,
                value: ReminderText.time(f, hour, minute),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: sheet,
                    initialTime: TimeOfDay(hour: hour, minute: minute),
                  );
                  if (picked != null) {
                    setSheetState(() {
                      hour = picked.hour;
                      minute = picked.minute;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              Text(l.recFieldRepeat, style: _label(sheet)),
              const SizedBox(height: 6),
              LumeSegmented(
                key: ReminderSheetKeys.repeat,
                value: repeat.name,
                items: <LumeChoice>[
                  for (final ReminderRepeat r in ReminderRepeat.values)
                    LumeChoice(value: r.name, label: ReminderText.repeat(l, r)),
                ],
                onChanged: (String v) => setSheetState(
                  () => repeat = ReminderRepeat.values.firstWhere((ReminderRepeat r) => r.name == v),
                ),
              ),
              const SizedBox(height: 14),
              LumeFormField(
                key: ReminderSheetKeys.notes,
                label: l.recFieldNotes,
                controller: notes,
                optionalLabel: l.actionNotSet,
                kind: LumeFieldKind.multiline,
              ),
              const SizedBox(height: 18),
              LumeButton.accent(
                key: ReminderSheetKeys.save,
                label: l.actionSave,
                block: true,
                onPressed: () {
                  final String trimmed = label.text.trim();
                  if (trimmed.isEmpty) {
                    setSheetState(() => labelError = l.remErrLabel);
                    return;
                  }
                  Navigator.of(sheet).pop(
                    ReminderDraftResult(
                      label: trimmed,
                      atHour: hour,
                      atMinute: minute,
                      repeat: repeat,
                      notes: notes.text,
                    ),
                  );
                },
              ),
              if (existing != null) ...<Widget>[
                const SizedBox(height: 8),
                LumeButton.dangerGhost(
                  key: ReminderSheetKeys.delete,
                  label: l.actionDelete,
                  block: true,
                  onPressed: () => Navigator.of(sheet).pop(_deleted),
                ),
              ],
              const SizedBox(height: 8),
              LumeButton(
                key: ReminderSheetKeys.cancel,
                label: l.actionCancel,
                block: true,
                onPressed: () => Navigator.of(sheet).pop(),
              ),
            ],
          ),
        );
      },
    ),
  );
}

bool reminderSheetIsDelete(ReminderDraftResult r) => identical(r, _deleted);
