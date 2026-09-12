/// `.hero` — the carousel at the top of Home, and the slide it carries.
///
/// Measured at 390 × 844: the track is the full width with 20 of gutter and
/// `4 0 6` of block padding, slides are `calc(100% - 8px)` — 342 — with 12
/// between them, each 194 tall with a 26 radius and 20 of padding, and the
/// dots sit 10 below.
///
/// Two things in here are not obvious from the stylesheet and both were found
/// by measuring.
///
/// **The call to action is compressed.** `.slide__cta` declares `height: 34px`
/// and renders 27.47 on the slide whose title wraps to two lines. The slide is
/// a fixed-height flex column, its content comes to 160.53 in 154 of space, and
/// the only item with a definite height absorbs all 6.53 of the overflow. That
/// is the same flex-shrink behaviour as D19, and it is reproduced here by
/// making the action the one flexible child.
///
/// **Snapping is to the slide, not to the viewport.** `scroll-snap-align:
/// center` on a 342 slide in a 390 track puts slide *i* at
/// `354i − 4`, clamped — so slide 0 sits flush against the gutter with the next
/// peeking, rather than centred with air on both sides. A `PageView` cannot
/// express that; [LumeSnapPhysics] can.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../layout/lume_breakpoint.dart';
import '../../layout/lume_measure.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';
import 'lume_text.dart';

/// The carousel's measured constants.
abstract final class LumeHeroMetrics {
  /// `.hero { margin-top: 14px }`.
  static const double topGap = 14;

  /// `.hero__track { padding: 4px var(--pad) 6px }`.
  static const double trackTop = 4;
  static const double trackBottom = 6;

  /// `.hero__track { gap: 12px }`.
  static const double gap = LumeSpace.x3;

  /// `.slide { flex: 0 0 calc(100% - 8px) }` — 8 less than the content width.
  static const double slideInset = 8;

  /// `.slide { height: 194px }`.
  static const double slideHeight = 194;

  /// `.slide { padding: 20px }`.
  static const double slidePadding = LumeSpace.x5;

  /// `.slide__cta { height: 34px }` — before the column shrinks it.
  static const double ctaHeight = 34;

  /// `.hero__dots { margin-top: 10px; gap: 5px }`.
  static const double dotsGap = 10;
  static const double dotGap = 5;
  static const double dotSize = 5;
  static const double dotActiveWidth = 18;

  /// The slide's height for the current text scale.
  ///
  /// The prototype's 194 is a hard number and its content simply overflows at
  /// large text. §60 asks for dynamic font scaling, so the slide grows instead
  /// — capped, because a hero that fills the screen is no longer a hero.
  static double slideHeightFor(BuildContext context) {
    final double scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    // Urdu and Arabic are set on a 1.6 line so their diacritics are not
    // clipped, which makes four lines of slide copy about 15 % taller. The
    // slide grows to hold them rather than cutting the last one off — §60's
    // "allow for longer translated strings", applied to height.
    final double script =
        LumeType.needsTallLineHeight(Localizations.maybeLocaleOf(context))
        ? 1.18
        : 1.0;
    // Capped at twice: a hero that fills the screen is no longer a hero, and
    // two lines of title plus two of text plus the action fit inside it at
    // every scale the platform offers.
    return slideHeight * scale.clamp(1.0, 2.0) * script;
  }
}

/// Snaps to a fixed stride, with an offset.
///
/// `PageScrollPhysics` snaps to multiples of the *viewport*; this snaps to
/// multiples of [stride] shifted by [origin], which is what a CSS snap
/// container with padding and a gap actually does.
class LumeSnapPhysics extends ScrollPhysics {
  const LumeSnapPhysics({required this.stride, this.origin = 0, super.parent});

  /// Slide width plus the gap.
  final double stride;

  /// Where slide 0 lands. Negative when a centred slide would sit before the
  /// scroll origin, which is then clamped away.
  final double origin;

  @override
  LumeSnapPhysics applyTo(ScrollPhysics? ancestor) => LumeSnapPhysics(
    stride: stride,
    origin: origin,
    parent: buildParent(ancestor),
  );

  double _target(ScrollMetrics position, double velocity) {
    double pixels = position.pixels;
    // A meaningful fling moves one slide, however short it was.
    if (velocity.abs() > 200) pixels += velocity.sign * stride / 2;
    final double index = ((pixels - origin) / stride).roundToDouble();
    return (origin + index * stride).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final double target = _target(position, velocity);
    final Tolerance t = toleranceFor(position);
    if ((target - position.pixels).abs() < t.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: t,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// The carousel.
class LumeHeroCarousel extends StatefulWidget {
  const LumeHeroCarousel({
    super.key,
    required this.slides,
    required this.semanticLabel,
    this.dotLabel,
  });

  /// Already ranked and capped by whoever built them.
  final List<Widget> slides;

  final String semanticLabel;

  /// "Slide {n} of {total}".
  final String Function(int index, int total)? dotLabel;

  @override
  State<LumeHeroCarousel> createState() => _LumeHeroCarouselState();
}

class _LumeHeroCarouselState extends State<LumeHeroCarousel> {
  final ScrollController _controller = ScrollController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double gutter = LumeLayout.pageGutter(context.measureClass);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double content = constraints.maxWidth - gutter * 2;
        final double slideWidth = math.max(
          0,
          content - LumeHeroMetrics.slideInset,
        );
        final double stride = slideWidth + LumeHeroMetrics.gap;
        // A centred snap puts slide i at `stride * i - 4`; slide 0 clamps
        // back to the origin, which is why it sits flush against the gutter.
        const double origin = -(LumeHeroMetrics.slideInset / 2);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height:
                  LumeHeroMetrics.slideHeightFor(context) +
                  LumeHeroMetrics.trackTop +
                  LumeHeroMetrics.trackBottom,
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification n) {
                  if (n is! ScrollUpdateNotification &&
                      n is! ScrollEndNotification) {
                    return false;
                  }
                  final int next = stride == 0
                      ? 0
                      : ((_controller.position.pixels - origin) / stride)
                            .round()
                            .clamp(0, widget.slides.length - 1);
                  if (next != _current) setState(() => _current = next);
                  return false;
                },
                child: Semantics(
                  container: true,
                  label: widget.semanticLabel,
                  child: ListView.separated(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: LumeSnapPhysics(stride: stride, origin: origin),
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      LumeHeroMetrics.trackTop,
                      gutter,
                      LumeHeroMetrics.trackBottom,
                    ),
                    itemCount: widget.slides.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: LumeHeroMetrics.gap),
                    itemBuilder: (BuildContext context, int i) =>
                        SizedBox(width: slideWidth, child: widget.slides[i]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: LumeHeroMetrics.dotsGap),
            LumeHeroDots(
              count: widget.slides.length,
              current: _current,
              label: widget.dotLabel,
              onTap: (int i) => _controller.animateTo(
                (origin + stride * i).clamp(
                  _controller.position.minScrollExtent,
                  _controller.position.maxScrollExtent,
                ),
                duration: LumeMotion.slow,
                curve: LumeMotion.easeOut,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// `.hero__dots` — the pagination.
///
/// Which dot is lit follows the scroll position rather than a counter, *"so a
/// drag, a swipe and a dot tap all agree."*
class LumeHeroDots extends StatelessWidget {
  const LumeHeroDots({
    super.key,
    required this.count,
    required this.current,
    this.onTap,
    this.label,
  });

  final int count;
  final int current;
  final void Function(int index)? onTap;
  final String Function(int index, int total)? label;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    // The row is the reference's 5 tall; the 44-point targets overlap the
    // track above and below it rather than pushing the carousel apart.
    return SizedBox(
      height: LumeHeroMetrics.dotSize,
      child: OverflowBox(
        maxHeight: LumeSpace.tap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < count; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: LumeHeroMetrics.dotGap),
              Semantics(
                button: true,
                selected: i == current,
                label: label?.call(i + 1, count),
                child: LumePressable(
                  onTap: onTap == null ? null : () => onTap!(i),
                  borderRadius: BorderRadius.circular(999),
                  minSize: LumeSpace.tap,
                  // The target is 44; the dot inside it stays 5, which is what
                  // `.hero__dot` is. Letting the pressable size the dot would draw
                  // a 44-point bar.
                  child: Center(
                    child: AnimatedContainer(
                      duration: LumeMotion.standard,
                      curve: LumeMotion.spring,
                      width: i == current
                          ? LumeHeroMetrics.dotActiveWidth
                          : LumeHeroMetrics.dotSize,
                      height: LumeHeroMetrics.dotSize,
                      decoration: BoxDecoration(
                        color: i == current ? lume.accent : lume.border2,
                        borderRadius: BorderRadius.circular(999),
                      ),
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

/// `.slide` — one card in the carousel.
///
/// White ink on its own artwork, which is why nothing in here reads a theme
/// colour: the slide brings its own ground.
class LumeHeroSlide extends StatelessWidget {
  const LumeHeroSlide({
    super.key,
    required this.kicker,
    required this.title,
    required this.text,
    required this.cta,
    required this.art,
    this.badge,
    this.onTap,
  });

  /// `.slide__kicker` — 10/700, 0.09em, upper-cased, 78 % opaque.
  final String kicker;

  /// `.slide__title` — 24/800, 1.12 line height, capped at 78 % of the width
  /// and balanced.
  final String title;

  /// `.slide__text` — 12/1.45, 82 % opaque, capped at 68 %.
  final String text;

  /// `.slide__cta` — the label inside the pill.
  final String cta;

  /// The full-bleed drawing behind everything.
  final Widget art;

  /// `.slide__pill` — the live countdown, on the prayer slide only.
  final Widget? badge;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LumePressable(
    onTap: onTap,
    semanticLabel: '$kicker. $title. $text',
    borderRadius: LumeRadius.brXl,
    minSize: 0,
    child: Container(
      height: LumeHeroMetrics.slideHeightFor(context),
      decoration: BoxDecoration(
        borderRadius: LumeRadius.brXl,
        boxShadow: context.lumeShadows.md,
      ),
      clipBehavior: Clip.antiAlias,
      child: ExcludeSemantics(
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: art),
            if (badge != null)
              PositionedDirectional(top: 18, end: 18, child: badge!),
            Padding(
              padding: const EdgeInsets.all(LumeHeroMetrics.slidePadding),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      kicker.toUpperCase(),
                      style: LumeType.tracked(
                        LumeType.fit(context, context.lumeType.tab),
                        0.09,
                      ).copyWith(color: Colors.white.withValues(alpha: 0.78)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    // `max-width: 78%` and `text-wrap: balance`.
                    SizedBox(
                      width: c.maxWidth * 0.78,
                      child: LumeBalancedText(
                        child: Text(
                          title,
                          style:
                              LumeType.tracked(
                                LumeType.fit(context, context.lumeType.display),
                                -0.036,
                              ).copyWith(
                                color: Colors.white,
                                fontSize: 24,
                                height: LumeType.lineHeight(context, 1.12),
                              ),
                          // Two, which is what the prototype renders at every
                          // measured cell — and what keeps the column inside a
                          // slide whose height is fixed.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: c.maxWidth * 0.68,
                      child: Text(
                        text,
                        style: LumeType.fit(context, context.lumeType.label)
                            .copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w500,
                              height: LumeType.lineHeight(context, 1.45),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // The one item with a definite height, so it is the one
                    // the column shrinks when the title takes two lines.
                    Flexible(
                      child: SizedBox(
                        height: LumeHeroMetrics.ctaHeight,
                        child: _Cta(label: cta),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Cta extends StatelessWidget {
  const _Cta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              style: LumeType.tracked(
                LumeType.fit(context, context.lumeType.label),
                -0.01,
              ).copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          const LumeIcon(LumeIcons.arrowR, size: 14, color: Colors.white),
        ],
      ),
    ),
  );
}

/// `.slide__pill` — the live countdown on the prayer slide.
///
/// The dot pulses, and stops when motion is reduced: an indefinite animation
/// that never stops is an indefinite animation a test can never settle.
class LumeHeroBadge extends StatefulWidget {
  const LumeHeroBadge({super.key, required this.text, this.semanticLabel});

  final String text;
  final String? semanticLabel;

  @override
  State<LumeHeroBadge> createState() => _LumeHeroBadgeState();
}

class _LumeHeroBadgeState extends State<LumeHeroBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedBuilder(
          animation: _pulse,
          builder: (BuildContext context, Widget? child) {
            // `@keyframes pulse` — full at both ends, down to .35 and 70 % of
            // the size in the middle.
            final double t = (math.cos(_pulse.value * 2 * math.pi) + 1) / 2;
            return Opacity(
              opacity: 0.35 + 0.65 * t,
              child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
            );
          },
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 6),
        LumeNumerals(
          widget.text,
          semanticsLabel: widget.semanticLabel,
          style: LumeType.numeric(
            LumeType.tracked(
              LumeType.fit(context, context.lumeType.label),
              -0.02,
            ),
          ).copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}
