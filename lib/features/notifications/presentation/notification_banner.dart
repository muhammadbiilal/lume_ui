/// `.nbanner` — a notification over whatever is showing.
///
/// The third surface, and the rule that makes it a surface at all: **an event
/// reaches the reader through exactly one of them**. Push when they are away,
/// a banner when they are here and it is worth interrupting for, the centre
/// otherwise. Never two for one event.
///
/// Two things follow from that and are enforced here rather than hoped for:
///
/// * it never appears while the notification centre is the screen — the
///   reader is already looking at the list it would be duplicating;
/// * it never appears over a sheet or a dialog. The reference's scrim is
///   z-index 50 and the banner 70, which would put it *above* a blocking
///   question; but the reference also only ticks while no sheet is up, so the
///   case never arises there. Here it is a condition rather than an accident.
///
/// It withholds exactly what a row in the centre withholds, because it is
/// given the same already-resolved [LumeNotification]: there is nothing on
/// this widget to leak from.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/navigation/lume_shell.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/notification_model.dart';

/// The banner itself. [LumeNotificationBannerHost] decides when it is up.
class LumeNotificationBanner extends StatelessWidget {
  const LumeNotificationBanner({
    super.key,
    required this.notification,
    this.onOpen,
    this.onDismiss,
  });

  final LumeNotification notification;
  final VoidCallback? onOpen;
  final VoidCallback? onDismiss;

  /// `inset-inline: 12px; top: 8px`.
  static const double inset = 12;
  static const double top = 8;

  /// How long it stays before it withdraws on its own.
  static const Duration life = Duration(seconds: 6);

  /// `.nbanner__icon` is 32 × 32 with a 16 px glyph.
  static const double iconSize = 32;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeNotification n = notification;

    return DecoratedBox(
      // The shadow sits outside the clip below, or the clip would cut it off.
      decoration: BoxDecoration(
        borderRadius: LumeRadius.brMd,
        boxShadow: context.lumeShadows.lg,
      ),
      child: ClipRRect(
        borderRadius: LumeRadius.brMd,
        // `backdrop-filter: saturate(1.6) blur(20px)` — the screen under the
        // banner is softened rather than legible through its 94 % card.
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 6, 4),
            decoration: BoxDecoration(
              // `color-mix(in srgb, var(--card) 94%, transparent)`.
              color: lume.card.withValues(alpha: 0.94),
              borderRadius: LumeRadius.brMd,
              border: Border.all(color: lume.border, width: LumeSpace.border),
            ),
            // `align-items: stretch` — the close control is as tall as the banner,
            // which in Flutter means the row has to know its own height first.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: LumePressable(
                      onTap: onOpen,
                      semanticLabel: '${n.title}, ${n.body}',
                      borderRadius: LumeRadius.brSm,
                      minSize: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                color: lume.tintNeutral,
                                borderRadius: LumeRadius.brSm,
                              ),
                              child: Center(
                                child: LumeIcon(
                                  n.icon,
                                  size: LumeSpace.iconSm,
                                  color: lume.text2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    n.title,
                                    style:
                                        LumeType.tracked(
                                          LumeType.natural(
                                            context,
                                            context.lumeType.meta,
                                            size: 13,
                                          ),
                                          -0.024,
                                        ).copyWith(
                                          color: lume.text,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    n.body,
                                    style:
                                        LumeType.natural(
                                          context,
                                          context.lumeType.metaSmall,
                                          size: 11,
                                        ).copyWith(
                                          color: lume.text3,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  LumePressable(
                    onTap: onDismiss,
                    semanticLabel: l.nDismiss,
                    borderRadius: LumeRadius.brSm,
                    minSize: 0,
                    child: SizedBox(
                      width: iconSize,
                      child: Center(
                        child: LumeIcon(
                          LumeIcons.x,
                          size: 14,
                          color: lume.text3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Holds one banner over [child], and decides when it may be there.
class LumeNotificationBannerHost extends StatefulWidget {
  const LumeNotificationBannerHost({
    super.key,
    required this.child,
    this.notification,
    this.suppressed = false,
    this.onOpen,
    this.onDismissed,
  });

  final Widget child;

  /// What to show, or `null` for nothing.
  final LumeNotification? notification;

  /// True while the reader is somewhere a banner must not cover — the
  /// notification centre itself, or under an open sheet or dialog.
  final bool suppressed;

  final ValueChanged<LumeNotification>? onOpen;

  /// Called when the banner goes, however it went.
  final VoidCallback? onDismissed;

  @override
  State<LumeNotificationBannerHost> createState() =>
      _LumeNotificationBannerHostState();
}

class _LumeNotificationBannerHostState
    extends State<LumeNotificationBannerHost> {
  Timer? _life;
  LumeNotification? _showing;

  bool get _mayShow => widget.notification != null && !widget.suppressed;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(LumeNotificationBannerHost old) {
    super.didUpdateWidget(old);
    if (old.notification?.id != widget.notification?.id ||
        old.suppressed != widget.suppressed) {
      _sync();
    }
  }

  @override
  void dispose() {
    _life?.cancel();
    super.dispose();
  }

  void _sync() {
    _life?.cancel();
    final LumeNotification? next = _mayShow ? widget.notification : null;
    if (next == null) {
      if (_showing != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _showing = null);
        });
      }
      return;
    }
    _showing = next;
    // Announced separately from the picture, because a banner that is only a
    // picture is a banner a screen reader never mentions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${next.title}. ${next.body}',
        Directionality.of(context),
      );
    });
    _life = Timer(LumeNotificationBanner.life, _dismiss);
  }

  void _dismiss() {
    _life?.cancel();
    if (mounted) setState(() => _showing = null);
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final LumeNotification? n = _mayShow ? _showing : null;

    return Stack(
      children: <Widget>[
        widget.child,
        if (n != null)
          // The shell's own banner slot, so the banner sits where the shell
          // measured it at every width: dropped in from the top on a phone,
          // settled into the trailing corner at medium and expanded
          // (`responsive.css`), where the top belongs to the status strip.
          Positioned.fill(
            // Above the shell's own `Scaffold`, so it brings its own
            // material: without one, text has no default style to inherit.
            child: Material(
              type: MaterialType.transparency,
              child: LumeOverlayHost(
                banner: LumeNotificationBanner(
                  notification: n,
                  onOpen: () {
                    _dismiss();
                    widget.onOpen?.call(n);
                  },
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
