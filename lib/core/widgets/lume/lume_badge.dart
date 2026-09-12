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

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final (Color bg, Color fg) = switch (tone) {
      LumeBadgeTone.neutral => (lume.tintNeutral, lume.text3),
      LumeBadgeTone.live => (
        lume.accent.withValues(alpha: 0.16),
        lume.accentInk,
      ),
      LumeBadgeTone.ok => (lume.accent.withValues(alpha: 0.14), lume.accent700),
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
                  style: LumeType.fit(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: fg, fontSize: 9),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: LumeType.tracked(
                LumeType.fit(
                  context,
                  context.lumeType.metaSmall,
                ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                0.005,
              ).copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
  const LumeDelta({super.key, required this.text, required this.direction});

  /// The already-formatted change — "2.4 %", "−120".
  final String text;

  final LumeDeltaDirection direction;

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
    final Color fg = switch (direction) {
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
            Text(
              glyphFor(direction),
              style: LumeType.fit(
                context,
                context.lumeType.metaSmall,
              ).copyWith(color: fg, fontSize: 9),
            ),
            const SizedBox(width: 3),
            Text(
              text,
              style: LumeType.numeric(
                LumeType.fit(context, context.lumeType.metaSmall),
              ).copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// How current a value is. §108: quality is never implied.
enum LumeFreshnessQuality { live, delayed, cached, estimated }

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
    final Color fg = switch (widget.quality) {
      LumeFreshnessQuality.live => lume.accent700,
      LumeFreshnessQuality.delayed => lume.amberInk,
      LumeFreshnessQuality.cached => lume.text3,
      LumeFreshnessQuality.estimated => lume.text3,
    };

    // Shape carries the quality as well as colour: live is filled, cached is
    // hollow, estimated is hollow and dashed-looking at this size.
    final bool filled =
        widget.quality == LumeFreshnessQuality.live ||
        widget.quality == LumeFreshnessQuality.delayed;

    Widget dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: filled ? fg : Colors.transparent,
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: fg, width: 1.5),
      ),
    );

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
              style: LumeType.fit(
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

    return Wrap(
      spacing: LumeSpace.x2,
      runSpacing: 2,
      children: <Widget>[
        for (final String p in parts)
          Text(
            p,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3, fontSize: 10),
          ),
      ],
    );
  }
}
