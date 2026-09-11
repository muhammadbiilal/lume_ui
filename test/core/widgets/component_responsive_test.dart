/// Every component, at every width class, in both directions, at both text
/// scales, in both themes.
///
/// This is the sweep that catches the things a per-component test does not: a
/// button that is fine in English and clipped in Urdu, a row that survives one
/// text scale and overflows at two, a chip that mirrors when it should not.
///
/// It is deliberately exhaustive rather than representative. Overflow is cheap
/// to test and expensive to find by eye.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/widgets/lume/lume.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

/// Every component, with realistic content, under one name.
///
/// Long-ish strings on purpose: a component that only ever sees "OK" has not
/// been tested for wrapping.
Map<String, Widget> specimens() => <String, Widget>{
  'button.accent': const LumeButton.accent(label: 'Save this expense'),
  'button.ghost': const LumeButton(label: 'Cancel'),
  'button.danger': const LumeButton.danger(label: 'Delete permanently'),
  'button.block': const LumeButton.accent(
    label: 'Continue to the next step',
    block: true,
  ),
  'button.busy': const LumeButton.accent(
    label: 'Save',
    busy: true,
    busyLabel: 'Saving your changes',
  ),
  'iconButton': const LumeIconButton(icon: LumeIcons.share, label: 'Share'),
  'textButton': const LumeTextButton(label: 'Save'),
  'fab': const LumeFab(label: 'Add an expense', showLabel: true),
  'searchField': const LumeSearchField(placeholder: 'Search your expenses'),
  'toolField': const LumeToolField(
    label: 'Amount to convert',
    hint: 'Up to two decimal places',
    prefix: 'PKR',
  ),
  'formField': const LumeFormField(
    label: 'What did you spend it on?',
    hint: 'A short description helps later',
  ),
  'formField.invalid': const LumeFormField(
    label: 'Amount',
    error: 'Enter an amount greater than zero',
  ),
  'formField.multiline': const LumeFormField(
    label: 'Notes',
    kind: LumeFieldKind.multiline,
  ),
  'checkbox': const LumeCheckbox(
    label: 'Remind me the day before',
    value: true,
  ),
  'radioRow': const LumeRadioRow(
    label: 'Use the device setting',
    subtitle: 'Follows your system appearance',
    selected: true,
  ),
  'switch': const LumeSwitch(value: true, semanticLabel: 'Islamic features'),
  'stepper': const LumeStepper(label: 'People sharing the bill', value: '4'),
  'filterChip': const LumeFilterChip(label: 'Everything', count: 128),
  'recordChip': const LumeRecordChip(label: 'Food and drink', count: 12),
  'segmented': const LumeSegmented(
    items: <LumeChoice>[
      LumeChoice(value: 'a', label: 'This week'),
      LumeChoice(value: 'b', label: 'This month'),
    ],
    value: 'a',
  ),
  'tabs': const LumeTabs(
    items: <LumeChoice>[
      LumeChoice(value: 'a', label: 'Everything', count: 12),
      LumeChoice(value: 'b', label: 'Due soon', count: 3),
    ],
    value: 'a',
  ),
  'sortBar': const LumeSortBar(
    items: <LumeChoice>[
      LumeChoice(value: 'a', label: 'Name'),
      LumeChoice(value: 'b', label: 'Date added'),
    ],
    value: 'a',
    direction: LumeSortDirection.ascending,
    label: 'Sort',
  ),
  'card': const LumeCard(child: Text('A card with something inside it')),
  'noteCard': const LumeNoteCard(
    title: 'Saved on this device',
    text: 'Nothing here is sent anywhere, and nothing appears on Home.',
  ),
  'sectionHeader': const LumeSectionHeader(
    title: 'Recent expenses',
    subtitle: 'The last seven days',
    link: 'See all',
  ),
  'summaryCard': const LumeSummaryCard(
    kicker: 'Spent this month',
    value: '124,500',
    unit: 'PKR',
    caption: 'Across 34 expenses in nine categories',
    stats: <LumeStat>[
      LumeStat(value: '34', label: 'Expenses'),
      LumeStat(value: '9', label: 'Categories'),
    ],
  ),
  'metric': const LumeMetric(
    value: '128',
    label: 'Tasks completed',
    icon: LumeIcons.check,
  ),
  'recordHero': const LumeRecordHero(
    kicker: 'Expense',
    value: '1,240',
    title: 'Groceries at the corner shop',
    caption: 'Monday, 7 September',
  ),
  'factCard': const LumeFactCard(
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
  'richRow': const LumeRichRow(
    title: 'United States Dollar',
    subtitle: 'Interbank rate',
    meta: <String>['Buy 277.10', 'Sell 279.40'],
    value: '278.50',
    icon: LumeIcons.currency,
    chevron: true,
  ),
  'compactRow': const LumeCompactRow(label: 'Fajr', value: '05:12'),
  'recordRow': const LumeRecordRow(
    title: 'Groceries at the corner shop',
    subtitle: 'Food and drink',
    meta: <String>['Today', 'Cash'],
    value: '1,240',
    initial: 'G',
  ),
  'recordRow.done': LumeRecordRow(
    title: 'Take the bins out',
    done: true,
    onToggle: (_) {},
  ),
  'expandRow': const LumeExpandRow(
    header: Text('How this is calculated'),
    child: Text('The detail'),
  ),
  'badge': const LumeBadge(label: 'Overdue', tone: LumeBadgeTone.late_),
  'delta': const LumeDelta(text: '2.4%', direction: LumeDeltaDirection.up),
  'freshness': const LumeFreshness(
    label: 'Updated 5 minutes ago',
    quality: LumeFreshnessQuality.cached,
  ),
  'sourceLine': const LumeSourceLine(
    source: 'State Bank of Pakistan',
    updated: '5 minutes ago',
  ),
  'detailAction': const LumeDetailAction(
    label: 'Edit this expense',
    icon: LumeIcons.note,
  ),
  'listCount': const LumeListCount(label: '34 expenses this month'),
  'toolState': const LumeToolState(
    title: 'Nothing to show yet',
    text: 'Add your first record and it will appear here.',
  ),
  'collectionState': const LumeCollectionState(
    kind: LumeCollectionStateKind.empty,
    title: 'Nothing on your list',
    text: 'Add a task and it will show up here and on Today.',
  ),
  'notice.error': const LumeNotice(
    kind: LumeNoticeKind.error,
    title: 'Could not save your changes',
    text: 'Nothing you typed was lost. Try again.',
  ),
  'noticeAction': const LumeNoticeAction(label: 'Try again'),
  'offlineBanner': const LumeOfflineBanner(
    title: 'You are offline',
    text: 'Showing records saved on this device.',
  ),
  'skeleton': const LumeSkeleton(count: 2),
  'privateState': const LumePrivateState(
    title: 'Health, documents and money',
    text: 'Only on this device, only for you.',
    revealLabel: 'Show',
  ),
  'toast': const LumeToast(
    data: LumeToastData(message: 'Expense deleted', actionLabel: 'Undo'),
  ),
  'deleteConfirmation': const LumeDeleteConfirmation(
    title: 'Delete Groceries?',
    consequence: 'You can undo this straight afterwards.',
    confirmLabel: 'Delete',
    cancelLabel: 'Keep it',
  ),
  'submitBar': const LumeSubmitBar(
    saveLabel: 'Save this expense',
    cancelLabel: 'Cancel',
    note: 'Saved on this device only.',
  ),
  'progressBar': const LumeProgressBar(value: 0.4, label: 'Water'),
  'meterRow': const LumeMeterRow(
    label: 'Water today',
    value: '6 of 10 glasses',
    progress: 0.6,
  ),
  'progressRing': const LumeProgressRing(value: 0.65, label: 'Read'),
  'segmentedProgress': const LumeSegmentedProgress(total: 9, completed: 4),
  'timeline': const LumeTimeline(
    entries: <LumeTimelineEntry>[
      LumeTimelineEntry(
        time: '09:00',
        title: 'Depart Lahore',
        subtitle: 'Platform 3',
        state: LumeTimelineState.done,
      ),
      LumeTimelineEntry(
        time: '13:40',
        title: 'Arrive Islamabad',
        state: LumeTimelineState.now,
      ),
    ],
  ),
  'journey': const LumeJourney(
    steps: <LumeJourneyStep>[
      LumeJourneyStep(label: 'Sent', done: true),
      LumeJourneyStep(label: 'In transit', current: true),
      LumeJourneyStep(label: 'Delivered'),
    ],
  ),
  'table': const LumeTable(
    label: 'Prayer times',
    columns: <LumeColumn>[
      LumeColumn(label: 'Prayer', strong: true),
      LumeColumn(label: 'Time', numeric: true),
    ],
    rows: <List<String>>[
      <String>['Fajr', '05:12'],
      <String>['Dhuhr', '12:04'],
    ],
  ),
  'imageCard': const LumeImageCard(
    title: 'What the new fuel prices mean for you',
    kicker: 'News',
    meta: '4 minute read',
    seed: 3,
  ),
  'relatedTools': const LumeRelatedTools(
    tools: <LumeRelatedTool>[
      LumeRelatedTool(
        id: 'calculator',
        name: 'Calculator',
        icon: LumeIcons.calculator,
      ),
      LumeRelatedTool(
        id: 'converter',
        name: 'Unit Converter',
        icon: LumeIcons.ruler,
      ),
    ],
  ),
  'toolbar': const LumeToolbar(
    title: 'Currency and gold',
    subtitle: 'Live interbank rates',
  ),
  'contextBar': const LumeContextBar(
    items: <LumeContextItem>[
      LumeContextItem(label: 'Islamabad', icon: LumeIcons.pin),
      LumeContextItem(label: 'PKR'),
    ],
  ),
  'backButton': LumeBackButton(onPressed: () {}),
  'sheet': const LumeSheet(
    title: 'Choose a category',
    child: Text('The body of the sheet'),
  ),
};

void main() {
  setUpAll(loadLumeFonts);

  final Map<String, Widget> all = specimens();

  /// A component never gets the whole screen. It gets a column of page width,
  /// which is the constraint it actually lives under.
  Future<void> place(
    WidgetTester tester,
    Widget widget, {
    required Size surface,
    required Locale locale,
    required ThemeMode theme,
    required double textScale,
  }) => pumpLume(
    tester,
    SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(LumeSpace.pageCompact),
        child: widget,
      ),
    ),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
  );

  group('every component lays out at every width class', () {
    const Map<String, Size> widths = <String, Size>{
      'narrow 359': LumeViewport.narrow,
      'phone 390': LumeViewport.phone,
      'medium 700': LumeViewport.medium,
      'expanded 1100': LumeViewport.expanded,
      'landscape phone 852x393': LumeViewport.landscapePhone,
    };

    widths.forEach((String label, Size size) {
      testWidgets('at $label', (WidgetTester tester) async {
        for (final MapEntry<String, Widget> e in all.entries) {
          await place(
            tester,
            e.value,
            surface: size,
            locale: const Locale('en'),
            theme: ThemeMode.light,
            textScale: 1.0,
          );
          final Object? problem = tester.takeException();
          expect(problem, isNull, reason: '${e.key} at $label: $problem');
        }
      });
    });
  });

  group('every component lays out in every language', () {
    for (final String code in <String>['en', 'ur', 'ar']) {
      testWidgets('in $code', (WidgetTester tester) async {
        for (final MapEntry<String, Widget> e in all.entries) {
          await place(
            tester,
            e.value,
            surface: LumeViewport.phone,
            locale: Locale(code),
            theme: ThemeMode.light,
            textScale: 1.0,
          );
          final Object? problem = tester.takeException();
          expect(problem, isNull, reason: '${e.key} in $code: $problem');
        }
      });
    }
  });

  group('every component lays out in both themes', () {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('in ${mode.name}', (WidgetTester tester) async {
        for (final MapEntry<String, Widget> e in all.entries) {
          await place(
            tester,
            e.value,
            surface: LumeViewport.phone,
            locale: const Locale('en'),
            theme: mode,
            textScale: 1.0,
          );
          final Object? problem = tester.takeException();
          expect(problem, isNull, reason: '${e.key} in ${mode.name}: $problem');
        }
      });
    }
  });

  group('every component survives 200 per cent text', () {
    // §9 and §4 both ask for at least 200 % without clipping. This is the
    // cheapest place to find out which component does not.
    for (final (String label, Size size) in <(String, Size)>[
      ('phone', LumeViewport.phone),
      ('narrow', LumeViewport.narrow),
    ]) {
      testWidgets('at $label width', (WidgetTester tester) async {
        for (final MapEntry<String, Widget> e in all.entries) {
          await place(
            tester,
            e.value,
            surface: size,
            locale: const Locale('en'),
            theme: ThemeMode.light,
            textScale: 2.0,
          );
          final Object? problem = tester.takeException();
          expect(
            problem,
            isNull,
            reason: '${e.key} at 200% on $label: $problem',
          );
        }
      });
    }

    testWidgets('and 200 per cent in Urdu', (WidgetTester tester) async {
      // The hardest cell: the longest strings, the tallest script and the
      // largest type at once.
      for (final MapEntry<String, Widget> e in all.entries) {
        await place(
          tester,
          e.value,
          surface: LumeViewport.phone,
          locale: const Locale('ur'),
          theme: ThemeMode.light,
          textScale: 2.0,
        );
        final Object? problem = tester.takeException();
        expect(problem, isNull, reason: '${e.key} at 200% in ur: $problem');
      }
    });
  });

  group('direction', () {
    testWidgets('a row puts its lead on the start edge in both directions', (
      WidgetTester tester,
    ) async {
      Future<double> leadX(String code) async {
        await place(
          tester,
          const LumeRecordRow(title: 'Groceries', initial: 'G'),
          surface: LumeViewport.phone,
          locale: Locale(code),
          theme: ThemeMode.light,
          textScale: 1.0,
        );
        return tester.getTopLeft(find.text('G')).dx;
      }

      final double ltr = await leadX('en');
      final double rtl = await leadX('ar');
      expect(
        rtl,
        greaterThan(ltr),
        reason: 'the initial disc follows the reading direction',
      );
    });

    testWidgets('a row value sits on the end edge in both directions', (
      WidgetTester tester,
    ) async {
      Future<double> valueX(String code) async {
        await place(
          tester,
          const LumeRecordRow(title: 'G', initial: 'G', value: '1,240'),
          surface: LumeViewport.phone,
          locale: Locale(code),
          theme: ThemeMode.light,
          textScale: 1.0,
        );
        return tester.getTopLeft(find.text('1,240')).dx;
      }

      expect(await valueX('ar'), lessThan(await valueX('en')));
    });

    testWidgets('a numeric value does not reorder in RTL', (
      WidgetTester tester,
    ) async {
      await place(
        tester,
        const LumeCompactRow(label: 'Balance', value: '1,240.50  16:41'),
        surface: LumeViewport.phone,
        locale: const Locale('ur'),
        theme: ThemeMode.light,
        textScale: 1.0,
      );
      expect(
        Directionality.of(tester.element(find.text('1,240.50  16:41'))),
        TextDirection.ltr,
        reason: 'the run is isolated, so the price and the time keep order',
      );
    });
  });

  group('touch targets', () {
    testWidgets('every interactive component clears 44 px', (
      WidgetTester tester,
    ) async {
      final Map<String, Widget> interactive = <String, Widget>{
        'button': LumeButton(label: 'Go', onPressed: () {}),
        'iconButton': LumeIconButton(
          icon: LumeIcons.share,
          label: 'Share',
          onPressed: () {},
        ),
        'textButton': LumeTextButton(label: 'Save', onPressed: () {}),
        'filterChip': LumeFilterChip(label: 'All', onTap: () {}),
        'recordChip': LumeRecordChip(label: 'Food', onTap: () {}),
        'checkbox': LumeCheckbox(
          label: 'Remind me',
          value: false,
          onChanged: (_) {},
        ),
        'switch': LumeSwitch(value: false, onChanged: (_) {}),
        'radioRow': LumeRadioRow(
          label: 'Metric',
          selected: false,
          onTap: () {},
        ),
        'backButton': LumeBackButton(onPressed: () {}),
        'detailAction': LumeDetailAction(label: 'Edit', onPressed: () {}),
        'noticeAction': LumeNoticeAction(label: 'Retry', onPressed: () {}),
        'recordRow': LumeRecordRow(title: 'G', initial: 'G', onTap: () {}),
        'compactRow': LumeCompactRow(label: 'Fajr', onTap: () {}),
        'stepper': LumeStepper(
          label: 'People',
          value: '2',
          onIncrement: () {},
          onDecrement: () {},
        ),
      };

      for (final MapEntry<String, Widget> e in interactive.entries) {
        await place(
          tester,
          Align(alignment: AlignmentDirectional.centerStart, child: e.value),
          surface: LumeViewport.phone,
          locale: const Locale('en'),
          theme: ThemeMode.light,
          textScale: 1.0,
        );
        final Size size = tester.getSize(find.byWidget(e.value));
        expect(
          size.height,
          greaterThanOrEqualTo(LumeSpace.tap),
          reason: '${e.key} is ${size.height} tall — under the 44 px floor',
        );
      }
    });
  });

  group('text does not clip', () {
    testWidgets('a long record title ellipsises rather than overflowing', (
      WidgetTester tester,
    ) async {
      await place(
        tester,
        const LumeRecordRow(
          title:
              'An extremely long record title that will not fit on one '
              'line at any phone width whatsoever',
          initial: 'A',
          value: '1,240',
        ),
        surface: LumeViewport.narrow,
        locale: const Locale('en'),
        theme: ThemeMode.light,
        textScale: 1.0,
      );
      expectNoOverflow(tester);
      expect(lineCountOf(tester, find.textContaining('extremely')), 1);
    });

    testWidgets('a long button label ellipsises', (WidgetTester tester) async {
      await place(
        tester,
        const LumeButton.accent(
          label: 'A button label far longer than the button it sits in',
          block: true,
        ),
        surface: LumeViewport.narrow,
        locale: const Locale('en'),
        theme: ThemeMode.light,
        textScale: 1.0,
      );
      expectNoOverflow(tester);
    });
  });
}
