/// `.kard--reader` — one passage to read: its reference, its words, a line
/// about where it comes from, and what can be done with it.
///
/// Measured on Hadith (`tool_hadith_muslim_pk_*`): `20 18` of padding in a
/// one-point border at radius 16, over the card washed to `card-2`; the
/// reference 11 / 700 / .04em in capitals in the accent, on 13; the words 12
/// below, 15 / 500 / −.012em on 1.7; the metaline 14 below, 11 / 600 in
/// `text-3`, its parts at either end; the actions 18 below, sharing the width
/// 8 apart, 46 tall.
library;

import 'package:flutter/material.dart';

import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';

class LumeReaderCard extends StatelessWidget {
  const LumeReaderCard({
    super.key,
    required this.reference,
    required this.body,
    this.byline,
    this.badge,
    this.actions = const <Widget>[],
    this.bodyDirection,
  });

  /// "Sahih Muslim · 2609" — drawn in capitals, read as written.
  final String reference;

  /// The passage.
  final String body;

  /// The metaline's start — who narrated it, where it is from.
  final String? byline;

  /// The metaline's end — its grade.
  final Widget? badge;

  final List<Widget> actions;

  /// The passage's own direction, when it differs from the reader's — a
  /// passage kept in English under an Urdu interface reads left to right.
  final TextDirection? bodyDirection;

  static const Key referenceKey = ValueKey<String>('reader.ref');
  static const Key bodyKey = ValueKey<String>('reader.body');
  static const Key metaKey = ValueKey<String>('reader.meta');
  static const Key actionsKey = ValueKey<String>('reader.acts');

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle meta = LumeType.natural(
      context,
      context.lumeType.metaSmall,
    ).copyWith(color: lume.text3, fontWeight: FontWeight.w600);

    Widget passage = Text(
      body,
      key: bodyKey,
      style: LumeType.tracked(
        LumeType.fit(
          context,
          context.lumeType.body,
        ).copyWith(fontSize: 15, height: 1.7, fontWeight: FontWeight.w500),
        -0.012,
      ).copyWith(color: lume.text),
    );
    if (bodyDirection != null) {
      passage = Directionality(textDirection: bodyDirection!, child: passage);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: LumeRadius.brMd,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.xs,
        gradient: LinearGradient(
          // `linear-gradient(170deg, card, card-2)`.
          begin: const Alignment(-0.17, -1),
          end: const Alignment(0.17, 1),
          colors: <Color>[lume.card, lume.card2],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            label: reference,
            excludeSemantics: true,
            child: Text(
              reference.toUpperCase(),
              key: referenceKey,
              style: LumeType.tracked(
                LumeType.natural(
                  context,
                  context.lumeType.metaSmall,
                ).copyWith(fontWeight: FontWeight.w700),
                0.04,
              ).copyWith(color: lume.accent),
            ),
          ),
          const SizedBox(height: 12),
          passage,
          if (byline != null || badge != null) ...<Widget>[
            const SizedBox(height: 14),
            Wrap(
              key: metaKey,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: <Widget>[
                if (byline != null) Text(byline!, style: meta),
                ?badge,
              ],
            ),
          ],
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Row(
              key: actionsKey,
              children: <Widget>[
                for (int i = 0; i < actions.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
