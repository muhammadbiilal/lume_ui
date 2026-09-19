/// Overlays: the adaptive sheet, the dialog, and the toast with its Undo.
///
/// The sheet is where the width classes show up in a component rather than in
/// a layout. Measured from `responsive.css`:
///
/// * compact — full-bleed, 26 px top radius, safe-area padding at the bottom;
/// * medium and expanded — a centred surface `min(520, 100% − 48)` wide,
///   24 px from the bottom, rounded on every corner.
///
/// A bottom sheet is a phone gesture. At tablet width it stops pretending to
/// be one and rises as a card with air around it.
///
/// The toast carries Undo where reversal is safe (§7, §10). Success is
/// confirmed **without blocking the next action**, so it is never a dialog and
/// never steals focus — but it does announce itself, because a confirmation a
/// screen-reader user never hears is not a confirmation.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../layout/lume_breakpoint.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// The content of a Lume sheet: a grabber, an optional title, the body.
class LumeSheet extends StatelessWidget {
  const LumeSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.onClose,
    this.closeLabel,
    this.tall = false,
    this.confirm = false,
  });

  final Widget child;
  final String? title;

  /// `.sheet__sub` — the line under the title, 12 / 500, muted.
  final String? subtitle;
  final VoidCallback? onClose;
  final String? closeLabel;

  /// `.sheet--tall` — search and Personalisation, which are lists rather than
  /// decisions and are given six more per cent of the viewport for them.
  final bool tall;

  /// `.sheet--confirm` — the destructive confirmation (`#sheet-recdelete`):
  /// no head and no body padding, the `.dconfirm` block straight under the
  /// grab, and 20 below it rather than 18.
  final bool confirm;

  /// `.sheet--confirm { padding-bottom: max(20px, …) }`.
  static const double confirmFloor = 20;

  /// `.sheet { max-height: 86% }`.
  static const double heightFraction = 0.86;

  /// `.sheet--tall { max-height: 92% }`.
  static const double tallHeightFraction = 0.92;

  /// `padding-bottom: max(18px, env(safe-area-inset-bottom))` — a floor, not
  /// just the inset, so a device without one still has a bottom edge.
  static const double bottomFloor = 18;

  /// `.closebtn { width: 30px; height: 30px }`.
  static const double closeSize = 30;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool compact = context.isCompact;
    final double inset = MediaQuery.paddingOf(context).bottom;
    final double floor = confirm ? confirmFloor : bottomFloor;

    return Container(
      constraints: BoxConstraints(
        maxWidth: compact ? double.infinity : 520,
        maxHeight:
            MediaQuery.sizeOf(context).height *
            (tall ? tallHeightFraction : heightFraction),
      ),
      decoration: BoxDecoration(
        color: lume.card,
        // Compact rounds only the top, because the sheet meets the bottom
        // edge. Above compact it floats, so every corner rounds.
        borderRadius: compact ? LumeRadius.sheetTop : LumeRadius.brXl,
        // `border: 1px solid var(--border); border-bottom: 0` — the hairline
        // is there at every width; only the bottom edge is absent, because
        // there is nothing below it to separate from.
        border: BorderDirectional(
          top: BorderSide(color: lume.border, width: LumeSpace.border),
          start: BorderSide(color: lume.border, width: LumeSpace.border),
          end: BorderSide(color: lume.border, width: LumeSpace.border),
          bottom: compact
              ? BorderSide.none
              : BorderSide(color: lume.border, width: LumeSpace.border),
        ),
        boxShadow: context.lumeShadows.lg,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: compact ? (inset > floor ? inset : floor) : floor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // The grab stays when the sheet floats: `responsive.css` moves and
            // rounds `.sheet` at medium and expanded, and leaves
            // `.sheet__grab` where it is.
            Center(
              child: Container(
                // `.sheet__grab { width: 36px; height: 4px;
                // margin: 9px auto 0 }` — no bottom margin: the head's own
                // 14 points of top padding is the gap under it.
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 9),
                decoration: BoxDecoration(
                  color: lume.border2,
                  borderRadius: LumeRadius.full,
                ),
              ),
            ),
            if (title != null)
              Padding(
                // `.sheet__head { padding: 14px 18px 10px }`.
                padding: const EdgeInsetsDirectional.only(
                  start: 18,
                  end: 18,
                  top: 14,
                  bottom: 10,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Semantics(
                            header: true,
                            child: Text(
                              title!,
                              style: LumeType.fit(
                                context,
                                context.lumeType.section,
                              ).copyWith(color: lume.text),
                            ),
                          ),
                          if (subtitle != null) ...<Widget>[
                            // `.sheet__sub { margin-top: 2px }`.
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style:
                                  LumeType.natural(
                                    context,
                                    context.lumeType.metaSmall,
                                    size: 12,
                                  ).copyWith(
                                    color: lume.text3,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onClose != null) ...<Widget>[
                      // `.sheet__head { gap: 12px }`.
                      const SizedBox(width: 12),
                      // `.closebtn` — a 30-point tinted circle holding a
                      // 15-point cross. Its 44-point target overhangs the
                      // head's own padding rather than growing the head, the
                      // rule the toolbar's back control keeps (D6).
                      SizedBox(
                        width: closeSize,
                        height: closeSize,
                        child: OverflowBox(
                          maxWidth: LumeSpace.tap,
                          maxHeight: LumeSpace.tap,
                          child: LumePressable(
                            onTap: onClose,
                            semanticLabel: closeLabel ?? 'Close',
                            borderRadius: LumeRadius.full,
                            minSize: LumeSpace.tap,
                            child: Center(
                              child: Container(
                                width: closeSize,
                                height: closeSize,
                                decoration: BoxDecoration(
                                  color: lume.tintNeutral,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: LumeIcon(
                                    LumeIcons.x,
                                    size: 15,
                                    color: lume.text2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Flexible(
              // `.sheet__body { padding: 0 18px 8px }` — no top padding,
              // because the head above it already ends with ten.
              child: Padding(
                padding: confirm
                    ? EdgeInsets.zero
                    : const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents [child] as a Lume sheet, adapted to the width class.
///
/// Below expanded it slides from the bottom; at expanded width it is a centred
/// dialog, because a bottom sheet on a 1100 px surface is a phone gesture
/// stretched across a desk.
Future<T?> showLumeSheet<T>({
  required BuildContext context,
  required Widget child,
  bool dismissible = true,
  String? barrierLabel,
}) {
  final bool compact = context.isCompact;
  final Color scrim = context.lume.overlay;

  // `.scrim` is z-index 50 and `.tabbar` is 40: the scrim covers the
  // navigation bar, so the sheet belongs to the root navigator rather than to
  // the branch it was raised from. A branch-navigator sheet would be drawn
  // *under* the bar.
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );

  if (!compact) {
    return navigator.push<T>(
      _LumeDialogRoute<T>(
        context: context,
        themes: themes,
        barrierDismissible: dismissible,
        barrierColor: scrim,
        barrierLabel: barrierLabel,
        // `responsive.css` at medium and expanded: `left: 50%; bottom: 24px;
        // width: min(520px, 100% - 48px)` — a surface rising from the bottom
        // with air around it, not a dialog in the middle of the screen.
        builder: (BuildContext context) => Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              LumeSpace.x6,
              LumeSpace.x6,
              LumeSpace.x6,
              LumeSpace.x6 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Material(color: Colors.transparent, child: child),
          ),
        ),
      ),
    );
  }

  final MaterialLocalizations words = MaterialLocalizations.of(context);
  return navigator.push<T>(
    _LumeSheetRoute<T>(
      capturedThemes: themes,
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      modalBarrierColor: scrim,
      barrierLabel: barrierLabel ?? words.scrimLabel,
      barrierOnTapHint: words.scrimOnTapHint(words.bottomSheetLabel),
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: child,
      ),
    ),
  );
}

/// `.scrim { backdrop-filter: blur(3px) }`.
///
/// The scrim does not only darken what is behind a sheet; it softens it, so
/// the destination reads as set aside rather than still live. A CSS blur
/// radius is a standard deviation, which is what a sigma is.
const double kLumeScrimBlur = 3;

/// The route's own barrier, blurred — and the blur fades in with the colour,
/// because `.scrim`'s opacity transition carries both.
Widget _blurred(Animation<double>? animation, Widget barrier) {
  if (animation == null) return barrier;
  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final double sigma = kLumeScrimBlur * animation.value;
      if (sigma <= 0) return child!;
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      );
    },
    child: barrier,
  );
}

/// A bottom sheet whose scrim blurs.
class _LumeSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _LumeSheetRoute({
    required super.builder,
    required super.isScrollControlled,
    super.capturedThemes,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.backgroundColor,
    super.modalBarrierColor,
    super.isDismissible,
    super.enableDrag,
  });

  @override
  Widget buildModalBarrier() => _blurred(animation, super.buildModalBarrier());
}

/// The same, where the sheet rises as a centred card.
class _LumeDialogRoute<T> extends DialogRoute<T> {
  _LumeDialogRoute({
    required super.context,
    required super.builder,
    super.themes,
    super.barrierColor,
    super.barrierDismissible,
    super.barrierLabel,
  });

  @override
  Widget buildModalBarrier() => _blurred(animation, super.buildModalBarrier());
}

/// A focused decision with explicit actions.
///
/// Deliberately a thin wrapper: the *content* — naming the record, stating the
/// consequence, labelling the destructive action with its verb — is
/// `LumeDeleteConfirmation`'s job, and this only presents it.
Future<T?> showLumeDialog<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool dismissible = true,
}) => showLumeSheet<T>(
  context: context,
  dismissible: dismissible,
  child: LumeSheet(title: title, child: child),
);

/// What a toast is reporting.
enum LumeToastTone { success, error, info }

/// The toast's content and its optional Undo.
@immutable
class LumeToastData {
  const LumeToastData({
    required this.message,
    this.tone = LumeToastTone.success,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final LumeToastTone tone;

  /// "Undo". Offered **only** where reversal is actually possible — a family
  /// whose deletion is irreversible must not be given one, because an Undo
  /// that cannot be honoured is worse than none.
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// `.toast` — a high-contrast pill above the navigation.
class LumeToast extends StatelessWidget {
  const LumeToast({super.key, required this.data});

  final LumeToastData data;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final Color ink = lume.bg;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: LumeSpace.tap),
        padding: const EdgeInsetsDirectional.only(
          start: LumeSpace.x4,
          end: LumeSpace.x2,
          top: LumeSpace.x2,
          bottom: LumeSpace.x2,
        ),
        decoration: BoxDecoration(
          color: lume.text,
          borderRadius: LumeRadius.full,
          boxShadow: context.lumeShadows.lg,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeIcon(
              switch (data.tone) {
                LumeToastTone.success => LumeIcons.checkCircle,
                LumeToastTone.error => LumeIcons.alert,
                LumeToastTone.info => LumeIcons.info,
              },
              size: LumeSpace.iconMd,
              color: data.tone == LumeToastTone.error ? lume.rose : lume.accent,
            ),
            const SizedBox(width: LumeSpace.x2),
            Flexible(
              child: Text(
                data.message,
                style: LumeType.fit(
                  context,
                  context.lumeType.bodyStrong,
                ).copyWith(color: ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (data.actionLabel != null) ...<Widget>[
              const SizedBox(width: LumeSpace.x3),
              LumePressable(
                onTap: data.onAction,
                semanticLabel: data.actionLabel,
                borderRadius: LumeRadius.full,
                minSize: LumeSpace.tap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: LumeSpace.x3),
                  child: Text(
                    data.actionLabel!,
                    style: LumeType.fit(
                      context,
                      context.lumeType.cardTitle,
                    ).copyWith(color: lume.accent),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows a toast above the navigation, and announces it.
///
/// Does not block, does not steal focus, and does not wait to be dismissed —
/// §7 is explicit that routine completion is confirmed without interrupting.
/// The announcement is separate from the visual, because a toast a screen
/// reader skips is a confirmation that did not happen.
void showLumeToast(BuildContext context, LumeToastData data) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    data.message,
    Directionality.of(context),
  );

  final OverlayState? overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final OverlayEntry entry;
  Timer? timer;

  void dismiss() {
    timer?.cancel();
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (BuildContext context) => Positioned(
      left: LumeSpace.x5,
      right: LumeSpace.x5,
      bottom: MediaQuery.paddingOf(context).bottom + 28,
      child: Directionality(
        textDirection: Directionality.of(context),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: LumeToast(
              data: LumeToastData(
                message: data.message,
                tone: data.tone,
                actionLabel: data.actionLabel,
                onAction: data.onAction == null
                    ? null
                    : () {
                        dismiss();
                        data.onAction!();
                      },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  // Long enough to read and reach Undo, short enough not to linger.
  timer = Timer(
    Duration(milliseconds: data.actionLabel != null ? 6000 : 3200),
    dismiss,
  );
}
