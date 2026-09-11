/// The content measure — one reading width for the whole product.
///
/// `responsive.css` caps every `.sect`, `.section` and `.row-gap` at
/// `--content-max + --pad * 2` and centres it from medium up, because a
/// 1200-pixel line of body text is not a tablet layout, it is a phone layout
/// that was pulled (§5, "Tablet content is adapted, not stretched").
///
/// The cap lives here so the whole product keeps one measure instead of each
/// screen inventing its own. A surface that genuinely needs the width says so
/// with [LumeMeasure.wide], which is the reference's `.is-wide`.
library;

import 'package:flutter/widgets.dart';

import '../theme/lume/lume_space.dart';
import 'lume_breakpoint.dart';

/// Page gutters and content caps for the current width class.
abstract final class LumeLayout {
  /// `--pad` for a width class. 20 compact, 24 medium, 32 expanded.
  static double pageGutter(LumeWidthClass c) => switch (c) {
    LumeWidthClass.compact => LumeSpace.pageCompact,
    LumeWidthClass.medium => LumeSpace.pageMedium,
    LumeWidthClass.expanded => LumeSpace.pageExpanded,
  };

  /// Horizontal page padding, as insets that follow the reading direction.
  static EdgeInsetsDirectional pagePadding(LumeWidthClass c) =>
      EdgeInsetsDirectional.symmetric(horizontal: pageGutter(c));

  /// The cap a section is centred within, gutters included — the CSS is
  /// `max-width: calc(var(--content-max) + var(--pad) * 2)`.
  static double contentCap(LumeWidthClass c, {bool wide = false}) {
    final double base = wide ? LumeSpace.contentWide : LumeSpace.contentMax;
    return base + pageGutter(c) * 2;
  }

  /// The width of the master-detail list pane for a shell this wide.
  ///
  /// The CSS is `minmax(320px, 380px)` against a flexible detail pane; the
  /// CRUD guide §8 asks for 360–440. Clamped so a narrow expanded shell does
  /// not starve the detail pane.
  static double listPaneWidth(double shellWidth) {
    final double available = shellWidth - LumeSpace.pageExpanded * 2;
    final double half = available * 0.42;
    return half.clamp(LumeSpace.listPaneMin, LumeSpace.listPane);
  }
}

/// Applies the product's one reading measure: pads to the width class's gutter,
/// caps the content, and centres it.
///
/// Compact does not cap — a phone is already narrower than the cap, and
/// centring there would add margins that are not in the design.
class LumeMeasure extends StatelessWidget {
  const LumeMeasure({
    super.key,
    required this.child,
    this.wide = false,
    this.gutters = true,
  });

  /// A surface that genuinely needs the width — master-detail, multi-column
  /// dashboards. The reference's `.is-wide`.
  const LumeMeasure.wide({super.key, required this.child, this.gutters = true})
    : wide = true;

  final Widget child;
  final bool wide;

  /// Whether to apply the page gutters. False where an ancestor already has.
  final bool gutters;

  @override
  Widget build(BuildContext context) {
    // The measure follows the width-only class. A landscape phone is compact
    // for navigation but its reading width is still governed by its 852 points
    // of width, not by its 393 of height.
    final LumeWidthClass measure = context.measureClass;
    final EdgeInsetsDirectional padding = gutters
        ? LumeLayout.pagePadding(measure)
        : EdgeInsetsDirectional.zero;

    if (measure == LumeWidthClass.compact) {
      return Padding(padding: padding, child: child);
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: LumeLayout.contentCap(measure, wide: wide),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
