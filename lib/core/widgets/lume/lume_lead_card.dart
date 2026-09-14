/// `.lead` — the story a feed leads with.
///
/// Stylesheet: the full width of its section, radius 20 with the art clipped
/// to it, the card fill inside a one-point border, `shadow-sm`; a 152-point
/// [LumeArt]; then `14 16 16` of body — the category 10 / 800 / .05em in
/// capitals and the accent, the title 17 / 700 / −.032em on a 1.28 line 6
/// below it, the meta 11 / 500 muted 8 below that.
library;

import 'package:flutter/material.dart';

import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_art.dart';
import 'lume_pressable.dart';

class LumeLeadCard extends StatelessWidget {
  const LumeLeadCard({
    super.key,
    required this.category,
    required this.title,
    required this.meta,
    this.tone = LumeArtTone.accent,
    this.seed = 1,
    this.onTap,
  });

  final String category;
  final String title;
  final String meta;
  final LumeArtTone tone;
  final int seed;
  final VoidCallback? onTap;

  static const double artHeight = 152;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: lume.card,
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LumeRadius.lg - LumeSpace.border),
        child: Padding(
          padding: const EdgeInsets.all(LumeSpace.border),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: artHeight,
                child: LumeArt(tone: tone, seed: seed),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // `.lead__cat { display: inline-block }` inside a block:
                    // it sits on a line box of the body's own 16-point font,
                    // its baseline on that line's — the line is 16's natural
                    // height, and the category's own box sits inside it.
                    _OnParentLine(
                      child: Text(
                        LumeType.overline(context, category),
                        style:
                            LumeType.tracked(
                              LumeType.natural(
                                context,
                                context.lumeType.label,
                                size: 10,
                              ),
                              0.05,
                            ).copyWith(
                              fontWeight: FontWeight.w800,
                              color: lume.accent,
                            ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: LumeType.fit(
                        context,
                        LumeType.tracked(
                          context.lumeType.body.copyWith(
                            fontSize: 17,
                            height: 1.28,
                            fontWeight: FontWeight.w700,
                          ),
                          -0.032,
                        ),
                      ).copyWith(color: lume.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meta,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                            size: 11,
                          ).copyWith(
                            fontWeight: FontWeight.w500,
                            color: lume.text3,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return LumePressable(
      onTap: onTap,
      button: false,
      semanticLabel: '$category. $title. $meta',
      borderRadius: LumeRadius.brLg,
      minSize: 0,
      child: card,
    );
  }
}

/// A child set on a line of the body's 16-point font, its baseline on that
/// line's — how CSS lays out an `inline-block` inside a block: the line is as
/// tall as 16 points on its natural line, and the child's own box sits where
/// its baseline meets the line's.
class _OnParentLine extends StatelessWidget {
  const _OnParentLine({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextPainter line = TextPainter(
      text: TextSpan(
        text: 'x',
        style: LumeType.natural(context, context.lumeType.body, size: 16),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final double height = line.height;
    final double baseline = line.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    line.dispose();
    return SizedBox(
      height: height,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Baseline(
          baseline: baseline,
          baselineType: TextBaseline.alphabetic,
          child: child,
        ),
      ),
    );
  }
}
