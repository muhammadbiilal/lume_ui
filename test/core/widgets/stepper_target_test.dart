/// The stepper's touch targets — an accessibility correction with unchanged
/// visible geometry.
///
/// The reference draws 26 × 26 buttons inside a 32 px pill, which is far under
/// §9's 44 × 44 floor. The correction gives each button a real 44 × 44 target
/// without moving a pixel of what is drawn.
///
/// Every clause of that is asserted here, because "the target is bigger now"
/// is easy to claim and easy to get subtly wrong: targets that overlap, targets
/// that spill outside the widget and get clipped, or a target that moved the
/// circle it belongs to.
library;

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/widgets/lume/lume.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../../helpers/measured.dart';

void main() {
  setUpAll(loadLumeFonts);

  Future<void> show(
    WidgetTester tester,
    Widget widget, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    Size surface = LumeViewport.phone,
  }) => pumpLume(
    tester,
    Align(alignment: AlignmentDirectional.topStart, child: widget),
    locale: locale,
    textScale: textScale,
    surface: surface,
  );

  Widget stepper({
    VoidCallback? onDecrement,
    VoidCallback? onIncrement,
    String value = '4',
  }) => LumeStepper(
    label: 'People',
    value: value,
    onDecrement: onDecrement,
    onIncrement: onIncrement,
  );

  /// The two targets, in start-to-end order.
  List<Rect> targets(WidgetTester tester) {
    final Finder f = find.bySemanticsLabel(RegExp('crease People'));
    return <Rect>[
      for (int i = 0; i < tester.widgetList(f).length; i++)
        tester.getRect(f.at(i)),
    ];
  }

  group('the visible geometry did not move', () {
    testWidgets('the pill is still the measured 32 tall', (
      WidgetTester tester,
    ) async {
      if (!Measurements.available()) return;
      final Measured m = Measurements.load()['stepper'];
      expect(LumeStepper.height, m.height);
      expect(LumeStepper.buttonSize, Measurements.load()['stepper.btn'].height);

      await show(tester, stepper(onDecrement: () {}, onIncrement: () {}));
      // The decorated pill, not the transparent target band.
      final Iterable<Container> boxes = tester
          .widgetList<Container>(find.byType(Container))
          .where((Container c) => c.decoration != null);
      final Container pill = boxes.firstWhere(
        (Container c) =>
            (c.decoration! as BoxDecoration).shape != BoxShape.circle,
      );
      expect(pill.constraints?.maxHeight ?? 32, LumeStepper.height);
    });

    testWidgets('the pill is the measured 92 × 32', (
      WidgetTester tester,
    ) async {
      if (!Measurements.available()) return;
      final Measured m = Measurements.load()['stepper'];
      await show(tester, stepper(onDecrement: () {}, onIncrement: () {}));

      final Container pill = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).shape != BoxShape.circle,
          );
      final Size size = tester.getSize(find.byWidget(pill));
      expect(size.height, m.height, reason: 'pill height');
      expect(
        size.width,
        m.width,
        reason: 'pill width — 3 + 26 + 4 + 26 + 4 + 26 + 3, as measured',
      );
    });

    testWidgets('each circle is still 26 × 26', (WidgetTester tester) async {
      await show(tester, stepper(onDecrement: () {}, onIncrement: () {}));
      final Iterable<Container> circles = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).shape == BoxShape.circle,
          );
      expect(circles, hasLength(2));
      for (final Container c in circles) {
        expect(c.constraints?.maxWidth, LumeStepper.buttonSize);
        expect(c.constraints?.maxHeight, LumeStepper.buttonSize);
      }
    });

    testWidgets('each target is centred on its own circle', (
      WidgetTester tester,
    ) async {
      // The whole point of the 6 px overhang: grow the target without moving
      // the thing it belongs to.
      await show(tester, stepper(onDecrement: () {}, onIncrement: () {}));
      final List<Rect> t = targets(tester);
      final List<Rect> circles = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).shape == BoxShape.circle,
          )
          .map((Container c) => tester.getRect(find.byWidget(c)))
          .toList();

      expect(t, hasLength(2));
      expect(circles, hasLength(2));
      for (int i = 0; i < 2; i++) {
        expect(
          t[i].center.dx,
          closeTo(circles[i].center.dx, 0.01),
          reason: 'target $i is off its circle horizontally',
        );
        expect(
          t[i].center.dy,
          closeTo(circles[i].center.dy, 0.01),
          reason: 'target $i is off its circle vertically',
        );
      }
    });
  });

  group('the targets are 44 × 44 and do not overlap', () {
    testWidgets('both axes clear the floor', (WidgetTester tester) async {
      await show(tester, stepper(onDecrement: () {}, onIncrement: () {}));
      for (final Rect r in targets(tester)) {
        expect(r.width, greaterThanOrEqualTo(LumeSpace.tap));
        expect(r.height, greaterThanOrEqualTo(LumeSpace.tap));
      }
    });

    testWidgets('they do not overlap', (WidgetTester tester) async {
      await show(tester, stepper(onDecrement: () {}, onIncrement: () {}));
      final List<Rect> t = targets(tester);
      expect(
        t[0].overlaps(t[1]),
        isFalse,
        reason: 'a thumb between them must not hit both',
      );
    });

    testWidgets('they do not overlap at the narrowest value', (
      WidgetTester tester,
    ) async {
      // A one-character value is the tightest the control ever gets.
      await show(
        tester,
        stepper(onDecrement: () {}, onIncrement: () {}, value: '1'),
      );
      final List<Rect> t = targets(tester);
      expect(t[0].overlaps(t[1]), isFalse);
    });

    testWidgets('they stay inside the widget, so nothing is clipped', (
      WidgetTester tester,
    ) async {
      await show(tester, stepper(onDecrement: () {}, onIncrement: () {}));
      final Rect whole = tester.getRect(find.byType(LumeStepper));
      for (final Rect r in targets(tester)) {
        expect(
          whole.contains(r.topLeft) &&
              whole.contains(r.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
          reason: 'a target outside the widget is a target that gets clipped',
        );
      }
    });
  });

  group('every way in works', () {
    testWidgets('pointer', (WidgetTester tester) async {
      int down = 0;
      int up = 0;
      await show(
        tester,
        stepper(onDecrement: () => down++, onIncrement: () => up++),
      );
      await tester.tap(find.bySemanticsLabel('Decrease People'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Increase People'));
      await tester.pump();
      expect(down, 1);
      expect(up, 1);
    });

    testWidgets('the target catches a thumb outside the circle', (
      WidgetTester tester,
    ) async {
      // The corner of the 44 box, which is outside the 26 circle. Before the
      // correction this hit nothing.
      int down = 0;
      await show(
        tester,
        stepper(onDecrement: () => down++, onIncrement: () {}),
      );
      final Rect r = targets(tester).first;
      await tester.tapAt(r.topLeft + const Offset(2, 2));
      await tester.pump();
      expect(down, 1);
    });

    testWidgets('keyboard — Enter and Space', (WidgetTester tester) async {
      int down = 0;
      await show(
        tester,
        stepper(onDecrement: () => down++, onIncrement: () {}),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(down, greaterThanOrEqualTo(1), reason: 'Enter must activate');

      final int afterEnter = down;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(down, greaterThan(afterEnter), reason: 'Space must activate');
    });

    testWidgets('screen reader', (WidgetTester tester) async {
      int down = 0;
      await show(
        tester,
        stepper(onDecrement: () => down++, onIncrement: () {}),
      );
      final SemanticsHandle handle = tester.ensureSemantics();

      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Decrease People'),
      );
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          nodeId: node.id,
          viewId: tester.view.viewId,
        ),
      );
      await tester.pump();
      expect(down, 1, reason: 'assistive technology must be able to press it');
      handle.dispose();
    });
  });

  group('disabled', () {
    testWidgets('cannot be activated by pointer', (WidgetTester t) async {
      await show(t, stepper());
      await t.tap(
        find.bySemanticsLabel('Decrease People'),
        warnIfMissed: false,
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('still reports itself, and reports itself as disabled', (
      WidgetTester t,
    ) async {
      await show(t, stepper());
      final SemanticsNode node = t.getSemantics(
        find.bySemanticsLabel('Decrease People'),
      );
      expect(node.label, 'Decrease People');
      expect(
        node.flagsCollection.isEnabled,
        isNot(Tristate.isTrue),
        reason: 'a control that cannot be pressed must say so',
      );
    });

    testWidgets('one side disabled does not disable the other', (
      WidgetTester t,
    ) async {
      int up = 0;
      await show(t, stepper(onIncrement: () => up++));
      await t.tap(find.bySemanticsLabel('Increase People'));
      await t.pump();
      expect(up, 1);
    });
  });

  group('across the conditions that break layout', () {
    testWidgets('200 per cent text', (WidgetTester tester) async {
      await show(
        tester,
        stepper(onDecrement: () {}, onIncrement: () {}),
        textScale: 2.0,
      );
      expectNoOverflow(tester);
      final List<Rect> t = targets(tester);
      expect(t[0].overlaps(t[1]), isFalse);
      for (final Rect r in t) {
        expect(r.width, greaterThanOrEqualTo(LumeSpace.tap));
        expect(r.height, greaterThanOrEqualTo(LumeSpace.tap));
      }
    });

    testWidgets('the narrowest supported width', (WidgetTester tester) async {
      await show(
        tester,
        stepper(onDecrement: () {}, onIncrement: () {}),
        surface: LumeViewport.narrow,
      );
      expectNoOverflow(tester);
      expect(targets(tester)[0].overlaps(targets(tester)[1]), isFalse);
    });

    testWidgets('right to left — the targets mirror with the control', (
      WidgetTester tester,
    ) async {
      await show(
        tester,
        stepper(onDecrement: () {}, onIncrement: () {}),
        locale: const Locale('ar'),
      );
      final List<Rect> t = targets(tester);
      expect(t[0].overlaps(t[1]), isFalse);
      // Decrement is the start edge, which in RTL is the right.
      final Rect decrement = tester.getRect(
        find.bySemanticsLabel('Decrease People'),
      );
      final Rect increment = tester.getRect(
        find.bySemanticsLabel('Increase People'),
      );
      expect(
        decrement.center.dx,
        greaterThan(increment.center.dx),
        reason: 'the control mirrors as a whole',
      );
    });

    testWidgets('beside another control, nothing is stolen', (
      WidgetTester tester,
    ) async {
      int neighbour = 0;
      int down = 0;
      await show(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            stepper(onDecrement: () => down++, onIncrement: () {}),
            const SizedBox(width: 8),
            LumeButton(label: 'Next', onPressed: () => neighbour++),
          ],
        ),
      );
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(neighbour, 1);
      expect(down, 0, reason: 'the stepper must not swallow its neighbour');

      await tester.tap(find.bySemanticsLabel('Increase People'));
      await tester.pump();
      expect(neighbour, 1, reason: 'and the neighbour must not swallow it');
    });
  });
}
