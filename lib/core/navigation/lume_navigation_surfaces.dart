/// The three presentations of the destination set: bottom bar, rail, sidebar.
///
/// One list in, three layouts out. None of them holds its own copy of the
/// destinations, and none decides which is selected — they are told, and they
/// report a tap. That is what keeps them from drifting apart.
///
/// Measured from the rendered prototype:
///
/// | | value |
/// |---|---|
/// | `.tabbar` | 62 tall, 12 from each edge, 0/4 padding, r20, `card` at 84 %, 1 px border, `shadow-md` |
/// | `.tab` | 60 tall, 4 px gap, 20 px glyph, label 10/700/−0.005em, `text-3` |
/// | `.tab.is-active` | accent ink; the glyph lifts 1 px and grows 6 % |
/// | `.tabbar__pill` | 50 tall, r16, `tintAccent`, 6 from the top |
/// | `.navside` (rail) | 84 wide, 20/12 padding, 4 px gap, `bgSunk` |
/// | `.navtab` (rail) | 44 min, 10/4 padding, 5 px gap, column, label 10/14/700 |
/// | `.navside` (sidebar) | 244 wide, same padding |
/// | `.navtab` (sidebar) | 44 min, 10/12 padding, 12 px gap, row, label 15/20/700 |
/// | `.navside__brand` | 28/32/800/−0.035em, 4/12/20 padding — **sidebar only** |
///
/// The rail and the sidebar are the *same element at two widths* in the
/// reference: one piece of markup, and the stylesheet decides whether the label
/// sits beside the icon or under it. [LumeNavigationRail] keeps that — it takes
/// an `expanded` flag rather than being two widgets.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/lume_icon.dart';
import '../theme/lume/lume_colors.dart';
import '../theme/lume/lume_motion.dart';
import '../theme/lume/lume_space.dart';
import '../theme/lume/lume_theme.dart';
import '../theme/lume/lume_type.dart';
import '../widgets/lume/lume_pressable.dart';
import 'lume_destination.dart';

/// `.tabbar` — the compact presentation.
class LumeBottomBar extends StatelessWidget {
  const LumeBottomBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.semanticLabel,
  });

  final List<LumeDestination> destinations;

  /// The index within [destinations]. `-1` when the current destination is not
  /// a tab — Explore reached from a link, a tool, the notification centre. The
  /// pill hides rather than pointing at the wrong place.
  final int selectedIndex;

  final ValueChanged<int> onSelected;
  final String? semanticLabel;

  /// Measured.
  static const double height = 62;
  static const double inset = 12;
  static const double pillHeight = 50;
  static const double pillTop = 6;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Padding(
      padding: EdgeInsets.only(
        left: inset,
        right: inset,
        bottom: math.max(inset, MediaQuery.paddingOf(context).bottom),
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            // `color-mix(in srgb, card 84%, transparent)`. The reference also
            // blurs what is behind it; a backdrop filter is expensive on a
            // surface this large and Flutter has no cheap equivalent, so the
            // translucency is kept and the blur is not — recorded in
            // KNOWN_DIFFERENCES.
            color: lume.card.withValues(alpha: 0.84),
            borderRadius: LumeRadius.brLg,
            border: Border.all(color: lume.border, width: LumeSpace.border),
            boxShadow: context.lumeShadows.md,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double slot =
                  constraints.maxWidth / math.max(destinations.length, 1);
              return Stack(
                children: <Widget>[
                  // The pill slides to the selected slot. It is behind the
                  // tabs, which is why it is first in the stack.
                  if (selectedIndex >= 0)
                    AnimatedPositionedDirectional(
                      duration: LumeMotion.duration(context, LumeMotion.slow),
                      curve: LumeMotion.spring,
                      start: slot * selectedIndex,
                      top: pillTop,
                      width: slot,
                      height: pillHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: lume.tintAccent,
                          borderRadius: LumeRadius.brMd,
                        ),
                      ),
                    ),
                  Row(
                    children: <Widget>[
                      for (int i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _BottomTab(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final LumeDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color ink = selected ? lume.accent : lume.text3;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.semanticLabel,
      child: LumePressable(
        onTap: onTap,
        borderRadius: LumeRadius.brMd,
        minSize: LumeBottomBar.height - 2,
        excludeSemantics: true,
        child: SizedBox(
          height: LumeBottomBar.height - 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // The selected glyph lifts a pixel and grows 6 %.
              AnimatedScale(
                scale: selected ? 1.06 : 1.0,
                duration: LumeMotion.duration(context, LumeMotion.standard),
                curve: LumeMotion.spring,
                child: AnimatedSlide(
                  offset: selected ? const Offset(0, -0.05) : Offset.zero,
                  duration: LumeMotion.duration(context, LumeMotion.standard),
                  curve: LumeMotion.spring,
                  child: _Glyph(destination: destination, colour: ink),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LumeType.tracked(
                    LumeType.fit(context, context.lumeType.tab),
                    -0.005,
                  ).copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.navside` — the rail at medium width and the sidebar at expanded.
///
/// One widget, because it is one element in the reference. [expanded] switches
/// the label from under the glyph to beside it and reveals the wordmark.
class LumeNavigationRail extends StatelessWidget {
  const LumeNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.expanded,
    this.brand,
    this.semanticLabel,
    this.background,
  });

  final List<LumeDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// `false` is the 84 px rail; `true` is the 244 px sidebar.
  final bool expanded;

  /// The wordmark. Shown only when [expanded] — the rail has no room, and the
  /// reference hides it there rather than shrinking it.
  final String? brand;

  final String? semanticLabel;

  /// The ground. Defaults to `--bg-sunk`.
  ///
  /// The shell passes `transparent` and paints the ground itself, one layer
  /// lower — because in the reference the ambient wash is a *positioned*
  /// element and `.navside` is not, so the wash paints over the rail's
  /// background rather than under it. Everywhere else the rail brings its own.
  final Color? background;

  double get width => expanded ? LumeSpace.navSide : LumeSpace.navRail;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: background ?? lume.bgSunk,
          border: BorderDirectional(
            end: BorderSide(color: lume.border, width: LumeSpace.border),
          ),
        ),
        child: SafeArea(
          right: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (expanded && brand != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 12,
                      end: 12,
                      top: 4,
                      bottom: 20,
                    ),
                    child: Text(
                      brand!,
                      style: LumeType.tracked(
                        LumeType.fit(context, context.lumeType.display),
                        -0.035,
                      ).copyWith(color: lume.text),
                    ),
                  ),
                for (int i = 0; i < destinations.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 4),
                  _RailTab(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    expanded: expanded,
                    onTap: () => onSelected(i),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailTab extends StatelessWidget {
  const _RailTab({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final LumeDestination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color ink = selected ? lume.accent700 : lume.text2;
    final Color glyph = selected ? lume.accent : lume.text2;

    final Widget label = Text(
      destination.label,
      textAlign: expanded ? TextAlign.start : TextAlign.center,
      maxLines: expanded ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: LumeType.tracked(
        LumeType.fit(
          context,
          expanded ? context.lumeType.cardTitle : context.lumeType.tab,
        ),
        -0.02,
      ).copyWith(color: ink),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: destination.semanticLabel,
      child: LumePressable(
        onTap: onTap,
        borderRadius: LumeRadius.brSm,
        minSize: LumeSpace.tap,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: LumeMotion.duration(context, LumeMotion.fast),
          curve: LumeMotion.ease,
          constraints: const BoxConstraints(minHeight: LumeSpace.tap),
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: expanded ? 12 : 4,
          ),
          decoration: BoxDecoration(
            color: selected ? lume.tintAccent : Colors.transparent,
            borderRadius: LumeRadius.brSm,
          ),
          child: expanded
              ? Row(
                  children: <Widget>[
                    _Glyph(destination: destination, colour: glyph),
                    const SizedBox(width: 12),
                    Expanded(child: label),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _Glyph(destination: destination, colour: glyph),
                    const SizedBox(height: 5),
                    label,
                  ],
                ),
        ),
      ),
    );
  }
}

/// A destination's glyph, with its badge.
///
/// The badge is drawn here rather than by each surface, so the bottom bar, the
/// rail and the sidebar cannot disagree about where an unread marker sits.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.destination, required this.colour});

  final LumeDestination destination;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Widget glyph = LumeIcon(
      destination.icon,
      size: LumeSpace.iconMd,
      color: colour,
    );

    if (!destination.hasBadge) return glyph;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        glyph,
        PositionedDirectional(
          top: -3,
          end: -5,
          child: destination.badgeCount != null && destination.badgeCount! > 0
              ? Container(
                  constraints: const BoxConstraints(minWidth: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: lume.accent,
                    borderRadius: LumeRadius.full,
                    border: Border.all(color: lume.card, width: 1.5),
                  ),
                  child: Text(
                    destination.badgeCount! > 99
                        ? '99+'
                        : '${destination.badgeCount}',
                    textAlign: TextAlign.center,
                    style: LumeType.numeric(
                      LumeType.fit(context, context.lumeType.tab),
                    ).copyWith(color: lume.onAccent, fontSize: 9),
                  ),
                )
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: lume.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: lume.card, width: 1.5),
                  ),
                ),
        ),
      ],
    );
  }
}
