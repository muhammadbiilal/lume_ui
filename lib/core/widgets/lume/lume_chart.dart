/// Charts, painted rather than borrowed.
///
/// `components.js` draws every chart as hand-written SVG — a donut is two
/// stroked circles with a dash array, not a charting library's pie — and
/// `COMPONENT_MATRIX.md` holds that their contracts come from the tools that
/// draw them. The donut is proved shared by Tax, Expenses, Loan, Faraid,
/// Subscriptions and Baby Budget, and it is built first because Tax is.
///
/// Measured on the running reference (`tool_tax_default_pk_390x844_light_en`):
///
/// | | size | type |
/// |---|---|---|
/// | `.donut` | 116 × 116, ring r 42 / stroke 14 on a 100 view box | — |
/// | `.donut__mid b` | 18 tall | 14 / 800 / −0.038em |
/// | `.donut__mid i` | 12 tall, 1 below | 10 / 600, muted |
/// | `.donut__key` | 13 tall, 7 apart, 9 × 9 swatch at radius 3 | 11 / 600 label, 700 value |
/// | `.donutwrap` | 18 between disc and legend; legend at least 130 | — |
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';

/// One slice of a donut.
@immutable
class LumeDonutSlice {
  const LumeDonutSlice({
    required this.label,
    required this.value,
    required this.color,
    this.display,
  });

  final String label;
  final double value;
  final Color color;

  /// What the legend prints for this slice. `null` prints its share, rounded
  /// to a whole percent — `Math.round(value / total * 100) + '%'`.
  final String? display;
}

/// `.donutwrap` — a ring of shares with its legend beside it.
///
/// The legend moves under the ring when the two do not fit side by side,
/// which is `flex-wrap` with a 130-point floor on the legend.
class LumeDonut extends StatelessWidget {
  const LumeDonut({
    super.key,
    required this.slices,
    required this.centre,
    required this.label,
    this.centreSub,
  });

  final List<LumeDonutSlice> slices;

  /// The figure in the hole, already formatted.
  final String centre;
  final String? centreSub;

  /// The figure's accessible name — `aria-label` on the `<figure>`.
  final String label;

  static const double size = 116;
  static const double gap = 18;
  static const double legendMinWidth = 130;

  /// The ring, in the SVG's own 100-unit view box.
  static const double viewBox = 100;
  static const double radius = 42;
  static const double stroke = 14;

  double get _total {
    final double t = slices.fold(
      0,
      (double a, LumeDonutSlice s) => a + s.value,
    );
    return t == 0 ? 1 : t;
  }

  /// The legend's default text for [slice].
  String shareOf(LumeDonutSlice slice) =>
      slice.display ?? '${(slice.value / _total * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double total = _total;

    final Widget disc = SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            painter: _DonutPainter(slices: slices, total: total),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LumeNumerals(
                  centre,
                  style: LumeType.numeric(
                    LumeType.tracked(
                      LumeType.natural(
                        context,
                        context.lumeType.label,
                        size: 14,
                      ),
                      -0.038,
                    ),
                  ).copyWith(fontWeight: FontWeight.w800, color: lume.text),
                  maxLines: 1,
                ),
                if (centreSub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      centreSub!,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                            size: 10,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            color: lume.text3,
                          ),
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final Widget legend = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < slices.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 7),
          _Key(slice: slices[i], share: shareOf(slices[i])),
        ],
      ],
    );

    return Semantics(
      container: true,
      label: label,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          if (c.maxWidth >= size + gap + legendMinWidth) {
            return Row(
              children: <Widget>[
                disc,
                const SizedBox(width: gap),
                Expanded(child: legend),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(alignment: AlignmentDirectional.centerStart, child: disc),
              const SizedBox(height: gap),
              legend,
            ],
          );
        },
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.slice, required this.share});

  final LumeDonutSlice slice;
  final String share;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle base = LumeType.natural(
      context,
      context.lumeType.metaSmall,
      size: 11,
    );
    return Row(
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: slice.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            slice.label,
            style: base.copyWith(
              fontWeight: FontWeight.w600,
              color: lume.text2,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        LumeNumerals(
          share,
          style: LumeType.numeric(
            LumeType.tracked(base, -0.02),
          ).copyWith(fontWeight: FontWeight.w700, color: lume.text),
          maxLines: 1,
        ),
      ],
    );
  }
}

/// The ring: one stroked arc per slice, from twelve o'clock, clockwise.
///
/// The SVG draws each slice as a whole circle whose dash is the slice's share
/// of the circumference, offset by the shares before it, with the element
/// rotated −90°. An arc of the same length from the same angle is that, with
/// butt ends, and it does not mirror in a right-to-left page — the reference's
/// ring does not either.
class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.total});

  final List<LumeDonutSlice> slices;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / LumeDonut.viewBox);
    canvas.rotate(-math.pi / 2);
    final Rect ring = Rect.fromCircle(
      center: Offset.zero,
      radius: LumeDonut.radius,
    );
    double start = 0;
    for (final LumeDonutSlice s in slices) {
      final double share = s.value / total;
      if (share > 0) {
        canvas.drawArc(
          ring,
          start * 2 * math.pi,
          share * 2 * math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = LumeDonut.stroke
            ..strokeCap = StrokeCap.butt
            ..color = s.color,
        );
      }
      start += share;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.total != total || !_same(old.slices, slices);

  static bool _same(List<LumeDonutSlice> a, List<LumeDonutSlice> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}
