/// Lume's three width classes, and the one place the app decides which it is in.
///
/// The reference system (`assets/js/core/breakpoint.js`, Design System §1, §6,
/// §10) defines three layouts rather than a pile of media queries:
///
/// | class      | width      | navigation            | layout               |
/// |------------|------------|-----------------------|----------------------|
/// | `compact`  | below 600  | bottom bar            | single pane          |
/// | `medium`   | 600 – 839  | labelled rail (84)    | centred, single pane |
/// | `expanded` | 840 and up | sidebar (244)         | master-detail        |
///
/// Three rules — two carried over from the reference, one this application had
/// to add.
///
/// **It measures the shell, not the window.** Those are different numbers. The
/// shell sits behind a rail or a sidebar, so a window 880 logical pixels wide
/// holds an 832-pixel content area — medium, not expanded. Deciding from
/// `MediaQuery.sizeOf(context).width` would put a master-detail layout into a
/// pane too narrow to hold it. [LumeBreakpointScope] measures its own
/// constraints with a [LayoutBuilder], and everything below reads that
/// measurement instead of asking the window.
///
/// **[LumeBreakpointX.hasDetailPane] is the question callers actually have.**
/// Whether "open this record" means pushing a route or moving a selection is a
/// navigation decision, answered here once rather than by every list screen
/// comparing numbers. A screen that counts pixels itself is a screen that will
/// disagree with the shell at exactly one width.
///
/// **A short shell is compact however wide it is.** See [LumeBreakpoints.compactHeight].
library;

import 'package:flutter/widgets.dart';

/// The width class of a measured surface.
enum LumeWidthClass {
  /// Below 600. A phone, or a tablet in a narrow split-screen.
  compact,

  /// 600–839. A small tablet, or a large one in split-screen.
  medium,

  /// 840 and above. A tablet with room for two panes.
  expanded,
}

/// The boundaries, and the only place they are written down.
abstract final class LumeBreakpoints {
  /// Compact ends here. 599 is compact; 600 is medium.
  static const double medium = 600;

  /// Medium ends here. 839 is medium; 840 is expanded.
  static const double expanded = 840;

  /// Below this height the shell is compact whatever its width.
  ///
  /// **A deliberate native adaptation, not something the reference specifies.**
  /// Lume is a browser prototype and its width classes are width-only, because
  /// it never met a phone held sideways. A real one is 844–926 logical pixels
  /// wide in landscape, which crosses [expanded] — so on width alone an iPhone
  /// 14 Pro on its side would be handed a 244-pixel persistent sidebar and a
  /// two-pane master-detail layout on a surface 393 pixels tall. That is not a
  /// tablet; it is a phone, and it needs the phone's presentation.
  ///
  /// 480 is Material's own compact-height boundary, which exists for this exact
  /// case, and it separates the two populations cleanly:
  ///
  /// | surface                      | size        | height class | presentation |
  /// |------------------------------|-------------|--------------|--------------|
  /// | iPhone SE, landscape         | 667 × 375   | compact      | compact      |
  /// | iPhone 14 Pro, landscape     | 852 × 393   | compact      | compact      |
  /// | iPhone 14 Pro Max, landscape | 926 × 428   | compact      | compact      |
  /// | iPad mini, portrait          | 744 × 1133  | tall         | medium       |
  /// | iPad mini, landscape         | 1133 × 744  | tall         | expanded     |
  /// | iPad Pro, landscape          | 1366 × 1024 | tall         | expanded     |
  ///
  /// So no tablet loses its rail or its sidebar in either orientation, and no
  /// phone gains one.
  static const double compactHeight = 480;

  /// Refinements *inside* a width class, not a fourth class.
  ///
  /// The reference's stylesheets carry these beyond `data-bp`, and they are
  /// visible: below [narrow] the tools category grid drops to two columns and
  /// the Home greeting to 20 px; above [wide] the metric grid goes to four
  /// columns and the tiles grid to five; above [ultrawide] the authentication
  /// screen grows an illustrated aside.
  ///
  /// They live here so the numbers are in one file, and a widget checks its own
  /// measured width against them. No screen writes a literal.
  static const double narrow = 360;
  static const double wide = 1180;
  static const double ultrawide = 1380;

  /// The width class for a measured width, ignoring height.
  ///
  /// This is the reference's `classFor`, unchanged — the same comparisons in
  /// the same order, so the measure Flutter applies and the measure the
  /// reference draws are the same one. For deciding a *presentation* use
  /// [resolve], which also accounts for height.
  static LumeWidthClass classFor(double width) {
    if (width >= expanded) return LumeWidthClass.expanded;
    if (width >= medium) return LumeWidthClass.medium;
    return LumeWidthClass.compact;
  }

  /// Whether a shell this tall is too short for a tablet presentation.
  static bool isCompactHeight(double height) => height < compactHeight;

  /// The presentation class for a measured shell.
  ///
  /// [classFor], then the height override: a shell shorter than
  /// [compactHeight] is compact whatever its width, so a landscape phone gets
  /// the bottom bar and single-pane record navigation rather than a sidebar it
  /// has no room for.
  static LumeWidthClass resolve({
    required double width,
    required double height,
  }) => isCompactHeight(height) ? LumeWidthClass.compact : classFor(width);
}

/// Publishes the measured width class to the subtree.
///
/// Read it through [LumeBreakpointX] on `BuildContext` rather than directly;
/// that is what keeps the call sites honest.
class LumeBreakpoint extends InheritedWidget {
  const LumeBreakpoint({
    super.key,
    required this.widthClass,
    required this.measureClass,
    required this.width,
    required this.height,
    required super.child,
  });

  /// The presentation class: what navigation to draw, and whether there is room
  /// for a second pane. Height-aware.
  final LumeWidthClass widthClass;

  /// The class the *content measure* uses — width only, no height override.
  ///
  /// These come apart on a landscape phone, and deliberately. Navigation and
  /// panes are about room: a 393-pixel-tall shell has none, so it gets the
  /// phone's presentation. The reading measure is about line length, and a
  /// 900-pixel line of body text is too long to read whatever the height is.
  /// Capping it there is not a tablet layout leaking onto a phone; it is the
  /// same typographic rule the reference applies from 600 up.
  final LumeWidthClass measureClass;

  /// The measured width, in logical pixels. Kept so a layout can size a pane
  /// against the real number instead of measuring again.
  final double width;

  /// The measured height, in logical pixels.
  final double height;

  /// Whether the height override is what made this compact — a shell that would
  /// otherwise be medium or expanded on its width alone.
  bool get isHeightConstrained =>
      widthClass == LumeWidthClass.compact &&
      measureClass != LumeWidthClass.compact;

  static LumeBreakpoint? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LumeBreakpoint>();

  @override
  bool updateShouldNotify(LumeBreakpoint old) =>
      old.widthClass != widthClass ||
      old.measureClass != measureClass ||
      old.width != width ||
      old.height != height;
}

/// Measures its own available size and publishes the class beneath it.
///
/// Wraps the application shell once. Nesting another scope is legitimate and
/// occasionally necessary — a detail pane 380 pixels wide inside an expanded
/// window is a compact surface, and the widgets inside it should be told so
/// rather than drawing a two-column form into a single column of space.
class LumeBreakpointScope extends StatelessWidget {
  const LumeBreakpointScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // An unbounded axis has not been laid out yet — a measurement, not a
        // size. The reference makes the same call for `offsetWidth == 0`: fall
        // back to the viewport rather than report a spurious compact.
        final Size window = MediaQuery.sizeOf(context);
        final double width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : window.width;
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : window.height;
        return LumeBreakpoint(
          widthClass: LumeBreakpoints.resolve(width: width, height: height),
          measureClass: LumeBreakpoints.classFor(width),
          width: width,
          height: height,
          child: child,
        );
      },
    );
  }
}

/// How every widget in the app asks about width.
extension LumeBreakpointX on BuildContext {
  /// The presentation class of the nearest measured shell.
  ///
  /// With no [LumeBreakpointScope] above — a widget tested in isolation, a
  /// screen pushed outside the shell — this falls back to the window, which is
  /// the same fallback order `breakpoint.js` uses when it has no observer.
  LumeWidthClass get widthClass {
    final LumeBreakpoint? b = LumeBreakpoint.maybeOf(this);
    if (b != null) return b.widthClass;
    final Size s = MediaQuery.sizeOf(this);
    return LumeBreakpoints.resolve(width: s.width, height: s.height);
  }

  /// The class the content measure uses — width only.
  LumeWidthClass get measureClass =>
      LumeBreakpoint.maybeOf(this)?.measureClass ??
      LumeBreakpoints.classFor(MediaQuery.sizeOf(this).width);

  /// The measured width the class was derived from.
  double get shellWidth =>
      LumeBreakpoint.maybeOf(this)?.width ?? MediaQuery.sizeOf(this).width;

  /// The measured height.
  double get shellHeight =>
      LumeBreakpoint.maybeOf(this)?.height ?? MediaQuery.sizeOf(this).height;

  /// Whether the shell is too short for a tablet presentation — a phone in
  /// landscape, or a very short split-screen.
  bool get isCompactHeight => LumeBreakpoints.isCompactHeight(shellHeight);

  /// Whether the height override is what made this compact.
  bool get isHeightConstrained =>
      LumeBreakpoint.maybeOf(this)?.isHeightConstrained ??
      (LumeBreakpoints.isCompactHeight(shellHeight) &&
          LumeBreakpoints.classFor(shellWidth) != LumeWidthClass.compact);

  /// Whether a record can be shown beside its list instead of over it.
  ///
  /// The one question a list screen should ask. `true` means selecting a record
  /// updates a detail pane; `false` means it pushes a route. False on a
  /// landscape phone, however wide it is.
  bool get hasDetailPane => widthClass == LumeWidthClass.expanded;

  bool get isCompact => widthClass == LumeWidthClass.compact;
  bool get isMedium => widthClass == LumeWidthClass.medium;
  bool get isExpanded => widthClass == LumeWidthClass.expanded;

  /// Below [LumeBreakpoints.narrow] — the sub-360 refinements.
  bool get isNarrow => shellWidth < LumeBreakpoints.narrow;

  /// At or above [LumeBreakpoints.wide] — four-column metrics, five-column tiles.
  bool get isWideSurface => shellWidth >= LumeBreakpoints.wide;

  /// At or above [LumeBreakpoints.ultrawide] — the authentication aside.
  bool get isUltrawideSurface => shellWidth >= LumeBreakpoints.ultrawide;
}
