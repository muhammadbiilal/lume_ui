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
    this.onClose,
    this.closeLabel,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onClose;
  final String? closeLabel;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool compact = context.isCompact;

    return Container(
      constraints: BoxConstraints(
        maxWidth: compact ? double.infinity : 520,
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: lume.card,
        // Compact rounds only the top, because the sheet meets the bottom
        // edge. Above compact it floats, so every corner rounds.
        borderRadius: compact ? LumeRadius.sheetTop : LumeRadius.brXl,
        border: compact
            ? null
            : Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.lg,
      ),
      child: SafeArea(
        top: false,
        bottom: compact,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (compact)
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: lume.border2,
                    borderRadius: LumeRadius.full,
                  ),
                ),
              ),
            if (title != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: LumeSpace.x5,
                  end: LumeSpace.x3,
                  top: LumeSpace.x3,
                  bottom: LumeSpace.x2,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title!,
                          style: LumeType.fit(
                            context,
                            context.lumeType.section,
                          ).copyWith(color: lume.text),
                        ),
                      ),
                    ),
                    if (onClose != null)
                      LumePressable(
                        onTap: onClose,
                        semanticLabel: closeLabel ?? 'Close',
                        borderRadius: LumeRadius.full,
                        child: LumeIcon(
                          LumeIcons.x,
                          size: LumeSpace.iconMd,
                          color: lume.text3,
                        ),
                      ),
                  ],
                ),
              ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  LumeSpace.x5,
                  LumeSpace.x2,
                  LumeSpace.x5,
                  LumeSpace.x5,
                ),
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

  if (!compact) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: scrim,
      barrierLabel: barrierLabel,
      builder: (BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(LumeSpace.x6),
          child: Material(color: Colors.transparent, child: child),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    barrierColor: scrim,
    barrierLabel: barrierLabel,
    builder: (BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    ),
  );
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
