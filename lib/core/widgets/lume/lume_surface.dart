/// Surfaces: the card, the section, its header, and the note card.
///
/// Measured from the rendered prototype, not read out of the stylesheet —
/// `.kard` is 20 px radius rather than the 16 px `--r-md` a quick read
/// suggests, because it takes `--r-lg`, and `.notecard` sits on `card-2`
/// rather than `card`. Both are the kind of thing a transcription gets wrong
/// and a measurement does not.
library;

import 'package:flutter/material.dart';

import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import 'lume_pressable.dart';

/// The standard card — `.kard`.
///
/// Measured: `card` fill, 1 px `border`, 20 px radius, `shadow-sm`, 16 px of
/// padding when padded.
class LumeCard extends StatelessWidget {
  const LumeCard({
    super.key,
    required this.child,
    this.padded = true,
    this.onTap,
    this.semanticLabel,
    this.tone,
    this.shadow = true,
    this.clip = false,
  });

  final Widget child;

  /// `.kard--pad` — on by default, as the builder has it.
  final bool padded;

  final VoidCallback? onTap;
  final String? semanticLabel;

  /// A tinted variant. `null` is the plain white card.
  final Color? tone;

  /// `.list--flat { box-shadow: none }` — the same surface without its lift.
  /// Global search's recents and results sit inside a sheet that already
  /// casts the shadow, and a second one under the list would be a card
  /// floating over a card.
  final bool shadow;

  /// `overflow: hidden` — for a card whose rows paint their own ground, like
  /// the notification list's unread tint, which would otherwise square off
  /// the card's rounded corners. Clipped inside the border, so the hairline
  /// stays the card's.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: tone ?? lume.card,
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: shadow ? context.lumeShadows.sm : null,
      ),
      child: Padding(
        // The border is part of the box: a `.kard` with a 1-point border and
        // six 61-point rows measures 367, not 365. `DecoratedBox` paints the
        // border without reserving room for it, so the inset is added here.
        padding:
            (padded ? const EdgeInsets.all(LumeSpace.padCard) : EdgeInsets.zero)
                .add(const EdgeInsets.all(LumeSpace.border)),
        child: clip
            ? ClipRRect(
                borderRadius:
                    LumeRadius.brLg -
                    const BorderRadius.all(Radius.circular(LumeSpace.border)),
                child: child,
              )
            : child,
      ),
    );

    if (onTap == null) return surface;
    return LumePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      borderRadius: LumeRadius.brLg,
      minSize: 0,
      child: surface,
    );
  }
}

/// A page section — `.sect`.
///
/// Measured: 20 px horizontal page padding, no background of its own. The
/// heading is `.sect__title` at 15/700 with −0.028em tracking, which is *not*
/// the `section` type role; the reference sets it per call site.
class LumeSection extends StatelessWidget {
  const LumeSection({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.link,
    this.onLinkTap,
    this.gutters = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  /// The trailing "See all" affordance — `.sect__link`.
  final String? link;
  final VoidCallback? onLinkTap;

  /// False where an ancestor already applied the page padding.
  final bool gutters;

  @override
  Widget build(BuildContext context) {
    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (title != null)
          LumeSectionHeader(
            title: title!,
            subtitle: subtitle,
            link: link,
            onLinkTap: onLinkTap,
          ),
        child,
      ],
    );

    if (!gutters) return body;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: LumeSpace.pageCompact,
      ),
      child: body,
    );
  }
}

/// `.sect__head` — title, optional subtitle, optional trailing link.
class LumeSectionHeader extends StatelessWidget {
  const LumeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.link,
    this.onLinkTap,
  });

  final String title;
  final String? subtitle;
  final String? link;
  final VoidCallback? onLinkTap;

  /// Measured: 15 px / 700 / −0.028em.
  static TextStyle titleStyle(BuildContext context) => LumeType.tracked(
    LumeType.fit(context, context.lumeType.cardTitle),
    -0.028,
  ).copyWith(color: context.lume.text);

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Padding(
      padding: const EdgeInsets.only(bottom: LumeSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: titleStyle(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: LumeType.fit(
                      context,
                      context.lumeType.metaSmall,
                    ).copyWith(color: lume.text3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (link != null) ...<Widget>[
            const SizedBox(width: LumeSpace.x2),
            LumePressable(
              onTap: onLinkTap,
              borderRadius: LumeRadius.brXs,
              minSize: LumeSpace.tap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    link!,
                    // Measured: 12 px / 700, accent ink.
                    style: LumeType.fit(
                      context,
                      context.lumeType.label,
                    ).copyWith(color: lume.accent),
                  ),
                  const SizedBox(width: 3),
                  LumeIcon(
                    LumeIcons.chevR,
                    size: LumeSpace.iconSm,
                    color: lume.accent,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The tone of a note card, and of the notices that share its shape.
enum LumeNoteTone { info, warn, danger, success }

/// `.notecard` — an inline aside.
///
/// Measured: `card-2` fill, 1 px `border`, 12 px radius, 14 px padding,
/// 11 px gap. Not a card; a quieter surface that sits inside one.
class LumeNoteCard extends StatelessWidget {
  const LumeNoteCard({
    super.key,
    required this.title,
    this.text,
    this.tone = LumeNoteTone.info,
    this.icon,
  });

  final String title;
  final String? text;
  final LumeNoteTone tone;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final (Color bg, Color border, Color glyph) = switch (tone) {
      LumeNoteTone.info => (lume.card2, lume.border, lume.text3),
      LumeNoteTone.warn => (
        Color.lerp(lume.card, lume.amber, 0.10)!,
        lume.amber.withValues(alpha: 0.30),
        lume.amberInk,
      ),
      LumeNoteTone.danger => (
        Color.lerp(lume.card, lume.rose, 0.08)!,
        lume.rose.withValues(alpha: 0.26),
        lume.roseInk,
      ),
      LumeNoteTone.success => (
        Color.lerp(lume.card, lume.accent, 0.08)!,
        lume.accent.withValues(alpha: 0.26),
        lume.accent700,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: LumeRadius.brIcon,
        border: Border.all(color: border, width: LumeSpace.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // `.notecard svg { width: 17px; margin-top: 1px }`.
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: LumeIcon(icon ?? _defaultIcon, size: 17, color: glyph),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // `.notecard b` — 13 / 700 / −.024em on the font's own line.
                Text(
                  title,
                  style: LumeType.tracked(
                    LumeType.natural(context, context.lumeType.body, size: 13),
                    -0.024,
                  ).copyWith(fontWeight: FontWeight.w700, color: lume.text),
                ),
                if (text != null) ...<Widget>[
                  // `.notecard p` — 12 on a 1.5 line, 3 below.
                  const SizedBox(height: 3),
                  Text(
                    text!,
                    style: LumeType.fit(
                      context,
                      context.lumeType.body.copyWith(fontSize: 12, height: 1.5),
                    ).copyWith(color: lume.text2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _defaultIcon => switch (tone) {
    LumeNoteTone.info => LumeIcons.info,
    LumeNoteTone.warn => LumeIcons.alert,
    LumeNoteTone.danger => LumeIcons.alert,
    LumeNoteTone.success => LumeIcons.checkCircle,
  };
}
