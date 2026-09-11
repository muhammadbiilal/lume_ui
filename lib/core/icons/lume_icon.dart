/// The one way a Lume icon is drawn.
///
/// Takes a name from [LumeIcons], paints it in the colour it is given, sizes it
/// from the Lume scale, and mirrors it in a right-to-left layout only when the
/// glyph genuinely means "forward in reading order".
///
/// The assets carry `stroke="currentColor"`, which SVG resolves from CSS and
/// Flutter cannot — so the colour arrives as a [ColorFilter] instead. That is
/// why every icon in the product comes through here rather than through a bare
/// `SvgPicture.asset`: one place decides colour, size, mirroring and semantics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/lume/lume_space.dart';
import '../theme/lume/lume_theme.dart';
import 'lume_icons.dart';

/// A Lume icon.
class LumeIcon extends StatelessWidget {
  const LumeIcon(
    this.name, {
    super.key,
    this.size = LumeSpace.iconMd,
    this.color,
    this.semanticLabel,
  });

  /// 16 px — inline with metadata.
  const LumeIcon.small(this.name, {super.key, this.color, this.semanticLabel})
    : size = LumeSpace.iconSm;

  /// 24 px — the sprite's own box.
  const LumeIcon.large(this.name, {super.key, this.color, this.semanticLabel})
    : size = LumeSpace.iconLg;

  /// A name from [LumeIcons].
  final String name;

  /// One of 16, 20 or 24 (§5). Other sizes exist in the reference at specific
  /// call sites — a 17 px chevron in a record row, an 18 px glyph in an icon
  /// button — and those pass their own number.
  final double size;

  /// Defaults to [LumeColors.text2], which is what `.ico` inherits in most of
  /// the reference's surfaces.
  final Color? color;

  /// Required when the icon is the only content of a control. An unlabelled
  /// icon-only button is unusable with a screen reader, and §9 asks for it by
  /// name.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Color resolved = color ?? context.lume.text2;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final bool mirror = rtl && LumeIcons.mirrors(name);

    Widget picture = SvgPicture.asset(
      LumeIcons.asset(name),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
      // The icon is decoration unless it was given a label; a labelled one
      // announces itself through the Semantics below instead.
      excludeFromSemantics: true,
    );

    if (mirror) {
      picture = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
        child: picture,
      );
    }

    // An icon is exactly its size, whatever the parent offers it. Without this
    // a LumeIcon handed tight constraints reports the parent's size, and a row
    // that measures its own glyph gets the wrong number.
    picture = SizedBox(width: size, height: size, child: picture);

    if (semanticLabel == null) {
      return ExcludeSemantics(child: picture);
    }
    return Semantics(label: semanticLabel, image: true, child: picture);
  }
}
