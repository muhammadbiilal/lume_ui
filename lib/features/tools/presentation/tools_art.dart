/// The hub's one drawing.
///
/// A dashed magnifier over two accent specks, lifted out of `tools.screen.js`
/// by `gen_destination_art.mjs` and painted through [LumeArtColours] so its
/// two theme colours are right in dark mode as well as light.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/lume/lume_art_colours.dart';
import '../../../core/theme/lume/lume_theme.dart';

/// `#toolEmpty`'s illustration — 88 × 66, drawn at its own size.
class LumeToolsEmptyArt extends StatelessWidget {
  const LumeToolsEmptyArt({super.key});

  static const String asset = 'assets/images/tools/empty.svg';

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    fit: BoxFit.contain,
    colorMapper: LumeArtColours(context.lume),
  );
}
