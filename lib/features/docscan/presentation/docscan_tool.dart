/// Document Scanner — a camera instrument beside QR Scanner (F6A-D5's own
/// family), over a contract of its own (`document_capture.dart`) rather than
/// `LumeScanner`'s: a document scan's result is the photo itself, not
/// something decoded from it.
///
/// `tools/daily/docscan.tool.js` shares its module (`shared/scanner.js`) with
/// `qr.tool.js`, and the reference itself never does more than toast
/// "Capturing…" — there is no edge detection, no perspective crop, no
/// enhancement and no PDF export behind it there either. This build makes
/// Capture and From gallery real (a genuine camera photo or a genuine chosen
/// image, through `LumePlatformDocumentCamera`) and keeps the session's pages
/// honestly in memory; it does not invent the crop, enhance or PDF steps the
/// reference's own four-step list named, because nothing here can honestly
/// do them yet (no image-processing or PDF package is part of this build —
/// see the wave report). The three steps below name only what actually
/// happens.
///
/// Pages are session-only: nothing is written when the tool closes, so there
/// is no cross-session "history" here the way `docscan`'s catalogue entry
/// aspires to (`LumeToolSupport.history`) — only this run's own captures,
/// which is what makes them honest to show at all.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_gradients.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/document_capture.dart';
import '../data/document_page.dart';
import '../data/document_sharer.dart';
import 'docscan_providers.dart';

class LumeDocScanTool extends ConsumerStatefulWidget {
  const LumeDocScanTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeDocScanTool(request: request);

  static const String id = 'docscan';

  static const Key viewKey = ValueKey<String>('docscan.view');
  static const Key hintKey = ValueKey<String>('docscan.hint');
  static const Key actionsKey = ValueKey<String>('docscan.actions');
  static const Key captureKey = ValueKey<String>('docscan.capture');
  static const Key galleryKey = ValueKey<String>('docscan.gallery');
  static const Key stepsKey = ValueKey<String>('docscan.steps');
  static const Key pagesKey = ValueKey<String>('docscan.pages');
  static const Key emptyKey = ValueKey<String>('docscan.empty');
  static const Key pageActionsKey = ValueKey<String>('docscan.pageActions');
  static const Key shareKey = ValueKey<String>('docscan.share');
  static const Key clearKey = ValueKey<String>('docscan.clear');

  static Key removeKey(String pageId) =>
      ValueKey<String>('docscan.remove.$pageId');

  /// What the screen says for an outcome that is not a capture; `null` for
  /// one that says nothing (the reader cancelled, or a photo was captured —
  /// the new row is what says that).
  static (String, LumeToastTone)? saying(
    AppLocalizations l,
    LumeCaptureOutcome outcome, {
    required bool camera,
  }) => switch (outcome) {
    LumeCaptureOutcome.captured => null,
    LumeCaptureOutcome.cancelled => null,
    LumeCaptureOutcome.denied => (
      camera ? l.docscanCaptureDenied : l.scanPhotosDenied,
      LumeToastTone.error,
    ),
    LumeCaptureOutcome.blocked => (
      camera ? l.scanBlocked : l.scanPhotosDenied,
      LumeToastTone.error,
    ),
    LumeCaptureOutcome.undetermined => (
      camera ? l.docscanCaptureUndetermined : l.scanPhotosDenied,
      LumeToastTone.error,
    ),
    LumeCaptureOutcome.restricted => (l.scanRestricted, LumeToastTone.error),
    LumeCaptureOutcome.unavailable => (l.scanUnavailable, LumeToastTone.info),
    LumeCaptureOutcome.failed => (l.scanFailed, LumeToastTone.error),
  };

  @override
  ConsumerState<LumeDocScanTool> createState() => _LumeDocScanToolState();
}

class _LumeDocScanToolState extends ConsumerState<LumeDocScanTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  bool _busy = false;
  int _nextId = 0;
  final List<LumeDocumentPage> _pages = <LumeDocumentPage>[];

  LumeToolScreenState? get _say => _host.currentState;

  Future<void> _capture({required bool camera}) async {
    if (_busy) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeDocumentCamera device = ref.read(documentCameraProvider);
    setState(() => _busy = true);
    final LumeCaptureResult result;
    try {
      result = camera ? await device.capture() : await device.pickImage();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    final Uint8List? bytes = result.bytes;
    if (result.outcome == LumeCaptureOutcome.captured &&
        bytes != null &&
        bytes.isNotEmpty) {
      setState(() {
        _pages.add(
          LumeDocumentPage(
            id: '${_nextId++}',
            bytes: bytes,
            mimeType: result.mimeType ?? 'image/jpeg',
            capturedAt: LumeClockScope.of(context).now(),
            fromGallery: !camera,
          ),
        );
      });
      return;
    }
    final (String, LumeToastTone)? said = LumeDocScanTool.saying(
      l,
      result.outcome,
      camera: camera,
    );
    if (said == null) return;
    final bool settings = camera && device.offersSettings(result.outcome);
    _say?.say(
      said.$1,
      tone: said.$2,
      actionLabel: settings ? l.scanOpenSettings : null,
      onAction: settings ? () => _openSettings(device) : null,
    );
  }

  Future<void> _openSettings(LumeDocumentCamera device) async {
    final String failed = AppLocalizations.of(context).scanSettingsFailed;
    if (await device.openSettings() || !mounted) return;
    _say?.say(failed, tone: LumeToastTone.error);
  }

  void _removePage(String id) =>
      setState(() => _pages.removeWhere((LumeDocumentPage p) => p.id == id));

  void _clearAll() {
    if (_pages.isEmpty) return;
    setState(_pages.clear);
    _say?.say(AppLocalizations.of(context).docscanCleared);
  }

  Future<void> _shareAll() async {
    if (_pages.isEmpty || _busy) return;
    final AppLocalizations l = AppLocalizations.of(context);
    setState(() => _busy = true);
    final LumeDocShareOutcome outcome;
    try {
      outcome = await ref
          .read(documentSharerProvider)
          .share(List<LumeDocumentPage>.of(_pages));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    switch (outcome) {
      case LumeDocShareOutcome.shared:
        _say?.say(l.shareShared);
      case LumeDocShareOutcome.dismissed:
        break;
      case LumeDocShareOutcome.unavailable:
        _say?.say(l.shareUnavailable, tone: LumeToastTone.info);
      case LumeDocShareOutcome.failed:
        _say?.say(l.docscanShareFailed, tone: LumeToastTone.error);
    }
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
                _CapturePanel(hint: l.docscanHint),
                const SizedBox(height: 14),
                LumeButtonRow(
                  key: LumeDocScanTool.actionsKey,
                  children: <Widget>[
                    LumeButton.accent(
                      key: LumeDocScanTool.captureKey,
                      label: l.docscanCapture,
                      icon: LumeIcons.camera,
                      onPressed: _busy ? null : () => _capture(camera: true),
                    ),
                    LumeButton(
                      key: LumeDocScanTool.galleryKey,
                      label: l.scanFromGallery,
                      icon: LumeIcons.image,
                      onPressed: _busy ? null : () => _capture(camera: false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.docscanPagesTitle,
            child: _pages.isEmpty
                ? LumeToolState(
                    key: LumeDocScanTool.emptyKey,
                    icon: LumeIcons.scan,
                    title: l.scanEmptyTitle,
                    text: l.scanEmptyText,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      LumeRows(
                        key: LumeDocScanTool.pagesKey,
                        children: <Widget>[
                          for (final (int i, LumeDocumentPage p)
                              in _pages.indexed)
                            LumeRichRow(
                              thumb: Image.memory(p.bytes, fit: BoxFit.cover),
                              title: l.docscanPageN(i + 1),
                              meta: <String>[
                                p.fromGallery
                                    ? l.docscanSourceGallery
                                    : l.docscanSourceCamera,
                              ],
                              trailing: LumeIconButton(
                                key: LumeDocScanTool.removeKey(p.id),
                                icon: LumeIcons.trash,
                                label:
                                    '${l.actionRemove} ${l.docscanPageN(i + 1)}',
                                onPressed: () => _removePage(p.id),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LumeButtonRow(
                        key: LumeDocScanTool.pageActionsKey,
                        children: <Widget>[
                          LumeButton.accent(
                            key: LumeDocScanTool.shareKey,
                            label: l.commonShare,
                            icon: LumeIcons.share,
                            onPressed: _busy ? null : _shareAll,
                          ),
                          LumeButton(
                            key: LumeDocScanTool.clearKey,
                            label: l.actionClear,
                            onPressed: _busy ? null : _clearAll,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.docscanStepsTitle,
            child: LumeTimeline(
              key: LumeDocScanTool.stepsKey,
              entries: <LumeTimelineEntry>[
                LumeTimelineEntry(
                  time: '1',
                  title: l.docscanStepCapture,
                  state: LumeTimelineState.now,
                ),
                LumeTimelineEntry(time: '2', title: l.docscanStepReview),
                LumeTimelineEntry(time: '3', title: l.docscanStepShare),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The capture panel. Unlike QR's `_Viewfinder`, there is no live frame to
/// show — Capture opens the system camera app rather than an embedded
/// preview Lume decodes — so this is a still panel, never animated: an
/// animated "scanning" beam here would claim a live detection that is not
/// happening.
class _CapturePanel extends StatelessWidget {
  const _CapturePanel({required this.hint});

  final String hint;

  static const double height = 168;

  @override
  Widget build(BuildContext context) {
    final LumeGradient scan = context.lumeGradients.scan;
    return ClipRRect(
      key: LumeDocScanTool.viewKey,
      borderRadius: LumeRadius.brLg,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: scan.css(
              160,
              Size(MediaQuery.sizeOf(context).width, height),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ExcludeSemantics(
                child: LumeIcon(
                  LumeIcons.scan,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              Positioned(
                bottom: 16,
                child: Container(
                  key: LumeDocScanTool.hintKey,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: LumeRadius.full,
                  ),
                  child: Text(
                    hint,
                    maxLines: 1,
                    softWrap: false,
                    style: LumeType.natural(context, context.lumeType.metaSmall)
                        .copyWith(
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
    );
  }
}
