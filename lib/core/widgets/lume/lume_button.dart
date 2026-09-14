/// Actions: the button in its four tones, the icon button, the text button,
/// the floating action, and a row of them.
///
/// Measured from the rendered prototype:
///
/// | | height | padding | radius | type |
/// |---|---|---|---|---|
/// | `.btn` | 46 | 0 20 | 12 | 14 / 700 / −0.022em |
/// | `.btn--sm` | 46 (min-height wins) | 8 12 | 12 | 12 / 700 |
/// | `.iconbtn` | 38 × 38 | — | 12 | — |
/// | `.textbtn` | 44 min | 0 10 | 8 | 15 / 700, accent-700 ink |
/// | `.fab` | 50 | 0 16 | full | 13 / 700 |
///
/// The small button keeping its 46 px height is the kind of thing only a
/// measurement catches: the padding shrinks but `min-height` does not, so
/// `.btn--sm` is a *narrower* button, not a shorter one.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_elevation.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// What a button is for, which decides how it looks.
enum LumeButtonTone {
  /// The one primary action of a screen. Filled jade.
  accent,

  /// Everything else. A neutral tinted surface.
  ghost,

  /// Irreversible or destructive. Rose ink on a rose surface.
  danger,

  /// `.btn--dangerghost` — the same ink on nothing, inside a rose hairline.
  /// The destructive action *inside* a danger block, where the block is
  /// already carrying the warning and a second filled surface would shout.
  dangerGhost,

  /// The default fill — near-black. Used where a screen has no accent action
  /// but still needs weight, as the onboarding footer does.
  solid,

  /// `.btn--danger` as `account.css` and the confirmation sheet draw it —
  /// solid rose ink, the one destructive press a sheet asks for.
  critical,

  /// `.sheet--confirm.is-warn .btn--danger` — amber, for leaving unsaved work
  /// rather than destroying saved work.
  warn,
}

/// `.btn`.
class LumeButton extends StatelessWidget {
  const LumeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.tone = LumeButtonTone.ghost,
    this.icon,
    this.trailingIcon,
    this.block = false,
    this.small = false,
    this.busy = false,
    this.busyLabel,
    this.semanticLabel,
  });

  const LumeButton.accent({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.block = false,
    this.small = false,
    this.busy = false,
    this.busyLabel,
    this.semanticLabel,
  }) : tone = LumeButtonTone.accent;

  /// `.btn--dangerghost`.
  const LumeButton.dangerGhost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.block = false,
    this.small = false,
    this.busy = false,
    this.busyLabel,
    this.semanticLabel,
  }) : tone = LumeButtonTone.dangerGhost;

  const LumeButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.block = false,
    this.small = false,
    this.busy = false,
    this.busyLabel,
    this.semanticLabel,
  }) : tone = LumeButtonTone.danger;

  final String label;

  /// `null` disables the button. A disabled action is not a missing one.
  final VoidCallback? onPressed;

  final LumeButtonTone tone;
  final String? icon;
  final String? trailingIcon;

  /// `.btn--block` — full width.
  final bool block;

  /// `.btn--sm` — tighter padding and smaller type. **Not** a shorter button.
  final bool small;

  /// A save in flight. The label is replaced by [busyLabel] and the button
  /// stops accepting taps, which is how duplicate submission is prevented.
  ///
  /// The size does not change: §7 asks that a busy action keep its label
  /// rather than collapse to a spinner, so the button does not move under the
  /// user's thumb while they are still touching it.
  final bool busy;
  final String? busyLabel;

  final String? semanticLabel;

  /// Measured: 46 px, and the floor even for the small variant.
  static const double height = 46;

  bool get _enabled => onPressed != null && !busy;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final (Color bg, Color fg, List<BoxShadow>? shadow) = switch (tone) {
      LumeButtonTone.accent => (
        lume.accent,
        lume.onAccent,
        LumeShadows.accent(lume.accent, isDark: context.isDark),
      ),
      LumeButtonTone.ghost => (lume.tintNeutral, lume.text, null),
      LumeButtonTone.danger => (
        Color.lerp(lume.card, lume.rose, 0.14)!,
        lume.roseInk,
        null,
      ),
      // `background: transparent` — the block around it is already carrying
      // the warning, and a second filled surface inside it would shout.
      LumeButtonTone.dangerGhost => (
        const Color(0x00000000),
        lume.roseInk,
        null,
      ),
      LumeButtonTone.solid => (lume.text, lume.bg, null),
      LumeButtonTone.critical => (
        lume.roseInk,
        lume.onRose,
        LumeShadows.accent(lume.roseInk, isDark: context.isDark),
      ),
      LumeButtonTone.warn => (lume.amber, lume.onAmber, null),
    };

    /// `.btn--dangerghost { border: 1px solid rose 34% }`. The only tone with
    /// an outline: the others are surfaces.
    final Border? outline = tone == LumeButtonTone.dangerGhost
        ? Border.all(
            color: lume.rose.withValues(alpha: 0.34),
            width: LumeSpace.border,
          )
        : null;

    final TextStyle style = LumeType.tracked(
      LumeType.fit(
        context,
        small ? context.lumeType.label : context.lumeType.body,
      ).copyWith(fontWeight: FontWeight.w700),
      small ? -0.022 : -0.022,
    ).copyWith(color: fg);

    final String shown = busy ? (busyLabel ?? label) : label;

    Widget content = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (busy) ...<Widget>[
          _BusyDot(color: fg),
          const SizedBox(width: 7),
        ] else if (icon != null) ...<Widget>[
          LumeIcon(icon!, size: 17, color: fg), // `.btn svg`
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Text(
            shown,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (trailingIcon != null) ...<Widget>[
          const SizedBox(width: 7),
          LumeIcon(trailingIcon!, size: 17, color: fg), // `.btn svg`
        ],
      ],
    );

    content = Container(
      constraints: const BoxConstraints(minHeight: height),
      width: block ? double.infinity : null,
      padding: small
          ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
          : const EdgeInsets.symmetric(horizontal: 20),
      // No `alignment:` — a Container with one and no explicit size expands to
      // fill whatever it is offered, which would make every non-block button as
      // tall as its parent. The Row centres the label instead.
      decoration: BoxDecoration(
        color: bg,
        borderRadius: LumeRadius.brSm,
        border: outline,
        boxShadow: _enabled ? shadow : null,
      ),
      child: content,
    );

    // Disabled is dimmed rather than recoloured, so the action stays
    // recognisable as the action it is.
    if (!_enabled) {
      content = Opacity(opacity: busy ? 0.72 : 0.4, child: content);
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      // The pressable below excludes the button's own text so it is not
      // announced twice — so the name has to be given here, or the button has
      // none. Found on a device in F6B (C84): TalkBack read "Button" for
      // every one of them.
      label: semanticLabel ?? label,
      // A screen reader should hear that a save is in progress, not just a
      // button whose label changed.
      liveRegion: busy,
      child: LumePressable(
        onTap: _enabled ? onPressed : null,
        enabled: _enabled,
        borderRadius: LumeRadius.brSm,
        minSize: height,
        excludeSemantics: true,
        button: true,
        child: content,
      ),
    );
  }
}

/// The spinner in a busy button — a dot that pulses rather than a ring that
/// spins, because it has to sit on a single line of text without changing the
/// button's height.
class _BusyDot extends StatefulWidget {
  const _BusyDot({required this.color});

  final Color color;

  @override
  State<_BusyDot> createState() => _BusyDotState();
}

class _BusyDotState extends State<_BusyDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Indefinite animation stops entirely when motion is reduced — it has no
    // end state to jump to, and it is what makes `pumpAndSettle` hang.
    if (LumeMotion.mayRepeat(context)) {
      _c ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat(reverse: true);
    } else {
      _c?.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (_c == null) return Opacity(opacity: 0.6, child: dot);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c!),
      child: dot,
    );
  }
}

/// `.iconbtn` — a 38 × 38 bordered square holding one glyph.
///
/// A label is required. An icon-only control with no accessible name is
/// unusable with a screen reader, and §9 names it.
class LumeIconButton extends StatelessWidget {
  const LumeIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.badge = false,
  });

  final String icon;

  /// The accessible name. Not optional.
  final String label;

  final VoidCallback? onPressed;

  /// `.iconbtn__badge` — an unread dot.
  final bool badge;

  static const double size = 38;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool enabled = onPressed != null;

    Widget box = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lume.card,
        borderRadius: LumeRadius.brSm,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.xs,
      ),
      child: LumeIcon(icon, size: 18, color: lume.text2),
    );

    if (badge) {
      box = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          box,
          PositionedDirectional(
            top: 7,
            end: 8,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: lume.accent,
                shape: BoxShape.circle,
                border: Border.all(color: lume.card, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    if (!enabled) box = Opacity(opacity: 0.4, child: box);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: LumePressable(
        onTap: onPressed,
        enabled: enabled,
        borderRadius: LumeRadius.brSm,
        // The box is 38, but the target is 44 — the two are allowed to differ,
        // and §9 only governs the target.
        minSize: LumeSpace.tap,
        excludeSemantics: true,
        child: Center(widthFactor: 1, child: box),
      ),
    );
  }
}

/// `.textbtn` — a named action in a toolbar.
///
/// Measured: 44 min-height, 0/10 padding, 8 px radius, 15 / 700, accent-700.
/// A record operation names itself in words because a glyph is not a promise.
class LumeTextButton extends StatelessWidget {
  const LumeTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.tone,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? icon;

  /// `aria-label` — "Add expense" for an action that reads "Add".
  final String? semanticLabel;

  /// Overrides the accent ink — a destructive text action uses `roseInk`.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color fg = tone ?? lume.accent700;
    final bool enabled = onPressed != null;

    Widget row = Container(
      constraints: const BoxConstraints(minHeight: LumeSpace.tap),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            LumeIcon(icon!, size: 17, color: fg), // `.btn svg`
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: LumeType.fit(
              context,
              context.lumeType.cardTitle,
            ).copyWith(color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (!enabled) row = Opacity(opacity: 0.4, child: row);

    return LumePressable(
      onTap: onPressed,
      enabled: enabled,
      borderRadius: LumeRadius.brXs,
      minSize: LumeSpace.tap,
      semanticLabel: semanticLabel,
      child: row,
    );
  }
}

/// `.fab` — 50 px tall, pill-shaped, jade, with an optional label.
class LumeFab extends StatelessWidget {
  const LumeFab({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.showLabel = false,
  });

  /// Always the accessible name, whether or not it is shown.
  final String label;

  final VoidCallback? onPressed;
  final String? icon;
  final bool showLabel;

  static const double height = 50;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: LumePressable(
        onTap: onPressed,
        borderRadius: LumeRadius.full,
        minSize: height,
        excludeSemantics: true,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: lume.accent,
            borderRadius: LumeRadius.full,
            boxShadow: LumeShadows.accent(lume.accent, isDark: context.isDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeIcon(
                icon ?? LumeIcons.plus,
                size: 19, // `.fab svg`
                color: lume.onAccent,
              ),
              if (showLabel) ...<Widget>[
                const SizedBox(width: 7),
                Text(
                  label,
                  style: LumeType.fit(
                    context,
                    context.lumeType.meta,
                  ).copyWith(color: lume.onAccent, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.btnrow` — buttons side by side, sharing the width.
class LumeButtonRow extends StatelessWidget {
  const LumeButtonRow({super.key, required this.children, this.expand = true});

  final List<Widget> children;

  /// Whether each button takes an equal share. False lets them size to content.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    if (!expand) {
      return Wrap(
        spacing: LumeSpace.x2,
        runSpacing: LumeSpace.x2,
        children: children,
      );
    }
    return Row(
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: LumeSpace.x2),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}
