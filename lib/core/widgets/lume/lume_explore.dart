/// Explore's furniture, and Today's quote card.
///
/// Six components that carry *outward-facing* content — something the product
/// found rather than something the reader wrote — which is why they all share
/// one rule: **every one of them takes structured values and composes its own
/// sentence.** Not one takes a preassembled line of English.
///
/// | | `.class` |
/// |---|---|
/// | [LumeQuoteCard] | `.quote` — Today's ayah and thought |
/// | [LumeFeatureCard] | `.feature` — the 216-point gradient hero |
/// | [LumeWeatherCard] | `.weather` — the reading, in the reader's units |
/// | [LumeListRow] | `.list-row` — "Around you" and "Nearby" |
/// | [LumeArticleRow] | `.article` — a story in "Today's reads" |
/// | [LumeScoreCard] | `.score` — the live cricket card |
///
/// **[LumeListRow] is not `LumeRichRow`.** That is `.rrow`; this is
/// `.list-row`, whose title is 14/700 over an 11/500 sub with a value *and* a
/// chevron at the end. Measured side by side.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// One of a card foot's ghost actions — Bookmark, Share.
///
/// Data rather than a widget, because the card places the painted control and
/// its touch target in two different places in its tree: a 35 × 30 spacer sits
/// in the foot's row so the layout is the reference's, and the glyph is drawn
/// inside a 44 × 44 target in the card's own stack. A caller handing in a
/// finished widget could not be split that way.
@immutable
class LumeCardAction {
  const LumeCardAction({
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.selected = false,
  });

  final String icon;

  /// The accessible name. Not optional.
  final String semanticLabel;

  final VoidCallback? onPressed;

  /// `.ghostbtn.is-on` — accented, and the glyph filled.
  final bool selected;

  /// `.ghostbtn { height: 30px; padding: 0 10px }` with a 15-point glyph.
  static const double boxWidth = 35;
  static const double boxHeight = 30;

  /// `.ghostbtn svg { width: 15px; height: 15px }`.
  static const double glyphSize = 15;

  /// `.card__actions { gap: 4px }`.
  static const double gap = 4;

  /// §9's floor, which the painted box is under on both axes.
  static const double target = LumeSpace.tap;
}

/// `.quote` — a card with a mark in its corner, a line worth reading, and who
/// it is from.
///
/// The Arabic is optional because the section is faith-*swapped* rather than
/// faith-gated: a Muslim reader gets an ayah with its original, everyone else
/// gets a thought with only a translation's worth of text.
///
/// ### Where the foot's actions really are
///
/// `.ghostbtn` is 35 × 30 — under §9's 44-point floor on both axes — and it
/// sits in a card foot that is exactly its own height, so growing the control
/// makes every card carrying one fourteen points taller. D6's remedy applies:
/// **separate the painted box from the target.**
///
/// The foot's row holds a 35 × 30 spacer per action, at the reference's
/// coordinates, which is what keeps the row 30 tall and the card its measured
/// height. The glyph itself is drawn inside a 44 × 44 [LumePressable] in the
/// card's own stack, laid exactly over that spacer and extended *outward* —
/// away from its neighbour — into the card's padding on the trailing side and
/// into the empty run before the actions on the leading side. The two targets
/// touch and do not overlap:
///
/// ```text
///  ← leading                                        trailing →
///        ┌─────────────────┐     ┌─────────────────┐
///        │  ╭───────────╮  │     │  ╭───────────╮  │
///        │  │ box 35×30 │ 9│  4  │ 9│ box 35×30 │  │
///        │  ╰───────────╯  │     │  ╰───────────╯  │
///        └─────────────────┘     └─────────────────┘
///           target 1: 44            target 0: 44    ↑ 18 of card padding
/// ```
///
/// Two is the most that fits: a third would have to overlap its neighbour by
/// five points, because the pitch between controls is 39 and the target is 44.
class LumeQuoteCard extends StatelessWidget {
  const LumeQuoteCard({
    super.key,
    required this.text,
    required this.attribution,
    this.arabic,
    this.actions = const <LumeCardAction>[],
  });

  /// The reading, in the reader's language.
  final String text;

  /// "Ar-Ra’d 13:28", "On building habits".
  final String attribution;

  /// Scripture in its own script. Carried, never translated, and always
  /// right-to-left whatever the interface is doing.
  final String? arabic;

  /// Bookmark and share, in the order the reference draws them.
  final List<LumeCardAction> actions;

  /// `.quote { padding: 20px 18px 16px }`.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(18, 20, 18, 16);

  /// How far a target reaches past its painted box, away from its neighbour.
  static const double outward = LumeCardAction.target - LumeCardAction.boxWidth;

  /// The trailing inset of the target over the action [fromEnd] places from
  /// the trailing edge, measured from the card's inner edge. 0 is the
  /// trailing-most action, whose spare points go into the card's padding.
  static double targetEnd(int fromEnd) => fromEnd == 0
      ? padding.right - outward
      : padding.right +
            fromEnd * (LumeCardAction.boxWidth + LumeCardAction.gap);

  /// The bottom inset of every target, measured from the card's inner edge.
  static const double targetBottom =
      16 - (LumeCardAction.target - LumeCardAction.boxHeight) / 2;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    // A third target cannot avoid overlapping its neighbour: the pitch between
    // controls is 39 and the target is 44. Asserted here rather than in the
    // constructor, which is const and cannot read a list's length.
    assert(
      actions.length <= 2,
      'a card foot takes at most two actions — see the diagram above',
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.sm,
        // `radial-gradient(120% 90% at 100% 0%, var(--tint-accent),
        //  transparent 60%), var(--card)` — a wash from the top corner the
        // mark sits in, *over* the card. A gradient replaces `color` rather
        // than layering on it, so the card colour is the far stop; a
        // transparent one there shows the page through the card.
        gradient: RadialGradient(
          center: const Alignment(1, -1),
          radius: 1.2,
          colors: <Color>[lume.tintAccent, lume.card],
          stops: const <double>[0, 0.6],
        ),
      ),
      // The stack wraps the padding rather than sitting inside it, so the
      // mark's offsets are the stylesheet's own and a target can reach into
      // the card's padding without being clipped out of the hit test.
      child: Stack(
        children: <Widget>[
          // `.quote__mark { top: 12px; right: 16px; opacity: .16 }` — under
          // the text, which is why `.quote__text` is `position: relative`.
          PositionedDirectional(
            top: 12,
            end: 16,
            child: ExcludeSemantics(
              child: Opacity(
                opacity: 0.16,
                child: LumeIcon(LumeIcons.quote, size: 42, color: lume.accent),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (arabic != null) ...<Widget>[
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        arabic!,
                        textAlign: TextAlign.right,
                        style:
                            LumeType.arabic(
                              size: 20,
                              weight: FontWeight.w500,
                            ).copyWith(
                              color: lume.text,
                              // `line-height: 2.1` — Naskh needs the room, and
                              // the reference gives it rather than taking the
                              // reading height the rest of the product uses.
                              height: 2.1,
                              letterSpacing: 0,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  text,
                  style:
                      LumeType.tracked(
                        LumeType.fit(context, context.lumeType.cardTitle),
                        -0.02,
                      ).copyWith(
                        color: lume.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: LumeType.lineHeight(context, 1.55),
                      ),
                ),
                // `.card__foot { margin-top: 14px; padding-top: 12px;
                //  border-top: 1px solid var(--border) }`
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: lume.border,
                        width: LumeSpace.border,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        // `.quote__by { margin-top: 11px }`. The foot centres
                        // its children, so the margin is part of what is
                        // centred: a 26-point margin box in a 30-point line
                        // leaves 2 above it, and the words sit 13 down.
                        child: Padding(
                          padding: const EdgeInsets.only(top: 11),
                          child: Text(
                            attribution,
                            style:
                                LumeType.natural(
                                  context,
                                  context.lumeType.meta,
                                  size: 12,
                                ).copyWith(
                                  color: lume.text3,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      // The room the painted glyphs occupy. The glyphs
                      // themselves are drawn inside their targets, above.
                      for (int i = 0; i < actions.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: LumeCardAction.gap),
                        const SizedBox(
                          width: LumeCardAction.boxWidth,
                          height: LumeCardAction.boxHeight,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < actions.length; i++)
            PositionedDirectional(
              end: targetEnd(actions.length - 1 - i),
              bottom: targetBottom,
              child: _ActionTarget(
                action: actions[i],
                fromEnd: actions.length - 1 - i,
              ),
            ),
        ],
      ),
    );
  }
}

/// A card action: a 44 × 44 target with the reference's 35 × 30 glyph box
/// inside it, pushed to whichever end keeps the target clear of its neighbour.
class _ActionTarget extends StatelessWidget {
  const _ActionTarget({required this.action, required this.fromEnd});

  final LumeCardAction action;

  /// 0 is the trailing-most action, whose spare nine points go outward into
  /// the card's padding; every other action's go inward, away from it.
  final int fromEnd;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return LumePressable(
      onTap: action.onPressed,
      semanticLabel: action.semanticLabel,
      // Said out loud only when it is true: "share" is not a thing that can be
      // deselected, and announcing "not selected" for it would be noise.
      selected: action.selected ? true : null,
      borderRadius: LumeRadius.brXs,
      // The box is already §9's floor; asking for it again would do nothing.
      minSize: 0,
      child: SizedBox(
        width: LumeCardAction.target,
        height: LumeCardAction.target,
        child: Align(
          // The glyph box sits against the edge nearest its neighbour, so the
          // spare nine points fall on the outward side.
          alignment: fromEnd == 0
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: LumeCardAction.boxWidth,
            height: LumeCardAction.boxHeight,
            child: Center(
              child: LumeIcon(
                action.icon,
                size: LumeCardAction.glyphSize,
                color: action.selected ? lume.accent : lume.text2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.feature`'s own three-stop gradient, and its dark counterpart.
LinearGradient _featureGradient(BuildContext context) {
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  return LinearGradient(
    // 160deg in CSS, measured from the top and turning clockwise.
    begin: const Alignment(-0.36, -1),
    end: const Alignment(0.36, 1),
    colors: dark
        ? const <Color>[Color(0xFF0B3A34), Color(0xFF0E6A5D), Color(0xFF12897A)]
        : const <Color>[
            Color(0xFF16544C),
            Color(0xFF0E9F8A),
            Color(0xFF34B39D),
          ],
    stops: const <double>[0, 0.6, 1],
  );
}

/// `.feature` — the 216-point gradient card at the top of Explore.
class LumeFeatureCard extends StatelessWidget {
  const LumeFeatureCard({
    super.key,
    required this.tag,
    required this.title,
    required this.text,
    required this.meta,
    required this.art,
    this.onTap,
  });

  /// "Featured collection", in a frosted pill.
  final String tag;

  final String title;
  final String text;

  /// The three facts under it — "40 duas", "Audio included", "12 min" — as
  /// separate strings, so the dots between them are drawn rather than typed.
  final List<String> meta;

  /// The drawing behind it.
  final Widget art;

  final VoidCallback? onTap;

  /// `.feature { min-height: 216px }`.
  static const double minHeight = 216;

  @override
  Widget build(BuildContext context) => LumePressable(
    onTap: onTap,
    semanticLabel: '$tag. $title. $text. ${meta.join(', ')}',
    borderRadius: LumeRadius.brXl,
    minSize: 0,
    child: Container(
      constraints: const BoxConstraints(minHeight: minHeight),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: LumeRadius.brXl,
        // `.feature` is its own gradient, not one of the eight tokens:
        // `linear-gradient(160deg, #16544C, #0E9F8A 60%, #34B39D)`.
        gradient: _featureGradient(context),
        boxShadow: context.lumeShadows.md,
      ),
      child: ExcludeSemantics(
        child: Stack(
          // The text block hugs the bottom edge; a Stack aligns its
          // unpositioned child at the top otherwise, which left the card
          // top-heavy against the reference.
          alignment: AlignmentDirectional.bottomStart,
          children: <Widget>[
            Positioned.fill(child: art),
            // `justify-content: flex-end` with `margin-bottom: auto` on the
            // tag: one child at the top, the rest on the bottom edge. A
            // column cannot express that inside a shrink-wrapping parent —
            // a `Spacer` there needs a height nobody has — so the two
            // groups are positioned instead.
            PositionedDirectional(top: 20, start: 20, child: _tag(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 65, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // `max-width: 84%` — the drawing lives in the other 16.
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 0.84,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          LumeType.tracked(
                            LumeType.fit(context, context.lumeType.title),
                            -0.036,
                          ).copyWith(
                            color: _onArt,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 0.82,
                    child: Text(
                      text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.lumeType.meta.copyWith(
                        color: _onArt.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w500,
                        height: LumeType.lineHeight(context, 1.45),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      for (int i = 0; i < meta.length; i++) ...<Widget>[
                        if (i > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _onArt.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            meta[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                LumeType.natural(
                                  context,
                                  context.lumeType.metaSmall,
                                  size: 11,
                                ).copyWith(
                                  color: _onArt.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// `.feature__tag` — a frosted pill that hugs its words.
  Widget _tag(BuildContext context) => Container(
    height: 25,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: _onArt.withValues(alpha: 0.18),
      borderRadius: LumeRadius.full,
      border: Border.all(
        color: _onArt.withValues(alpha: 0.24),
        width: LumeSpace.border,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const LumeIcon(LumeIcons.sparkles, size: 12, color: _onArt),
        const SizedBox(width: 5),
        Text(
          tag,
          style: LumeType.tracked(
            LumeType.natural(context, context.lumeType.tab, size: 10),
            0.01,
          ).copyWith(color: _onArt, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

/// Everything on the featured card is white on a gradient.
const Color _onArt = Colors.white;

/// `.weather` — the reading, in the reader's own units.
class LumeWeatherCard extends StatelessWidget {
  const LumeWeatherCard({
    super.key,
    required this.icon,
    required this.temperature,
    required this.degreeSign,
    required this.description,
    required this.stats,
  });

  final String icon;

  /// The figure alone — the degree sign is set smaller and raised.
  final String temperature;
  final String degreeSign;

  /// "Hazy sun · humid · 38°", already composed from the condition and the
  /// feels-like, both of which are the reader's.
  final String description;

  /// Rain, wind, sunset.
  final List<LumeWeatherStat> stats;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.sm,
        // `linear-gradient(135deg, color-mix(sky 16%, card), card 70%)`
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color.lerp(lume.card, lume.sky, 0.16)!, lume.card],
          stops: const <double>[0, 0.7],
        ),
      ),
      child: Row(
        children: <Widget>[
          LumeIcon(icon, size: 40, color: lume.sky),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LumeNumerals.rich(
                  children: <InlineSpan>[
                    TextSpan(text: temperature),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: Text(
                        degreeSign,
                        style: context.lumeType.meta.copyWith(
                          color: lume.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  style:
                      LumeType.tracked(
                        LumeType.fit(context, context.lumeType.display),
                        -0.05,
                      ).copyWith(
                        color: lume.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.lumeType.meta.copyWith(
                    color: lume.text2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < stats.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 6),
                Semantics(
                  label: stats[i].semanticLabel,
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      LumeIcon(stats[i].icon, size: 12, color: lume.text3),
                      const SizedBox(width: 5),
                      LumeNumerals(
                        stats[i].value,
                        maxLines: 1,
                        style:
                            LumeType.natural(
                              context,
                              context.lumeType.metaSmall,
                              size: 11,
                            ).copyWith(
                              color: lume.text2,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
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

/// One of the weather card's three figures.
@immutable
class LumeWeatherStat {
  const LumeWeatherStat({
    required this.icon,
    required this.value,
    required this.semanticLabel,
  });

  final String icon;
  final String value;

  /// A glyph and a number say nothing out loud. "Rain 8 per cent" does.
  final String semanticLabel;
}

/// `.list-row` — an icon, two lines, a value and a chevron.
class LumeListRow extends StatelessWidget {
  const LumeListRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.value,
    this.titleTrailing,
    this.end,
    this.semanticLabel,
    this.onTap,
    this.isLast = false,
  });

  final String icon;
  final String title;
  final String subtitle;

  /// The figure at the end. `null` for a row that has none.
  final String? value;

  /// Set inside the title, after the words — Trains' `.trainno` chip. The
  /// title shrinks to make room rather than the chip wrapping.
  final Widget? titleTrailing;

  /// Replaces the value and the chevron together. A row whose end is a status
  /// pill does not also lead anywhere by chevron, and the reference draws
  /// neither beside the other.
  final Widget? end;

  /// Overrides what a screen reader hears. The default is the title, the
  /// subtitle and the value; a row with an [end] has to say what that says.
  final String? semanticLabel;

  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel:
          semanticLabel ?? <String>[title, subtitle, ?value].join(', '),
      minSize: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: lume.border,
                    width: LumeSpace.border,
                  ),
                ),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: lume.tintNeutral,
                  borderRadius: LumeRadius.brIcon,
                ),
                alignment: Alignment.center,
                child: LumeIcon(icon, size: 17, color: lume.text2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                LumeType.tracked(
                                  LumeType.natural(
                                    context,
                                    context.lumeType.meta,
                                    size: 14,
                                  ),
                                  -0.022,
                                ).copyWith(
                                  color: lume.text,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (titleTrailing != null) ...<Widget>[
                          const SizedBox(width: 6),
                          titleTrailing!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 2,
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
              const SizedBox(width: 8),
              if (end != null)
                end!
              else ...<Widget>[
                if (value != null) ...<Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: LumeNumerals(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          LumeType.tracked(
                            LumeType.natural(
                              context,
                              context.lumeType.meta,
                              size: 13,
                            ),
                            -0.02,
                          ).copyWith(
                            color: lume.text2,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                LumeIcon(LumeIcons.chevR, size: 16, color: lume.text3),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.article` — a story: artwork, a category, a headline, a reading time.
class LumeArticleRow extends StatelessWidget {
  const LumeArticleRow({
    super.key,
    required this.category,
    required this.title,
    required this.meta,
    required this.art,
    this.onTap,
    this.isLast = false,
  });

  final String category;
  final String title;
  final String meta;
  final Widget art;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel: '$category. $title. $meta',
      minSize: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: lume.border,
                    width: LumeSpace.border,
                  ),
                ),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: LumeRadius.brIcon,
                child: SizedBox(width: 62, height: 62, child: art),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      LumeType.overline(context, category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          LumeType.tracked(
                            LumeType.natural(
                              context,
                              context.lumeType.tab,
                              size: 10,
                            ),
                            0.06,
                          ).copyWith(
                            color: lume.accent,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          LumeType.tracked(
                            LumeType.natural(
                              context,
                              context.lumeType.meta,
                              size: 13,
                            ),
                            -0.025,
                          ).copyWith(
                            color: lume.text,
                            fontWeight: FontWeight.w700,
                            height: LumeType.lineHeight(context, 1.32),
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meta,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// `.score` — two sides and a note, in a three-column grid.
class LumeScoreCard extends StatelessWidget {
  const LumeScoreCard({
    super.key,
    required this.homeTeam,
    required this.homeRuns,
    required this.homeWickets,
    required this.homeOvers,
    required this.awayTeam,
    required this.awayRuns,
    required this.awayOvers,
    required this.note,
    required this.versus,
    this.onTap,
  });

  final String homeTeam;
  final String homeRuns;

  /// "/4", drawn smaller. `null` for a side that is all out.
  final String? homeWickets;

  final String homeOvers;
  final String awayTeam;
  final String awayRuns;
  final String awayOvers;

  /// "Pakistan trail by 87 runs · Babar 78*".
  final String note;

  /// "vs".
  final String versus;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumePressable(
      onTap: onTap,
      semanticLabel:
          '$homeTeam $homeRuns${homeWickets ?? ''} $homeOvers, '
          '$versus $awayTeam $awayRuns $awayOvers. $note',
      borderRadius: LumeRadius.brLg,
      minSize: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: _Side(
                      team: homeTeam,
                      runs: homeRuns,
                      wickets: homeWickets,
                      overs: homeOvers,
                      alignEnd: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    versus,
                    style: LumeType.natural(
                      context,
                      context.lumeType.tab,
                      size: 10,
                    ).copyWith(color: lume.text3, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Side(
                      team: awayTeam,
                      runs: awayRuns,
                      wickets: null,
                      overs: awayOvers,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              // `.score__note { padding-top: 11px; margin-top: 3px;
              //  border-top: 1px solid var(--border) }`
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.only(top: 11),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: lume.border,
                      width: LumeSpace.border,
                    ),
                  ),
                ),
                child: Text(
                  note,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                    size: 11,
                  ).copyWith(color: lume.text2, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.team,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.alignEnd,
  });

  final String team;
  final String runs;
  final String? wickets;
  final String overs;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          LumeType.overline(context, team),
          style: LumeType.tracked(
            LumeType.natural(context, context.lumeType.tab, size: 10),
            0.06,
          ).copyWith(color: lume.text3, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        LumeNumerals.rich(
          children: <InlineSpan>[
            TextSpan(text: runs),
            if (wickets != null)
              TextSpan(
                text: wickets,
                style: context.lumeType.meta.copyWith(
                  color: lume.text3,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
          style:
              LumeType.tracked(
                LumeType.fit(context, context.lumeType.display),
                -0.05,
              ).copyWith(
                color: lume.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
        ),
        const SizedBox(height: 3),
        LumeNumerals(
          overs,
          style: LumeType.natural(
            context,
            context.lumeType.tab,
            size: 10,
          ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
