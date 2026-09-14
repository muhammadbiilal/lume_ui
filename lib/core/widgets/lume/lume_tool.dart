/// The two pieces every tool screen is laid out with: the section and the
/// source card.
///
/// `engine.js` wraps each block of a tool in `UI.section` and closes every
/// tool with a `.srcbar` inside one, so these are the rhythm and the ending of
/// all 85 screens. Measured on the running reference
/// (`tool_tax_default_pk_390x844_light_en`):
///
/// | | geometry | type |
/// |---|---|---|
/// | `.sect` | 24 above, page gutter each side; `--flush` has none | — |
/// | `.sect--tight` | 16 above | — |
/// | `.sect__head` | 12 below, ends aligned | title 15 / 700 / −0.028em on 19; sub 11 / 500 on 13, 2 below |
/// | `.srcbar` | 12 / 14 padding, `card-2`, hairline, radius 12; 39 tall | — |
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../layout/lume_breakpoint.dart';
import '../../layout/lume_measure.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_badge.dart';
import 'lume_pressable.dart';

/// `.sect` — one block of a tool screen.
class LumeToolSection extends StatelessWidget {
  const LumeToolSection({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.link,
    this.onLinkTap,
    this.flush = false,
    this.tight = false,
    this.spaceAbove,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  /// The space above, when a neighbour's 44-point targets overhang the gap —
  /// a filter rail, a sort bar — and the points they reach past their drawing
  /// come out of it rather than growing the page. `null` is [gap] or
  /// [tightGap].
  final double? spaceAbove;

  /// `.sect__link` — "See all", with its chevron.
  final String? link;
  final VoidCallback? onLinkTap;

  /// `.sect--flush` — no gutters on the body, for a block that brings its own
  /// (a context strip, a scrolling chip row). The head keeps them.
  final bool flush;

  /// `.sect--tight` — 16 above rather than 24.
  final bool tight;

  static const double gap = LumeSpace.gapSection;
  static const double tightGap = 16;

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsDirectional gutters = LumeLayout.pagePadding(
      context.measureClass,
    );
    return Padding(
      padding: EdgeInsets.only(top: spaceAbove ?? (tight ? tightGap : gap)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: gutters,
              child: _Head(
                title: title!,
                subtitle: subtitle,
                link: link,
                onLinkTap: onLinkTap,
              ),
            ),
          Padding(
            padding: flush ? EdgeInsetsDirectional.zero : gutters,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.title, this.subtitle, this.link, this.onLinkTap});

  final String title;
  final String? subtitle;
  final String? link;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Padding(
      padding: const EdgeInsets.only(bottom: LumeSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: LumeType.tracked(
                      LumeType.natural(context, context.lumeType.cardTitle),
                      -0.028,
                    ).copyWith(color: lume.text),
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: LumeType.natural(
                      context,
                      context.lumeType.metaSmall,
                    ).copyWith(color: lume.text3),
                  ),
                ],
              ],
            ),
          ),
          if (link != null) ...<Widget>[
            const SizedBox(width: LumeSpace.x3),
            LumePressable(
              onTap: onLinkTap,
              borderRadius: LumeRadius.brXs,
              minSize: LumeSpace.tap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    link!,
                    style: LumeType.natural(
                      context,
                      context.lumeType.label,
                    ).copyWith(color: lume.accent),
                  ),
                  const SizedBox(width: 3),
                  LumeIcon(LumeIcons.chevR, size: 13, color: lume.accent),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.srcbar` — how current a tool's figures are, and where they came from.
///
/// The freshness mark at the start and the source line at the end, on one
/// line when they fit and wrapped when they do not. §107: provenance is
/// discoverable but never dominant, which is why this is the quietest card on
/// the screen.
class LumeSourceBar extends StatelessWidget {
  const LumeSourceBar({
    super.key,
    this.quality,
    this.qualityLabel,
    this.source,
    this.updated,
    this.note,
  });

  final LumeFreshnessQuality? quality;
  final String? qualityLabel;
  final String? source;
  final String? updated;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: lume.card2,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        borderRadius: LumeRadius.brSm,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: LumeSpace.x3,
        runSpacing: LumeSpace.x3,
        children: <Widget>[
          if (quality != null && qualityLabel != null)
            LumeFreshness(label: qualityLabel!, quality: quality!),
          LumeSourceLine(source: source, updated: updated, note: note),
        ],
      ),
    );
  }
}
