/// Profile's and the account section's own furniture.
///
/// *"The §124.30 standard is the existing list row: icon, title, description,
/// value, chevron. It is not re-invented here — only the account-specific
/// variants are."* So this file holds the variants and nothing else:
///
/// | here | already existed | why not that one |
/// |---|---|---|
/// | `.srow__value` 12.5/700, wraps, 46vw cap | `LumeListRow.value` | that one is a figure: 13/700, numerals, capped at 110 and ellipsised. An address has to wrap |
/// | `.optrow` a radio with a check at the end | `LumeChoiceChip` | a full-width row in a radio group, with a roving tab stop |
/// | `.phead` a centred identity card | `LumeCard` | its own art, avatar, meta row and stacked actions |
/// | `.sessrow` a device with its own Sign out | `LumeListRow` | a row whose end is a destructive control, not a chevron |
/// | `.danger` a block that is deliberately apart | — | nothing like it exists |
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

/// The measured constants for Profile and the account section.
abstract final class LumeSettingsMetrics {
  /// `.group-label { padding: 0 var(--pad); margin-bottom: 9px }`.
  static const double groupLabelGap = 9;

  /// `.phead { margin: 14px var(--pad) 0; padding: 20px 18px 18px }`.
  static const EdgeInsets identityPadding = EdgeInsets.fromLTRB(18, 20, 18, 18);
  static const double identityTop = 14;

  /// `.phead__id { gap: 10px }`, `.phead__acts { margin-top: 14px; gap: 9px }`.
  static const double identityGap = 10;
  static const double actsTop = 14;
  static const double actsGap = 9;

  /// `.pavatar { width: 76px; height: 76px; border-radius: 26px }`.
  static const double avatarSize = 76;
  static const double avatarRadius = 26;
  static const double avatarGlyph = 30;

  /// `.pavatar--sm`.
  static const double avatarSmall = 54;
  static const double avatarSmallRadius = 18;

  /// `.guestwhy { margin-top: 14px; padding: 14px 16px }`.
  static const EdgeInsets guestWhyPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  /// `.optrow { padding: var(--pad-row); gap: 12px }`.
  static const EdgeInsets optionPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const double optionGap = 12;

  /// `.srow__value { max-width: 46vw }`.
  static const double valueFraction = 0.46;
}

/// `.group-label` — an uppercase kicker over a list.
class LumeSettingsGroupLabel extends StatelessWidget {
  const LumeSettingsGroupLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      // `text-transform: uppercase` is presentation, so it is applied here
      // rather than baked into a translation. Urdu and Arabic have no case
      // and are unchanged by it.
      LumeType.overline(context, label),
      style: LumeType.tracked(
        LumeType.natural(context, context.lumeType.metaSmall, size: 11),
        0.07,
      ).copyWith(color: context.lume.text3, fontWeight: FontWeight.w700),
    ),
  );
}

/// `.list-row` as a settings row: an icon, a title, a description, a value
/// that wraps, and a chevron — or a switch instead of the last two.
class LumeSettingsRow extends StatelessWidget {
  const LumeSettingsRow({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.value,
    this.toggle,
    this.accent = false,
    this.chevron = true,
    this.onTap,
    this.isLast = false,
    this.semanticLabel,
  });

  final String title;
  final String? icon;
  final String? subtitle;

  /// The current setting, read without opening anything. An **empty** string
  /// means "the product holds this and knows it to be empty" and renders as
  /// "Not set"; `null` means it has no such value at all. They are not the
  /// same, and the row for the first says so.
  final String? value;

  /// A switch instead of a value and a chevron. `null` for a row that is not
  /// one — a switch that is always off would advertise a setting that does
  /// not exist.
  final bool? toggle;

  /// `style="background:var(--tint-accent);color:var(--accent)"` on the first
  /// row of a group.
  final bool accent;

  final bool chevron;
  final VoidCallback? onTap;
  final bool isLast;

  /// Overrides what a screen reader hears.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool isSwitch = toggle != null;

    return LumePressable(
      onTap: onTap,
      semanticLabel:
          semanticLabel ?? <String>[title, ?subtitle, ?value].join(', '),
      button: !isSwitch,
      selected: isSwitch ? toggle : null,
      minSize: 0,
      child: Container(
        constraints: const BoxConstraints(minHeight: LumeSpace.tap),
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
              if (icon != null) ...<Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent ? lume.tintAccent : lume.tintNeutral,
                    borderRadius: LumeRadius.brIcon,
                  ),
                  alignment: Alignment.center,
                  child: LumeIcon(
                    icon!,
                    size: 17,
                    color: accent ? lume.accent : lume.text2,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: LumeType.tracked(
                        LumeType.natural(
                          context,
                          context.lumeType.meta,
                          size: 14,
                        ),
                        -0.022,
                      ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        // `.list-row__sub--wrap { white-space: normal }` — a
                        // description explains, so it is allowed to wrap.
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSwitch)
                _Switch(on: toggle!)
              else ...<Widget>[
                if (value != null)
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.sizeOf(context).width *
                            LumeSettingsMetrics.valueFraction,
                      ),
                      child: LumeNumerals(
                        value!,
                        style:
                            LumeType.natural(
                              context,
                              context.lumeType.meta,
                              size: 12.5,
                            ).copyWith(
                              color: lume.text2,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                if (chevron) ...<Widget>[
                  const SizedBox(width: 8),
                  LumeIcon(LumeIcons.chevR, size: 16, color: lume.text3),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.switch` — the reference's own two-state control.
class _Switch extends StatelessWidget {
  const _Switch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 42,
      height: 25,
      padding: const EdgeInsets.all(3),
      alignment: on
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: on ? lume.accent : lume.tintNeutral,
        borderRadius: LumeRadius.full,
      ),
      child: Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: on ? lume.onAccent : lume.card,
          shape: BoxShape.circle,
          boxShadow: context.lumeShadows.xs,
        ),
      ),
    );
  }
}

/// `.optrow` — one choice in a radio group.
class LumeOptionRow extends StatelessWidget {
  const LumeOptionRow({
    super.key,
    required this.title,
    required this.selected,
    this.subtitle,
    this.onTap,
    this.isLast = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: LumePressable(
        onTap: onTap,
        semanticLabel: <String>[title, ?subtitle].join(', '),
        button: false,
        minSize: 0,
        child: Container(
          constraints: const BoxConstraints(minHeight: LumeSpace.tap),
          padding: LumeSettingsMetrics.optionPadding,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
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
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 1),
                        LumeNumerals(
                          subtitle!,
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
                    ],
                  ),
                ),
                const SizedBox(width: LumeSettingsMetrics.optionGap),
                // The check is the state made visible. It is not the only
                // signal — the weight changes too — so the row does not
                // depend on colour alone.
                Opacity(
                  opacity: selected ? 1 : 0,
                  child: LumeIcon(
                    LumeIcons.check,
                    size: 17,
                    color: lume.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.optlist` — a radio group of [LumeOptionRow]s.
class LumeOptionList extends StatelessWidget {
  const LumeOptionList({
    super.key,
    required this.label,
    required this.children,
  });

  /// What the group is choosing, for a screen reader.
  final String label;
  final List<LumeOptionRow> children;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brLg,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.sm,
        ),
        padding: const EdgeInsets.all(LumeSpace.border),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < children.length; i++)
              if (i == children.length - 1)
                LumeOptionRow(
                  key: children[i].key,
                  title: children[i].title,
                  subtitle: children[i].subtitle,
                  selected: children[i].selected,
                  onTap: children[i].onTap,
                  isLast: true,
                )
              else
                children[i],
          ],
        ),
      ),
    );
  }
}

/// `.pavatar` — a photo, initials from a real name, or a neutral glyph.
///
/// In that order, and **never an invented set of letters**: an email is not a
/// name, and two characters taken from one is a guess presented as a fact.
class LumeProfileAvatar extends StatelessWidget {
  const LumeProfileAvatar({
    super.key,
    this.photo = '',
    this.initials = '',
    this.small = false,
  });

  final String photo;
  final String initials;

  /// `.pavatar--sm`, on the edit form.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double size = small
        ? LumeSettingsMetrics.avatarSmall
        : LumeSettingsMetrics.avatarSize;
    final double radius = small
        ? LumeSettingsMetrics.avatarSmallRadius
        : LumeSettingsMetrics.avatarRadius;
    final bool anonymous = photo.isEmpty && initials.isEmpty;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: anonymous ? lume.tintNeutral : lume.tintAccent,
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          border: Border.all(
            color: anonymous
                ? lume.border
                : lume.accent.withValues(alpha: 0.18),
            width: LumeSpace.border,
          ),
        ),
        alignment: Alignment.center,
        child: photo.isNotEmpty
            ? Image.network(photo, fit: BoxFit.cover, width: size, height: size)
            : initials.isNotEmpty
            ? Text(
                initials,
                style: LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.title,
                    size: small ? 17 : 23,
                  ),
                  -0.02,
                ).copyWith(color: lume.accentInk, fontWeight: FontWeight.w800),
              )
            : LumeIcon(
                LumeIcons.user,
                size: LumeSettingsMetrics.avatarGlyph,
                color: lume.text3,
              ),
      ),
    );
  }
}

/// `.guestwhy` — three reasons an account is worth having.
class LumeGuestWhy extends StatelessWidget {
  const LumeGuestWhy({super.key, required this.title, required this.reasons});

  final String title;
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Container(
      padding: LumeSettingsMetrics.guestWhyPadding,
      decoration: BoxDecoration(
        color: lume.card2,
        borderRadius: LumeRadius.brMd,
        border: Border.all(color: lume.border, width: LumeSpace.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            LumeType.overline(context, title),
            style: LumeType.tracked(
              LumeType.natural(context, context.lumeType.metaSmall, size: 11),
              0.04,
            ).copyWith(color: lume.text3, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < reasons.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: LumeIcon(
                    LumeIcons.check,
                    size: 14,
                    color: lume.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reasons[i],
                    style:
                        LumeType.natural(
                          context,
                          context.lumeType.meta,
                          size: 12.5,
                        ).copyWith(
                          color: lume.text2,
                          fontWeight: FontWeight.w600,
                          height: LumeType.lineHeight(context, 1.4),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// `.sessrow` — a device holding a session, and the way to end it.
class LumeSessionRow extends StatelessWidget {
  const LumeSessionRow({
    super.key,
    required this.label,
    required this.detail,
    required this.semanticLabel,
    this.thisDeviceLabel,
    this.signOutLabel,
    this.onSignOut,
    this.isLast = false,
  });

  final String label;

  /// "Islamabad, Pakistan · Last seen 6 Sept, 9:14 pm", composed by the
  /// caller so the date and the time are the reader's.
  final String detail;

  final String semanticLabel;

  /// Set on the device the reader is holding. It has no Sign out of its own:
  /// ending this session is signing out, which lives elsewhere and says so.
  final String? thisDeviceLabel;

  final String? signOutLabel;
  final VoidCallback? onSignOut;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        constraints: const BoxConstraints(minHeight: LumeSpace.tap),
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
        child: Row(
          children: <Widget>[
            ExcludeSemantics(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: lume.tintNeutral,
                  borderRadius: LumeRadius.brIcon,
                ),
                alignment: Alignment.center,
                child: LumeIcon(LumeIcons.device, size: 17, color: lume.text2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            label,
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
                        if (thisDeviceLabel != null) ...<Widget>[
                          const SizedBox(width: 6),
                          Text(
                            thisDeviceLabel!,
                            style:
                                LumeType.natural(
                                  context,
                                  context.lumeType.metaSmall,
                                  size: 11,
                                ).copyWith(
                                  color: lume.accent,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    LumeNumerals(
                      detail,
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
            ),
            if (onSignOut != null && signOutLabel != null) ...<Widget>[
              const SizedBox(width: 8),
              LumePressable(
                onTap: onSignOut,
                semanticLabel: '$signOutLabel, $label',
                borderRadius: LumeRadius.brSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      signOutLabel!,
                      style: LumeType.natural(
                        context,
                        context.lumeType.metaSmall,
                        size: 11,
                      ).copyWith(color: lume.rose, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `.danger` — a block kept deliberately apart from routine rows.
class LumeDangerZone extends StatelessWidget {
  const LumeDangerZone({
    super.key,
    required this.label,
    required this.text,
    required this.child,
  });

  /// The kicker above the block.
  final String label;

  /// What it does, before the control that does it.
  final String text;

  /// The action.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            LumeType.overline(context, label),
            style: LumeType.tracked(
              LumeType.natural(context, context.lumeType.metaSmall, size: 11),
              0.07,
            ).copyWith(color: lume.rose, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: LumeSettingsMetrics.groupLabelGap),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lume.rose.withValues(alpha: 0.06),
            borderRadius: LumeRadius.brLg,
            border: Border.all(
              color: lume.rose.withValues(alpha: 0.24),
              width: LumeSpace.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                text,
                style:
                    LumeType.natural(
                      context,
                      context.lumeType.meta,
                      size: 12.5,
                    ).copyWith(
                      color: lume.text2,
                      fontWeight: FontWeight.w500,
                      height: LumeType.lineHeight(context, 1.45),
                    ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

/// `.conseq` — what an irreversible action takes away, and what it leaves.
class LumeConsequenceList extends StatelessWidget {
  const LumeConsequenceList({
    super.key,
    required this.items,
    required this.keeps,
  });

  final List<String> items;

  /// `conseq--keep` rather than `conseq--lose`: a check and the accent, not a
  /// cross and the rose.
  final bool keeps;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color tint = keeps ? lume.accent : lume.rose;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: LumeIcon(
                  keeps ? LumeIcons.check : LumeIcons.x,
                  size: 14,
                  color: tint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  items[i],
                  style:
                      LumeType.natural(
                        context,
                        context.lumeType.meta,
                        size: 12.5,
                      ).copyWith(
                        color: lume.text2,
                        fontWeight: FontWeight.w600,
                        height: LumeType.lineHeight(context, 1.4),
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// `.storegroup` — a labelled list of what is kept somewhere.
class LumeStoreGroup extends StatelessWidget {
  const LumeStoreGroup({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
  });

  final String icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Row(
            children: <Widget>[
              LumeIcon(icon, size: 14, color: lume.text3),
              const SizedBox(width: 7),
              Text(
                label,
                style: LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                    size: 11,
                  ),
                  0.04,
                ).copyWith(color: lume.text3, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: LumeSettingsMetrics.groupLabelGap),
        child,
      ],
    );
  }
}
