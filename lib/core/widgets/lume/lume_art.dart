/// `.artimg` — the generated illustration an image card and a row thumbnail
/// lead with.
///
/// `components.js` `art()`: a 120 × 80 view box filled with the tone's two
/// stops from corner to corner, a white circle at 16 % and a dark one at 10 %
/// placed by the seed, and an optional glyph at the centre in white at 90 %.
/// The SVG is `preserveAspectRatio="xMidYMid slice"`, so the drawing covers
/// its box and is cropped rather than letterboxed. The same seed draws the
/// same picture, so a golden never flickers.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// `ART_TONES`.
enum LumeArtTone {
  accent(Color(0xFF10998A), Color(0xFF34B39D)),
  violet(Color(0xFF6E62E5), Color(0xFF9A90FF)),
  amber(Color(0xFFE0913A), Color(0xFFF0B96B)),
  rose(Color(0xFFDE6B7A), Color(0xFFF0919C)),
  sky(Color(0xFF3E9BD4), Color(0xFF6EBAE8)),
  indigo(Color(0xFF3D4BC7), Color(0xFF7E8AF0)),
  slate(Color(0xFF4A5560), Color(0xFF7C8794)),
  green(Color(0xFF3E9B62), Color(0xFF69C48C));

  const LumeArtTone(this.from, this.to);

  final Color from;
  final Color to;
}

class LumeArt extends StatelessWidget {
  const LumeArt({
    super.key,
    this.tone = LumeArtTone.accent,
    this.seed = 1,
    this.glyph,
  });

  final LumeArtTone tone;
  final int seed;
  final String? glyph;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: CustomPaint(
        painter: _ArtPainter(tone: tone, seed: seed, glyph: glyph),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _ArtPainter extends CustomPainter {
  const _ArtPainter({required this.tone, required this.seed, this.glyph});

  final LumeArtTone tone;
  final int seed;
  final String? glyph;

  static const Size _box = Size(120, 80);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // `xMidYMid slice` — cover, centred.
    final double scale = math.max(
      size.width / _box.width,
      size.height / _box.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - _box.width * scale) / 2,
      (size.height - _box.height * scale) / 2,
    );
    canvas.scale(scale);

    final Rect box = Offset.zero & _box;
    // `x1=0 y1=0 x2=1 y2=1` in the box's own units — corner to corner.
    canvas.drawRect(
      box,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[tone.from, tone.to],
        ).createShader(box),
    );

    final int s = seed == 0 ? 1 : seed;
    canvas.drawCircle(
      Offset(20.0 + s * 13 % 80, 18.0 + s * 7 % 40),
      16.0 + s * 5 % 18,
      Paint()..color = const Color(0x29FFFFFF),
    );
    canvas.drawCircle(
      Offset(80.0 + s * 11 % 30, 56.0 + s * 3 % 20),
      12.0 + s * 9 % 14,
      Paint()..color = const Color(0x1A000000),
    );

    if (glyph != null) {
      // `<text x="60" y="48" text-anchor="middle" font-size="28">` — the
      // baseline at 48, centred on 60.
      final TextPainter p = TextPainter(
        text: TextSpan(
          text: glyph,
          style: const TextStyle(fontSize: 28, color: Color(0xE6FFFFFF)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(
        canvas,
        Offset(
          60 - p.width / 2,
          48 - p.computeDistanceToActualBaseline(TextBaseline.alphabetic),
        ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.tone != tone || old.seed != seed || old.glyph != glyph;
}
