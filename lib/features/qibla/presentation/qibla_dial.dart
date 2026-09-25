/// The Qibla dial — a compass face with the computed bearing drawn on it.
///
/// **Not a live compass.** `qibla.tool.js`'s `.compass` is a needle a
/// magnetometer moves as the reader turns; nothing in this build reads the
/// device's orientation, so that live needle is out of scope here (it would
/// need a sensor package this conversion is not authorised to add). This is
/// the honest, computed-only half of it instead: a fixed dial, drawn once
/// from [bearing] and never re-drawn as the phone moves. True north is
/// always "up" on the face — the reader turns the dial to true north
/// themselves, with a compass or a map, the way the note under it says.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';

/// A static dial, its needle fixed at [bearing] degrees clockwise from true
/// north.
class LumeQiblaDial extends StatelessWidget {
  const LumeQiblaDial({super.key, required this.bearing, this.size = 200});

  /// Degrees clockwise from true north, `[0, 360)`.
  final double bearing;
  final double size;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double rad = bearing * math.pi / 180;

    Widget cardinal(String label, Alignment at) => Align(
      alignment: at,
      child: Text(
        label,
        style: LumeType.tracked(
          LumeType.natural(context, context.lumeType.metaSmall, size: 11),
          0.02,
        ).copyWith(color: lume.text3, fontWeight: FontWeight.w700),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lume.card2,
                border: Border.all(color: lume.border, width: 1),
              ),
            ),
            CustomPaint(
              size: Size.square(size),
              painter: _DialTicks(color: lume.border2),
            ),
            // The four cardinals are geography, not reading order: they never
            // mirror under RTL (§17), which is why this uses [Alignment]
            // rather than the directional variant.
            cardinal('N', const Alignment(0, -0.84)),
            cardinal('E', const Alignment(0.84, 0)),
            cardinal('S', const Alignment(0, 0.84)),
            cardinal('W', const Alignment(-0.84, 0)),
            Transform.rotate(
              angle: rad,
              child: CustomPaint(
                size: Size(size * 0.1, size * 0.62),
                painter: _NeedlePainter(
                  head: lume.accent,
                  tail: lume.text3.withValues(alpha: 0.35),
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: lume.text,
                shape: BoxShape.circle,
                border: Border.all(color: lume.card2, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eight faint ticks, at every cardinal and ordinal point.
class _DialTicks extends CustomPainter {
  const _DialTicks({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final double a = i * math.pi / 4;
      final Offset from = Offset(
        centre.dx + (r - 11) * math.sin(a),
        centre.dy - (r - 11) * math.cos(a),
      );
      final Offset to = Offset(
        centre.dx + (r - 4) * math.sin(a),
        centre.dy - (r - 4) * math.cos(a),
      );
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialTicks oldDelegate) =>
      oldDelegate.color != color;
}

/// A classic two-tone needle: [head] points where [LumeQiblaDial.bearing]
/// says, [tail] is its quieter opposite half. Drawn pointing straight up (true
/// north, unrotated) inside its own box; [Transform.rotate] turns the whole
/// thing to the bearing, pivoting on the box's centre — which is the dial's
/// own centre, because the box is centred in the same [Stack].
class _NeedlePainter extends CustomPainter {
  const _NeedlePainter({required this.head, required this.tail});

  final Color head;
  final Color tail;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cy = h / 2;
    final double flare = w / 2;

    canvas.drawPath(
      Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, cy)
        ..lineTo(w / 2, cy - flare)
        ..lineTo(0, cy)
        ..close(),
      Paint()..color = head,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, cy)
        ..lineTo(w / 2, cy + flare)
        ..lineTo(w, cy)
        ..lineTo(w / 2, h)
        ..close(),
      Paint()..color = tail,
    );
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) =>
      oldDelegate.head != head || oldDelegate.tail != tail;
}
