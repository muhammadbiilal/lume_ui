/// Press feedback, once, for everything that can be pressed.
///
/// `base.css` is one rule:
///
/// ```css
/// .pressable { transition: transform 160ms …; touch-action: manipulation; }
/// .pressable:active { transform: scale(.972); }
/// ```
///
/// A scale, not a ripple. Material's ink spreads from the touch point and
/// washes over the surface; Lume's whole surface dips. They are different
/// design languages and mixing them is visible immediately, which is why
/// `LumeTheme` turns Material's splash off and every pressable surface in the
/// product comes through here.
///
/// The 2.8 % dip is small on purpose. It reads as a press on a 44-pixel row
/// without making a full-width button look like it is being sucked into the
/// screen.
library;

import 'package:flutter/material.dart';

import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';

/// Wraps a surface in Lume's press feedback, focus ring and semantics.
class LumePressable extends StatefulWidget {
  const LumePressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.button = true,
    this.selected,
    this.enabled = true,
    this.borderRadius,
    this.focusRadius,
    this.minSize = LumeSpace.tap,
    this.excludeSemantics = false,
  });

  final Widget child;

  /// `null` makes the surface inert — a row that is only a row.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Required when the surface has no text of its own.
  final String? semanticLabel;

  /// Whether this announces itself as a button. False for a row that opens a
  /// detail, which is closer to a link.
  final bool button;

  /// Exposed to the screen reader as a selected state when non-null.
  final bool? selected;

  final bool enabled;

  /// Shapes the focus ring. Defaults to the control radius.
  final BorderRadius? borderRadius;

  /// A focus ring larger than the surface, for controls that sit tight against
  /// their neighbours.
  final BorderRadius? focusRadius;

  /// §9's floor. A pressable smaller than this is a miss waiting to happen.
  final double minSize;

  final bool excludeSemantics;

  @override
  State<LumePressable> createState() => _LumePressableState();
}

class _LumePressableState extends State<LumePressable> {
  bool _down = false;
  bool _focused = false;

  bool get _live =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = widget.borderRadius ?? LumeRadius.brSm;

    Widget surface = AnimatedScale(
      scale: _down ? 0.972 : 1.0,
      duration: LumeMotion.duration(context, LumeMotion.fast),
      curve: LumeMotion.ease,
      child: widget.child,
    );

    if (_focused) {
      // §9: a visible 2 px accent outline with 2 px offset. Painted outside the
      // surface so it never eats into the component's own bounds — a focus ring
      // that changes the layout is a focus ring that makes the page jump.
      surface = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          surface,
          Positioned(
            left: -LumeSpace.focusOffset,
            top: -LumeSpace.focusOffset,
            right: -LumeSpace.focusOffset,
            bottom: -LumeSpace.focusOffset,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      widget.focusRadius ??
                      BorderRadius.all(
                        Radius.circular(
                          radius.topLeft.x + LumeSpace.focusOffset,
                        ),
                      ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: LumeSpace.focusRing,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget result = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minSize),
      child: surface,
    );

    if (!_live) {
      if (widget.excludeSemantics) return ExcludeSemantics(child: result);
      return result;
    }

    result = Focus(
      onFocusChange: (bool has) => setState(() => _focused = has),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: result,
      ),
    );

    return Semantics(
      container: true,
      button: widget.button,
      link: !widget.button,
      selected: widget.selected,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: result,
    );
  }
}
