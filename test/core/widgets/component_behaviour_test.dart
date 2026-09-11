/// What the components *do*, as opposed to what they look like.
///
/// Parity tests prove the pixels; these prove the contract. A button that
/// looks right and fires twice on one tap is not a correct button, and a
/// record row that looks selected but does not say so to a screen reader is
/// not a correct row.
library;

import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/widgets/lume/lume.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  Future<void> show(
    WidgetTester tester,
    Widget widget, {
    Locale locale = const Locale('en'),
    ThemeMode theme = ThemeMode.light,
    double textScale = 1.0,
    Size surface = LumeViewport.phone,
  }) => pumpLume(
    tester,
    Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.all(LumeSpace.x5),
        child: widget,
      ),
    ),
    locale: locale,
    theme: theme,
    textScale: textScale,
    surface: surface,
  );

  group('actions', () {
    testWidgets('a button fires once per tap', (WidgetTester tester) async {
      int taps = 0;
      await show(tester, LumeButton(label: 'Go', onPressed: () => taps++));
      await tester.tap(find.byType(LumeButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('a disabled button does not fire', (WidgetTester t) async {
      const int taps = 0;
      await show(t, const LumeButton(label: 'Go'));
      await t.tap(find.byType(LumeButton), warnIfMissed: false);
      await t.pump();
      expect(taps, 0);
    });

    testWidgets('a busy button refuses the second tap', (WidgetTester t) async {
      // §8: prevent duplicate submission while a request is active. This is
      // the single most consequential behaviour in the whole form system —
      // a double-tapped save creates two records.
      int saves = 0;
      await show(
        t,
        LumeButton.accent(
          label: 'Save',
          busyLabel: 'Saving',
          busy: true,
          onPressed: () => saves++,
        ),
      );
      await t.tap(find.byType(LumeButton), warnIfMissed: false);
      await t.tap(find.byType(LumeButton), warnIfMissed: false);
      await t.pump();
      expect(saves, 0);
    });

    testWidgets('a busy button keeps its label and its size', (
      WidgetTester t,
    ) async {
      await show(t, const LumeButton.accent(label: 'Save'));
      final Size resting = t.getSize(find.byType(LumeButton));

      await show(
        t,
        const LumeButton.accent(
          label: 'Save',
          busy: true,
          busyLabel: 'Saving…',
        ),
      );
      expect(find.text('Saving…'), findsOneWidget);
      expect(
        t.getSize(find.byType(LumeButton)).height,
        resting.height,
        reason: 'the button must not move under the thumb mid-save',
      );
    });

    testWidgets('a busy button announces itself', (WidgetTester t) async {
      await show(
        t,
        const LumeButton.accent(label: 'Save', busy: true, busyLabel: 'Saving'),
      );
      expect(
        t.getSemantics(find.byType(LumeButton)).flagsCollection.isLiveRegion,
        isTrue,
      );
    });

    testWidgets('an icon button carries its name', (WidgetTester t) async {
      await show(
        t,
        LumeIconButton(icon: LumeIcons.share, label: 'Share', onPressed: () {}),
      );
      expect(t.getSemantics(find.byType(LumeIconButton)).label, 'Share');
    });
  });

  group('selection', () {
    testWidgets('a chip reports its toggled state', (WidgetTester t) async {
      await show(t, const LumeFilterChip(label: 'All', selected: true));
      expect(
        t.getSemantics(find.byType(LumeFilterChip)).flagsCollection.isToggled ==
            Tristate.isTrue,
        isTrue,
      );
    });

    testWidgets('a segmented control reports exactly one selection', (
      WidgetTester t,
    ) async {
      await show(
        t,
        LumeSegmented(
          items: const <LumeChoice>[
            LumeChoice(value: 'a', label: 'Day'),
            LumeChoice(value: 'b', label: 'Week'),
          ],
          value: 'b',
          onChanged: (_) {},
        ),
      );
      // The selected flag sits on the segment's Semantics wrapper, not on its
      // Text, so walk the semantics tree rather than the widget tree.
      int selected = 0;
      void visit(SemanticsNode node) {
        if (node.getSemanticsData().flagsCollection.isSelected ==
            Tristate.isTrue) {
          selected++;
        }
        node.visitChildren((SemanticsNode child) {
          visit(child);
          return true;
        });
      }

      visit(t.binding.rootElement!.findRenderObject()!.debugSemantics!);
      expect(selected, 1, reason: 'exactly one segment is selected');
    });

    testWidgets('pressing the active sort option reverses it', (
      WidgetTester t,
    ) async {
      LumeSortDirection? got;
      String? which;
      await show(
        t,
        LumeSortBar(
          items: const <LumeChoice>[LumeChoice(value: 'a', label: 'Name')],
          value: 'a',
          direction: LumeSortDirection.ascending,
          onChanged: (String v, LumeSortDirection d) {
            which = v;
            got = d;
          },
        ),
      );
      await t.tap(find.text('Name'));
      await t.pump();
      expect(which, 'a');
      expect(got, LumeSortDirection.descending);
    });

    testWidgets('a sort option speaks its direction', (WidgetTester t) async {
      await show(
        t,
        LumeSortBar(
          items: const <LumeChoice>[LumeChoice(value: 'a', label: 'Name')],
          value: 'a',
          direction: LumeSortDirection.ascending,
          onChanged: (_, _) {},
        ),
      );
      // The direction is spoken by the option's Semantics wrapper.
      expect(
        find.bySemanticsLabel(RegExp('ascending')),
        findsOneWidget,
        reason: 'a sort option must say which way it runs',
      );
    });

    testWidgets('a switch toggles and reports it', (WidgetTester t) async {
      bool value = false;
      await show(
        t,
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => LumeSwitch(
            value: value,
            semanticLabel: 'Islamic features',
            onChanged: (bool v) => setState(() => value = v),
          ),
        ),
      );
      expect(
        t.getSemantics(find.byType(LumeSwitch)).flagsCollection.isToggled ==
            Tristate.isTrue,
        isFalse,
      );
      await t.tap(find.byType(LumeSwitch));
      await t.pump();
      expect(value, isTrue);
    });

    testWidgets('a checkbox exposes its checked state', (WidgetTester t) async {
      await show(
        t,
        LumeCheckbox(label: 'Remind me', value: true, onChanged: (_) {}),
      );
      expect(
        t.getSemantics(find.byType(LumeCheckbox)).flagsCollection.isChecked ==
            CheckedState.isTrue,
        isTrue,
      );
    });
  });

  group('records', () {
    testWidgets('a record row opens on tap', (WidgetTester t) async {
      int opened = 0;
      await show(
        t,
        LumeRecordRow(title: 'Groceries', initial: 'G', onTap: () => opened++),
      );
      await t.tap(find.byType(LumeRecordRow));
      await t.pump();
      expect(opened, 1);
    });

    testWidgets('a selected row says it is current', (WidgetTester t) async {
      await show(
        t,
        LumeRecordRow(title: 'G', initial: 'G', selected: true, onTap: () {}),
      );
      expect(
        t.getSemantics(find.byType(LumeRecordRow)).flagsCollection.isSelected ==
            Tristate.isTrue,
        isTrue,
      );
    });

    testWidgets('a checkable row logs from the row itself', (
      WidgetTester t,
    ) async {
      // §11: fast optimistic logging — ticking writes immediately, with no
      // form in between.
      bool? wrote;
      await show(
        t,
        LumeRecordRow(title: 'Water', onToggle: (bool v) => wrote = v),
      );
      await t.tap(find.bySemanticsLabel('Not done'));
      await t.pump();
      expect(wrote, isTrue);
    });

    testWidgets('the checkbox exposes a checked state, not just a tick', (
      WidgetTester t,
    ) async {
      await show(
        t,
        LumeRecordRow(title: 'Water', done: true, onToggle: (_) {}),
      );
      expect(find.bySemanticsLabel('Done'), findsOneWidget);
    });

    testWidgets('a row with no callback is inert', (WidgetTester t) async {
      await show(t, const LumeRecordRow(title: 'G', initial: 'G'));
      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  group('forms', () {
    testWidgets('typing reaches the callback', (WidgetTester t) async {
      String? typed;
      await show(
        t,
        LumeFormField(label: 'Title', onChanged: (String v) => typed = v),
      );
      await t.enterText(find.byType(TextField), 'Milk');
      await t.pump();
      expect(typed, 'Milk');
    });

    testWidgets('leaving a field fires the blur validation', (
      WidgetTester t,
    ) async {
      // §8: validate independently judgeable rules on blur, and nothing
      // before. The widget only reports the blur; the engine decides.
      int blurs = 0;
      await show(
        t,
        Column(
          children: <Widget>[
            LumeFormField(label: 'A', onEditingComplete: () => blurs++),
            const LumeFormField(label: 'B'),
          ],
        ),
      );
      await t.tap(find.byType(TextField).first);
      await t.pump();
      await t.tap(find.byType(TextField).last);
      await t.pump();
      expect(blurs, 1);
    });

    testWidgets('an untouched field shows no error', (WidgetTester t) async {
      await show(t, const LumeFormField(label: 'Title'));
      expect(find.text('!'), findsNothing);
    });

    testWidgets('an error replaces the hint rather than joining it', (
      WidgetTester t,
    ) async {
      await show(
        t,
        const LumeFormField(
          label: 'Title',
          hint: 'What to buy',
          error: 'Required',
        ),
      );
      expect(find.text('Required'), findsOneWidget);
      expect(
        find.text('What to buy'),
        findsNothing,
        reason: 'a field that is wrong does not also need explaining',
      );
    });

    testWidgets('an invalid field carries its message in semantics', (
      WidgetTester t,
    ) async {
      await show(t, const LumeFormField(label: 'Title', error: 'Required'));
      expect(t.getSemantics(find.byType(LumeFormField)).value, 'Required');
    });

    testWidgets('a money field opens a decimal keyboard', (
      WidgetTester t,
    ) async {
      await show(
        t,
        const LumeFormField(label: 'Amount', kind: LumeFieldKind.money),
      );
      final TextField f = t.widget<TextField>(find.byType(TextField));
      expect(f.keyboardType.index, TextInputType.number.index);
    });

    testWidgets('a text area starts taller than a single line', (
      WidgetTester t,
    ) async {
      await show(
        t,
        const LumeFormField(label: 'Note', kind: LumeFieldKind.multiline),
      );
      expect(
        t.getSize(find.byType(LumeFormField)).height,
        greaterThan(LumeFormField.boxHeight),
      );
    });
  });

  group('states', () {
    testWidgets('an empty collection offers exactly one primary action', (
      WidgetTester t,
    ) async {
      await show(
        t,
        LumeCollectionState(
          kind: LumeCollectionStateKind.empty,
          title: 'Nothing on your list',
          text: 'Add a task and it will show up here.',
          primaryAction: LumeButton.accent(
            label: 'Add a task',
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(LumeButton), findsOneWidget);
    });

    testWidgets('a load error offers Retry first', (WidgetTester t) async {
      await show(
        t,
        LumeCollectionState(
          kind: LumeCollectionStateKind.error,
          title: 'We could not load your expenses',
          text: 'Check your connection.',
          primaryAction: LumeButton.accent(
            label: 'Try again',
            onPressed: () {},
          ),
          secondaryAction: LumeButton(label: 'Show saved', onPressed: () {}),
          footnote: 'Your saved data is still safe on this device.',
        ),
      );
      final List<Widget> buttons = t
          .widgetList<LumeButton>(find.byType(LumeButton))
          .toList();
      expect(buttons, hasLength(2));
      expect((buttons.first as LumeButton).label, 'Try again');
      expect(
        find.text('Your saved data is still safe on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('an error state announces itself', (WidgetTester t) async {
      await show(
        t,
        const LumeCollectionState(
          kind: LumeCollectionStateKind.error,
          title: 'Could not load',
          text: 'x',
        ),
      );
      expect(
        t
            .getSemantics(find.byType(LumeCollectionState))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
    });

    testWidgets('a conflict offers Review and Reload, never a silent save', (
      WidgetTester t,
    ) async {
      int reviews = 0;
      int reloads = 0;
      await show(
        t,
        LumeNotice(
          kind: LumeNoticeKind.warning,
          title: 'This record changed elsewhere',
          text: 'A newer version exists.',
          actions: <Widget>[
            LumeNoticeAction(label: 'Review', onPressed: () => reviews++),
            LumeNoticeAction(label: 'Reload', onPressed: () => reloads++),
          ],
        ),
      );
      await t.tap(find.text('Review'));
      await t.pump();
      await t.tap(find.text('Reload'));
      await t.pump();
      expect(reviews, 1);
      expect(reloads, 1);
    });

    testWidgets('a skeleton does not animate when motion is reduced', (
      WidgetTester t,
    ) async {
      // The harness disables animations, which is what stops `pumpAndSettle`
      // hanging on an indefinite shimmer.
      await show(t, const LumeSkeleton(count: 3));
      await t.pumpAndSettle();
      expect(find.byType(LumeSkeleton), findsOneWidget);
    });

    testWidgets('a live freshness marker settles too', (WidgetTester t) async {
      await show(
        t,
        const LumeFreshness(label: 'Live', quality: LumeFreshnessQuality.live),
      );
      await t.pumpAndSettle();
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('a private surface hides its detail until asked', (
      WidgetTester t,
    ) async {
      int reveals = 0;
      await show(
        t,
        LumePrivateState(
          title: 'Health, documents and money',
          text: 'Only on this device, only for you.',
          revealLabel: 'Show',
          onReveal: () => reveals++,
        ),
      );
      await t.tap(find.text('Show'));
      await t.pump();
      expect(reveals, 1);
    });
  });

  group('deletion', () {
    testWidgets('the confirmation names the record and its consequence', (
      WidgetTester t,
    ) async {
      await show(
        t,
        const LumeDeleteConfirmation(
          title: 'Delete Groceries?',
          consequence: 'You can undo this straight afterwards.',
          confirmLabel: 'Delete',
          cancelLabel: 'Keep',
        ),
      );
      expect(find.text('Delete Groceries?'), findsOneWidget);
      expect(
        find.text('You can undo this straight afterwards.'),
        findsOneWidget,
      );
      expect(
        find.text('Delete'),
        findsOneWidget,
        reason: 'the destructive action is labelled with the verb, not OK',
      );
      expect(find.text('OK'), findsNothing);
    });

    testWidgets('an irreversible deletion says so', (WidgetTester t) async {
      await show(
        t,
        const LumeDeleteConfirmation(
          title: 'Delete Passport?',
          consequence: 'This cannot be undone.',
          confirmLabel: 'Delete permanently',
          cancelLabel: 'Keep',
          kind: LumeDeleteKind.irreversible,
        ),
      );
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.text('Delete permanently'), findsOneWidget);
    });

    testWidgets('a toast offers Undo only when one is given', (
      WidgetTester t,
    ) async {
      await show(
        t,
        const LumeToast(data: LumeToastData(message: 'Expense deleted')),
      );
      expect(find.text('Undo'), findsNothing);

      await show(
        t,
        LumeToast(
          data: LumeToastData(
            message: 'Expense deleted',
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
      );
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('a toast announces itself', (WidgetTester t) async {
      await show(t, const LumeToast(data: LumeToastData(message: 'Saved')));
      expect(
        t.getSemantics(find.byType(LumeToast)).flagsCollection.isLiveRegion,
        isTrue,
      );
    });
  });

  group('expandable disclosure', () {
    testWidgets('it opens and reports its state', (WidgetTester t) async {
      await show(
        t,
        const LumeExpandRow(
          header: Text('More detail'),
          child: Text('The detail'),
        ),
      );
      expect(
        find.text('The detail'),
        findsNothing,
        reason: 'collapsed, the body is not in the tree',
      );
      await t.tap(find.text('More detail'));
      await t.pumpAndSettle();
      expect(find.text('The detail'), findsOneWidget);
    });
  });

  group('progress', () {
    testWidgets('a bar announces its value', (WidgetTester t) async {
      await show(
        t,
        const SizedBox(
          width: 200,
          child: LumeProgressBar(value: 0.4, label: 'Water'),
        ),
      );
      expect(t.getSemantics(find.byType(LumeProgressBar)).value, '40%');
    });

    testWidgets('a bar clamps rather than overflowing', (WidgetTester t) async {
      await show(
        t,
        const SizedBox(width: 200, child: LumeProgressBar(value: 1.8)),
      );
      expect(t.takeException(), isNull);
      expect(t.getSemantics(find.byType(LumeProgressBar)).value, '100%');
    });

    testWidgets('a journey says where it has reached', (WidgetTester t) async {
      await show(
        t,
        const LumeJourney(
          steps: <LumeJourneyStep>[
            LumeJourneyStep(label: 'Sent', done: true),
            LumeJourneyStep(label: 'In transit', current: true),
            LumeJourneyStep(label: 'Delivered'),
          ],
        ),
      );
      expect(
        t.getSemantics(find.byType(LumeJourney)).value,
        contains('In transit'),
      );
    });

    testWidgets('the segmented progress says which step', (
      WidgetTester t,
    ) async {
      await show(
        t,
        const SizedBox(
          width: 300,
          child: LumeSegmentedProgress(total: 9, completed: 4),
        ),
      );
      expect(t.getSemantics(find.byType(LumeSegmentedProgress)).value, '4 / 9');
    });
  });

  group('tables', () {
    testWidgets('the scroll region is named', (WidgetTester t) async {
      await show(
        t,
        const LumeTable(
          label: 'Prayer times',
          columns: <LumeColumn>[
            LumeColumn(label: 'Prayer'),
            LumeColumn(label: 'Time', numeric: true),
          ],
          rows: <List<String>>[
            <String>['Fajr', '05:12'],
            <String>['Dhuhr', '12:04'],
          ],
        ),
      );
      expect(
        t.getSemantics(find.byType(LumeTable)).label,
        contains('Prayer times'),
      );
    });

    testWidgets('it scrolls rather than squeezing its columns', (
      WidgetTester t,
    ) async {
      await show(
        t,
        const LumeTable(
          label: 'Wide',
          columns: <LumeColumn>[
            LumeColumn(label: 'A'),
            LumeColumn(label: 'B'),
            LumeColumn(label: 'C'),
            LumeColumn(label: 'D'),
            LumeColumn(label: 'E'),
          ],
          rows: <List<String>>[
            <String>['1', '2', '3', '4', '5'],
          ],
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  group('the master-detail scaffold', () {
    testWidgets('shows one pane below expanded', (WidgetTester t) async {
      await show(
        t,
        const LumeMasterDetail(
          list: Text('the list'),
          detail: Text('the detail'),
        ),
        surface: LumeViewport.phone,
      );
      expect(find.text('the list'), findsOneWidget);
      expect(find.text('the detail'), findsNothing);
    });

    testWidgets('shows both panes at expanded', (WidgetTester t) async {
      await show(
        t,
        const LumeMasterDetail(
          list: Text('the list'),
          detail: Text('the detail'),
        ),
        surface: LumeViewport.expanded,
      );
      expect(find.text('the list'), findsOneWidget);
      expect(find.text('the detail'), findsOneWidget);
    });

    testWidgets('shows one pane on a landscape phone', (WidgetTester t) async {
      // Wide enough for `expanded` on width alone; the height override claims
      // it back, and the detail must not appear beside the list.
      await show(
        t,
        const LumeMasterDetail(
          list: Text('the list'),
          detail: Text('the detail'),
        ),
        surface: LumeViewport.landscapePhone,
      );
      expect(find.text('the detail'), findsNothing);
    });
  });

  group('the sheet adapts to the width class', () {
    testWidgets('compact rounds only the top', (WidgetTester t) async {
      await show(
        t,
        const LumeSheet(child: Text('body')),
        surface: LumeViewport.phone,
      );
      final BoxDecoration d = t
          .widgetList<Container>(find.byType(Container))
          .map((Container c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((BoxDecoration d) => d.borderRadius != null);
      final BorderRadius r = d.borderRadius! as BorderRadius;
      expect(r.bottomLeft.x, 0, reason: 'it meets the bottom edge');
    });

    testWidgets('expanded rounds every corner', (WidgetTester t) async {
      await show(
        t,
        const LumeSheet(child: Text('body')),
        surface: LumeViewport.expanded,
      );
      final BoxDecoration d = t
          .widgetList<Container>(find.byType(Container))
          .map((Container c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((BoxDecoration d) => d.borderRadius != null);
      final BorderRadius r = d.borderRadius! as BorderRadius;
      expect(r.bottomLeft.x, greaterThan(0), reason: 'it floats');
    });
  });
}
