/// Explore's seven drawings.
///
/// Six are lifted byte for byte out of `explore.screen.js` by
/// `gen_destination_art.mjs` — the two featured cards and the four collection
/// cards. The seventh is *painted*, because the reference paints it too: a
/// story's thumbnail is generated from a three-colour tone rather than drawn,
/// so reproducing it as seven static files would lose the thing that makes it
/// a system. Today's own sparkle lives beside Today, in `today_art.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/lume/lume_art_colours.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../domain/explore_model.dart';

const String _explore = 'assets/images/explore';

/// The featured card's full-bleed drawing.
///
/// `preserveAspectRatio="xMidYMid slice"` on a 350 × 216 canvas: it fills and
/// crops, which is [BoxFit.cover].
class LumeFeaturedArt extends StatelessWidget {
  const LumeFeaturedArt({super.key, required this.id});

  final LumeFeatureId id;

  String get asset =>
      '$_explore/featured_${id == LumeFeatureId.duas ? 'duas' : 'calm'}.svg';

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    fit: BoxFit.cover,
    alignment: Alignment.center,
    colorMapper: LumeArtColours(context.lume),
  );
}

/// A collection card's 148 × 84 drawing.
///
/// `preserveAspectRatio="none"`: it stretches to its box, which is
/// [BoxFit.fill]. The same rule the Discover strip's cards follow, and
/// getting it wrong is how artwork ends up letterboxed.
class LumeCollectionArt extends StatelessWidget {
  const LumeCollectionArt({super.key, required this.id});

  final String id;

  static const Map<String, String> _files = <String, String>{
    'nightSurahs': 'night_surahs',
    'focus': 'focus',
    'gratitude': 'gratitude',
    'budget': 'budget',
  };

  String get asset => '$_explore/collection_${_files[id] ?? id}.svg';

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    fit: BoxFit.fill,
    colorMapper: LumeArtColours(context.lume),
  );
}

/// A story's 62 × 62 thumbnail.
///
/// Painted rather than lifted. `renderNews` builds this inline from a tone —
/// three colours, a gradient, a disc and a wave — and writes a fresh gradient
/// id per story. Six static files would reproduce the output and lose the
/// rule; this reproduces the rule.
class LumeArticleArt extends StatelessWidget {
  const LumeArticleArt({super.key, required this.tone});

  final LumeArticleTone tone;

  /// `TONES` in `explore.screen.js`: a pale start, a deeper stop, and an ink
  /// for the two shapes at 30 per cent.
  static const Map<LumeArticleTone, (Color, Color, Color)> tones =
      <LumeArticleTone, (Color, Color, Color)>{
        LumeArticleTone.accent: (
          Color(0xFFE7F4F1),
          Color(0xFFA5DED4),
          Color(0xFF10998A),
        ),
        LumeArticleTone.violet: (
          Color(0xFFEDEAFB),
          Color(0xFFB7AEF6),
          Color(0xFF6E62E5),
        ),
        LumeArticleTone.amber: (
          Color(0xFFFBEEDD),
          Color(0xFFEFC894),
          Color(0xFFC9793F),
        ),
      };

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(62),
    painter: _ArticlePainter(tones[tone]!),
  );
}

class _ArticlePainter extends CustomPainter {
  const _ArticlePainter(this.tone);

  final (Color, Color, Color) tone;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 62;
    final Rect box = Offset.zero & size;

    canvas.drawRect(
      box,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[tone.$1, tone.$2],
        ).createShader(box),
    );

    final Paint ink = Paint()..color = tone.$3.withValues(alpha: 0.3);
    // `<circle cx="44" cy="18" r="12" opacity=".3"/>`
    canvas.drawCircle(Offset(44 * s, 18 * s), 12 * s, ink);
    // `<path d="M0 48c12-8 20 4 32-3s18-14 30-8v25H0z" opacity=".3"/>`
    final Path wave = Path()
      ..moveTo(0, 48 * s)
      ..cubicTo(12 * s, 40 * s, 20 * s, 52 * s, 32 * s, 45 * s)
      ..cubicTo(44 * s, 38 * s, 50 * s, 31 * s, 62 * s, 37 * s)
      ..lineTo(62 * s, 62 * s)
      ..lineTo(0, 62 * s)
      ..close();
    canvas.drawPath(wave, ink);
  }

  @override
  bool shouldRepaint(_ArticlePainter old) => old.tone != tone;
}
