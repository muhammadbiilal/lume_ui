/// `text-wrap: balance`, reproduced rather than approximated.
///
/// Three of Lume's headings ask for it — `.onb__title`, `.slide__title` and
/// `.auth__title` — and the difference is visible in every one. A greedy
/// wrap fills each line to the brim and leaves the last one short:
///
/// ```text
/// Everything your day needs,
/// quietly organised.
/// ```
///
/// A balanced wrap keeps the line count and evens the lines out:
///
/// ```text
/// Everything your day
/// needs, quietly organised.
/// ```
///
/// CSS defines it as: lay the text out normally, then find the **narrowest**
/// width that still produces the same number of lines, and use that. That is
/// what [LumeBalancedText] does, by bisecting the width and asking the child
/// how tall it would be — line height is uniform, so height is line count.
///
/// Because the line count never changes, the balanced box is exactly as tall
/// as the greedy one. Intrinsic height is therefore untouched, which matters:
/// a widget that lies about its height inside a `SliverFillRemaining` produces
/// an overflow with no visible cause.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A heading that balances its lines.
///
/// Wrap a [Text] — not a string — so the caller keeps every one of `Text`'s
/// own options, and so a paragraph that does not want balancing simply does
/// not get wrapped.
class LumeBalancedText extends SingleChildRenderObjectWidget {
  const LumeBalancedText({
    super.key,
    required Text super.child,
    this.enabled = true,
  });

  /// Off leaves the child exactly as it was, for a caller that wants to switch
  /// on a locale or a setting without a second code path.
  final bool enabled;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBalanced(
    enabled: enabled,
    align: _alignOf(context, child! as Text),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderBalanced)
      ..enabled = enabled
      ..align = _alignOf(context, child! as Text);
  }

  /// Where the narrowed box sits in the width the block was given.
  ///
  /// CSS aligns lines inside the *container*, so a centred heading stays
  /// centred in the full width and a start-aligned one stays at the start.
  /// Centring the narrowed box and letting the child centre its lines inside
  /// it comes to the same place.
  static double _alignOf(BuildContext context, Text text) {
    final TextAlign align =
        text.textAlign ??
        DefaultTextStyle.of(context).textAlign ??
        TextAlign.start;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return switch (align) {
      TextAlign.center => 0.0,
      TextAlign.end => rtl ? -1.0 : 1.0,
      TextAlign.right => 1.0,
      TextAlign.left => -1.0,
      TextAlign.start || TextAlign.justify => rtl ? 1.0 : -1.0,
    };
  }
}

class _RenderBalanced extends RenderProxyBox {
  _RenderBalanced({required bool enabled, required double align})
    : _enabled = enabled,
      _align = align;

  bool _enabled;
  set enabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    markNeedsLayout();
  }

  /// −1 start, 0 centre, 1 end, in the resolved reading direction.
  double _align;
  set align(double value) {
    if (value == _align) return;
    _align = value;
    markNeedsLayout();
  }

  /// Where the narrowed child sits inside the block's full width. Kept here
  /// rather than in parent data, which a proxy box does not give its child.
  Offset _childOffset = Offset.zero;

  /// How close the search gets before it stops. Half a logical pixel is below
  /// what any glyph advance can resolve, and caps the search at ~10 probes on
  /// a phone.
  static const double _epsilon = 0.5;

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    if (!_enabled || !constraints.hasBoundedWidth) {
      child.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child.size);
      _offsetChild(0);
      return;
    }

    final double full = constraints.maxWidth;
    final double greedy = child
        .getDryLayout(BoxConstraints(maxWidth: full))
        .height;

    // One line already: nothing to balance, and the search would only find the
    // text's own width, which is what a single line is anyway.
    double lo = child.getMinIntrinsicWidth(double.infinity);
    if (lo > full) lo = full;

    double hi = full;
    while (hi - lo > _epsilon) {
      final double mid = lo + (hi - lo) / 2;
      final double h = child.getDryLayout(BoxConstraints(maxWidth: mid)).height;
      // Taller means the line count went up, so `mid` was too narrow.
      if (h > greedy) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    // The child is laid out at the balanced width even when the block was
    // given a tight one — the *box* keeps the full width, and the narrowed
    // text sits inside it where its alignment puts it.
    child.layout(
      BoxConstraints(maxWidth: hi, maxHeight: constraints.maxHeight),
      parentUsesSize: true,
    );
    size = constraints.constrain(Size(full, child.size.height));
    _offsetChild(size.width - child.size.width);
  }

  void _offsetChild(double slack) {
    _childOffset = Offset(slack * (_align + 1) / 2, 0);
  }

  // The child is shifted, so the default proxy hit test — which assumes the
  // child sits at the origin — would miss it.
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: _childOffset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) return;
    context.paintChild(child, offset + _childOffset);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    transform.translateByDouble(_childOffset.dx, _childOffset.dy, 0, 1);
  }
}
