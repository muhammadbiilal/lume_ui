/// Lume's elevation — four shadows, authored separately for each theme.
///
/// CSS and Flutter do not measure blur the same way. A CSS `box-shadow`'s blur
/// radius is roughly **twice** Flutter's `blurRadius` for the same visual
/// softness, so every value here is the CSS number halved. Getting that wrong
/// is the single most common reason a ported card looks like it is floating.
///
/// A CSS shadow with two layers becomes two [BoxShadow]s in the same order.
/// Negative CSS spread becomes a negative `spreadRadius`.
///
/// §5: LG is for sheets and overlays only. A card that reaches for it has
/// mistaken emphasis for importance.
library;

import 'package:flutter/material.dart';

/// The elevation half of the design system.
@immutable
class LumeShadows extends ThemeExtension<LumeShadows> {
  const LumeShadows({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.nav,
  });

  /// `--shadow-xs` — a row, a chip, anything barely lifted.
  final List<BoxShadow> xs;

  /// `--shadow-sm` — the standard card.
  final List<BoxShadow> sm;

  /// `--shadow-md` — a raised card, a popover.
  final List<BoxShadow> md;

  /// `--shadow-lg` — sheets and overlays only.
  final List<BoxShadow> lg;

  /// `--shadow-nav` — the bottom bar. Casts *upward*, and its first layer is a
  /// hairline rather than a blur.
  final List<BoxShadow> nav;

  // The light theme's shadow ink, rgb(16, 24, 40).
  static const Color _ink = Color(0xFF101828);

  static BoxShadow _b({
    double dy = 0,
    required double cssBlur,
    double spread = 0,
    required Color color,
  }) => BoxShadow(
    color: color,
    offset: Offset(0, dy),
    // CSS blur is about twice Flutter's for the same softness.
    blurRadius: cssBlur / 2,
    spreadRadius: spread,
  );

  /// `tokens.css` `:root`.
  static final LumeShadows light = LumeShadows(
    // 0 1px 2px rgba(16,24,40,.05)
    xs: <BoxShadow>[_b(dy: 1, cssBlur: 2, color: _ink.withValues(alpha: 0.05))],
    // 0 1px 2px rgba(16,24,40,.04), 0 2px 6px -2px rgba(16,24,40,.06)
    sm: <BoxShadow>[
      _b(dy: 1, cssBlur: 2, color: _ink.withValues(alpha: 0.04)),
      _b(dy: 2, cssBlur: 6, spread: -2, color: _ink.withValues(alpha: 0.06)),
    ],
    // 0 2px 4px -2px rgba(16,24,40,.05), 0 8px 20px -6px rgba(16,24,40,.10)
    md: <BoxShadow>[
      _b(dy: 2, cssBlur: 4, spread: -2, color: _ink.withValues(alpha: 0.05)),
      _b(dy: 8, cssBlur: 20, spread: -6, color: _ink.withValues(alpha: 0.10)),
    ],
    // 0 8px 16px -8px rgba(16,24,40,.10), 0 24px 48px -16px rgba(16,24,40,.20)
    lg: <BoxShadow>[
      _b(dy: 8, cssBlur: 16, spread: -8, color: _ink.withValues(alpha: 0.10)),
      _b(dy: 24, cssBlur: 48, spread: -16, color: _ink.withValues(alpha: 0.20)),
    ],
    // 0 -1px 0 var(--border), 0 -8px 32px -12px rgba(16,24,40,.16)
    nav: <BoxShadow>[
      _b(dy: -1, cssBlur: 0, color: const Color(0x12101113)),
      _b(dy: -8, cssBlur: 32, spread: -12, color: _ink.withValues(alpha: 0.16)),
    ],
  );

  /// `tokens.css` `[data-theme="dark"]`.
  ///
  /// Not the light shadows at a higher opacity — a dark surface needs a deeper,
  /// blacker shadow to read as lifted at all, and these are authored for that.
  static final LumeShadows dark = LumeShadows(
    xs: <BoxShadow>[
      _b(
        dy: 1,
        cssBlur: 2,
        color: const Color(0xFF000000).withValues(alpha: 0.5),
      ),
    ],
    sm: <BoxShadow>[
      _b(
        dy: 1,
        cssBlur: 2,
        color: const Color(0xFF000000).withValues(alpha: 0.4),
      ),
      _b(
        dy: 2,
        cssBlur: 6,
        spread: -2,
        color: const Color(0xFF000000).withValues(alpha: 0.5),
      ),
    ],
    md: <BoxShadow>[
      _b(
        dy: 2,
        cssBlur: 4,
        spread: -2,
        color: const Color(0xFF000000).withValues(alpha: 0.4),
      ),
      _b(
        dy: 8,
        cssBlur: 20,
        spread: -6,
        color: const Color(0xFF000000).withValues(alpha: 0.55),
      ),
    ],
    lg: <BoxShadow>[
      _b(
        dy: 8,
        cssBlur: 16,
        spread: -8,
        color: const Color(0xFF000000).withValues(alpha: 0.5),
      ),
      _b(
        dy: 24,
        cssBlur: 48,
        spread: -16,
        color: const Color(0xFF000000).withValues(alpha: 0.7),
      ),
    ],
    nav: <BoxShadow>[
      _b(dy: -1, cssBlur: 0, color: const Color(0x13FFFFFF)),
      _b(
        dy: -8,
        cssBlur: 32,
        spread: -12,
        color: const Color(0xFF000000).withValues(alpha: 0.8),
      ),
    ],
  );

  /// `--shadow-accent` — the glow under a filled accent button. Derived from
  /// the live accent rather than frozen, because the accent differs by theme.
  static List<BoxShadow> accent(Color accentColor, {bool isDark = false}) =>
      <BoxShadow>[
        _b(
          dy: 6,
          cssBlur: 18,
          spread: -8,
          color: accentColor.withValues(alpha: isDark ? 0.55 : 0.80),
        ),
      ];

  Map<String, List<BoxShadow>> get all => <String, List<BoxShadow>>{
    'xs': xs,
    'sm': sm,
    'md': md,
    'lg': lg,
    'nav': nav,
  };

  @override
  LumeShadows copyWith({
    List<BoxShadow>? xs,
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    List<BoxShadow>? nav,
  }) {
    return LumeShadows(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      nav: nav ?? this.nav,
    );
  }

  @override
  LumeShadows lerp(ThemeExtension<LumeShadows>? other, double t) {
    if (other is! LumeShadows) return this;
    List<BoxShadow> l(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? a;
    return LumeShadows(
      xs: l(xs, other.xs),
      sm: l(sm, other.sm),
      md: l(md, other.md),
      lg: l(lg, other.lg),
      nav: l(nav, other.nav),
    );
  }
}
