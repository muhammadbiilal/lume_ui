/// The controls the seven remaining steps need, and nothing they do not.
///
/// Each is measured from the rendered prototype. They live together because
/// they are all small and all onboarding's own — none is a shared Lume
/// component, and putting them in `core/widgets` would claim they were.
///
/// | | measured |
/// |---|---|
/// | `.onb__brand` | 11 gap, 20 below; mark 46 at `r-md` on an accent gradient |
/// | `.onb__wordmark` | 20 / 800 / −0.04em, tagline 11 / 500 `text3` 1 below |
/// | `.onb-row` | 14 / 15 padding, 13 gap, `r-md`, `card` on a 1 px border |
/// | `.onb-row__icon` | 38 × 38 at `r-icon`, `tintNeutral` → `tintAccent` on |
/// | `.onb-row__title` | 14 / 700 / −0.024em |
/// | `.onb-row__sub` | 11 / 500 / 1.4, `text3`, 2 above |
/// | `.onb-choice` | wraps, 7 gap, 4 above |
/// | `.onb-choice button` | 34 tall, 13 side padding, full radius, 12 / 600 |
/// | `.onb-choice .is-active` | **inverted** — `text` ground, `bg` ink |
/// | `.onb__link` | 13 / 700 / −0.02em, `text2`, 10 padding, accent `<b>` |
/// | `.onb__note` | 11 / 500 / 1.5, `text3`, centred |
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
import 'onboarding_chrome.dart';

/// The measured constants for these parts.
abstract final class LumeOnboardingPartMetrics {
  static const double brandGap = 11;
  static const double brandBottom = 20;
  static const double markSize = 46;
  static const double markGlyph = 25;

  static const double rowPaddingY = 14;
  static const double rowPaddingX = 15;
  static const double rowGap = 13;
  static const double rowIcon = 38;
  static const double rowGlyph = 18;
  static const double rowSubGap = 2;

  /// `.onb-rows { gap: 10px; margin-top: 4px }`.
  static const double rowsGap = 10;
  static const double rowsTop = 4;

  /// `.onb-choice { gap: 7px; margin-top: 4px }`, buttons 34 tall with 13 of
  /// side padding. Measured at 390: the five pills fall into two runs 7 apart,
  /// the block is 75 tall and the first is 141.77 wide.
  static const double choiceGap = 7;
  static const double choiceTop = 4;
  static const double choiceHeight = 34;
  static const double choicePaddingX = 13;

  /// `.group-label` with the inline `padding: 0; margin: 18px 0 9px` the step
  /// gives it. The 9 and the choice's own 4 are adjacent block margins, so
  /// they collapse to 9 — measured: label bottom 489.38, pills 498.38.
  static const double choiceLabelTop = 18;
  static const double choiceLabelGap = 9;
  static const double choiceLabelSize = 11;

  /// Measured 13 tall — 11 px on a normal line box.
  static const double choiceLabelHeight = 13;

  static const double linkPadding = 10;

  /// `.onb__namefield { margin-top: 22px }`.
  static const double nameFieldTop = 22;
}

/// `.onb__brand` — the mark, the wordmark and the tagline.
class LumeOnboardingBrand extends StatelessWidget {
  const LumeOnboardingBrand({
    super.key,
    required this.wordmark,
    required this.tagline,
  });

  final String wordmark;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: LumeOnboardingPartMetrics.brandBottom,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: LumeOnboardingPartMetrics.markSize,
            height: LumeOnboardingPartMetrics.markSize,
            decoration: BoxDecoration(
              borderRadius: LumeRadius.brMd,
              // `linear-gradient(150deg, accent-400, accent-600)` — 150° from
              // the top, which is Flutter's top-left to bottom-right rotated.
              gradient: LinearGradient(
                begin: const Alignment(-0.5, -1),
                end: const Alignment(0.5, 1),
                colors: <Color>[lume.accent400, lume.accent600],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: lume.accent.withValues(alpha: 0.9),
                  blurRadius: 22,
                  spreadRadius: -10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              widthFactor: 1,
              child: LumeIcon(
                LumeIcons.lume,
                size: LumeOnboardingPartMetrics.markGlyph,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: LumeOnboardingPartMetrics.brandGap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                wordmark,
                style:
                    LumeType.tracked(
                      LumeType.fit(context, context.lumeType.title),
                      -0.04,
                    ).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 25 / 20,
                      color: lume.text,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                tagline,
                style:
                    LumeType.tracked(
                      LumeType.fit(context, context.lumeType.metaSmall),
                      -0.01,
                    ).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 14 / 11,
                      color: lume.text3,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `.onb-row` — a permission, as a switch on a card.
class LumeOnboardingToggleRow extends StatelessWidget {
  const LumeOnboardingToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String title;

  /// Changes with the faith preference: "For prayer times, Qibla, weather and
  /// nearby places" rather than "For weather, local services and nearby
  /// places". The step supplies whichever applies.
  final String subtitle;

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      toggled: value,
      label: '$title. $subtitle',
      child: LumePressable(
        onTap: () => onChanged(!value),
        excludeSemantics: true,
        borderRadius: LumeRadius.brMd,
        minSize: LumeSpace.tap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: LumeOnboardingPartMetrics.rowPaddingY,
            horizontal: LumeOnboardingPartMetrics.rowPaddingX,
          ),
          decoration: BoxDecoration(
            color: lume.card,
            borderRadius: LumeRadius.brMd,
            border: Border.all(color: lume.border, width: LumeSpace.border),
            boxShadow: context.lumeShadows.xs,
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: LumeOnboardingPartMetrics.rowIcon,
                height: LumeOnboardingPartMetrics.rowIcon,
                decoration: BoxDecoration(
                  color: value ? lume.tintAccent : lume.tintNeutral,
                  borderRadius: LumeRadius.brIcon,
                ),
                child: Center(
                  widthFactor: 1,
                  child: LumeIcon(
                    icon,
                    size: LumeOnboardingPartMetrics.rowGlyph,
                    color: value ? lume.accent : lume.text2,
                  ),
                ),
              ),
              const SizedBox(width: LumeOnboardingPartMetrics.rowGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style:
                          LumeType.tracked(
                            LumeType.fit(context, context.lumeType.cardTitle),
                            -0.024,
                          ).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 18 / 14,
                            color: lume.text,
                          ),
                    ),
                    const SizedBox(height: LumeOnboardingPartMetrics.rowSubGap),
                    Text(
                      subtitle,
                      style: LumeType.fit(context, context.lumeType.metaSmall)
                          .copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: lume.text3,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LumeOnboardingPartMetrics.rowGap),
              LumeSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// One option in `.onb-choice`.
@immutable
class LumeChoiceOption {
  const LumeChoiceOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// `.onb-choice` — wrapping pills, one chosen.
///
/// The selected pill **inverts**: `text` ground and `bg` ink, which is the one
/// place in the product a control goes fully dark rather than taking the
/// accent tint. Reproduced rather than normalised.
class LumeOnboardingChoice extends StatelessWidget {
  const LumeOnboardingChoice({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final List<LumeChoiceOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  /// `.group-label` above the pills — "Prayer calculation method". Visible,
  /// not only announced: the prototype draws it, and five bare pills do not
  /// say what they are choosing between.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget pills = Wrap(
      spacing: LumeOnboardingPartMetrics.choiceGap,
      // Each item is a 44-point target around a 34-point pill, so it already
      // reaches 5 past the pill on each side. A 7-point run gap on top of that
      // would make neighbouring targets overlap, and a target that overlaps
      // another is worse than a gap three points wider than the reference's.
      // 0 leaves the pills 10 apart where the prototype draws 7 — D15.
      runSpacing: 0,
      children: <Widget>[
        for (final LumeChoiceOption option in options)
          Semantics(
            button: true,
            selected: option.id == value,
            label: option.label,
            child: LumePressable(
              onTap: () => onChanged(option.id),
              excludeSemantics: true,
              borderRadius: LumeRadius.full,
              minSize: LumeSpace.tap,
              // The target is 44 and the pill inside it is 34. `Align` sizes
              // itself to the room it is given and the pill to its own height,
              // which is what keeps the two apart — without it the pressable's
              // floor would simply make the pill taller.
              child: Align(
                widthFactor: 1,
                child: Container(
                  height: LumeOnboardingPartMetrics.choiceHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: LumeOnboardingPartMetrics.choicePaddingX,
                  ),
                  decoration: BoxDecoration(
                    color: option.id == value ? lume.text : lume.card,
                    borderRadius: LumeRadius.full,
                    border: Border.all(
                      color: option.id == value ? lume.text : lume.border,
                      width: LumeSpace.border,
                    ),
                  ),
                  // `widthFactor: 1` and nothing else: a pill is as wide as
                  // its label plus 13 each side, which is what lets five of
                  // them wrap into two runs rather than five.
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      option.label,
                      style:
                          LumeType.tracked(
                            LumeType.fit(context, context.lumeType.label),
                            -0.015,
                          ).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 16 / 12,
                            color: option.id == value ? lume.bg : lume.text2,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (label == null) {
      return Padding(
        padding: const EdgeInsets.only(
          top: LumeOnboardingPartMetrics.choiceTop,
        ),
        child: pills,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            top: LumeOnboardingPartMetrics.choiceLabelTop,
            bottom: LumeOnboardingPartMetrics.choiceLabelGap,
          ),
          child: Text(
            label!.toUpperCase(),
            // The glyphs are capitals; the announcement is not.
            semanticsLabel: label,
            style:
                LumeType.tracked(
                  LumeType.fit(context, context.lumeType.label),
                  0.07,
                ).copyWith(
                  fontSize: LumeOnboardingPartMetrics.choiceLabelSize,
                  fontWeight: FontWeight.w700,
                  height:
                      LumeOnboardingPartMetrics.choiceLabelHeight /
                      LumeOnboardingPartMetrics.choiceLabelSize,
                  color: lume.text3,
                ),
          ),
        ),
        // The heading is read as text and again as the group's label, which is
        // what `aria-labelledby` does for the same markup.
        Semantics(container: true, label: label, child: pills),
      ],
    );
  }
}

/// `.onb__link` — a centred secondary action, with an accent tail.
class LumeOnboardingLink extends StatelessWidget implements LumeFootRow {
  const LumeOnboardingLink({
    super.key,
    required this.label,
    this.emphasis,
    this.onPressed,
  });

  /// The quiet half — "Already have an account?".
  final String label;

  /// The accent half — "Sign in". `null` for a link that is all one weight.
  final String? emphasis;

  final VoidCallback? onPressed;

  /// `.onb__link` — 13 px of text on a 17-point line box inside 10 of padding
  /// on every side. Measured 36 tall on steps 0 and 7.
  static const double height = 36;

  /// The 8 points §9's floor adds, halved. Taken out of the gap above and the
  /// step's padding below, so the text does not move.
  @override
  double get overhang => (LumeSpace.tap - height) / 2;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle base =
        LumeType.tracked(
          LumeType.fit(context, context.lumeType.bodyStrong),
          -0.02,
        ).copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 17 / 13,
          color: lume.text2,
        );

    return LumePressable(
      onTap: onPressed,
      semanticLabel: emphasis == null ? label : '$label $emphasis',
      borderRadius: LumeRadius.brXs,
      minSize: LumeSpace.tap,
      child: Padding(
        padding: const EdgeInsets.all(LumeOnboardingPartMetrics.linkPadding),
        child: Text.rich(
          TextSpan(
            text: emphasis == null ? label : '$label ',
            style: base,
            children: emphasis == null
                ? null
                : <InlineSpan>[
                    TextSpan(
                      text: emphasis,
                      style: base.copyWith(color: lume.accent),
                    ),
                  ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// `.onb__note` — the quiet line under an action.
class LumeOnboardingNote extends StatelessWidget {
  const LumeOnboardingNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: LumeType.fit(context, context.lumeType.metaSmall).copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: context.lume.text3,
    ),
  );
}
