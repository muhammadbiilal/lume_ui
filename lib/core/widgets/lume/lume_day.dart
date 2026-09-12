/// Today's own furniture: the ring card, the statistics row, the agenda
/// timeline, the task list and the habit strip.
///
/// Every one of these is a *new* component rather than a near-miss reused.
/// The temptation was real — the library already has `LumeProgressRing`,
/// `LumeTimeline`, `LumeMetrics` and `LumeRichRow` — and every one of them is
/// a different CSS class with different measurements:
///
/// | here | already existed | why not that one |
/// |---|---|---|
/// | `.ring` 82 × 82, r 42, stroke 9, label inside | `.pring` | a different size, and its value sits beside it rather than in it |
/// | `.timeline` / `.tl-item` | `.tline` | a rail with a 50-point time gutter, not a plain rail |
/// | `.stats` / `.stat` | `.metrics` | three fixed columns, 13/12 padding, a glyph above the figure |
/// | `.list-row` | `.rrow` | 14/700 title over an 11/500 sub, a value and a chevron at the end |
///
/// Measured from the running screen rather than read off the stylesheet, so
/// the numbers here are what it renders and not what it declares.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';

/// The measured constants for Today and Explore.
abstract final class LumeDayMetrics {
  /// `.ring { width: 82px; height: 82px }`.
  static const double ringSize = 82;

  /// `stroke-width: 9` on a circle of `r: 42` in a 100-unit box.
  static const double ringStroke = 9;

  /// The clear space inside the arc: `2 * (42 - 9 / 2)` of the 100-unit box,
  /// scaled to the rendered size. The label lives here, and at a text scale
  /// the reference never has to survive it shrinks to stay inside rather than
  /// spilling over the arc.
  static const double ringInner = (42 - ringStroke / 2) * 2 * ringSize / 100;

  /// `.ring-card { gap: 16px; padding: 16px }`.
  static const double ringCardPadding = 16;
  static const double ringCardGap = 16;

  /// `.stats { grid-template-columns: repeat(3, 1fr); gap: 10px }`.
  static const double statGap = 10;

  /// `.stat { padding: 13px 12px }`, measured 110 × 91 at the reference cell.
  static const EdgeInsets statPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 13,
  );

  /// `.tl-time { width: 50px; padding-top: 13px }`.
  static const double timeGutter = 50;

  /// `.tl-item { gap: 13px; padding-bottom: 14px }`.
  static const double timelineGap = 13;
  static const double timelineRowGap = 14;

  /// `.tl-line { width: 11px }` with a 9-point node 15 down.
  static const double railWidth = 11;
  static const double nodeSize = 9;
  static const double nodeTop = 15;

  /// `.tl-card { padding: 12px 14px; gap: 11px }`.
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  /// `.task { padding: 13px 15px; gap: 12px }`, measured 48 tall.
  static const EdgeInsets taskPadding = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 13,
  );

  /// `.task__box { width: 21px; height: 21px; border-radius: 7px }`.
  static const double checkboxSize = 21;

  /// `.habits { gap: 10px; padding: 14px 15px }`.
  static const EdgeInsets habitsPadding = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 14,
  );
  static const double habitGap = 10;

  /// `.habit { gap: 12px }`, `.habit__name { width: 78px }`,
  /// `.habit__days { gap: 5px }`, `.habit__day { height: 22px }`.
  static const double habitNameWidth = 78;
  static const double habitDayGap = 5;
  static const double habitDayHeight = 22;
}

/// `.ring` — the day's progress as an arc with its share written in the
/// middle.
///
/// *"The share of the day is text as well as an arc, so the progress is not
/// carried by the drawing alone."* The reference's own comment, and the reason
/// the value is a `Text` here rather than a label painted into the canvas: a
/// screen reader gets the number, not a description of a circle.
class LumeDayRing extends StatelessWidget {
  const LumeDayRing({
    super.key,
    required this.fraction,
    required this.label,
    required this.unit,
  });

  /// 0–1.
  final double fraction;

  /// The share, already formatted — "70 %".
  final String label;

  /// What the share is *of*.
  final String unit;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      label: '$label $unit',
      excludeSemantics: true,
      child: SizedBox(
        width: LumeDayMetrics.ringSize,
        height: LumeDayMetrics.ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              size: const Size.square(LumeDayMetrics.ringSize),
              painter: _RingPainter(
                fraction: fraction.clamp(0.0, 1.0),
                track: lume.tintNeutral,
                fill: lume.accent,
              ),
            ),
            // The ring is a fixed circle, so what is written in it cannot
            // grow with the reader's text size — at 200 % the two lines are
            // half again as tall as the arc is wide. They scale down to fit
            // instead of being clipped, which is the overflow exception the
            // visual-authority rule allows. At every scale the reference is
            // rendered at, nothing is scaled at all and the label is drawn at
            // its measured size.
            SizedBox.square(
              dimension: LumeDayMetrics.ringInner,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LumeNumerals(
                      label,
                      style: LumeType.tracked(
                        LumeType.natural(
                          context,
                          context.lumeType.title,
                          size: 20,
                        ),
                        -0.045,
                      ).copyWith(color: lume.text, fontWeight: FontWeight.w800),
                    ),
                    // `margin-top: -1px` in the stylesheet, which closes the gap
                    // the two natural lines leave.
                    Transform.translate(
                      offset: const Offset(0, -1),
                      child: Text(
                        unit,
                        style:
                            LumeType.natural(
                              context,
                              context.lumeType.tab,
                              size: 10,
                            ).copyWith(
                              color: lume.text3,
                              fontWeight: FontWeight.w600,
                            ),
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

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.track,
    required this.fill,
  });

  final double fraction;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    // `r: 42` in a 100-unit viewBox, scaled to the rendered box.
    final double scale = size.width / 100;
    final double radius = 42 * scale;
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = LumeDayMetrics.ringStroke * scale;

    canvas.drawCircle(centre, radius, base..color = track);
    if (fraction <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      // `transform: rotate(-90deg)` on the svg — the arc starts at the top.
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      base
        ..color = fill
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.fill != fill;
}

/// `.ring-card` — the ring, a title and a line about the day.
class LumeRingCard extends StatelessWidget {
  const LumeRingCard({
    super.key,
    required this.ring,
    required this.title,
    required this.text,
    this.sticker,
  });

  final Widget ring;
  final String title;
  final String text;

  /// `<span class="sticker sticker--slow" style="top:-12px;right:-6px">` — a
  /// 46-point sparkle that overhangs the card's top corner and drifts. Handed
  /// in rather than drawn here, so the component does not import a feature's
  /// artwork.
  final Widget? sticker;

  /// Where the sparkle sits, measured from the card's own corner.
  static const double stickerTop = -12;
  static const double stickerEnd = -6;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Widget card = Container(
      padding: const EdgeInsets.all(LumeDayMetrics.ringCardPadding),
      decoration: BoxDecoration(
        color: lume.card,
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ring,
          const SizedBox(width: LumeDayMetrics.ringCardGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: LumeType.tracked(
                    LumeType.natural(
                      context,
                      context.lumeType.cardTitle,
                      size: 15,
                    ),
                    -0.028,
                  ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  // `line-height: 1.45` rather than the natural line: this one
                  // wraps, and the stylesheet says what it wraps on.
                  style: context.lumeType.meta.copyWith(
                    color: lume.text2,
                    height: LumeType.lineHeight(context, 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (sticker == null) return card;
    return Stack(
      // The sparkle hangs past two of the card's edges, as the reference's
      // negative offsets do, and it is decoration: no hit test, no semantics.
      clipBehavior: Clip.none,
      children: <Widget>[
        card,
        PositionedDirectional(
          top: stickerTop,
          end: stickerEnd,
          child: IgnorePointer(
            child: ExcludeSemantics(
              // `--sticker-opacity` — 1 in light, .72 in dark, over the .14
              // the artwork itself carries.
              child: Opacity(opacity: lume.stickerOpacity, child: sticker!),
            ),
          ),
        ),
      ],
    );
  }
}

/// `.stat` — a glyph, a figure and a label, in a fixed-width column.
class LumeStatCard extends StatelessWidget {
  const LumeStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
  });

  final String icon;

  /// The figure on its own, so it is the size the design gives a figure.
  final String value;

  /// What follows it in a smaller, muted face — "days", "/5".
  final String? unit;

  final String label;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      label: '$value${unit ?? ''}, $label',
      excludeSemantics: true,
      child: Container(
        padding: LumeDayMetrics.statPadding,
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brMd,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // `.stat__icon { margin-bottom: 8px }`, a 16-point glyph.
            LumeIcon(icon, size: 16, color: lume.accent),
            const SizedBox(height: 8),
            LumeNumerals.rich(
              children: <InlineSpan>[
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: unit,
                    style: LumeType.natural(
                      context,
                      context.lumeType.metaSmall,
                      size: 11,
                    ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
                  ),
              ],
              style: LumeType.tracked(
                LumeType.natural(context, context.lumeType.title, size: 20),
                -0.04,
              ).copyWith(color: lume.text, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LumeType.natural(
                context,
                context.lumeType.tab,
                size: 10,
              ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.stats` — three equal columns.
///
/// Three, not "as many as fit": the reference declares
/// `repeat(3, 1fr)` and the row is chosen for the reader rather than filled.
class LumeStatRowGrid extends StatelessWidget {
  const LumeStatRowGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: LumeDayMetrics.statGap),
          Expanded(child: children[i]),
        ],
      ],
    ),
  );
}
