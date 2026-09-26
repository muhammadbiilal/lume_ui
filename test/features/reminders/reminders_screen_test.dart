/// Reminders on screen: first use, adding, editing, toggling, deleting with
/// Undo, the permission banner, and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_notification_gate.dart';
import 'package:lume/features/reminders/presentation/reminder_sheets.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/features/reminders/presentation/reminder_tool.dart';

import '../../helpers/load_fonts.dart';
import 'reminders_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('starts empty, nothing seeded into a fresh install', (
      WidgetTester t,
    ) async {
      final ReminderWorld w = ReminderWorld();
      await pumpReminders(t, w);
      expect(find.byKey(LumeReminderTool.emptyKey), findsOneWidget);
      expect(w.repo.view().entries, isEmpty);
      w.dispose();
    });
  });

  group('the reference’s composition', () {
    Future<ReminderWorld> seeded(WidgetTester t) async {
      final ReminderWorld w = ReminderWorld();
      await pumpReminders(t, w);
      for (final (String label, int h, int m) in <(String, int, int)>[
        ('Morning pills', 9, 0),
        ('Call home', 18, 30),
        ('Read', 21, 0),
      ]) {
        await w.repo.add(label: label, atHour: h, atMinute: m, zoneId: null);
        await t.pumpAndSettle();
      }
      return w;
    }

    testWidgets('Today names the next one after now (the clock reads 16:41)', (
      WidgetTester t,
    ) async {
      final ReminderWorld w = await seeded(t);
      final LumeSummaryCard card = t.widget<LumeSummaryCard>(
        find.byKey(LumeReminderTool.summaryKey),
      );
      expect(card.kicker, 'Today');
      expect(card.value, '3');
      expect(card.caption, startsWith('Call home at '));
      w.dispose();
    });

    testWidgets('Coming up marks what has passed done, and the next now', (
      WidgetTester t,
    ) async {
      final ReminderWorld w = await seeded(t);
      final List<LumeTimelineEntry> entries = t
          .widget<LumeTimeline>(find.byKey(LumeReminderTool.upcomingKey))
          .entries;
      expect(
        entries.map((LumeTimelineEntry e) => e.state).toList(),
        <LumeTimelineState>[
          LumeTimelineState.done,
          LumeTimelineState.now,
          LumeTimelineState.upcoming,
        ],
      );
      w.dispose();
    });

    testWidgets('the list’s search narrows by label', (WidgetTester t) async {
      final ReminderWorld w = await seeded(t);
      await t.enterText(find.byKey(LumeReminderTool.searchKey), 'call');
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(LumeReminderTool.listKey),
          matching: find.byType(LumeRichRow),
        ),
        findsOneWidget,
      );
      w.dispose();
    });
  });

  group('adding', () {
    testWidgets('opens the sheet, saves, appears in the list', (
      WidgetTester t,
    ) async {
      final ReminderWorld w = ReminderWorld();
      await pumpReminders(t, w);
      await tapShown(t, find.byKey(LumeReminderTool.addKey));
      expect(find.byKey(ReminderSheetKeys.label), findsOneWidget);

      await t.enterText(find.byKey(ReminderSheetKeys.label), 'Take a walk');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(ReminderSheetKeys.save));

      // In the list, and — switched on — in the day's timeline too.
      expect(
        find.descendant(
          of: find.byKey(LumeReminderTool.listKey),
          matching: find.text('Take a walk'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(LumeReminderTool.upcomingKey),
          matching: find.text('Take a walk'),
        ),
        findsOneWidget,
      );
      expect(w.repo.view().entries.single.label, 'Take a walk');
      expect(
        w.scheduler.scheduled,
        contains(w.repo.view().entries.single.id.value),
      );
      w.dispose();
    });
  });

  group('editing', () {
    testWidgets('changes the label in place, not a duplicate row', (
      WidgetTester t,
    ) async {
      final ReminderWorld w = ReminderWorld();
      await pumpReminders(t, w);
      await tapShown(t, find.byKey(LumeReminderTool.addKey));
      await t.enterText(find.byKey(ReminderSheetKeys.label), 'Old name');
      await tapShown(t, find.byKey(ReminderSheetKeys.save));

      final String id = w.repo.view().entries.single.id.value;
      await tapShown(t, find.byKey(LumeReminderTool.row(id)));
      await t.enterText(find.byKey(ReminderSheetKeys.label), 'New name');
      await tapShown(t, find.byKey(ReminderSheetKeys.save));

      expect(w.repo.view().entries, hasLength(1));
      expect(w.repo.view().entries.single.label, 'New name');
      w.dispose();
    });
  });

  group('toggling', () {
    testWidgets('turning it off cancels the schedule but keeps the record', (
      WidgetTester t,
    ) async {
      final ReminderWorld w = ReminderWorld();
      await pumpReminders(t, w);
      await tapShown(t, find.byKey(LumeReminderTool.addKey));
      await t.enterText(find.byKey(ReminderSheetKeys.label), 'Stretch');
      await tapShown(t, find.byKey(ReminderSheetKeys.save));
      final String id = w.repo.view().entries.single.id.value;

      await tapShown(t, find.byKey(LumeReminderTool.toggle(id)));
      expect(w.repo.view().entries.single.enabled, isFalse);
      expect(w.scheduler.scheduled, isNot(contains(id)));
      w.dispose();
    });
  });

  group('deleting', () {
    testWidgets('removes it, and Undo brings it back', (WidgetTester t) async {
      final ReminderWorld w = ReminderWorld();
      await pumpReminders(t, w);
      await tapShown(t, find.byKey(LumeReminderTool.addKey));
      await t.enterText(
        find.byKey(ReminderSheetKeys.label),
        'Water the plants',
      );
      await tapShown(t, find.byKey(ReminderSheetKeys.save));
      final String id = w.repo.view().entries.single.id.value;

      await tapShown(t, find.byKey(LumeReminderTool.row(id)));
      expect(find.byKey(ReminderSheetKeys.delete), findsOneWidget);
      await tapShown(t, find.byKey(ReminderSheetKeys.delete));

      expect(w.repo.view().entries, isEmpty);
      expect(find.text('Undo'), findsOneWidget);
      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().entries, hasLength(1));
      w.dispose();
    });
  });

  group('permission banner', () {
    testWidgets(
      'shown when notifications are not granted, hidden once they are',
      (WidgetTester t) async {
        final ReminderWorld w = ReminderWorld();
        w.gate.now = const LumeNotificationState(
          LumeNotificationAccess.firstRequest,
        );
        await pumpReminders(t, w);
        expect(
          find.byKey(LumeReminderTool.permissionBannerKey),
          findsOneWidget,
        );

        w.gate.answer = const LumeNotificationState(
          LumeNotificationAccess.granted,
        );
        // The "Enable notifications" button is inside the banner's LumeToolState action.
        await t.tap(
          find.byKey(LumeReminderTool.permissionBannerKey),
          warnIfMissed: false,
        );
        await t.pumpAndSettle();
        w.dispose();
      },
    );
  });

  group('language', () {
    testWidgets('Urdu: the empty state is translated', (WidgetTester t) async {
      final ReminderWorld w = ReminderWorld();
      await pumpReminders(t, w, locale: const Locale('ur'));
      expect(find.byKey(LumeReminderTool.emptyKey), findsOneWidget);
      w.dispose();
    });
  });
}
