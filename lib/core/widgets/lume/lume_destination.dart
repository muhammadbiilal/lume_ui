/// The furniture every primary destination is built from.
///
/// Home, the Tools hub, Today, Explore, Trains and Profile share a page shape,
/// and the reference puts it in `base.css` and `screens/shared.css` rather than
/// in any one screen. This is that, measured:
///
/// | | measured |
/// |---|---|
/// | `.screen` | fills, scrolls, `padding-bottom: 118` for the floating bar |
/// | `.appbar` | 59 tall, `10 20 4`, greeting 20/800/−0.032em |
/// | `.page-head` | `12 20 0`, title 28/800/−0.038em, sub 13/500 |
/// | `.section` | `margin-top: 24`, children carry the 20 px gutters |
/// | `.section__head` | baseline-aligned, `margin-bottom: 13` |
/// | `.section__title` | 17/700/−0.028em |
/// | `.section__sub` | 12/500, muted |
/// | `.section__link` | 12/700 accent, `4 2` padding, 13 px chevron |
/// | `.hscroll` | 12 px gaps, `2 20 6`, snaps to the gutter |
/// | `.iconbtn` | 38 × 38, 12 px radius, card fill, 18 px glyph |
/// | `.avatar` | 38 × 38, round, jade gradient, 13/700 initials |
///
/// **This is not `LumeSection`.** That one is `.sect`, the *tool* screen's
/// section: 15 px title, 11 px subtitle, `flex-end` alignment, its own
/// gutters. A destination's `.section` is a different component with a
/// different scale, and the two were measured side by side rather than assumed
/// to be one thing.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../layout/lume_breakpoint.dart';
import '../../layout/lume_measure.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// The measured constants, in one place so a screen never holds a number.
abstract final class LumeDestinationMetrics {
  /// `.screen { padding-bottom: 118px }` — clearance for the floating bar,
  /// which is 62 tall and sits 12 up from the bottom.
  static const double bottomClearanceCompact = 118;

  /// `:root[data-bp="medium"] .screen { padding-bottom: 40px }` — no floating
  /// bar to clear once navigation is a rail.
  static const double bottomClearanceWide = 40;

  /// `.appbar { padding: 10px var(--pad) 4px }`.
  static const EdgeInsets appBarPadding = EdgeInsets.fromLTRB(0, 10, 0, 4);

  /// `.page-head { padding: 12px var(--pad) 0 }`.
  static const EdgeInsets pageHeadPadding = EdgeInsets.fromLTRB(0, 12, 0, 0);

  /// `.section { margin-top: var(--gap-section) }`.
  static const double sectionGap = LumeSpace.gapSection;

  /// `.section__head { margin-bottom: 13px }`. Thirteen, not twelve — that is
  /// `.sect__head`, and the two are a pixel apart on purpose.
  static const double sectionHeadGap = 13;

  /// `.iconbtn`, `.avatar` — both 38.
  static const double actionSize = 38;

  /// `.hscroll { gap: 12px; padding: 2px var(--pad) 6px }`.
  static const double stripGap = 12;
  static const EdgeInsets stripPadding = EdgeInsets.fromLTRB(0, 2, 0, 6);

  /// `.qactions { gap: 8px; padding: 0 var(--pad) 2px;
  /// margin: 0 calc(var(--pad) * -1) }` — the margin cancels the padding, so
  /// the first pill starts at the section's own edge rather than one gutter
  /// in. See [LumeHorizontalStrip].
  static const double actionStripGap = 8;

  /// `.chips { gap: 7px; padding: 0 var(--pad) 2px }`.
  static const double chipStripGap = 7;

  /// Bottom clearance for a shell this wide.
  static double bottomClearance(LumeWidthClass c) => c == LumeWidthClass.compact
      ? bottomClearanceCompact
      : bottomClearanceWide;
}

/// A primary destination's page.
///
/// Scrolls as one column, keeps its offset through a [PageStorageKey], applies
/// the product's measure, and leaves the floating navigation bar its clearance.
/// The slivers are handed in rather than built here, because every destination
/// composes a different set and this only owns what they share.
class LumeDestinationPage extends StatelessWidget {
  const LumeDestinationPage({
    super.key,
    required this.storageId,
    required this.slivers,
    this.onRefresh,
    this.semanticLabel,
    this.controller,
  });

  /// Distinguishes this page's scroll offset from every other one's.
  final String storageId;

  final List<Widget> slivers;

  /// Pull to refresh. `null` where the destination has nothing to re-fetch.
  final Future<void> Function()? onRefresh;

  /// What a screen reader calls the page.
  final String? semanticLabel;

  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final double clearance = LumeDestinationMetrics.bottomClearance(
      context.widthClass,
    );

    final Widget view = CustomScrollView(
      key: PageStorageKey<String>('destination:$storageId'),
      controller: controller,
      primary: false,
      slivers: <Widget>[
        ...slivers,
        SliverToBoxAdapter(
          child: SizedBox(
            height: clearance + MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );

    final Widget scroller = onRefresh == null
        ? view
        : RefreshIndicator(
            onRefresh: onRefresh!,
            edgeOffset: MediaQuery.paddingOf(context).top,
            child: view,
          );

    // A destination is the root of its subtree, and `Text` has no default
    // style above a `Material` — every line would render in the debug face
    // with a yellow underline. The same trap as the authentication scaffold's.
    final Widget body = Material(color: context.lume.bg, child: scroller);

    if (semanticLabel == null) return body;
    return Semantics(container: true, label: semanticLabel, child: body);
  }
}

/// `.appbar` — the greeting header Home wears.
///
/// Two lines of identity on the left, up to three 38-point controls on the
/// right. Measured 59 tall at the reference cell, which is `10 + 45 + 4`.
class LumeGreetingBar extends StatelessWidget {
  const LumeGreetingBar({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.place,
    this.actions = const <Widget>[],
    this.emoji,
  });

  /// "Good afternoon". The emoji is a separate field so it is not read out.
  final String greeting;

  /// The date.
  final String subtitle;

  /// The city, shown after a dot and a pin. `null` leaves the line as the date
  /// alone rather than drawing an empty pin.
  final String? place;

  final List<Widget> actions;

  /// `👋`. Decorative, and excluded from semantics.
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumeMeasure(
      child: Padding(
        padding: LumeDestinationMetrics.appBarPadding,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          greeting,
                          style:
                              LumeType.tracked(
                                LumeType.fit(context, context.lumeType.title),
                                -0.032,
                              ).copyWith(
                                color: lume.text,
                                fontWeight: FontWeight.w800,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (emoji != null) ...<Widget>[
                        const SizedBox(width: 6),
                        ExcludeSemantics(
                          child: Text(
                            emoji!,
                            style: LumeType.fit(
                              context,
                              context.lumeType.title,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  DefaultTextStyle(
                    style: LumeType.natural(
                      context,
                      context.lumeType.meta,
                    ).copyWith(color: lume.text3, fontWeight: FontWeight.w500),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: LumeNumerals(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (place != null) ...<Widget>[
                          const SizedBox(width: 6),
                          // `.appbar__sub .dot` — 3 px, half-opacity.
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lume.text3.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          LumeIcon(LumeIcons.pin, size: 12, color: lume.text3),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              place!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < actions.length; i++) ...<Widget>[
              // `.appbar { gap: 12px }`, and
              // `.appbar .iconbtn + .iconbtn { margin-left: -2px }` — so two
              // icon buttons sit 10 apart and the avatar keeps its 12.
              SizedBox(
                width:
                    i > 0 &&
                        actions[i] is LumeHeaderButton &&
                        actions[i - 1] is LumeHeaderButton
                    ? LumeSpace.x3 - 2
                    : LumeSpace.x3,
              ),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// `.page-head` — the title block the other destinations wear.
class LumePageHead extends StatelessWidget {
  const LumePageHead({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.leading,
  });

  final String title;
  final String? subtitle;

  /// A single 38-point control at the trailing edge.
  final Widget? action;

  /// A single 38-point control at the leading edge.
  ///
  /// `.page-head__bar` is a three-part row and only Explore fills the first
  /// part: it is reachable in a market where it is not a tab, so it carries
  /// its own way back. Every other destination leaves this `null` and the row
  /// is the two-part one it has always been.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return LumeMeasure(
      child: Padding(
        padding: LumeDestinationMetrics.pageHeadPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: LumeSpace.x3),
            ],
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
                        LumeType.natural(context, context.lumeType.display),
                        -0.038,
                      ).copyWith(color: lume.text),
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: LumeNumerals(
                        subtitle!,
                        // `.page-head__sub { font-size: 13px }` and no line
                        // height, so the line is the font's own — 16, not the
                        // reading height a role carries.
                        style:
                            LumeType.natural(
                              context,
                              context.lumeType.meta,
                              size: 13,
                            ).copyWith(
                              color: lume.text3,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(width: LumeSpace.x3),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// `.section` — a block of a destination, with its heading.
///
/// The gutters are **not** applied to the block: `.section` has none, and its
/// children carry `padding: 0 var(--pad)` individually. That is what lets a
/// horizontal strip bleed to the edge while the heading above it lines up with
/// the rest of the page, and reproducing it any other way loses the bleed.
class LumePageSection extends StatelessWidget {
  const LumePageSection({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.link,
    this.onLinkTap,
    this.linkIcon = LumeIcons.chevR,
    this.trailing,
    this.topGap = LumeDestinationMetrics.sectionGap,
    this.headingLevel = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  /// The "See all" affordance.
  final String? link;
  final VoidCallback? onLinkTap;

  /// `.section__link svg` — a chevron by default, a refresh glyph where the
  /// action re-fetches rather than navigates.
  final String linkIcon;

  /// Something other than a link at the end of the head — Explore's market
  /// tag is one. Ignored when [link] is given; a head carries one or the
  /// other, as every head in the reference does.
  final Widget? trailing;

  /// `.section { margin-top: 24 }`, overridden inline on three sections.
  final double topGap;

  /// Whether the title is a heading for a screen reader. False for a section
  /// whose title repeats one above it.
  final bool headingLevel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: topGap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (title != null)
          LumeMeasure(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: LumeDestinationMetrics.sectionHeadGap,
              ),
              child: LumeSectionHeading(
                title: title!,
                subtitle: subtitle,
                link: link,
                onLinkTap: onLinkTap,
                linkIcon: linkIcon,
                trailing: trailing,
                headingLevel: headingLevel,
              ),
            ),
          ),
        child,
      ],
    ),
  );
}

/// `.section__head` — title, optional subtitle, optional trailing action.
///
/// Baseline-aligned, which is why the link sits 2 points below the title's top
/// rather than flush with it.
class LumeSectionHeading extends StatelessWidget {
  const LumeSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.link,
    this.onLinkTap,
    this.linkIcon = LumeIcons.chevR,
    this.trailing,
    this.headingLevel = true,
  });

  final String title;
  final String? subtitle;
  final String? link;
  final VoidCallback? onLinkTap;
  final String linkIcon;

  /// Something other than a link at the end of the head. A head carries one
  /// or the other, as every head in the reference does.
  final Widget? trailing;

  final bool headingLevel;

  /// `.section__title` — 17/700/−0.028em.
  static TextStyle titleStyle(BuildContext context) => LumeType.tracked(
    LumeType.natural(context, context.lumeType.section),
    -0.028,
  ).copyWith(color: context.lume.text);

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: headingLevel,
                child: Text(
                  title,
                  style: titleStyle(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: LumeNumerals(
                    subtitle!,
                    style: LumeType.natural(
                      context,
                      context.lumeType.meta,
                    ).copyWith(color: lume.text3, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        if (link == null && trailing != null) ...<Widget>[
          const SizedBox(width: LumeSpace.x3),
          trailing!,
        ],
        if (link != null) ...<Widget>[
          const SizedBox(width: LumeSpace.x3),
          // `.section__link { padding: 4px 2px }` — a 12/700 accent label and
          // a 13 px chevron that points the way the language reads.
          LumePressable(
            onTap: onLinkTap,
            semanticLabel: link,
            borderRadius: LumeRadius.brXs,
            // `.section__link` is 23 tall. Padding it to §9's 44 would add five
            // points to every section head and push the whole page down;
            // the link is a shortcut to a destination the tab bar already
            // carries at full size. Recorded in `docs/LUME_DESTINATIONS.md`.
            minSize: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (linkIcon == LumeIcons.refresh) ...<Widget>[
                    LumeIcon(linkIcon, size: 13, color: lume.accent),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    link!,
                    style: LumeType.fit(
                      context,
                      context.lumeType.label,
                    ).copyWith(color: lume.accent),
                  ),
                  if (linkIcon != LumeIcons.refresh) ...<Widget>[
                    const SizedBox(width: 2),
                    LumeIcon(linkIcon, size: 13, color: lume.accent),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// `.hscroll`, `.qactions`, `.chips` — a row that scrolls sideways and bleeds
/// into the page gutters.
///
/// One widget for all three because they differ only in their gap, their
/// bottom padding and whether they bleed, and giving each its own would
/// guarantee they drift apart.
///
/// Two geometries, both measured:
///
/// | | port | first item |
/// |---|---|---|
/// | `.hscroll`, `.chips` | the section's box | one gutter in |
/// | `.qactions` | one gutter wider, each side | the section's own edge |
///
/// `.qactions` adds `margin: 0 calc(var(--pad) * -1)` to the padding the other
/// two share, which cancels its own gutter: the first pill sits against the
/// page edge and a scrolled pill passes out through the margin rather than
/// stopping at it. At 390 the reference measures the strip at x −20 by 430 and
/// its first pill at x 0, where a chip starts at 20; at 1100 it measures
/// x 237 by 870 against a section of 269 by 806. It is a full-bleed strip, and
/// it is deliberate.
class LumeHorizontalStrip extends StatelessWidget {
  const LumeHorizontalStrip({
    super.key,
    required this.children,
    this.gap = LumeDestinationMetrics.stripGap,
    this.padding = LumeDestinationMetrics.stripPadding,
    this.bleed = false,
    this.semanticLabel,
    this.controller,
  });

  /// `.qactions` — 8 px gaps, 2 px of bottom padding, full bleed.
  const LumeHorizontalStrip.actions({
    super.key,
    required this.children,
    this.semanticLabel,
    this.controller,
  }) : gap = LumeDestinationMetrics.actionStripGap,
       padding = const EdgeInsets.only(bottom: 2),
       bleed = true;

  /// `.chips` — 7 px gaps, 2 px of bottom padding.
  const LumeHorizontalStrip.chips({
    super.key,
    required this.children,
    this.semanticLabel,
    this.controller,
  }) : gap = LumeDestinationMetrics.chipStripGap,
       padding = const EdgeInsets.only(bottom: 2),
       bleed = false;

  final List<Widget> children;
  final double gap;
  final EdgeInsets padding;

  /// Whether the strip cancels its own gutter, as `.qactions` does.
  final bool bleed;

  final String? semanticLabel;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final LumeWidthClass measure = context.measureClass;
    final double gutter = LumeLayout.pageGutter(measure);

    final Widget strip = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        // The strip supplies its own gutters, so it is not inside a
        // `LumeMeasure` — but it still belongs to the measure, and the
        // reference caps it with every other section. Without this the first
        // item lands at the window's edge instead of the content column's.
        final double section = measure == LumeWidthClass.compact
            ? c.maxWidth
            : math.min(c.maxWidth, LumeLayout.contentCap(measure));

        // The negative margin, in the only form that cannot scroll the page
        // sideways: the port grows into the room beside the section, and no
        // further. At a phone width there is none, and the page edge clips
        // exactly what the reference's overflow does.
        final double spill = bleed
            ? math.min(gutter, math.max(0, (c.maxWidth - section) / 2))
            : 0;
        final double inset = bleed ? spill : gutter;

        return SizedBox(
          width: section + spill * 2,
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsetsDirectional.only(start: inset, end: inset),
            // `align-items` is `stretch` on all three flexes, so a card that
            // takes two lines raises every card beside it rather than leaving
            // a ragged row of different heights. A Row centres by default,
            // and a horizontal scroller has no height to stretch into until
            // the tallest child has named one.
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < children.length; i++) ...<Widget>[
                    if (i > 0) SizedBox(width: gap),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    final Widget padded = Padding(
      padding: padding,
      child: Center(child: strip),
    );
    if (semanticLabel == null) return padded;
    return Semantics(container: true, label: semanticLabel, child: padded);
  }
}

/// `.iconbtn` — a 38-point control in the header.
///
/// Carries a count when it has one. §100.1 asks for *"one badge, in the app
/// header, formatted compactly"*, and `renderNotifBadge` computes exactly that
/// (`n > 99 ? '99+' : n`) — then writes it into `.iconbtn__badge`, which is a
/// 7 × 7 disc with `overflow: visible` and no room for a glyph. The digits
/// render outside the disc, in the button's own inherited text, across the
/// bell: the reference's header reads "13" in near-black over the icon (C16).
/// Repaired here, and the repair is the only change — the marker keeps the
/// reference's centre, its accent fill and its two-point card ring, and
/// becomes the smallest pill the number fits in.
///
/// A count that cannot fit without swallowing the control — which is what a
/// large text scale does to a 38-point button — falls back to the reference's
/// plain dot. Nothing is lost: the count is in the control's accessible name
/// either way, which is where a screen reader was reading it from already.
class LumeHeaderButton extends StatelessWidget {
  const LumeHeaderButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.badgeCount,
    this.showDot = false,
  });

  final String icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  /// `null` or zero draws nothing.
  final int? badgeCount;

  /// An unread marker with no number.
  final bool showDot;

  static String formatCount(int n) => n > 99 ? '99+' : '$n';

  /// `.iconbtn__badge { top: 7px; right: 8px; width: 7px; height: 7px }` —
  /// the disc's centre is 10.5 down and 11.5 in from the trailing edge. A
  /// pill keeps that centre and grows around it.
  static const Offset badgeCentre = Offset(11.5, 10.5);

  /// `.iconbtn__badge` — the marker with no number in it.
  static const double dotSize = 7;

  /// `box-shadow: 0 0 0 2px var(--card)` — outside the shape, as the
  /// reference's is, so the ring never eats into the fill.
  static const double badgeRing = 2;

  static const double badgeFontSize = 9;

  /// The smallest the pill goes. The reference's marker is round, and a
  /// one-digit count keeps it round rather than shrinking to the glyph.
  static const double badgeMinSize = 14;

  /// How far past the control's edge the badge may sit before the number is
  /// dropped for the dot. `.appbar .iconbtn + .iconbtn` leaves 10 points
  /// between the header's controls; four keeps the badge clear of its
  /// neighbour, and clear of the bar's own 13.5 above the row.
  static const double badgeOverhang = 4;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final int count = badgeCount ?? 0;
    final bool hasBadge = count > 0 || showDot;

    return LumePressable(
      onTap: onTap,
      semanticLabel: count > 0 ? '$semanticLabel, $count' : semanticLabel,
      borderRadius: LumeRadius.brSm,
      // 38, not the 44 §9 asks for. The header's three controls are 38 with 12
      // between them, so the *reachable* area is 50 wide and the bar around
      // them is 59 tall; padding each to 44 would push the avatar off the
      // 359-point phone. Recorded in `docs/LUME_DESTINATIONS.md`.
      minSize: 0,
      child: SizedBox(
        width: LumeDestinationMetrics.actionSize,
        height: LumeDestinationMetrics.actionSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: lume.card,
                borderRadius: LumeRadius.brSm,
                border: Border.all(color: lume.border, width: LumeSpace.border),
                boxShadow: context.lumeShadows.xs,
              ),
              child: Center(child: LumeIcon(icon, size: 18, color: lume.text2)),
            ),
            if (hasBadge) _HeaderBadge(count: count),
          ],
        ),
      ),
    );
  }
}

/// `.iconbtn__badge` — the unread marker, with or without its number.
///
/// Measures the number before drawing it, so the pill is the smallest one the
/// text fits in and the decision to fall back to a dot is made on the width
/// the text actually takes rather than on a guess about the text scale.
class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    const Offset centre = LumeHeaderButton.badgeCentre;
    const double ring = LumeHeaderButton.badgeRing;

    Widget shape(double w, double h, {Widget? child}) => PositionedDirectional(
      top: centre.dy - h / 2,
      end: centre.dx - w / 2,
      // The count is already in the control's own name; read out again here
      // it would be announced twice.
      child: ExcludeSemantics(
        child: Container(
          width: w,
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: lume.accent,
            borderRadius: BorderRadius.circular(999),
            // The reference's ring is a spread shadow, so it sits outside the
            // shape. A border would sit inside it and eat into the fill.
            boxShadow: <BoxShadow>[
              BoxShadow(color: lume.card, spreadRadius: ring),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (count <= 0) {
      return shape(LumeHeaderButton.dotSize, LumeHeaderButton.dotSize);
    }

    final String text = LumeHeaderButton.formatCount(count);
    final TextStyle style = LumeType.numeric(
      LumeType.fit(context, context.lumeType.tab),
    ).copyWith(color: lume.onAccent, fontSize: LumeHeaderButton.badgeFontSize);

    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final double textWidth = painter.width;
    final double textHeight = painter.height;
    painter.dispose();

    // Four points each side of the digits, one above and below the line box,
    // and never smaller or narrower than the marker itself — one digit stays
    // a disc, two become a pill.
    final double height = math.max(
      LumeHeaderButton.badgeMinSize,
      textHeight + 2,
    );
    final double width = math.max(textWidth + 8, height);

    // The badge grows around a fixed centre, so what runs out is the room
    // between that centre and the control's edge. Past it the pill stops
    // being a badge on the control and becomes a lid over it.
    const Offset anchor = LumeHeaderButton.badgeCentre;
    const double allowed = LumeHeaderButton.badgeOverhang;
    if (width / 2 + ring - anchor.dx > allowed ||
        height / 2 + ring - anchor.dy > allowed) {
      return shape(LumeHeaderButton.dotSize, LumeHeaderButton.dotSize);
    }

    return shape(
      width,
      height,
      child: LumeNumerals(text, style: style, maxLines: 1),
    );
  }
}

/// `.avatar` — the profile control.
///
/// Initials when Lume has a name, the neutral glyph when it does not. Never
/// invented letters (`.avatar--anon`).
class LumeAvatarButton extends StatelessWidget {
  const LumeAvatarButton({
    super.key,
    required this.initials,
    required this.semanticLabel,
    this.onTap,
    this.size = LumeDestinationMetrics.actionSize,
  });

  final String initials;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool anonymous = initials.isEmpty;

    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      borderRadius: BorderRadius.circular(999),
      // See [LumeHeaderButton]: the header's controls are 38 by design.
      minSize: 0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: anonymous
              ? null
              : LinearGradient(
                  begin: const Alignment(-0.7, -1),
                  end: const Alignment(0.7, 1),
                  colors: <Color>[lume.accent400, lume.accent600],
                ),
          color: anonymous ? lume.card : null,
          border: anonymous
              ? Border.all(color: lume.border, width: LumeSpace.border)
              : null,
          boxShadow: context.lumeShadows.sm,
        ),
        alignment: Alignment.center,
        child: anonymous
            ? LumeIcon(LumeIcons.user, size: 18, color: lume.text2)
            : Text(
                initials,
                style:
                    LumeType.tracked(
                      LumeType.fit(context, context.lumeType.meta),
                      -0.02,
                    ).copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
              ),
      ),
    );
  }
}

/// A CSS grid of equal-width tiles, in rows that size to their tallest member.
///
/// `GridView` cannot do this: it takes one aspect ratio for every cell, so the
/// row whose label wraps to two lines overflows and every other row is padded
/// to match it. A CSS grid's default `align-items: stretch` makes each *row*
/// as tall as its own tallest cell and leaves the next row alone, which is why
/// "Date Calculator" is allowed to be taller than "Calculator" beside it
/// without making the row below it taller too.
///
/// Rows of [IntrinsicHeight] with [Expanded] children is that, exactly.
class LumeTileGrid extends StatelessWidget {
  const LumeTileGrid({
    super.key,
    required this.children,
    required this.columns,
    this.spacing = 10,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i += columns) {
      final List<Widget> row = children.skip(i).take(columns).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : spacing),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int c = 0; c < columns; c++) ...<Widget>[
                  if (c > 0) SizedBox(width: spacing),
                  // The last row is short; its empty cells still hold their
                  // column so the tiles above them stay aligned.
                  Expanded(
                    child: c < row.length ? row[c] : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}
