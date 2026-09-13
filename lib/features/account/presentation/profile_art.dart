/// Profile's one drawing.
///
/// `.phead__art` — two tinted discs and a four-point spark behind the identity
/// card, clipped by it. Painted rather than lifted, for the same reason
/// `LumeRailSearchArt` is: three shapes on a 350 × 150 canvas with
/// `preserveAspectRatio="xMidYMid slice"` is a rule, and a rule survives a
/// change of accent colour that a file would not.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';

/// The wash behind `.phead`.
class LumeProfileHeadArt extends StatelessWidget {
  const LumeProfileHeadArt({super.key});

  /// The canvas the reference draws on.
  static const Size canvas = Size(350, 150);

  /// `.phead__art { opacity: .85 }` — on the container, over everything in it.
  static const double wash = 0.85;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Opacity(
      opacity: wash,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: canvas.width,
          height: canvas.height,
          child: CustomPaint(
            painter: _HeadArtPainter(accent: lume.accent, violet: lume.violet),
          ),
        ),
      ),
    );
  }
}

class _HeadArtPainter extends CustomPainter {
  const _HeadArtPainter({required this.accent, required this.violet});

  final Color accent;
  final Color violet;

  @override
  void paint(Canvas canvas, Size size) {
    // `<circle cx="322" cy="12" r="58" fill="var(--accent)" opacity=".07"/>`
    canvas.drawCircle(
      const Offset(322, 12),
      58,
      Paint()..color = accent.withValues(alpha: 0.07),
    );
    // `<circle cx="26" cy="140" r="42" fill="var(--violet)" opacity=".06"/>`
    canvas.drawCircle(
      const Offset(26, 140),
      42,
      Paint()..color = violet.withValues(alpha: 0.06),
    );
    // `m286 30 2.4 5.8 …` — the reference's own path, relative throughout.
    final Path spark = Path()
      ..moveTo(286, 30)
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
  bool shouldRepaint(_HeadArtPainter old) =>
      old.accent != accent || old.violet != violet;
}
