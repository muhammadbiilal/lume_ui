/// The cards a primary destination is filled with.
///
/// Every one of these is shared: Home and the Tools hub both draw tiles, Home
/// and Today both draw progress cards and statistic rows, Home, Explore and
/// Trains all draw the horizontal strip's mini-cards. So they live here rather
/// than in the first screen that needed one.
///
/// Measured at 390 × 844, from the running prototype:
///
/// | | measured |
/// |---|---|
/// | `.ctx` | 66 tall, `13 15`, 20 radius, 38 disc, label 10/700/0.07em |
/// | `.tool` | 80 × 112, `12 4 11`, 16 radius, 38 disc, label 11/600 |
/// | `.cat-tool` | 110 × 96, `13 12 14`, 16 radius, 20 glyph, label 12/600 |
/// | `.qaction` | 44 tall, `9 14 9 10`, pill, 24 disc, label 12/600 |
/// | `.livecard` | 70 tall, `14 15`, 20 radius, 40 disc, value 17/800 |
/// | `.progress-card` | 86 tall, `15 16`, 54 art, title 15/700, bar 5 |
/// | `.stat-row` | 74 tall, `16`, 40 disc, value 15/800 |
/// | `.minicard` | 148 × 140, 84 of art, title 13/700 |
/// | `.recent` | 46 tall, `9 13 9 9`, pill, 26 disc |
/// | `.chip` | 32 tall, `0 13`, pill; active fills with `--text` |
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// Which wash an icon disc wears. Named for what it means, never for a colour:
/// a card cannot then be given the wrong tone for its content.
enum LumeCardTone {
  /// The brand tint. The default.
  accent,

  /// Weather and anything about the sky.
  sky,

  /// A warning — an outage, an overdue bill.
  warn,

  /// A figure that rose.
  up,

  /// A figure that fell.
  down,

  /// No colour at all.
  neutral,
}

/// The disc an icon sits in, with the wash its tone calls for.
class LumeToneDisc extends StatelessWidget {
  const LumeToneDisc({
    super.key,
    required this.icon,
    this.tone = LumeCardTone.accent,
    this.size = 40,
    this.iconSize = 19,
    this.radius,
  });

  final String icon;
  final LumeCardTone tone;
  final double size;
  final double iconSize;
  final BorderRadius? radius;

  static Color foreground(LumeColors lume, LumeCardTone tone) => switch (tone) {
    LumeCardTone.accent => lume.accent,
    LumeCardTone.sky => lume.sky,
    LumeCardTone.warn => lume.amber,
    LumeCardTone.up => lume.up,
    LumeCardTone.down => lume.down,
    LumeCardTone.neutral => lume.text2,
  };

  static Color background(LumeColors lume, LumeCardTone tone) => switch (tone) {
    LumeCardTone.accent => lume.tintAccent,
    LumeCardTone.sky => lume.tone(lume.sky),
    LumeCardTone.warn => lume.toneAmber,
    // `color-mix(in srgb, var(--up) 14%, transparent)`.
    LumeCardTone.up => lume.tone(lume.up, opacity: 0.14),
    LumeCardTone.down => lume.tone(lume.down, opacity: 0.14),
    LumeCardTone.neutral => lume.tintNeutral,
  };

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background(lume, tone),
        borderRadius: radius ?? LumeRadius.brIcon,
      ),
      alignment: Alignment.center,
      child: LumeIcon(icon, size: iconSize, color: foreground(lume, tone)),
    );
  }
}

/// `.ctx` — Home's contextual strip.
///
/// A label in small caps, a title, and a value at the end. The artwork behind
/// it bleeds to the card's edge, which is why it is a [Stack] rather than a
/// decoration: `inset: 0` is the card, not the padded box.
class LumeContextStrip extends StatelessWidget {
  const LumeContextStrip({
    super.key,
    required this.icon,
    required this.label,
    required this.title,
    required this.value,
    required this.unit,
    required this.semanticLabel,
    this.background,
    this.onTap,
    this.tone = LumeCardTone.accent,
  });

  final String icon;

  /// `.ctx__label` — 10/700, 0.07em, upper-cased.
  final String label;

  /// `.ctx__title` — 15/600. Built by the caller, because it mixes an 800
  /// fragment with a 600 one.
  final Widget title;

  /// `.ctx__count` — 17/800 accent.
  final String value;

  /// `.ctx__unit` — 10/600 muted.
  final String unit;

  final String semanticLabel;

  /// The decorative wash. Bleeds to the card's edge.
  final Widget? background;

  final VoidCallback? onTap;
  final LumeCardTone tone;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      borderRadius: LumeRadius.brLg,
      minSize: 0,
      child: Container(
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            if (background != null)
              Positioned.fill(child: ExcludeSemantics(child: background!)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
              child: ExcludeSemantics(
                child: Row(
                  children: <Widget>[
                    LumeToneDisc(
                      icon: icon,
                      tone: tone,
                      size: 38,
                      iconSize: 19,
                    ),
                    const SizedBox(width: LumeSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            label.toUpperCase(),
                            style: LumeType.tracked(
                              LumeType.natural(context, context.lumeType.tab),
                              0.07,
                            ).copyWith(color: lume.text3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          title,
                        ],
                      ),
                    ),
                    const SizedBox(width: LumeSpace.x2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        LumeNumerals(
                          value,
                          style:
                              LumeType.numeric(
                                LumeType.tracked(
                                  LumeType.natural(
                                    context,
                                    context.lumeType.section,
                                  ),
                                  -0.04,
                                ),
                              ).copyWith(
                                color: lume.accent,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          unit,
                          style: LumeType.natural(context, context.lumeType.tab)
                              .copyWith(
                                color: lume.text3,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
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

/// `.tool` — a quick-tool tile. Icon over a centred label.
class LumeToolTile extends StatelessWidget {
  const LumeToolTile({
    super.key,
    required this.icon,
    required this.label,
    this.status,
    this.accent = false,
    this.onTap,
  });

  final String icon;
  final String label;

  /// `.tool__value` — the small status line under the label.
  final String? status;

  /// `.tool__icon--accent` — a faith feature's disc is tinted.
  final bool accent;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: status == null ? label : '$label, $status',
      borderRadius: LumeRadius.brMd,
      minSize: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 11),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brMd,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.xs,
        ),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent ? lume.tintAccent : lume.tintNeutral,
                  borderRadius: LumeRadius.brIcon,
                ),
                alignment: Alignment.center,
                child: LumeIcon(
                  icon,
                  size: 18.5,
                  color: accent ? lume.accent : lume.text,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style:
                    LumeType.tracked(
                      LumeType.natural(
                        context,
                        context.lumeType.metaSmall,
                      ).copyWith(fontWeight: FontWeight.w600),
                      -0.015,
                    ).copyWith(
                      color: lume.text,
                      height: LumeType.lineHeight(context, 1.2),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (status != null)
                // `.tool__value { margin-top: -3px }` — it rides up into the
                // label's descender space rather than sitting under it.
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LumeNumerals(
                    status!,
                    style: LumeType.tracked(
                      LumeType.natural(context, context.lumeType.tab),
                      -0.03,
                    ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which marker a catalogue tile wears in its corner.
///
/// The three compete for one corner, so the precedence is declared rather than
/// left to whichever branch runs last. Privacy wins: a sensitive tool shows
/// its lock even when it also has a count, because the lock is a promise and
/// the count is information.
enum LumeTileMarker { none, private, count, local }

/// `.cat-tool` — a catalogue tile in the Tools hub.
///
/// Icon at the top, label pushed to the bottom (`margin-top: auto`), status
/// under it, and one marker in the trailing corner.
class LumeCatalogueTile extends StatelessWidget {
  const LumeCatalogueTile({
    super.key,
    required this.icon,
    required this.label,
    this.status,
    this.marker = LumeTileMarker.none,
    this.count,
    this.markerLabel,
    this.accent = false,
    this.onTap,
  });

  final String icon;
  final String label;
  final String? status;
  final LumeTileMarker marker;

  /// The number behind [LumeTileMarker.count].
  final int? count;

  /// What a screen reader calls the marker.
  final String? markerLabel;

  /// `.cat--islamic .cat-tool__icon` — a faith category's glyph is accented.
  final bool accent;

  final VoidCallback? onTap;

  /// `.cat-tool { min-height: 92px }`.
  static const double minHeight = 92;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: <String>[label, ?status, ?markerLabel].join(', '),
      borderRadius: LumeRadius.brMd,
      minSize: 0,
      child: Container(
        constraints: const BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.fromLTRB(12, 13, 12, 14),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brMd,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.xs,
        ),
        child: ExcludeSemantics(
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LumeIcon(
                    icon,
                    size: LumeSpace.iconMd,
                    color: accent ? lume.accent : lume.text,
                  ),
                  // `.cat-tool__label { margin-top: auto }`: in a row where a
                  // neighbour's label wraps to two lines, every tile is
                  // stretched and the shorter ones push their label and status
                  // to the bottom rather than leaving a gap under them.
                  const SizedBox(height: 9),
                  const Spacer(),
                  Text(
                    label,
                    style:
                        LumeType.tracked(
                          LumeType.natural(
                            context,
                            context.lumeType.label,
                          ).copyWith(fontWeight: FontWeight.w600),
                          -0.022,
                        ).copyWith(
                          color: lume.text,
                          height: LumeType.lineHeight(context, 1.25),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 11),
                      child: LumeNumerals(
                        status!,
                        style: LumeType.natural(context, context.lumeType.tab)
                            .copyWith(
                              color: lume.text3,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              if (marker != LumeTileMarker.none)
                PositionedDirectional(
                  top: marker == LumeTileMarker.local ? -3 : -5,
                  end: marker == LumeTileMarker.local ? -2 : -4,
                  child: _Marker(marker: marker, count: count),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.marker, this.count});

  final LumeTileMarker marker;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return switch (marker) {
      LumeTileMarker.private => LumeIcon(
        LumeIcons.lock,
        size: 12,
        color: lume.text3.withValues(alpha: 0.6),
      ),
      // `.cat-tool__pin` — a 5 px accent dot at 55 % that says "local
      // service". The prototype tests `f.loc`, a field the catalogue renamed
      // to `countries`, so this marker never renders there at all (C13).
      LumeTileMarker.local => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: lume.accent.withValues(alpha: 0.55),
        ),
      ),
      LumeTileMarker.count => Container(
        constraints: const BoxConstraints(minWidth: 16),
        height: 16,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: lume.amber,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: LumeNumerals(
          (count ?? 0) > 9 ? '9+' : '${count ?? 0}',
          style: LumeType.numeric(
            LumeType.natural(context, context.lumeType.tab),
          ).copyWith(color: lume.onAmber, fontSize: 9),
        ),
      ),
      LumeTileMarker.none => const SizedBox.shrink(),
    };
  }
}

/// `.qaction` — a quick-action pill. A task, not a destination.
class LumeQuickActionPill extends StatelessWidget {
  const LumeQuickActionPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(999),
      minSize: 0,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 14, 9),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.xs,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lume.tintAccent,
                ),
                alignment: Alignment.center,
                child: LumeIcon(icon, size: 13, color: lume.accent),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.label,
                  ).copyWith(fontWeight: FontWeight.w600),
                  -0.02,
                ).copyWith(color: lume.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.livecard` — a "Right now" row.
class LumeLiveRow extends StatelessWidget {
  const LumeLiveRow({
    super.key,
    required this.icon,
    required this.title,
    required this.meta,
    required this.value,
    this.tone = LumeCardTone.accent,
    this.subValue,
    this.trailing,
    this.onTap,
  });

  final String icon;
  final String title;
  final String meta;
  final String value;
  final LumeCardTone tone;

  /// `.livecard__sub` — a 10/600 line under the value.
  final String? subValue;

  /// A delta, where the card carries one.
  final Widget? trailing;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: '$title, $meta, $value',
      borderRadius: LumeRadius.brLg,
      minSize: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) => Row(
              children: <Widget>[
                LumeToneDisc(icon: icon, tone: tone),
                const SizedBox(width: LumeSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style:
                            LumeType.tracked(
                              LumeType.natural(
                                context,
                                context.lumeType.bodyStrong,
                              ),
                              -0.026,
                            ).copyWith(
                              color: lume.text,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      LumeNumerals(
                        meta,
                        style: LumeType.natural(
                          context,
                          context.lumeType.metaSmall,
                        ).copyWith(color: lume.text3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: LumeSpace.x2),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.max(0, c.maxWidth - 120),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      LumeNumerals(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            LumeType.numeric(
                              LumeType.tracked(
                                LumeType.natural(
                                  context,
                                  context.lumeType.section,
                                ),
                                -0.04,
                              ),
                            ).copyWith(
                              color: lume.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (subValue != null) ...<Widget>[
                        const SizedBox(height: 3),
                        LumeNumerals(
                          subValue!,
                          style: LumeType.natural(context, context.lumeType.tab)
                              .copyWith(
                                color: lume.text3,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                      if (trailing != null) ...<Widget>[
                        const SizedBox(height: 3),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.progress-card` — art, two lines and a bar.
///
/// **The bar is drawn.** `.bar` is a `<span>` that the prototype never gives a
/// `display`, so it stays inline and collapses to nothing: measured 0 × 0 with
/// its fill 78.39 × 0. Everything about it is specified — 5 tall, pill,
/// neutral track, a jade gradient fill, animated over 1.1 s by `animateBars` —
/// and none of it renders. Drawn here (C15); the card's height is unchanged,
/// because the 54-point artwork is what sets it.
class LumeProgressCard extends StatelessWidget {
  const LumeProgressCard({
    super.key,
    required this.icon,
    required this.title,
    required this.meta,
    required this.progress,
    this.actionIcon = LumeIcons.arrowR,
    this.onTap,
    this.semanticLabel,
  });

  final String icon;
  final String title;
  final String meta;

  /// 0–1.
  final double progress;

  final String actionIcon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel ?? '$title, $meta',
      borderRadius: LumeRadius.brLg,
      minSize: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        child: ExcludeSemantics(
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: lume.tintAccent,
                  borderRadius: LumeRadius.brIcon,
                ),
                alignment: Alignment.center,
                child: LumeIcon(
                  icon,
                  size: LumeSpace.iconLg,
                  color: lume.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: LumeType.tracked(
                        LumeType.natural(context, context.lumeType.cardTitle),
                        -0.025,
                      ).copyWith(color: lume.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    LumeNumerals(
                      meta,
                      style: LumeType.natural(
                        context,
                        context.lumeType.metaSmall,
                      ).copyWith(color: lume.text3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 9),
                    _Bar(value: progress),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lume.accent,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: lume.accent.withValues(alpha: 0.7),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: LumeIcon(
                  actionIcon,
                  size: LumeSpace.iconSm,
                  color: lume.onAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.bar` — a 5-point track with a jade gradient fill.
class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: ColoredBox(color: lume.tintNeutral)),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: <Color>[lume.accent400, lume.accent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.stat-row` — a figure with its source and its change.
class LumeStatRow extends StatelessWidget {
  const LumeStatRow({
    super.key,
    required this.icon,
    required this.title,
    required this.meta,
    required this.value,
    this.tag,
    this.delta,
    this.deltaUp = true,
    this.onTap,
  });

  final String icon;
  final String title;
  final String meta;
  final String value;

  /// The market pill beside the title.
  final String? tag;

  final String? delta;
  final bool deltaUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: <String>[title, ?tag, meta, value, ?delta].join(', '),
      borderRadius: LumeRadius.brLg,
      minSize: 0,
      child: Container(
        padding: const EdgeInsets.all(LumeSpace.padCard),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        child: ExcludeSemantics(
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lume.tintNeutral,
                  borderRadius: LumeRadius.brSm,
                ),
                alignment: Alignment.center,
                child: LumeIcon(
                  icon,
                  size: LumeSpace.iconMd,
                  color: lume.text2,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            title,
                            style:
                                LumeType.tracked(
                                  LumeType.natural(
                                    context,
                                    context.lumeType.bodyStrong,
                                  ),
                                  -0.028,
                                ).copyWith(
                                  color: lume.text,
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tag != null) ...<Widget>[
                          const SizedBox(width: 7),
                          // Flexible: at 200 % the market's name is wider than
                          // the row, and a pill that cannot shrink pushes the
                          // whole card off the screen.
                          Flexible(child: LumeTag(label: tag!)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    LumeNumerals(
                      meta,
                      style: LumeType.natural(
                        context,
                        context.lumeType.metaSmall,
                      ).copyWith(color: lume.text3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LumeSpace.x2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LumeNumerals(
                    value,
                    style: LumeType.numeric(
                      LumeType.tracked(
                        LumeType.natural(context, context.lumeType.cardTitle),
                        -0.04,
                      ),
                    ).copyWith(color: lume.text, fontWeight: FontWeight.w800),
                  ),
                  if (delta != null) ...<Widget>[
                    const SizedBox(height: 2),
                    LumeNumerals(
                      delta!,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                          ).copyWith(
                            color: deltaUp ? lume.accent : lume.text3,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.tag` — a 21-point pill naming a market or a state.
///
/// Shared rather than screen-local: Today and Explore both carry one, and a
/// second copy is how two pills end up a point apart.
class LumeTag extends StatelessWidget {
  const LumeTag({super.key, required this.label, this.neutral = true});

  final String label;

  /// `.tag--neutral` is the muted variant and the one a market wears; the
  /// accented one names a state.
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: lume.tintNeutral,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: LumeType.tracked(
          LumeType.natural(context, context.lumeType.tab),
          -0.005,
        ).copyWith(color: lume.text3),
      ),
    );
  }
}

/// `.minicard` — a 148-point card in a horizontal strip.
class LumeMiniCard extends StatelessWidget {
  const LumeMiniCard({
    super.key,
    required this.title,
    required this.meta,
    required this.art,
    this.onTap,
  });

  final String title;
  final String meta;

  /// The 148 × 84 drawing at the top.
  final Widget art;

  final VoidCallback? onTap;

  static const double width = 148;
  static const double artHeight = 84;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: '$title, $meta',
      borderRadius: LumeRadius.brMd,
      minSize: 0,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brMd,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.xs,
        ),
        clipBehavior: Clip.antiAlias,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: artHeight, child: art),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LumeNumerals(
                      title,
                      style:
                          LumeType.tracked(
                            LumeType.natural(
                              context,
                              context.lumeType.meta,
                              size: 13,
                            ).copyWith(fontWeight: FontWeight.w700),
                            -0.024,
                          ).copyWith(
                            color: lume.text,
                            height: LumeType.lineHeight(context, 1.25),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    LumeNumerals(
                      meta,
                      style: LumeType.natural(context, context.lumeType.tab)
                          .copyWith(
                            color: lume.text3,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.recent` — a pill in the "Recently used" strip.
class LumeRecentPill extends StatelessWidget {
  const LumeRecentPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(999),
      minSize: 0,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(9, 9, 13, 9),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.xs,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: lume.tintNeutral,
                  borderRadius: LumeRadius.brIcon,
                ),
                alignment: Alignment.center,
                child: LumeIcon(icon, size: 14, color: lume.text2),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.label,
                  ).copyWith(fontWeight: FontWeight.w600),
                  -0.022,
                ).copyWith(color: lume.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.chip` — the category chip in the Tools hub.
///
/// **Not `LumeFilterChip`.** That is `.fchip`, the tool screens' filter: 31
/// tall and accent-filled when on. This is 32 tall and fills with `--text`,
/// near-black on the light ground. Measured side by side rather than assumed
/// to be one control.
class LumeChoiceChip extends StatelessWidget {
  const LumeChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final String? icon;
  final VoidCallback? onTap;

  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color fg = selected ? lume.bg : lume.text2;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: LumePressable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          minSize: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: selected ? lume.text : lume.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? lume.text : lume.border,
                width: LumeSpace.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  LumeIcon(icon!, size: 14, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: LumeType.tracked(
                    LumeType.natural(
                      context,
                      context.lumeType.label,
                    ).copyWith(fontWeight: FontWeight.w600),
                    -0.015,
                  ).copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.cat__head` — a category heading in the Tools hub.
class LumeCategoryHeading extends StatelessWidget {
  const LumeCategoryHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    this.accent = false,
  });

  final String icon;
  final String title;
  final String subtitle;

  /// How many tools are *shown*, which is not always how many exist.
  final String count;

  /// `.cat--islamic .cat__dot` — the faith category's disc is tinted.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accent ? lume.tintAccent : lume.tintNeutral,
            borderRadius: LumeRadius.brIcon,
          ),
          alignment: Alignment.center,
          child: LumeIcon(
            icon,
            size: 14,
            color: accent ? lume.accent : lume.text2,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: LumeType.tracked(
                    LumeType.natural(context, context.lumeType.cardTitle),
                    -0.028,
                  ).copyWith(color: lume.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  subtitle,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: lume.text3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        LumeNumerals(
          count,
          style: LumeType.natural(
            context,
            context.lumeType.metaSmall,
          ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
