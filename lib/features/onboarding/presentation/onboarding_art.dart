/// `.onb__art` — the illustration stage, and the theme-aware SVGs in it.
///
/// The prototype writes each illustration inline and paints it in CSS custom
/// properties, so the same drawing is a different set of colours in light and
/// dark. `flutter_svg` cannot resolve a custom property, so
/// `tool/gen_onboarding_art.mjs` lifts the geometry byte-for-byte and swaps
/// each `var(--token)` for a sentinel colour; [_LumeArtColours] maps the
/// sentinels back to the live theme at paint time.
///
/// The alternative — freezing one theme's hex values into the asset — would
/// have produced a light illustration on a dark ground, which is exactly what
/// §58 says not to ship.
///
/// The stage itself is measured: `flex: 1 1 auto`, `min-height: 200px`,
/// 12 px of block padding, and the drawing capped at 292 and centred. Three
/// steps override the cap inline and they pass [maxWidth] and [minHeight].
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_motion.dart';
import '../../../core/theme/lume/lume_theme.dart';

/// The measured stage.
abstract final class LumeArtMetrics {
  /// `.onb__art { min-height: 200px; padding: 12px 0 }`.
  static const double minHeight = 200;
  static const double padding = 12;

  /// `.onb__art > svg { max-width: 292px }`.
  static const double maxWidth = 292;
}

/// Which illustration. The numbering is the prototype's `data-step`.
enum LumeOnboardingArtwork {
  welcome(0),
  plan(1),
  tools(2),
  setUp(6),
  name(7),
  done(8);

  const LumeOnboardingArtwork(this.step);

  final int step;

  String get asset => 'assets/images/onboarding/step_$step.svg';
}

/// Maps the generator's sentinels onto the theme.
///
/// A `ColorMapper` is given every colour the SVG parser meets; anything that
/// is not a sentinel is returned untouched, so the white strokes and the
/// literal opacities in the art survive.
@immutable
class _LumeArtColours extends ColorMapper {
  const _LumeArtColours(this.lume);

  final LumeColors lume;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color colour,
  ) => switch (colour.toARGB32() & 0x00FFFFFF) {
    0xFF0001 => lume.accent,
    0xFF0002 => lume.accent400,
    0xFF0003 => lume.accent600,
    0xFF0004 => lume.accent700,
    0xFF0005 => lume.violet,
    0xFF0006 => lume.sky,
    0xFF0007 => lume.card,
    0xFF0008 => lume.card2,
    0xFF0009 => lume.border,
    0xFF000A => lume.text,
    0xFF000B => lume.text2,
    0xFF000C => lume.text3,
    0xFF000D => lume.tintAccent,
    0xFF000E => lume.tintNeutral,
    0xFF000F => lume.bg,
    0xFF0010 => lume.amber,
    0xFF0011 => lume.rose,
    _ => colour,
  };
}

/// One step's illustration, in its stage.
class LumeOnboardingArt extends StatelessWidget {
  const LumeOnboardingArt({
    super.key,
    required this.artwork,
    this.maxWidth = LumeArtMetrics.maxWidth,
    this.minHeight = LumeArtMetrics.minHeight,
    this.padding = const EdgeInsets.symmetric(vertical: LumeArtMetrics.padding),
  });

  /// Step 6's stage is `flex: 0 0 auto; min-height: 0; padding: 2px 0 10px`
  /// and caps the drawing at 242; step 7 at 250 with `6px 0 4px`. Those are
  /// the inline overrides, passed rather than branched on inside.
  const LumeOnboardingArt.compact({
    super.key,
    required this.artwork,
    required this.maxWidth,
    required this.padding,
  }) : minHeight = 0;

  final LumeOnboardingArtwork artwork;
  final double maxWidth;

  /// `.onb__art { min-height: 200px }`. The stage's *flex* is the scaffold's
  /// business — it hands the art to the column that bounds it.
  final double minHeight;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    // `min-height: 200px`. `ConstrainedBox` enforces its own constraints
    // against the ones it is given, so a stage inside a `Flexible` that has
    // less than 200 to offer simply takes what there is — the floor is a floor
    // only while there is room for it, which is how a flex item with a
    // min-height behaves in the prototype too.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: padding,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ExcludeSemantics(
              child: SvgPicture.asset(
                artwork.asset,
                colorMapper: _LumeArtColours(lume),
                // The drawing's own aspect ratio, from its viewBox. Letting it
                // stretch would be the one thing that makes bespoke art look
                // like clip art.
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.onb__seal` — the completion mark, drawn rather than shown.
///
/// The prototype draws the ring and the tick with `stroke-dasharray`
/// animations and pops the sparks in after them. The same shapes are in the
/// asset; this fades and scales the whole seal, which is the honest Flutter
/// reading of "it arrives" without re-deriving a path-drawing animation the
/// design does not depend on.
///
/// Under reduced motion it is simply there, which is what an indefinite
/// celebration should do when someone has asked for stillness.
class LumeOnboardingSeal extends StatefulWidget {
  const LumeOnboardingSeal({super.key});

  @override
  State<LumeOnboardingSeal> createState() => _LumeOnboardingSealState();
}

class _LumeOnboardingSealState extends State<LumeOnboardingSeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LumeMotion.slow,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LumeMotion.stillness(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation curve = CurvedAnimation(
      parent: _controller,
      curve: LumeMotion.easeOut,
    );
    return FadeTransition(
      opacity: curve,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.86, end: 1).animate(curve),
        child: const LumeOnboardingArt(artwork: LumeOnboardingArtwork.done),
      ),
    );
  }
}
