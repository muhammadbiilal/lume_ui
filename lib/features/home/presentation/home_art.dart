/// Home's thirteen drawings.
///
/// Six hero slides, the two context strips the faith dimension swaps between,
/// and five Discover cards — lifted byte for byte out of `home.screen.js` by
/// `gen_home_art.mjs` and painted through [LumeArtColours], so the two that use
/// theme variables are right in dark mode instead of being a light drawing on a
/// dark ground.
///
/// Each one keeps its own `preserveAspectRatio`, because the reference's are
/// not the same: a slide and a context strip *slice* (fill and crop), a
/// Discover card stretches to its box. Getting that wrong is how the aside
/// artwork ended up clipped and stretched in F4C.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/lume/lume_art_colours.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../domain/home_model.dart';

/// Where the generator writes.
const String _dir = 'assets/images/home';

/// One hero slide's full-bleed artwork.
///
/// `preserveAspectRatio="xMidYMid slice"` on a 320 × 190 drawing: it fills the
/// slide and crops whichever axis is over, which is [BoxFit.cover].
class LumeHeroArt extends StatelessWidget {
  const LumeHeroArt({super.key, required this.slide});

  final LumeHeroSlideId slide;

  String get asset => '$_dir/hero_${slide.name}.svg';

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    fit: BoxFit.cover,
    alignment: Alignment.center,
    colorMapper: LumeArtColours(context.lume),
  );
}

/// The wash behind the context strip.
///
/// 350 × 72, `slice`. Its two circles are `var(--accent)`, `var(--violet)` and
/// `var(--sky)` at 6–8 %, which is why it is mapped rather than frozen.
class LumeContextArt extends StatelessWidget {
  const LumeContextArt({super.key, required this.islamic});

  /// The faith strip's wash is jade over violet; the other is sky over jade.
  final bool islamic;

  String get asset => '$_dir/ctx_${islamic ? 'islamic' : 'none'}.svg';

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    fit: BoxFit.cover,
    alignment: Alignment.center,
    colorMapper: LumeArtColours(context.lume),
  );
}

/// A Discover card's artwork.
///
/// `preserveAspectRatio="none"` on a 148 × 84 drawing — it stretches to the
/// box, which is [BoxFit.fill]. The box is exactly 148 × 84 at every width, so
/// nothing actually distorts; saying `cover` instead would crop the sun out of
/// the weather card at 200 % text.
class LumeDiscoverArt extends StatelessWidget {
  const LumeDiscoverArt({super.key, required this.card});

  final LumeDiscoverId card;

  String get asset => '$_dir/discover_${card.name}.svg';

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return SvgPicture.asset(
      asset,
      fit: BoxFit.fill,
      colorMapper: LumeArtColours(lume),
    );
  }
}
