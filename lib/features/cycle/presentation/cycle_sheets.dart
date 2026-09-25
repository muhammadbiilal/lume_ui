/// The sheet for logging a new period, correcting a logged one, or deleting
/// it — Cycle Tracker's only form. Dates are chosen, never typed: the reader
/// picks a day from the platform's own calendar, exactly as a date-of-birth
/// or a due-date field does elsewhere in Lume.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/lume_format.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';

abstract final class CycleSheetKeys {
  static const Key startPicker = ValueKey<String>('cycle.sheet.start');
  static const Key ongoingToggle = ValueKey<String>('cycle.sheet.ongoing');
  static const Key endPicker = ValueKey<String>('cycle.sheet.end');
  static const Key save = ValueKey<String>('cycle.sheet.save');
  static const Key delete = ValueKey<String>('cycle.sheet.delete');
  static const Key cancel = ValueKey<String>('cycle.sheet.cancel');
  static const Key confirmDelete = ValueKey<String>('cycle.sheet.confirmDelete');
}

/// What the sheet decided: save these dates, delete the entry, or (`null`
/// from [CycleEntrySheet.show]) walk away.
@immutable
class CycleEntryResult {
  const CycleEntryResult.saved(LumeDate this.start, this.end) : delete = false;
  const CycleEntryResult.deleted() : start = null, end = null, delete = true;

  final LumeDate? start;
  final LumeDate? end;
  final bool delete;
}

/// Logs a new period, or edits/deletes one already logged.
class CycleEntrySheet extends StatefulWidget {
  const CycleEntrySheet({
    super.key,
    required this.isNew,
    required this.initialStart,
    required this.today,
    this.initialEnd,
    this.earliest,
    this.canDelete = false,
    this.startTaken,
  });

  final bool isNew;
  final LumeDate initialStart;
  final LumeDate? initialEnd;
  final LumeDate today;

  /// How far back the start-date picker reaches. Defaults to ten years.
  final LumeDate? earliest;

  final bool canDelete;

  /// Whether another logged period already starts on this day — disabled in
  /// the picker so the reader cannot create the conflict, rather than
  /// picking it and being told afterwards.
  final bool Function(LumeDate day)? startTaken;

  static Future<CycleEntryResult?> show(
    BuildContext context, {
    required bool isNew,
    required LumeDate initialStart,
    required LumeDate today,
    LumeDate? initialEnd,
    LumeDate? earliest,
    bool canDelete = false,
    bool Function(LumeDate day)? startTaken,
  }) {
    final AppLocalizations l = AppLocalizations.of(context);
    return showLumeSheet<CycleEntryResult>(
      context: context,
      barrierLabel: isNew ? l.cycleLogPeriod : l.cycleEditPeriod,
      child: CycleEntrySheet(
        isNew: isNew,
        initialStart: initialStart,
        initialEnd: initialEnd,
        today: today,
        earliest: earliest,
        canDelete: canDelete,
        startTaken: startTaken,
      ),
    );
  }

  @override
  State<CycleEntrySheet> createState() => _CycleEntrySheetState();
}

class _CycleEntrySheetState extends State<CycleEntrySheet> {
  late LumeDate _start = widget.initialStart;
  late LumeDate? _end = widget.initialEnd;
  late bool _ongoing = widget.initialEnd == null;

  LumeDate get _earliest => widget.earliest ?? widget.today.addDays(-3650);

  Future<void> _pickStart() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _start.toCalendarDateTime(),
      firstDate: _earliest.toCalendarDateTime(),
      lastDate: widget.today.toCalendarDateTime(),
      selectableDayPredicate: widget.startTaken == null
          ? null
          : (DateTime d) => !widget.startTaken!(LumeDate.ofWallClock(d)),
    );
    if (picked == null || !mounted) return;
    final LumeDate next = LumeDate.ofWallClock(picked);
    setState(() {
      _start = next;
      // An end already logged before the new start no longer makes sense;
      // moving the start forward past it clears it rather than leaving a
      // silently invalid range.
      if (_end != null && _end!.isBefore(_start)) _end = null;
    });
  }

  Future<void> _pickEnd() async {
    final LumeDate base = _end ?? (widget.today.isBefore(_start) ? _start : widget.today);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: base.toCalendarDateTime(),
      firstDate: _start.toCalendarDateTime(),
      lastDate: widget.today.toCalendarDateTime(),
    );
    if (picked == null || !mounted) return;
    setState(() => _end = LumeDate.ofWallClock(picked));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context);

    return LumeSheet(
      title: widget.isNew ? l.cycleLogPeriod : l.cycleEditPeriod,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeFormPicker(
            key: CycleSheetKeys.startPicker,
            label: l.cycleStartDateLabel,
            value: f.dateMediumYear(_start.toCalendarDateTime()),
            onTap: _pickStart,
          ),
          const SizedBox(height: 14),
          LumeCheckbox(
            key: CycleSheetKeys.ongoingToggle,
            label: l.cycleStillOngoing,
            value: _ongoing,
            onChanged: (bool v) => setState(() {
              _ongoing = v;
              // Unchecking defaults the end to today (or the start, if the
              // start is somehow later than today) — the overwhelmingly
              // common case — and the picker beside it can still change it.
              _end = v ? null : (widget.today.isBefore(_start) ? _start : widget.today);
            }),
          ),
          if (!_ongoing) ...<Widget>[
            const SizedBox(height: 14),
            LumeFormPicker(
              key: CycleSheetKeys.endPicker,
              label: l.cycleEndDateLabel,
              value: _end == null
                  ? l.cycleEndDateLabel
                  : f.dateMediumYear(_end!.toCalendarDateTime()),
              onTap: _pickEnd,
            ),
          ],
          const SizedBox(height: 18),
          LumeButton.accent(
            key: CycleSheetKeys.save,
            label: l.actionSave,
            block: true,
            onPressed: () => Navigator.of(context).pop(
              CycleEntryResult.saved(_start, _ongoing ? null : _end),
            ),
          ),
          if (widget.canDelete) ...<Widget>[
            const SizedBox(height: 8),
            LumeButton.dangerGhost(
              key: CycleSheetKeys.delete,
              label: l.cycleDeleteEntry,
              block: true,
              onPressed: () => unawaited(_confirmDelete(l)),
            ),
          ],
          const SizedBox(height: 8),
          LumeButton(
            key: CycleSheetKeys.cancel,
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
      barrierLabel: l.cycleDeleteTitle,
      child: LumeSheet(
        confirm: true,
        child: LumeDeleteConfirmation(
          key: CycleSheetKeys.confirmDelete,
          title: l.cycleDeleteTitle,
          consequence: l.cycleDeleteText,
          confirmLabel: l.cycleDeleteEntry,
          cancelLabel: l.actionCancel,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const CycleEntryResult.deleted());
    }
  }
}
