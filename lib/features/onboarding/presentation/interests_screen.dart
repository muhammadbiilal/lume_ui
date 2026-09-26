/// "What are you here for?" — the interest picker, as a widget.
///
/// One presentation widget over a [LumeInterestsModel]. It renders chips,
/// reports taps, and shows the count; every rule about what is offered, what
/// the cap does and what the faith switch seeds belongs to
/// [LumeInterestsController] and [LumeInterests].
///
/// Measured from the rendered prototype at 390 (light, LTR):
///
/// | | value |
/// |---|---|
/// | `.picker__bar` | 23 tall, 12 gap, 11 below, space-between |
/// | `.picker__count` | 12 / 700 / −0.015em, `text3`, tabular; count in accent |
/// | `.picker__clear` | 12 / 700, `text3`, 4 padding |
/// | `.picker` | wraps, 8 gap |
/// | `.pick` | 40 tall, 0/15/0/12 padding, full radius, `card`, 13 / 600 |
/// | `.pick.is-on` | `tintAccent`, 42 % accent border, `accentInk` |
/// | `.pick.is-muted` | 0.42 opacity |
/// | `.pickgroup__label` | 10 / 700 / +0.07em, uppercase, `text3`, 9 below |
/// | `.pickgroup--faith` | 18 above, 4 padding, 20 radius, `card2` |
/// | `.faithtoggle` | 11 padding, 11 gap, 16 radius; icon 34 at 12 radius |
/// | `.picker--nested` | 2 / 11 / 11 padding |
///
/// **One of those is a value a stylesheet read gets wrong.**
/// `.pickgroup--faith` declares `margin-top: 20px`, but `.pickgroup +
/// .pickgroup` declares 18 and carries two class selectors to its one — so the
/// faith card actually sits 18 below its neighbour. The measurement says 18.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../domain/interests_model.dart';
import 'onboarding_chrome.dart';

/// The measured constants for the picker.
abstract final class LumePickerMetrics {
  /// `.picker__bar`.
  static const double barGap = 12;
  static const double barHeight = 23;
  static const double barBottom = 11;

  /// Clear is a 23 px control, so its 44 px target overhangs the bar by 10.5
  /// each way — into the 18 above it and the 11 below, both of which are
  /// empty. The two gaps are reduced by the same amount, so the bar's contents
  /// land exactly where the prototype puts them while the target is whole.
  /// D6 again: the reference is under §9's floor and that is a defect to
  /// correct, not a measurement to copy.
  static const double barOverhang = (LumeSpace.tap - barHeight) / 2;

  /// `.picker { gap: 8px }`.
  static const double chipGap = 8;

  /// `.pick`.
  static const double chipHeight = 40;
  static const double chipPaddingStart = 12;
  static const double chipPaddingEnd = 15;
  static const double chipIconGap = 8;
  static const double chipIcon = 16;

  /// `.pick.is-muted { opacity: .42 }`.
  static const double mutedOpacity = 0.42;

  /// `.pickgroup__label { margin-bottom: 9px }`.
  static const double groupLabelBottom = 9;

  /// `.pickgroup + .pickgroup { margin-top: 18px }` — which beats
  /// `.pickgroup--faith`'s declared 20 on specificity, so the faith card sits
  /// at 18 like every other group.
  static const double groupGap = 18;

  /// `.pickgroup--faith { padding: 4px }`.
  static const double faithPadding = 4;

  /// `.faithtoggle`.
  static const double togglePadding = 11;
  static const double toggleGap = 11;
  static const double toggleIconSize = 34;
  static const double toggleIconGlyph = 17;
  static const double toggleSubGap = 2;

  /// `.picker--nested { padding: 2px 11px 11px }`.
  static const EdgeInsets nestedPadding = EdgeInsets.fromLTRB(11, 2, 11, 11);
}

/// The counter, the clear action, the groups and the faith card.
class LumeInterestsView extends StatelessWidget {
  const LumeInterestsView({
    super.key,
    required this.model,
    required this.onToggle,
    required this.onClear,
    required this.onFaithChanged,
    required this.countLabel,
    required this.clearLabel,
    required this.faithTitle,
    required this.faithSubtitle,
    this.header,
    this.footer,
    this.scrollController,
  });

  final LumeInterestsModel model;

  /// Called with the interest's id. The screen above decides what a refused
  /// tap says; this only reports it.
  final ValueChanged<String> onToggle;

  final VoidCallback onClear;
  final ValueChanged<bool> onFaithChanged;

  /// Already formatted — `{n} of {min} minimum` below the minimum, `{n} of
  /// {max} selected` at or above it. The screen owns which, because only it
  /// has the localisations.
  final String countLabel;

  final String clearLabel;
  final String faithTitle;
  final String faithSubtitle;

  /// The step's kicker, title and supporting copy.
  ///
  /// It goes *inside* the scroll view rather than above it, because the
  /// reference's interests step has no `--list` modifier: `.onb-step` is the
  /// scroller and everything but the sticky footer moves with it. Pinning the
  /// lead instead left 46 points for a region needing 52 on a landscape phone,
  /// and the column overflowed.
  final Widget? header;

  /// After the picker, scrolling with it — the Personalisation sheet's
  /// data-safe note and Save. Onboarding has none.
  final Widget? footer;

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final List<LumeInterestGroup> ordinary = model.groups
        .where((LumeInterestGroup g) => !g.faith)
        .toList();
    final LumeInterestGroup? faith = model.groups
        .where((LumeInterestGroup g) => g.faith)
        .firstOrNull;

    return ListView(
      controller: scrollController,
      primary: false,
      padding: EdgeInsets.zero,
      children: <Widget>[
        ?header,
        // The step puts 18 between its copy and the picker, less the target's
        // overhang — see `barOverhang`.
        const SizedBox(
          height:
              LumeOnboardingMetrics.pickerTop - LumePickerMetrics.barOverhang,
        ),
        _Bar(
          countLabel: countLabel,
          clearLabel: clearLabel,
          onClear: model.count == 0 ? null : onClear,
        ),
        const SizedBox(
          height: LumePickerMetrics.barBottom - LumePickerMetrics.barOverhang,
        ),
        for (int i = 0; i < ordinary.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: LumePickerMetrics.groupGap),
          _Group(group: ordinary[i], model: model, onToggle: onToggle),
        ],
        if (faith != null) ...<Widget>[
          const SizedBox(height: LumePickerMetrics.groupGap),
          _FaithCard(
            group: faith,
            model: model,
            title: faithTitle,
            subtitle: faithSubtitle,
            onToggle: onToggle,
            onChanged: onFaithChanged,
          ),
        ],
        ?footer,
      ],
    );
  }
}

/// `.picker__bar` — how many are chosen, and a way to start again.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.countLabel,
    required this.clearLabel,
    required this.onClear,
  });

  final String countLabel;
  final String clearLabel;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return SizedBox(
      height: LumeSpace.tap,
      child: Row(
        children: <Widget>[
          // Flexible, not Expanded: `.picker__count` is an inline span that
          // shrink-wraps its text, and the bar's `space-between` is what puts
          // Clear on the end edge. Expanding it would make the count's box the
          // width of the whole bar.
          Flexible(
            child: Semantics(
              liveRegion: true,
              child: Text(
                countLabel,
                style: LumeType.numeric(
                  LumeType.tracked(
                    LumeType.fit(context, context.lumeType.label),
                    -0.015,
                  ),
                ).copyWith(fontSize: 12, color: lume.text3),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: LumePickerMetrics.barGap),
          LumePressable(
            onTap: onClear,
            semanticLabel: clearLabel,
            minSize: LumeSpace.tap,
            borderRadius: LumeRadius.brXs,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                clearLabel,
                style: LumeType.fit(
                  context,
                  context.lumeType.label,
                ).copyWith(fontSize: 12, color: lume.text3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.group,
    required this.model,
    required this.onToggle,
  });

  final LumeInterestGroup group;
  final LumeInterestsModel model;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    // Stretched: `.pickgroup__label` is a block `<p>` and fills the group's
    // width, even though its ink is left-aligned.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          group.label.toUpperCase(),
          // The glyphs are capitals; the announcement is not.
          semanticsLabel: group.label,
          style:
              LumeType.tracked(
                LumeType.fit(context, context.lumeType.label),
                0.07,
              ).copyWith(
                fontSize: 10,
                // `.pickgroup__label` is 12 tall.
                height: 12 / 10,
                color: lume.text3,
              ),
        ),
        const SizedBox(height: LumePickerMetrics.groupLabelBottom),
        _Chips(interests: group.interests, model: model, onToggle: onToggle),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.interests,
    required this.model,
    required this.onToggle,
  });

  final List<LumeInterest> interests;
  final LumeInterestsModel model;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LumePickerMetrics.chipGap,
      runSpacing: LumePickerMetrics.chipGap,
      children: <Widget>[
        for (final LumeInterest interest in interests)
          LumeInterestChip(
            interest: interest,
            selected: model.isSelected(interest.id),
            muted: model.isMuted(interest.id),
            onTap: () => onToggle(interest.id),
          ),
      ],
    );
  }
}

/// `.pick` — one interest.
class LumeInterestChip extends StatelessWidget {
  const LumeInterestChip({
    super.key,
    required this.interest,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  final LumeInterest interest;
  final bool selected;

  /// At the cap, an unselected chip steps back rather than disappearing. It
  /// stays pressable: a tap is what produces the message explaining why it
  /// cannot be added, and a chip that silently ignored a tap would be worse.
  final bool muted;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: selected,
      label: interest.label,
      child: Opacity(
        opacity: muted ? LumePickerMetrics.mutedOpacity : 1,
        child: LumePressable(
          onTap: onTap,
          excludeSemantics: true,
          borderRadius: LumeRadius.full,
          minSize: LumePickerMetrics.chipHeight,
          child: Container(
            height: LumePickerMetrics.chipHeight,
            padding: const EdgeInsetsDirectional.only(
              start: LumePickerMetrics.chipPaddingStart,
              end: LumePickerMetrics.chipPaddingEnd,
            ),
            decoration: BoxDecoration(
              color: selected ? lume.tintAccent : lume.card,
              borderRadius: LumeRadius.full,
              border: Border.all(
                color: selected
                    ? lume.accent.withValues(alpha: 0.42)
                    : lume.border,
                width: LumeSpace.border,
              ),
              boxShadow: selected ? null : context.lumeShadows.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LumeIcon(
                  interest.icon,
                  size: LumePickerMetrics.chipIcon,
                  color: selected ? lume.accent : lume.text3,
                ),
                const SizedBox(width: LumePickerMetrics.chipIconGap),
                // Loose, so a chip no wider than its row ellipsizes its label
                // at large text instead of running past its own edge; a chip
                // that fits is drawn exactly as before.
                Flexible(
                  child: Text(
                    interest.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        LumeType.tracked(
                          LumeType.fit(context, context.lumeType.label),
                          -0.02,
                        ).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          // `[data-theme="dark"] .pick.is-on` swaps the ink, because
                          // `accentInk` is a dark green that disappears on a dark
                          // ground.
                          color: selected
                              ? (dark ? lume.accent700 : lume.accentInk)
                              : lume.text2,
                        ),
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

/// `.pickgroup--faith` — the switch that makes its own features exist.
///
/// Kept apart from the five ordinary groups on purpose, and never preselected:
/// §3 says the product never asks whether someone is Muslim and never infers
/// it. Choosing an Islamic interest is what switches the experience on.
class _FaithCard extends StatelessWidget {
  const _FaithCard({
    required this.group,
    required this.model,
    required this.title,
    required this.subtitle,
    required this.onToggle,
    required this.onChanged,
  });

  final LumeInterestGroup group;
  final LumeInterestsModel model;
  final String title;
  final String subtitle;
  final ValueChanged<String> onToggle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool on = model.faithOpen;

    return Container(
      padding: const EdgeInsets.all(LumePickerMetrics.faithPadding),
      decoration: BoxDecoration(
        color: lume.card2,
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            toggled: on,
            label: '$title. $subtitle',
            child: LumePressable(
              onTap: () => onChanged(!on),
              excludeSemantics: true,
              borderRadius: LumeRadius.brMd,
              minSize: LumeSpace.tap,
              child: Padding(
                padding: const EdgeInsets.all(LumePickerMetrics.togglePadding),
                child: Row(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: LumePickerMetrics.toggleIconSize,
                      height: LumePickerMetrics.toggleIconSize,
                      decoration: BoxDecoration(
                        color: on ? lume.tintAccent : lume.tintNeutral,
                        borderRadius: LumeRadius.brIcon,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: LumeIcon(
                          LumeIcons.moonStar,
                          size: LumePickerMetrics.toggleIconGlyph,
                          color: on ? lume.accent : lume.text2,
                        ),
                      ),
                    ),
                    const SizedBox(width: LumePickerMetrics.toggleGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            title,
                            style:
                                LumeType.tracked(
                                  LumeType.fit(
                                    context,
                                    context.lumeType.cardTitle,
                                  ),
                                  -0.026,
                                ).copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: lume.text,
                                ),
                          ),
                          const SizedBox(
                            height: LumePickerMetrics.toggleSubGap,
                          ),
                          Text(
                            subtitle,
                            style:
                                LumeType.fit(
                                  context,
                                  context.lumeType.metaSmall,
                                ).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  color: lume.text3,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: LumePickerMetrics.toggleGap),
                    LumeSwitch(value: on, onChanged: onChanged),
                  ],
                ),
              ),
            ),
          ),
          // `.picker--nested[hidden]` — the interests do not exist until the
          // switch is on, so they are built only then rather than hidden.
          if (on)
            Padding(
              padding: LumePickerMetrics.nestedPadding,
              child: _Chips(
                interests: group.interests,
                model: model,
                onToggle: onToggle,
              ),
            ),
        ],
      ),
    );
  }
}
