/// `text-wrap: balance` on a clamped heading (C60).
///
/// Balancing searches for the narrowest width that keeps the line count. A
/// `Text` clamped to two lines cannot report a third, so the search used to
/// narrow to the longest word and Home's hero read "Plan / your …". The count
/// is now taken from the text unclamped — balance first, clamp after, as CSS
/// applies them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_text.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  const TextStyle style = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.12,
  );

  Future<double> widthOf(
    WidgetTester tester,
    String text, {
    int? maxLines,
    double box = 235.55,
  }) async {
    await pumpLume(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: box,
          child: LumeBalancedText(
            child: Text(
              text,
              style: style,
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.text(text)).width;
  }

  testWidgets('a clamped heading balances exactly as an unclamped one', (
    WidgetTester tester,
  ) async {
    // Two lines greedily in a 520-point box — whichever face the test binding
    // resolves — so the clamp hides nothing and balancing is allowed to
    // narrow.
    const String title = 'Plan your day before it starts';
    final double free = await widthOf(tester, title, box: 520);
    final double clamped = await widthOf(tester, title, maxLines: 2, box: 520);
    expect(clamped, closeTo(free, 0.5));
    // Narrowed — balanced — and not collapsed to the longest word.
    expect(clamped, lessThan(500));
    expect(clamped, greaterThan(120));
  });

  testWidgets('a heading that overflows its clamp keeps the full width', (
    WidgetTester tester,
  ) async {
    const String long =
        'One two three four five six seven eight nine ten eleven twelve';
    final double width = await widthOf(tester, long, maxLines: 2, box: 180);
    expect(width, 180);
  });

  testWidgets('Home’s hero sets its title on two full lines', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(tester, initialLocation: '/home');
    final Finder title = find.text('Plan your day before it starts');
    final Size size = tester.getSize(title);
    // Two 26.88-point lines, and a box wider than any single word.
    expect(size.height, closeTo(2 * 24 * 1.12, 1.5));
    expect(size.width, greaterThan(150));
  });

  testWidgets('and at twice the type size the full title is still announced', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpLumeRouter(tester, initialLocation: '/home', textScale: 2);
    expect(
      find.bySemanticsLabel(RegExp('Plan your day before it starts')),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
