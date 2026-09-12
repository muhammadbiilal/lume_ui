/// Trains' own furniture: the route search, the running strip, the status
/// pill and the route card.
///
/// Every one of these is a *new* component rather than a near-miss reused.
/// The library already has `LumeBadge`, `LumeProgressBar`, `LumeField` and
/// `LumeMiniCard`, and every one of them is a different CSS class with
/// different measurements:
///
/// | here | already existed | why not that one |
/// |---|---|---|
/// | `.status` 10/700, 4/9 padding, a pulsing dot | `.badge` | a different scale, a different tone set, and a live dot the badge has no notion of |
/// | `.railfield` a labelled button, not an input | `.field` | it opens a picker; it never takes a keystroke |
/// | `.live-train__track` 4 tall with a 26-point pin riding it | `.pbar` | a bar has no pin and no position |
/// | `.routecard` 152 wide, a code pair and a fare | `.minicard` | a different width, and three lines that are not a title and a meta |
///
/// Measured from `assets/css/screens/trains.css` and the rendered screen.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// The measured constants for Trains.
abstract final class LumeRailMetrics {
  /// `.railsearch { padding: 16px 15px 14px }`.
  static const EdgeInsets searchPadding = EdgeInsets.fromLTRB(15, 16, 15, 14);

  /// `.railsearch__row { gap: 11px }`.
  static const double rowGap = 11;

  /// `.railsearch__dots { padding: 12px 0 }` with 8-point ends.
  static const double dotSize = 8;
  static const double dotsPadding = 12;

  /// `.railsearch__line { width: 2px; min-height: 24px; margin: 3px 0 }`.
  static const double lineWidth = 2;
  static const double lineMinHeight = 24;
  static const double lineMargin = 3;

  /// `.railsearch__fields { gap: 6px }`, `.railfield { padding: 7px 11px }`.
  static const double fieldGap = 6;
  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 7,
  );

  /// `.railswap { width: 34px; height: 34px }` with a 16-point glyph.
  static const double swapSize = 34;
  static const double swapGlyph = 16;

  /// `.railsearch__foot { gap: 7px; margin-top: 13px }`.
  static const double footGap = 7;
  static const double footTop = 13;

  /// `.railchip { padding: 8px 12px }` with a 14-point glyph.
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const double chipGlyph = 14;

  /// `.live-train__head { gap: 11px }`, `.live-train__no { padding: 5px 8px }`.
  static const double liveHeadGap = 11;
  static const EdgeInsets numberPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 5,
  );

  /// `.live-train__track { height: 4px; margin: 22px 0 14px }` with a
  /// 26-point pin centred on it.
  static const double trackHeight = 4;
  static const double trackTop = 22;
  static const double trackBottom = 14;
  static const double pinSize = 26;
  static const double pinGlyph = 13;

  /// `.railsearch__go` is a `.btn`, and `.btn { height: 46px }`.
  static const double goHeight = 46;

  /// `.routecard { width: 152px; padding: 14px }`.
  static const double routeCardWidth = 152;
  static const EdgeInsets routeCardPadding = EdgeInsets.all(14);

  /// `.status { padding: 4px 9px; gap: 5px }` with a 5-point live dot.
  static const EdgeInsets statusPadding = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 4,
  );
  static const double statusGap = 5;
  static const double liveDot = 5;

  /// `.trainno { padding: 1px 5px; border-radius: 5px }`.
  static const EdgeInsets numberChipPadding = EdgeInsets.symmetric(
    horizontal: 5,
    vertical: 1,
  );
  static const BorderRadius numberChipRadius = BorderRadius.all(
    Radius.circular(5),
  );
}

/// What a `.status` pill is saying.
enum LumeStatusTone {
  /// `.status` with no modifier — a neutral fact.
  neutral,

  /// `.status--ok`.
  ok,

  /// `.status--late`.
  late_,
}

/// `.status` — a short running-status pill.
///
/// Not [LumeBadge]: that is `.badge`, a different scale with a different tone
/// set. This one carries an optional pulsing dot, which is the only thing on
/// the screen that says a figure is being watched rather than remembered.
class LumeStatusPill extends StatelessWidget {
  const LumeStatusPill({
    super.key,
    required this.label,
    this.tone = LumeStatusTone.neutral,
    this.live = false,
  });

  final String label;
  final LumeStatusTone tone;

  /// `.status .live` — a dot that pulses. Decoration: what it means is in the
  /// label beside it, because a pulse is not a word.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg) = switch (tone) {
      LumeStatusTone.neutral => (lume.tintNeutral, lume.text2),
      // `[data-theme="dark"] .status--ok { color: var(--accent-700) }`.
      LumeStatusTone.ok => (
        lume.tintAccent,
        dark ? lume.accent700 : lume.accentInk,
      ),
      LumeStatusTone.late_ => (lume.amber.withValues(alpha: 0.16), lume.amber),
    };

    return Container(
      padding: LumeRailMetrics.statusPadding,
      decoration: BoxDecoration(color: bg, borderRadius: LumeRadius.full),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (live) ...<Widget>[
            _LiveDot(colour: fg),
            const SizedBox(width: LumeRailMetrics.statusGap),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LumeType.natural(
              context,
              context.lumeType.metaSmall,
              size: 10,
            ).copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// `@keyframes pulse` on a 5-point disc.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.colour});

  final Color colour;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    // Repeating forever is only acceptable while the platform allows motion;
    // under reduced motion the dot is simply a dot.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.disableAnimationsOf(context)) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(
      begin: 1,
      end: 0.35,
    ).animate(CurvedAnimation(parent: _c, curve: LumeMotion.ease)),
    child: Container(
      width: LumeRailMetrics.liveDot,
      height: LumeRailMetrics.liveDot,
      decoration: BoxDecoration(color: widget.colour, shape: BoxShape.circle),
    ),
  );
}

/// `.trainno` — a service's own identifier, set small beside its name.
class LumeTrainNumber extends StatelessWidget {
  const LumeTrainNumber(this.number, {super.key});

  final String number;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Container(
      padding: LumeRailMetrics.numberChipPadding,
      decoration: BoxDecoration(
        color: lume.tintNeutral,
        borderRadius: LumeRailMetrics.numberChipRadius,
      ),
      // A railway's identifier is Latin whatever the interface is doing, and
      // `rtl.css` isolates it for exactly that reason.
      child: LumeNumerals(
        number,
        style: LumeType.natural(
          context,
          context.lumeType.metaSmall,
          size: 10,
        ).copyWith(color: lume.text3, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// `.railfield` — a labelled button that opens a station picker.
///
/// Not a text field: it never takes a keystroke, and drawing it as one would
/// promise a keyboard that never appears.
class LumeRailField extends StatelessWidget {
  const LumeRailField({
    super.key,
    required this.label,
    required this.value,
    required this.semanticLabel,
    this.onTap,
  });

  /// "FROM", "TO" — set in caps by the stylesheet, not by the string.
  final String label;
  final String value;

  /// What a screen reader hears: the label and the station together.
  final String semanticLabel;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      borderRadius: LumeRadius.brSm,
      minSize: 0,
      child: Container(
        width: double.infinity,
        padding: LumeRailMetrics.fieldPadding,
        decoration: BoxDecoration(
          color: lume.card2,
          borderRadius: LumeRadius.brSm,
          border: Border.all(color: lume.border, width: LumeSpace.border),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                // `text-transform: uppercase` — a presentation rule, so it is
                // applied here rather than baked into the translation.
                label.toUpperCase(),
                style: LumeType.tracked(
                  LumeType.natural(context, context.lumeType.tab, size: 10),
                  0.07,
                ).copyWith(color: lume.text3, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.cardTitle,
                    size: 14,
                  ),
                  -0.026,
                ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.railchip` — Today, Tomorrow, and the one that opens a date picker.
class LumeRailChip extends StatelessWidget {
  const LumeRailChip({
    super.key,
    this.label,
    this.icon,
    required this.semanticLabel,
    this.selected = false,
    this.onTap,
  });

  final String? label;
  final String? icon;
  final String semanticLabel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color fg = selected ? lume.bg : lume.text2;
    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      // Both ways round, not only when it is true: these are a single
      // selection, and "not selected" is as much a fact as "selected" (R3).
      selected: selected,
      borderRadius: LumeRadius.full,
      minSize: 0,
      child: Container(
        padding: LumeRailMetrics.chipPadding,
        decoration: BoxDecoration(
          color: selected ? lume.text : lume.card2,
          borderRadius: LumeRadius.full,
          border: Border.all(
            color: selected ? lume.text : lume.border,
            width: LumeSpace.border,
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null)
                LumeIcon(icon!, size: LumeRailMetrics.chipGlyph, color: fg),
              if (label != null)
                // Whole, never ellipsised: `min-width: auto` holds a flex
                // item at its content size, and the reference's chips keep
                // their widths at every cell it is drawn at.
                Text(
                  label!,
                  maxLines: 1,
                  style: LumeType.natural(
                    context,
                    context.lumeType.meta,
                    size: 12,
                  ).copyWith(color: fg, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.railsearch` — the origin, the destination, the day and the search.
class LumeRailSearchCard extends StatelessWidget {
  /// `.railsearch__foot`, so a test can measure the row the chips and the
  /// Search button share.
  static const Key footKey = Key('railsearch.foot');

  /// `.railsearch__go`, whose trailing edge is the whole point of the foot's
  /// `margin-left: auto`.
  static const Key goKey = Key('railsearch.go');

  const LumeRailSearchCard({
    super.key,
    required this.origin,
    required this.destination,
    required this.chips,
    required this.searchLabel,
    this.art,
    this.onSwap,
    this.swapLabel = '',
    this.onSearch,
  });

  final LumeRailField origin;
  final LumeRailField destination;

  /// Today, Tomorrow, and the date picker.
  final List<LumeRailChip> chips;

  final String searchLabel;

  /// `.railsearch__art` — decoration behind the card, clipped by it.
  final Widget? art;

  final VoidCallback? onSwap;
  final String swapLabel;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: lume.card,
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.sm,
      ),
      child: Stack(
        children: <Widget>[
          if (art != null)
            Positioned.fill(
              child: IgnorePointer(child: ExcludeSemantics(child: art!)),
            ),
          Padding(
            // The border is *not* added here: this card is a `Container`, and
            // `BoxDecoration.padding` already reserves `Border.all`'s
            // dimensions. Adding it again cost the two fields two points
            // each. (`LumeCard` is a `DecoratedBox`, which does not — see
            // C26.)
            padding: LumeRailMetrics.searchPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // `align-items: stretch` — the rail and the swap take the
                // height the two fields set between them.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const _StationRail(),
                      const SizedBox(width: LumeRailMetrics.rowGap),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            origin,
                            const SizedBox(height: LumeRailMetrics.fieldGap),
                            destination,
                          ],
                        ),
                      ),
                      const SizedBox(width: LumeRailMetrics.rowGap),
                      Center(
                        child: LumeRailSwap(
                          semanticLabel: swapLabel,
                          onTap: onSwap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LumeRailMetrics.footTop),
                // `.railsearch__foot` is a flex whose items do not shrink:
                // `min-width: auto` is every flex item's default and nothing
                // overrides it. Measured at 359, the chips keep their 61.19
                // and the Search button is pushed to 337.75 — past the
                // content box, which ends at 323, and into the card's own
                // 15 points of padding, which it very nearly fills.
                //
                // So the row is laid out at `max(natural, available)`:
                // `IntrinsicWidth` finds the natural total, the minimum holds
                // it to the box when there is room — which is what lets the
                // `Spacer` (`margin-left: auto`) put the button on the
                // trailing edge at 390 — and `OverflowBox` lets it out of the
                // box when there is not. Nothing is clipped here: the card is
                // `overflow: hidden` and clips the remainder itself, exactly
                // where the prototype does.
                //
                // The obvious translation is wrong in a way that looks right.
                // `Flexible` divides free space by flex factor whether or not
                // the child needs it, so a row of `Flexible` chips gives each
                // an equal share and ellipsises the longer label. CSS
                // `flex-shrink` engages only on overflow. See C32.
                SizedBox(
                  key: footKey,
                  // The Search button is the tallest item, and `align-items:
                  // center` holds the chips against it.
                  height: LumeRailMetrics.goHeight,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) =>
                        OverflowBox(
                          maxWidth: double.infinity,
                          alignment: AlignmentDirectional.centerStart,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: c.maxWidth),
                            child: IntrinsicWidth(
                              child: Row(
                                children: <Widget>[
                                  for (
                                    int i = 0;
                                    i < chips.length;
                                    i++
                                  ) ...<Widget>[
                                    if (i > 0)
                                      const SizedBox(
                                        width: LumeRailMetrics.footGap,
                                      ),
                                    chips[i],
                                  ],
                                  // `gap: 7px` applies between every pair of
                                  // items; `margin-left: auto` is extra on
                                  // top of it. When there is no free space
                                  // the auto margin is nothing and the gap
                                  // still stands, which is why the button
                                  // starts at 243.11 and not at the last
                                  // chip's right edge.
                                  const SizedBox(
                                    width: LumeRailMetrics.footGap,
                                  ),
                                  const Spacer(),
                                  _SearchButton(
                                    key: goKey,
                                    label: searchLabel,
                                    onTap: onSearch,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.railswap` — the control that turns a journey around.
///
/// `align-self: center` on a stretched row, so it sits between the two fields
/// whatever height they take.
class LumeRailSwap extends StatelessWidget {
  const LumeRailSwap({super.key, required this.semanticLabel, this.onTap});

  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      borderRadius: LumeRadius.brIcon,
      minSize: 0,
      child: Container(
        width: LumeRailMetrics.swapSize,
        height: LumeRailMetrics.swapSize,
        decoration: BoxDecoration(
          color: lume.tintNeutral,
          borderRadius: LumeRadius.brIcon,
        ),
        child: Center(
          child: LumeIcon(
            LumeIcons.swap,
            size: LumeRailMetrics.swapGlyph,
            color: lume.text2,
          ),
        ),
      ),
    );
  }
}

/// `.railsearch__go` — `.btn.btn--accent` at a smaller size.
class _SearchButton extends StatelessWidget {
  const _SearchButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return LumePressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: LumeRadius.brSm,
      child: Container(
        // `.btn { height: 46px }` — a fixed height the `.railsearch__go`
        // override does not touch, so the 10 points of vertical padding it
        // declares never decide anything.
        height: LumeRailMetrics.goHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: lume.accent,
          borderRadius: LumeRadius.brSm,
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeIcon(LumeIcons.search, size: 15, color: lume.onAccent),
              const SizedBox(width: 7),
              Text(
                label,
                // `.btn { letter-spacing: -.022em }` — 13px of it is the
                // -0.286px the prototype reports, and all six of them are
                // the difference between a 94.64 button and a 96.36 one.
                style: LumeType.tracked(
                  LumeType.natural(context, context.lumeType.label, size: 13),
                  -0.022,
                ).copyWith(color: lume.onAccent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.railsearch__dots` — two rings and the line between them.
class _StationRail extends StatelessWidget {
  const _StationRail();

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    Widget dot(Color border) => Container(
      width: LumeRailMetrics.dotSize,
      height: LumeRailMetrics.dotSize,
      decoration: BoxDecoration(
        color: lume.card,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
    );

    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: LumeRailMetrics.dotsPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            dot(lume.accent),
            Flexible(
              child: Container(
                width: LumeRailMetrics.lineWidth,
                constraints: const BoxConstraints(
                  minHeight: LumeRailMetrics.lineMinHeight,
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: LumeRailMetrics.lineMargin,
                ),
                decoration: BoxDecoration(
                  color: lume.border2,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
            dot(lume.text3),
          ],
        ),
      ),
    );
  }
}

/// `.live-train` — the service being followed, and where it has got to.
class LumeLiveTrainCard extends StatelessWidget {
  const LumeLiveTrainCard({
    super.key,
    required this.number,
    required this.name,
    required this.route,
    required this.status,
    required this.progress,
    required this.stops,
    required this.semanticLabel,
  });

  final String number;
  final String name;

  /// "Karachi Cantt → Islamabad", composed by the caller so the arrow follows
  /// the reading direction.
  final String route;

  final LumeStatusPill status;

  /// 0–1 along the line.
  final double progress;

  /// The three the reference names: start, now, end.
  final List<LumeLiveTrainStop> stops;

  /// The whole card said once, so a screen reader is not read a bar.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: LumeRailMetrics.numberPadding,
                decoration: BoxDecoration(
                  color: lume.tintAccent,
                  borderRadius: LumeRadius.brIcon,
                ),
                child: LumeNumerals(
                  number,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                    size: 11,
                  ).copyWith(color: lume.accent, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: LumeRailMetrics.liveHeadGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LumeType.tracked(
                        LumeType.natural(
                          context,
                          context.lumeType.cardTitle,
                          size: 14,
                        ),
                        -0.028,
                      ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    LumeNumerals(
                      route,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                            size: 11,
                          ).copyWith(
                            color: lume.text3,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LumeRailMetrics.liveHeadGap),
              status,
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: LumeRailMetrics.trackTop,
              bottom: LumeRailMetrics.trackBottom,
            ),
            child: _Track(progress: progress.clamp(0.0, 1.0)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < stops.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _Stop(
                    stop: stops[i],
                    align: i == 0
                        ? TextAlign.start
                        : i == stops.length - 1
                        ? TextAlign.end
                        : TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One column of `.live-train__stops`.
@immutable
class LumeLiveTrainStop {
  const LumeLiveTrainStop({
    required this.lead,
    required this.station,
    this.isNow = false,
  });

  /// "22:00", or the word the reference uses for the middle column.
  final String lead;

  final String station;
  final bool isNow;
}

class _Stop extends StatelessWidget {
  const _Stop({required this.stop, required this.align});

  final LumeLiveTrainStop stop;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Column(
      crossAxisAlignment: switch (align) {
        TextAlign.start => CrossAxisAlignment.start,
        TextAlign.end => CrossAxisAlignment.end,
        _ => CrossAxisAlignment.center,
      },
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumeNumerals(
          stop.lead,
          style:
              LumeType.tracked(
                LumeType.natural(context, context.lumeType.meta, size: 12),
                -0.02,
              ).copyWith(
                color: stop.isNow ? lume.accent : lume.text2,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          stop.station,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LumeType.natural(
            context,
            context.lumeType.tab,
            size: 10,
          ).copyWith(color: lume.text3, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// `.live-train__track` with its pin.
class _Track extends StatelessWidget {
  const _Track({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Duration d = LumeMotion.duration(context, LumeMotion.slow);

    return SizedBox(
      height: LumeRailMetrics.trackHeight,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) => Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: lume.tintNeutral,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
              child: const SizedBox.expand(),
            ),
            AnimatedContainer(
              duration: d,
              curve: LumeMotion.easeOut,
              width: c.maxWidth * progress,
              decoration: BoxDecoration(
                color: lume.accent,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
            // `left: <pct>; transform: translate(-50%, -50%)` — the pin rides
            // the fill's leading edge and hangs off the track on both sides.
            AnimatedPositioned(
              duration: d,
              curve: LumeMotion.easeOut,
              left: c.maxWidth * progress - LumeRailMetrics.pinSize / 2,
              top:
                  LumeRailMetrics.trackHeight / 2 - LumeRailMetrics.pinSize / 2,
              child: Container(
                width: LumeRailMetrics.pinSize,
                height: LumeRailMetrics.pinSize,
                decoration: BoxDecoration(
                  color: lume.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: lume.accent, width: 1.5),
                  boxShadow: context.lumeShadows.sm,
                ),
                child: Center(
                  child: LumeIcon(
                    LumeIcons.train,
                    size: LumeRailMetrics.pinGlyph,
                    color: lume.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.routecard` — a code pair, how long and how many, and the cheapest fare.
class LumeRouteCard extends StatelessWidget {
  const LumeRouteCard({
    super.key,
    required this.fromCode,
    required this.toCode,
    required this.meta,
    required this.fare,
    required this.semanticLabel,
    this.onTap,
  });

  final String fromCode;
  final String toCode;

  /// "17h 45m · 4 trains", already composed for the reader's locale.
  final String meta;

  /// "from Rs 2,400".
  final String fare;

  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      borderRadius: LumeRadius.brLg,
      minSize: 0,
      child: Container(
        // `.routecard { width: 152px }` is the width at the sizes the
        // reference is drawn at — the content is narrower, so the minimum
        // decides and the card measures exactly 152. At an accessibility text
        // scale the codes and the fare outgrow it, and a fixed width would
        // clip them; the strip scrolls sideways, so the card widens instead.
        // The same call D36 makes for the day ring, with the opposite remedy
        // because here there is somewhere to grow into.
        constraints: const BoxConstraints(
          minWidth: LumeRailMetrics.routeCardWidth,
        ),
        padding: LumeRailMetrics.routeCardPadding,
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _Code(fromCode),
                  const SizedBox(width: 7),
                  // `rtl.css` flips this one, because the pair reads in the
                  // direction the language does.
                  LumeIcon(LumeIcons.arrowR, size: 14, color: lume.text3),
                  const SizedBox(width: 7),
                  _Code(toCode),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LumeType.natural(
                  context,
                  context.lumeType.metaSmall,
                  size: 11,
                ).copyWith(color: lume.text3, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 5),
              LumeNumerals(
                fare,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LumeType.natural(
                  context,
                  context.lumeType.meta,
                  size: 12,
                ).copyWith(color: lume.accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Code extends StatelessWidget {
  const _Code(this.code);

  final String code;

  @override
  Widget build(BuildContext context) => Text(
    code,
    style: LumeType.tracked(
      LumeType.natural(context, context.lumeType.cardTitle, size: 15),
      -0.03,
    ).copyWith(color: context.lume.text, fontWeight: FontWeight.w800),
  );
}
