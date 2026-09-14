/// `.journey` — a trip from one end to the other, and how far along it is.
///
/// `components.js` `journey(o)`: the departure end, a track, and the arrival
/// end. Each end is 66 wide — the code 17 / 800 / −.04em on 22, the place
/// 10 / 600 on 12 one below, the time 12 / 700 tabular on 15 five below — so
/// an end is 55 tall. The track takes the rest, 12 from each end and 8 down,
/// 46 tall: a dashed two-point line 9 down (5 on, 5 off, `--border-2`), the
/// progress over it in the accent, the craft — a 20-point accent disc inside
/// a 4-point tint ring — centred on the progress point, and what is left
/// written 26 down, 10 / 600, centred.
///
/// In a right-to-left page the ends trade sides and the craft flies from the
/// start edge to the end edge, turned to face the way it goes; the codes and
/// times stay left-to-right (`.is-rtl .journey__end b, i { direction: ltr }`).
///
/// The reference's steps-and-dots journey that F2 invented has no `.journey`
/// of that shape in the stylesheet; this is the one the reference draws.
library;

import 'package:flutter/material.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';

class LumeJourney extends StatelessWidget {
  const LumeJourney({
    super.key,
    required this.fromCode,
    required this.from,
    required this.fromTime,
    required this.toCode,
    required this.to,
    required this.toTime,
    required this.remaining,
    required this.progress,
    this.icon = LumeIcons.plane,
  });

  final String fromCode;
  final String from;
  final String fromTime;
  final String toCode;
  final String to;
  final String toTime;

  /// What is left, already worded — "774 km to run".
  final String remaining;

  /// 0 at the start, 1 at the end; clamped.
  final double progress;

  final String icon;

  static const double endWidth = 66;
  static const double trackHeight = 46;
  static const double craftSize = 20;

  static const Key lineKey = ValueKey<String>('journey.line');
  static const Key progressKey = ValueKey<String>('journey.progress');
  static const Key craftKey = ValueKey<String>('journey.craft');
  static const Key trackKey = ValueKey<String>('journey.track');

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double p = progress.clamp(0, 1).toDouble();
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      container: true,
      label: '$fromCode $from $fromTime, $toCode $to $toTime',
      value: remaining,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: endWidth,
              child: _End(code: fromCode, place: from, time: fromTime),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  key: trackKey,
                  height: trackHeight,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      final double w = box.maxWidth;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 9,
                            height: 2,
                            child: CustomPaint(
                              key: lineKey,
                              painter: _DashPainter(lume.border2),
                            ),
                          ),
                          PositionedDirectional(
                            start: 0,
                            top: 9,
                            height: 2,
                            width: w * p,
                            child: DecoratedBox(
                              key: progressKey,
                              decoration: BoxDecoration(
                                color: lume.accent,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            start: w * p - craftSize / 2,
                            top: 0,
                            width: craftSize,
                            height: craftSize,
                            child: Container(
                              key: craftKey,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: lume.accent,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: lume.tintAccent,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Transform.flip(
                                flipX: rtl,
                                child: LumeIcon(
                                  icon,
                                  size: 11,
                                  color: lume.onAccent,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 26,
                            child: Text(
                              remaining,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  LumeType.natural(
                                    context,
                                    context.lumeType.metaSmall,
                                    size: 10,
                                  ).copyWith(
                                    color: lume.text3,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: endWidth,
              child: _End(code: toCode, place: to, time: toTime, end: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _End extends StatelessWidget {
  const _End({
    required this.code,
    required this.place,
    required this.time,
    this.end = false,
  });

  final String code;
  final String place;
  final String time;

  /// `.journey__end--to { text-align: end }`.
  final bool end;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextAlign align = end ? TextAlign.end : TextAlign.start;
    // An isolated left-to-right run that still sits at its end's edge.
    Widget ltr(String s, TextStyle style) => Align(
      alignment: end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Text(s, textDirection: TextDirection.ltr, style: style),
    );

    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ltr(
          code,
          LumeType.tracked(
            LumeType.natural(context, context.lumeType.cardTitle, size: 17),
            -0.04,
          ).copyWith(fontWeight: FontWeight.w800, color: lume.text),
        ),
        const SizedBox(height: 1),
        Text(
          place,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LumeType.natural(
            context,
            context.lumeType.metaSmall,
            size: 10,
          ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        ltr(
          time,
          LumeType.numeric(
            LumeType.natural(context, context.lumeType.label, size: 12),
          ).copyWith(fontWeight: FontWeight.w700, color: lume.text),
        ),
      ],
    );
  }
}

/// `repeating-linear-gradient(to right, border-2 0 5px, transparent 5px 10px)`
/// — physical, left to right, in either direction.
class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          0,
          (size.width - x).clamp(0, 5).toDouble(),
          size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
