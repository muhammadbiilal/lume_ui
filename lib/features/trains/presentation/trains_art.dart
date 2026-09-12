/// Trains' one drawing.
///
/// `.railsearch__art` — two tinted discs and a four-point spark, behind the
/// route search and clipped by it. Painted rather than lifted: it is three
/// shapes on a 350 × 150 canvas with `preserveAspectRatio="xMidYMid slice"`,
/// which is a rule rather than an asset, and a rule survives a change of
/// accent colour that a file would not.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';

/// The wash behind `.railsearch`.
class LumeRailSearchArt extends StatelessWidget {
  const LumeRailSearchArt({super.key});

  /// The canvas the reference draws on.
  static const Size canvas = Size(350, 150);

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: canvas.width,
        height: canvas.height,
        child: CustomPaint(
          painter: _RailArtPainter(accent: lume.accent, indigo: lume.indigo),
        ),
      ),
    );
  }
}

class _RailArtPainter extends CustomPainter {
  const _RailArtPainter({required this.accent, required this.indigo});

  final Color accent;
  final Color indigo;

  @override
  void paint(Canvas canvas, Size size) {
    // `<circle cx="322" cy="10" r="54" fill="var(--accent)" opacity=".07"/>`
    canvas.drawCircle(
      const Offset(322, 10),
      54,
      Paint()..color = accent.withValues(alpha: 0.07),
    );
    // `<circle cx="300" cy="140" r="32" fill="var(--indigo)" opacity=".06"/>`
    canvas.drawCircle(
      const Offset(300, 140),
      32,
      Paint()..color = indigo.withValues(alpha: 0.06),
    );
    // The four-point spark, `m286 44 …` in the reference's own path.
    final Path spark = Path()
      ..moveTo(286, 44)
      ..relativeLineTo(2.4, 5.8)
      ..relativeLineTo(5.8, 2.4)
      ..relativeLineTo(-5.8, 2.4)
      ..relativeLineTo(-2.4, 5.8)
      ..relativeLineTo(-2.4, -5.8)
      ..relativeLineTo(-5.8, -2.4)
      ..relativeLineTo(5.8, -2.4)
      ..close();
    canvas.drawPath(spark, Paint()..color = accent.withValues(alpha: 0.22));
  }

  @override
  bool shouldRepaint(_RailArtPainter old) =>
      old.accent != accent || old.indigo != indigo;
}
