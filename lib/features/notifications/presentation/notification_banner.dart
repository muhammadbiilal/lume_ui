/// `.nbanner` — a notification above whatever is showing.
///
/// The third surface, and the rule that makes it a surface at all: **an event
/// reaches the reader through exactly one of them**. Push when they are away,
/// a banner when they are here and it is worth interrupting for, the centre
/// otherwise. Never two for one event.
///
/// Three things follow from that and are enforced here rather than hoped for:
///
/// * it never appears while the notification centre is the screen — the
///   reader is already looking at the list it would be duplicating;
/// * it never appears over a sheet or a dialog. The reference's scrim is
///   z-index 50 and the banner 70, which would put it *above* a blocking
///   question; but the reference also only ticks while no sheet is up, so the
///   case never arises there. Here it is a condition rather than an accident.
///
/// * it never lies over anything. The reference places it absolutely, over
///   the header on a phone and the pane's bottom corner on a tablet; here it
///   takes a measured slot of its own and the shell is laid out below it
///   (C92).
///
/// It withholds exactly what a row in the centre withholds, because it is
/// given the same already-resolved [LumeNotification]: there is nothing on
/// this widget to leak from.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/navigation/lume_shell.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_motion.dart';
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

/// Holds one banner above [child], and decides when it may be there.
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

class _LumeNotificationBannerHostState extends State<LumeNotificationBannerHost>
    with SingleTickerProviderStateMixin {
  Timer? _life;

  /// What should be showing: the notification, unless it is suppressed or
  /// the reader dismissed it.
  LumeNotification? _active;

  /// What is laid out in the slot — kept through the closing transition.
  LumeNotification? _shown;

  /// The one the reader dismissed, so it is not brought back.
  String? _dismissed;

  /// The events already announced. A banner withheld under a sheet and shown
  /// again when the sheet closes is the same event, heard once.
  final Set<String> _announced = <String>{};

  /// Pointers down on the screen. While any is down, a transition does not
  /// start and does not finish: the layout under a finger never moves.
  int _pointers = 0;

  /// 0 — no slot; 1 — the slot fully open.
  late final AnimationController _slot = AnimationController(
    vsync: this,
    duration: LumeMotion.standard,
  );

  /// The shell keeps its element, and every state under it, whether or not
  /// a banner is in the slot above it.
  static const Key _shellKey = ValueKey<String>('nbanner.shell');

  @override
  void initState() {
    super.initState();
    _slot.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.dismissed && _active == null && mounted) {
        setState(() => _shown = null);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the slot opens and closes in one frame.
    _slot.duration = LumeMotion.duration(context, LumeMotion.standard);
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
    _slot.dispose();
    super.dispose();
  }

  void _sync() {
    final LumeNotification? n = widget.notification;
    _active = widget.suppressed || n == null || n.id == _dismissed ? null : n;
    if (_active == null) _life?.cancel();
    _apply();
  }

  /// Bring the slot to what should be showing — unless a pointer is down,
  /// in which case it waits, and a transition under way pauses, until the
  /// last pointer lifts.
  void _apply() {
    if (!mounted || _pointers > 0) return;
    final LumeNotification? next = _active;
    if (next == null) {
      if (_shown != null) _slot.reverse();
      return;
    }
    if (_shown?.id != next.id) {
      setState(() => _shown = next);
      // Announced separately from the picture, because a banner that is
      // only a picture is a banner a screen reader never mentions.
      if (_announced.add(next.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          SemanticsService.sendAnnouncement(
            View.of(context),
            '${next.title}. ${next.body}',
            Directionality.of(context),
          );
        });
      }
    }
    // Its life counts from when it begins to show, not from when it was
    // held back: a notice deferred is not a notice used up.
    if (_life == null || !_life!.isActive) {
      _life = Timer(LumeNotificationBanner.life, _dismiss);
    }
    _slot.forward();
  }

  void _dismiss() {
    _life?.cancel();
    _dismissed = _shown?.id ?? _active?.id;
    _active = null;
    _apply();
    widget.onDismissed?.call();
  }

  void _down(PointerDownEvent _) {
    _pointers++;
    if (_slot.isAnimating) _slot.stop();
  }

  void _up(PointerEvent _) {
    if (_pointers > 0) _pointers--;
    if (_pointers == 0) _apply();
  }

  @override
  Widget build(BuildContext context) {
    final LumeNotification? n = _shown;
    final MediaQueryData media = MediaQuery.of(context);

    // The banner takes a slot of its own above the shell rather than
    // floating over it (C92). The slot opens and closes by animation, and
    // the shell moves with it: never under a finger that is down, and never
    // taking a tap while it moves. A tap during a transition lands on
    // nothing rather than on whatever slid under it.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedBuilder(
        animation: _slot,
        builder: (BuildContext context, Widget? _) {
          final double t = _slot.value;
          final bool moving = t > 0 && t < 1;
          return AbsorbPointer(
            absorbing: moving,
            child: CustomMultiChildLayout(
              delegate: _BannerFirst(_slot),
              children: <Widget>[
                // The shell first in paint order and the banner after it,
                // as the reference stacks them: something the shell paints
                // can hide what was painted before it from a screen reader,
                // and the banner must not be that. The layout, not the
                // paint order, puts it on top.
                LayoutId(
                  key: _shellKey,
                  id: _BannerFirst.shell,
                  child: MediaQuery(
                    // The slot takes the status-bar inset as it opens; the
                    // shell pads for what the slot has not yet covered.
                    data: n == null || t == 0
                        ? media
                        : media.copyWith(
                            padding: media.padding.copyWith(
                              top: media.padding.top * (1 - t),
                            ),
                            viewPadding: media.viewPadding.copyWith(
                              top: media.viewPadding.top * (1 - t),
                            ),
                          ),
                    child: widget.child,
                  ),
                ),
                if (n != null)
                  LayoutId(
                    id: _BannerFirst.banner,
                    child: _BannerSlot(
                      safeTop: media.padding.top,
                      // Escape withdraws it for a keyboard reader focused
                      // inside it.
                      child: CallbackShortcuts(
                        bindings: <ShortcutActivator, VoidCallback>{
                          const SingleActivator(LogicalKeyboardKey.escape):
                              _dismiss,
                        },
                        child: LumeNotificationBanner(
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
            ),
          );
        },
      ),
    );
  }
}

/// The banner's slot is measured first, across the top, and opened by
/// [progress]: the slot slides down from above, and the shell takes the
/// rest of the screen below what is open of it.
class _BannerFirst extends MultiChildLayoutDelegate {
  _BannerFirst(this.progress) : super(relayout: progress);

  final Animation<double> progress;

  static const String shell = 'shell';
  static const String banner = 'banner';

  @override
  void performLayout(Size size) {
    double top = 0;
    if (hasChild(banner)) {
      final double h = layoutChild(
        banner,
        BoxConstraints(minWidth: size.width, maxWidth: size.width),
      ).height;
      top = h * progress.value;
      positionChild(banner, Offset(0, top - h));
    }
    layoutChild(
      shell,
      BoxConstraints.tight(
        Size(size.width, (size.height - top).clamp(0, size.height)),
      ),
    );
    positionChild(shell, Offset(0, top));
  }

  @override
  bool shouldRelayout(_BannerFirst oldDelegate) =>
      oldDelegate.progress != progress;
}

/// The measured room a banner takes: under the status bar and 8 from it on
/// a phone, inset 12 from each edge; at medium and expanded, 400 wide at the
/// end, as the reference sizes it, with 24 of air.
class _BannerSlot extends StatelessWidget {
  const _BannerSlot({required this.safeTop, required this.child});

  final double safeTop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool compact = context.widthClass == LumeWidthClass.compact;
    final double inset = compact
        ? LumeShellMetrics.bannerInsetCompact
        : LumeShellMetrics.bannerInsetPane;
    return ColoredBox(
      color: context.lume.bg,
      // Above the shell's own `Scaffold`, so it brings its own material:
      // without one, text has no default style to inherit.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            inset,
            safeTop + LumeShellMetrics.bannerTopCompact,
            inset,
            LumeShellMetrics.bannerTopCompact,
          ),
          child: compact
              ? child
              : Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: LumeShellMetrics.bannerWidthPane,
                    ),
                    child: child,
                  ),
                ),
        ),
      ),
    );
  }
}
