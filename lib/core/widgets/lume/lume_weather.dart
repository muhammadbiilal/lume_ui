/// The weather dashboard's own instruments — `.hourly`, `.tempbar`, `.aqi`
/// and `.sunarc` in `tools/shared.css`, measured on Weather
/// (`tool_weather_default_pk_*`).
library;

import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../layout/lume_breakpoint.dart';
import '../../layout/lume_measure.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_badge.dart';

/// One column of `.hourly`.
@immutable
class LumeHourlyItem {
  const LumeHourlyItem({
    required this.time,
    required this.icon,
    required this.temperature,
    required this.rain,
    this.now = false,
  });

  final String time;
  final String icon;
  final String temperature;
  final String rain;
  final bool now;
}

/// `.hourly` — the next hours on one scrolling rail.
///
/// Measured: columns 54 × 116, 4 apart, the rail's own gutter; each `12 4`
/// inside a one-point border at radius 12 — time 10 / 700 in `text-3`, icon
/// 18 in `text-2`, temperature 14 / 800 / −.03em, rain 10 / 600 in `sky`, 6
/// apart. The current hour is on the accent tint with its icon in the accent.
class LumeHourlyStrip extends StatelessWidget {
  const LumeHourlyStrip({super.key, required this.items, required this.label});

  final List<LumeHourlyItem> items;

  /// The rail's name for a screen reader — the section's title.
  final String label;

  static const double columnWidth = 54;
  static const double gap = 4;

  @override
  Widget build(BuildContext context) {
    // `padding: 0 var(--pad) 4px` — the page's gutter at this width.
    final double pad = LumeLayout.pageGutter(context.measureClass);
    return Semantics(
      container: true,
      label: label,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.only(start: pad, end: pad, bottom: 4),
        // A flex row stretches its columns to the tallest: one time that
        // wraps ("10:00 pm" in 46 points) makes every column that tall.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < items.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: gap),
                _HourColumn(item: items[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HourColumn extends StatelessWidget {
  const _HourColumn({required this.item});

  final LumeHourlyItem item;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle small = LumeType.natural(
      context,
      context.lumeType.metaSmall,
      size: 10,
    );
    return MergeSemantics(
      child: Container(
        width: LumeHourlyStrip.columnWidth,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: item.now ? lume.tintAccent : lume.card,
          borderRadius: LumeRadius.brSm,
          border: Border.all(
            color: item.now ? lume.accent.withValues(alpha: 0.30) : lume.border,
            width: LumeSpace.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
            Text(
              item.time,
              textAlign: TextAlign.center,
              style: small.copyWith(
                fontWeight: FontWeight.w700,
                color: lume.text3,
              ),
            ),
            ExcludeSemantics(
              child: LumeIcon(
                item.icon,
                size: 18,
                color: item.now ? lume.accent : lume.text2,
              ),
            ),
            LumeNumerals(
              item.temperature,
              style: LumeType.tracked(
                LumeType.natural(context, context.lumeType.body),
                -0.03,
              ).copyWith(fontWeight: FontWeight.w800, color: lume.text),
            ),
            LumeNumerals(
              item.rain,
              style: small.copyWith(
                fontWeight: FontWeight.w600,
                color: lume.sky,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.tempbar` — a day's low-to-high across the week's range.
///
/// 60 × 5 on the neutral tint, the span sky to amber, placed by percentage
/// from the inline start, so it reads from the right in RTL.
class LumeTempBar extends StatelessWidget {
  const LumeTempBar({super.key, required this.start, required this.end});

  /// Where the day's low sits across the range, in [0, 100].
  final int start;

  /// Where its high sits, in [0, 100].
  final int end;

  static const double width = 60;
  static const double height = 5;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final double left = width * start.clamp(0, 100) / 100;
    final double right = width * (100 - end.clamp(0, 100)) / 100;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: lume.tintNeutral,
            borderRadius: LumeRadius.full,
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                bottom: 0,
                left: rtl ? right : left,
                right: rtl ? left : right,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: LumeRadius.full,
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: <Color>[lume.sky, lume.amber],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One pollutant under `.aqi`.
@immutable
class LumeAqiPartItem {
  const LumeAqiPartItem({required this.value, required this.name});

  final String value;
  final String name;
}

/// `.aqi` with `.aqi__parts` — the index, its band and advice, and the
/// pollutants under a hairline.
///
/// Measured: the value column at its content, 34 / 800 / −.05em on 43 over
/// the unit 10 / 700 / .06em in `text-3`; 16 to the body — the band's badge,
/// then the advice 12 on 18 in `text-2` 7 below; the parts 14 under, past a
/// hairline and 13 of padding, each 14 / 800 over 10 / 600, 2 apart.
class LumeAqiCard extends StatelessWidget {
  const LumeAqiCard({
    super.key,
    required this.value,
    required this.unit,
    required this.badge,
    required this.advice,
    required this.parts,
  });

  final String value;
  final String unit;
  final LumeBadge badge;
  final String advice;
  final List<LumeAqiPartItem> parts;

  /// `.aqi` — the value and the body, without the parts under them.
  static const Key topKey = ValueKey<String>('aqi.top');
  static const Key valueKey = ValueKey<String>('aqi.value');
  static const Key bodyKey = ValueKey<String>('aqi.body');
  static const Key partsKey = ValueKey<String>('aqi.parts');

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle small = LumeType.natural(
      context,
      context.lumeType.metaSmall,
      size: 10,
    );
    final TextStyle strong = LumeType.tracked(
      LumeType.natural(context, context.lumeType.body),
      -0.03,
    ).copyWith(fontWeight: FontWeight.w800, color: lume.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          key: topKey,
          children: <Widget>[
            MergeSemantics(
              key: valueKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LumeNumerals(
                    value,
                    style: LumeType.tracked(
                      LumeType.natural(
                        context,
                        context.lumeType.display,
                        size: 34,
                      ),
                      -0.05,
                    ).copyWith(fontWeight: FontWeight.w800, color: lume.text),
                  ),
                  Text(
                    unit,
                    style: LumeType.tracked(
                      small.copyWith(fontWeight: FontWeight.w700),
                      0.06,
                    ).copyWith(color: lume.text3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                key: bodyKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // The badge is inline, so it sits in the body's 21-point
                  // line — 4.5 above it, half a point below.
                  Padding(
                    padding: const EdgeInsets.only(top: 4.5, bottom: 0.5),
                    child: badge,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    advice,
                    style: LumeType.fit(
                      context,
                      context.lumeType.meta,
                    ).copyWith(color: lume.text2, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          key: partsKey,
          padding: const EdgeInsets.only(top: 13),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: lume.border, width: LumeSpace.border),
            ),
          ),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < parts.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: MergeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        LumeNumerals(parts[i].value, style: strong),
                        const SizedBox(height: 2),
                        // `.aqi__part i` inherits the card's 1.4 line: 14,
                        // which makes the part the measured 34.
                        Text(
                          parts[i].name,
                          textAlign: TextAlign.center,
                          style: small.copyWith(
                            fontWeight: FontWeight.w600,
                            color: lume.text3,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// `.sunarc` — the day's arc from sunrise to sunset, the part already passed
/// drawn in amber and the sun where it is now.
///
/// Measured: 74 tall across the card; a dashed `border-2` half-ellipse (3 on,
/// 4 off, 2 wide) from 8 in and 6 up at each end, 58 high; the passed part
/// 2.5 wide in amber, round-capped; the sun a 6-radius amber dot ringed in the
/// card's colour. Sunrise and sunset under it, 8 below: 14 / 800 over 10 /
/// 600, the second at the end.
class LumeSunArc extends StatelessWidget {
  const LumeSunArc({
    super.key,
    required this.progress,
    required this.rise,
    required this.riseLabel,
    required this.set,
    required this.setLabel,
  });

  /// How far through the day the sun is, in [0, 1].
  final double progress;

  final String rise;
  final String riseLabel;
  final String set;
  final String setLabel;

  static const double arcHeight = 74;

  static const Key drawingKey = ValueKey<String>('sunarc.svg');
  static const Key endsKey = ValueKey<String>('sunarc.ends');

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle strong = LumeType.tracked(
      LumeType.natural(context, context.lumeType.body),
      -0.03,
    ).copyWith(fontWeight: FontWeight.w800, color: lume.text);
    final TextStyle small = LumeType.natural(
      context,
      context.lumeType.metaSmall,
      size: 10,
    ).copyWith(fontWeight: FontWeight.w600, color: lume.text3);

    Widget end(String time, String label, CrossAxisAlignment align) =>
        MergeSemantics(
          child: Column(
            crossAxisAlignment: align,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeNumerals(time, style: strong),
              const SizedBox(height: 1),
              Text(label, style: small),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: SizedBox(
            key: drawingKey,
            height: arcHeight,
            child: CustomPaint(
              painter: _SunArcPainter(
                progress: progress.clamp(0.0, 1.0),
                track: lume.border2,
                sun: lume.amber,
                ring: lume.card,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          key: endsKey,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            end(rise, riseLabel, CrossAxisAlignment.start),
            end(set, setLabel, CrossAxisAlignment.end),
          ],
        ),
      ],
    );
  }
}

class _SunArcPainter extends CustomPainter {
  const _SunArcPainter({
    required this.progress,
    required this.track,
    required this.sun,
    required this.ring,
    required this.rtl,
  });

  final double progress;
  final Color track;
  final Color sun;
  final Color ring;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    // The reference's viewBox is 200 × 74, stretched to the card's width.
    final double sx = size.width / 200;
    final double sy = size.height / 74;
    Offset at(double t) {
      final double u = rtl ? 1 - t : t;
      return Offset((8 + 184 * u) * sx, (68 - math.sin(math.pi * t) * 58) * sy);
    }

    final Path arc = Path()..moveTo(at(0).dx, at(0).dy);
    for (int i = 1; i <= 64; i++) {
      final Offset p = at(i / 64);
      arc.lineTo(p.dx, p.dy);
    }

    final Paint dashed = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final PathMetric m in arc.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 3, m.length)), dashed);
        d += 7;
      }
    }

    final Paint done = Paint()
      ..color = sun
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final PathMetric m in arc.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), done);
    }

    final Offset dot = at(progress);
    canvas.drawCircle(dot, 6 + 1.25, Paint()..color = ring);
    canvas.drawCircle(dot, 6 - 1.25, Paint()..color = sun);
  }

  @override
  bool shouldRepaint(_SunArcPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.sun != sun ||
      old.ring != ring ||
      old.rtl != rtl;
}
