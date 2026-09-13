/// The pieces the eleven authentication screens are assembled from.
///
/// Everything here is measured. The one thing that is not is the seal's
/// drawing animation: the reference animates a `stroke-dashoffset` on a glyph
/// referenced through `<use>`, which is a CSS technique rather than a design
/// requirement, so the seal here fades and scales in — the same "it arrives",
/// reached honestly. Under reduced motion it is simply there.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_motion.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../domain/password_policy.dart';
import 'auth_chrome.dart';

/// How warm the seal reads. The same geometry at three temperatures.
enum LumeSealTone {
  /// A celebration: the accent disc, white glyph.
  bright,

  /// A status rather than an arrival.
  calm,

  /// Something the user has to deal with.
  warn,
}

/// The success visual: a ring, a disc, a glyph and two specks.
class LumeAuthSeal extends StatefulWidget {
  const LumeAuthSeal({
    super.key,
    required this.icon,
    this.tone = LumeSealTone.bright,
  });

  final String icon;
  final LumeSealTone tone;

  @override
  State<LumeAuthSeal> createState() => _LumeAuthSealState();
}

class _LumeAuthSealState extends State<LumeAuthSeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LumeMotion.stillness(context)) {
      _in.value = 1;
    } else if (!_in.isAnimating && _in.value == 0) {
      _in.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double size = LumeAuthMetrics.sealFor(
      MediaQuery.sizeOf(context).width,
    );

    final Color ringFill = switch (widget.tone) {
      LumeSealTone.bright => lume.tintAccent,
      LumeSealTone.calm => lume.accent.withValues(alpha: 0.08),
      LumeSealTone.warn => lume.amber.withValues(alpha: 0.12),
    };
    final Color ringEdge = switch (widget.tone) {
      LumeSealTone.warn => lume.amber.withValues(alpha: 0.30),
      _ => lume.accent.withValues(alpha: 0.26),
    };
    final Color discFill = switch (widget.tone) {
      LumeSealTone.bright => lume.accent,
      LumeSealTone.calm => lume.card,
      LumeSealTone.warn => Color.alphaBlend(
        lume.amber.withValues(alpha: 0.16),
        lume.card,
      ),
    };
    final Color glyph = switch (widget.tone) {
      LumeSealTone.bright => lume.onAccent,
      LumeSealTone.calm => lume.accent,
      LumeSealTone.warn => lume.amber,
    };
    final Color? discEdge = switch (widget.tone) {
      LumeSealTone.bright => null,
      LumeSealTone.calm => lume.border,
      LumeSealTone.warn => lume.amber.withValues(alpha: 0.34),
    };

    final CurvedAnimation curve = CurvedAnimation(
      parent: _in,
      curve: LumeMotion.easeOut,
    );

    return Padding(
      padding: const EdgeInsets.only(top: LumeAuthMetrics.visualTop),
      child: ExcludeSemantics(
        child: Center(
          key: LumeAuthKeys.visual,
          child: FadeTransition(
            opacity: curve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.72, end: 1).animate(curve),
              child: SizedBox.square(
                key: LumeAuthKeys.seal,
                dimension: size,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    // The ring, and the hairline that sits 10 outside it.
                    Positioned(
                      left: -LumeAuthMetrics.sealRingOutset,
                      right: -LumeAuthMetrics.sealRingOutset,
                      top: -LumeAuthMetrics.sealRingOutset,
                      bottom: -LumeAuthMetrics.sealRingOutset,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ringEdge,
                            width: LumeSpace.border,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ringFill,
                        ),
                      ),
                    ),
                    Container(
                      width: LumeAuthMetrics.sealDisc,
                      height: LumeAuthMetrics.sealDisc,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: discFill,
                        border: discEdge == null
                            ? null
                            : Border.all(
                                color: discEdge,
                                width: LumeSpace.border,
                              ),
                        boxShadow: widget.tone == LumeSealTone.bright
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: lume.accent.withValues(alpha: 0.38),
                                  blurRadius: 30,
                                  spreadRadius: -14,
                                  offset: const Offset(0, 12),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: LumeIcon(
                          widget.icon,
                          size: LumeAuthMetrics.sealIcon,
                          color: glyph,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 6,
                      end: 10,
                      child: _Spark(colour: glyphSpark(lume, widget.tone)),
                    ),
                    PositionedDirectional(
                      bottom: 14,
                      start: 6,
                      child: _Spark(colour: glyphSpark(lume, widget.tone)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color glyphSpark(LumeColors lume, LumeSealTone tone) =>
      tone == LumeSealTone.warn ? lume.amber : lume.accent;
}

class _Spark extends StatelessWidget {
  const _Spark({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.55,
    child: LumeIcon(
      LumeIcons.sparkles,
      size: LumeAuthMetrics.sealSpark,
      color: colour,
    ),
  );
}

/// The primary action.
///
/// **It never changes size when it starts working.** The label changes, the
/// arrow becomes a spinner, and the box stays 54 tall and full width — so
/// nothing under the user's thumb moves at the moment they have just pressed.
class LumeAuthSubmit extends StatelessWidget {
  const LumeAuthSubmit({
    super.key,
    required this.label,
    required this.onPressed,
    this.busyLabel,
    this.busy = false,
  });

  final String label;
  final String? busyLabel;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color ground = busy
        ? Color.lerp(lume.accent, lume.card, 0.18)!
        : lume.accent;

    return LumePressable(
      key: LumeAuthKeys.submit,
      onTap: busy ? null : onPressed,
      semanticLabel: busy ? (busyLabel ?? label) : label,
      borderRadius: BorderRadius.circular(LumeAuthMetrics.submitRadius),
      minSize: LumeAuthMetrics.submitHeight,
      child: AnimatedContainer(
        duration: LumeMotion.fast,
        curve: LumeMotion.easeOut,
        height: LumeAuthMetrics.submitHeight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(LumeAuthMetrics.submitRadius),
          boxShadow: busy
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: lume.accent.withValues(alpha: 0.9),
                    blurRadius: 26,
                    spreadRadius: -14,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (busy) ...<Widget>[
              SizedBox.square(
                dimension: LumeAuthMetrics.spinner,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: lume.onAccent,
                  backgroundColor: lume.onAccent.withValues(alpha: 0.28),
                ),
              ),
              const SizedBox(width: LumeSpace.x2),
            ],
            Flexible(
              child: Text(
                busy ? (busyLabel ?? label) : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LumeAuthType.button(
                  context,
                ).copyWith(color: lume.onAccent),
              ),
            ),
            if (!busy) ...<Widget>[
              const SizedBox(width: LumeSpace.x2),
              LumeIcon(
                LumeIcons.arrowR,
                size: LumeAuthMetrics.submitArrow,
                color: lume.onAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The bordered alternative: "Continue as a guest", and where a federated
/// provider would sit if Lume had one.
class LumeAuthSecondary extends StatelessWidget {
  const LumeAuthSecondary({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return LumePressable(
      onTap: onPressed,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(LumeAuthMetrics.secondaryRadius),
      minSize: LumeAuthMetrics.secondaryHeight,
      child: Container(
        height: LumeAuthMetrics.secondaryHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: LumeSpace.x5),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: BorderRadius.circular(LumeAuthMetrics.secondaryRadius),
          border: Border.all(color: lume.border2, width: LumeSpace.border),
        ),
        child: Text(
          label,
          style: LumeAuthType.button(
            context,
          ).copyWith(fontSize: 14.5, letterSpacing: -0.2175, color: lume.text),
        ),
      ),
    );
  }
}

/// A footer link: a quiet question with an accented answer.
///
/// A link is a control, with a real target and a real press — 46 tall and the
/// full width, not a word in a sentence.
class LumeAuthLink extends StatelessWidget {
  const LumeAuthLink({
    super.key,
    required this.text,
    required this.onPressed,
    this.strong,
  });

  final String text;

  /// The half that carries the action's name.
  final String? strong;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle base = LumeAuthType.link(context);
    return LumePressable(
      onTap: onPressed,
      semanticLabel: strong == null ? text : '$text $strong',
      borderRadius: BorderRadius.circular(LumeAuthMetrics.secondaryRadius),
      minSize: LumeAuthMetrics.linkHeight,
      child: Container(
        height: LumeAuthMetrics.linkHeight,
        alignment: Alignment.center,
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              if (text.isNotEmpty)
                TextSpan(text: strong == null ? text : '$text '),
              if (strong != null)
                TextSpan(
                  // `.auth__link b { margin-inline-start: 5px }` — carried by
                  // the space above, so a link with no quiet half does not
                  // start with one.
                  text: strong,
                  style: base.copyWith(
                    fontWeight: FontWeight.w700,
                    color: LumeAuthType.linkAccent(context),
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
          style: base.copyWith(color: lume.text2),
          maxLines: 2,
        ),
      ),
    );
  }
}

/// A line that says something and does nothing. Not a control, so it has no
/// target and no role.
class LumeAuthQuietLine extends StatelessWidget {
  const LumeAuthQuietLine(this.text, {super.key, this.live = false});

  final String text;

  /// Announced as it changes — the resend countdown, and nothing else.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final Widget line = Padding(
      padding: const EdgeInsets.symmetric(vertical: LumeAuthMetrics.quietPad),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: LumeAuthType.caption(context),
      ),
    );
    return live ? Semantics(liveRegion: true, child: line) : line;
  }
}

/// The recovery link, at the end of the line of the field it belongs to.
class LumeAuthInlineLink extends StatelessWidget implements LumeAuthFormRow {
  const LumeAuthInlineLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  /// `margin-top: -4`. The link belongs to the field above it, and sits four
  /// points closer than the form's own rhythm would put it.
  @override
  double get gapAdjust => -4;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: LumePressable(
        key: LumeAuthKeys.inline,
        onTap: onPressed,
        semanticLabel: label,
        borderRadius: BorderRadius.circular(10),
        // No `alignment` on the box: a `Container` that is told to align
        // its child fills the width it is offered, and the link would sit
        // in the middle of the row rather than at the end of it.
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: (LumeSpace.tap - 19) / 2,
          ),
          child: Text(
            label,
            style: LumeAuthType.link(context).copyWith(
              fontWeight: FontWeight.w700,
              color: LumeAuthType.linkAccent(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// A form-level message: tinted, iconed and explained.
class LumeAuthMessage extends StatelessWidget {
  const LumeAuthMessage.error(this.text, {super.key}) : _tone = _Tone.error;
  const LumeAuthMessage.notice(this.text, {super.key}) : _tone = _Tone.notice;

  final String text;
  final _Tone _tone;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool error = _tone == _Tone.error;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: error ? LumeAuthKeys.formError : LumeAuthKeys.notice,
        padding: LumeAuthMetrics.messagePad,
        decoration: BoxDecoration(
          color: error
              ? Color.alphaBlend(lume.rose.withValues(alpha: 0.10), lume.card)
              : lume.tintAccent,
          borderRadius: BorderRadius.circular(LumeAuthMetrics.messageRadius),
          border: Border.all(
            color: error
                ? lume.rose.withValues(alpha: 0.26)
                : lume.accent.withValues(alpha: 0.24),
            width: LumeSpace.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: LumeIcon(
                error ? LumeIcons.alert : LumeIcons.lock,
                size: LumeAuthMetrics.messageIcon,
                color: error ? lume.rose : lume.accent,
              ),
            ),
            const SizedBox(width: LumeAuthMetrics.messageGap),
            Expanded(
              child: Text(
                text,
                style: LumeAuthType.caption(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, color: lume.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Tone { error, notice }

/// The strength meter. Advice, never a substitute for the rules beneath it.
class LumePasswordMeter extends StatelessWidget implements LumeAuthFormRow {
  const LumePasswordMeter({
    super.key,
    required this.strength,
    required this.label,
  });

  final LumePasswordStrength strength;
  final String label;

  /// `margin-top: 2`, on top of the form's own gap.
  @override
  double get gapAdjust => 2;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final int on = LumePasswordPolicy.segments(strength);
    final Color tone = switch (strength) {
      LumePasswordStrength.none => lume.tintNeutral,
      LumePasswordStrength.weak => lume.rose,
      LumePasswordStrength.fair => lume.amber,
      LumePasswordStrength.good => lume.sky,
      LumePasswordStrength.strong => lume.accent,
    };

    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 4,
            child: Row(
              children: <Widget>[
                for (int i = 1; i <= 4; i++) ...<Widget>[
                  if (i > 1) const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedContainer(
                      duration: LumeMotion.fast,
                      decoration: BoxDecoration(
                        color: i <= on ? tone : lume.tintNeutral,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: LumeAuthMetrics.brandGap),
        Text(
          label,
          style: context.lumeType.body.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 13 / 11,
            letterSpacing: -0.11,
            color: lume.text3,
          ),
        ),
      ],
    );
  }
}

/// The checklist. What it draws is what a submission enforces.
class LumePasswordRules extends StatelessWidget implements LumeAuthFormRow {
  const LumePasswordRules({
    super.key,
    required this.checks,
    required this.title,
    required this.labelFor,
  });

  final List<LumePasswordCheck> checks;
  final String title;
  final String Function(LumePasswordRule) labelFor;

  /// `margin-top: 2`, on top of the form's own gap.
  @override
  double get gapAdjust => 2;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: lume.card2,
        borderRadius: BorderRadius.circular(LumeRadius.sm),
        border: Border.all(color: lume.border, width: LumeSpace.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              // `text-transform: uppercase`.
              title.toUpperCase(),
              // The glyphs are capitals; the announcement is not.
              semanticsLabel: title,
              style: context.lumeType.body.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 13 / 11,
                letterSpacing: 0.22,
                color: lume.text3,
              ),
            ),
          ),
          for (final LumePasswordCheck c in checks) ...<Widget>[
            const SizedBox(height: 5),
            _Rule(check: c, label: labelFor(c.rule)),
          ],
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.check, required this.label});

  final LumePasswordCheck check;
  final String label;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      checked: check.met,
      // A rule is a statement about the password, not a control. Announcing
      // it as checked or not is the whole of its meaning; colour alone is
      // never the signal, and the mark is filled as well as tinted.
      enabled: true,
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: check.met ? lume.accent : null,
                border: Border.all(
                  color: check.met ? lume.accent : lume.border2,
                  width: 1.5,
                ),
              ),
              child: check.met
                  ? Center(
                      child: LumeIcon(
                        LumeIcons.check,
                        size: 9,
                        color: lume.onAccent,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: context.lumeType.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: check.met ? lume.text2 : lume.text3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The legal line under a sign-up, with the one link that opens a sheet.
///
/// **A sheet rather than a screen.** Leaving here would take the password the
/// user has just typed with it.
class LumeAuthLegal extends StatefulWidget {
  const LumeAuthLegal({
    super.key,
    required this.text,
    required this.linkLabel,
    required this.onPressed,
  });

  final String text;
  final String linkLabel;
  final VoidCallback? onPressed;

  @override
  State<LumeAuthLegal> createState() => _LumeAuthLegalState();
}

class _LumeAuthLegalState extends State<LumeAuthLegal> {
  late final TapGestureRecognizer _tap = TapGestureRecognizer()
    ..onTap = () => widget.onPressed?.call();

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle base = LumeAuthType.caption(
      context,
    ).copyWith(fontSize: 12, color: lume.text3);

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: '${widget.text} '),
          TextSpan(
            text: widget.linkLabel,
            style: base.copyWith(
              fontWeight: FontWeight.w700,
              color: LumeAuthType.linkAccent(context),
              decoration: TextDecoration.underline,
              decorationColor: LumeAuthType.linkAccent(context),
            ),
            recognizer: _tap,
            // An inline link inside running text cannot be 44 points tall
            // without breaking the paragraph it sits in. It is announced as a
            // link, and the same page is reachable at full size from
            // Profile → Privacy — see LUME_AUTH §7.
            semanticsLabel: widget.linkLabel,
            mouseCursor: SystemMouseCursors.click,
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: base,
    );
  }
}
