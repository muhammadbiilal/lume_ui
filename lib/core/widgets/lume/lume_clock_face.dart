/// `.clockface` — a running clock's time, its hint and its two actions.
///
/// `shared/clock.js` `clockScreen`, drawn by Timer and Stopwatch. Stylesheet:
/// 28 above and 4 below inside the page gutter; 14 between the parts, the
/// hint pulled 8 closer; the time 58 / 800 / −0.055em in tabular figures; the
/// hint 12 / 600, muted; the actions 8 apart.
library;

import 'package:flutter/material.dart';

import '../../layout/lume_breakpoint.dart';
import '../../layout/lume_measure.dart';
import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';

class LumeClockFace extends StatelessWidget {
  const LumeClockFace({
    super.key,
    required this.display,
    required this.primary,
    required this.reset,
    this.hint,
    this.timeKey,
  });

  final String display;
  final String? hint;
  final Widget primary;
  final Widget reset;

  /// The key on the time itself, for a tool's tests.
  final Key? timeKey;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // A live region, so a reader hears the time it changes to — and
          // `.is-rtl .clockface__time { direction: ltr }`.
          Semantics(
            liveRegion: true,
            child: LumeNumerals(
              display,
              key: timeKey,
              style: LumeType.numeric(
                LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.display,
                    size: 58,
                  ).copyWith(fontWeight: FontWeight.w800),
                  -0.055,
                ),
              ).copyWith(color: lume.text),
            ),
          ),
          if (hint != null) ...<Widget>[
            const SizedBox(height: 14 - 8),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: LumeType.natural(
                context,
                context.lumeType.meta,
              ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[primary, const SizedBox(width: 8), reset],
          ),
        ],
      ),
    );
  }
}
