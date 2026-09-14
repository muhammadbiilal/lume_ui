/// Lume's gradient colourways.
///
/// Reserved for hero surfaces, featured content, decoration and important
/// states. Most cards are flat; a gradient is a signal, and a product where
/// every card is colourful has no signals left.
///
/// Each colourway is two stops plus the ink that stays legible on it, and each
/// is **re-authored for dark rather than dimmed**: the dark pair drops in
/// luminance so it sits on `#0A0A0B` without glowing, and the ink is re-checked
/// against the lighter stop. Deriving the dark pair from the light one is what
/// produces the washed, floating gradients this file exists to avoid.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One colourway: two stops and the ink for them.
@immutable
class LumeGradient {
  const LumeGradient(this.a, this.b, this.on, this.onDim);

  /// The first stop — the darker end in both themes.
  final Color a;

  /// The second stop.
  final Color b;

  /// Primary ink on this surface.
  final Color on;

  /// Secondary ink — captions and supporting lines.
  final Color onDim;

  /// The CSS is `linear-gradient(150deg, a, b)`. In CSS, 0deg points up and
  /// the angle turns clockwise, so 150deg runs from the top-left down towards
  /// the bottom-right, tilted past the diagonal.
  LinearGradient get linear => LinearGradient(
    begin: const Alignment(-0.5, -1),
    end: const Alignment(0.5, 1),
    colors: <Color>[a, b],
  );

  /// `linear-gradient(<degrees>deg, a, b)` on a box of [size], exactly as CSS
  /// lays it: the gradient line runs through the centre at [degrees]
  /// (clockwise from up) and is long enough that the corners take the end
  /// colours. An [Alignment] is relative to each axis, so a non-square box
  /// needs its size to land the ends where the browser does.
  LinearGradient css(double degrees, Size size) {
    final double t = degrees * math.pi / 180;
    final double sx = math.sin(t), cy = -math.cos(t);
    final double half = (size.width * sx.abs() + size.height * cy.abs()) / 2;
    final double ax = size.width == 0 ? 0 : half * sx / (size.width / 2);
    final double ay = size.height == 0 ? 0 : half * cy / (size.height / 2);
    return LinearGradient(
      begin: Alignment(-ax, -ay),
      end: Alignment(ax, ay),
      colors: <Color>[a, b],
    );
  }

  /// The same pair as a plain top-to-bottom fill, for surfaces that carry a
  /// gradient as a ground rather than as a shape.
  LinearGradient get vertical => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[a, b],
  );
}

/// The gradient half of the design system.
@immutable
class LumeGradients extends ThemeExtension<LumeGradients> {
  const LumeGradients({
    required this.accent,
    required this.prayer,
    required this.night,
    required this.gold,
    required this.sky,
    required this.flame,
    required this.lock,
    required this.sport,
    required this.warn,
    required this.sos,
    required this.scan,
  });

  /// The brand colourway — the default for a featured surface.
  final LumeGradient accent;

  /// Prayer and other time-of-day content.
  final LumeGradient night;
  final LumeGradient prayer;

  /// Rates and precious metals.
  final LumeGradient gold;

  /// Weather and travel.
  final LumeGradient sky;

  /// Heat, streaks, Ramadan.
  final LumeGradient flame;

  /// Security and private surfaces.
  final LumeGradient lock;

  /// Sport and live scores.
  final LumeGradient sport;

  /// Warnings that are not failures.
  final LumeGradient warn;

  /// Emergency.
  final LumeGradient sos;

  /// Scanners and camera surfaces.
  final LumeGradient scan;

  // `--on-grad` / `--on-grad-dim`.
  static const Color _onLight = Color(0xFFFFFFFF);
  static const Color _onDimLight = Color(0xD1FFFFFF); // rgba(255,255,255,.82)
  static const Color _onDark = Color(0xFFF4F6F5);
  static const Color _onDimDark = Color(0xCCF4F6F5); // rgba(244,246,245,.80)

  /// `tokens.css` `:root`.
  static const LumeGradients light = LumeGradients(
    accent: LumeGradient(
      Color(0xFF0B7F73),
      Color(0xFF23A894),
      _onLight,
      _onDimLight,
    ),
    prayer: LumeGradient(
      Color(0xFF0B4F63),
      Color(0xFF10998A),
      _onLight,
      _onDimLight,
    ),
    night: LumeGradient(
      Color(0xFF1F2352),
      Color(0xFF4B3E8E),
      _onLight,
      _onDimLight,
    ),
    gold: LumeGradient(
      Color(0xFF5E4110),
      Color(0xFF8A6420),
      _onLight,
      _onDimLight,
    ),
    sky: LumeGradient(
      Color(0xFF1F5680),
      Color(0xFF3E86BB),
      _onLight,
      _onDimLight,
    ),
    flame: LumeGradient(
      Color(0xFF8A3A16),
      Color(0xFFB36A22),
      _onLight,
      _onDimLight,
    ),
    lock: LumeGradient(
      Color(0xFF2E3440),
      Color(0xFF55606F),
      _onLight,
      _onDimLight,
    ),
    sport: LumeGradient(
      Color(0xFF14513A),
      Color(0xFF2E8F63),
      _onLight,
      _onDimLight,
    ),
    warn: LumeGradient(
      Color(0xFF7A3A14),
      Color(0xFFA8672C),
      _onLight,
      _onDimLight,
    ),
    sos: LumeGradient(
      Color(0xFF8E1B2E),
      Color(0xFFB83D48),
      _onLight,
      _onDimLight,
    ),
    scan: LumeGradient(
      Color(0xFF1A1D22),
      Color(0xFF2B3038),
      _onLight,
      _onDimLight,
    ),
  );

  /// `tokens.css` `[data-theme="dark"]`.
  static const LumeGradients dark = LumeGradients(
    accent: LumeGradient(
      Color(0xFF06463F),
      Color(0xFF0E6F63),
      _onDark,
      _onDimDark,
    ),
    prayer: LumeGradient(
      Color(0xFF072F3C),
      Color(0xFF0A6156),
      _onDark,
      _onDimDark,
    ),
    night: LumeGradient(
      Color(0xFF14163A),
      Color(0xFF2E2760),
      _onDark,
      _onDimDark,
    ),
    gold: LumeGradient(
      Color(0xFF3B2909),
      Color(0xFF5E4415),
      _onDark,
      _onDimDark,
    ),
    sky: LumeGradient(
      Color(0xFF133753),
      Color(0xFF24567A),
      _onDark,
      _onDimDark,
    ),
    flame: LumeGradient(
      Color(0xFF57240D),
      Color(0xFF7A4716),
      _onDark,
      _onDimDark,
    ),
    lock: LumeGradient(
      Color(0xFF1D222B),
      Color(0xFF364049),
      _onDark,
      _onDimDark,
    ),
    sport: LumeGradient(
      Color(0xFF0C3325),
      Color(0xFF1B5C40),
      _onDark,
      _onDimDark,
    ),
    warn: LumeGradient(
      Color(0xFF4E250D),
      Color(0xFF6F441D),
      _onDark,
      _onDimDark,
    ),
    sos: LumeGradient(
      Color(0xFF5C111E),
      Color(0xFF7C2831),
      _onDark,
      _onDimDark,
    ),
    scan: LumeGradient(
      Color(0xFF101216),
      Color(0xFF1B1F25),
      _onDark,
      _onDimDark,
    ),
  );

  /// Every colourway, keyed by the name the reference uses. Lets the gallery
  /// and the token tests walk the set rather than listing it twice.
  Map<String, LumeGradient> get all => <String, LumeGradient>{
    'accent': accent,
    'prayer': prayer,
    'night': night,
    'gold': gold,
    'sky': sky,
    'flame': flame,
    'lock': lock,
    'sport': sport,
    'warn': warn,
    'sos': sos,
    'scan': scan,
  };

  @override
  LumeGradients copyWith({
    LumeGradient? accent,
    LumeGradient? prayer,
    LumeGradient? night,
    LumeGradient? gold,
    LumeGradient? sky,
    LumeGradient? flame,
    LumeGradient? lock,
    LumeGradient? sport,
    LumeGradient? warn,
    LumeGradient? sos,
    LumeGradient? scan,
  }) {
    return LumeGradients(
      accent: accent ?? this.accent,
      prayer: prayer ?? this.prayer,
      night: night ?? this.night,
      gold: gold ?? this.gold,
      sky: sky ?? this.sky,
      flame: flame ?? this.flame,
      lock: lock ?? this.lock,
      sport: sport ?? this.sport,
      warn: warn ?? this.warn,
      sos: sos ?? this.sos,
      scan: scan ?? this.scan,
    );
  }

  @override
  LumeGradients lerp(ThemeExtension<LumeGradients>? other, double t) {
    if (other is! LumeGradients) return this;
    LumeGradient g(LumeGradient a, LumeGradient b) => LumeGradient(
      Color.lerp(a.a, b.a, t)!,
      Color.lerp(a.b, b.b, t)!,
      Color.lerp(a.on, b.on, t)!,
      Color.lerp(a.onDim, b.onDim, t)!,
    );
    return LumeGradients(
      accent: g(accent, other.accent),
      prayer: g(prayer, other.prayer),
      night: g(night, other.night),
      gold: g(gold, other.gold),
      sky: g(sky, other.sky),
      flame: g(flame, other.flame),
      lock: g(lock, other.lock),
      sport: g(sport, other.sport),
      warn: g(warn, other.warn),
      sos: g(sos, other.sos),
      scan: g(scan, other.scan),
    );
  }
}
