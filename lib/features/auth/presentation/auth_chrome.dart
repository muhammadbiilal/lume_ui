/// The frame every authentication screen sits in.
///
/// Eleven compositions, one shell, one order: top → brand → visual → hero →
/// steps → notice → form → grow → actions → alternates → foot → legal. A
/// screen that needs less leaves a slot empty; none of them reorders the
/// slots, and none of them draws its own header.
///
/// Authentication has its own vertical rhythm, its own input and button sizing
/// and its own motion. What it does not have is its own palette, its own font
/// or its own geometry language — every value below resolves to a Lume token.
/// It is the first room of the same house, not a different building.
///
/// Measured from the rendered prototype at 390 × 844, light, LTR
/// (`docs/conversion_archive/measurements/auth_*.json`):
///
/// | | value |
/// |---|---|
/// | panel | max 420 wide, 24 of side padding (20 at ≤ 359) |
/// | `.auth__top` | min 48 tall, `max(16, safe-top)` above; 60 with a control |
/// | `.auth__nav` | 44 × 44, radius 14, 21 px glyph, −10 outdent |
/// | `.auth__brand` | 24 above; mark 34 × 34 radius 11, glyph 19, gap 10 |
/// | `.auth__word` | 17 / 800 / −0.035em |
/// | `.auth__visual` | 24 above, 116 tall (96 at ≤ 359); a seal is 128 (108) |
/// | `.auth__title` | `clamp(31, 8.6vw, 38)` / 720 / 1.1 / −0.034em, balanced |
/// | `.auth__text` | 15.5 / 500 / 1.5, 10 above, capped at 34ch |
/// | `.auth__note` | 12.5 / 500 / 1.45, 12 above |
/// | `.authsteps` | 16 above, 150 × 4, 6 between |
/// | `.auth__form` | 24 above, 12 between |
/// | `.auth__actions` | 24 above; the button is 54 tall, radius 15 |
/// | `.auth__foot` | 16 above, 8 between; a link is 46 tall |
/// | `.auth__legal` | 24 above, 12 px, centred |
///
/// **The one thing a measurement cannot give** is the ambient drift. The glows
/// animate over 18 seconds on a loop, and every capture was taken with reduced
/// motion forced — so the geometry below is the resting frame, read from
/// `auth.css`, and said so here rather than left to look measured.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_motion.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_text.dart';

/// Every measured constant, in one place, so no screen writes a literal.
abstract final class LumeAuthMetrics {
  /// `--auth-pad`, and its small-phone override.
  static const double pad = 24;
  static const double padNarrow = 20;
  static const double narrowWidth = 360;

  /// `--auth-form-max` and `--auth-heading-max`.
  static const double panelMax = 420;
  static const double headingMax = 360;

  /// The card composition, and the two-region one.
  static const double cardWidth = 1180;
  static const double asideWidth = 1380;
  static const double cardPanelMax = 460;
  static const double cardPad = 48;

  /// `.auth__top`.
  static const double topMin = 48;
  static const double topPadMin = 16;
  static const double navSize = 44;
  static const double navIcon = 21;
  static const double navOutdent = 10;
  static const double navRadius = 14;

  /// `.auth__brand`.
  static const double brandTop = 24;
  static const double markSize = 34;
  static const double markRadius = 11;
  static const double markIcon = 19;
  static const double brandGap = 10;

  /// `.auth__visual`.
  static const double visualTop = 24;
  static const double visualHeight = 116;
  static const double visualHeightNarrow = 96;

  /// `.authseal`.
  static const double sealSize = 128;
  static const double sealSizeNarrow = 108;
  static const double sealDisc = 68;
  static const double sealIcon = 28;
  static const double sealRingOutset = 10;
  static const double sealSpark = 15;

  /// `.auth__hero`.
  static const double heroTop = 24;
  static const double textTop = 10;
  static const double noteTop = 12;

  /// `.authsteps`.
  static const double stepsTop = 16;
  static const double stepsWidth = 150;
  static const double stepsHeight = 4;
  static const double stepsGap = 6;

  /// The form-level message, and the gap above a notice that sits outside
  /// the form.
  static const double messageRadius = 14;
  static const double noticeTop = 18;
  static const EdgeInsets messagePad = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 13,
  );
  static const double messageGap = 9;
  static const double messageIcon = 16;

  /// `.auth__form`.
  static const double formTop = 24;
  static const double formGap = 12;

  /// `.auth__actions` and the two buttons.
  static const double actionsTop = 24;
  static const double submitHeight = 54;
  static const double submitRadius = 15;
  static const double submitArrow = 17;
  static const double secondaryHeight = 50;
  static const double secondaryRadius = 14;
  static const double spinner = 15;

  /// `.auth__foot`.
  static const double footTop = 16;
  static const double footGap = 8;
  static const double linkHeight = 46;
  static const double quietPad = 8;

  /// `.auth__legal`.
  static const double legalTop = 24;

  /// The panel's own bottom: 24 plus the safe area plus the keyboard.
  static const double panelBottom = 24;

  /// Side padding at a given width.
  static double padFor(double width) => width < narrowWidth ? padNarrow : pad;

  /// The title's size — `clamp(31px, 8.6vw, 38px)`, 28 on a small phone, and
  /// the display ramp `clamp(34px, 10vw, 44px)` once the panel is a card.
  static double titleSizeFor(double width) {
    if (width >= cardWidth) return (width * 0.10).clamp(34.0, 44.0);
    if (width < narrowWidth) return 28;
    return (width * 0.086).clamp(31.0, 38.0);
  }

  /// The tracking that goes with it: −0.038em on display, −0.034 elsewhere.
  static double titleTrackFor(double width) =>
      width >= cardWidth ? -0.038 : -0.034;

  static double sealFor(double width) =>
      width < narrowWidth ? sealSizeNarrow : sealSize;

  static double visualFor(double width) =>
      width < narrowWidth ? visualHeightNarrow : visualHeight;
}

/// The type ramp §126.24 names, resolved against the Lume font.
abstract final class LumeAuthType {
  static TextStyle title(BuildContext context, double width) =>
      context.lumeType.display.copyWith(
        fontSize: LumeAuthMetrics.titleSizeFor(width),
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing:
            LumeAuthMetrics.titleSizeFor(width) *
            LumeAuthMetrics.titleTrackFor(width),
        color: context.lume.text,
      );

  static TextStyle body(BuildContext context) => context.lumeType.body.copyWith(
    fontSize: 15.5,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: context.lume.text2,
  );

  static TextStyle caption(BuildContext context) =>
      context.lumeType.body.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: context.lume.text3,
      );

  static TextStyle label(BuildContext context) =>
      context.lumeType.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.065,
        color: context.lume.text2,
      );

  static TextStyle button(BuildContext context) =>
      context.lumeType.body.copyWith(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        height: 1,
        letterSpacing: -0.279,
      );

  static TextStyle link(BuildContext context) => context.lumeType.body.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: context.lume.text2,
  );

  /// The accent a link's emphasised half takes. Dark mode uses the brighter
  /// accent, because the ink version is tuned for a light ground.
  static Color linkAccent(BuildContext context) {
    final LumeColors lume = context.lume;
    return Theme.of(context).brightness == Brightness.dark
        ? lume.accent
        : lume.accentInk;
  }
}

/// Keys the tests and the bounds comparison address parts by.
abstract final class LumeAuthKeys {
  static const Key panel = Key('auth.panel');
  static const Key top = Key('auth.top');
  static const Key back = Key('auth.back');
  static const Key close = Key('auth.close');
  static const Key stepOf = Key('auth.stepOf');
  static const Key brand = Key('auth.brand');
  static const Key mark = Key('auth.mark');
  static const Key word = Key('auth.word');
  static const Key visual = Key('auth.visual');
  static const Key seal = Key('auth.seal');
  static const Key hero = Key('auth.hero');
  static const Key title = Key('auth.title');
  static const Key text = Key('auth.text');
  static const Key note = Key('auth.note');
  static const Key steps = Key('auth.steps');
  static const Key notice = Key('auth.notice');
  static const Key formError = Key('auth.formerr');
  static const Key form = Key('auth.form');
  static const Key actions = Key('auth.actions');
  static const Key submit = Key('auth.submit');
  static const Key foot = Key('auth.foot');
  static const Key legal = Key('auth.legal');
  static const Key inline = Key('auth.inline');
  static const Key aside = Key('auth.aside');
}

/// A form row that does not take the form's standard gap above it.
///
/// Three of them differ, and each for a stated reason: the recovery link pulls
/// itself four points up into the field it belongs to, and the strength meter
/// and the rule list each sit two points further down than the flex gap alone
/// would put them. Declaring the difference here keeps the arithmetic in the
/// form rather than in a stack of one-off paddings.
abstract interface class LumeAuthFormRow {
  /// Added to the 12-point gap above this row. Negative pulls it up.
  double get gapAdjust;
}

/// The whole screen: ambient, optional aside, and the panel.
class LumeAuthScaffold extends StatelessWidget {
  const LumeAuthScaffold({
    super.key,
    this.top,
    this.brand = true,
    this.visual,
    required this.title,
    this.text,
    this.textSpan,
    this.note,
    this.steps,
    this.notice,
    this.form,
    this.grow = false,
    this.actions,
    this.alternates,
    this.foot = const <Widget>[],
    this.legal,
    this.status = false,
    this.asideTitle,
    this.asideText,
  });

  /// The header. `null` draws an empty one, which still reserves its height.
  final Widget? top;

  /// The mark and the wordmark. A status screen drops them: the seal is the
  /// focal point and two marks compete.
  final bool brand;

  final Widget? visual;
  final String title;
  final String? text;

  /// A supporting line with a run of emphasis in it — the masked address on
  /// the expiry and verification screens.
  final InlineSpan? textSpan;

  final String? note;
  final Widget? steps;

  /// A message that sits *outside* the form, above it.
  final Widget? notice;

  final Widget? form;

  /// Push the actions to the bottom. Status screens do; form screens do not.
  final bool grow;

  final Widget? actions;
  final Widget? alternates;
  final List<Widget> foot;
  final Widget? legal;

  /// A screen that reports rather than asks: centred hero, no heading cap.
  final bool status;

  final String? asideTitle;
  final String? asideText;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final MediaQueryData media = MediaQuery.of(context);
    final double width = media.size.width;
    final bool twoRegion = width >= LumeAuthMetrics.asideWidth;
    final bool card = width >= LumeAuthMetrics.cardWidth;

    final Widget panel = _Panel(
      card: card,
      status: status,
      slots: <Widget>[
        top ?? const LumeAuthTop(),
        if (brand) const LumeAuthBrand(),
        ?visual,
        _Hero(
          title: title,
          text: text,
          textSpan: textSpan,
          note: note,
          status: status,
        ),
        ?steps,
        if (notice != null)
          Padding(
            padding: const EdgeInsets.only(top: LumeAuthMetrics.noticeTop),
            child: notice,
          ),
        if (form != null)
          Padding(
            padding: const EdgeInsets.only(top: LumeAuthMetrics.formTop),
            child: KeyedSubtree(key: LumeAuthKeys.form, child: form!),
          ),
        // `.auth__grow` — the slack a status screen puts between what it says
        // and the action it offers, so the action sits at the bottom. The
        // card composition drops it: a card is as tall as its contents, so
        // there is no bottom to sit at and nothing to push against.
        if (grow && !card) const Spacer(),
        if (actions != null)
          Padding(
            padding: const EdgeInsets.only(top: LumeAuthMetrics.actionsTop),
            child: KeyedSubtree(key: LumeAuthKeys.actions, child: actions!),
          ),
        ?alternates,
        if (foot.isNotEmpty) _Foot(rows: foot),
        if (legal != null)
          Padding(
            padding: const EdgeInsets.only(top: LumeAuthMetrics.legalTop),
            child: KeyedSubtree(key: LumeAuthKeys.legal, child: legal!),
          ),
      ],
    );

    // The screen is a surface: a `Material` at its root is what gives every
    // text style, ink and selection handle underneath it something to resolve
    // against. Without one, `Text` falls back to the debug style and every
    // line renders underlined in yellow.
    return Material(
      color: lume.bg,
      child: Stack(
        children: <Widget>[
          // The aside carries the atmosphere when it is present, so the
          // ambient layer stands down rather than doubling it.
          if (!twoRegion) const Positioned.fill(child: LumeAuthAmbient()),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (twoRegion)
                  Expanded(
                    flex: 48,
                    child: LumeAuthAside(
                      title: asideTitle ?? '',
                      text: asideText ?? '',
                    ),
                  ),
                Expanded(flex: twoRegion ? 52 : 1, child: panel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The column, capped and centred, with the page's own padding.
class _Panel extends StatelessWidget {
  const _Panel({required this.slots, required this.card, required this.status});

  final List<Widget> slots;
  final bool card;
  final bool status;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final MediaQueryData media = MediaQuery.of(context);
    final double width = media.size.width;
    final double side = card
        ? LumeAuthMetrics.cardPad
        : LumeAuthMetrics.padFor(width);
    // `padding-bottom: calc(24px + safe-area + var(--auth-kb))`. The keyboard
    // is *added* to the panel's own bottom, so the field being typed into and
    // the button that submits it are never underneath it. The safe area gives
    // way to it, because a keyboard covers the home indicator too.
    final double keyboard = media.viewInsets.bottom;
    final double bottom = card
        ? LumeAuthMetrics.cardPad
        : LumeAuthMetrics.panelBottom +
              (keyboard > 0 ? keyboard : media.padding.bottom);

    // Always stretched. A status screen centres its *text*, not its blocks:
    // `.auth--status` sets `text-align: center`, and the paragraph is still a
    // full-width block. Shrink-wrapping it instead moves it off the gutter.
    final Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: slots,
    );

    final Widget padded = Padding(
      key: LumeAuthKeys.panel,
      padding: EdgeInsets.only(left: side, right: side, bottom: bottom),
      child: column,
    );

    final Widget scrollable = CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(hasScrollBody: false, child: padded),
      ],
    );

    final Widget capped = Align(
      alignment: card ? Alignment.center : Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: card
              ? LumeAuthMetrics.cardPanelMax
              : LumeAuthMetrics.panelMax,
        ),
        child: card
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: lume.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: lume.border,
                    width: LumeSpace.border,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: lume.overlay.withValues(alpha: 0.14),
                      blurRadius: 56,
                      spreadRadius: -28,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: padded,
              )
            : scrollable,
      ),
    );

    return card
        ? SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: capped,
          )
        : capped;
  }
}

/// The header: back on the leading edge, a dismissal on the trailing one.
///
/// **They are never the same control.** A back chevron steps through a flow; a
/// cross dismisses one that was put in front of something. A screen with a
/// step behind it keeps its Back even when the whole flow can also be
/// dismissed — otherwise step two of a sign-up reached from a link has no way
/// home to step one.
class LumeAuthTop extends StatelessWidget {
  const LumeAuthTop({
    super.key,
    this.onBack,
    this.onClose,
    this.stepOf,
    this.backLabel,
    this.closeLabel,
  });

  final VoidCallback? onBack;
  final VoidCallback? onClose;

  /// "Step 2 of 2", spelled out beside the indicator because a bar of
  /// segments is never the only way to know where you are.
  final String? stepOf;

  final String? backLabel;
  final String? closeLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    // Inside a card there is no notch to clear and no status bar behind the
    // header, so it sits flush against the card's own padding.
    final bool card =
        MediaQuery.sizeOf(context).width >= LumeAuthMetrics.cardWidth;
    final double top = card
        ? 0
        : math.max(
            LumeAuthMetrics.topPadMin,
            MediaQuery.paddingOf(context).top,
          );
    final double minHeight = card ? 44 : LumeAuthMetrics.topMin;

    // `min-height` is a border-box measurement in the reference, so the 48
    // includes the padding above it rather than sitting under it. A header
    // with a control is 60 tall and one without is 48 — and getting this wrong
    // moves every screen four points down.
    return Padding(
      key: LumeAuthKeys.top,
      padding: EdgeInsets.only(top: top),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: math.max(0, minHeight - top)),
        child: Row(
          children: <Widget>[
            if (onBack != null)
              Transform.translate(
                offset: Offset(card ? -12 : -LumeAuthMetrics.navOutdent, 0),
                child: _Nav(
                  key: LumeAuthKeys.back,
                  icon: LumeIcons.chevL,
                  label: backLabel,
                  onPressed: onBack,
                ),
              ),
            const Spacer(),
            if (stepOf != null)
              Text(
                stepOf!,
                key: LumeAuthKeys.stepOf,
                style: LumeAuthType.caption(
                  context,
                ).copyWith(letterSpacing: 0.125, color: lume.text3),
              ),
            if (onClose != null)
              Transform.translate(
                offset: const Offset(LumeAuthMetrics.navOutdent, 0),
                child: _Nav(
                  key: LumeAuthKeys.close,
                  icon: LumeIcons.x,
                  label: closeLabel,
                  onPressed: onClose,
                  // A dismissal is not a direction; it never mirrors.
                  mirror: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.mirror = true,
  });

  final String icon;
  final String? label;
  final VoidCallback? onPressed;

  /// The chevron follows the reading direction; a dismissal never does.
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    // `LumeIcon` mirrors a glyph only when the glyph means "forward in
    // reading order", which the chevron does and the cross does not — so the
    // rule is already right and [mirror] only records the intent.
    assert(mirror == LumeIcons.mirrors(icon), 'the icon decides its own');
    return LumePressable(
      onTap: onPressed,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(LumeAuthMetrics.navRadius),
      minSize: LumeAuthMetrics.navSize,
      child: SizedBox.square(
        dimension: LumeAuthMetrics.navSize,
        child: Center(
          child: LumeIcon(
            icon,
            size: LumeAuthMetrics.navIcon,
            color: lume.text2,
          ),
        ),
      ),
    );
  }
}

/// The mark, at its own size, in air. Never inside a heavy card.
class LumeAuthBrand extends StatelessWidget {
  const LumeAuthBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Padding(
      padding: const EdgeInsets.only(top: LumeAuthMetrics.brandTop),
      child: Row(
        key: LumeAuthKeys.brand,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            key: LumeAuthKeys.mark,
            width: LumeAuthMetrics.markSize,
            height: LumeAuthMetrics.markSize,
            decoration: BoxDecoration(
              color: lume.accent,
              borderRadius: BorderRadius.circular(LumeAuthMetrics.markRadius),
              boxShadow: context.lumeShadows.xs,
            ),
            child: Center(
              child: LumeIcon(
                LumeIcons.lume,
                size: LumeAuthMetrics.markIcon,
                color: lume.onAccent,
              ),
            ),
          ),
          const SizedBox(width: LumeAuthMetrics.brandGap),
          Text(
            'Lume',
            key: LumeAuthKeys.word,
            style: context.lumeType.body.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              // Measured 22 tall, which is what centres it against the 34
              // mark beside it.
              height: 22 / 17,
              letterSpacing: 17 * -0.035,
              color: lume.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.title,
    required this.text,
    required this.textSpan,
    required this.note,
    required this.status,
  });

  final String title;
  final String? text;
  final InlineSpan? textSpan;
  final String? note;
  final bool status;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final TextAlign align = status ? TextAlign.center : TextAlign.start;

    final Widget heading = LumeBalancedText(
      key: LumeAuthKeys.title,
      child: Text(
        title,
        style: LumeAuthType.title(context, width),
        textAlign: align,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: LumeAuthMetrics.heroTop),
      child: Column(
        key: LumeAuthKeys.hero,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // A form screen caps its heading at 360 so the line breaks land
          // where the design put them; a status screen is centred and takes
          // the width it is given.
          if (status)
            heading
          else
            // `LumeMaxWidth` rather than `ConstrainedBox`: a cap that lies
            // about its intrinsic height reports one line where there are two,
            // and `SliverFillRemaining` believes it.
            LumeMaxWidth(maxWidth: LumeAuthMetrics.headingMax, child: heading),
          if (text != null || textSpan != null)
            Padding(
              padding: const EdgeInsets.only(top: LumeAuthMetrics.textTop),
              child: _Capped(
                key: LumeAuthKeys.text,
                centred: status,
                child: textSpan != null
                    ? Text.rich(
                        textSpan!,
                        style: LumeAuthType.body(context),
                        textAlign: align,
                      )
                    : Text(
                        text!,
                        style: LumeAuthType.body(context),
                        textAlign: align,
                      ),
              ),
            ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: LumeAuthMetrics.noteTop),
              child: Text(
                note!,
                key: LumeAuthKeys.note,
                style: LumeAuthType.caption(context),
                textAlign: align,
              ),
            ),
        ],
      ),
    );
  }
}

/// `max-width: 34ch`, and centred when the screen is a status.
class _Capped extends StatelessWidget {
  const _Capped({super.key, required this.child, required this.centred});

  final Widget child;
  final bool centred;

  @override
  Widget build(BuildContext context) {
    // `max-width: 34ch`. At 390 the cap is wider than the column, so it does
    // not bind and the paragraph is a full-width block — which is why the `ch`
    // has to be measured rather than guessed: a low estimate wraps a line that
    // the reference does not.
    final double cap = 34 * lumeChWidth(context, LumeAuthType.body(context));
    return Align(
      alignment: centred ? Alignment.topCenter : AlignmentDirectional.topStart,
      child: LumeMaxWidth(maxWidth: cap, fill: true, child: child),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: LumeAuthMetrics.footTop),
      child: Column(
        key: LumeAuthKeys.foot,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: LumeAuthMetrics.footGap),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// The progressive indicator: 150 × 4, never visually dominant, and never the
/// only way to know which step this is — the count is spelled out in the
/// header beside it.
class LumeAuthSteps extends StatelessWidget {
  const LumeAuthSteps({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Padding(
      padding: const EdgeInsets.only(top: LumeAuthMetrics.stepsTop),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ExcludeSemantics(
          child: SizedBox(
            key: LumeAuthKeys.steps,
            width: LumeAuthMetrics.stepsWidth,
            height: LumeAuthMetrics.stepsHeight,
            child: Row(
              children: <Widget>[
                for (int i = 1; i <= total; i++) ...<Widget>[
                  if (i > 1) const SizedBox(width: LumeAuthMetrics.stepsGap),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: lume.card2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: lume.border2,
                          width: LumeSpace.border,
                        ),
                      ),
                      child: AnimatedFractionallySizedBox(
                        duration: LumeMotion.slow,
                        curve: LumeMotion.easeOut,
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: i <= step ? 1 : 0,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: lume.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
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

/// The two soft fields of light and three specks behind the panel.
///
/// Decorative and inert: no pointer, no semantics. The 18-second drift runs
/// only when the platform is not asking for less motion, and the specks are
/// dropped entirely when it is.
class LumeAuthAmbient extends StatefulWidget {
  const LumeAuthAmbient({super.key});

  @override
  State<LumeAuthAmbient> createState() => _LumeAuthAmbientState();
}

class _LumeAuthAmbientState extends State<LumeAuthAmbient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool quiet = MediaQuery.disableAnimationsOf(context);
    if (quiet) {
      _drift.stop();
      _drift.value = 0;
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool quiet = MediaQuery.disableAnimationsOf(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _drift,
            builder: (BuildContext context, Widget? _) {
              final double t = _drift.value;
              return Stack(
                children: <Widget>[
                  PositionedDirectional(
                    top: -140 + 34 * t,
                    start: -110 + 26 * t,
                    child: _Glow(
                      size: 320 * (1 + 0.12 * t),
                      colour: lume.accent.withValues(alpha: dark ? 0.16 : 0.12),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: -130 + 26 * t,
                    end: -100 + 30 * t,
                    child: _Glow(
                      size: 280 * (1.06 - 0.06 * t),
                      colour: lume.violet.withValues(alpha: dark ? 0.14 : 0.10),
                    ),
                  ),
                  if (!quiet) ...<Widget>[
                    _Speck(top: 0.22, end: 0.16, size: 5, colour: lume.accent),
                    _Speck(
                      top: 0.62,
                      start: 0.11,
                      size: 4,
                      colour: lume.accent,
                    ),
                    _Speck(top: 0.79, end: 0.24, size: 3, colour: lume.accent),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A circle under `filter: blur(48px)`, as the radial gradient that reads the
/// same: solid to the edge of the disc, then a soft fall-off.
class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[colour, colour.withValues(alpha: 0)],
            stops: const <double>[0.42, 1],
          ),
        ),
      ),
    );
  }
}

class _Speck extends StatelessWidget {
  const _Speck({
    required this.top,
    required this.size,
    required this.colour,
    this.start,
    this.end,
  });

  /// Fractions of the box, as the stylesheet writes them.
  final double top;
  final double? start;
  final double? end;
  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    // A `LayoutBuilder` is not a `Stack`, so the positioned dot needs one of
    // its own inside it — otherwise the parent data has nowhere to go.
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => Stack(
        children: <Widget>[
          PositionedDirectional(
            top: box.maxHeight * top,
            start: start == null ? null : box.maxWidth * start!,
            end: end == null ? null : box.maxWidth * end!,
            child: Opacity(
              opacity: 0.28,
              child: SizedBox.square(
                dimension: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colour,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The decorative half of the desktop composition.
///
/// Atmosphere and one line of brand message — never a field, never a control,
/// so nothing is lost when the composition collapses back to one column.
class LumeAuthAside extends StatelessWidget {
  const LumeAuthAside({super.key, required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return ExcludeSemantics(
      child: Container(
        key: LumeAuthKeys.aside,
        margin: const EdgeInsets.all(LumeSpace.x6),
        decoration: BoxDecoration(
          color: lume.card2,
          borderRadius: BorderRadius.circular(28),
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.8),
            radius: 1.1,
            colors: <Color>[
              lume.accent.withValues(alpha: 0.22),
              lume.card2.withValues(alpha: 0),
            ],
            stops: const <double>[0, 0.65],
          ),
        ),
        child: Stack(
          children: <Widget>[
            // `inset: 0` — the drawing fills the aside, not the padded box
            // the message sits in.
            Positioned.fill(child: _AsideArt(lume: lume)),
            Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 15 * 16.5),
                    child: Text(
                      title,
                      style: context.lumeType.display.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: 30 * -0.034,
                        color: lume.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: LumeSpace.x4),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          34 * lumeChWidth(context, LumeAuthType.body(context)),
                    ),
                    child: Text(text, style: LumeAuthType.body(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The aside's drawing: two soft discs, one sparkle and two specks, in the
/// proportions the source's 400 × 500 artboard puts them.
///
/// `preserveAspectRatio="xMidYMid slice"`: one scale for both axes, the larger
/// of the two so the box is covered, and the overflow clipped by the aside's
/// own rounded corner rather than spilling past it.
class _AsideArt extends StatelessWidget {
  const _AsideArt({required this.lume});

  final LumeColors lume;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double scale = math.max(box.maxWidth / 400, box.maxHeight / 500);
        final double dx = (box.maxWidth - 400 * scale) / 2;
        final double dy = (box.maxHeight - 500 * scale) / 2;

        Widget disc(double cx, double cy, double r, Color c) => Positioned(
          left: dx + (cx - r) * scale,
          top: dy + (cy - r) * scale,
          width: 2 * r * scale,
          height: 2 * r * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: c),
          ),
        );

        return Stack(
          children: <Widget>[
            disc(316, 96, 120, lume.accent.withValues(alpha: 0.10)),
            disc(86, 392, 96, lume.violet.withValues(alpha: 0.10)),
            disc(330, 330, 7, lume.sky.withValues(alpha: 0.4)),
            disc(252, 188, 4.5, lume.violet.withValues(alpha: 0.45)),
            Positioned(
              left: dx + (132 - 15) * scale,
              top: dy + (133 - 15) * scale,
              child: Opacity(
                opacity: 0.42,
                child: LumeIcon(
                  LumeIcons.sparkles,
                  size: 30 * scale,
                  color: lume.accent,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
