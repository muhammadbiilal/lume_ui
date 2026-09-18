/// The share sheet — `sheet-share` in `sheets-markup.js`.
///
/// "Share · Your card is ready", the card at up to 260 wide on a 20-point
/// radius with `shadow-md`, then **Save image** and **Share** in two equal
/// columns 8 apart. Each press renders the card to a 1080 × 1350 PNG and hands
/// it to the injected [LumeImageSaver] or [LumeSharer]; the toast says what the
/// platform reported and nothing it did not (D7). A dismissed share sheet says
/// nothing, as a closed share sheet should.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/platform_services.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_share_card.dart';
import '../../../l10n/app_localizations.dart';

Future<void> showLumeShareSheet({
  required BuildContext context,
  required LumeShareCard card,
}) => showLumeSheet<void>(
  context: context,
  barrierLabel: AppLocalizations.of(context).actionClose,
  child: LumeShareSheet(card: card),
);

class LumeShareSheet extends ConsumerStatefulWidget {
  const LumeShareSheet({super.key, required this.card});

  final LumeShareCard card;

  static const Key previewKey = ValueKey<String>('share.preview');
  static const Key saveKey = ValueKey<String>('share.save');
  static const Key sendKey = ValueKey<String>('share.send');

  /// `.sharecard canvas { max-width: 260px }`.
  static const double previewWidth = 260;

  @override
  ConsumerState<LumeShareSheet> createState() => LumeShareSheetState();
}

class LumeShareSheetState extends ConsumerState<LumeShareSheet> {
  final GlobalKey _boundary = GlobalKey();
  bool _busy = false;
  Future<void>? _pending;

  /// The render and save or share a press started, until it has said what
  /// became of it. A test awaits this rather than guessing how long a PNG
  /// takes to encode.
  @visibleForTesting
  Future<void>? get pending => _pending;

  /// `canvas.toBlob(cb, 'image/png')` — the card at its own 1080 × 1350.
  Future<Uint8List?> _png() async {
    final RenderObject? box = _boundary.currentContext?.findRenderObject();
    if (box is! RenderRepaintBoundary) return null;
    final ui.Image image = await box.toImage();
    try {
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  void _say(String message, LumeToastTone tone) =>
      showLumeToast(context, LumeToastData(message: message, tone: tone));

  Future<void> _run(
    Future<(String, LumeToastTone)?> Function(Uint8List png) act,
  ) {
    if (_busy) return _pending ?? Future<void>.value();
    return _pending = _render(act);
  }

  Future<void> _render(
    Future<(String, LumeToastTone)?> Function(Uint8List png) act,
  ) async {
    setState(() => _busy = true);
    final AppLocalizations l = AppLocalizations.of(context);
    try {
      final Uint8List? png = await _png();
      if (!mounted) return;
      if (png == null) {
        _say(l.shareFailed, LumeToastTone.error);
        return;
      }
      final (String, LumeToastTone)? said = await act(png);
      if (mounted && said != null) _say(said.$1, said.$2);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _run((Uint8List png) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeSaveOutcome outcome = await ref
        .read(imageSaverProvider)
        .saveImage(png, fileName: widget.card.fileName);
    return switch (outcome) {
      LumeSaveOutcome.saved => (l.shareSaved, LumeToastTone.success),
      LumeSaveOutcome.denied => (l.shareSaveDenied, LumeToastTone.error),
      LumeSaveOutcome.noSpace => (l.shareSaveNoSpace, LumeToastTone.error),
      LumeSaveOutcome.unavailable => (
        l.shareSaveUnavailable,
        LumeToastTone.info,
      ),
      LumeSaveOutcome.failed => (l.shareSaveFailed, LumeToastTone.error),
    };
  });

  Future<void> _send() => _run((Uint8List png) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeShareOutcome outcome = await ref
        .read(sharerProvider)
        .shareImage(
          png,
          fileName: widget.card.fileName,
          caption: widget.card.caption,
        );
    return switch (outcome) {
      LumeShareOutcome.shared => (l.shareShared, LumeToastTone.success),
      LumeShareOutcome.dismissed => null,
      LumeShareOutcome.unavailable => (l.shareUnavailable, LumeToastTone.info),
      LumeShareOutcome.failed => (l.shareFailed, LumeToastTone.error),
    };
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return LumeSheet(
      title: l.actionShare,
      subtitle: l.shareCardReady,
      tall: true,
      closeLabel: l.actionClose,
      onClose: () => Navigator.of(context).pop(),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // `.sharecard { padding: 4px 0 2px; place-items: center }`.
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LumeShareSheet.previewWidth,
                  ),
                  child: AspectRatio(
                    aspectRatio:
                        LumeShareCardArt.size.width /
                        LumeShareCardArt.size.height,
                    child: Semantics(
                      key: LumeShareSheet.previewKey,
                      image: true,
                      label: '${l.sharePreviewLabel}: ${widget.card.caption}',
                      child: ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: LumeRadius.brLg,
                            boxShadow: context.lumeShadows.md,
                          ),
                          child: ClipRRect(
                            borderRadius: LumeRadius.brLg,
                            child: FittedBox(
                              child: RepaintBoundary(
                                key: _boundary,
                                child: LumeShareCardArt(
                                  card: widget.card,
                                  tagline: l.appTagline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // `.sharecard__actions { gap: 8px; margin: 16px 0 6px }`.
            const SizedBox(height: 16),
            LumeButtonRow(
              children: <Widget>[
                LumeButton(
                  key: LumeShareSheet.saveKey,
                  label: l.actionSaveImage,
                  icon: LumeIcons.download,
                  onPressed: _busy ? null : _save,
                ),
                LumeButton.accent(
                  key: LumeShareSheet.sendKey,
                  label: l.actionShare,
                  icon: LumeIcons.share,
                  onPressed: _busy ? null : _send,
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
