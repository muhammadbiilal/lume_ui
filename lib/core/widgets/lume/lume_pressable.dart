/// Press feedback, focus, keyboard and screen-reader activation, once, for
/// everything that can be pressed.
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
///
/// **Four ways in, not one.** A `GestureDetector` alone answers a finger and
/// nothing else: Enter and Space do nothing, and a screen reader's activate
/// gesture does nothing, because neither produces a pointer event. So this
/// wraps a [FocusableActionDetector] for the keyboard and passes `onTap` into
/// [Semantics] for assistive technology. A control that looks focusable and
/// cannot be activated from the keyboard is worse than one that is visibly
/// inert.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';

/// Wraps a surface in Lume's press feedback, focus ring, keyboard activation
/// and semantics.
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
    this.autofocus = false,
    this.focusNode,
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

  /// Set when an ancestor already supplies the semantics — it stops the node
  /// being announced twice.
  final bool excludeSemantics;

  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<LumePressable> createState() => _LumePressableState();
}

class _LumePressableState extends State<LumePressable> {
  bool _down = false;
  bool _focused = false;

  bool get _live =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _activate() {
    if (!_live) return;
    widget.onTap?.call();
  }

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
      // An inert surface still reports its disabled state when it was given
      // one to report — a button that cannot be pressed is not the same thing
      // as a paragraph.
      if (widget.onTap == null && widget.onLongPress == null) return result;
      return Semantics(
        container: true,
        button: widget.button,
        enabled: false,
        label: widget.semanticLabel,
        child: result,
      );
    }

    result = FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: _live,
      onShowFocusHighlight: (bool has) {
        if (_focused != has) setState(() => _focused = has);
      },
      // Enter and Space, which a GestureDetector never sees.
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            _activate();
            return null;
          },
        ),
      },
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

    if (widget.excludeSemantics) {
      // The ancestor owns the label and the role, but the *action* still has
      // to live on a node assistive technology can activate, so it stays here.
      return Semantics(onTap: _activate, excludeSemantics: true, child: result);
    }

    return Semantics(
      container: true,
      button: widget.button,
      link: !widget.button,
      selected: widget.selected,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      // Without this a screen reader can find the control and not press it.
      onTap: _activate,
      onLongPress: widget.onLongPress,
      child: result,
    );
  }
}
