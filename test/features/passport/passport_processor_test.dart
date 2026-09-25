/// [LumePassportProcessor] — real pixel work, checked against real pixels.
///
/// Every fixture here is a PNG synthesised on the fly through `dart:ui`
/// (a flat-coloured rectangle at a chosen size), so the assertions below are
/// about what the processor actually drew, not about a bundled fixture file
/// this feature is not allowed to add (`pubspec.yaml`'s asset list is out of
/// this build's scope).
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/passport/data/passport_processor.dart';
import 'package:lume/features/passport/domain/passport_spec.dart';

/// A solid-colour PNG, [width] × [height].
Future<Uint8List> _pngOf(int width, int height) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF336699),
  );
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(width, height);
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<(int, int)> _decodedSize(Uint8List png) async {
  final ui.Codec codec = await ui.instantiateImageCodec(png);
  final ui.FrameInfo frame = await codec.getNextFrame();
  final (int, int) size = (frame.image.width, frame.image.height);
  frame.image.dispose();
  return size;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a landscape photo is centre-cropped and resized onto the US spec\'s '
      'exact 1200 × 1200 canvas', () async {
    final Uint8List source = await _pngOf(1600, 900);
    final Uint8List? out = await LumePassportProcessor.cropToSpec(
      source,
      LumePassportSpec.us,
    );
    expect(out, isNotNull);
    expect(await _decodedSize(out!), (1200, 1200));
  });

  test('a portrait photo resizes onto the reference default\'s 827 × 1063 '
      'canvas (35 × 45 mm at 600 dpi)', () async {
    final Uint8List source = await _pngOf(900, 1600);
    final Uint8List? out = await LumePassportProcessor.cropToSpec(
      source,
      LumePassportSpec.intl,
    );
    expect(out, isNotNull);
    expect(await _decodedSize(out!), (827, 1063));
  });

  test('a square source still lands on a non-square spec\'s own canvas', () async {
    final Uint8List source = await _pngOf(1000, 1000);
    final Uint8List? out = await LumePassportProcessor.cropToSpec(
      source,
      LumePassportSpec.intl,
    );
    expect(out, isNotNull);
    expect(await _decodedSize(out!), (827, 1063));
  });

  test('bytes that are not a decodable image answer null, not a throw', () async {
    final Uint8List garbage = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
    expect(
      await LumePassportProcessor.cropToSpec(garbage, LumePassportSpec.us),
      isNull,
    );
  });

  test('empty bytes answer null', () async {
    expect(
      await LumePassportProcessor.cropToSpec(
        Uint8List(0),
        LumePassportSpec.intl,
      ),
      isNull,
    );
  });
}
