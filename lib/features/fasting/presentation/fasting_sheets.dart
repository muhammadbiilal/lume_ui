/// The sheet for logging a new fast, correcting a logged one, or deleting
/// it — Fasting Tracker's only form. The date is chosen, never typed: the
/// reader picks a day from the platform's own calendar, exactly as Cycle
/// Tracker's period dates are.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/lume_format.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/fasting_model.dart';

abstract final class FastingSheetKeys {
  static const Key datePicker = ValueKey<String>('fasting.sheet.date');
  static const Key kindControl = ValueKey<String>('fasting.sheet.kind');
  static const Key keptToggle = ValueKey<String>('fasting.sheet.kept');
  static const Key save = ValueKey<String>('fasting.sheet.save');
  static const Key delete = ValueKey<String>('fasting.sheet.delete');
  static const Key cancel = ValueKey<String>('fasting.sheet.cancel');
  static const Key confirmDelete = ValueKey<String>('fasting.sheet.confirmDelete');
}

/// What the sheet decided: save this entry, delete it, or (`null` from
/// [FastEntrySheet.show]) walk away.
@immutable
class FastEntryResult {
  const FastEntryResult.saved(LumeDate this.date, this.kind, this.kept)
    : delete = false;
  const FastEntryResult.deleted()
    : date = null,
      kind = null,
      kept = false,
      delete = true;

  final LumeDate? date;
  final FastingKind? kind;
  final bool kept;
  final bool delete;
}

/// Logs a new fast, or edits/deletes one already logged.
class FastEntrySheet extends StatefulWidget {
  const FastEntrySheet({
    super.key,
    required this.isNew,
    required this.initialDate,
    required this.today,
    this.initialKind = FastingKind.voluntary,
    this.initialKept = true,
    this.earliest,
    this.canDelete = false,
    this.dateTaken,
  });

  final bool isNew;
  final LumeDate initialDate;
  final LumeDate today;
  final FastingKind initialKind;
  final bool initialKept;

  /// How far back the date picker reaches. Defaults to ten years.
  final LumeDate? earliest;

  final bool canDelete;

  /// Whether another logged fast already falls on this day — disabled in the
  /// picker so the reader cannot create the conflict, rather than picking it
  /// and being told afterwards.
  final bool Function(LumeDate day)? dateTaken;

  static Future<FastEntryResult?> show(
    BuildContext context, {
    required bool isNew,
    required LumeDate initialDate,
    required LumeDate today,
    FastingKind initialKind = FastingKind.voluntary,
    bool initialKept = true,
    LumeDate? earliest,
    bool canDelete = false,
    bool Function(LumeDate day)? dateTaken,
  }) {
    final AppLocalizations l = AppLocalizations.of(context);
    return showLumeSheet<FastEntryResult>(
      context: context,
      barrierLabel: isNew ? l.fastingLogFast : l.fastingEditFast,
      child: FastEntrySheet(
        isNew: isNew,
        initialDate: initialDate,
        today: today,
        initialKind: initialKind,
        initialKept: initialKept,
        earliest: earliest,
        canDelete: canDelete,
        dateTaken: dateTaken,
      ),
    );
  }

  @override
  State<FastEntrySheet> createState() => _FastEntrySheetState();
}

class _FastEntrySheetState extends State<FastEntrySheet> {
  late LumeDate _date = widget.initialDate;
  late FastingKind _kind = widget.initialKind;
  late bool _kept = widget.initialKept;

  LumeDate get _earliest => widget.earliest ?? widget.today.addDays(-3650);

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date.toCalendarDateTime(),
      firstDate: _earliest.toCalendarDateTime(),
      lastDate: widget.today.toCalendarDateTime(),
      selectableDayPredicate: widget.dateTaken == null
          ? null
          : (DateTime d) => !widget.dateTaken!(LumeDate.ofWallClock(d)),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = LumeDate.ofWallClock(picked));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context);

    return LumeSheet(
      title: widget.isNew ? l.fastingLogFast : l.fastingEditFast,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeFormPicker(
            key: FastingSheetKeys.datePicker,
            label: l.fastingDateLabel,
            value: f.dateMediumYear(_date.toCalendarDateTime()),
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          LumeFieldLabel(label: l.fastingKindLabel),
          const SizedBox(height: 8),
          LumeSegmented(
            key: FastingSheetKeys.kindControl,
            value: _kind.name,
            items: <LumeChoice>[
              LumeChoice(value: FastingKind.voluntary.name, label: l.fastingKindSunnah),
              LumeChoice(value: FastingKind.makeup.name, label: l.fastingKindQada),
            ],
            semanticLabel: l.fastingKindLabel,
            onChanged: (String v) => setState(
              () => _kind = FastingKind.values.byName(v),
            ),
          ),
          const SizedBox(height: 14),
          LumeCheckbox(
            key: FastingSheetKeys.keptToggle,
            label: l.fastingKeptToggleLabel,
            value: _kept,
            onChanged: (bool v) => setState(() => _kept = v),
          ),
          const SizedBox(height: 18),
          LumeButton.accent(
            key: FastingSheetKeys.save,
            label: l.actionSave,
            block: true,
            onPressed: () => Navigator.of(context).pop(
              FastEntryResult.saved(_date, _kind, _kept),
            ),
          ),
          if (widget.canDelete) ...<Widget>[
            const SizedBox(height: 8),
            LumeButton.dangerGhost(
              key: FastingSheetKeys.delete,
              label: l.fastingDeleteEntry,
              block: true,
              onPressed: () => unawaited(_confirmDelete(l)),
            ),
          ],
          const SizedBox(height: 8),
          LumeButton(
            key: FastingSheetKeys.cancel,
            label: l.actionCancel,
            block: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AppLocalizations l) async {
    final bool? confirmed = await showLumeSheet<bool>(
      context: context,
      barrierLabel: l.fastingDeleteTitle,
      child: LumeSheet(
        confirm: true,
        child: LumeDeleteConfirmation(
          key: FastingSheetKeys.confirmDelete,
          title: l.fastingDeleteTitle,
          consequence: l.fastingDeleteText,
          confirmLabel: l.fastingDeleteEntry,
          cancelLabel: l.actionCancel,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const FastEntryResult.deleted());
    }
  }
}
