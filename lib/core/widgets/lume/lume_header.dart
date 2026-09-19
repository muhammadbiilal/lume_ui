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
import '../../layout/lume_breakpoint.dart';
import '../../layout/lume_measure.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_button.dart';
import 'lume_pressable.dart';
import 'lume_target.dart';

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

  /// `10 + 38 + 12` of padding and back control, and one more point for the
  /// hairline below it.
  static const double height = 61;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Container(
      constraints: const BoxConstraints(minHeight: height),
      // `border-bottom: 1px solid transparent`, which `.toolbar.is-stuck`
      // turns to `--border` when the bar sticks. Transparent is not the same
      // as absent: the point it occupies is what makes a `.toolbar` 61 rather
      // than 60, and without it the 38-point back control centres itself in a
      // 40-point content box and sits a point low on every route (C46).
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.transparent,
            width: LumeSpace.border,
          ),
        ),
      ),
      // `padding: 10px var(--pad) 12px` — the gutter is the width class's:
      // measured on Tax, the title starts 24 in at 700 and 32 in at 1100.
      padding: EdgeInsetsDirectional.only(
        top: 10,
        bottom: 12,
        start: LumeLayout.pageGutter(context.measureClass),
        end: LumeLayout.pageGutter(context.measureClass),
      ),
      child: Row(
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            // The circle is 38 and the target is 44 (D6). The extra three
            // points on each side overhang into the bar's own 10/12 padding
            // rather than growing it: a `.toolbar` is 61 in the prototype and
            // an accessible target must not make it 66. Same rule as D35 —
            // the touchable area and the drawn one are separate.
            SizedBox(
              width: LumeBackButton.toolbarSize,
              height: LumeBackButton.toolbarSize,
              child: OverflowBox(
                maxWidth: LumeSpace.tap,
                maxHeight: LumeSpace.tap,
                child: LumeBackButton(
                  onPressed: onBack,
                  label: backLabel,
                  size: LumeBackButton.toolbarSize,
                ),
              ),
            ),
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
                    // Measured: 20 / 800 / −0.034em, on the font's natural
                    // line — which is 25, not the `--t-title` token's. The
                    // token's is taller, and it pushed the 38-point back
                    // control off the bar's own padding and the bar itself
                    // two points past its measured 61.
                    style: LumeType.tracked(
                      LumeType.natural(
                        context,
                        context.lumeType.title,
                        size: 20,
                      ).copyWith(fontWeight: FontWeight.w800),
                      -0.034,
                    ).copyWith(color: lume.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  // `margin-top: 1px`.
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    // C47 again, one line down: `.toolbar__sub` is 11 / 500
                    // with no `line-height`, so the line is the font's own
                    // 13 and not `--t-meta-small`'s 16. The token's three
                    // extra points made the bar 64 where it is measured at
                    // 62 on every route that carries a subtitle.
                    style: LumeType.natural(
                      context,
                      context.lumeType.metaSmall,
                      size: 11,
                    ).copyWith(color: lume.text3, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
                  // An icon action is drawn at 38 and touched at 44, the same
                  // as the back control: its target overhangs the bar's own
                  // padding rather than growing the bar. Measured on Tax, a
                  // `.toolbar` with two icon actions is still 62 (D6).
                  if (actions[i] is LumeIconButton)
                    SizedBox(
                      width: LumeIconButton.size,
                      height: LumeIconButton.size,
                      child: OverflowBox(
                        maxWidth: LumeSpace.tap,
                        maxHeight: LumeSpace.tap,
                        child: actions[i],
                      ),
                    )
                  else
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
  const LumeBackButton({
    super.key,
    this.onPressed,
    this.label,
    this.size = onboardingSize,
  });

  final VoidCallback? onPressed;
  final String? label;

  /// The drawn circle. Two of them in the product, and they are different
  /// controls that happen to look alike: `.onb__nav` is 34 and the toolbar's
  /// `.iconbtn` is 38.
  final double size;

  /// `.onb__nav` — onboarding's, and the default.
  static const double onboardingSize = 34;

  /// `.toolbar .iconbtn`.
  static const double toolbarSize = 38;

  /// The drawn circle, so a measurement can tell it from the target around
  /// it. They are deliberately different sizes — see D6.
  static const Key circleKey = Key('back.circle');

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
                  key: circleKey,
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
              // `.ctxbar__sep` — 3 × 3 in `currentColor` at .35.
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: lume.text3.withValues(alpha: 0.35),
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
  const LumeContextItem({
    required this.label,
    this.icon,
    this.onTap,
    this.semanticsLabel,
  });

  final String label;
  final String? icon;
  final VoidCallback? onTap;

  /// What a screen reader hears instead of [label], where the drawn words
  /// leave something out — a time zone's label and the identifier it
  /// stands for.
  final String? semanticsLabel;
}

class _ContextItem extends StatelessWidget {
  const _ContextItem({required this.item});

  /// The drawn height of a pressable item, and how far its target reaches.
  static const double height = 18;
  static const double slopY = 13;
  static const double slopX = 4;

  final LumeContextItem item;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool pressable = item.onTap != null;
    // `button.ctxbar__item { color: var(--text-2) }` — the one item that
    // opens something reads a step darker than the facts beside it, and its
    // icon and caret take the same ink.
    final Color ink = pressable ? lume.text2 : lume.text3;
    // 11 / 600 on the font's own 13.
    final TextStyle style = LumeType.natural(
      context,
      context.lumeType.metaSmall,
    ).copyWith(color: ink, fontWeight: FontWeight.w600);

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (item.icon != null) ...<Widget>[
          LumeIcon(item.icon!, size: 13, color: ink),
          const SizedBox(width: 5),
        ],
        Text(item.label, style: style),
        if (pressable) ...<Widget>[
          const SizedBox(width: 5),
          // `.ctxbar__caret` — 11 at .6.
          Opacity(
            opacity: 0.6,
            child: LumeIcon(LumeIcons.chevD, size: 11, color: ink),
          ),
        ],
      ],
    );

    if (!pressable) {
      return item.semanticsLabel == null
          ? content
          : Semantics(
              label: item.semanticsLabel,
              excludeSemantics: true,
              child: content,
            );
    }
    // `min-height: 32px; padding: 7px 4px; margin: -7px -4px` — the button
    // takes 18 of the strip's height, which is what makes the strip 22, and
    // reaches 7 past it each way. The touchable area reaches 13 above and
    // below — §9's 44, which the section gap has room for — and 4 to each
    // side, half the 8-point gap, so neighbours never share a point. Drawn
    // exactly as before; see [LumeTargetSlop].
    return LumeTargetSlop(
      slop: const EdgeInsetsDirectional.symmetric(
        horizontal: slopX,
        vertical: slopY,
      ),
      child: LumePressable(
        onTap: item.onTap,
        borderRadius: LumeRadius.full,
        minSize: 0,
        semanticLabel: item.semanticsLabel ?? item.label,
        child: SizedBox(
          height: height,
          child: Center(widthFactor: 1, child: content),
        ),
      ),
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
