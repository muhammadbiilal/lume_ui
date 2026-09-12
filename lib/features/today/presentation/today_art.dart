/// Today's one drawing.
///
/// Lifted byte for byte out of `today.screen.js` by `gen_destination_art.mjs`,
/// like Explore's six. It sits here rather than beside them because it belongs
/// to this screen, and a destination should not have to import another one's
/// artwork to draw its own card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/lume/lume_art_colours.dart';
import '../../../core/theme/lume/lume_theme.dart';

/// `<span class="sticker sticker--slow">` — the sparkle that hangs off the
/// ring card's top corner.
///
/// 46 × 46, drawn at `opacity: .14` in the artwork itself; the theme's
/// `--sticker-opacity` is applied by whoever places it.
class LumeTodaySticker extends StatelessWidget {
  const LumeTodaySticker({super.key});

  static const String asset = 'assets/images/today/sticker.svg';

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    width: 46,
    height: 46,
    colorMapper: LumeArtColours(context.lume),
  );
}
