/// The camera, full screen, in Lume's own states — and only while it is seen.
///
/// The page never knows which package drives the camera: it is handed a
/// [LumeCameraView] and listens to what that view reports. What it owns is
/// when a camera may exist at all (C80):
///
/// * **starting** — the view is in the tree and has not reported a picture;
/// * **live** — scanning; a code that is not a QR code is said, and scanning
///   goes on;
/// * **paused** — the app is in the background, or something covers the page:
///   the view is taken out of the tree, which closes the camera; it comes back
///   when the page is seen again;
/// * a QR code, Close, Back, or a camera that will not start ends the page
///   with a [LumeScanResult].
///
/// Nothing is kept: no frame, no image, no history.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/app_localizations.dart';
import '../icons/lume_icon.dart';
import '../icons/lume_icons.dart';
import '../theme/lume/lume_space.dart';
import '../theme/lume/lume_theme.dart';
import '../theme/lume/lume_type.dart';
import '../widgets/lume/lume_pressable.dart';
import '../widgets/lume/lume_scan_window.dart';
import 'lume_scanner.dart';

/// What a camera view tells the page.
@immutable
class LumeCameraEvents {
  const LumeCameraEvents({
    required this.onLive,
    required this.onCode,
    required this.onTrouble,
  });

  /// The camera is showing a picture.
  final VoidCallback onLive;

  /// A code was decoded. [isQr] is false for any other symbology.
  final void Function(String text, {required bool isQr}) onCode;

  /// The camera will not run: [LumeScanOutcome.denied],
  /// [LumeScanOutcome.blocked], [LumeScanOutcome.unavailable] or
  /// [LumeScanOutcome.failed].
  final ValueChanged<LumeScanOutcome> onTrouble;
}

/// Builds the camera. [scanSide] is the side of the centred window the page
/// draws, so the view can decode the same square.
typedef LumeCameraView =
    Widget Function(
      BuildContext context,
      LumeCameraEvents events,
      double scanSide,
    );

/// Opens the capture page over everything and answers what became of it.
Future<LumeScanResult> showLumeCapture(
  NavigatorState navigator, {
  required LumeCameraView camera,
  Duration startLimit = LumeCapturePage.defaultStartLimit,
}) async {
  final LumeScanResult? result = await navigator.push<LumeScanResult>(
    PageRouteBuilder<LumeScanResult>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (BuildContext context, _, _) =>
          LumeCapturePage(camera: camera, startLimit: startLimit),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            _,
            Widget child,
          ) => FadeTransition(opacity: animation, child: child),
    ),
  );
  return result ?? const LumeScanResult(LumeScanOutcome.cancelled);
}

enum LumeCapturePhase { starting, live, paused }

class LumeCapturePage extends StatefulWidget {
  const LumeCapturePage({
    super.key,
    required this.camera,
    this.startLimit = LumeCapturePage.defaultStartLimit,
  });

  final LumeCameraView camera;

  /// How long the camera may take to show a picture while Lume is in the
  /// foreground. Time spent away — a permission prompt makes the app
  /// inactive — is not counted. A device with no camera never reports
  /// anything, and this is how the page finds out.
  final Duration startLimit;

  static const Duration defaultStartLimit = Duration(seconds: 10);

  static const Key cameraKey = ValueKey<String>('capture.camera');
  static const Key closeKey = ValueKey<String>('capture.close');
  static const Key statusKey = ValueKey<String>('capture.status');
  static const Key windowKey = ValueKey<String>('capture.window');

  @override
  State<LumeCapturePage> createState() => LumeCapturePageState();
}

@visibleForTesting
class LumeCapturePageState extends State<LumeCapturePage>
    with WidgetsBindingObserver {
  bool _away = false;
  bool _live = false;
  bool _notQr = false;
  bool _done = false;

  /// Something — a permission prompt — has been drawn over Lume since the
  /// page opened.
  bool _prompted = false;
  Timer? _limit;

  /// Rebuilt each time the camera returns, so a reopened camera is a new one.
  int _session = 0;

  bool get _foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  LumeCapturePhase phaseFor({required bool covered}) {
    if (_away || covered) return LumeCapturePhase.paused;
    return _live ? LumeCapturePhase.live : LumeCapturePhase.starting;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armLimit();
  }

  @override
  void dispose() {
    _limit?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _armLimit() {
    _limit?.cancel();
    if (_live || _away || !_foreground) return;
    _limit = Timer(widget.startLimit, () {
      if (!_live && !_away && _foreground) {
        _finish(const LumeScanResult(LumeScanOutcome.unavailable));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_away) {
          setState(() {
            _away = false;
            _live = false;
            _session++;
          });
        }
        _armLimit();
      // Inactive is a permission prompt or a notification shade: the camera
      // stays, or the prompt would be asked again on every return.
      case AppLifecycleState.inactive:
        _prompted = true;
        _limit?.cancel();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _limit?.cancel();
        if (!_away) {
          setState(() => _away = true);
          // Frames stop while the app is away, and the camera leaves the tree
          // only in a frame: ask for one now rather than on return.
          SchedulerBinding.instance.scheduleForcedFrame();
        }
    }
  }

  void _finish(LumeScanResult result) {
    if (_done || !mounted) return;
    _done = true;
    _limit?.cancel();
    Navigator.of(context).pop(result);
  }

  late final LumeCameraEvents _events = LumeCameraEvents(
    onLive: () {
      if (_done || !mounted) return;
      _limit?.cancel();
      if (!_live) setState(() => _live = true);
    },
    onCode: (String text, {required bool isQr}) {
      if (_done || !mounted) return;
      if (isQr && text.isNotEmpty) {
        _finish(LumeScanResult(LumeScanOutcome.read, text));
      } else if (!_notQr) {
        setState(() => _notQr = true);
      }
    },
    // Android answers `CameraAccessDenied` both when the reader refuses the
    // prompt and when it will never prompt again. Only the first puts a
    // prompt over Lume, so a refusal with no prompt shown is a refusal only
    // Settings can undo.
    onTrouble: (LumeScanOutcome outcome) => _finish(
      LumeScanResult(
        outcome == LumeScanOutcome.denied && !_prompted
            ? LumeScanOutcome.blocked
            : outcome,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool covered = !(ModalRoute.of(context)?.isCurrent ?? true);
    final LumeCapturePhase phase = phaseFor(covered: covered);
    final Size size = MediaQuery.sizeOf(context);
    final double side = (size.shortestSide * 0.64).clamp(160.0, 300.0);
    final String status = switch (phase) {
      LumeCapturePhase.starting => l.captureStarting,
      LumeCapturePhase.paused => l.capturePaused,
      LumeCapturePhase.live => _notQr ? l.captureNotQr : l.qrHint,
    };
    final EdgeInsets pad = MediaQuery.paddingOf(context);

    return PopScope<LumeScanResult>(
      canPop: true,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (phase != LumeCapturePhase.paused && !_done)
              KeyedSubtree(
                key: LumeCapturePage.cameraKey,
                child: KeyedSubtree(
                  key: ValueKey<int>(_session),
                  child: ExcludeSemantics(
                    child: widget.camera(context, _events, side),
                  ),
                ),
              ),
            Positioned.fill(
              key: LumeCapturePage.windowKey,
              child: ExcludeSemantics(
                child: CustomPaint(painter: LumeScanWindow(side: side)),
              ),
            ),
            PositionedDirectional(
              top: pad.top + LumeSpace.x2,
              start: LumeSpace.x3,
              end: LumeSpace.x3,
              child: Row(
                children: <Widget>[
                  LumePressable(
                    key: LumeCapturePage.closeKey,
                    onTap: () => _finish(
                      const LumeScanResult(LumeScanOutcome.cancelled),
                    ),
                    semanticLabel: l.actionClose,
                    borderRadius: LumeRadius.full,
                    minSize: LumeSpace.tap,
                    child: Container(
                      width: LumeSpace.tap,
                      height: LumeSpace.tap,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        shape: BoxShape.circle,
                      ),
                      child: const LumeIcon(
                        LumeIcons.x,
                        size: LumeSpace.iconMd,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: LumeSpace.x3),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l.captureTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LumeType.fit(
                          context,
                          context.lumeType.cardTitle,
                        ).copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: LumeSpace.x5,
              right: LumeSpace.x5,
              bottom: pad.bottom + 40,
              child: Center(
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    key: LumeCapturePage.statusKey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: LumeRadius.full,
                    ),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: LumeType.fit(
                        context,
                        context.lumeType.bodyStrong,
                      ).copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
