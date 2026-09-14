/// A stylised map with a route and its markers — `components.js` `map()`.
///
/// The reference draws no tiles: "real tiles need a network; the
/// composition, markers and controls are what the spec asks the interface to
/// get right". Neither does this. It is a card-2 ground under two soft washes
/// and a 34-point grid, a dashed route in a 100 × 100 view box stretched to
/// the box, and pins placed by percentage inside the border.
///
/// Measured (`.lmap`, `tool_flights_*`): 168 tall, or 220 as `.lmap--tall`;
/// radius 20 inside a one-point border; pins 26 across, centred on their
/// point, a 13-point glyph, the active one accent inside a 5-point ring;
/// the caption 10 / 700 on a pill 12 in and 10 up, `4 9` of padding.
///
/// The reference's pins are `<button>`s with nothing behind them. These are
/// not pressable: each is announced by its name inside the map's group, and
/// nothing pretends to be a control (C73).
library;

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';

/// One marker, at a percentage of the map's inner box.
@immutable
class LumeMapPin {
  const LumeMapPin({
    required this.x,
    required this.y,
    required this.label,
    this.icon,
    this.active = false,
  });

  /// 0–100 across, from the start edge.
  final double x;

  /// 0–100 down.
  final double y;

  final String label;
  final String? icon;
  final bool active;
}

/// A cubic route through the view box — `M x0 y0 C x1 y1, x2 y2, x3 y3`.
@immutable
class LumeMapRoute {
  const LumeMapRoute(this.start, this.c1, this.c2, this.end);

  final Offset start;
  final Offset c1;
  final Offset c2;
  final Offset end;
}

/// `.lmap`.
class LumeMap extends StatelessWidget {
  const LumeMap({
    super.key,
    required this.label,
    this.pins = const <LumeMapPin>[],
    this.route,
    this.caption,
    this.tall = false,
  });

  final String label;
  final List<LumeMapPin> pins;
  final LumeMapRoute? route;
  final String? caption;

  /// `.lmap--tall`.
  final bool tall;

  static const double height = 168;
  static const double tallHeight = 220;
  static const double pinSize = 26;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      container: true,
      label: label,
      child: Container(
        height: tall ? tallHeight : height,
        decoration: BoxDecoration(
          color: lume.card2,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LumeSpace.border),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              LumeRadius.lg - LumeSpace.border,
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                final double w = box.maxWidth, h = box.maxHeight;
                // `left: x%` is from the left in both directions: the map is
                // a picture of places, and the reference does not mirror it.
                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: _GroundPainter(
                            accent: lume.accent,
                            sky: lume.sky,
                            grid: lume.border,
                            route: route,
                          ),
                        ),
                      ),
                    ),
                    for (final LumeMapPin p in pins)
                      if (!p.active) _pin(context, p, w, h),
                    for (final LumeMapPin p in pins)
                      if (p.active) _pin(context, p, w, h),
                    if (caption != null)
                      PositionedDirectional(
                        start: 12,
                        bottom: 10,
                        child: ExcludeSemantics(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 9,
                            ),
                            decoration: BoxDecoration(
                              color: lume.card.withValues(alpha: 0.82),
                              borderRadius: LumeRadius.full,
                            ),
                            child: Text(
                              caption!,
                              style:
                                  LumeType.natural(
                                    context,
                                    context.lumeType.metaSmall,
                                    size: 10,
                                  ).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: lume.text3,
                                    // The inline span's 14-point line, in a 22-point pill.
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _pin(BuildContext context, LumeMapPin p, double w, double h) {
    final LumeColors lume = context.lume;
    return Positioned(
      left: w * p.x / 100 - pinSize / 2,
      top: h * p.y / 100 - pinSize / 2,
      width: pinSize,
      height: pinSize,
      child: Semantics(
        label: p.label,
        selected: p.active,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.active ? lume.accent : lume.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: p.active ? lume.accent : lume.border,
              width: LumeSpace.border,
            ),
            boxShadow: p.active
                ? <BoxShadow>[
                    BoxShadow(
                      color: lume.accent.withValues(alpha: 0.22),
                      spreadRadius: 5,
                    ),
                  ]
                : context.lumeShadows.sm,
          ),
          child: p.icon == null
              ? Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: p.active ? lume.onAccent : lume.text2,
                    shape: BoxShape.circle,
                  ),
                )
              : LumeIcon(
                  p.icon!,
                  size: 13,
                  color: p.active ? lume.onAccent : lume.text2,
                ),
        ),
      ),
    );
  }
}

class _GroundPainter extends CustomPainter {
  const _GroundPainter({
    required this.accent,
    required this.sky,
    required this.grid,
    this.route,
  });

  final Color accent;
  final Color sky;
  final Color grid;
  final LumeMapRoute? route;

  @override
  void paint(Canvas canvas, Size size) {
    // `radial-gradient(70% 90% at 20% 10%, accent 12%, transparent 70%)` and
    // `radial-gradient(60% 80% at 90% 90%, sky 12%, transparent 70%)`.
    void wash(Offset at, double rx, double ry, Color c) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(1, ry / rx);
      canvas.drawCircle(
        Offset.zero,
        rx,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[c.withValues(alpha: 0.12), c.withValues(alpha: 0)],
            stops: const <double>[0, 0.7],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: rx)),
      );
      canvas.restore();
    }

    wash(
      Offset(size.width * 0.2, size.height * 0.1),
      size.width * 0.7,
      size.height * 0.9,
      accent,
    );
    wash(
      Offset(size.width * 0.9, size.height * 0.9),
      size.width * 0.6,
      size.height * 0.8,
      sky,
    );

    // `.lmap__grid` — one-point lines every 34, at half strength.
    final Paint line = Paint()..color = grid.withValues(alpha: grid.a * 0.5);
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), line);
    }

    final LumeMapRoute? r = route;
    if (r != null) {
      Offset at(Offset v) =>
          Offset(v.dx * size.width / 100, v.dy * size.height / 100);
      final Path curve = Path()
        ..moveTo(at(r.start).dx, at(r.start).dy)
        ..cubicTo(
          at(r.c1).dx,
          at(r.c1).dy,
          at(r.c2).dx,
          at(r.c2).dy,
          at(r.end).dx,
          at(r.end).dy,
        );
      // `stroke-width: 1.6; stroke-dasharray: 4 3; opacity: .8`.
      final Paint stroke = Paint()
        ..color = accent.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      for (final PathMetric m in curve.computeMetrics()) {
        for (double d = 0; d < m.length; d += 7) {
          canvas.drawPath(m.extractPath(d, d + 4), stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GroundPainter old) =>
      old.accent != accent ||
      old.sky != sky ||
      old.grid != grid ||
      old.route != route;
}
