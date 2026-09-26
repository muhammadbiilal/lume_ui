/// `.gauge` — a half-circle track and its accent fill, with the reading in
/// the middle.
///
/// Measured from `css/tools/shared.css` `.gauge`: a `0 0 200 120` view box
/// drawn 132 tall at full width (so scaled by `min(w / 200, 132 / 120)` and
/// centred), the arc `M20 108 A 80 80 0 0 1 180 108` — radius 80 about
/// (100, 108) — in 12-point round-capped strokes, the track `tint-neutral`
/// and the fill `accent`. The middle is the value at 34 / 800 / −0.05em over
/// "Mbps" at 11 / 700 in `text-3`, pushed down 26 points.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/lume_numerals.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';

class LumeSpeedGauge extends StatelessWidget {
  const LumeSpeedGauge({
    super.key,
    required this.fraction,
    required this.value,
    required this.unit,
    required this.semanticLabel,
  });

  /// 0–1 along the arc.
  final double fraction;
  final String value;
  final String unit;
  final String semanticLabel;

  static const double height = 132;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(
              painter: _GaugePainter(
                fraction: fraction.clamp(0, 1).toDouble(),
                track: lume.tintNeutral,
                fill: lume.accent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 26),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LumeNumerals(
                      value,
                      style: LumeType.numeric(
                        LumeType.tracked(
                          LumeType.fit(
                            context,
                            context.lumeType.display,
                          ).copyWith(fontSize: 34, height: 1.1),
                          -0.05,
                        ),
                      ).copyWith(color: lume.text),
                      maxLines: 1,
                    ),
                    Text(
                      unit,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                          ).copyWith(
                            color: lume.text3,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.fraction,
    required this.track,
    required this.fill,
  });

  final double fraction;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    // `preserveAspectRatio` default: meet, centred.
    final double s = math.min(size.width / 200, size.height / 120);
    final double dx = (size.width - 200 * s) / 2;
    final double dy = (size.height - 120 * s) / 2;
    final Rect circle = Rect.fromCircle(
      center: Offset(dx + 100 * s, dy + 108 * s),
      radius: 80 * s,
    );
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * s
      ..strokeCap = StrokeCap.round;

    // From the left end (180°) sweeping clockwise over the top to the right.
    canvas.drawArc(circle, math.pi, math.pi, false, stroke(track));
    if (fraction > 0) {
      canvas.drawArc(circle, math.pi, math.pi * fraction, false, stroke(fill));
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.track != track || old.fill != fill;
}
