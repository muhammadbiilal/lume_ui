/// Reminders — a real, durably-stored record family with a real scheduled
/// notification behind it (`ROLLOUT_WAVE_7.md`, `REMINDERS_PROPOSAL.md`).
///
/// One flat list, like Meal Plan's screen shape: no separate list/detail/
/// form navigation, a tap opens a sheet. What is new here, and nowhere
/// else in this build: the store survives the app closing, and a saved
/// reminder is handed to the platform as a real scheduled notification —
/// so this is also the one screen that has to show the reader when the
/// platform itself is standing between them and that promise (permission
/// refused, exact timing unavailable), rather than only the record layer's
/// own failure states.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/platform_services.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/platform/lume_app_settings.dart';
import '../../../core/platform/lume_notification_gate.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/reminder_providers.dart';
import '../data/reminder_scheduler.dart';
import '../domain/reminder_book.dart';
import '../domain/reminder_failure.dart';
import '../domain/reminder_model.dart';
import '../domain/reminder_repository.dart';
import 'reminder_sheets.dart';
import 'reminder_text.dart';

abstract final class LumeReminderTool {
  static const String id = 'reminders';

  static const Key summaryKey = ValueKey<String>('rem.summary');
  static const Key permissionBannerKey = ValueKey<String>('rem.permission');
  static const Key exactAlarmBannerKey = ValueKey<String>('rem.exactAlarm');
  static const Key listKey = ValueKey<String>('rem.list');
  static const Key emptyKey = ValueKey<String>('rem.empty');
  static const Key addKey = ValueKey<String>('rem.add');
  static const Key searchKey = ValueKey<String>('rem.search');
  static const Key upcomingKey = ValueKey<String>('rem.upcoming');

  static Key row(String id) => ValueKey<String>('rem.row.$id');
  static Key toggle(String id) => ValueKey<String>('rem.toggle.$id');

  static Widget open(LumeToolRequest request) => ReminderTool(request: request);
}

class ReminderTool extends ConsumerStatefulWidget {
  const ReminderTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<ReminderTool> createState() => _ReminderToolState();
}

class _ReminderToolState extends ConsumerState<ReminderTool>
    with WidgetsBindingObserver {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final ReminderRepository _repo = ref.read(reminderRepositoryProvider);
  late final LumeNotificationGate _gate = ref.read(notificationGateProvider);

  LumeNotificationState? _access;

  /// The list's search — `crud-engine.js`'s own, over the label.
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshAccess());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshAccess());
  }

  Future<void> _refreshAccess() async {
    final LumeNotificationState a = await _gate.check();
    if (mounted) setState(() => _access = a);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repo.changes.removeListener(_changed);
    _query.dispose();
    super.dispose();
  }

  void _say(
    String message, {
    LumeToastTone tone = LumeToastTone.success,
    String? actionLabel,
    VoidCallback? onAction,
  }) => _host.currentState?.say(
    message,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  String? _zoneId(BuildContext context) {
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;
    final LumeZoneResolution resolution = ref
        .watch(timeZoneServiceProvider)
        .readerZone(
          startup.profile,
          ref.watch(deviceZoneProvider),
          country: widget.request.user.country,
          city: widget.request.user.city,
        );
    return resolution.zone?.id ?? resolution.canonicalId;
  }

  void _failed(AppLocalizations l, ReminderFailure f) {
    _say(switch (f.kind) {
      ReminderFailureKind.conflict ||
      ReminderFailureKind.notFound => l.remErrConflict,
      _ => l.remErrFailed,
    }, tone: LumeToastTone.error);
  }

  void _reportSchedule(AppLocalizations l, ReminderScheduleOutcome? outcome) {
    switch (outcome) {
      case ReminderScheduleOutcome.zoneUnresolved:
        _say(l.remSavedNoZone, tone: LumeToastTone.info);
      case ReminderScheduleOutcome.failed:
        _say(l.remSavedNoSchedule, tone: LumeToastTone.info);
      case ReminderScheduleOutcome.scheduled:
      case ReminderScheduleOutcome.cancelled:
      case ReminderScheduleOutcome.denied:
      case null:
        _say(l.commonSaved);
    }
  }

  Future<void> _add(AppLocalizations l) async {
    final ReminderDraftResult? d = await reminderEditSheet(
      context,
      title: l.remAddReminder,
      existing: null,
    );
    if (d == null || !mounted) return;
    final ReminderResult<ReminderWrite> r = await _repo.add(
      label: d.label,
      atHour: d.atHour,
      atMinute: d.atMinute,
      repeat: d.repeat,
      notes: d.notes,
      zoneId: _zoneId(context),
    );
    if (!mounted) return;
    if (r.failure != null) return _failed(l, r.failure!);
    _reportSchedule(l, r.value!.scheduleOutcome);
  }

  Future<void> _edit(AppLocalizations l, ReminderEntry e) async {
    final ReminderDraftResult? d = await reminderEditSheet(
      context,
      title: l.remEditReminder,
      existing: e,
    );
    if (d == null || !mounted) return;
    if (reminderSheetIsDelete(d)) return _delete(l, e);
    final ReminderResult<ReminderWrite> r = await _repo.edit(
      e.id,
      label: d.label,
      atHour: d.atHour,
      atMinute: d.atMinute,
      repeat: d.repeat,
      notes: d.notes,
      zoneId: _zoneId(context),
    );
    if (!mounted) return;
    if (r.failure != null) return _failed(l, r.failure!);
    _reportSchedule(l, r.value!.scheduleOutcome);
  }

  Future<void> _toggle(
    AppLocalizations l,
    ReminderEntry e,
    bool enabled,
  ) async {
    final ReminderResult<ReminderWrite> r = await _repo.setEnabled(
      e.id,
      enabled,
      zoneId: _zoneId(context),
    );
    if (!mounted) return;
    if (r.failure != null) return _failed(l, r.failure!);
  }

  Future<void> _delete(AppLocalizations l, ReminderEntry e) async {
    final ReminderResult<ReminderWrite> r = await _repo.remove(e.id);
    if (!mounted) return;
    if (r.failure != null) return _failed(l, r.failure!);
    final String? zoneId = _zoneId(context);
    _say(
      l.remDeletedToast,
      actionLabel: l.recUndo,
      onAction: () => unawaited(_undo(l, r.value!, zoneId)),
    );
  }

  Future<void> _undo(
    AppLocalizations l,
    ReminderWrite w,
    String? zoneId,
  ) async {
    final ReminderResult<void> r = await _repo.undo(w, zoneId: zoneId);
    if (mounted && r.failure != null) _failed(l, r.failure!);
  }

  Future<void> _requestPermission() async {
    final LumeNotificationState a = await _gate.request();
    if (mounted) setState(() => _access = a);
  }

  Future<void> _openSettings() async {
    await const LumeChannelAppSettings().open();
    await _refreshAccess();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: widget.request.user.country,
    );
    final ReminderSnapshot snapshot = _repo.view();

    LumeToolStatus status = LumeToolStatus.ready;
    ReminderBook? book;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed) {
      status = LumeToolStatus.error;
    } else {
      book = snapshot.book;
    }

    return LumeToolScreen(
      key: _host,
      feature: widget.request.feature,
      user: widget.request.user,
      onBack: widget.request.onBack,
      onOpenRelated: widget.request.onOpenRelated,
      status: status,
      onRetry: () => setState(_repo.retry),
      // `UI.fab({ label: 'Add a reminder' })` — the reference's floating
      // add, here opening the real add sheet.
      floating: book == null
          ? null
          : LumeFab(
              key: LumeReminderTool.addKey,
              label: l.remAddReminder,
              icon: LumeIcons.plus,
              onPressed: () => unawaited(_add(l)),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: book == null ? const <Widget>[] : _body(context, l, f, book),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    ReminderBook book,
  ) {
    final LumeNotificationState? access = _access;
    return <Widget>[
      if (access != null && access.access != LumeNotificationAccess.granted)
        LumeToolSection(
          child: LumeToolState(
            key: LumeReminderTool.permissionBannerKey,
            icon: LumeIcons.bellRing,
            title: l.remPermissionTitle,
            text: l.remPermissionText,
            action: LumeButton.accent(
              label: access.access.settingsHelp
                  ? l.remOpenSettings
                  : l.remEnableNotifications,
              onPressed: () => unawaited(
                access.access.settingsHelp
                    ? _openSettings()
                    : _requestPermission(),
              ),
            ),
          ),
        )
      else if (access != null && !access.canScheduleExact)
        LumeToolSection(
          child: LumeToolState(
            key: LumeReminderTool.exactAlarmBannerKey,
            icon: LumeIcons.clock,
            title: l.remExactAlarmTitle,
            text: l.remExactAlarmText,
            action: LumeButton.accent(
              label: l.remOpenSettings,
              onPressed: () => unawaited(
                _gate.openExactAlarmSettings().then((_) => _refreshAccess()),
              ),
            ),
          ),
        ),
      // The engine's own list first, as `engine.js` composes a record
      // tool: its search, then the reader's reminders.
      if (book.isEmpty)
        LumeToolSection(
          child: LumeToolState(
            key: LumeReminderTool.emptyKey,
            icon: LumeIcons.bellRing,
            title: l.remEmptyTitle,
            text: l.remEmptyText,
          ),
        )
      else ...<Widget>[
        LumeToolSection(
          child: LumeSearchField(
            key: LumeReminderTool.searchKey,
            controller: _query,
            placeholder: l.remSearch,
            onChanged: (String _) => setState(() {}),
          ),
        ),
        LumeToolSection(
          child: LumeRows(
            key: LumeReminderTool.listKey,
            children: <Widget>[
              for (final ReminderEntry e in book.sorted)
                if (_query.text.trim().isEmpty ||
                    e.label.toLowerCase().contains(
                      _query.text.trim().toLowerCase(),
                    ))
                  _row(context, l, f, e),
            ],
          ),
        ),
      ],
      // Then the tool's own composition: today, and what is coming up.
      ..._today(context, l, f, book),
    ];
  }

  /// `reminders.tool.js`: "Today", how many are set, and the next one —
  /// then the day as a timeline, what has passed marked done and the next
  /// one marked now. Worked out from the reader's own switched-on
  /// reminders against the injected clock.
  List<Widget> _today(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    ReminderBook book,
  ) {
    final DateTime now = LumeClockScope.of(context).now();
    final int nowMinute = now.hour * 60 + now.minute;
    final List<ReminderEntry> on = <ReminderEntry>[
      for (final ReminderEntry e in book.sorted)
        if (e.enabled) e,
    ];
    int minuteOf(ReminderEntry e) => e.atHour * 60 + e.atMinute;
    final ReminderEntry? next = on
        .where((ReminderEntry e) => minuteOf(e) > nowMinute)
        .firstOrNull;
    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeReminderTool.summaryKey,
          kicker: l.remToday,
          value: f.integer(on.length),
          caption: next == null
              ? l.remNone
              : l.remNext(
                  next.label,
                  ReminderText.time(f, next.atHour, next.atMinute),
                ),
        ),
      ),
      if (on.isNotEmpty)
        LumeToolSection(
          title: l.remUpcoming,
          child: LumeTimeline(
            key: LumeReminderTool.upcomingKey,
            entries: <LumeTimelineEntry>[
              for (final ReminderEntry e in on)
                LumeTimelineEntry(
                  time: ReminderText.time(f, e.atHour, e.atMinute),
                  title: e.label,
                  subtitle: ReminderText.repeat(l, e.repeat),
                  state: minuteOf(e) <= nowMinute
                      ? LumeTimelineState.done
                      : identical(e, next)
                      ? LumeTimelineState.now
                      : LumeTimelineState.upcoming,
                ),
            ],
          ),
        ),
    ];
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    ReminderEntry e,
  ) => LumeRichRow(
    key: LumeReminderTool.row(e.id.value),
    icon: ReminderText.icon(e.repeat),
    title: e.label,
    subtitle: ReminderText.repeat(l, e.repeat),
    value: ReminderText.time(f, e.atHour, e.atMinute),
    trailing: LumeSwitch(
      key: LumeReminderTool.toggle(e.id.value),
      value: e.enabled,
      semanticLabel: e.label,
      onChanged: (bool v) => unawaited(_toggle(l, e, v)),
    ),
    onTap: () => unawaited(_edit(l, e)),
  );
}
