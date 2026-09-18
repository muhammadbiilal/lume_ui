/// Tip & Split's people stepper, held to why its row is six points taller than
/// the reference's (C83, approved in the F6B closure): two real 44-point
/// targets that never overlap, in every layout a reader can bring.
library;

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/features/tipsplit/presentation/tipsplit_tool.dart';

import '../../helpers/load_fonts.dart';
import '../wave1/wave1_tools_test.dart' show pumpTool;

/// The stepper's two targets, decrement first.
(Rect, Rect) targets(WidgetTester tester) {
  final Finder presses = find.descendant(
    of: find.byKey(LumeTipsplitTool.peopleKey),
    matching: find.byType(LumePressable),
  );
  expect(presses, findsNWidgets(2));
  return (tester.getRect(presses.at(0)), tester.getRect(presses.at(1)));
}

Rect card(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.byKey(LumeTipsplitTool.peopleKey),
        matching: find.byType(LumeCard),
      )
      .first,
);

/// Everything the stepper promises, in whatever layout is on screen.
void expectSound(WidgetTester tester, {required String label}) {
  expect(tester.takeException(), isNull, reason: 'nothing overflows');
  final (Rect minus, Rect plus) = targets(tester);
  for (final Rect r in <Rect>[minus, plus]) {
    expect(r.width, greaterThanOrEqualTo(44));
    expect(r.height, greaterThanOrEqualTo(44));
  }
  expect(minus.overlaps(plus), isFalse, reason: 'the targets overlap');
  final Rect row = tester.getRect(find.byKey(LumeTipsplitTool.peopleKey));
  final Rect text = tester.getRect(find.bySemanticsLabel(label).first);
  expect(text.overlaps(row), isFalse, reason: 'the label runs under it');
  final Rect c = card(tester);
  expect(c.left <= row.left && row.right <= c.right, isTrue);
  expect(row.bottom <= c.bottom, isTrue, reason: 'it hangs out of its card');
  final Rect chips = tester.getRect(find.byKey(LumeTipsplitTool.tipsKey));
  expect(chips.bottom <= row.top + 0.01, isTrue, reason: 'it rides the chips');
}

Future<void> show(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(LumeTipsplitTool.peopleKey));
  await tester.pumpAndSettle();
}

String people(WidgetTester tester) =>
    tester.getSemantics(find.byKey(LumeTipsplitTool.peopleKey)).value;

void main() {
  setUpAll(loadLumeFonts);

  testWidgets('two 44-point targets, apart, inside the card', (
    WidgetTester tester,
  ) async {
    await pumpTool(tester, 'tipsplit');
    expectSound(tester, label: 'People');
    final (Rect minus, Rect plus) = targets(tester);
    expect(plus.left - minus.right, greaterThanOrEqualTo(16));
    expect(LumeStepper.targetSize, 44);
    expect(
      LumeStepper.targetSize - LumeStepper.height,
      12,
      reason:
          'the row is 12 taller than the pill: six of it the declared '
          'deviation, six from the card\'s own padding',
    );
  });

  for (final (String name, Size size, Locale locale, double scale)
      in <(String, Size, Locale, double)>[
        ('at 200 %', const Size(390, 5000), const Locale('en'), 2),
        (
          'in Urdu, right to left',
          const Size(390, 5000),
          const Locale('ur'),
          1,
        ),
        (
          'in Arabic, right to left',
          const Size(390, 5000),
          const Locale('ar'),
          1,
        ),
        ('in Arabic at 200 %', const Size(390, 5000), const Locale('ar'), 2),
        ('on a narrow phone', const Size(320, 5000), const Locale('en'), 1),
        ('in landscape', const Size(640, 360), const Locale('en'), 1),
        ('in landscape at 200 %', const Size(640, 360), const Locale('en'), 2),
      ]) {
    testWidgets(name, (WidgetTester tester) async {
      await pumpTool(
        tester,
        'tipsplit',
        surface: size,
        locale: locale,
        textScale: scale,
      );
      await show(tester);
      final String label = switch (locale.languageCode) {
        'ur' => 'افراد',
        'ar' => 'الأشخاص',
        _ => 'People',
      };
      expectSound(tester, label: label);
      if (locale.languageCode != 'en') {
        // Right to left: the label at the start (right), and "fewer" at the
        // start of the stepper, as the row reads.
        final (Rect minus, Rect plus) = targets(tester);
        expect(minus.left, greaterThan(plus.left));
        final Rect text = tester.getRect(find.bySemanticsLabel(label).first);
        expect(
          text.left,
          greaterThan(
            tester.getRect(find.byKey(LumeTipsplitTool.peopleKey)).left,
          ),
        );
      }
    });
  }

  testWidgets('the keyboard reaches both, and Enter and Space press them', (
    WidgetTester tester,
  ) async {
    await pumpTool(tester, 'tipsplit');
    Future<bool> tabTo(String label) async {
      for (int i = 0; i < 80; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        String? found;
        FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
          Element e,
        ) {
          final Widget w = e.widget;
          if (w is Semantics && w.properties.label != null) {
            found = w.properties.label;
            return false;
          }
          return true;
        });
        if (found == label) return true;
      }
      return false;
    }

    expect(people(tester), '2');
    expect(await tabTo('More People'), isTrue, reason: 'Tab never got there');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(people(tester), '3');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(people(tester), '4');
    // Tab goes round the screen and comes back to the stepper's first half.
    expect(await tabTo('Fewer People'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(people(tester), '3');
  });

  testWidgets('switch access and TalkBack press through the tap action, and '
      'a step that cannot happen offers none', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpTool(tester, 'tipsplit');
    void press(String label) {
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel(label),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
    }

    press('Fewer People');
    await tester.pump();
    expect(people(tester), '1');
    final SemanticsData fewer = tester
        .getSemantics(find.bySemanticsLabel('Fewer People'))
        .getSemanticsData();
    expect(fewer.hasAction(SemanticsAction.tap), isFalse);
    expect(fewer.flagsCollection.isEnabled, Tristate.isFalse);
    press('More People');
    await tester.pump();
    expect(people(tester), '2');
    handle.dispose();
  });

  testWidgets('a screen reader meets it in the order the card reads', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpTool(tester, 'tipsplit');
    final List<String> order = <String>[
      for (final SemanticsNode n
          in tester.semantics.simulatedAccessibilityTraversal())
        n.label,
    ];
    int at(bool Function(String) test, String what) {
      final int i = order.indexWhere(test);
      expect(i, isNonNegative, reason: '$what is not in the traversal');
      return i;
    }

    final int bill = at((String s) => s.startsWith('Bill'), 'Bill');
    final int tip = at((String s) => s == '15%' || s == '10%', 'a tip chip');
    final int stepper = at((String s) => s == 'People', 'the stepper');
    final int fewer = at((String s) => s == 'Fewer People', 'Fewer');
    final int more = at((String s) => s == 'More People', 'More');
    expect(
      <int>[bill, tip, stepper, fewer, more],
      <int>[
        ...(<int>[bill, tip, stepper, fewer, more]..sort()),
      ],
      reason: order.join(' | '),
    );
    handle.dispose();
  });
}
