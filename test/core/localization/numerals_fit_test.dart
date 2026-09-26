/// `LumeNumerals.shrinkToFit`: a figure too wide for its box is drawn
/// smaller and whole, never below its floor, and one that fits is untouched.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/localization/lume_numerals.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

const TextStyle _style = TextStyle(fontSize: 30, fontWeight: FontWeight.w800);

void main() {
  setUpAll(loadLumeFonts);

  Future<RenderParagraph> pump(
    WidgetTester tester, {
    required double width,
    required double textScale,
    double minScale = 1,
  }) async {
    await pumpLume(
      tester,
      Center(
        child: SizedBox(
          width: width,
          child: LumeNumerals(
            'Rs 10,188,000',
            style: _style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            shrinkToFit: true,
            minScale: minScale,
          ),
        ),
      ),
      textScale: textScale,
      surface: const Size(1200, 400),
    );
    return tester.renderObject<RenderParagraph>(find.byType(RichText));
  }

  double scaleOf(RenderParagraph p) => p.textScaler.scale(30) / 30;

  testWidgets('a figure that fits is drawn at the reader\'s scale', (
    WidgetTester tester,
  ) async {
    final RenderParagraph p = await pump(tester, width: 1000, textScale: 1.5);
    expect(scaleOf(p), closeTo(1.5, 1e-9));
    expect(p.didExceedMaxLines, isFalse);
  });

  testWidgets('at 200 % a figure too wide is drawn smaller and whole', (
    WidgetTester tester,
  ) async {
    final RenderParagraph p = await pump(tester, width: 500, textScale: 2);
    expect(scaleOf(p), lessThan(2));
    expect(scaleOf(p), greaterThanOrEqualTo(1));
    expect(p.didExceedMaxLines, isFalse);
    expect(p.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(500));
  });

  testWidgets('never below the floor: past it, the ellipsis', (
    WidgetTester tester,
  ) async {
    final RenderParagraph p = await pump(tester, width: 60, textScale: 2);
    expect(scaleOf(p), closeTo(1, 1e-9));
    expect(p.didExceedMaxLines, isTrue);
  });

  testWidgets('a lower floor lets a tight figure go under the design size', (
    WidgetTester tester,
  ) async {
    final RenderParagraph wide = await pump(tester, width: 1000, textScale: 1);
    final double natural = wide.getMaxIntrinsicWidth(double.infinity);
    final RenderParagraph p = await pump(
      tester,
      width: natural * 0.9,
      textScale: 1,
      minScale: 0.8,
    );
    expect(scaleOf(p), lessThan(1));
    expect(p.didExceedMaxLines, isFalse);
  });
}
