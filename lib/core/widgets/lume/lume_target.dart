/// A touch target larger than what is drawn, without moving anything.
///
/// D6 and D35 settled that a control's drawn box and its touchable area are
/// different things. Where the extra area fits inside the control's own
/// parent, an `OverflowBox` is enough. Where it does not — a context-strip item
/// is 18 tall in a 22-point strip, and the reference draws its target 32 tall
/// with negative margins — a Flutter hit test never reaches it, because a
/// `RenderBox` refuses a position outside its own size before asking its
/// children.
///
/// So the widening happens one level up. A [LumeTargetRegion] wraps a surface
/// whose layout has room around its controls (a tool body: sections are 24
/// apart); a [LumeTargetSlop] inside it declares how far its target reaches.
/// When a tap lands on **nothing** in the region — empty margin, not a card and
/// not a word — the region gives it to the nearest slop whose widened box holds
/// it. A tap on anything real is never taken, and where two widened boxes meet,
/// the nearer centre wins, so no position is ambiguous.
///
/// Layout, paint and semantics are untouched: this changes where a finger may
/// land, and nothing else.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The surface inside which [LumeTargetSlop]s may reach past their own boxes.
class LumeTargetRegion extends SingleChildRenderObjectWidget {
  const LumeTargetRegion({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderLumeTargetRegion();
}

/// A control whose touchable area reaches [slop] past its drawn box.
class LumeTargetSlop extends SingleChildRenderObjectWidget {
  const LumeTargetSlop({
    super.key,
    required this.slop,
    required Widget super.child,
  });

  /// How far past each edge a tap still belongs to [child]. Directional, so a
  /// right-to-left strip widens the same way it reads.
  final EdgeInsetsGeometry slop;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderLumeTargetSlop(slop.resolve(Directionality.of(context)));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLumeTargetSlop renderObject,
  ) {
    renderObject.slop = slop.resolve(Directionality.of(context));
  }
}

class RenderLumeTargetRegion extends RenderProxyBox {
  final Set<RenderLumeTargetSlop> _targets = <RenderLumeTargetSlop>{};

  /// The widened boxes, in this region's coordinates — exposed so a test can
  /// prove two of them do not claim the same point.
  Iterable<(RenderLumeTargetSlop, Rect, Rect)> get targets sync* {
    for (final RenderLumeTargetSlop t in _targets) {
      if (!t.attached || !t.hasSize) continue;
      final Rect drawn = MatrixUtils.transformRect(
        t.getTransformTo(this),
        Offset.zero & t.size,
      );
      yield (t, drawn, t.slop.inflateRect(drawn));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final int before = result.path.length;
    final bool hit = super.hitTestChildren(result, position: position);
    // Something real is under the finger. It keeps the tap.
    if (result.path.length > before) return hit;

    RenderLumeTargetSlop? best;
    double nearest = double.infinity;
    for (final (RenderLumeTargetSlop t, Rect drawn, Rect widened) in targets) {
      if (!widened.contains(position)) continue;
      final double d = (drawn.center - position).distanceSquared;
      if (d < nearest) {
        nearest = d;
        best = t;
      }
    }
    if (best == null) return hit;
    final RenderLumeTargetSlop target = best;
    return result.addWithPaintTransform(
      transform: target.getTransformTo(this),
      position: position,
      hitTest: (BoxHitTestResult result, Offset local) => target.hitTest(
        result,
        // Onto the nearest point of the drawn box, so the control's own
        // recognisers see a position inside it.
        position: Offset(
          local.dx.clamp(0, target.size.width - 0.5),
          local.dy.clamp(0, target.size.height - 0.5),
        ),
      ),
    );
  }
}

class RenderLumeTargetSlop extends RenderProxyBox {
  RenderLumeTargetSlop(this._slop);

  EdgeInsets _slop;
  EdgeInsets get slop => _slop;
  set slop(EdgeInsets value) {
    if (value == _slop) return;
    _slop = value;
  }

  RenderLumeTargetRegion? _region;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    RenderObject? p = parent;
    while (p != null && p is! RenderLumeTargetRegion) {
      p = p.parent;
    }
    _region = p as RenderLumeTargetRegion?;
    _region?._targets.add(this);
  }

  @override
  void detach() {
    _region?._targets.remove(this);
    _region = null;
    super.detach();
  }
}
