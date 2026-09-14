/// `.mgrid` — a month on a card.
///
/// `context.js` `monthGrid()`: a title, the seven weekday heads in the week's
/// own order, blank cells up to the first day, then every day of the month —
/// today filled with the accent, and for a Muslim reader the Hijri day under
/// each date.
///
/// Stylesheet: 16 of padding inside a one-point border, radius 20,
/// `shadow-sm`; the title 13 / 700 / −.026em, 12 above the grid; seven
/// columns 4 apart; heads 10 / 700 muted on 12 with 4 below; square cells of
/// radius 12, the date 12 / 600 in tabular figures and the Hijri day under it
/// 11 / 600 muted.
library;

import 'package:flutter/material.dart';

import '../../localization/lume_numerals.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// One day of the month.
@immutable
class LumeMonthDay {
  const LumeMonthDay({
    required this.label,
    required this.spoken,
    this.sub,
    this.today = false,
  });

  /// The date as drawn — "7".
  final String label;

  /// The date as a reader hears it — "Monday, 7 September".
  final String spoken;

  /// The Hijri day, where the reader has the Islamic experience.
  final String? sub;
  final bool today;
}

class LumeMonthGrid extends StatelessWidget {
  const LumeMonthGrid({
    super.key,
    required this.title,
    required this.heads,
    required this.leading,
    required this.days,
    this.subtitle,
    this.onDay,
  });

  /// "September 2026".
  final String title;

  /// " · Rabi‘ al-Awwal 1448", drawn muted after the title.
  final String? subtitle;

  /// The seven weekday heads, first day of the week first.
  final List<String> heads;

  /// Blank cells before the 1st.
  final int leading;
  final List<LumeMonthDay> days;

  /// `button.mgrid__cell` — each day is a button, and the reference's does
  /// nothing; a caller that has somewhere to go passes it. Every day is
  /// announced with its full date, and today as selected, tappable or not.
  final ValueChanged<int>? onDay;

  static const double gap = 4;
  static const Key todayKey = ValueKey<String>('mgrid.today');

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextStyle titleStyle = LumeType.tracked(
      LumeType.natural(context, context.lumeType.body, size: 13),
      -0.026,
    ).copyWith(fontWeight: FontWeight.w700, color: lume.text);

    final List<Widget> cells = <Widget>[
      for (final String h in heads)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            h,
            textAlign: TextAlign.center,
            style: LumeType.natural(
              context,
              context.lumeType.label,
              size: 10,
            ).copyWith(fontWeight: FontWeight.w700, color: lume.text3),
          ),
        ),
      for (int i = 0; i < leading; i++) const SizedBox.shrink(),
      for (int i = 0; i < days.length; i++)
        _Cell(day: days[i], index: i, onDay: onDay),
    ];

    final List<Widget> rows = <Widget>[];
    for (int start = 0; start < cells.length; start += 7) {
      final int end = start + 7 > cells.length ? cells.length : start + 7;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: start == 0 ? 0 : gap),
          child: Row(
            crossAxisAlignment: start == 0
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = start; i < start + 7; i++) ...<Widget>[
                if (i > start) const SizedBox(width: gap),
                Expanded(child: i < end ? cells[i] : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16 + LumeSpace.border),
      decoration: BoxDecoration(
        color: lume.card,
        borderRadius: LumeRadius.brLg,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                text: title,
                children: <InlineSpan>[
                  if (subtitle != null)
                    TextSpan(
                      text: subtitle,
                      style: titleStyle.copyWith(
                        color: lume.text3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              style: titleStyle,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.day, required this.index, this.onDay});

  final LumeMonthDay day;
  final int index;
  final ValueChanged<int>? onDay;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color ink = day.today ? lume.onAccent : lume.text;
    return LumePressable(
      onTap: onDay == null ? null : () => onDay!(index),
      borderRadius: LumeRadius.brIcon,
      minSize: 0,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: day.today ? lume.accent : null,
            borderRadius: LumeRadius.brIcon,
          ),
          child: Semantics(
            key: day.today ? LumeMonthGrid.todayKey : null,
            container: true,
            label: day.spoken,
            selected: day.today,
            excludeSemantics: true,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LumeNumerals(
                    day.label,
                    style: LumeType.numeric(
                      LumeType.natural(
                        context,
                        context.lumeType.label,
                        size: 12,
                      ),
                    ).copyWith(fontWeight: FontWeight.w600, color: ink),
                  ),
                  if (day.sub != null)
                    LumeNumerals(
                      day.sub!,
                      style:
                          LumeType.numeric(
                            LumeType.natural(
                              context,
                              context.lumeType.label,
                              size: 11,
                            ),
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            color: day.today
                                ? lume.onAccent.withValues(alpha: 0.76)
                                : lume.text3,
                          ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
