/// Chrome: the tool header, the context strip, the circular back control and
/// the segmented progress indicator.
///
/// Measured:
///
/// | | height | padding | type |
/// |---|---|---|---|
/// | `.toolbar` | 62 | 10 20 12 20 | title 20 / 800 / −0.034em |
/// | `.ctxbar` | 22 | 0 20 4 20 | 11 / 600, muted, 8 px gaps |
/// | `.onb__nav` | 34 × 34 | — | 17 px glyph |
/// | `.onb__seg` | 3 | — | 5 px gaps, fills over `--dur-slow` |
///
/// §9: an ordinary screen navigates *back*. An X is only for a surface the
/// user is dismissing, so [LumeToolbar] has no close affordance — a sheet
/// brings its own.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// `.toolbar` — back, title, optional subtitle, trailing actions.
class LumeToolbar extends StatelessWidget {
  const LumeToolbar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.backLabel,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;

  /// `null` hides the back control — a root destination has nowhere to go.
  final VoidCallback? onBack;

  final String? backLabel;
  final List<Widget> actions;

  static const double height = 62;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Container(
      constraints: const BoxConstraints(minHeight: height),
      padding: const EdgeInsetsDirectional.only(
        top: 10,
        bottom: 12,
        start: LumeSpace.pageCompact,
        end: LumeSpace.pageCompact,
      ),
      child: Row(
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            LumeBackButton(onPressed: onBack, label: backLabel),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    // Measured: 20 / 800 / −0.034em.
                    style: LumeType.tracked(
                      LumeType.fit(
                        context,
                        context.lumeType.title,
                      ).copyWith(fontWeight: FontWeight.w800),
                      -0.034,
                    ).copyWith(color: lume.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: LumeType.fit(
                      context,
                      context.lumeType.metaSmall,
                    ).copyWith(color: lume.text3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < actions.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 6),
                  actions[i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// `.onb__nav` — the circular back control.
///
/// Measured: 34 × 34, `card` fill, 1 px `border`, `shadow-xs`, 17 px glyph.
/// Disabled fades to nothing and shrinks to 80 % rather than greying out, so
/// the first onboarding step simply has no back button rather than a dead one.
///
/// The chevron mirrors in RTL, because "back" is a statement about reading
/// order.
class LumeBackButton extends StatelessWidget {
  const LumeBackButton({super.key, this.onPressed, this.label});

  final VoidCallback? onPressed;
  final String? label;

  static const double size = 34;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool enabled = onPressed != null;

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0,
      duration: LumeMotion.duration(context, LumeMotion.standard),
      curve: LumeMotion.ease,
      child: AnimatedScale(
        scale: enabled ? 1 : 0.8,
        duration: LumeMotion.duration(context, LumeMotion.standard),
        curve: LumeMotion.ease,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Semantics(
            button: true,
            enabled: enabled,
            label: label ?? 'Back',
            child: LumePressable(
              onTap: onPressed,
              enabled: enabled,
              borderRadius: LumeRadius.full,
              minSize: LumeSpace.tap,
              excludeSemantics: true,
              child: Center(
                widthFactor: 1,
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: lume.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: lume.border,
                      width: LumeSpace.border,
                    ),
                    boxShadow: context.lumeShadows.xs,
                  ),
                  child: LumeIcon(LumeIcons.chevL, size: 17, color: lume.text2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.ctxbar` — the location, account or source strip under a header.
class LumeContextBar extends StatelessWidget {
  const LumeContextBar({super.key, required this.items, this.gutters = true});

  final List<LumeContextItem> items;
  final bool gutters;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Padding(
      padding: gutters
          ? const EdgeInsetsDirectional.only(
              start: LumeSpace.pageCompact,
              end: LumeSpace.pageCompact,
              bottom: 4,
            )
          : const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: LumeSpace.x2,
        runSpacing: LumeSpace.x1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: lume.text3.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            _ContextItem(item: items[i]),
          ],
        ],
      ),
    );
  }
}

/// One entry in a context strip. Pressable when it opens a picker.
@immutable
class LumeContextItem {
  const LumeContextItem({required this.label, this.icon, this.onTap});

  final String label;
  final String? icon;
  final VoidCallback? onTap;
}

class _ContextItem extends StatelessWidget {
  const _ContextItem({required this.item});

  final LumeContextItem item;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle style = LumeType.fit(
      context,
      context.lumeType.metaSmall,
    ).copyWith(color: lume.text3, fontWeight: FontWeight.w600);

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (item.icon != null) ...<Widget>[
          LumeIcon(item.icon!, size: 13, color: lume.text3),
          const SizedBox(width: 5),
        ],
        Text(item.label, style: style),
        if (item.onTap != null) ...<Widget>[
          const SizedBox(width: 5),
          LumeIcon(LumeIcons.chevD, size: 12, color: lume.text3),
        ],
      ],
    );

    if (item.onTap == null) return content;
    return LumePressable(
      onTap: item.onTap,
      borderRadius: LumeRadius.full,
      minSize: 22,
      semanticLabel: item.label,
      child: content,
    );
  }
}

/// `.onb__progress` — the segmented progress indicator.
///
/// Measured: 3 px tall segments, 5 px apart, pill-shaped, each filling from
/// its start over `--dur-slow` with `--ease-out`.
///
/// **Not dots.** A dot indicator says "there are some steps"; a segmented bar
/// says how far through them you are, which is the question someone six screens
/// into a first run is actually asking.
class LumeSegmentedProgress extends StatelessWidget {
  const LumeSegmentedProgress({
    super.key,
    required this.total,
    required this.completed,
    this.semanticLabel,
  });

  final int total;

  /// How many segments are filled.
  final int completed;

  final String? semanticLabel;

  static const double segmentHeight = 3;
  static const double gap = 5;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      label: semanticLabel ?? 'Step $completed of $total',
      value: '$completed / $total',
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            for (int i = 0; i < total; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: gap),
              Expanded(
                child: ClipRRect(
                  borderRadius: LumeRadius.full,
                  child: Container(
                    height: segmentHeight,
                    color: lume.border2,
                    child: AnimatedFractionallySizedBox(
                      duration: LumeMotion.duration(context, LumeMotion.slow),
                      curve: LumeMotion.easeOut,
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: i < completed ? 1 : 0,
                      child: ColoredBox(color: lume.accent),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
