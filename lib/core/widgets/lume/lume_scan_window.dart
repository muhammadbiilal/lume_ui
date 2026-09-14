/// A scanner's window: the frame a code is held in.
///
/// `.scanner__frame { box-shadow: 0 0 0 2px white/.55, 0 0 0 999px black/.28 }`
/// — a CSS shadow is never painted under its own box, so the frame is a clear
/// window: everything outside a centred square at radius 16 is dimmed, and a
/// 2-point ring sits just outside its edge. QR Scanner's viewfinder and the
/// camera capture page both draw it.
library;

import 'package:flutter/rendering.dart';

class LumeScanWindow extends CustomPainter {
  const LumeScanWindow({required this.side});

  final double side;

  static const double radius = 16;

  @override
  void paint(Canvas canvas, Size box) {
    final Rect window = Rect.fromCenter(
      center: box.center(Offset.zero),
      width: side,
      height: side,
    );
    final RRect hole = RRect.fromRectAndRadius(
      window,
      const Radius.circular(radius),
    );
    final Path dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & box)
      ..addRRect(hole);
    canvas.drawPath(dim, Paint()..color = const Color(0x47000000));
    canvas.drawRRect(
      hole.inflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x8CFFFFFF),
    );
  }

  @override
  bool shouldRepaint(LumeScanWindow old) => old.side != side;
}
