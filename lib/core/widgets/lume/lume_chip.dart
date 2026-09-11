/// Selection: filter chips, record chips, the segmented control, in-screen
/// tabs, and the sort bar.
///
/// Five controls that all mean "choose", measured apart because they are not
/// the same shape:
///
/// | | height | padding | radius | selected |
/// |---|---|---|---|---|
/// | `.fchip` | 31 | 7 12 | full | filled accent, white ink |
/// | `.cchip` | 38 | 0 16 | full | filled accent, white ink |
/// | `.seg` | 31 | 8 10 | full | `card` fill **and a shadow** |
/// | `.ttab` | 37 | 10 12 | 0 | ink darkens; underline carries it |
/// | `.sortopt` | 23 | 5 10 | full | `tintAccent` fill, `accentInk` |
///
/// The segmented control's selected state casting a shadow is the giveaway
/// that it is a sliding thumb over a track rather than a row of buttons.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// One option in any of the controls below.
@immutable
class LumeChoice {
  const LumeChoice({
    required this.value,
    required this.label,
    this.count,
    this.icon,
  });

  final String value;
  final String label;

  /// A count shown beside the label, tabular so a column of them aligns.
  final int? count;

  final String? icon;
}

/// `.fchip` — a tool's filter chip. Compact, bordered, fills when on.
class LumeFilterChip extends StatelessWidget {
  const LumeFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.count,
    this.muted = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? icon;
  final int? count;

  /// Dimmed because a selection limit has been reached — the interest picker's
  /// `.is-muted`. Still pressable: pressing it says why.
  final bool muted;

  static const double height = 31;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    Widget chip = Container(
      constraints: const BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? lume.accent : lume.card,
        borderRadius: LumeRadius.full,
        border: Border.all(
          color: selected ? lume.accent : lume.border,
          width: LumeSpace.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            LumeIcon(
              icon!,
              size: LumeSpace.iconSm,
              color: selected ? lume.onAccent : lume.text2,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: LumeType.tracked(
              LumeType.fit(context, context.lumeType.meta),
              -0.015,
            ).copyWith(color: selected ? lume.onAccent : lume.text2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (count != null) ...<Widget>[
            const SizedBox(width: 5),
            Text(
              '$count',
              style:
                  LumeType.numeric(
                    LumeType.fit(context, context.lumeType.meta),
                  ).copyWith(
                    color: (selected ? lume.onAccent : lume.text2).withValues(
                      alpha: 0.7,
                    ),
                  ),
            ),
          ],
        ],
      ),
    );

    if (muted && !selected) chip = Opacity(opacity: 0.45, child: chip);

    return Semantics(
      button: true,
      toggled: selected,
      label: label,
      child: LumePressable(
        onTap: onTap,
        borderRadius: LumeRadius.full,
        minSize: LumeSpace.tap,
        excludeSemantics: true,
        child: Center(widthFactor: 1, child: chip),
      ),
    );
  }
}

/// `.cchip` — a record collection's filter chip. Taller, carries its count.
class LumeRecordChip extends StatelessWidget {
  const LumeRecordChip({
    super.key,
    required this.label,
    this.count,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  static const double height = 38;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      button: true,
      toggled: selected,
      label: count == null ? label : '$label, $count',
      child: LumePressable(
        onTap: onTap,
        borderRadius: LumeRadius.full,
        minSize: LumeSpace.tap,
        excludeSemantics: true,
        child: Center(
          widthFactor: 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: height),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? lume.accent : lume.card,
              borderRadius: LumeRadius.full,
              border: Border.all(
                color: selected ? lume.accent : lume.border2,
                width: LumeSpace.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: LumeType.fit(
                    context,
                    context.lumeType.label,
                  ).copyWith(color: selected ? lume.onAccent : lume.text2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (count != null) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style:
                        LumeType.numeric(
                          LumeType.fit(context, context.lumeType.label),
                        ).copyWith(
                          color: (selected ? lume.onAccent : lume.text2)
                              .withValues(alpha: 0.7),
                        ),
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

/// `.segmented` — mutually exclusive options on one track.
class LumeSegmented extends StatelessWidget {
  const LumeSegmented({
    super.key,
    required this.items,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  final List<LumeChoice> items;
  final String value;
  final ValueChanged<String>? onChanged;
  final String? semanticLabel;

  static const double height = 31;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: lume.tintNeutral,
          borderRadius: LumeRadius.full,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final LumeChoice item in items)
              _Segment(
                item: item,
                selected: item.value == value,
                onTap: onChanged == null ? null : () => onChanged!(item.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.item, required this.selected, this.onTap});

  final LumeChoice item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: LumePressable(
        onTap: onTap,
        borderRadius: LumeRadius.full,
        minSize: LumeSegmented.height,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: LumeMotion.duration(context, LumeMotion.fast),
          curve: LumeMotion.ease,
          constraints: const BoxConstraints(minHeight: LumeSegmented.height),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            // The selected segment is a raised thumb, not just a tinted cell.
            color: selected ? lume.card : Colors.transparent,
            borderRadius: LumeRadius.full,
            boxShadow: selected ? context.lumeShadows.xs : null,
          ),
          child: Text(
            item.label,
            style: LumeType.tracked(
              LumeType.fit(context, context.lumeType.label),
              -0.02,
            ).copyWith(color: selected ? lume.text : lume.text3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// `.ttabs` — in-screen tabs that re-compose the screen.
///
/// Pressed buttons in a named group, not ARIA tabs: there is no tab panel for
/// them to point at, because choosing one rebuilds the screen rather than
/// swapping a sibling.
class LumeTabs extends StatelessWidget {
  const LumeTabs({
    super.key,
    required this.items,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  final List<LumeChoice> items;
  final String value;
  final ValueChanged<String>? onChanged;
  final String? semanticLabel;

  static const double height = 37;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: lume.border, width: LumeSpace.border),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (final LumeChoice item in items)
                _Tab(
                  item: item,
                  selected: item.value == value,
                  onTap: onChanged == null
                      ? null
                      : () => onChanged!(item.value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, this.onTap});

  final LumeChoice item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      button: true,
      selected: selected,
      label: item.count == null ? item.label : '${item.label}, ${item.count}',
      child: LumePressable(
        onTap: onTap,
        borderRadius: LumeRadius.brXs,
        minSize: LumeTabs.height,
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: LumeTabs.height),
          padding: const EdgeInsets.only(
            top: 10,
            bottom: 11,
            left: 12,
            right: 12,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? lume.text : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                item.label,
                style:
                    LumeType.tracked(
                      LumeType.fit(context, context.lumeType.meta),
                      -0.024,
                    ).copyWith(
                      color: selected ? lume.text : lume.text3,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (item.count != null) ...<Widget>[
                const SizedBox(width: 5),
                Text(
                  '${item.count}',
                  style: LumeType.numeric(
                    LumeType.fit(context, context.lumeType.metaSmall),
                  ).copyWith(color: lume.text3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Which way a sort runs.
enum LumeSortDirection { ascending, descending }

/// `.sortbar` — the dimensions a list can be sorted by.
///
/// Pressing the active dimension reverses it, which is why the direction
/// belongs to the selected option rather than to the bar.
class LumeSortBar extends StatelessWidget {
  const LumeSortBar({
    super.key,
    required this.items,
    required this.value,
    required this.direction,
    this.onChanged,
    this.label,
  });

  final List<LumeChoice> items;
  final String value;
  final LumeSortDirection direction;

  /// Called with the option pressed and the direction it should now take.
  final void Function(String value, LumeSortDirection direction)? onChanged;

  final String? label;

  static const double optionHeight = 23;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Row(
      children: <Widget>[
        LumeIcon(LumeIcons.sliders, size: LumeSpace.iconSm, color: lume.text3),
        const SizedBox(width: 5),
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: LumeSpace.x2),
        ],
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final LumeChoice item in items) ...<Widget>[
                  _SortOption(
                    item: item,
                    selected: item.value == value,
                    direction: direction,
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!(
                            item.value,
                            item.value == value
                                ? (direction == LumeSortDirection.ascending
                                      ? LumeSortDirection.descending
                                      : LumeSortDirection.ascending)
                                : LumeSortDirection.descending,
                          ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.item,
    required this.selected,
    required this.direction,
    this.onTap,
  });

  final LumeChoice item;
  final bool selected;
  final LumeSortDirection direction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final String spoken = selected
        ? '${item.label}, '
              '${direction == LumeSortDirection.ascending ? 'ascending' : 'descending'}'
        : item.label;

    return Semantics(
      button: true,
      selected: selected,
      label: spoken,
      child: LumePressable(
        onTap: onTap,
        borderRadius: LumeRadius.full,
        minSize: LumeSpace.tap,
        excludeSemantics: true,
        child: Center(
          widthFactor: 1,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: LumeSortBar.optionHeight,
            ),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? lume.tintAccent : lume.tintNeutral,
              borderRadius: LumeRadius.full,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  item.label,
                  style: LumeType.fit(context, context.lumeType.metaSmall)
                      .copyWith(
                        color: selected ? lume.accentInk : lume.text3,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (selected) ...<Widget>[
                  const SizedBox(width: 3),
                  // Direction is a glyph, not a rotation of the label.
                  LumeIcon(
                    direction == LumeSortDirection.ascending
                        ? LumeIcons.arrowUp
                        : LumeIcons.arrowDown,
                    size: 13,
                    color: lume.accentInk,
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

/// `.filterbar` — groups of filter chips on one scrolling rail.
class LumeFilterBar extends StatelessWidget {
  const LumeFilterBar({super.key, required this.children, this.gutters = true});

  final List<Widget> children;
  final bool gutters;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: gutters
        ? const EdgeInsetsDirectional.symmetric(
            horizontal: LumeSpace.pageCompact,
          )
        : EdgeInsets.zero,
    child: Row(
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 6),
          children[i],
        ],
      ],
    ),
  );
}
