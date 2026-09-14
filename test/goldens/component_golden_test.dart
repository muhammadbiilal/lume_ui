/// Golden coverage for the component system.
///
/// A golden proves the widget has not changed. It does **not** prove the
/// widget matches Lume — `component_parity_test.dart` does that, against the
/// measurements taken from the rendered prototype. These freeze what parity
/// already agreed, so a later edit that drifts is caught by an image rather
/// than by someone noticing.
///
/// Grouped rather than one-per-component: a sheet of related controls catches
/// spacing and alignment between them, which a component alone cannot.
///
/// Run `flutter test --update-goldens` only when a change to the design is
/// intended and approved.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/theme/lume/lume_colors.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/theme/lume/lume_theme.dart';
import 'package:lume/core/widgets/lume/lume.dart';

import '../helpers/load_fonts.dart';
import '../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// Pumps a sheet and compares it, in one theme and one language.
  Future<void> golden(
    WidgetTester tester,
    String name,
    Widget child, {
    ThemeMode theme = ThemeMode.light,
    Locale locale = const Locale('en'),
    double width = 390,
    double height = 700,
    double textScale = 1.0,
  }) async {
    await pumpLume(
      tester,
      _Sheet(child: child),
      theme: theme,
      locale: locale,
      surface: Size(width, height),
      textScale: textScale,
    );
    await expectLater(
      find.byType(_Sheet),
      matchesGoldenFile('images/$name.png'),
    );
  }

  /// The sheets, each a coherent group rather than one lonely widget.
  final Map<String, (Widget, double)> sheets = <String, (Widget, double)>{
    'actions': (
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LumeButton.accent(label: 'Save', onPressed: () {}),
          const SizedBox(height: 10),
          LumeButton(label: 'Cancel', onPressed: () {}),
          const SizedBox(height: 10),
          LumeButton.danger(label: 'Delete', onPressed: () {}),
          const SizedBox(height: 10),
          const LumeButton.accent(label: 'Save'),
          const SizedBox(height: 10),
          const LumeButton.accent(
            label: 'Save',
            busy: true,
            busyLabel: 'Saving…',
          ),
          const SizedBox(height: 10),
          LumeButton.accent(label: 'Continue', block: true, onPressed: () {}),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              LumeIconButton(
                icon: LumeIcons.share,
                label: 'Share',
                onPressed: () {},
              ),
              const SizedBox(width: 10),
              LumeTextButton(label: 'Save', onPressed: () {}),
              const SizedBox(width: 10),
              LumeButton(label: 'Edit', small: true, onPressed: () {}),
            ],
          ),
          const SizedBox(height: 10),
          LumeFab(label: 'Add', showLabel: true, onPressed: () {}),
        ],
      ),
      520.0,
    ),
    'inputs': (
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LumeSearchField(placeholder: 'Search'),
          SizedBox(height: 16),
          LumeToolField(label: 'Amount', prefix: 'PKR', hint: 'Two decimals'),
          SizedBox(height: 16),
          LumeFormField(label: 'Title', hint: 'What you spent it on'),
          SizedBox(height: 16),
          LumeFormField(label: 'Amount', error: 'Enter an amount above zero'),
          SizedBox(height: 16),
          LumeFormField(label: 'Notes', kind: LumeFieldKind.multiline),
        ],
      ),
      560.0,
    ),
    'selection': (
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              LumeFilterChip(label: 'Everything', selected: true, onTap: () {}),
              LumeFilterChip(label: 'Food', onTap: () {}),
              LumeFilterChip(label: 'Bills', count: 3, onTap: () {}),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            children: <Widget>[
              LumeRecordChip(
                label: 'All',
                count: 34,
                selected: true,
                onTap: () {},
              ),
              LumeRecordChip(label: 'Food', count: 12, onTap: () {}),
            ],
          ),
          const SizedBox(height: 14),
          LumeSegmented(
            items: const <LumeChoice>[
              LumeChoice(value: 'a', label: 'Week'),
              LumeChoice(value: 'b', label: 'Month'),
              LumeChoice(value: 'c', label: 'Year'),
            ],
            value: 'a',
            onChanged: (_) {},
          ),
          const SizedBox(height: 14),
          LumeTabs(
            items: const <LumeChoice>[
              LumeChoice(value: 'a', label: 'All', count: 34),
              LumeChoice(value: 'b', label: 'Due', count: 3),
            ],
            value: 'a',
            onChanged: (_) {},
          ),
          const SizedBox(height: 14),
          LumeSortBar(
            label: 'Sort',
            items: const <LumeChoice>[
              LumeChoice(value: 'a', label: 'Name'),
              LumeChoice(value: 'b', label: 'Date'),
            ],
            value: 'a',
            direction: LumeSortDirection.ascending,
            onChanged: (_, _) {},
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              LumeSwitch(value: true, onChanged: (_) {}),
              const SizedBox(width: 16),
              LumeStepper(
                label: 'People',
                value: '4',
                onDecrement: () {},
                onIncrement: () {},
              ),
            ],
          ),
        ],
      ),
      420.0,
    ),
    'rows': (
      LumeRecordList(
        children: <Widget>[
          LumeRecordRow(
            title: 'Groceries',
            subtitle: 'Food and drink',
            meta: const <String>['Today', 'Cash'],
            value: '1,240',
            initial: 'G',
            onTap: () {},
          ),
          LumeRecordRow(
            title: 'Electricity',
            initial: 'E',
            value: '8,900',
            badge: const LumeBadge(label: 'Due', tone: LumeBadgeTone.warn),
            selected: true,
            onTap: () {},
          ),
          LumeRecordRow(
            title: 'Take the bins out',
            done: true,
            onToggle: (_) {},
          ),
          LumeRows(
            children: <Widget>[
              LumeRichRow(
                title: 'USD',
                subtitle: 'US Dollar',
                meta: const <String>['Buy 277.10', 'Sell 279.40'],
                value: '278.50',
                logo: r'$',
                delta: const LumeDelta(
                  text: '0.4%',
                  direction: LumeDeltaDirection.up,
                ),
                onTap: () {},
                chevron: true,
              ),
              const LumeCompactRow(
                label: 'Fajr',
                value: '05:12',
                icon: LumeIcons.clock,
              ),
            ],
          ),
        ],
      ),
      420.0,
    ),
    'values': (
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LumeSummaryCard(
            kicker: 'Spent this month',
            value: '124,500',
            unit: 'PKR',
            caption: 'Across 34 expenses',
            stats: <LumeStat>[
              LumeStat(value: '34', label: 'Expenses'),
              LumeStat(value: '9', label: 'Categories'),
            ],
          ),
          SizedBox(height: 16),
          LumeMetrics(
            children: <Widget>[
              LumeMetric(value: '128', label: 'Done', icon: LumeIcons.check),
              LumeMetric(value: '12', label: 'Due', icon: LumeIcons.clock),
              LumeMetric(value: '3', label: 'Late', icon: LumeIcons.alert),
            ],
          ),
          SizedBox(height: 16),
          LumeRecordHero(
            kicker: 'Expense',
            value: '1,240',
            title: 'Groceries',
            caption: 'Monday, 7 September',
          ),
        ],
      ),
      560.0,
    ),
    'status': (
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              LumeBadge(label: 'Draft'),
              LumeBadge(label: 'Live', tone: LumeBadgeTone.live),
              LumeBadge(label: 'Paid', tone: LumeBadgeTone.ok),
              LumeBadge(label: 'Due', tone: LumeBadgeTone.warn),
              LumeBadge(label: 'Overdue', tone: LumeBadgeTone.late_),
              LumeBadge(label: 'Off', tone: LumeBadgeTone.off),
            ],
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 14,
            children: <Widget>[
              LumeDelta(text: '2.4%', direction: LumeDeltaDirection.up),
              LumeDelta(text: '1.1%', direction: LumeDeltaDirection.down),
              LumeDelta(text: '0.0%', direction: LumeDeltaDirection.flat),
            ],
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: <Widget>[
              LumeFreshness(label: 'Live'),
              LumeFreshness(
                label: 'Delayed',
                quality: LumeFreshnessQuality.delayed,
              ),
              LumeFreshness(
                label: 'Cached',
                quality: LumeFreshnessQuality.cached,
              ),
            ],
          ),
          SizedBox(height: 14),
          LumeSourceLine(source: 'State Bank', updated: '5 minutes ago'),
          SizedBox(height: 14),
          LumeNoteCard(
            title: 'Saved on this device',
            text: 'Nothing here is sent anywhere.',
          ),
          SizedBox(height: 10),
          LumeNoteCard(
            title: 'Rates are indicative',
            text: 'Your bank may differ.',
            tone: LumeNoteTone.warn,
          ),
        ],
      ),
      480.0,
    ),
    'states': (
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const LumeSkeleton(count: 2),
          const SizedBox(height: 16),
          LumeCollectionState(
            kind: LumeCollectionStateKind.empty,
            title: 'Nothing on your list',
            text: 'Add a task and it will show up here and on Today.',
            primaryAction: LumeButton.accent(
              label: 'Add a task',
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 16),
          LumeNotice(
            kind: LumeNoticeKind.error,
            title: 'Could not save changes',
            text: 'Nothing you typed was lost.',
            actions: <Widget>[
              LumeNoticeAction(label: 'Try again', onPressed: () {}),
            ],
          ),
          const SizedBox(height: 10),
          LumeNotice(
            kind: LumeNoticeKind.warning,
            title: 'This record changed elsewhere',
            text: 'A newer version exists.',
            actions: <Widget>[
              LumeNoticeAction(label: 'Review', onPressed: () {}),
              LumeNoticeAction(label: 'Reload', onPressed: () {}),
            ],
          ),
          const SizedBox(height: 10),
          const LumeOfflineBanner(
            title: 'You are offline',
            text: 'Showing records saved on this device.',
          ),
          const SizedBox(height: 10),
          const LumeToast(
            data: LumeToastData(
              message: 'Expense deleted',
              actionLabel: 'Undo',
            ),
          ),
        ],
      ),
      760.0,
    ),
    'crud': (
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LumeDetailActions(
            editLabel: 'Edit',
            onEdit: () {},
            deleteLabel: 'Delete',
            onDelete: () {},
          ),
          const SizedBox(height: 16),
          const LumeCard(
            child: LumeFactCard(
              facts: <LumeFact>[
                LumeFact(label: 'Category', value: 'Food and drink'),
                LumeFact(label: 'Date', value: 'Monday, 7 September'),
                LumeFact(
                  label: 'Note',
                  value: 'Weekly shop, plus something for the neighbours.',
                  block: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LumeSubmitBar(
            saveLabel: 'Save expense',
            onSave: () {},
            cancelLabel: 'Cancel',
            onCancel: () {},
            note: 'Saved on this device only.',
          ),
        ],
      ),
      620.0,
    ),
    'progress': (
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LumeSegmentedProgress(total: 9, completed: 4),
          SizedBox(height: 18),
          LumeMeterRow(
            label: 'Water today',
            value: '6 of 10',
            progress: 0.6,
            footnote: 'Two more before bed.',
          ),
          SizedBox(height: 18),
          LumeJourney(
            fromCode: 'LHE',
            from: 'Lahore',
            fromTime: '09:00',
            toCode: 'ISB',
            to: 'Islamabad',
            toTime: '13:40',
            remaining: '120 km to run',
            progress: 0.6,
          ),
          SizedBox(height: 18),
          LumeTimeline(
            entries: <LumeTimelineEntry>[
              LumeTimelineEntry(
                time: '09:00',
                title: 'Depart Lahore',
                subtitle: 'Platform 3',
                state: LumeTimelineState.done,
              ),
              LumeTimelineEntry(
                time: '11:20',
                title: 'Faisalabad',
                state: LumeTimelineState.now,
              ),
              LumeTimelineEntry(time: '13:40', title: 'Arrive Islamabad'),
            ],
          ),
          SizedBox(height: 18),
          LumeProgressRing(value: 0.65, label: 'Read'),
        ],
      ),
      520.0,
    ),
    'chrome': (
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LumeToolbar(
            title: 'Currency and gold',
            subtitle: 'Live interbank rates',
            onBack: () {},
            actions: <Widget>[
              LumeIconButton(
                icon: LumeIcons.share,
                label: 'Share',
                onPressed: () {},
              ),
            ],
          ),
          const LumeContextBar(
            gutters: false,
            items: <LumeContextItem>[
              LumeContextItem(label: 'Islamabad', icon: LumeIcons.pin),
              LumeContextItem(label: 'PKR'),
            ],
          ),
          const SizedBox(height: 16),
          LumeSectionHeader(
            title: 'Recent expenses',
            subtitle: 'The last seven days',
            link: 'See all',
            onLinkTap: () {},
          ),
          const SizedBox(height: 16),
          const LumeTable(
            label: 'Prayer times',
            columns: <LumeColumn>[
              LumeColumn(label: 'Prayer', strong: true),
              LumeColumn(label: 'Begins', numeric: true),
            ],
            rows: <List<String>>[
              <String>['Fajr', '05:12'],
              <String>['Dhuhr', '12:04'],
            ],
          ),
        ],
      ),
      480.0,
    ),
  };

  group('light', () {
    sheets.forEach((String name, (Widget, double) sheet) {
      testWidgets(name, (WidgetTester tester) async {
        await golden(tester, '${name}_light', sheet.$1, height: sheet.$2);
      });
    });
  });

  group('dark', () {
    sheets.forEach((String name, (Widget, double) sheet) {
      testWidgets(name, (WidgetTester tester) async {
        await golden(
          tester,
          '${name}_dark',
          sheet.$1,
          theme: ThemeMode.dark,
          height: sheet.$2,
        );
      });
    });
  });

  group('right to left', () {
    // Urdu rather than Arabic: it is the harder of the two here, because the
    // interface falls back to Noto Naskh for it and the line heights move.
    for (final String name in <String>['rows', 'inputs', 'states', 'chrome']) {
      testWidgets(name, (WidgetTester tester) async {
        await golden(
          tester,
          '${name}_rtl',
          sheets[name]!.$1,
          locale: const Locale('ur'),
          height: sheets[name]!.$2,
        );
      });
    }
  });

  group('dynamic type', () {
    for (final String name in <String>['actions', 'rows', 'states']) {
      testWidgets('$name at 200 per cent', (WidgetTester tester) async {
        await golden(
          tester,
          '${name}_x2',
          sheets[name]!.$1,
          textScale: 2.0,
          height: sheets[name]!.$2 * 1.8,
        );
      });
    }
  });

  group('width classes', () {
    for (final (String label, double width) in <(String, double)>[
      ('medium', 700),
      ('expanded', 1100),
    ]) {
      testWidgets('rows at $label', (WidgetTester tester) async {
        await golden(
          tester,
          'rows_$label',
          sheets['rows']!.$1,
          width: width,
          height: sheets['rows']!.$2,
        );
      });
    }
  });
}

/// A page-shaped ground so every golden is measured the same way.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return ColoredBox(
      color: lume.bg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(LumeSpace.pageCompact),
          child: child,
        ),
      ),
    );
  }
}
