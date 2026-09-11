/// The application shell: ambient ground, status strip, content outlet,
/// navigation and overlay host.
///
/// `index.html` is a shell rather than a page — a mesh, a status strip, an
/// empty `<main id="screens">`, two navigations built from one destination set,
/// a banner, a toast, a scrim and two overlay roots. Every screen is mounted
/// into the outlet and none of them owns any of that furniture. This is the
/// same arrangement.
///
/// **The three layouts** (`responsive.css`, Design System §1, §6, §10):
///
/// | class | shape |
/// |---|---|
/// | compact | one column; the bar floats over the content, inset 12 |
/// | medium | status strip across the top, 84 px rail down the start edge |
/// | expanded | the same grid with a 244 px sidebar |
///
/// **What the shell measures.** `breakpoint.js` observes `.app` — the whole
/// shell including its navigation, not the content area and not the window —
/// and `.app` is capped (560 below 600, 1366 above it) and centred. So the cap
/// is applied first and [LumeBreakpointScope] measures inside it, which is why
/// the width class Flutter resolves and the width class the reference draws are
/// the same number. The cap never argues with itself: the 560 one applies only
/// when the *window* is already below 600, where the shell is compact anyway.
///
/// **Three native differences**, each recorded in KNOWN_DIFFERENCES:
///
/// * The prototype dresses itself as a device on a desk above 600 — 24 px of
///   stage padding, a soft radial ground, a rounded frame. That is a browser
///   affordance for showing a tablet layout on a monitor. On a tablet the
///   application *is* the screen, so the shell fills the window.
/// * The compact status strip is a drawing of a phone's: 9:41, signal, wifi,
///   battery. The device draws the real one. Compact reserves the inset and
///   shows nothing in it; medium and expanded keep the strip, because there it
///   is genuine application chrome — the wordmark and the clock — and drop the
///   three device glyphs.
/// * The floating bar hides while the keyboard is up. `100dvh` does not track
///   the keyboard, so in the browser the bar ends up behind it; hiding is the
///   honest native reading of the same result.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/lume_icon.dart';
import '../icons/lume_icons.dart';
import '../layout/lume_breakpoint.dart';
import '../theme/lume/lume_colors.dart';
import '../theme/lume/lume_motion.dart';
import '../theme/lume/lume_space.dart';
import '../theme/lume/lume_theme.dart';
import '../theme/lume/lume_type.dart';
import 'lume_destination.dart';
import 'lume_navigation_surfaces.dart';

/// The clearances a screen has to respect, published by the shell so no screen
/// counts the bar's height for itself.
abstract final class LumeShellMetrics {
  /// `.screen { padding-bottom: 118px }` — the 62 px bar, its 12 px inset, and
  /// 44 px of air so the last row is not tucked under the glass.
  static const double contentBottomCompact = 118;

  /// `:root[data-bp] .screen { padding-bottom: 40px }` — no floating bar to
  /// clear at these widths.
  static const double contentBottomPane = 40;

  /// `.statusbar` at medium and expanded: 12 px block padding on a 1 px rule.
  static const double statusStripPadding = 12;

  /// `.toast { bottom: 92px }` — above the bar, not under it. 28 at medium and
  /// expanded, where there is no bar to clear.
  static const double toastBottomCompact = 92;
  static const double toastBottomPane = 28;

  /// `.nbanner` — inset 12 from each edge, 8 from the top, at compact.
  static const double bannerInsetCompact = 12;
  static const double bannerTopCompact = 8;

  /// At expanded the banner leaves the top and settles into the end corner:
  /// `bottom: 24; inset-inline-end: 24; width: min(400px, …)`.
  static const double bannerInsetPane = 24;
  static const double bannerWidthPane = 400;
}

/// Where a sheet, a toast and a notification banner are raised.
///
/// They belong to the shell rather than to whichever screen opened one —
/// `index.html` puts `#overlay-root`, `.toast` and `.nbanner` outside
/// `<main id="screens">` for exactly that reason. A screen that is left while
/// its own toast is showing would otherwise take the toast with it.
///
/// Positions are the measured ones, and they move with the width class: the
/// toast clears the floating bar at compact and does not need to at medium or
/// expanded; the banner drops in from the top on a phone and settles into the
/// end corner on a tablet.
class LumeOverlayHost extends StatelessWidget {
  const LumeOverlayHost({
    super.key,
    this.scrim = false,
    this.onDismissScrim,
    this.scrimLabel,
    this.sheet,
    this.banner,
    this.toast,
  });

  /// Dims and blurs what is behind a sheet or a dialog. `.scrim`, z-50.
  final bool scrim;
  final VoidCallback? onDismissScrim;
  final String? scrimLabel;

  /// A bottom sheet or a dialog, already built. Raised above the scrim.
  final Widget? sheet;

  /// The in-app notification banner, z-70.
  final Widget? banner;

  /// A confirmation, z-70. Never blocks the next action.
  final Widget? toast;

  @override
  Widget build(BuildContext context) {
    final bool compact = context.widthClass == LumeWidthClass.compact;
    final EdgeInsets safe = MediaQuery.paddingOf(context);

    return Stack(
      children: <Widget>[
        if (scrim || sheet != null)
          Positioned.fill(
            child: LumeScrim(
              open: scrim,
              onDismiss: onDismissScrim,
              label: scrimLabel,
            ),
          ),
        if (sheet != null) Positioned.fill(child: sheet!),
        if (banner != null)
          if (compact)
            PositionedDirectional(
              start: LumeShellMetrics.bannerInsetCompact,
              end: LumeShellMetrics.bannerInsetCompact,
              top: safe.top + LumeShellMetrics.bannerTopCompact,
              child: banner!,
            )
          else
            PositionedDirectional(
              end: LumeShellMetrics.bannerInsetPane,
              bottom: LumeShellMetrics.bannerInsetPane,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LumeShellMetrics.bannerWidthPane,
                ),
                child: banner!,
              ),
            ),
        if (toast != null)
          Positioned(
            left: 0,
            right: 0,
            bottom:
                (compact
                    ? LumeShellMetrics.toastBottomCompact
                    : LumeShellMetrics.toastBottomPane) +
                safe.bottom,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: LumeSpace.x6),
                child: toast!,
              ),
            ),
          ),
      ],
    );
  }
}

/// Everything the shell needs in order to draw itself around a screen.
class LumeShell extends StatelessWidget {
  const LumeShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
    this.brand = 'Lume',
    this.clock,
    this.navigationLabel,
    this.overlay,
    this.showNavigation = true,
  });

  /// The destination set, already personalised. The shell never builds it —
  /// see [LumeDestinations].
  final List<LumeDestination> destinations;

  /// Which of [destinations] is current, or `-1` when the current destination
  /// is not a tab: Explore reached from a link, a tool, the notification
  /// centre. The pill hides rather than pointing somewhere wrong.
  final int selectedIndex;

  final ValueChanged<int> onSelected;

  /// The content outlet — one screen, or a nested navigator holding a branch's
  /// whole stack.
  final Widget child;

  /// The wordmark in the status strip and at the top of the sidebar.
  final String brand;

  /// The clock in the status strip. `null` leaves the slot empty rather than
  /// inventing a time.
  final String? clock;

  /// `aria-label="Main"` on both navigations.
  final String? navigationLabel;

  /// Sheets, dialogs and the first-run flow, raised over everything. They
  /// belong to the shell rather than to whichever screen happened to open one.
  final Widget? overlay;

  /// `false` hides both navigations — onboarding and authentication cover the
  /// shell rather than sitting inside it.
  final bool showNavigation;

  /// The shell's own width, before it is measured.
  ///
  /// `.app { max-width: 1366 }`, and `@media (max-width: 599px) { 560 }`. The
  /// media query reads the *window*, so this does too.
  static double capFor(double windowWidth) =>
      windowWidth < LumeBreakpoints.medium ? 560 : LumeSpace.shellMax;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double cap = capFor(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: lume.bg,
      // The shell handles the keyboard itself. Letting Scaffold do it would
      // shrink the whole shell, and a tablet with a keyboard open is under
      // 480 points tall — so the rail would vanish mid-sentence and the width
      // class would be reporting the keyboard rather than the device. The
      // outlet absorbs the inset instead, which is where a form needs it.
      resizeToAvoidBottomInset: false,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cap),
          child: LumeBreakpointScope(
            child: Builder(
              builder: (BuildContext context) => _ShellBody(
                destinations: destinations,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
                brand: brand,
                clock: clock,
                navigationLabel: navigationLabel,
                overlay: overlay,
                showNavigation: showNavigation,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.brand,
    required this.clock,
    required this.navigationLabel,
    required this.overlay,
    required this.showNavigation,
    required this.child,
  });

  final List<LumeDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String brand;
  final String? clock;
  final String? navigationLabel;
  final Widget? overlay;
  final bool showNavigation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LumeWidthClass klass = context.widthClass;
    final bool compact = klass == LumeWidthClass.compact;

    return Stack(
      children: <Widget>[
        // The rail's ground goes *under* the ambient wash, because that is the
        // order the browser paints them in: `.app__mesh` is positioned and
        // `.navside` is not, so the wash tints the rail rather than being
        // hidden by it. Everything above the wash — the status strip, the
        // screens — is positioned too, and paints over it.
        if (!compact)
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: klass == LumeWidthClass.expanded
                ? LumeSpace.navSide
                : LumeSpace.navRail,
            child: ColoredBox(color: context.lume.bgSunk),
          ),
        const Positioned.fill(child: LumeAmbient()),
        Positioned.fill(
          child: compact
              ? _CompactLayout(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  navigationLabel: navigationLabel,
                  showNavigation: showNavigation,
                  child: child,
                )
              : _PaneLayout(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  expanded: klass == LumeWidthClass.expanded,
                  brand: brand,
                  clock: clock,
                  navigationLabel: navigationLabel,
                  showNavigation: showNavigation,
                  child: child,
                ),
        ),
        if (overlay != null) Positioned.fill(child: overlay!),
      ],
    );
  }
}

/// Compact: one column, and the bar floats over it.
class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.navigationLabel,
    required this.showNavigation,
    required this.child,
  });

  final List<LumeDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? navigationLabel;
  final bool showNavigation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The keyboard. `100dvh` does not track it, so the reference's bar ends up
    // behind the keyboard; hiding it is the same outcome, drawn honestly.
    final bool typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bool bar = showNavigation && destinations.isNotEmpty && !typing;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: _Outlet(
            bottom: bar
                ? LumeShellMetrics.contentBottomCompact
                : LumeShellMetrics.contentBottomPane,
            child: child,
          ),
        ),
        if (bar)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: LumeBottomBar(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              semanticLabel: navigationLabel,
            ),
          ),
      ],
    );
  }
}

/// Medium and expanded: a status strip across the top, navigation down the
/// start edge, the outlet filling the rest. One grid, two nav widths.
class _PaneLayout extends StatelessWidget {
  const _PaneLayout({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.expanded,
    required this.brand,
    required this.clock,
    required this.navigationLabel,
    required this.showNavigation,
    required this.child,
  });

  final List<LumeDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool expanded;
  final String brand;
  final String? clock;
  final String? navigationLabel;
  final bool showNavigation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        LumeStatusStrip(
          brand: brand,
          clock: clock,
          gutter: expanded ? LumeSpace.pageExpanded : LumeSpace.pageMedium,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showNavigation && destinations.isNotEmpty)
                LumeNavigationRail(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  expanded: expanded,
                  brand: expanded ? brand : null,
                  semanticLabel: navigationLabel,
                ),
              Expanded(
                child: _Outlet(
                  bottom: LumeShellMetrics.contentBottomPane,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The content outlet.
///
/// Consumes the top and side insets so a screen never draws under the notch,
/// and republishes the bottom one as the clearance the navigation needs — so a
/// screen's own `SafeArea` or `MediaQuery.paddingOf(context).bottom` lands its
/// last row above the bar without any screen knowing the bar's height.
class _Outlet extends StatelessWidget {
  const _Outlet({required this.bottom, required this.child});

  final double bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(
          // The navigation's clearance, plus the keyboard when there is one:
          // a scroll view padded by this can lift its last field above the
          // keyboard without any screen reading `viewInsets` for itself.
          bottom: math.max(bottom, mq.padding.bottom) + mq.viewInsets.bottom,
        ),
      ),
      child: SafeArea(top: true, bottom: false, child: child),
    );
  }
}

/// `.app__mesh` — three blurred radial washes behind everything.
///
/// Decorative and inert: it never takes a pointer and it carries no semantics,
/// so a screen reader walks straight past it.
class LumeAmbient extends StatelessWidget {
  const LumeAmbient({super.key});

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: lume.meshOpacity,
          // Three `radial-gradient`s stacked in one `background`. Flutter
          // paints one gradient per box, so they are three boxes — the same
          // colours, the same centres, the same order.
          child: Stack(
            children: <Widget>[
              _Wash(
                colour: lume.accent,
                centre: const Alignment(-0.84, -0.96),
                extent: 0.38,
                strength: 0.26,
              ),
              _Wash(
                colour: lume.violet,
                centre: const Alignment(0.92, -0.76),
                extent: 0.34,
                strength: 0.22,
              ),
              _Wash(
                colour: lume.sky,
                centre: Alignment.bottomCenter,
                extent: 0.46,
                strength: 0.14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wash extends StatelessWidget {
  const _Wash({
    required this.colour,
    required this.centre,
    required this.extent,
    required this.strength,
  });

  final Color colour;

  /// `radial-gradient(… at 8% 2%)`, as an [Alignment].
  final Alignment centre;

  /// The first value of the CSS gradient — its horizontal extent as a fraction
  /// of the box. Doubled here, because CSS measures a radius from the centre
  /// and [RadialGradient.radius] is a fraction of the box's shortest side.
  final double extent;

  /// The wash's own alpha, before [LumeColors.meshOpacity] is applied.
  final double strength;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: centre,
            radius: extent * 2,
            colors: <Color>[
              colour.withValues(alpha: strength),
              colour.withValues(alpha: 0),
            ],
            stops: const <double>[0, 0.7],
          ),
        ),
      ),
    );
  }
}

/// `.statusbar` at medium and expanded — the top of the application.
///
/// On a phone this is the device's and the shell does not draw it. Here it is
/// the product's own strip: the wordmark, then the clock. The reference also
/// draws signal, wifi and battery glyphs; those are a drawing of a device and
/// are dropped, because on a device the device draws them.
class LumeStatusStrip extends StatelessWidget {
  const LumeStatusStrip({
    super.key,
    required this.brand,
    this.clock,
    this.gutter = LumeSpace.pageMedium,
  });

  final String brand;
  final String? clock;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: lume.card,
        border: Border(
          bottom: BorderSide(color: lume.border, width: LumeSpace.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: LumeShellMetrics.statusStripPadding,
          ),
          child: Row(
            children: <Widget>[
              LumeIcon(LumeIcons.lume, size: 17, color: lume.accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  brand.toUpperCase(),
                  style: LumeType.tracked(
                    LumeType.fit(context, context.lumeType.label),
                    0.1,
                  ).copyWith(color: lume.accent700),
                ),
              ),
              if (clock != null)
                Text(
                  clock!,
                  style: LumeType.numeric(
                    LumeType.fit(context, context.lumeType.bodyStrong),
                  ).copyWith(color: lume.text),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The scrim behind a sheet or a dialog. `.scrim`, z-50.
class LumeScrim extends StatelessWidget {
  const LumeScrim({super.key, required this.open, this.onDismiss, this.label});

  final bool open;
  final VoidCallback? onDismiss;

  /// What a screen reader calls the dismiss gesture. Required when [onDismiss]
  /// is set, or the only way out is invisible to it.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: AnimatedOpacity(
        opacity: open ? 1 : 0,
        duration: LumeMotion.duration(context, LumeMotion.standard),
        curve: LumeMotion.ease,
        child: Semantics(
          button: onDismiss != null,
          label: onDismiss == null ? null : label,
          onTap: onDismiss,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: ColoredBox(color: context.lume.overlay),
          ),
        ),
      ),
    );
  }
}
