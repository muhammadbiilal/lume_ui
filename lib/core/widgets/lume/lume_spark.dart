/// A sparkline and a line chart, drawn as `components.js` draws them.
///
/// Both are SVGs in the reference with `preserveAspectRatio="none"`: the
/// view box is stretched to the element, so x scales with the width while the
/// strokes stay their own width (`vector-effect: non-scaling-stroke`). Points
/// are straight segments through each value, placed in the view box and
/// rounded to a tenth as `toFixed(1)` writes the path.
///
/// * [LumeSparkline] — `sparkline(vals)`: a 56 × 22 view box, 2 of padding, a
///   1.6-point line and a 14 % area to the base, in the trend's colour.
/// * [LumeLineChart] — `lineChart(o)`: a 320 × 132 view box, 6 above and 20
///   below the plot, three grid lines, a 12 % area, a 2-point round-joined
///   line, a 3.2 dot on the last value, x labels, and a caption 10 below.
///
/// Neither uses a charting package's defaults: the scale, the baseline, the
/// grid and the labels are the reference's.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';

/// Which way a series went — `dirOf`, and the chart's tone.
enum LumeTrend { up, down, flat }

/// `extent(vals)` — a flat series is given a span of two.
(double, double) _extent(List<double> v) {
  double lo = v.reduce(math.min), hi = v.reduce(math.max);
  if (lo == hi) {
    lo -= 1;
    hi += 1;
  }
  return (lo, hi);
}

/// `toFixed(1)`.
double _tenth(double x) => (x * 10).roundToDouble() / 10;

Color _ink(LumeColors lume, LumeTrend? trend, {required Color fallback}) =>
    switch (trend) {
      LumeTrend.up => lume.up,
      LumeTrend.down => lume.down,
      LumeTrend.flat => lume.text3,
      null => fallback,
    };

/// `.rrow__spark` — a small trend line.
class LumeSparkline extends StatelessWidget {
  const LumeSparkline({
    super.key,
    required this.values,
    this.trend,
    this.width = 54,
    this.height = 22,
    this.fill = true,
  });

  final List<double> values;

  /// `null` reads the series: up when it ends at or above where it began.
  final LumeTrend? trend;
  final double width;
  final double height;
  final bool fill;

  static const Size viewBox = Size(56, 22);

  @override
  Widget build(BuildContext context) {
    final LumeTrend t =
        trend ??
        (values.isEmpty || values.last >= values.first
            ? LumeTrend.up
            : LumeTrend.down);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparkPainter(
            values: values,
            color: _ink(context.lume, t, fallback: context.lume.up),
            fill: fill,
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({
    required this.values,
    required this.color,
    required this.fill,
  });

  final List<double> values;
  final Color color;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const double w = 56, h = 22, pad = 2;
    final (double lo, double hi) = _extent(values);
    final double step = values.length > 1 ? w / (values.length - 1) : w;
    final double sx = size.width / w, sy = size.height / h;
    final List<Offset> pts = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(
          _tenth(i * step) * sx,
          _tenth(pad + (h - pad * 2) * (1 - (values[i] - lo) / (hi - lo))) * sy,
        ),
    ];
    final Path line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final Offset p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    if (fill) {
      final Path area = Path.from(line)
        ..lineTo(w * sx, h * sy)
        ..lineTo(0, h * sy)
        ..close();
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.14));
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color || old.fill != fill || !_same(old.values, values);
}

bool _same(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// `.chart--line` — a series over time, with its labels and caption.
class LumeLineChart extends StatelessWidget {
  const LumeLineChart({
    super.key,
    required this.values,
    required this.label,
    this.labels = const <String>[],
    this.caption,
    this.trend,
    this.summary,
  });

  final List<double> values;

  /// The figure's accessible name — `aria-label`.
  final String label;

  /// Along the bottom, first at the start and last at the end.
  final List<String> labels;
  final String? caption;

  /// `chart--up` / `chart--down`; `null` is the accent.
  final LumeTrend? trend;

  /// What a reader hears after the name — where the series began and ended.
  final String? summary;

  static const double viewWidth = 320;
  static const double height = 132;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color ink = _ink(lume, trend, fallback: lume.accent);
    return Semantics(
      container: true,
      label: summary == null ? label : '$label. $summary',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: height,
              child: CustomPaint(
                painter: _LinePainter(
                  values: values,
                  labels: labels,
                  ink: ink,
                  grid: lume.border,
                  card: lume.card,
                  labelStyle: LumeType.natural(
                    context,
                    context.lumeType.label,
                    size: 11,
                  ).copyWith(fontWeight: FontWeight.w600, color: lume.text3),
                  direction: Directionality.of(context),
                ),
              ),
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  caption!,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                    size: 11,
                  ).copyWith(fontWeight: FontWeight.w500, color: lume.text3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.labels,
    required this.ink,
    required this.grid,
    required this.card,
    required this.labelStyle,
    required this.direction,
  });

  final List<double> values;
  final List<String> labels;
  final Color ink;
  final Color grid;
  final Color card;
  final TextStyle labelStyle;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const double w = LumeLineChart.viewWidth, h = LumeLineChart.height;
    const double padB = 20, padT = 6;
    final double sx = size.width / w;
    final (double lo, double hi) = _extent(values);
    final double step = values.length > 1 ? w / (values.length - 1) : w;
    final List<Offset> pts = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(
          _tenth(i * step) * sx,
          _tenth(padT + (h - padB - padT) * (1 - (values[i] - lo) / (hi - lo))),
        ),
    ];

    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final double f in <double>[0, 0.5, 1]) {
      final double y = _tenth(padT + (h - padB - padT) * f);
      canvas.drawLine(Offset(0, y), Offset(w * sx, y), gridPaint);
    }

    final Path line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final Offset p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final Path area = Path.from(line)
      ..lineTo(w * sx, h - padB)
      ..lineTo(0, h - padB)
      ..close();
    canvas.drawPath(area, Paint()..color = ink.withValues(alpha: 0.12));
    canvas.drawPath(
      line,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // `<circle r="3.2">` in a stretched view box is an ellipse as wide as the
    // stretch; its stroke keeps its width.
    final Rect dot = Rect.fromCenter(
      center: pts.last,
      width: 6.4 * sx,
      height: 6.4,
    );
    canvas.drawOval(dot, Paint()..color = ink);
    canvas.drawOval(
      dot,
      Paint()
        ..color = card
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (int i = 0; i < labels.length; i++) {
      final double vx = math.min(
        w - 8,
        math.max(8, i * (w / math.max(1, labels.length - 1))),
      );
      final TextPainter p = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: direction,
      )..layout();
      final double x = vx * sx;
      final double left = i == 0
          ? x
          : i == labels.length - 1
          ? x - p.width
          : x - p.width / 2;
      p.paint(
        canvas,
        Offset(
          left,
          (h - 4) - p.computeDistanceToActualBaseline(TextBaseline.alphabetic),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.ink != ink ||
      old.grid != grid ||
      old.card != card ||
      old.direction != direction ||
      !_same(old.values, values) ||
      old.labels.join(' ') != labels.join(' ');
}
