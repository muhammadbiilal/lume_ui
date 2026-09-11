/// The furniture every onboarding step sits in.
///
/// `onboardingTemplate()` gives all nine steps the same frame — a circular back
/// control, a nine-segment progress bar, a skip action, then whatever the step
/// is, then a footer holding the primary action. Only the middle changes. So
/// only the middle is a parameter here, and a step that wants a different back
/// button does not get one.
///
/// Measured from the rendered prototype at 390 (light, LTR):
///
/// | | value |
/// |---|---|
/// | `.onb__top` | 80 tall, `max(46, safe-top + 34)` / 20 / 0 padding, 12 gap |
/// | `.onb__nav` | 34 × 34, full radius, `card` on a 1 px border, `shadow-xs` |
/// | `.onb__seg` | 3 tall, full radius, `border2` track, 5 px gaps |
/// | `.onb__skip` | 13 / 700 / −0.02em, `text3`, 8 / 4 padding |
/// | `.onb__kicker` | 11 / 800 / +0.1em, uppercase, `accent`, 10 below |
/// | `.onb__title` | 28 / 800 / −0.04em, 1.12 line height |
/// | `.onb__text` | 14 / 500 / 1.55, `text2`, 10 above, capped at 30ch |
/// | `.onb__foot` | 22 above (18 when sticky), 10 between, 4 below |
/// | Continue | 46 tall, 12 radius, 14 / 700, 0.38 opacity when disabled |
///
/// **The progress fill is the one value a measurement cannot give.**
/// `.onb__seg::after` is a pseudo-element, and `getComputedStyle` on the
/// segment reports the track. Its rule is unambiguous in `onboarding.css` —
/// `height: 100%`, `background: var(--accent)`, `width: 0` going to `100%` on
/// `.is-done` over `--dur-slow` — so that one is read from the stylesheet, and
/// said so here rather than left to look measured.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_motion.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_text.dart';

/// The measured constants, in one place so a step never writes a literal.
abstract final class LumeOnboardingMetrics {
  /// `.onb__top` padding: `max(46px, env(safe-area-inset-top) + 34px)`.
  static const double topPaddingMin = 46;
  static const double topPaddingOverSafeArea = 34;

  /// `.onb__nav` — the circular back control.
  static const double navSize = 34;
  static const double navIcon = 17;

  /// `.onb__seg`.
  static const double segmentHeight = 3;
  static const double segmentGap = 5;

  /// The flow's nine steps, which is why the bar has nine segments.
  static const int steps = 9;

  /// `.onb__top { gap: 12px }`.
  static const double topGap = 12;

  /// The top row's own height: the back control's 34, which is what makes
  /// `.onb__top` 80 tall against its 46 of padding.
  static const double topRowHeight = navSize;

  /// How far the controls' touch targets reach past the row, above and below.
  ///
  /// Both controls are under §9's 44 px floor in the reference — the circle is
  /// 34 and Skip is 32 — and D6 says that is a defect to correct, not a design
  /// to copy. Growing the row to 44 would have been the easy fix and it moved
  /// the whole flow five pixels down, which the bounds comparison caught
  /// immediately. So the row stays 34 and the targets overhang it by 5 each
  /// way: upward into the bar's own 46 of padding, downward into the step's
  /// first five pixels, which are empty because its content starts ten below.
  ///
  /// Reaching *below* the bar is why the bar and the step are stacked rather
  /// than stacked in a column — a sibling in a `Column` cannot hit-test past
  /// its own bounds.
  static const double targetOverhang = (LumeSpace.tap - navSize) / 2;

  /// `.onb-step { padding-bottom: max(22px, env(safe-area-inset-bottom)) }`.
  static const double stepBottomMin = 22;

  /// `.onb__foot`, and the sticky variant used by the two list steps.
  static const double footPaddingTop = 22;
  static const double footPaddingTopSticky = 18;
  static const double footPaddingBottomSticky = 4;
  static const double footGap = 10;

  /// `.onb__text { max-width: 30ch }`.
  static const int textMeasureCh = 30;

  /// `.onb__kicker { margin-bottom: 10px }` and `.onb__text { margin-top }`.
  static const double kickerGap = 10;
  static const double textGap = 10;

  /// `.onb__lead { padding-top: 10px }` on the two list steps, and the
  /// interests step's own `padding-top: 14px`.
  static const double leadTopList = 10;
  static const double leadTopPicker = 14;

  /// The interests step puts its picker 18 below the lead.
  static const double pickerTop = 18;
}

/// Keys for the parts whose *visible* box differs from their touch target.
///
/// The back control and Skip are 34 and 32 tall and both carry a 44 px target,
/// so "where is the back button" has two answers. A parity test wants the
/// visible one; these name it so the test is not guessing at a widget type.
abstract final class LumeOnboardingKeys {
  /// The visible 34 px circle, not its 44 px target.
  static const Key backCircle = Key('onb.nav.circle');

  /// The visible Skip label, not its 44 px target.
  static const Key skipLabel = Key('onb.skip.label');

  /// `.onb-rows` — the set-up step's two permission rows and the gap between.
  static const Key rows = Key('onb.rows');
}

/// One onboarding step, framed.
class LumeOnboardingScaffold extends StatelessWidget {
  const LumeOnboardingScaffold({
    super.key,
    required this.step,
    required this.child,
    required this.action,
    this.onBack,
    this.onSkip,
    this.backLabel,
    this.skipLabel,
    this.lead,
    this.art,
    this.stickyFoot = false,
    this.secondaryAction = const <Widget>[],
  });

  /// Which of the nine steps this is, zero-based. Drives the progress bar and
  /// whether there is anywhere to go back to.
  final int step;

  /// The step's own content, below the lead and above the footer.
  final Widget child;

  /// The primary action. Usually a [LumeOnboardingContinue].
  final Widget action;

  /// `null` on the first step: `.onb__nav[disabled]` is invisible and
  /// unreachable, not merely greyed.
  final VoidCallback? onBack;

  /// `null` hides Skip the same way.
  final VoidCallback? onSkip;

  final String? backLabel;
  final String? skipLabel;

  /// Kicker, title and supporting text. Scrolls with the content on a short
  /// step and stays put above a list on the two picker steps.
  final Widget? lead;

  /// `.onb__art` — the illustration stage.
  ///
  /// A slot rather than something a step puts in its own column, because the
  /// stage is `flex: 1 1 auto`: it absorbs whatever the copy and the footer
  /// leave. A flex child has to be a *direct* child of the flex that bounds
  /// it, so the scaffold takes it and the step does not.
  final Widget? art;

  /// The two list steps keep the action in reach while their content scrolls.
  final bool stickyFoot;

  /// A second line under the action — "Already have an account?".
  /// `.onb__foot`'s further rows — a link, a note, or both.
  final List<Widget> secondaryAction;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final EdgeInsets safe = MediaQuery.paddingOf(context);

    // The browser resizes its viewport when the keyboard opens, so `.onb`
    // shrinks and the footer stays above it. There is no `Scaffold` here to do
    // that — the flow covers the shell and brings its own ground — so the step
    // region ends where the keyboard begins, and the footer rides up with it.
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final double gutter = context.isCompact
        ? LumeSpace.pageCompact
        : LumeSpace.pageMedium;

    // `.onb__top`: `max(46px, safe + 34px)` of padding over a 34 px row.
    final double topPadding = math.max(
      LumeOnboardingMetrics.topPaddingMin,
      safe.top + LumeOnboardingMetrics.topPaddingOverSafeArea,
    );
    final double topHeight = topPadding + LumeOnboardingMetrics.topRowHeight;

    // `Material` rather than `Scaffold`: the flow covers the shell and brings
    // its own ground, but text still needs a Material ancestor or MaterialApp
    // paints it with the yellow "no Material" underline. Transparent, so the
    // ground below stays visible.
    return Material(
      type: MaterialType.transparency,
      child: ColoredBox(
        color: lume.bg,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: _OnboardingGround()),
            // The step starts where the bar ends. The bar is laid over it,
            // five pixels taller, so its controls can carry a 44 px target
            // without moving anything — see `targetOverhang`.
            Positioned(
              left: 0,
              right: 0,
              top: topHeight,
              bottom: keyboard,
              child: _Step(
                gutter: gutter,
                // A raised keyboard covers the gesture bar, so the safe-area
                // inset it stands for is no longer there to respect.
                bottom: math.max(
                  LumeOnboardingMetrics.stepBottomMin,
                  keyboard > 0 ? 0 : safe.bottom,
                ),
                lead: lead,
                art: art,
                stickyFoot: stickyFoot,
                action: action,
                secondaryAction: secondaryAction,
                child: child,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: topHeight + LumeOnboardingMetrics.targetOverhang,
              child: _Top(
                step: step,
                onBack: onBack,
                onSkip: onSkip,
                backLabel: backLabel,
                skipLabel: skipLabel,
                gutter: gutter,
                topPadding: topPadding,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.onb__bg` — the same three washes as the shell's, at their own stops.
class _OnboardingGround extends StatelessWidget {
  const _OnboardingGround();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: lume.meshOpacity,
          child: Stack(
            children: <Widget>[
              _Wash(lume.accent, const Alignment(-0.76, -0.92), 0.52, 0.26),
              _Wash(lume.violet, const Alignment(0.92, -0.68), 0.46, 0.20),
              _Wash(lume.sky, const Alignment(0.2, 1.0), 0.60, 0.16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wash extends StatelessWidget {
  const _Wash(this.colour, this.centre, this.extent, this.strength);

  final Color colour;
  final Alignment centre;
  final double extent;
  final double strength;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: centre,
          radius: extent * 2,
          colors: <Color>[
            colour.withValues(alpha: strength),
            colour.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.7],
        ),
      ),
    ),
  );
}

class _Top extends StatelessWidget {
  const _Top({
    required this.step,
    required this.onBack,
    required this.onSkip,
    required this.backLabel,
    required this.skipLabel,
    required this.gutter,
    required this.topPadding,
  });

  final int step;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final String? backLabel;
  final String? skipLabel;
  final double gutter;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    // A 44-tall row placed five above where a 34-tall one would go, so every
    // control lands exactly where the prototype puts it — the circle at 46,
    // Skip at 47, the progress bar at 61.5 — while each carries a full-height
    // target. The row is transparent, so the five pixels it borrows above and
    // below are invisible.
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding - LumeOnboardingMetrics.targetOverhang,
        left: gutter,
        right: gutter,
      ),
      child: SizedBox(
        height: LumeSpace.tap,
        child: Row(
          children: <Widget>[
            LumeOnboardingBack(onPressed: onBack, label: backLabel),
            const SizedBox(width: LumeOnboardingMetrics.topGap),
            Expanded(child: LumeOnboardingProgress(step: step)),
            const SizedBox(width: LumeOnboardingMetrics.topGap),
            LumeOnboardingSkip(onPressed: onSkip, label: skipLabel),
          ],
        ),
      ),
    );
  }
}

/// `.onb__nav` — the circular back control.
///
/// Disabled it is *gone*: `opacity: 0`, `pointer-events: none`, scaled to 0.8.
/// It keeps its 34 px of space so the progress bar does not jump between steps,
/// and it leaves the semantics tree so a screen reader is not offered a control
/// that cannot be pressed.
class LumeOnboardingBack extends StatelessWidget {
  const LumeOnboardingBack({super.key, this.onPressed, this.label});

  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool live = onPressed != null;

    final Widget circle = Container(
      key: LumeOnboardingKeys.backCircle,
      width: LumeOnboardingMetrics.navSize,
      height: LumeOnboardingMetrics.navSize,
      decoration: BoxDecoration(
        color: lume.card,
        shape: BoxShape.circle,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.xs,
      ),
      child: Center(
        widthFactor: 1,
        child: LumeIcon(
          LumeIcons.chevL,
          size: LumeOnboardingMetrics.navIcon,
          color: lume.text2,
        ),
      ),
    );

    if (!live) {
      return ExcludeSemantics(
        child: SizedBox.square(
          dimension: LumeOnboardingMetrics.navSize,
          child: AnimatedOpacity(
            opacity: 0,
            duration: LumeMotion.duration(context, LumeMotion.standard),
            child: Transform.scale(scale: 0.8, child: circle),
          ),
        ),
      );
    }

    return LumePressable(
      onTap: onPressed,
      semanticLabel: label,
      borderRadius: LumeRadius.full,
      minSize: LumeSpace.tap,
      child: Center(widthFactor: 1, child: circle),
    );
  }
}

/// `.onb__skip`.
class LumeOnboardingSkip extends StatelessWidget {
  const LumeOnboardingSkip({super.key, this.onPressed, this.label});

  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) return const SizedBox.shrink();
    final LumeColors lume = context.lume;

    // `.onb__skip[disabled] { opacity: 0; pointer-events: none }` — the last
    // step has nothing to skip to, and the control still holds the top row's
    // shape. Removing it instead would let the progress bar grow by 47 points
    // on the one step where the bar is finally full, which reads as the bar
    // jumping at the finish.
    if (onPressed == null) {
      return ExcludeSemantics(
        child: IgnorePointer(child: Opacity(opacity: 0, child: _label(lume))),
      );
    }

    return LumePressable(
      onTap: onPressed,
      semanticLabel: label,
      borderRadius: LumeRadius.brXs,
      minSize: LumeSpace.tap,
      child: Center(widthFactor: 1, child: _label(lume)),
    );
  }

  Widget _label(LumeColors lume) => Builder(
    builder: (BuildContext context) => Padding(
      key: LumeOnboardingKeys.skipLabel,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        label!,
        style:
            LumeType.tracked(
              LumeType.fit(context, context.lumeType.bodyStrong),
              -0.02,
            ).copyWith(
              fontSize: 13,
              // `.onb__skip` measures 32 tall against 8 of padding each way,
              // so its line box is 16. The body role's own height would make
              // it 36 and drop the label two pixels.
              height: 16 / 13,
              color: lume.text3,
            ),
      ),
    ),
  );
}

/// `.onb__progress` — nine segments, filled up to and including the current one.
///
/// `aria-hidden` in the reference, so it carries no semantics here either: the
/// step is announced by the screen's own heading, and a screen reader reading
/// out nine anonymous bars helps nobody.
class LumeOnboardingProgress extends StatelessWidget {
  const LumeOnboardingProgress({
    super.key,
    required this.step,
    this.total = LumeOnboardingMetrics.steps,
  });

  /// Zero-based. Segments up to and including this one are filled.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return ExcludeSemantics(
      child: Row(
        children: <Widget>[
          for (int i = 0; i < total; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: LumeOnboardingMetrics.segmentGap),
            Expanded(
              child: SizedBox(
                height: LumeOnboardingMetrics.segmentHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: lume.border2,
                    borderRadius: LumeRadius.full,
                  ),
                  // `.onb__seg::after` — a fill that grows from 0 to the full
                  // width. Read from the stylesheet, because a pseudo-element
                  // is not something `getComputedStyle` will report.
                  child: ClipRRect(
                    borderRadius: LumeRadius.full,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: i <= step ? 1.0 : 0.0,
                      ),
                      duration: LumeMotion.duration(context, LumeMotion.slow),
                      curve: LumeMotion.easeOut,
                      builder:
                          (BuildContext context, double t, Widget? child) =>
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                // Sized, not merely aligned: an `Align` with a
                                // width factor still lays its child out against
                                // the incoming constraints, so the fill would
                                // paint across the whole track and every
                                // segment would read as done.
                                child: FractionallySizedBox(
                                  alignment: AlignmentDirectional.centerStart,
                                  widthFactor: t,
                                  child: child,
                                ),
                              ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: lume.accent,
                          borderRadius: LumeRadius.full,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.gutter,
    required this.bottom,
    required this.lead,
    required this.art,
    required this.stickyFoot,
    required this.action,
    required this.secondaryAction,
    required this.child,
  });

  final double gutter;

  /// `.onb-step`'s bottom padding, already reduced by whatever the footer's
  /// secondary action overhangs — see `LumeOnboardingFoot.overhangOf`.
  final double bottom;

  final Widget? lead;
  final Widget? art;
  final bool stickyFoot;
  final Widget action;

  /// `.onb__foot`'s further rows — a link, a note, or both.
  final List<Widget> secondaryAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget foot = LumeOnboardingFoot(
      sticky: stickyFoot,
      secondary: secondaryAction,
      child: action,
    );
    final double footBottom =
        bottom - LumeOnboardingFoot.trailingOverhang(secondaryAction);

    // A list step keeps its footer in reach while the list scrolls, so the
    // list scrolls and the footer does not. A short step scrolls as one piece
    // and pushes the footer to the bottom.
    if (stickyFoot) {
      // On a surface too short to pin a lead over a list — a landscape phone —
      // the lead has already been folded into the list by the step itself, and
      // `lead` arrives null. `.onb-step`'s own `overflow-y: auto` does the
      // same thing by simply letting everything scroll.
      return Padding(
        padding: EdgeInsets.only(
          left: gutter,
          right: gutter,
          bottom: footBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (art != null) Flexible(child: art!),
            ?lead,
            Expanded(child: child),
            foot,
          ],
        ),
      );
    }

    // `.onb-step` is a flex column that also scrolls: its children can grow
    // into the space it has *and* the whole thing scrolls when they need more.
    //
    // `SliverFillRemaining(hasScrollBody: false)` is that, exactly: it hands
    // the column *at least* the viewport's height with a bounded constraint,
    // so `Flexible` and `Spacer` work, and lets it be taller, in which case it
    // scrolls. The `IntrinsicHeight` recipe does the same job but measures the
    // column twice, and its intrinsic answer disagreed with the laid-out one
    // by 0.08 of a pixel on a landscape phone — an overflow with no visible
    // cause, which is the worst kind.
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          // Sides only. `SliverFillRemaining` fills the viewport *before* the
          // sliver's own bottom padding is added, so padding there does not
          // hold the footer up — it pushes it off the bottom and makes the
          // page scroll instead. The step's bottom padding belongs under the
          // footer, inside the column.
          padding: EdgeInsets.only(left: gutter, right: gutter),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // `flex: 1 1 auto` — the stage takes what the copy and the
                // footer leave, and it has to be a direct child of this column
                // to do it.
                if (art != null) Flexible(child: art!),
                ?lead,
                child,
                // `.onb__foot { margin-top: auto }` — but only when there is
                // no stage above it. CSS resolves flexible lengths before auto
                // margins, so a growing stage leaves the footer's margin
                // nothing to take; and two flex children here would make the
                // column claim twice the stage's height as its intrinsic,
                // which is enough to push the footer off a phone.
                if (art == null) const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: footBottom),
                  child: foot,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `.onb__lead` — kicker, title, supporting text.
class LumeOnboardingLead extends StatelessWidget {
  const LumeOnboardingLead({
    super.key,
    required this.title,
    this.kicker,
    this.text,
    this.emphasis,
    this.topPadding = LumeOnboardingMetrics.leadTopList,
  });

  final String title;
  final String? kicker;
  final String? text;

  /// A run inside [text] the reference wraps in `<b>` — the completion step's
  /// prayer name. Set in bold where it occurs; ignored when it does not, so a
  /// translation that drops the substitution degrades to plain text rather
  /// than to a hole.
  final String? emphasis;

  /// `.onb__lead { padding-top }`. The interests step uses 14 where the two
  /// list steps use 10.
  final double topPadding;

  /// The supporting sentence, with [emphasis] in bold where the reference
  /// puts a `<b>`.
  Widget _leadText(String body, TextStyle style) {
    final String? run = emphasis;
    final int at = run == null || run.isEmpty ? -1 : body.indexOf(run);
    if (at < 0) return Text(body, style: style);
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: body.substring(0, at)),
          TextSpan(
            text: run,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: body.substring(at + run!.length)),
        ],
      ),
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    // Stretched, not shrink-wrapped: `.onb__kicker`, `.onb__title` and
    // `.onb__text` are block elements and fill the content width. The text's
    // own 30ch cap is applied inside [LumeTextMeasure], so capping and
    // filling do not fight.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(height: topPadding),
        if (kicker != null) ...<Widget>[
          Text(
            kicker!.toUpperCase(),
            // The glyphs are capitals; the announcement is not.
            semanticsLabel: kicker,
            style:
                LumeType.tracked(
                  LumeType.fit(context, context.lumeType.label),
                  0.1,
                ).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  // `.onb__kicker` is 13 tall: 11 px on a normal line box. The
                  // label role's own height would make it 15 and push the
                  // title down two.
                  height: 13 / 11,
                  color: lume.accent,
                ),
          ),
          const SizedBox(height: LumeOnboardingMetrics.kickerGap),
        ],
        Semantics(
          header: true,
          // `.onb__title { text-wrap: balance }`.
          child: LumeBalancedText(
            child: Text(
              title,
              style:
                  LumeType.tracked(
                    LumeType.fit(context, context.lumeType.display),
                    -0.04,
                  ).copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    color: lume.text,
                  ),
            ),
          ),
        ),
        if (text != null) ...<Widget>[
          const SizedBox(height: LumeOnboardingMetrics.textGap),
          LumeTextMeasure(
            characters: LumeOnboardingMetrics.textMeasureCh,
            style: LumeType.fit(
              context,
              context.lumeType.body,
            ).copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.55),
            builder: (BuildContext context, TextStyle style) =>
                _leadText(text!, style.copyWith(color: lume.text2)),
          ),
        ],
      ],
    );
  }
}

/// `max-width: 30ch`, reproduced rather than approximated.
///
/// CSS's `ch` is the advance width of the `0` glyph in the element's own font,
/// so the cap moves with the family, the weight and the text scale. Converting
/// it to a constant would freeze one of those; measuring the glyph keeps all
/// three. `.onb__text` at 14 px Plus Jakarta measures 304.08 px in the
/// prototype, which is what this reproduces.
class LumeTextMeasure extends StatelessWidget {
  const LumeTextMeasure({
    super.key,
    required this.characters,
    required this.style,
    required this.builder,
  });

  final int characters;
  final TextStyle style;
  final Widget Function(BuildContext context, TextStyle style) builder;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: LumeMaxWidth(
        maxWidth: lumeChWidth(context, style) * characters,
        child: builder(context, style),
      ),
    );
  }
}

/// A footer row whose touch target is taller than the box it draws.
///
/// The chrome cannot name the parts that follow the action — they are the
/// steps' own — so a row that overhangs declares how far, and the footer takes
/// it out of the gaps rather than out of the reference's spacing.
abstract interface class LumeFootRow {
  /// Half the difference between the target and the drawn box.
  double get overhang;
}

/// `.onb__foot` — the action region.
class LumeOnboardingFoot extends StatelessWidget {
  const LumeOnboardingFoot({
    super.key,
    required this.child,
    this.sticky = false,
    this.secondary = const <Widget>[],
  });

  final Widget child;
  final bool sticky;

  /// What follows the action, in order. `.onb__foot` is a grid with a 10 px
  /// gap, so a step with a link *and* a note has three rows of it rather than
  /// a column nested inside one.
  final List<Widget> secondary;

  /// How far a footer row reaches past the box the prototype draws for it.
  ///
  /// `.onb__link` is 36 tall — 13 px of text in 10 of padding — and §9 wants
  /// 44. The extra 8 comes out of the gaps on either side of it, so the target
  /// clears the floor while the *text* stays exactly where the prototype puts
  /// it, and nothing overlaps: a 10 px gap becomes 6.
  static double overhangOf(Widget row) {
    final Object widget = row;
    return widget is LumeFootRow ? widget.overhang : 0;
  }

  /// What the last row overhangs, which the step takes off its own padding.
  static double trailingOverhang(List<Widget> secondary) =>
      secondary.isEmpty ? 0 : overhangOf(secondary.last);

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget content = Padding(
      padding: EdgeInsets.only(
        top: sticky
            ? LumeOnboardingMetrics.footPaddingTopSticky
            : LumeOnboardingMetrics.footPaddingTop,
        bottom: sticky ? LumeOnboardingMetrics.footPaddingBottomSticky : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          child,
          for (int i = 0; i < secondary.length; i++) ...<Widget>[
            SizedBox(
              height:
                  LumeOnboardingMetrics.footGap -
                  overhangOf(i == 0 ? child : secondary[i - 1]) -
                  overhangOf(secondary[i]),
            ),
            secondary[i],
          ],
        ],
      ),
    );

    if (!sticky) return content;

    // `background: linear-gradient(to bottom, transparent, var(--bg) 34%)` —
    // the list runs under the footer rather than stopping at it, so the fade
    // is what keeps the last row legible.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[lume.bg.withValues(alpha: 0), lume.bg],
          stops: const <double>[0, 0.34],
        ),
      ),
      child: content,
    );
  }
}

/// The flow's primary action.
///
/// A `btn btn--accent btn--block` with the trailing arrow, which mirrors in a
/// right-to-left layout because it means "forward" rather than "right".
class LumeOnboardingContinue extends StatelessWidget {
  const LumeOnboardingContinue({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.busyLabel,
  });

  final String label;

  /// `null` is the disabled state — `.btn[disabled]`, 0.38 opacity and inert.
  final VoidCallback? onPressed;

  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    return LumeButton.accent(
      label: label,
      onPressed: onPressed,
      trailingIcon: LumeIcons.arrowR,
      block: true,
      busy: busy,
      busyLabel: busyLabel,
    );
  }
}
