/// The share card, drawn as `share-cards.js` `drawShareCard` draws it.
///
/// A 1080 × 1350 canvas: the kind's two-stop gradient from corner to corner,
/// two soft circles and three sparkles, the Arabic line (when there is one)
/// right to left in Noto Naskh Arabic, the words in Plus Jakarta Sans, their
/// source, and the footer — a rule, the half-filled mark, the wordmark and the
/// tagline. The block is measured before it is drawn so it sits optically
/// centred, exactly as the reference measures it.
///
/// The card follows the reading direction: an Urdu or Arabic card anchors its
/// words and its footer on the right, rather than being mirrored.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../platform/lume_share.dart';

class LumeShareCardArt extends StatelessWidget {
  const LumeShareCardArt({
    super.key,
    required this.card,
    required this.tagline,
  });

  final LumeShareCard card;

  /// `t('app.tagline')`.
  final String tagline;

  static const Size size = Size(1080, 1350);

  /// `THEMES` — two stops and the accent for the sparkles and the Arabic.
  static (Color, Color, Color) theme(LumeShareKind kind) => switch (kind) {
    LumeShareKind.quran => (
      const Color(0xFF1B2A5E),
      const Color(0xFF3E4E9E),
      const Color(0xFFFFE9B8),
    ),
    LumeShareKind.hadith => (
      const Color(0xFF1D4E4A),
      const Color(0xFF2F7F6E),
      const Color(0xFF8FE6D2),
    ),
    LumeShareKind.dua => (
      const Color(0xFF4A3F9E),
      const Color(0xFF6E62E5),
      const Color(0xFFD9D3FF),
    ),
    LumeShareKind.quote => (
      const Color(0xFF0E8C7E),
      const Color(0xFF25B7A2),
      const Color(0xFFDFF5EF),
    ),
    LumeShareKind.reminder => (
      const Color(0xFF3A3A44),
      const Color(0xFF5C5C6B),
      const Color(0xFFE6E6EA),
    ),
  };

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: CustomPaint(
      painter: _SharePainter(
        card: card,
        tagline: tagline,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
    ),
  );
}

class _SharePainter extends CustomPainter {
  const _SharePainter({
    required this.card,
    required this.tagline,
    required this.rtl,
  });

  final LumeShareCard card;
  final String tagline;
  final bool rtl;

  static const Color _white = Color(0xFFFFFFFF);
  static const double _pad = 110;

  static TextStyle _latin(double size, FontWeight weight, Color color) =>
      TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontFamilyFallback: const <String>['NotoNaskhArabic'],
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  /// A paragraph laid out at [width] with every line [lineStep] apart — the
  /// canvas's `y += step` after each `fillText`.
  static TextPainter _paragraph(
    String text,
    TextStyle style, {
    required double width,
    required double lineStep,
    required TextDirection direction,
    required TextAlign align,
  }) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    textAlign: align,
    strutStyle: StrutStyle(
      fontFamily: style.fontFamily,
      fontSize: style.fontSize,
      height: lineStep / style.fontSize!,
      leading: 0,
      forceStrutHeight: true,
    ),
  )..layout(minWidth: width, maxWidth: width);

  static int _lines(TextPainter p) => p.computeLineMetrics().length;

  /// Paints [p] so that its first baseline sits at [baseline].
  static void _at(Canvas canvas, TextPainter p, double x, double baseline) {
    final List<LineMetrics> lines = p.computeLineMetrics();
    final double first = lines.isEmpty ? 0 : lines.first.baseline;
    p.paint(canvas, Offset(x, baseline - first));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    final (Color a, Color b, Color accent) = LumeShareCardArt.theme(card.kind);
    final TextDirection dir = rtl ? TextDirection.rtl : TextDirection.ltr;

    // The ground, corner to corner.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[a, b],
        ).createShader(Offset.zero & size),
    );

    // Decorative shapes, same language as the rest of the app.
    canvas.drawCircle(
      Offset(w - 90, 150),
      300,
      Paint()..color = _white.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      Offset(120, h - 120),
      220,
      Paint()..color = _white.withValues(alpha: 0.08),
    );

    void sparkle(double x, double y, double r, double alpha) {
      final Path p = Path()
        ..moveTo(x, y - r)
        ..quadraticBezierTo(x, y, x + r, y)
        ..quadraticBezierTo(x, y, x, y + r)
        ..quadraticBezierTo(x, y, x - r, y)
        ..quadraticBezierTo(x, y, x, y - r);
      canvas.drawPath(p, Paint()..color = accent.withValues(alpha: alpha));
    }

    sparkle(150, 190, 34, 0.75);
    sparkle(w - 190, h - 300, 22, 0.5);
    sparkle(w - 130, 470, 14, 0.35);

    final double maxW = w - _pad * 2;

    // Measure first so the block sits optically centred.
    final TextPainter? arabic = card.arabic == null
        ? null
        : _paragraph(
            card.arabic!,
            TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 62,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
            width: maxW,
            lineStep: 96,
            direction: TextDirection.rtl,
            align: TextAlign.right,
          );
    final TextPainter words = _paragraph(
      card.text,
      _latin(54, FontWeight.w700, _white),
      width: maxW,
      lineStep: 74,
      direction: dir,
      align: rtl ? TextAlign.right : TextAlign.left,
    );
    final int aLines = arabic == null ? 0 : _lines(arabic);
    final int tLines = _lines(words);
    final double blockH =
        aLines * 96 + (aLines > 0 ? 40 : 0) + tLines * 74 + 58;
    double y = math.max(300, ((h - 190 - blockH) / 2).roundToDouble() + 60);

    if (arabic != null) {
      _at(canvas, arabic, _pad, y);
      y += aLines * 96 + 40;
    }

    _at(canvas, words, _pad, y);
    y += tLines * 74 + 24;

    final TextPainter source = _paragraph(
      card.source,
      _latin(34, FontWeight.w500, _white.withValues(alpha: 0.75)),
      width: maxW,
      lineStep: 44,
      direction: dir,
      align: rtl ? TextAlign.right : TextAlign.left,
    );
    _at(canvas, source, _pad, y);

    // Footer: the same wordmark the app uses.
    final double fy = h - 110;
    canvas.drawLine(
      Offset(_pad, fy - 70),
      Offset(w - _pad, fy - 70),
      Paint()
        ..color = _white.withValues(alpha: 0.28)
        ..strokeWidth = 2,
    );

    final double markX = rtl ? w - _pad - 26 : _pad + 26;
    final Rect mark = Rect.fromCircle(
      center: Offset(markX, fy - 8),
      radius: 26,
    );
    canvas.drawCircle(
      mark.center,
      26,
      Paint()
        ..color = _white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawPath(
      Path()
        ..addArc(mark, -math.pi / 2, math.pi)
        ..close(),
      Paint()..color = _white,
    );

    TextPainter line(String text, TextStyle style) => TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: dir,
    )..layout();

    void anchored(TextPainter p, double baseline) {
      final double x = rtl ? markX - 46 - p.width : markX + 46;
      p.paint(
        canvas,
        Offset(
          x,
          baseline - p.computeDistanceToActualBaseline(TextBaseline.alphabetic),
        ),
      );
    }

    anchored(line('Lume', _latin(40, FontWeight.w800, _white)), fy);
    anchored(
      line(tagline, _latin(26, FontWeight.w500, _white.withValues(alpha: 0.7))),
      fy + 38,
    );
  }

  @override
  bool shouldRepaint(_SharePainter old) =>
      old.card != card || old.tagline != tagline || old.rtl != rtl;
}
