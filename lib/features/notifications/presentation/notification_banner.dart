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

class _LumeNotificationBannerHostState
    extends State<LumeNotificationBannerHost> {
  Timer? _life;
  LumeNotification? _showing;

  /// The events already announced. A banner withheld under a sheet and shown
  /// again when the sheet closes is the same event, heard once.
  final Set<String> _announced = <String>{};

  /// The shell keeps its element, and every state under it, whether or not
  /// a banner is in the slot above it.
  static const Key _shellKey = ValueKey<String>('nbanner.shell');

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
    // picture is a banner a screen reader never mentions — and announced
    // once, however often a sheet withholds it and gives it back.
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
    final MediaQueryData media = MediaQuery.of(context);

    // The banner takes a slot of its own above the shell rather than
    // floating over it (C92). The reference's `.nbanner` is absolutely
    // placed over the page — over the header's Back and Save on a phone, and
    // over the pane's bottom corner, where a form's Save sits, on a tablet.
    // Here the shell is laid out in what the banner leaves, so nothing the
    // reader needs is under it, and there are no invisible bounds to catch a
    // tap meant for something else.
    return CustomMultiChildLayout(
      delegate: _BannerFirst(),
      children: <Widget>[
        // The shell first in paint order and the banner after it, as the
        // reference stacks them: something the shell paints can hide what
        // was painted before it from a screen reader, and the banner must
        // not be that. The layout, not the paint order, puts it on top.
        LayoutId(
          key: _shellKey,
          id: _BannerFirst.shell,
          child: MediaQuery(
            // The slot has taken the status-bar inset; the shell below it
            // must not pad for it a second time.
            data: n == null
                ? media
                : media
                      .removePadding(removeTop: true)
                      .removeViewPadding(removeTop: true),
            child: widget.child,
          ),
        ),
        if (n != null)
          LayoutId(
            id: _BannerFirst.banner,
            child: _BannerSlot(
              safeTop: media.padding.top,
              // Escape withdraws it for a keyboard reader focused inside it.
              child: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.escape): _dismiss,
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
    );
  }
}

/// The banner's slot is measured first, across the top; the shell takes
/// the rest, below it.
class _BannerFirst extends MultiChildLayoutDelegate {
  static const String shell = 'shell';
  static const String banner = 'banner';

  @override
  void performLayout(Size size) {
    double top = 0;
    if (hasChild(banner)) {
      top = layoutChild(
        banner,
        BoxConstraints(minWidth: size.width, maxWidth: size.width),
      ).height;
      positionChild(banner, Offset.zero);
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
  bool shouldRelayout(_BannerFirst oldDelegate) => false;
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
