/// Cropping and resizing a picked photo onto a passport spec's exact pixel
/// canvas.
///
/// This is real pixel work — decode, centre-crop to the target aspect ratio,
/// resize onto a canvas sized in real pixels for the spec's mm at its DPI,
/// re-encode — done entirely through `dart:ui`, the engine Flutter already
/// ships (`instantiateImageCodec`, a `PictureRecorder` canvas,
/// `Image.toByteData`). No image-manipulation package (the `image` package,
/// say) is a dependency of this app, and this build's own scope cannot add
/// one (`pubspec.yaml` is out of bounds) — `dart:ui` needed no such addition.
///
/// What a fuller port would still want and this does not attempt: face
/// detection to centre the crop on the subject rather than the frame
/// (the reference has none either — its own "capture"/"import" buttons only
/// toast and go nowhere), and an interactive drag/zoom crop before
/// committing to it. This processor always centre-crops, which is an honest
/// default, not a claim of either.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import '../domain/passport_spec.dart';

abstract final class LumePassportProcessor {
  /// Decodes [sourceBytes], centre-crops it to [spec]'s own aspect ratio and
  /// resizes the crop onto a canvas exactly [LumePassportSpec.widthPx] ×
  /// [LumePassportSpec.heightPx], and encodes the result as a PNG.
  ///
  /// `null` when [sourceBytes] is not an image the engine's codec can decode
  /// — a corrupt file, or a format it does not know.
  static Future<Uint8List?> cropToSpec(
    Uint8List sourceBytes,
    LumePassportSpec spec,
  ) async {
    ui.Image? source;
    ui.Image? out;
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(sourceBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      source = frame.image;
      if (source.width <= 0 || source.height <= 0) return null;

      // The canvas's own aspect ratio, not the spec's raw mm figures: the two
      // differ by a fraction of a pixel once mm is rounded to px (827 × 1063
      // is not exactly 35:45), and cropping to the canvas's real ratio is
      // what keeps the resize below from stretching the image at all.
      final double targetAspect = spec.widthPx / spec.heightPx;
      final double sourceAspect = source.width / source.height;

      final double cropWidth;
      final double cropHeight;
      if (sourceAspect > targetAspect) {
        cropHeight = source.height.toDouble();
        cropWidth = cropHeight * targetAspect;
      } else {
        cropWidth = source.width.toDouble();
        cropHeight = cropWidth / targetAspect;
      }
      final double left = (source.width - cropWidth) / 2;
      final double top = (source.height - cropHeight) / 2;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        source,
        ui.Rect.fromLTWH(left, top, cropWidth, cropHeight),
        ui.Rect.fromLTWH(0, 0, spec.widthPx.toDouble(), spec.heightPx.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final ui.Picture picture = recorder.endRecording();
      try {
        out = await picture.toImage(spec.widthPx, spec.heightPx);
        final ByteData? png = await out.toByteData(
          format: ui.ImageByteFormat.png,
        );
        return png?.buffer.asUint8List();
      } finally {
        picture.dispose();
      }
    } on Object {
      return null;
    } finally {
      source?.dispose();
      out?.dispose();
    }
  }
}
