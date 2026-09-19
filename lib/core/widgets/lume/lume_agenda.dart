/// The day's rows: the agenda timeline, the task list, the habit strip and
/// the private card.
///
/// Split from `lume_day.dart` — which holds the day's *summary* furniture, the
/// ring and the statistics — because these four are lists and those two are
/// headers, and a five-hundred-line file that holds both is a file nobody
/// finds anything in.
///
/// **This is not `LumeTimeline`.** That one is `.tline`, the trains journey's
/// rail: a node, a line and a card. This is `.timeline`, which puts a
/// 50-point time gutter to the left of the rail and gives the node three
/// states. They were measured side by side rather than assumed to be one
/// component.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_day.dart';
import 'lume_pressable.dart';

/// Where an agenda entry sits relative to now, for the timeline's own use.
///
/// A component in `core/` must not import a feature's model, or the library
/// stops being a library — so the screen maps its domain state onto this.
enum LumeAgendaTone { done, now, upcoming }

/// One row of `.timeline` — a time in a gutter, a node on a rail, a card.
class LumeAgendaRow extends StatelessWidget {
  const LumeAgendaRow({
    super.key,
    required this.time,
    required this.title,
    required this.meta,
    required this.icon,
    required this.tone,
    this.onTap,
    this.isLast = false,
  });

  /// Already formatted, in the reader's clock.
  final String time;

  final String title;
  final String meta;
  final String icon;
  final LumeAgendaTone tone;
  final VoidCallback? onTap;

  /// The rail stops at the last row rather than running on into the next
  /// section: `.tl-item:last-child .tl-line::before { display: none }`.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool done = tone == LumeAgendaTone.done;
    final bool now = tone == LumeAgendaTone.now;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : LumeDayMetrics.timelineRowGap,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // `.tl-time { width: 50px; padding-top: 13px; text-align: right }`
            SizedBox(
              width: LumeDayMetrics.timeGutter,
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: LumeNumerals(
                    time,
                    maxLines: 1,
                    style: LumeType.tracked(
                      LumeType.natural(
                        context,
                        context.lumeType.metaSmall,
                        size: 11,
                      ),
                      -0.02,
                    ).copyWith(color: lume.text3, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: LumeDayMetrics.timelineGap),
            _Rail(tone: tone, isLast: isLast),
            const SizedBox(width: LumeDayMetrics.timelineGap),
            Expanded(
              child: LumePressable(
                onTap: onTap,
                semanticLabel: '$time, $title, $meta',
                borderRadius: LumeRadius.brMd,
                minSize: 0,
                child: Opacity(
                  // `.tl-item.is-done .tl-card { opacity: .6 }`
                  opacity: done ? 0.6 : 1,
                  child: Container(
                    padding: LumeDayMetrics.cardPadding,
                    decoration: BoxDecoration(
                      color: lume.card,
                      borderRadius: LumeRadius.brMd,
                      border: Border.all(
                        // `color-mix(in srgb, var(--accent) 34%, var(--border))`
                        color: now
                            ? Color.lerp(lume.border, lume.accent, 0.34)!
                            : lume.border,
                        width: LumeSpace.border,
                      ),
                      boxShadow: now
                          // `box-shadow: 0 0 0 3px var(--tint-accent)`
                          ? <BoxShadow>[
                              BoxShadow(
                                color: lume.tintAccent,
                                spreadRadius: 3,
                              ),
                            ]
                          : context.lumeShadows.xs,
                    ),
                    child: ExcludeSemantics(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      LumeType.tracked(
                                        LumeType.natural(
                                          context,
                                          context.lumeType.meta,
                                          size: 13,
                                        ),
                                        -0.024,
                                      ).copyWith(
                                        color: lume.text,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  meta,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      LumeType.natural(
                                        context,
                                        context.lumeType.metaSmall,
                                        size: 11,
                                      ).copyWith(
                                        color: lume.text3,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 11),
                          LumeIcon(icon, size: 16, color: lume.text3),
                        ],
                      ),
                    ),
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

/// `.tl-line` — the rail and its node.
class _Rail extends StatelessWidget {
  const _Rail({required this.tone, required this.isLast});

  final LumeAgendaTone tone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool now = tone == LumeAgendaTone.now;
    final bool done = tone == LumeAgendaTone.done;
    final Color node = now
        ? lume.accent
        : done
        ? lume.text3
        : lume.card;
    final Color edge = now
        ? lume.accent
        : done
        ? lume.text3
        : lume.border2;

    return SizedBox(
      width: LumeDayMetrics.railWidth,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: <Widget>[
          // `.tl-line::before { top: 20px; bottom: -14px; width: 1.5px }` —
          // it runs from under one node into the gap before the next, which
          // is why it is negative at the bottom.
          if (!isLast)
            Positioned(
              top: 20,
              bottom: -LumeDayMetrics.timelineRowGap,
              child: SizedBox(
                width: 1.5,
                child: ColoredBox(color: lume.border),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: LumeDayMetrics.nodeTop),
            child: Container(
              width: LumeDayMetrics.nodeSize,
              height: LumeDayMetrics.nodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: node,
                border: Border.all(color: edge, width: 2),
                boxShadow: now
                    ? <BoxShadow>[
                        BoxShadow(color: lume.tintAccent, spreadRadius: 4),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.task` — a checkbox, a label and a time.
class LumeTaskRow extends StatelessWidget {
  const LumeTaskRow({
    super.key,
    required this.label,
    required this.done,
    this.time,
    this.onToggle,
    this.isLast = false,
  });

  final String label;
  final bool done;

  /// Already formatted, or a word where the reference has one ("Evening").
  final String? time;

  final VoidCallback? onToggle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      checked: done,
      child: LumePressable(
        onTap: onToggle,
        semanticLabel: time == null ? label : '$label, $time',
        minSize: 0,
        child: Container(
          padding: LumeDayMetrics.taskPadding,
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: lume.border,
                      width: LumeSpace.border,
                    ),
                  ),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: LumeMotion.standard,
                  curve: LumeMotion.spring,
                  width: LumeDayMetrics.checkboxSize,
                  height: LumeDayMetrics.checkboxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: done ? lume.accent : null,
                    border: Border.all(
                      color: done ? lume.accent : lume.border2,
                      width: 1.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? LumeIcon(
                          LumeIcons.check,
                          size: 12,
                          color: lume.onAccent,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        LumeType.tracked(
                          LumeType.natural(
                            context,
                            context.lumeType.meta,
                            size: 13,
                          ),
                          -0.022,
                        ).copyWith(
                          color: done ? lume.text3 : lume.text,
                          fontWeight: FontWeight.w600,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationThickness: 1.5,
                          decorationColor: lume.text3,
                        ),
                  ),
                ),
                if (time != null) ...<Widget>[
                  const SizedBox(width: 12),
                  LumeNumerals(
                    time!,
                    maxLines: 1,
                    style: LumeType.tracked(
                      LumeType.natural(
                        context,
                        context.lumeType.metaSmall,
                        size: 11,
                      ),
                      -0.03,
                    ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.taskrow` — a tool's checkable row: a 21-point box, the label with a
/// meta line under it, and a badge or a value at the end. The whole row is
/// the checkbox (`role="checkbox"`), 44 tall at least.
class LumeCheckRow extends StatelessWidget {
  const LumeCheckRow({
    super.key,
    required this.label,
    required this.done,
    this.meta,
    this.value,
    this.trailing,
    this.onToggle,
  });

  final String label;
  final bool done;

  /// `.taskrow__meta`.
  final String? meta;

  /// `.taskrow__value` — already formatted.
  final String? value;

  /// A badge in place of a value.
  final Widget? trailing;

  final VoidCallback? onToggle;

  /// `.taskrow__box`.
  static const double box = 21;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final String spoken = <String?>[
      label,
      meta,
      value,
    ].whereType<String>().join(', ');

    return Semantics(
      checked: done,
      child: LumePressable(
        onTap: onToggle,
        semanticLabel: spoken,
        minSize: LumeSpace.tap,
        borderRadius: BorderRadius.zero,
        child: Container(
          // `--pad-row: 12px 16px`.
          // The hairline between rows is [LumeRows]'.
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: ExcludeSemantics(
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: LumeMotion.duration(context, LumeMotion.fast),
                  curve: LumeMotion.ease,
                  width: box,
                  height: box,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: done ? lume.accent : null,
                    border: Border.all(
                      color: done ? lume.accent : lume.border2,
                      width: 1.7,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? LumeIcon(
                          LumeIcons.check,
                          size: 12,
                          color: lume.onAccent,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            LumeType.tracked(
                              LumeType.natural(
                                context,
                                context.lumeType.meta,
                                size: 13,
                              ),
                              -0.022,
                            ).copyWith(
                              color: done ? lume.text3 : lume.text,
                              fontWeight: FontWeight.w600,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationThickness: 1.5,
                              decorationColor: lume.text3,
                            ),
                      ),
                      if (meta != null && meta!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          meta!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              LumeType.natural(
                                context,
                                context.lumeType.metaSmall,
                                size: 11,
                              ).copyWith(
                                color: lume.text3,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 12),
                  trailing!,
                ],
                if (value != null) ...<Widget>[
                  const SizedBox(width: 12),
                  LumeNumerals(
                    value!,
                    maxLines: 1,
                    style: LumeType.natural(
                      context,
                      context.lumeType.metaSmall,
                      size: 12,
                    ).copyWith(color: lume.text2, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.habit` — a name, seven days and a streak.
class LumeHabitRow extends StatelessWidget {
  const LumeHabitRow({
    super.key,
    required this.name,
    required this.days,
    required this.streak,
    required this.todayIndex,
    required this.semanticLabel,
  });

  final String name;

  /// Oldest first.
  final List<bool> days;

  /// Already formatted.
  final String streak;

  /// Which cell is today, so it can carry the ring the reference gives it.
  final int todayIndex;

  /// The whole row in words. A line of coloured squares is readable by an eye
  /// and by nothing else, so the row says what it means.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: LumeDayMetrics.habitNameWidth,
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LumeType.tracked(
                LumeType.natural(context, context.lumeType.meta, size: 12),
                -0.02,
              ).copyWith(color: lume.text, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: <Widget>[
                for (int i = 0; i < days.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: LumeDayMetrics.habitDayGap),
                  Expanded(
                    child: Container(
                      height: LumeDayMetrics.habitDayHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        // `color-mix(in srgb, var(--accent) 78%, transparent)`
                        color: days[i]
                            ? lume.accent.withValues(alpha: 0.78)
                            : lume.tintNeutral,
                        // `inset 0 0 0 1.5px var(--accent)`
                        border: i == todayIndex
                            ? Border.all(color: lume.accent, width: 1.5)
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeIcon(LumeIcons.flame, size: 12, color: lume.amber),
              const SizedBox(width: 3),
              LumeNumerals(
                streak,
                style: LumeType.natural(
                  context,
                  context.lumeType.metaSmall,
                  size: 11,
                ).copyWith(color: lume.text3, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `.habits` — the card the habit rows sit in.
class LumeHabitCard extends StatelessWidget {
  const LumeHabitCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Container(
      padding: LumeDayMetrics.habitsPadding,
      decoration: BoxDecoration(
        color: lume.card,
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: LumeDayMetrics.habitGap),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// `.private-card` — the door to everything sensitive, and nothing through it.
///
/// §61 and §62: sensitive records are *discoverable without being intrusive*.
/// The card names the areas — health, documents, money — and no record, no
/// count, no value and no date. That is the whole design, and it is why this
/// takes no data at all: there is nothing it could leak, because nothing is
/// passed to it.
class LumePrivateCard extends StatelessWidget {
  const LumePrivateCard({
    super.key,
    required this.title,
    required this.text,
    this.onTap,
  });

  final String title;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return LumePressable(
      onTap: onTap,
      semanticLabel: '$title. $text',
      borderRadius: LumeRadius.brLg,
      minSize: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: lume.tintNeutral,
                  borderRadius: LumeRadius.brIcon,
                ),
                alignment: Alignment.center,
                child: LumeIcon(LumeIcons.lock, size: 17, color: lume.text2),
              ),
              const SizedBox(width: 13),
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
                          context.lumeType.meta,
                          size: 14,
                        ),
                        -0.024,
                      ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                            size: 11,
                          ).copyWith(
                            color: lume.text3,
                            fontWeight: FontWeight.w500,
                            height: LumeType.lineHeight(context, 1.45),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              LumeIcon(LumeIcons.chevR, size: 16, color: lume.text3),
            ],
          ),
        ),
      ),
    );
  }
}
