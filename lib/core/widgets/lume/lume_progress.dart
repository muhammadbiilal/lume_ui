/// Progress: the bar, the meter row, the ring, the timeline and the journey.
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
          tone: tone,
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

/// `.tline` — a chronological list with a rail down its side.
class LumeTimeline extends StatelessWidget {
  const LumeTimeline({super.key, required this.entries});

  final List<LumeTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            first: i == 0,
            last: i == entries.length - 1,
            railColour: lume.border2,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.first,
    required this.last,
    required this.railColour,
  });

  final LumeTimelineEntry entry;
  final bool first;
  final bool last;
  final Color railColour;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color nodeColour = switch (entry.state) {
      LumeTimelineState.done => lume.accent,
      LumeTimelineState.now => lume.accent,
      LumeTimelineState.upcoming => lume.border2,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Measured: tabular 11 / 700, muted, nudged 1 px down so it sits on
          // the node's centre line.
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: LumeNumerals(
                entry.time ?? '',
                style: LumeType.numeric(
                  LumeType.fit(context, context.lumeType.metaSmall),
                ).copyWith(color: lume.text3, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 11),
          SizedBox(
            width: 14,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 5,
                  child: first
                      ? null
                      : VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: railColour,
                        ),
                ),
                Container(
                  width: entry.state == LumeTimelineState.now ? 12 : 9,
                  height: entry.state == LumeTimelineState.now ? 12 : 9,
                  decoration: BoxDecoration(
                    color: entry.state == LumeTimelineState.upcoming
                        ? lume.card
                        : nodeColour,
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColour, width: 2),
                  ),
                  child: entry.icon == null
                      ? null
                      : LumeIcon(entry.icon!, size: 8, color: lume.onAccent),
                ),
                if (!last)
                  Expanded(
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: railColour,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : LumeSpace.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    entry.title,
                    style: LumeType.fit(context, context.lumeType.meta)
                        .copyWith(
                          color: entry.state == LumeTimelineState.upcoming
                              ? lume.text2
                              : lume.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (entry.subtitle != null)
                    Text(
                      entry.subtitle!,
                      style: LumeType.fit(
                        context,
                        context.lumeType.metaSmall,
                      ).copyWith(color: lume.text3),
                    ),
                ],
              ),
            ),
          ),
          if (entry.value != null)
            LumeNumerals(
              entry.value!,
              style: LumeType.numeric(
                LumeType.fit(context, context.lumeType.meta),
              ).copyWith(color: lume.text2),
            ),
        ],
      ),
    );
  }
}

/// One step of a journey.
@immutable
class LumeJourneyStep {
  const LumeJourneyStep({
    required this.label,
    this.done = false,
    this.current = false,
  });

  final String label;
  final bool done;
  final bool current;
}

/// `.journey` — a horizontal progress presentation. A parcel, an application,
/// a multi-step form.
class LumeJourney extends StatelessWidget {
  const LumeJourney({super.key, required this.steps});

  final List<LumeJourneyStep> steps;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final int reached = steps.lastIndexWhere(
      (LumeJourneyStep s) => s.done || s.current,
    );

    return Semantics(
      label: 'Progress',
      value: reached < 0
          ? 'not started'
          : '${steps[reached].label}, step ${reached + 1} of ${steps.length}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < steps.length; i++)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: i == 0
                              ? const SizedBox(height: 2)
                              : Container(
                                  height: 2,
                                  color: i <= reached
                                      ? lume.accent
                                      : lume.border2,
                                ),
                        ),
                        Container(
                          width: steps[i].current ? 14 : 10,
                          height: steps[i].current ? 14 : 10,
                          decoration: BoxDecoration(
                            color: i <= reached ? lume.accent : lume.card,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: i <= reached ? lume.accent : lume.border2,
                              width: 2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: i == steps.length - 1
                              ? const SizedBox(height: 2)
                              : Container(
                                  height: 2,
                                  color: i < reached
                                      ? lume.accent
                                      : lume.border2,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i].label,
                      textAlign: TextAlign.center,
                      style: LumeType.fit(context, context.lumeType.metaSmall)
                          .copyWith(
                            color: i <= reached ? lume.text : lume.text3,
                            fontWeight: steps[i].current
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
