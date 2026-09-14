/// Value surfaces: the summary card, the metric, the metric grid, the stat,
/// and the record hero.
///
/// §85: a card must carry information, never just a label. All four of these
/// lead with a number and explain it underneath, rather than naming a thing and
/// making the user open it.
///
/// Measured:
///
/// | | padding | radius | lead type |
/// |---|---|---|---|
/// | `.summary` | 20 | 20 | 34 / 800 / −0.05em |
/// | `.metric` | 13 12 | 12 | 15 / 800 / −0.036em |
/// | `.chero` | 22 | 20 | 32 / 800 / −0.035em on a gradient |
///
/// The summary's 34 px value is a size the type scale does not have, and
/// deliberately: it is a display number, not a heading, and it is set per
/// surface. Same for the hero's 32.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../layout/lume_breakpoint.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_gradients.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_badge.dart';
import 'lume_pressable.dart';

/// One figure in a summary card's footer strip.
@immutable
class LumeStat {
  const LumeStat({required this.value, required this.label});

  final String value;
  final String label;
}

/// `.summary` — the card a tool leads with.
class LumeSummaryCard extends StatelessWidget {
  const LumeSummaryCard({
    super.key,
    required this.value,
    this.kicker,
    this.unit,
    this.caption,
    this.stats = const <LumeStat>[],
    this.aside,
    this.footer,
    this.gradient,
  });

  /// The lead figure, already formatted.
  final String value;

  /// The uppercase label above it.
  final String? kicker;

  /// A unit set beside the value at a smaller size — "PKR", "km".
  final String? unit;

  final String? caption;

  /// The strip of secondary figures under the lead.
  final List<LumeStat> stats;

  /// Something at the trailing edge of the lead row — a delta, a badge.
  final Widget? aside;

  final Widget? footer;

  /// A gradient colourway. `null` is the plain card.
  final LumeGradient? gradient;

  /// Measured: 34 px / 800 / −0.05em.
  static const double valueSize = 34;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool onGradient = gradient != null;
    final Color ink = onGradient ? gradient!.on : lume.text;

    // Measured on `.summary` and its parts, on a tool screen:
    //
    //   kicker   11 / 700 / .05em, 13 tall — muted at .72 on the plain card,
    //            `--on-grad-dim` at full strength on a gradient
    //   value    6 below; 34 / 800 / −0.05em on a 1.05 line (35.7)
    //   caption  7 below; 12 / 500 on 1.45 (17.4) — `text-2`, or on-grad-dim
    //   stats    16 below, then a hairline in 14 % of the ink, then 14; three
    //            equal columns 10 apart; 15 / 800 / −0.032em on 19 over
    //            10 / 600 on 12, 2 between
    //   foot     14 below
    //
    // A gradient card keeps its one-point border, only transparent, so its
    // content sits where the plain card's does; both keep `shadow-sm`.
    final Color kickerInk = onGradient ? gradient!.onDim : lume.text3;
    final Color captionInk = onGradient ? gradient!.onDim : lume.text2;
    final Color statLabelInk = onGradient ? gradient!.onDim : lume.text3;

    return Container(
      padding: const EdgeInsets.all(LumeSpace.x5),
      decoration: BoxDecoration(
        color: onGradient ? null : lume.card,
        gradient: gradient?.linear,
        borderRadius: LumeRadius.brLg,
        border: Border.all(
          color: onGradient ? Colors.transparent : lume.border,
          width: LumeSpace.border,
        ),
        boxShadow: context.lumeShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (kicker != null)
                      Opacity(
                        opacity: onGradient ? 1 : 0.72,
                        child: Text(
                          LumeType.overline(context, kicker!),
                          semanticsLabel: kicker,
                          style:
                              LumeType.tracked(
                                LumeType.natural(
                                  context,
                                  context.lumeType.metaSmall,
                                ),
                                0.05,
                              ).copyWith(
                                color: kickerInk,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: LumeSpace.x2,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: <Widget>[
                        LumeNumerals(
                          value,
                          style: LumeType.numeric(
                            LumeType.tracked(
                              LumeType.fit(
                                context,
                                context.lumeType.display,
                              ).copyWith(fontSize: valueSize, height: 1.05),
                              -0.05,
                            ),
                          ).copyWith(color: ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (unit != null)
                          Opacity(
                            opacity: 0.74,
                            child: Text(
                              unit!,
                              style: LumeType.tracked(
                                LumeType.natural(
                                  context,
                                  context.lumeType.cardTitle,
                                ),
                                -0.02,
                              ).copyWith(color: ink),
                            ),
                          ),
                      ],
                    ),
                    if (caption != null) ...<Widget>[
                      const SizedBox(height: 7),
                      Text(
                        caption!,
                        style: LumeType.fit(context, context.lumeType.meta)
                            .copyWith(
                              color: captionInk,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (aside != null) ...<Widget>[const SizedBox(width: 14), aside!],
            ],
          ),
          if (stats.isNotEmpty) ...<Widget>[
            const SizedBox(height: LumeSpace.x4),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: ink.withValues(alpha: 0.14),
                    width: LumeSpace.border,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < 3; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: i < stats.length
                          ? _Stat(
                              stat: stats[i],
                              ink: ink,
                              labelInk: statLabelInk,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (footer != null) ...<Widget>[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }
}

/// `.summary__stat` — a figure and what it counts.
class _Stat extends StatelessWidget {
  const _Stat({required this.stat, required this.ink, required this.labelInk});

  final LumeStat stat;
  final Color ink;
  final Color labelInk;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      LumeNumerals(
        stat.value,
        style: LumeType.numeric(
          LumeType.tracked(
            LumeType.natural(context, context.lumeType.cardTitle),
            -0.032,
          ),
        ).copyWith(color: ink, fontWeight: FontWeight.w800),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text(
        stat.label,
        style: LumeType.natural(
          context,
          context.lumeType.metaSmall,
          size: 10,
        ).copyWith(color: labelInk, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

/// `.metric` — one figure in a grid of them.
///
/// Measured: 84 tall, 13/12 padding, 12 px radius, own border.
class LumeMetric extends StatelessWidget {
  const LumeMetric({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.delta,
    this.onTap,
  });

  final String value;
  final String label;
  final String? icon;
  final LumeDelta? delta;
  final VoidCallback? onTap;

  static const double height = 84;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget card = Container(
      constraints: const BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      decoration: BoxDecoration(
        color: lume.card,
        borderRadius: LumeRadius.brIcon,
        border: Border.all(color: lume.border, width: LumeSpace.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            LumeIcon(icon!, size: LumeSpace.iconMd, color: lume.text3),
            const SizedBox(height: LumeSpace.x2),
          ],
          LumeNumerals(
            value,
            style: LumeType.numeric(
              LumeType.tracked(
                LumeType.fit(
                  context,
                  context.lumeType.cardTitle,
                ).copyWith(fontWeight: FontWeight.w800),
                -0.036,
              ),
            ).copyWith(color: lume.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: LumeType.fit(context, context.lumeType.metaSmall).copyWith(
              color: lume.text3,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (delta != null) ...<Widget>[
            const SizedBox(height: LumeSpace.x1),
            delta!,
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return LumePressable(
      onTap: onTap,
      semanticLabel: '$label, $value',
      borderRadius: LumeRadius.brIcon,
      minSize: 0,
      child: card,
    );
  }
}

/// `.metrics` — the metric grid.
///
/// Two or three columns by default; **four** above the 1180 px refinement,
/// which is a measured rule rather than a guess (`.app--wide .metrics
/// { --cols: 4 }`).
class LumeMetrics extends StatelessWidget {
  const LumeMetrics({super.key, required this.children, this.columns});

  final List<Widget> children;

  /// Overrides the responsive default.
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final int cols =
        columns ??
        (context.isWideSurface
            ? 4
            : (children.length < 3 ? children.length : 3));

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = LumeSpace.x2;
        final double width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(width: width > 0 ? width : null, child: child),
          ],
        );
      },
    );
  }
}

/// `.chero` — the gradient hero a record detail leads with.
///
/// Measured: 22 px padding, 20 px radius, gradient ground, white ink,
/// 32 / 800 / −0.035em tabular value.
class LumeRecordHero extends StatelessWidget {
  const LumeRecordHero({
    super.key,
    required this.value,
    this.kicker,
    this.title,
    this.caption,
    this.gradient,
  });

  final String value;
  final String? kicker;
  final String? title;
  final String? caption;

  /// Defaults to the brand colourway.
  final LumeGradient? gradient;

  static const double valueSize = 32;

  @override
  Widget build(BuildContext context) {
    final LumeGradient g = gradient ?? context.lumeGradients.accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: g.linear,
        borderRadius: LumeRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (kicker != null) ...<Widget>[
            Opacity(
              opacity: 0.82,
              child: Text(
                LumeType.overline(context, kicker!),
                style: LumeType.tracked(
                  LumeType.fit(context, context.lumeType.label),
                  0.09,
                ).copyWith(color: g.on),
              ),
            ),
            const SizedBox(height: LumeSpace.x2),
          ],
          LumeNumerals(
            value,
            style: LumeType.numeric(
              LumeType.tracked(
                LumeType.fit(
                  context,
                  context.lumeType.display,
                ).copyWith(fontSize: valueSize),
                -0.035,
              ),
            ).copyWith(color: g.on),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (title != null) ...<Widget>[
            const SizedBox(height: LumeSpace.x1),
            Text(
              title!,
              style: LumeType.fit(
                context,
                context.lumeType.section,
              ).copyWith(color: g.on),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (caption != null) ...<Widget>[
            const SizedBox(height: 10),
            Opacity(
              opacity: 0.78,
              child: Text(
                caption!,
                style: LumeType.fit(
                  context,
                  context.lumeType.meta,
                ).copyWith(color: g.on),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.cfacts` — label left, value right, hairline between.
///
/// A long value — a note — wraps under its label instead of squeezing into a
/// column, which is what [LumeFact.block] is for.
@immutable
class LumeFact {
  const LumeFact({
    required this.label,
    required this.value,
    this.block = false,
  });

  final String label;
  final String value;

  /// Wraps the value under the label rather than beside it.
  final bool block;
}

/// A card of [LumeFact] rows.
class LumeFactCard extends StatelessWidget {
  const LumeFactCard({super.key, required this.facts});

  final List<LumeFact> facts;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle labelStyle = LumeType.fit(
      context,
      context.lumeType.body,
    ).copyWith(color: lume.text3);
    final TextStyle valueStyle = LumeType.fit(
      context,
      context.lumeType.body,
    ).copyWith(color: lume.text, fontWeight: FontWeight.w700);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < facts.length; i++) ...<Widget>[
          if (i > 0)
            Divider(
              height: LumeSpace.border,
              thickness: LumeSpace.border,
              color: lume.border,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: facts[i].block
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(facts[i].label, style: labelStyle),
                      const SizedBox(height: LumeSpace.x1),
                      Text(facts[i].value, style: valueStyle),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(facts[i].label, style: labelStyle),
                      const SizedBox(width: LumeSpace.x5),
                      Expanded(
                        child: Text(
                          facts[i].value,
                          style: valueStyle,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}
