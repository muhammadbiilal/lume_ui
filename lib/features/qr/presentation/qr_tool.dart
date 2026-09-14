/// QR Scanner — the reference tool for camera instruments (F6A-D5).
///
/// `tools/daily/qr.tool.js` over `shared/scanner.js`: the viewfinder with its
/// frame, beam and hint, Scan and From gallery, what the scanner recognises,
/// and the history. Scan and From gallery go through [scannerProvider]; a code
/// read is shown in [LumeQrResultSheet] and goes nowhere until the reader
/// chooses; every other outcome is said as it is (C78, C80).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/platform_services.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_qr_payload.dart';
import '../../../core/platform/lume_scanner.dart';
import '../../../core/theme/lume/lume_gradients.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_scan_window.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import 'qr_result_sheet.dart';

class LumeQrTool extends ConsumerStatefulWidget {
  const LumeQrTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) => LumeQrTool(request: request);

  static const String id = 'qr';

  static const Key viewKey = ValueKey<String>('qr.view');
  static const Key frameKey = ValueKey<String>('qr.frame');
  static const Key hintKey = ValueKey<String>('qr.hint');
  static const Key actionsKey = ValueKey<String>('qr.actions');
  static const Key scanKey = ValueKey<String>('qr.scan');
  static const Key galleryKey = ValueKey<String>('qr.gallery');
  static const Key stepsKey = ValueKey<String>('qr.steps');
  static const Key historyKey = ValueKey<String>('qr.history');

  /// What the screen says for an outcome that is not a code read; `null` for
  /// one that says nothing (the reader cancelled).
  static (String, LumeToastTone)? saying(
    AppLocalizations l,
    LumeScanOutcome outcome, {
    required bool camera,
  }) => switch (outcome) {
    // A read with no text is a code with nothing in it.
    LumeScanOutcome.read => (l.scanUnreadable, LumeToastTone.error),
    LumeScanOutcome.nothing => (l.scanNothing, LumeToastTone.info),
    LumeScanOutcome.cancelled => null,
    LumeScanOutcome.denied => (
      camera ? l.scanDenied : l.scanPhotosDenied,
      LumeToastTone.error,
    ),
    LumeScanOutcome.blocked => (
      camera ? l.scanBlocked : l.scanPhotosDenied,
      LumeToastTone.error,
    ),
    LumeScanOutcome.unavailable => (l.scanUnavailable, LumeToastTone.info),
    LumeScanOutcome.failed => (l.scanFailed, LumeToastTone.error),
    LumeScanOutcome.multiple => (l.scanMultiple, LumeToastTone.info),
    LumeScanOutcome.unsupported => (l.scanUnsupported, LumeToastTone.info),
    LumeScanOutcome.unreadable => (l.scanUnreadable, LumeToastTone.error),
    LumeScanOutcome.tooLarge => (l.scanTooLarge, LumeToastTone.error),
  };

  @override
  ConsumerState<LumeQrTool> createState() => _LumeQrToolState();
}

class _LumeQrToolState extends ConsumerState<LumeQrTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  bool _busy = false;

  Future<void> _run({required bool camera}) async {
    if (_busy) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeScanner scanner = ref.read(scannerProvider);
    setState(() => _busy = true);
    final LumeScanResult result;
    try {
      result = camera ? await scanner.scan() : await scanner.pickImage();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    final String? value = result.value;
    if (result.outcome == LumeScanOutcome.read &&
        value != null &&
        value.isNotEmpty) {
      await showLumeQrResult(
        context: context,
        payload: LumeQrPayload.classify(value),
      );
      return;
    }
    final (String, LumeToastTone)? said = LumeQrTool.saying(
      l,
      result.outcome,
      camera: camera,
    );
    if (said != null) _host.currentState?.say(said.$1, tone: said.$2);
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Viewfinder(hint: l.qrHint),
                // `.scanner .btnrow { margin-top: 14px }`.
                const SizedBox(height: 14),
                LumeButtonRow(
                  key: LumeQrTool.actionsKey,
                  children: <Widget>[
                    LumeButton.accent(
                      key: LumeQrTool.scanKey,
                      label: l.qrScan,
                      icon: LumeIcons.qr,
                      onPressed: _busy ? null : () => _run(camera: true),
                    ),
                    LumeButton(
                      key: LumeQrTool.galleryKey,
                      label: l.scanFromGallery,
                      icon: LumeIcons.image,
                      onPressed: _busy ? null : () => _run(camera: false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.qrDetects,
            child: LumeTimeline(
              key: LumeQrTool.stepsKey,
              entries: <LumeTimelineEntry>[
                LumeTimelineEntry(
                  time: '1',
                  title: l.qrStepPoint,
                  state: LumeTimelineState.now,
                ),
                LumeTimelineEntry(time: '2', title: l.qrStepDetect),
                LumeTimelineEntry(time: '3', title: l.qrStepAct),
              ],
            ),
          ),
          LumeToolSection(
            title: l.commonHistory,
            // The reference's two scans are fixtures: nothing here has been
            // scanned, a scan is never added to it, and pressing one only
            // names it (C78, C80).
            child: LumeRows(
              key: LumeQrTool.historyKey,
              children: <Widget>[
                for (final (String icon, String title, String kind, String day)
                    in <(String, String, String, String)>[
                      (
                        LumeIcons.globe,
                        'lume.app/tools',
                        l.qrKindLink,
                        l.commonToday,
                      ),
                      (
                        LumeIcons.wifi,
                        'Home-WiFi',
                        l.qrKindWifi,
                        l.commonYesterday,
                      ),
                    ])
                  LumeRichRow(
                    icon: icon,
                    title: title,
                    subtitle: kind,
                    meta: <String>[day],
                    chevron: true,
                    onTap: () => _host.currentState?.say(
                      title,
                      tone: LumeToastTone.info,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.scanner__view` — 232 tall at radius 20 on the scan gradient; a 148-point
/// frame at radius 16 ringed in white at .55 with the rest dimmed at .28; the
/// beam, 148 × 2, accent-400 fading to either side, sweeping the frame; the
/// hint 16 from the bottom, 11 / 600 in white at .82 on black at .32 in a
/// full pill, `6 12`.
class _Viewfinder extends StatefulWidget {
  const _Viewfinder({required this.hint});

  final String hint;

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder>
    with SingleTickerProviderStateMixin {
  // `animation: scanbeam 2.4s infinite` — stopped when motion is reduced.
  late final AnimationController _beam = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  static const double frame = 148;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _beam
        ..stop()
        ..value = 0.5;
    } else if (!_beam.isAnimating) {
      _beam.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _beam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeGradient scan = context.lumeGradients.scan;
    final lume = context.lume;
    return ExcludeSemantics(
      excluding: false,
      child: ClipRRect(
        key: LumeQrTool.viewKey,
        borderRadius: LumeRadius.brLg,
        child: SizedBox(
          height: 232,
          child: DecoratedBox(
            // `linear-gradient(160deg, grad-scan-a, grad-scan-b)`.
            decoration: BoxDecoration(
              gradient: scan.css(
                160,
                Size(MediaQuery.sizeOf(context).width, 232),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                const Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(painter: LumeScanWindow(side: frame)),
                  ),
                ),
                const SizedBox(
                  key: LumeQrTool.frameKey,
                  width: frame,
                  height: frame,
                ),
                ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _beam,
                    builder: (BuildContext context, Widget? child) =>
                        Transform.translate(
                          offset: Offset(0, (_beam.value - 0.5) * (frame - 8)),
                          child: child,
                        ),
                    child: Container(
                      width: frame,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            Colors.transparent,
                            lume.accent400,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  child: Container(
                    key: LumeQrTool.hintKey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: LumeRadius.full,
                    ),
                    child: Text(
                      widget.hint,
                      maxLines: 1,
                      softWrap: false,
                      style:
                          LumeType.natural(
                            context,
                            context.lumeType.metaSmall,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
