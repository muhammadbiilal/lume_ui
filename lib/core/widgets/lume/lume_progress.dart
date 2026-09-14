/// Progress: the bar, the meter row, the ring and the timeline. The journey is
/// lume_journey.dart.
///
/// Measured: `.pbar` is 6 px tall, pill-shaped, on a 14 %-ink track.
/// `.tline__item` uses an 11 px gap and a tabular 11 / 700 time column.
///
/// All four announce their value. A progress indicator a screen reader reports
/// as "progress bar" and nothing else has told the user nothing.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';

/// `.pbar` — a determinate bar.
class LumeProgressBar extends StatelessWidget {
  const LumeProgressBar({
    super.key,
    required this.value,
    this.label,
    this.valueText,
    this.tone,
  });

  /// 0–1. Clamped, because a percentage over 100 is a bug upstream and a bar
  /// that overflows its track is that bug made visible in the wrong place.
  final double value;

  final String? label;

  /// What a screen reader says instead of a raw percentage.
  final String? valueText;

  final Color? tone;

  static const double height = 6;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double v = value.clamp(0.0, 1.0);

    return Semantics(
      label: label,
      value: valueText ?? '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: LumeRadius.full,
        child: Container(
          height: height,
          color: lume.text.withValues(alpha: 0.14),
          child: AnimatedFractionallySizedBox(
            duration: LumeMotion.duration(context, LumeMotion.slow),
            curve: LumeMotion.easeOut,
            alignment: AlignmentDirectional.centerStart,
            widthFactor: v,
            child: ColoredBox(color: tone ?? lume.accent),
          ),
        ),
      ),
    );
  }
}

/// `.meter` — a labelled bar with its value beside the label.
class LumeMeterRow extends StatelessWidget {
  const LumeMeterRow({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    this.footnote,
    this.tone,
  });

  final String label;

  /// The formatted value — "6 of 10 glasses".
  final String value;

  final double progress;
  final String? footnote;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: LumeType.fit(
                  context,
                  context.lumeType.meta,
                ).copyWith(color: lume.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: LumeSpace.x2),
            LumeNumerals(
              value,
              style: LumeType.numeric(
                LumeType.fit(context, context.lumeType.meta),
              ).copyWith(color: lume.text2),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LumeProgressBar(
          value: progress,
          label: label,
          valueText: value,
          // `.pbar__fill { background: currentColor }` — outside a summary a
          // meter is drawn in the ink, and only a tone colours it (C83).
          tone: tone ?? lume.text,
        ),
        if (footnote != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            footnote!,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3),
          ),
        ],
      ],
    );
  }
}

/// `.pring` — a ring with a value in the middle.
///
/// Measured on Learning's summary: 66 × 66 (`.pring--lg` is 92), a ring of
/// radius 30 and stroke 7 on a 72 view box, so both scale with the size; the
/// track is the ring's own colour at 16 %, the arc has round ends and starts at
/// twelve o'clock; the centre is 14 / 800 / −0.04em over an optional
/// 11 / 600 line at .8.
class LumeProgressRing extends StatelessWidget {
  const LumeProgressRing({
    super.key,
    required this.value,
    this.centre,
    this.centreValue,
    this.centreSub,
    this.label,
    this.valueText,
    this.size = defaultSize,
    this.stroke,
    this.tone,
    this.centreInk,
  });

  final double value;

  /// What sits inside the ring, when it is more than a figure.
  final Widget? centre;

  /// `.pring__mid b` and `i` — the figure, and a word under it.
  final String? centreValue;
  final String? centreSub;

  final String? label;
  final String? valueText;
  final double size;

  /// `null` is the reference's 7 on 72, at this size.
  final double? stroke;
  final Color? tone;

  /// The centre's ink — `text` on a plain card, `--on-grad` on a gradient.
  final Color? centreInk;

  static const double defaultSize = 66;
  static const double largeSize = 92;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double v = value.clamp(0.0, 1.0);
    final Color fill = tone ?? lume.accent;
    final Color ink = centreInk ?? lume.text;

    return Semantics(
      label: label,
      value: valueText ?? '${(v * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                value: v,
                track: fill.withValues(alpha: 0.16),
                fill: fill,
                stroke: stroke ?? 7 * size / 72,
                radius: 30 * size / 72,
              ),
            ),
            if (centre != null)
              ExcludeSemantics(child: centre!)
            else if (centreValue != null)
              ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LumeNumerals(
                      centreValue!,
                      style: LumeType.numeric(
                        LumeType.tracked(
                          LumeType.natural(
                            context,
                            context.lumeType.body,
                          ).copyWith(fontWeight: FontWeight.w800),
                          -0.04,
                        ),
                      ).copyWith(color: ink),
                    ),
                    if (centreSub != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Opacity(
                          opacity: 0.8,
                          child: Text(
                            centreSub!,
                            style: LumeType.natural(
                              context,
                              context.lumeType.metaSmall,
                            ).copyWith(color: ink, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
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
    required this.value,
    required this.track,
    required this.fill,
    required this.stroke,
    required this.radius,
  });

  final double value;
  final Color track;
  final Color fill;
  final double stroke;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);

    final Paint base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centre, radius, base);

    if (value <= 0) return;
    final Paint arc = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.fill != fill || old.track != track;
}

/// One entry on a timeline.
@immutable
class LumeTimelineEntry {
  const LumeTimelineEntry({
    required this.title,
    this.time,
    this.subtitle,
    this.meta,
    this.value,
    this.icon,
    this.state = LumeTimelineState.upcoming,
  });

  final String title;
  final String? time;
  final String? subtitle;
  final String? meta;
  final String? value;
  final String? icon;
  final LumeTimelineState state;
}

/// Where an entry sits relative to now.
enum LumeTimelineState { done, now, upcoming }

/// `.tline` -- a chronological list with a rail down its side.
///
/// Stylesheet: each item a row 11 apart, 16 below it and none after the last;
/// a 52-point time gutter, 11 / 700 muted in tabular figures, end-aligned and
/// 1 down; a 16-point rail holding a 14-point node 3 down, its line 1.5 wide
/// in `--border` from 18 down to the next node; the body's 13 / 700 title,
/// 11 / 500 sub 2 below it and 10 / 500 meta 3 below that; a 12 / 700 value at
/// the end. A done node fills muted around a card-coloured glyph; now fills
/// with the accent inside a 4-point tint ring; upcoming is a card inside
/// `--border-2`, and a done item's title steps back to `--text-2`.
class LumeTimeline extends StatelessWidget {
  const LumeTimeline({super.key, required this.entries});

  final List<LumeTimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (int i = 0; i < entries.length; i++)
        _TimelineRow(entry: entries[i], last: i == entries.length - 1),
    ],
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.last});

  final LumeTimelineEntry entry;
  final bool last;

  /// `.tline__item { padding-bottom: 16px }`.
  static const double gap = 16;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool done = entry.state == LumeTimelineState.done;
    final bool now = entry.state == LumeTimelineState.now;
    final (Color fill, Color ring, Color glyph) = done
        ? (lume.text3, lume.text3, lume.card)
        : now
        ? (lume.accent, lume.accent, lume.onAccent)
        : (lume.card, lume.border2, const Color(0x00000000));

    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : gap),
      // .tline__rail is 20 tall — a 14-point node 3 down — so an entry with
      // only a title is 20, not the title's own line.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: LumeNumerals(
                      entry.time ?? '',
                      style:
                          LumeType.numeric(
                            LumeType.natural(
                              context,
                              context.lumeType.metaSmall,
                              size: 11,
                            ),
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            color: lume.text3,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              SizedBox(
                width: 16,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    if (!last)
                      PositionedDirectional(
                        start: 8 - 0.75,
                        top: 18,
                        bottom: -gap,
                        width: 1.5,
                        child: ColoredBox(color: lume.border),
                      ),
                    PositionedDirectional(
                      start: 1,
                      top: 3,
                      child: Container(
                        width: 14,
                        height: 14,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: fill,
                          shape: BoxShape.circle,
                          border: Border.all(color: ring, width: 2),
                          boxShadow: now
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: lume.tintAccent,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: entry.icon == null
                            ? null
                            : LumeIcon(entry.icon!, size: 8, color: glyph),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        entry.title,
                        style:
                            LumeType.tracked(
                              LumeType.natural(
                                context,
                                context.lumeType.body,
                                size: 13,
                              ),
                              -0.024,
                            ).copyWith(
                              fontWeight: FontWeight.w700,
                              color: done ? lume.text2 : lume.text,
                            ),
                      ),
                      if (entry.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            entry.subtitle!,
                            style:
                                LumeType.natural(
                                  context,
                                  context.lumeType.metaSmall,
                                  size: 11,
                                ).copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: lume.text2,
                                ),
                          ),
                        ),
                      if (entry.meta != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            entry.meta!,
                            style:
                                LumeType.natural(
                                  context,
                                  context.lumeType.metaSmall,
                                  size: 10,
                                ).copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: lume.text3,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (entry.value != null) ...<Widget>[
                const SizedBox(width: 11),
                LumeNumerals(
                  entry.value!,
                  style: LumeType.numeric(
                    LumeType.natural(context, context.lumeType.label, size: 12),
                  ).copyWith(fontWeight: FontWeight.w700, color: lume.text2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
