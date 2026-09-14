/// The context strip's widened touch target: where a finger may land, and
/// where it may not.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/core/widgets/lume/lume_target.dart';

import '../../features/tax/tax_harness.dart';
import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  Future<void> sheetOpens(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('on Tax, through the real frame', () {
    testWidgets('the strip is drawn exactly as the reference measures it', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester);
      expect(tester.getSize(find.byType(LumeContextBar)).height, 22);
      final Rect item = tester.getRect(find.byType(LumeTargetSlop));
      expect(item.height, 18);
    });

    for (final double dy in <double>[-12, 12]) {
      testWidgets('a tap ${dy.abs().round()} ${dy < 0 ? 'above' : 'below'} the '
          'country still opens Personalise', (WidgetTester tester) async {
        await pumpTax(tester);
        final Rect item = tester.getRect(find.byType(LumeTargetSlop));
        await tester.tapAt(
          Offset(item.center.dx, dy < 0 ? item.top + dy : item.bottom + dy),
        );
        await sheetOpens(tester);
        expect(find.byType(LumeSheet), findsOneWidget);
      });
    }

    testWidgets('and one past the widened box does nothing', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester);
      final Rect item = tester.getRect(find.byType(LumeTargetSlop));
      await tester.tapAt(Offset(item.center.dx, item.top - 15));
      await sheetOpens(tester);
      expect(find.byType(LumeSheet), findsNothing);
    });

    testWidgets('a tap on a fact in the strip is not taken for the country', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester);
      await tester.tap(find.text('FBR salaried slabs'));
      await sheetOpens(tester);
      expect(find.byType(LumeSheet), findsNothing);
    });

    testWidgets('the target is 44 tall and does not reach the tool bar', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester);
      final RenderLumeTargetRegion region = tester.renderObject(
        find.byType(LumeTargetRegion),
      );
      final (_, Rect drawn, Rect widened) = region.targets.single;
      expect(widened.height, 44);
      expect(widened.width, drawn.width + 8);
      final Rect bar = tester.getRect(find.byType(LumeToolbar));
      final Offset origin = tester
          .renderObject<RenderBox>(find.byType(LumeTargetRegion))
          .localToGlobal(Offset.zero);
      expect(widened.shift(origin).top, greaterThanOrEqualTo(bar.bottom));
    });

    testWidgets('in Urdu, right to left, and at 200 %', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, locale: const Locale('ur'), textScale: 2);
      expectNoOverflow(tester);
      final Rect item = tester.getRect(find.byType(LumeTargetSlop));
      await tester.tapAt(Offset(item.center.dx, item.top - 10));
      await sheetOpens(tester);
      expect(find.byType(LumeSheet), findsOneWidget);
    });

    testWidgets('semantics still name the item, at its drawn size', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester);
      final SemanticsHandle handle = tester.ensureSemantics();
      final SemanticsNode node = tester.getSemantics(
        find.descendant(
          of: find.byType(LumeTargetSlop),
          matching: find.byType(LumePressable),
        ),
      );
      expect(node.label, 'Pakistan');
      expect(node.rect.height, 18);
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });

  group('neighbours', () {
    Future<List<String>> pumpTwo(
      WidgetTester tester,
      TextDirection direction,
    ) async {
      final List<String> taps = <String>[];
      await pumpLume(
        tester,
        Directionality(
          textDirection: direction,
          child: Align(
            alignment: AlignmentDirectional.topStart,
            // The region is the surface with room around the strip, so the
            // room is inside it.
            child: LumeTargetRegion(
              child: SizedBox(
                width: 390,
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: LumeContextBar(
                    items: <LumeContextItem>[
                      LumeContextItem(
                        label: 'One',
                        onTap: () => taps.add('one'),
                      ),
                      LumeContextItem(
                        label: 'Two',
                        onTap: () => taps.add('two'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return taps;
    }

    for (final TextDirection d in TextDirection.values) {
      testWidgets('share no point, and each takes its own half of the gap '
          '(${d.name})', (WidgetTester tester) async {
        final List<String> taps = await pumpTwo(tester, d);
        final RenderLumeTargetRegion region = tester.renderObject(
          find.byType(LumeTargetRegion),
        );
        final List<Rect> widened = <Rect>[
          for (final (_, _, Rect w) in region.targets) w,
        ];
        expect(widened, hasLength(2));
        final Rect overlap = widened[0].intersect(widened[1]);
        expect(overlap.width <= 0 || overlap.height <= 0, isTrue);

        final Rect one = tester.getRect(find.text('One'));
        final Rect two = tester.getRect(find.text('Two'));
        final bool oneFirst = one.left < two.left;
        final Rect left = oneFirst ? one : two;
        final Rect right = oneFirst ? two : one;
        // A point just past each word, inside the gap and above the strip.
        await tester.tapAt(Offset(left.right + 1, left.top - 6));
        await tester.tapAt(Offset(right.left - 1, right.top - 6));
        expect(
          taps,
          oneFirst ? <String>['one', 'two'] : <String>['two', 'one'],
        );
      });
    }
  });
}
