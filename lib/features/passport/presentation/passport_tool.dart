/// Passport Photos — the reference tool for `tools/daily/passport.tool.js`.
///
/// **What the reference actually is.** `passport.tool.js` never touches a
/// camera: its "Take a photo" and "Import" buttons only `toast:` "Opening the
/// camera" / "Choosing a photo" and go nowhere. What it draws for real is a
/// static guide (a frame, four spec chips from `passportSpecs()`), a
/// requirements checklist, and a table of common document sizes.
///
/// **What this build does instead.** Lume already has a real, working camera
/// and photo-library path (QR's own `LumeScanner`/`image_picker`) and a real
/// save-to-photos path (`LumeImageSaver`), so this tool actually takes or
/// picks a photo, crops and resizes it for real onto the reader's country's
/// own spec at a real pixel size (`LumePassportProcessor`, `dart:ui` —
/// see its own doc comment for exactly what a fuller port would still need),
/// and saves the result to the reader's photos. That is a deliberate
/// correction in the same spirit as this wave's others (Currency's real
/// picker, Duas' fixed share) rather than reproducing a mockup's fake
/// buttons — see `PASSPORT_PHOTOS.md` for the fuller account.
///
/// **Country awareness (§4/§35).** [LumePassportSpec.forCountry] is the
/// reference's own rule, unchanged: only the United States gets 2 × 2 in;
/// every other country gets 35 × 45 mm. That is real, but it is also not
/// every country's actual authority (Canada's is 50 × 70 mm) — the tool
/// never claims otherwise, it only ever states the specific figure for the
/// reader's own country.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/platform_services.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/providers/shell_provider.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/passport_providers.dart';
import '../data/passport_processor.dart';
import '../domain/passport_photo_source.dart';
import '../domain/passport_spec.dart';

class LumePassportTool extends ConsumerStatefulWidget {
  const LumePassportTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumePassportTool(request: request);

  static const String id = 'passport';

  static const Key contextKey = ValueKey<String>('passport.context');
  static const Key guideKey = ValueKey<String>('passport.guide');
  static const Key specsKey = ValueKey<String>('passport.specs');
  static const Key actionsKey = ValueKey<String>('passport.actions');
  static const Key captureKey = ValueKey<String>('passport.capture');
  static const Key importKey = ValueKey<String>('passport.import');
  static const Key previewKey = ValueKey<String>('passport.preview');
  static const Key saveKey = ValueKey<String>('passport.save');
  static const Key retakeKey = ValueKey<String>('passport.retake');
  static const Key chooseDifferentKey = ValueKey<String>(
    'passport.chooseDifferent',
  );
  static const Key requirementsKey = ValueKey<String>('passport.requirements');
  static const Key sizesKey = ValueKey<String>('passport.sizes');

  /// What the screen says for an outcome that is not a captured photo;
  /// `null` says nothing (the reader cancelled). [camera] tells the camera's
  /// own wording from the gallery's.
  static (String, LumeToastTone)? saying(
    AppLocalizations l,
    LumePassportPhotoOutcome outcome, {
    required bool camera,
  }) => switch (outcome) {
    LumePassportPhotoOutcome.captured => null,
    LumePassportPhotoOutcome.cancelled => null,
    LumePassportPhotoOutcome.denied => (
      camera ? l.passportCameraDenied : l.passportGalleryDenied,
      LumeToastTone.error,
    ),
    LumePassportPhotoOutcome.blocked => (
      l.passportCameraBlocked,
      LumeToastTone.error,
    ),
    LumePassportPhotoOutcome.restricted => (
      l.passportCameraRestricted,
      LumeToastTone.error,
    ),
    LumePassportPhotoOutcome.undetermined => (
      l.passportCameraUndetermined,
      LumeToastTone.error,
    ),
    LumePassportPhotoOutcome.unavailable => (
      camera ? l.passportCameraUnavailable : l.passportGalleryUnavailable,
      LumeToastTone.info,
    ),
    LumePassportPhotoOutcome.failed => (
      camera ? l.passportCameraFailed : l.passportGalleryFailed,
      LumeToastTone.error,
    ),
    LumePassportPhotoOutcome.tooLarge => (
      l.passportTooLarge,
      LumeToastTone.error,
    ),
  };

  @override
  ConsumerState<LumePassportTool> createState() => _LumePassportToolState();
}

class _LumePassportToolState extends ConsumerState<LumePassportTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();

  bool _busy = false;
  bool _saving = false;
  Uint8List? _photo;

  /// The spec [_photo] was cropped for. When the reader's country changes
  /// mid-session the spec's pixel size may no longer match what is on
  /// screen, so a stale crop is dropped rather than shown as though it still
  /// fit — never reprocessed silently into a figure the reader did not ask
  /// for.
  String? _photoSpecId;

  Future<void> _runCamera() => _run(camera: true);

  Future<void> _runGallery() => _run(camera: false);

  Future<void> _run({required bool camera}) async {
    if (_busy) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumePassportPhotoSource source = ref.read(passportPhotoSourceProvider);
    final LumePassportSpec spec = LumePassportSpec.forCountry(
      widget.request.user.country,
    );
    setState(() => _busy = true);
    final LumePassportPhotoResult result;
    try {
      result = camera ? await source.capture() : await source.pickImage();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    final Uint8List? bytes = result.bytes;
    if (result.outcome == LumePassportPhotoOutcome.captured && bytes != null) {
      final Uint8List? cropped = await LumePassportProcessor.cropToSpec(
        bytes,
        spec,
      );
      if (!mounted) return;
      if (cropped == null) {
        _host.currentState?.say(
          l.passportProcessFailed,
          tone: LumeToastTone.error,
        );
        return;
      }
      setState(() {
        _photo = cropped;
        _photoSpecId = spec.id;
      });
      return;
    }

    final (String, LumeToastTone)? said = LumePassportTool.saying(
      l,
      result.outcome,
      camera: camera,
    );
    if (said == null) return;
    final bool settings = camera && source.offersSettings(result.outcome);
    _host.currentState?.say(
      said.$1,
      tone: said.$2,
      actionLabel: settings ? l.passportOpenSettings : null,
      onAction: settings ? () => _openSettings(source) : null,
    );
  }

  Future<void> _openSettings(LumePassportPhotoSource source) async {
    final String failed = AppLocalizations.of(context).passportSettingsFailed;
    if (await source.openSettings() || !mounted) return;
    _host.currentState?.say(failed, tone: LumeToastTone.error);
  }

  Future<void> _save() async {
    final Uint8List? photo = _photo;
    if (_saving || photo == null) return;
    final AppLocalizations l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final LumeSaveOutcome outcome;
    try {
      outcome = await ref
          .read(imageSaverProvider)
          .saveImage(photo, fileName: 'lume-passport.png');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    switch (outcome) {
      case LumeSaveOutcome.saved:
        _host.currentState?.say(l.passportSaved);
      case LumeSaveOutcome.denied:
        _host.currentState?.say(
          l.passportSaveDenied,
          tone: LumeToastTone.error,
        );
      case LumeSaveOutcome.noSpace:
        _host.currentState?.say(
          l.passportSaveNoSpace,
          tone: LumeToastTone.error,
        );
      case LumeSaveOutcome.unavailable:
        _host.currentState?.say(
          l.passportSaveUnavailable,
          tone: LumeToastTone.info,
        );
      case LumeSaveOutcome.failed:
        _host.currentState?.say(
          l.passportSaveFailed,
          tone: LumeToastTone.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumePassportSpec spec = LumePassportSpec.forCountry(r.user.country);
    final Uint8List? photo = _photoSpecId == spec.id ? _photo : null;
    final DateTime now = LumeClockScope.of(context).now();
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      exportFile: () => LumeExportFile.record(
        tool: LumePassportTool.id,
        day: now,
        exported: now,
        locale:
            '${Localizations.localeOf(context).languageCode}-${r.user.country}',
        currency: startup.countries?.currencyOf(r.user.country) ?? '',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumePassportTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(
                  label: LumeToolScreen.countryName(context, ref, r.user.country),
                  icon: LumeIcons.globe,
                  onTap: () => showLumePersonalise(context),
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (photo == null)
                    _GuideFrame(key: LumePassportTool.guideKey, hint: l.passportGuideHint)
                  else
                    _PreviewFrame(
                      key: LumePassportTool.previewKey,
                      bytes: photo,
                      semanticLabel: l.passportPreviewAlt,
                    ),
                  const SizedBox(height: LumeSpace.x4),
                  _SpecRow(
                    key: LumePassportTool.specsKey,
                    items: <(String, String)>[
                      (
                        l.passportCountry,
                        LumeToolScreen.countryName(context, ref, r.user.country),
                      ),
                      (l.passportSize, spec.sizeLabel),
                      (l.passportBackground, l.passportWhite),
                      (l.passportHeadHeight, spec.headHeightLabel),
                    ],
                  ),
                  const SizedBox(height: LumeSpace.x4),
                  if (photo == null)
                    LumeButtonRow(
                      key: LumePassportTool.actionsKey,
                      children: <Widget>[
                        LumeButton.accent(
                          key: LumePassportTool.captureKey,
                          label: l.passportCapture,
                          icon: LumeIcons.camera,
                          busy: _busy,
                          busyLabel: l.passportCapturing,
                          onPressed: _busy ? null : _runCamera,
                        ),
                        LumeButton(
                          key: LumePassportTool.importKey,
                          label: l.passportImport,
                          icon: LumeIcons.image,
                          busy: _busy,
                          busyLabel: l.passportImporting,
                          onPressed: _busy ? null : _runGallery,
                        ),
                      ],
                    )
                  else ...<Widget>[
                    LumeButtonRow(
                      key: LumePassportTool.actionsKey,
                      children: <Widget>[
                        LumeButton.accent(
                          key: LumePassportTool.saveKey,
                          label: l.passportSavePhoto,
                          icon: LumeIcons.download,
                          busy: _saving,
                          busyLabel: l.passportSaving,
                          onPressed: _busy || _saving ? null : _save,
                        ),
                        LumeButton(
                          key: LumePassportTool.retakeKey,
                          label: l.passportRetake,
                          icon: LumeIcons.refresh,
                          busy: _busy,
                          busyLabel: l.passportCapturing,
                          onPressed: _busy || _saving ? null : _runCamera,
                        ),
                      ],
                    ),
                    const SizedBox(height: LumeSpace.x2),
                    Center(
                      child: LumeButton(
                        key: LumePassportTool.chooseDifferentKey,
                        label: l.passportChooseDifferent,
                        onPressed: _busy || _saving ? null : _runGallery,
                        small: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.passportRequirements,
            child: LumeRows(
              key: LumePassportTool.requirementsKey,
              children: <Widget>[
                LumeCompactRow(
                  icon: LumeIcons.check,
                  label: l.passportReqBackground,
                  chevron: false,
                ),
                LumeCompactRow(
                  icon: LumeIcons.check,
                  label: l.passportReqExpression,
                  chevron: false,
                ),
                LumeCompactRow(
                  icon: LumeIcons.check,
                  label: l.passportReqGlasses,
                  chevron: false,
                ),
                LumeCompactRow(
                  icon: LumeIcons.check,
                  label: l.passportReqRecent,
                  chevron: false,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.passportSizes,
            child: LumeTable(
              key: LumePassportTool.sizesKey,
              label: l.passportSizes,
              columns: <LumeColumn>[
                LumeColumn(label: l.passportDocument),
                LumeColumn(label: l.passportSize, numeric: true),
                LumeColumn(label: l.passportDpi, numeric: true),
              ],
              rows: <List<String>>[
                <String>[l.passportPassport, LumePassportSpec.intl.sizeLabel, '600'],
                <String>[l.passportVisaUS, LumePassportSpec.us.sizeLabel, '600'],
                <String>[l.passportIdCard, LumePassportSpec.intl.sizeLabel, '600'],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.photoguide__frame` — the placement guide shown before a photo exists:
/// a soft frame with a silhouette, standing in for a live camera preview.
class _GuideFrame extends StatelessWidget {
  const _GuideFrame({super.key, required this.hint});

  final String hint;

  static const double height = 200;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      label: hint,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: LumeRadius.brLg,
          child: Container(
            height: height,
            width: double.infinity,
            color: lume.tintAccent,
            alignment: Alignment.center,
            child: Container(
              width: 108,
              height: 132,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: lume.accent400, width: 2),
              ),
              alignment: Alignment.center,
              child: LumeIcon.large(LumeIcons.user, color: lume.accent600),
            ),
          ),
        ),
      ),
    );
  }
}

/// The photo as [LumePassportProcessor] actually cropped it, at its own
/// aspect ratio rather than stretched into a fixed box.
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({super.key, required this.bytes, this.semanticLabel});

  final Uint8List bytes;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return ClipRRect(
      borderRadius: LumeRadius.brLg,
      child: Container(
        color: lume.bgSunk,
        alignment: Alignment.center,
        constraints: const BoxConstraints(maxHeight: 260),
        child: Semantics(
          label: semanticLabel,
          image: true,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

/// `.photoguide__specs` — the four small label/value chips under the frame.
class _SpecRow extends StatelessWidget {
  const _SpecRow({super.key, required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Wrap(
      spacing: LumeSpace.x4,
      runSpacing: LumeSpace.x2,
      children: <Widget>[
        for (final (String label, String value) in items)
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  value,
                  style: LumeType.natural(
                    context,
                    context.lumeType.cardTitle,
                  ).copyWith(color: lume.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: lume.text3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
