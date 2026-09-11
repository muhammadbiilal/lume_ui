/// Lume's colour tokens — one light theme and one dark theme, and no screen
/// anywhere holds a colour literal.
///
/// Two rules are load-bearing and neither is negotiable.
///
/// **Dark is authored, not derived.** Every value in [LumeColors.dark] is a
/// colour someone chose for the dark ground, not the light value with its
/// luminance flipped. Computing one from the other produces a palette that
/// glows on `#0A0A0B` and loses the contrast the ink pairs exist to protect.
///
/// **Some roles need two tokens, not one.** A colour used as a *surface* and
/// the same colour used as *ink* are different jobs with different contrast
/// requirements, and three of Lume's hues fail one of the two jobs if they
/// share a token:
///
/// * rose carries white at 3.24:1 and reads on `card` at 3.24:1 — so
///   [onRose] (what sits on rose) and [roseInk] (rose as text) are separate.
/// * amber is worse: white on `#E0913A` is 2.1:1. [onAmber] is a deep ink and
///   [amberInk] darkens before it reads on `card`.
/// * accent flips by theme: white sits on the light jade, a deep ink sits on
///   the lighter dark-mode jade. [onAccent] carries that.
library;

import 'package:flutter/material.dart';

/// The colour half of the Lume design system.
///
/// Reach for it through `context.lume`, never through [Theme.of] directly.
@immutable
class LumeColors extends ThemeExtension<LumeColors> {
  const LumeColors({
    required this.accent50,
    required this.accent100,
    required this.accent200,
    required this.accent400,
    required this.accent,
    required this.accent600,
    required this.accent700,
    required this.accentInk,
    required this.onAccent,
    required this.violet,
    required this.indigo,
    required this.amber,
    required this.onAmber,
    required this.amberInk,
    required this.rose,
    required this.onRose,
    required this.roseInk,
    required this.sky,
    required this.bg,
    required this.bgSunk,
    required this.card,
    required this.card2,
    required this.cardHover,
    required this.text,
    required this.text2,
    required this.text3,
    required this.border,
    required this.border2,
    required this.overlay,
    required this.tintAccent,
    required this.tintNeutral,
    required this.stickerOpacity,
    required this.meshOpacity,
  });

  // ---- Brand accent (jade). The ramp every accented surface draws from.

  /// Soft highlight.
  final Color accent50;
  final Color accent100;
  final Color accent200;
  final Color accent400;

  /// The brand accent itself.
  final Color accent;
  final Color accent600;
  final Color accent700;

  /// Accent *as ink* — accent-coloured text. Not the same value as accent as a
  /// surface.
  final Color accentInk;

  /// What sits *on* the accent: a filled button's label, a selected chip's
  /// text. White in light, a deep ink in dark.
  final Color onAccent;

  // ---- Secondary hues. Illustration and category colour only, never a second
  // brand colour.

  final Color violet;
  final Color indigo;
  final Color amber;

  /// What sits *on* amber. White on light amber is 2.1:1, so this is a deep
  /// ink in both themes.
  final Color onAmber;

  /// Amber *as* text, darkened until it reads on [card].
  final Color amberInk;

  final Color rose;

  /// What sits *on* rose.
  final Color onRose;

  /// Rose *as* text.
  final Color roseInk;

  final Color sky;

  // ---- Neutral foundation.

  /// Page ground.
  final Color bg;

  /// A step below [bg] — the shell behind the page.
  final Color bgSunk;

  /// Card and sheet fill.
  final Color card;

  /// A card sitting on another card.
  final Color card2;

  /// A card under the pointer or a press.
  final Color cardHover;

  /// Primary text.
  final Color text;

  /// Secondary text.
  final Color text2;

  /// Muted text and metadata.
  final Color text3;

  /// Hairline between surfaces.
  final Color border;

  /// The stronger border — form fields, and anything that has to read as an
  /// editable boundary.
  final Color border2;

  /// Scrim behind sheets and dialogs.
  final Color overlay;

  // ---- Tinted surfaces.

  /// The selected/accented surface tint.
  final Color tintAccent;

  /// The neutral surface tint — ghost buttons, icon containers.
  final Color tintNeutral;

  // ---- Decorative intensity. Dark mode carries less of both.

  final double stickerOpacity;
  final double meshOpacity;

  /// `tokens.css` `:root`.
  static const LumeColors light = LumeColors(
    accent50: Color(0xFFE9F7F4),
    accent100: Color(0xFFCFEDE7),
    accent200: Color(0xFFA5DED4),
    accent400: Color(0xFF34B39D),
    accent: Color(0xFF10998A),
    accent600: Color(0xFF0B7F73),
    accent700: Color(0xFF086357),
    accentInk: Color(0xFF07564C),
    // `.btn--accent { color: #fff }`.
    onAccent: Color(0xFFFFFFFF),
    violet: Color(0xFF6E62E5),
    indigo: Color(0xFF3D4BC7),
    amber: Color(0xFFE0913A),
    onAmber: Color(0xFF2A1A06),
    amberInk: Color(0xFF8A5410),
    rose: Color(0xFFDE6B7A),
    onRose: Color(0xFFFFFFFF),
    roseInk: Color(0xFFA3323F),
    sky: Color(0xFF3E9BD4),
    bg: Color(0xFFF6F6F4),
    bgSunk: Color(0xFFEFEFEC),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFFAFAF9),
    cardHover: Color(0xFFF4F4F2),
    text: Color(0xFF101113),
    text2: Color(0xFF56585F),
    text3: Color(0xFF8B8D95),
    // rgba(16, 17, 19, .07)
    border: Color(0x12101113),
    // rgba(16, 17, 19, .12)
    border2: Color(0x1F101113),
    // rgba(16, 17, 19, .38)
    overlay: Color(0x61101113),
    tintAccent: Color(0xFFE7F4F1),
    tintNeutral: Color(0xFFF1F1EE),
    stickerOpacity: 1,
    meshOpacity: 0.55,
  );

  /// `tokens.css` `[data-theme="dark"]`.
  ///
  /// Authored, not derived. Compare it against [light] and note that the accent
  /// ramp inverts direction — 700 is the *lightest* jade here, because on a
  /// near-black ground the ink that reads is the pale one.
  static const LumeColors dark = LumeColors(
    accent50: Color(0xFF0C2B27),
    accent100: Color(0xFF103B35),
    accent200: Color(0xFF17564D),
    accent400: Color(0xFF2FC0A9),
    accent: Color(0xFF35CBB2),
    accent600: Color(0xFF58D8C2),
    accent700: Color(0xFF8AE7D7),
    accentInk: Color(0xFFB6F2E7),
    // `[data-theme="dark"] .btn--accent { color: #06231F }` — white glares on
    // the lighter dark-mode jade.
    onAccent: Color(0xFF06231F),
    violet: Color(0xFF9A90FF),
    indigo: Color(0xFF7E8AF0),
    amber: Color(0xFFEDB268),
    onAmber: Color(0xFF2A1A06),
    amberInk: Color(0xFFF0C48A),
    rose: Color(0xFFF0919C),
    onRose: Color(0xFF2A0E12),
    roseInk: Color(0xFFF0A3AD),
    sky: Color(0xFF6EBAE8),
    bg: Color(0xFF0A0A0B),
    bgSunk: Color(0xFF060607),
    card: Color(0xFF141416),
    card2: Color(0xFF191A1C),
    cardHover: Color(0xFF1E1F22),
    text: Color(0xFFF3F3F4),
    text2: Color(0xFFA2A4AB),
    text3: Color(0xFF74767D),
    // rgba(255, 255, 255, .075)
    border: Color(0x13FFFFFF),
    // rgba(255, 255, 255, .14)
    border2: Color(0x24FFFFFF),
    // rgba(0, 0, 0, .6)
    overlay: Color(0x99000000),
    tintAccent: Color(0xFF10312C),
    tintNeutral: Color(0xFF1C1D20),
    stickerOpacity: 0.72,
    meshOpacity: 0.35,
  );

  @override
  LumeColors copyWith({
    Color? accent50,
    Color? accent100,
    Color? accent200,
    Color? accent400,
    Color? accent,
    Color? accent600,
    Color? accent700,
    Color? accentInk,
    Color? onAccent,
    Color? violet,
    Color? indigo,
    Color? amber,
    Color? onAmber,
    Color? amberInk,
    Color? rose,
    Color? onRose,
    Color? roseInk,
    Color? sky,
    Color? bg,
    Color? bgSunk,
    Color? card,
    Color? card2,
    Color? cardHover,
    Color? text,
    Color? text2,
    Color? text3,
    Color? border,
    Color? border2,
    Color? overlay,
    Color? tintAccent,
    Color? tintNeutral,
    double? stickerOpacity,
    double? meshOpacity,
  }) {
    return LumeColors(
      accent50: accent50 ?? this.accent50,
      accent100: accent100 ?? this.accent100,
      accent200: accent200 ?? this.accent200,
      accent400: accent400 ?? this.accent400,
      accent: accent ?? this.accent,
      accent600: accent600 ?? this.accent600,
      accent700: accent700 ?? this.accent700,
      accentInk: accentInk ?? this.accentInk,
      onAccent: onAccent ?? this.onAccent,
      violet: violet ?? this.violet,
      indigo: indigo ?? this.indigo,
      amber: amber ?? this.amber,
      onAmber: onAmber ?? this.onAmber,
      amberInk: amberInk ?? this.amberInk,
      rose: rose ?? this.rose,
      onRose: onRose ?? this.onRose,
      roseInk: roseInk ?? this.roseInk,
      sky: sky ?? this.sky,
      bg: bg ?? this.bg,
      bgSunk: bgSunk ?? this.bgSunk,
      card: card ?? this.card,
      card2: card2 ?? this.card2,
      cardHover: cardHover ?? this.cardHover,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      border: border ?? this.border,
      border2: border2 ?? this.border2,
      overlay: overlay ?? this.overlay,
      tintAccent: tintAccent ?? this.tintAccent,
      tintNeutral: tintNeutral ?? this.tintNeutral,
      stickerOpacity: stickerOpacity ?? this.stickerOpacity,
      meshOpacity: meshOpacity ?? this.meshOpacity,
    );
  }

  @override
  LumeColors lerp(ThemeExtension<LumeColors>? other, double t) {
    if (other is! LumeColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return LumeColors(
      accent50: c(accent50, other.accent50),
      accent100: c(accent100, other.accent100),
      accent200: c(accent200, other.accent200),
      accent400: c(accent400, other.accent400),
      accent: c(accent, other.accent),
      accent600: c(accent600, other.accent600),
      accent700: c(accent700, other.accent700),
      accentInk: c(accentInk, other.accentInk),
      onAccent: c(onAccent, other.onAccent),
      violet: c(violet, other.violet),
      indigo: c(indigo, other.indigo),
      amber: c(amber, other.amber),
      onAmber: c(onAmber, other.onAmber),
      amberInk: c(amberInk, other.amberInk),
      rose: c(rose, other.rose),
      onRose: c(onRose, other.onRose),
      roseInk: c(roseInk, other.roseInk),
      sky: c(sky, other.sky),
      bg: c(bg, other.bg),
      bgSunk: c(bgSunk, other.bgSunk),
      card: c(card, other.card),
      card2: c(card2, other.card2),
      cardHover: c(cardHover, other.cardHover),
      text: c(text, other.text),
      text2: c(text2, other.text2),
      text3: c(text3, other.text3),
      border: c(border, other.border),
      border2: c(border2, other.border2),
      overlay: c(overlay, other.overlay),
      tintAccent: c(tintAccent, other.tintAccent),
      tintNeutral: c(tintNeutral, other.tintNeutral),
      stickerOpacity: lerpDouble(stickerOpacity, other.stickerOpacity, t),
      meshOpacity: lerpDouble(meshOpacity, other.meshOpacity, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
