/// The width classes, their boundaries, and the one rule the reference does
/// not have.
///
/// Boundary tests assert the pixel *either side* of each edge, because an
/// off-by-one in a breakpoint is invisible until a device lands exactly on it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/layout/lume_breakpoint.dart';
import 'package:lume/core/layout/lume_measure.dart';
import 'package:lume/core/theme/lume/lume_space.dart';

import '../../helpers/lume_harness.dart';

void main() {
  group('boundaries', () {
    test('599 is compact, 600 is medium', () {
      expect(LumeBreakpoints.classFor(599), LumeWidthClass.compact);
      expect(LumeBreakpoints.classFor(600), LumeWidthClass.medium);
    });

    test('839 is medium, 840 is expanded', () {
      expect(LumeBreakpoints.classFor(839), LumeWidthClass.medium);
      expect(LumeBreakpoints.classFor(840), LumeWidthClass.expanded);
    });

    test('the smallest supported width is still compact', () {
      expect(LumeBreakpoints.classFor(320), LumeWidthClass.compact);
    });

    test('the largest supported width is expanded', () {
      expect(LumeBreakpoints.classFor(1366), LumeWidthClass.expanded);
    });

    test('the boundaries are the Design System\'s numbers', () {
      expect(LumeBreakpoints.medium, 600);
      expect(LumeBreakpoints.expanded, 840);
    });
  });

  group('compact-height override', () {
    test('479 is short, 480 is not', () {
      expect(LumeBreakpoints.isCompactHeight(479), isTrue);
      expect(LumeBreakpoints.isCompactHeight(480), isFalse);
    });

    test('a landscape phone is compact however wide it is', () {
      // iPhone 14 Pro on its side: 852 crosses `expanded` on width alone.
      expect(LumeBreakpoints.classFor(852), LumeWidthClass.expanded);
      expect(
        LumeBreakpoints.resolve(width: 852, height: 393),
        LumeWidthClass.compact,
      );
    });

    test('every phone in landscape stays compact', () {
      const List<Size> phones = <Size>[
        Size(667, 375), // iPhone SE
        Size(852, 393), // iPhone 14 Pro
        Size(926, 428), // iPhone 14 Pro Max
      ];
      for (final Size s in phones) {
        expect(
          LumeBreakpoints.resolve(width: s.width, height: s.height),
          LumeWidthClass.compact,
          reason: '${s.width}x${s.height} is a phone, not a tablet',
        );
      }
    });

    test('no tablet loses its rail or sidebar in either orientation', () {
      expect(
        LumeBreakpoints.resolve(width: 744, height: 1133), // iPad mini portrait
        LumeWidthClass.medium,
      );
      expect(
        LumeBreakpoints.resolve(
          width: 1133,
          height: 744,
        ), // iPad mini landscape
        LumeWidthClass.expanded,
      );
      expect(
        LumeBreakpoints.resolve(
          width: 1366,
          height: 1024,
        ), // iPad Pro landscape
        LumeWidthClass.expanded,
      );
    });
  });

  group('measured from the shell', () {
    testWidgets('the class comes from the constraints, not the window', (
      WidgetTester tester,
    ) async {
      late LumeWidthClass outer;
      late LumeWidthClass inner;

      await pumpLume(
        tester,
        LumeProbe(onBuild: (BuildContext c) => outer = c.widthClass),
        surface: LumeViewport.expanded,
      );
      expect(outer, LumeWidthClass.expanded);

      // A 380-pixel detail pane inside an expanded window is a compact
      // surface, and the widgets inside it must be told so.
      await pumpLume(
        tester,
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: LumeSpace.listPane,
            child: LumeBreakpointScope(
              child: LumeProbe(
                onBuild: (BuildContext c) => inner = c.widthClass,
              ),
            ),
          ),
        ),
        surface: LumeViewport.expanded,
      );
      expect(inner, LumeWidthClass.compact);
    });

    testWidgets('each viewport resolves to the class it should', (
      WidgetTester tester,
    ) async {
      final Map<Size, LumeWidthClass> want = <Size, LumeWidthClass>{
        LumeViewport.narrow: LumeWidthClass.compact,
        LumeViewport.phone: LumeWidthClass.compact,
        LumeViewport.phoneLarge: LumeWidthClass.compact,
        LumeViewport.medium: LumeWidthClass.medium,
        LumeViewport.expanded: LumeWidthClass.expanded,
        LumeViewport.wide: LumeWidthClass.expanded,
        LumeViewport.landscapePhone: LumeWidthClass.compact,
      };

      for (final MapEntry<Size, LumeWidthClass> e in want.entries) {
        late LumeWidthClass got;
        await pumpLume(
          tester,
          LumeProbe(onBuild: (BuildContext c) => got = c.widthClass),
          surface: e.key,
        );
        expect(got, e.value, reason: '${e.key.width}x${e.key.height}');
      }
    });
  });

  group('detail pane', () {
    testWidgets('exists only at expanded, and never on a landscape phone', (
      WidgetTester tester,
    ) async {
      Future<bool> paneAt(Size size) async {
        late bool has;
        await pumpLume(
          tester,
          LumeProbe(onBuild: (BuildContext c) => has = c.hasDetailPane),
          surface: size,
        );
        return has;
      }

      expect(await paneAt(LumeViewport.phone), isFalse);
      expect(await paneAt(LumeViewport.medium), isFalse);
      expect(await paneAt(LumeViewport.expanded), isTrue);
      expect(
        await paneAt(LumeViewport.landscapePhone),
        isFalse,
        reason: 'a phone on its side has no room for two panes',
      );
    });
  });

  group('the content measure keeps the width-only class', () {
    testWidgets('a landscape phone is compact to navigate, wide to read', (
      WidgetTester tester,
    ) async {
      late LumeWidthClass presentation;
      late LumeWidthClass measure;
      late bool constrained;

      await pumpLume(
        tester,
        LumeProbe(
          onBuild: (BuildContext c) {
            presentation = c.widthClass;
            measure = c.measureClass;
            constrained = c.isHeightConstrained;
          },
        ),
        surface: LumeViewport.landscapePhone,
      );

      expect(presentation, LumeWidthClass.compact);
      expect(
        measure,
        LumeWidthClass.expanded,
        reason: 'a 900-pixel line of body text is too long whatever the height',
      );
      expect(constrained, isTrue);
    });

    testWidgets('an ordinary phone is compact on both', (WidgetTester t) async {
      late LumeWidthClass presentation;
      late LumeWidthClass measure;
      await pumpLume(
        t,
        LumeProbe(
          onBuild: (BuildContext c) {
            presentation = c.widthClass;
            measure = c.measureClass;
          },
        ),
        surface: LumeViewport.phone,
      );
      expect(presentation, LumeWidthClass.compact);
      expect(measure, LumeWidthClass.compact);
    });
  });

  group('page gutters and content cap', () {
    test('20 compact, 24 medium, 32 expanded', () {
      expect(LumeLayout.pageGutter(LumeWidthClass.compact), 20);
      expect(LumeLayout.pageGutter(LumeWidthClass.medium), 24);
      expect(LumeLayout.pageGutter(LumeWidthClass.expanded), 32);
    });

    test('the cap includes the gutters, as the CSS calc does', () {
      expect(
        LumeLayout.contentCap(LumeWidthClass.medium),
        LumeSpace.contentMax + 24 * 2,
      );
      expect(
        LumeLayout.contentCap(LumeWidthClass.expanded, wide: true),
        LumeSpace.contentWide + 32 * 2,
      );
    });

    test('the list pane stays inside the band at every expanded width', () {
      for (final double w in <double>[840, 1000, 1100, 1280, 1366]) {
        final double pane = LumeLayout.listPaneWidth(w);
        expect(
          pane,
          inInclusiveRange(LumeSpace.listPaneMin, LumeSpace.listPane),
          reason: 'shell $w',
        );
      }
    });

    testWidgets('compact does not cap or centre', (WidgetTester tester) async {
      await pumpLume(
        tester,
        const LumeMeasure(child: SizedBox.expand()),
        surface: LumeViewport.phone,
      );
      final Size box = tester.getSize(find.byType(SizedBox).first);
      expect(box.width, LumeViewport.phone.width - 20 * 2);
    });

    testWidgets('expanded caps and centres', (WidgetTester tester) async {
      await pumpLume(
        tester,
        const LumeMeasure(child: SizedBox.expand()),
        surface: LumeViewport.expanded,
      );
      final Size box = tester.getSize(find.byType(SizedBox).first);
      expect(box.width, LumeSpace.contentMax);
    });
  });

  group('sub-breakpoints are named, not literal', () {
    test('the narrow, wide and ultrawide refinements have one home', () {
      expect(LumeBreakpoints.narrow, 360);
      expect(LumeBreakpoints.wide, 1180);
      expect(LumeBreakpoints.ultrawide, 1380);
    });

    testWidgets('359 is narrow, 360 is not', (WidgetTester tester) async {
      late bool narrowAt359;
      late bool narrowAt360;
      await pumpLume(
        tester,
        LumeProbe(onBuild: (BuildContext c) => narrowAt359 = c.isNarrow),
        surface: LumeViewport.narrow,
      );
      await pumpLume(
        tester,
        LumeProbe(onBuild: (BuildContext c) => narrowAt360 = c.isNarrow),
        surface: LumeViewport.small,
      );
      expect(narrowAt359, isTrue);
      expect(narrowAt360, isFalse);
    });
  });
}
