/// Status: the badge, the delta, the freshness marker and the source line.
///
/// One rule binds all four, and it is §101: **status is never carried by
/// colour alone.** A badge has a glyph, a delta has a direction arrow *and* a
/// sign, freshness has a dot whose shape differs as well as its colour. A
/// user who cannot separate rose from jade still reads every one of them.
///
/// Measured:
///
/// | | height | padding | radius | type |
/// |---|---|---|---|---|
/// | `.badge` | 16 | 2 7 | full | 10 / 700 / .005em |
/// | `.fresh` | 13 | — | — | 11 / 700 |
/// | `.srcline` | 12 | — | — | 10 / 500, 8 px gaps |
library;

import 'package:flutter/material.dart';

import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';

/// What a badge is saying.
enum LumeBadgeTone {
  /// No judgement — a category, a draft.
  neutral,

  /// Happening now.
  live,

  /// Done, paid, settled.
  ok,

  /// Needs attention but is not yet a failure.
  warn,

  /// Overdue.
  late_,

  /// Switched off, unavailable.
  off,

  /// Explanatory.
  info,
}

/// `.badge` — a short status pill.
class LumeBadge extends StatelessWidget {
  const LumeBadge({
    super.key,
    required this.label,
    this.tone = LumeBadgeTone.neutral,
  });

  final String label;
  final LumeBadgeTone tone;

  static const double height = 16;

  /// The glyph each tone carries, so the tone is legible without its colour.
  /// These are the reference's own `BADGE_GLYPH` table.
  static String? glyphFor(LumeBadgeTone tone) => switch (tone) {
    LumeBadgeTone.live => '●',
    LumeBadgeTone.ok => '✓',
    LumeBadgeTone.warn => '!',
    LumeBadgeTone.late_ => '▲',
    LumeBadgeTone.off => '—',
    LumeBadgeTone.info => 'i',
    LumeBadgeTone.neutral => null,
  };

  /// The pill's drawn width for [label] in [tone], at the reader's text size —
  /// for a line that has to decide whether a badge still fits beside a title.
  static double widthOf(
    BuildContext context,
    String label,
    LumeBadgeTone tone,
  ) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    double measure(String text, TextStyle style) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final double w = p.width;
      p.dispose();
      return w;
    }

    final String? glyph = glyphFor(tone);
    final double labelWidth = measure(
      label,
      LumeType.tracked(
        LumeType.natural(
          context,
          context.lumeType.metaSmall,
          size: 10,
        ).copyWith(fontWeight: FontWeight.w700),
        0.005,
      ),
    );
    final double glyphWidth = glyph == null
        ? 0
        : measure(
                glyph,
                LumeType.fit(
                  context,
                  context.lumeType.metaSmall,
                ).copyWith(fontSize: 11, height: 1),
              ) +
              4;
    return 7 + glyphWidth + labelWidth + 7;
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final (Color bg, Color fg) = switch (tone) {
      LumeBadgeTone.neutral => (lume.tintNeutral, lume.text3),
      LumeBadgeTone.live => (
        lume.accent.withValues(alpha: 0.16),
        lume.accentInk,
      ),
      // `.badge--ok { background: up 14%; color: var(--up) }`.
      LumeBadgeTone.ok => (lume.up.withValues(alpha: 0.14), lume.up),
      LumeBadgeTone.warn => (lume.amber.withValues(alpha: 0.20), lume.amberInk),
      LumeBadgeTone.late_ => (lume.rose.withValues(alpha: 0.18), lume.roseInk),
      LumeBadgeTone.off => (lume.tintNeutral, lume.text3),
      LumeBadgeTone.info => (lume.sky.withValues(alpha: 0.16), lume.sky),
    };

    final String? glyph = glyphFor(tone);

    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
        decoration: BoxDecoration(color: bg, borderRadius: LumeRadius.full),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (glyph != null) ...<Widget>[
              ExcludeSemantics(
                child: Text(
                  glyph,
                  // `.badge i { font-size: 11px; line-height: 1 }` — a glyph
                  // set on its own box, so it does not decide the pill's
                  // height.
                  style: LumeType.fit(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: fg, fontSize: 11, height: 1),
                ),
              ),
              const SizedBox(width: 4),
            ],
            // Flexible, so a pill narrower than its words — a narrow row at
            // 200 % — ellipsizes rather than running past its edge.
            Flexible(
              child: Text(
                label,
                // `.badge` sets a size and leaves `line-height` alone, so the
                // line is the font's natural 12 rather than the `--t-metasm`
                // token's. With 2 points of padding above and below that is
                // the pill's measured 16; the token's line made it 19. See C35.
                style: LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                    size: 10,
                  ).copyWith(fontWeight: FontWeight.w700),
                  0.005,
                ).copyWith(color: fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Which way a value moved.
enum LumeDeltaDirection { up, down, flat }

/// `.delta` — a signed change.
///
/// The arrow is the point. A red number and a green number are the same number
/// to a lot of people; an arrow and a sign are not.
class LumeDelta extends StatelessWidget {
  const LumeDelta({
    super.key,
    required this.text,
    required this.direction,
    this.color,
    this.lineHeight,
  });

  /// A line the change inherits from where it is set — a summary caption's
  /// 1.45, which makes it 15.95 tall. `null` is the font's own 13.
  final double? lineHeight;

  /// The already-formatted change — "2.4 %", "−120".
  final String text;

  final LumeDeltaDirection direction;

  /// `.summary[class*="summary--"] .delta { color: inherit }` — on a
  /// gradient the change takes the card's ink; `null` is the direction's.
  final Color? color;

  /// The reference's own glyphs.
  static String glyphFor(LumeDeltaDirection d) => switch (d) {
    LumeDeltaDirection.up => '▲',
    LumeDeltaDirection.down => '▼',
    LumeDeltaDirection.flat => '—',
  };

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    // `--up` and `--down`, not the accent and the rose. Measured from the
    // rendered `.delta--up` / `.delta--down`: rgb(23, 145, 111) and
    // rgb(198, 72, 92). F2 read them off the brand ramp, which was two shades
    // too dark on one and a different hue on the other.
    final Color fg =
        color ??
        switch (direction) {
          LumeDeltaDirection.up => lume.up,
          LumeDeltaDirection.down => lume.down,
          LumeDeltaDirection.flat => lume.text3,
        };

    return Semantics(
      label:
          '${switch (direction) {
            LumeDeltaDirection.up => 'up',
            LumeDeltaDirection.down => 'down',
            LumeDeltaDirection.flat => 'unchanged',
          }} $text',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(glyphFor(direction), style: _glyphStyle(context, fg)),
            const SizedBox(width: gap),
            Text(
              _drawn,
              style: _textStyle(context, fg).copyWith(height: lineHeight),
            ),
          ],
        ),
      ),
    );
  }

  /// `.delta { gap: 3px }`.
  static const double gap = 3;

  /// `white-space: nowrap` collapses a run of spaces to one, as the
  /// reference's "+1,162  +0.42%" is drawn.
  String get _drawn => text.replaceAll(RegExp(r'\s+'), ' ');

  /// `.delta i` — 11 on a line of 1.
  static TextStyle _glyphStyle(BuildContext context, Color fg) =>
      LumeType.natural(
        context,
        context.lumeType.metaSmall,
        size: 11,
      ).copyWith(color: fg, height: 1);

  /// `.delta` — 11 / 700 / −.01em, tabular, on the font's own 13.
  static TextStyle _textStyle(BuildContext context, Color fg) =>
      LumeType.numeric(
        LumeType.tracked(
          LumeType.natural(context, context.lumeType.metaSmall, size: 11),
          -0.01,
        ),
      ).copyWith(color: fg, fontWeight: FontWeight.w700);

  /// How wide a change is drawn — for a table column that sizes itself to
  /// its widest cell, as `table-layout: auto` does.
  static double widthOf(
    BuildContext context,
    String text,
    LumeDeltaDirection direction,
  ) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection dir = Directionality.of(context);
    double w(String s, TextStyle style) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: dir,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final double width = p.width;
      p.dispose();
      return width;
    }

    const Color ink = Color(0xFF000000);
    return w(glyphFor(direction), _glyphStyle(context, ink)) +
        gap +
        w(
          LumeDelta(text: text, direction: direction)._drawn,
          _textStyle(context, ink),
        );
  }
}

/// How current a value is. §108: quality is never implied.
///
/// `computed` and `local` are the tool frame's own two (`engine.js`
/// `FRESH_TEXT`): a figure worked out for the reader's place, and a figure
/// that lives on the device. Each draws differently from the others.
enum LumeFreshnessQuality { live, delayed, cached, estimated, computed, local }

/// `.fresh` — a dot and a word saying how current the data is.
///
/// The live dot pulses, and **stops** when motion is reduced. An indefinite
/// animation has no end state to jump to, so it does not run at all rather
/// than running instantly — and it is what makes `pumpAndSettle` hang.
class LumeFreshness extends StatefulWidget {
  const LumeFreshness({
    super.key,
    required this.label,
    this.quality = LumeFreshnessQuality.live,
  });

  final String label;
  final LumeFreshnessQuality quality;

  @override
  State<LumeFreshness> createState() => _LumeFreshnessState();
}

class _LumeFreshnessState extends State<LumeFreshness>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  bool get _shouldPulse => widget.quality == LumeFreshnessQuality.live;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shouldPulse && LumeMotion.mayRepeat(context)) {
      _pulse ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    } else {
      _pulse?.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    // `.fresh--*` — measured: live is `--up`, delayed `--amber`, computed
    // `--sky`, and the rest the muted ink.
    final Color fg = switch (widget.quality) {
      LumeFreshnessQuality.live => lume.up,
      LumeFreshnessQuality.delayed => lume.amber,
      LumeFreshnessQuality.cached => lume.text3,
      LumeFreshnessQuality.estimated => lume.text3,
      LumeFreshnessQuality.computed => lume.sky,
      LumeFreshnessQuality.local => lume.text3,
    };

    // Shape carries the quality as well as colour (§101): a filled circle is
    // live, a filled square delayed, a hollow circle cached, a filled diamond
    // computed, a hollow rounded square local.
    final bool filled = switch (widget.quality) {
      LumeFreshnessQuality.live ||
      LumeFreshnessQuality.delayed ||
      LumeFreshnessQuality.computed => true,
      _ => false,
    };
    final BorderRadius? corners = switch (widget.quality) {
      LumeFreshnessQuality.delayed ||
      LumeFreshnessQuality.computed => BorderRadius.circular(1),
      LumeFreshnessQuality.local => BorderRadius.circular(2),
      _ => null,
    };

    Widget dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: filled ? fg : Colors.transparent,
        shape: corners == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: corners,
        border: filled ? null : Border.all(color: fg, width: 1.5),
      ),
    );
    if (widget.quality == LumeFreshnessQuality.computed) {
      dot = Transform.rotate(angle: 0.7853981633974483, child: dot);
    }

    if (_pulse != null) {
      dot = FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulse!),
        child: dot,
      );
    }

    return Semantics(
      label: widget.label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            dot,
            const SizedBox(width: 6),
            Text(
              widget.label,
              // 11 / 700 on the font's own 13, measured on `.fresh`.
              style: LumeType.natural(
                context,
                context.lumeType.metaSmall,
              ).copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.srcline` — where a value came from and when.
///
/// §19: a number without provenance is a number the user has to trust blindly.
class LumeSourceLine extends StatelessWidget {
  const LumeSourceLine({super.key, this.source, this.updated, this.note});

  final String? source;
  final String? updated;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final List<String> parts = <String?>[
      source,
      updated,
      note,
    ].whereType<String>().toList();
    // 10 / 500 on the font's own 12.
    final TextStyle style = LumeType.natural(
      context,
      context.lumeType.metaSmall,
      size: 10,
    ).copyWith(color: lume.text3);

    // `.srcline span + span::before { content: "·"; margin-inline-end: 8px;
    // opacity: .55 }` inside an 8-point gap — so every part after the first
    // leads with its separator.
    return Wrap(
      spacing: LumeSpace.x2,
      runSpacing: 2,
      children: <Widget>[
        for (int i = 0; i < parts.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (i > 0) ...<Widget>[
                Opacity(opacity: 0.55, child: Text('·', style: style)),
                const SizedBox(width: LumeSpace.x2),
              ],
              Text(parts[i], style: style),
            ],
          ),
      ],
    );
  }
}
