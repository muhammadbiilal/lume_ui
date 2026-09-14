/// Inputs: the tool field, the form field, the search field, the text area,
/// the select, the checkbox, the switch and the stepper.
///
/// **Two field systems, deliberately.** The measurement makes it plain:
///
/// | | height | padding | radius | fill | border |
/// |---|---|---|---|---|---|
/// | `.field__box` (tool) | 42 | 10 12 | 8 | `card-2` | `border` |
/// | `.cfield__box` (record form) | 48 | 0 14 | 12 | `card` | `border-2` |
///
/// A calculator's inputs are dense and sit inside a card; a record form's are
/// the screen. Collapsing them into one widget with a `dense` flag would lose
/// that, so both exist, named after the surfaces they belong to.
///
/// Validation follows §8's lifecycle, and the engine drives it — the widget
/// only renders what it is told: a field it has not been told is invalid is
/// not invalid. Do not judge an untouched field.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../icons/lume_icon.dart';
import '../../icons/lume_icons.dart';
import '../../theme/lume/lume_colors.dart';
import '../../theme/lume/lume_motion.dart';
import '../../theme/lume/lume_space.dart';
import '../../theme/lume/lume_theme.dart';
import '../../theme/lume/lume_type.dart';
import 'lume_pressable.dart';

/// What kind of value a field holds, which decides its keyboard.
///
/// §8: "use appropriate mobile keyboards". A money field that opens a QWERTY
/// keyboard is a field the user has to fight.
enum LumeFieldKind { text, multiline, number, money, date, time, email, phone }

/// `.field` — the dense tool input. Label above, box below, optional hint.
class LumeToolField extends StatefulWidget {
  const LumeToolField({
    super.key,
    required this.label,
    this.controller,
    this.value,
    this.onChanged,
    this.hint,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.kind = LumeFieldKind.text,
    this.boxPadding,
    this.boxRadius,
    this.inputStyle,
    this.enabled = true,
    this.wide = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;

  /// `.field__hint` — 10 / 500, muted.
  final String? hint;

  final String? placeholder;

  /// `.field__affix` — a unit or currency inside the box.
  final String? prefix;
  final String? suffix;

  final LumeFieldKind kind;

  /// A screen's own override of the box — the onboarding name step asks for
  /// `padding: 14px 16px; border-radius: var(--r-md)` where `.field__box` is
  /// `10px 12px` at `r-xs`. `null` takes the component's own.
  final EdgeInsets? boxPadding;
  final BorderRadius? boxRadius;

  /// Merged over `.field__box input`'s own 14 / 700. The onboarding name step
  /// sets 16, which is also what keeps iOS from zooming on focus.
  final TextStyle? inputStyle;

  final bool enabled;

  /// `.field--wide` — spans both columns of a two-column grid.
  final bool wide;

  /// Measured: 42 px.
  static const double boxHeight = 42;

  @override
  State<LumeToolField> createState() => _LumeToolFieldState();
}

class _LumeToolFieldState extends State<LumeToolField> {
  /// `.field__box:focus-within` — the ring belongs to the box, and it is the
  /// *input inside it* that takes focus. `Focus` with `canRequestFocus: false`
  /// is that relationship: it never takes focus itself and hears when a
  /// descendant does.
  bool _within = false;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Measured: 11 / 800 / .02em / uppercase / muted. Uppercased for the
        // eye and announced as written, so a screen reader does not spell it.
        Text(
          LumeType.overline(context, widget.label),
          semanticsLabel: widget.label,
          style:
              LumeType.tracked(
                LumeType.fit(
                  context,
                  context.lumeType.metaSmall,
                ).copyWith(fontWeight: FontWeight.w700),
                0.02,
              ).copyWith(
                // Measured 13 tall: 11 px on a normal line box. The role's own 16
                // would add three to every field in the app.
                height: 13 / 11,
                color: lume.text3,
              ),
        ),
        // `.field { gap: 6px }`.
        const SizedBox(height: 6),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (bool has) {
            if (_within != has) setState(() => _within = has);
          },
          child: AnimatedContainer(
            duration: LumeMotion.duration(context, LumeMotion.fast),
            curve: LumeMotion.ease,
            constraints: const BoxConstraints(
              minHeight: LumeToolField.boxHeight,
            ),
            padding:
                widget.boxPadding ?? const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: lume.card2,
              borderRadius: widget.boxRadius ?? LumeRadius.brXs,
              border: Border.all(
                // `border-color: color-mix(in srgb, accent 50%, border)`.
                color: _within
                    ? Color.lerp(lume.border, lume.accent, 0.5)!
                    : lume.border,
                width: LumeSpace.border,
              ),
              // `box-shadow: 0 0 0 3px var(--tint-accent)`.
              boxShadow: _within
                  ? <BoxShadow>[
                      BoxShadow(color: lume.tintAccent, spreadRadius: 3),
                    ]
                  : null,
            ),
            child: Row(
              children: <Widget>[
                if (widget.prefix != null) ...<Widget>[
                  _Affix(widget.prefix!),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: _RawInput(
                    controller: widget.controller,
                    value: widget.value,
                    onChanged: widget.onChanged,
                    placeholder: widget.placeholder,
                    kind: widget.kind,
                    enabled: widget.enabled,
                    style: LumeType.fit(
                      context,
                      context.lumeType.bodyStrong,
                    ).copyWith(color: lume.text).merge(widget.inputStyle),
                  ),
                ),
                if (widget.suffix != null) ...<Widget>[
                  const SizedBox(width: 6),
                  _Affix(widget.suffix!),
                ],
              ],
            ),
          ),
        ),
        if (widget.hint != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            widget.hint!,
            style: LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(color: lume.text3, fontSize: 10),
          ),
        ],
      ],
    );
  }
}

class _Affix extends StatelessWidget {
  const _Affix(this.text);

  final String text;

  @override
  // `.field__affix` — 11 / 700 / −.01em on the font's own 13.
  Widget build(BuildContext context) => Text(
    text,
    style: LumeType.tracked(
      LumeType.natural(context, context.lumeType.metaSmall),
      -0.01,
    ).copyWith(color: context.lume.text3, fontWeight: FontWeight.w700),
  );
}

/// `.cfield` — the record form field.
///
/// Label above, control, then **either** an error or a hint directly below it.
/// Never both: the error replaces the hint, because a field that is wrong does
/// not also need to be told what it is for.
class LumeFormField extends StatefulWidget {
  const LumeFormField({
    super.key,
    required this.label,
    this.controller,
    this.value,
    this.onChanged,
    this.onEditingComplete,
    this.error,
    this.hint,
    this.placeholder,
    this.prefix,
    this.optionalLabel,
    this.kind = LumeFieldKind.text,
    this.enabled = true,
    this.required = false,
    this.wide = false,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;

  /// Fires on blur. §8 validates independently judgeable rules here, and
  /// nothing before.
  final VoidCallback? onEditingComplete;

  /// Non-null makes the field invalid: a rose boundary **and** this message
  /// below it, paired with a glyph. Colour never carries a status alone.
  final String? error;

  final String? hint;
  final String? placeholder;
  final String? prefix;

  /// "Optional", shown beside the label. §8 asks for optional fields to be
  /// marked, rather than required ones.
  final String? optionalLabel;

  final LumeFieldKind kind;
  final bool enabled;
  final bool required;
  final bool wide;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Measured: 48 px.
  static const double boxHeight = 48;

  /// Measured: `.cfield__box textarea` min-height.
  static const double textAreaMinHeight = 76;

  @override
  State<LumeFormField> createState() => _LumeFormFieldState();
}

class _LumeFormFieldState extends State<LumeFormField> {
  late final FocusNode _node = widget.focusNode ?? FocusNode();
  bool _ownsNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsNode = widget.focusNode == null;
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focused == _node.hasFocus) return;
    setState(() => _focused = _node.hasFocus);
    if (!_node.hasFocus) widget.onEditingComplete?.call();
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    if (_ownsNode) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool invalid = widget.error != null;
    final bool multiline = widget.kind == LumeFieldKind.multiline;

    final Color borderColour = invalid
        ? lume.roseInk
        : _focused
        ? lume.accent
        : lume.border2;

    return Semantics(
      textField: true,
      label: widget.label,
      hint: widget.hint,
      enabled: widget.enabled,
      // The screen reader hears the message, not just that something is wrong.
      value: widget.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  widget.label,
                  // Measured: 12 / 700, `text-2`.
                  style: LumeType.fit(
                    context,
                    context.lumeType.label,
                  ).copyWith(color: lume.text2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.optionalLabel != null) ...<Widget>[
                const SizedBox(width: LumeSpace.x2),
                Text(
                  widget.optionalLabel!,
                  style: LumeType.fit(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: lume.text3),
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          AnimatedContainer(
            duration: LumeMotion.duration(context, LumeMotion.fast),
            curve: LumeMotion.ease,
            constraints: BoxConstraints(
              minHeight: multiline
                  ? LumeFormField.textAreaMinHeight
                  : LumeFormField.boxHeight,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: multiline ? 12 : 0,
            ),
            decoration: BoxDecoration(
              color: lume.card,
              borderRadius: LumeRadius.brSm,
              border: Border.all(color: borderColour, width: LumeSpace.border),
              // The focus and invalid rings, measured as `0 0 0 3px`.
              boxShadow: _focused || invalid
                  ? <BoxShadow>[
                      BoxShadow(
                        color: invalid
                            ? lume.rose.withValues(alpha: 0.22)
                            : lume.tintAccent,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: multiline
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: <Widget>[
                if (widget.prefix != null) ...<Widget>[
                  _Affix(widget.prefix!),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _RawInput(
                    controller: widget.controller,
                    value: widget.value,
                    onChanged: widget.onChanged,
                    placeholder: widget.placeholder,
                    kind: widget.kind,
                    enabled: widget.enabled,
                    focusNode: _node,
                    autofocus: widget.autofocus,
                    style: LumeType.fit(context, context.lumeType.bodyStrong)
                        .copyWith(
                          color: lume.text,
                          fontWeight: FontWeight.w500,
                          height: multiline ? 1.55 : null,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (invalid) ...<Widget>[
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // A glyph as well as the colour (§9).
                Text(
                  '!',
                  style: LumeType.fit(
                    context,
                    context.lumeType.label,
                  ).copyWith(color: lume.roseInk, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.error!,
                    style: LumeType.fit(
                      context,
                      context.lumeType.label,
                    ).copyWith(color: lume.roseInk),
                  ),
                ),
              ],
            ),
          ] else if (widget.hint != null) ...<Widget>[
            const SizedBox(height: 7),
            Text(
              widget.hint!,
              style: LumeType.fit(
                context,
                context.lumeType.metaSmall,
              ).copyWith(color: lume.text3),
            ),
          ],
        ],
      ),
    );
  }
}

/// The bare editable, with the right keyboard and no decoration of its own.
class _RawInput extends StatefulWidget {
  const _RawInput({
    this.controller,
    this.value,
    this.onChanged,
    this.placeholder,
    required this.kind,
    required this.enabled,
    required this.style,
    this.focusNode,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final LumeFieldKind kind;
  final bool enabled;
  final TextStyle style;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_RawInput> createState() => _RawInputState();
}

class _RawInputState extends State<_RawInput> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController(text: widget.value));

  @override
  void didUpdateWidget(_RawInput old) {
    super.didUpdateWidget(old);
    // A fixture-driven field is told its value; only adopt a change that did
    // not come from the user, or typing would fight the rebuild.
    if (widget.controller == null &&
        widget.value != null &&
        widget.value != _controller.text) {
      _controller.text = widget.value!;
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  TextInputType get _keyboard => switch (widget.kind) {
    LumeFieldKind.multiline => TextInputType.multiline,
    LumeFieldKind.number => TextInputType.number,
    LumeFieldKind.money => const TextInputType.numberWithOptions(decimal: true),
    LumeFieldKind.date => TextInputType.datetime,
    LumeFieldKind.time => TextInputType.datetime,
    LumeFieldKind.email => TextInputType.emailAddress,
    LumeFieldKind.phone => TextInputType.phone,
    LumeFieldKind.text => TextInputType.text,
  };

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    // Material's TextField requires a Material ancestor for its selection
    // handles and cursor. Lume draws its own box, so the widget carries a
    // transparent one itself rather than making every screen that holds a
    // field also hold a Scaffold.
    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        // A search field's keyboard says "search"; every other kind keeps
        // the platform default, because nothing else here submits.
        textInputAction: widget.onSubmitted == null
            ? null
            : TextInputAction.search,
        keyboardType: _keyboard,
        maxLines: widget.kind == LumeFieldKind.multiline ? null : 1,
        minLines: widget.kind == LumeFieldKind.multiline ? 3 : 1,
        style: widget.style,
        cursorColor: lume.accent,
        inputFormatters: widget.kind == LumeFieldKind.number
            ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: widget.placeholder,
          hintStyle: widget.style.copyWith(
            color: lume.text3,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// `.search` — the search field.
///
/// Measured: 44 tall, 0/14 padding, 12 px radius, `card` fill, 1 px `border`,
/// `shadow-xs`, 9 px gap, muted glyph.
class LumeSearchField extends StatelessWidget {
  const LumeSearchField({
    super.key,
    this.placeholder,
    this.controller,
    this.value,
    this.onChanged,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
    this.semanticLabel,
    this.small = false,
    this.focusNode,
    this.onSubmitted,
  });

  final String? placeholder;
  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;

  /// For a caller that focuses the field itself. Global search does: the
  /// reference waits until the sheet has finished rising before it takes
  /// focus, which `autofocus` cannot express.
  final FocusNode? focusNode;

  /// The keyboard's own submit. A search field has nothing to submit *to* —
  /// results are already live — so this re-runs the query rather than
  /// navigating anywhere.
  final ValueChanged<String>? onSubmitted;

  /// Shows a clear affordance when non-null and the field has content.
  final VoidCallback? onClear;

  final bool enabled;
  final bool autofocus;
  final String? semanticLabel;

  /// `.search--sm` — the variant the two location pickers use. Same height,
  /// tighter side padding and a 13 px input, so a picker's field does not read
  /// as heavier than the list underneath it.
  final bool small;

  static const double height = 44;

  /// Measured: `.search` pads 14, `.search--sm` pads 12.
  static const double horizontalPadding = 14;
  static const double horizontalPaddingSmall = 12;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool hasText = (controller?.text ?? value ?? '').isNotEmpty;

    return Semantics(
      textField: true,
      label: semanticLabel ?? placeholder,
      child: _FocusWithin(
        builder: (BuildContext context, bool within) => AnimatedContainer(
          duration: LumeMotion.duration(context, LumeMotion.fast),
          curve: LumeMotion.ease,
          constraints: const BoxConstraints(minHeight: height),
          padding: EdgeInsets.symmetric(
            horizontal: small ? horizontalPaddingSmall : horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: lume.card,
            borderRadius: LumeRadius.brSm,
            // `.search:focus-within { border-color: color-mix(in srgb,
            // var(--accent) 50%, var(--border)) }`.
            border: Border.all(
              color: within
                  ? Color.lerp(lume.border, lume.accent, 0.5)!
                  : lume.border,
              width: LumeSpace.border,
            ),
            // `box-shadow: 0 0 0 3px var(--tint-accent)` — *instead of*
            // `shadow-xs`, because the rule replaces the property.
            boxShadow: within
                ? <BoxShadow>[
                    BoxShadow(color: lume.tintAccent, spreadRadius: 3),
                  ]
                : context.lumeShadows.xs,
          ),
          child: Row(
            children: <Widget>[
              // `.search svg { width: 17px; height: 17px }`.
              LumeIcon(LumeIcons.search, size: 17, color: lume.text3),
              const SizedBox(width: 9),
              Expanded(
                child: _RawInput(
                  controller: controller,
                  value: value,
                  onChanged: onChanged,
                  placeholder: placeholder,
                  kind: LumeFieldKind.text,
                  enabled: enabled,
                  autofocus: autofocus,
                  focusNode: focusNode,
                  onSubmitted: onSubmitted,
                  style: LumeType.fit(
                    context,
                    context.lumeType.bodyStrong,
                  ).copyWith(color: lume.text, fontSize: small ? 13 : null),
                ),
              ),
              if (onClear != null && hasText)
                LumePressable(
                  onTap: onClear,
                  semanticLabel: 'Clear',
                  minSize: 32,
                  borderRadius: LumeRadius.full,
                  child: LumeIcon(
                    LumeIcons.x,
                    size: LumeSpace.iconSm,
                    color: lume.text3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `:focus-within` for a box whose *input* is what takes focus.
///
/// The same relationship `LumeToolField` keeps: a `Focus` that can never be
/// focused itself and hears when a descendant is.
class _FocusWithin extends StatefulWidget {
  const _FocusWithin({required this.builder});

  final Widget Function(BuildContext context, bool within) builder;

  @override
  State<_FocusWithin> createState() => _FocusWithinState();
}

class _FocusWithinState extends State<_FocusWithin> {
  bool _within = false;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (bool has) {
      if (_within != has) setState(() => _within = has);
    },
    child: widget.builder(context, _within),
  );
}

/// `.stepper` — decrement, value, increment.
///
/// Measured: the pill is 92 × 32, its buttons 26 × 26, 3 px inset, 4 px gaps,
/// tabular value at 13 / 700.
///
/// **The visible control is exactly that. The touch targets are not.**
/// 26 × 26 is far under §9's 44 × 44 floor, and the reference has the same
/// problem — this is an accessibility correction, not a redesign. Each button
/// gets a real 44 × 44 target laid over the pill and extending 6 px past each
/// end; the pill, the circles, their size, their colour and their positions are
/// unchanged to the pixel.
///
/// ```text
///  0        44          60         104     the widget's own box, 104 × 44
///  ├── decrement ──┤    ├── increment ──┤  two 44 × 44 targets, 16 px apart
///      ╭───────────────────────────╮
///   6  │ (–)   26   value   26  (+) │  6   the pill, 92 × 32, centred
///      ╰───────────────────────────╯
/// ```
///
/// The targets cannot overlap: the gap between them is the value column plus
/// both inner gaps, and the value has a 26 px floor. They stay inside the
/// widget's own bounds, so nothing is clipped and nothing hangs into a
/// neighbour.
class LumeStepper extends StatelessWidget {
  const LumeStepper({
    super.key,
    required this.label,
    required this.value,
    this.onDecrement,
    this.onIncrement,
    this.decrementLabel,
    this.incrementLabel,
  });

  /// The accessible name of the quantity being stepped.
  final String label;

  /// Already formatted — the widget does not know what the number means.
  final String value;

  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final String? decrementLabel;
  final String? incrementLabel;

  /// The visible pill. Measured.
  static const double height = 32;

  /// The visible button. Measured.
  static const double buttonSize = 26;

  /// The interactive target, per §9.
  static const double targetSize = LumeSpace.tap;

  /// How far each target reaches past the pill: (44 − 26) / 2 − 3 inset = 6.
  /// Chosen so a target's centre lands exactly on its circle's centre.
  static const double overhang = 6;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      container: true,
      label: label,
      value: value,
      child: SizedBox(
        height: targetSize,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // The pill, unchanged, inset by the overhang so the targets have
            // somewhere to reach.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: overhang),
              child: Container(
                height: height,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: lume.tintNeutral,
                  borderRadius: LumeRadius.full,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // The circles are drawn by the targets above, so these are
                    // the space they occupy and nothing else.
                    const SizedBox(width: buttonSize, height: buttonSize),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: buttonSize),
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style:
                            LumeType.numeric(
                              LumeType.fit(context, context.lumeType.meta),
                            ).copyWith(
                              color: lume.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const SizedBox(width: buttonSize, height: buttonSize),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: targetSize,
              child: _StepButton(
                icon: LumeIcons.minus,
                label: '${decrementLabel ?? 'Decrease'} $label',
                onTap: onDecrement,
              ),
            ),
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              width: targetSize,
              child: _StepButton(
                icon: LumeIcons.plus,
                label: '${incrementLabel ?? 'Increase'} $label',
                onTap: onIncrement,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 44 × 44 target holding a 26 × 26 circle at its centre.
///
/// The circle is what moves under a press and what carries focus; the
/// surrounding 9 px of target is transparent and does nothing but catch
/// thumbs.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, this.onTap});

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: LumePressable(
        onTap: onTap,
        enabled: enabled,
        borderRadius: LumeRadius.full,
        minSize: LumeStepper.targetSize,
        excludeSemantics: true,
        child: Center(
          child: Container(
            width: LumeStepper.buttonSize,
            height: LumeStepper.buttonSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: lume.card, shape: BoxShape.circle),
            child: LumeIcon(
              icon,
              size: LumeSpace.iconSm,
              color: enabled ? lume.text2 : lume.text3,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.cfield--check` — a checkbox with its label, as one 44 px target.
class LumeCheckbox extends StatelessWidget {
  const LumeCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      checked: value,
      enabled: onChanged != null,
      label: label,
      child: LumePressable(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        enabled: onChanged != null,
        borderRadius: LumeRadius.brXs,
        button: false,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LumeSpace.x2),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: LumeMotion.duration(context, LumeMotion.fast),
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value ? lume.accent : lume.card,
                  borderRadius: LumeRadius.brXs,
                  border: Border.all(
                    color: value ? lume.accent : lume.border2,
                    width: LumeSpace.border,
                  ),
                ),
                child: value
                    ? LumeIcon(LumeIcons.check, size: 15, color: lume.onAccent)
                    : null,
              ),
              const SizedBox(width: LumeSpace.x3),
              Expanded(
                child: Text(
                  label,
                  style: LumeType.fit(
                    context,
                    context.lumeType.bodyStrong,
                  ).copyWith(color: lume.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single-choice row — the shape the account routes' option lists use.
class LumeRadioRow extends StatelessWidget {
  const LumeRadioRow({
    super.key,
    required this.label,
    required this.selected,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      child: LumePressable(
        onTap: onTap,
        selected: selected,
        borderRadius: LumeRadius.brSm,
        excludeSemantics: true,
        child: Padding(
          padding: LumeSpace.padRow,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: LumeType.fit(
                        context,
                        context.lumeType.bodyStrong,
                      ).copyWith(color: lume.text),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: LumeType.fit(
                          context,
                          context.lumeType.metaSmall,
                        ).copyWith(color: lume.text3),
                      ),
                  ],
                ),
              ),
              if (selected)
                LumeIcon(
                  LumeIcons.check,
                  size: LumeSpace.iconMd,
                  color: lume.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.switch` — the toggle the faith card and the settings rows use.
class LumeSwitch extends StatelessWidget {
  const LumeSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  /// `.switch { width: 42px; height: 25px; padding: 3px }` with a 19 px knob
  /// that travels 17. Measured from the stylesheet rather than rounded to a
  /// friendlier pair: two points is the difference between a permission row's
  /// body being 212 wide and 210, and it compounds down a column.
  static const double width = 42;
  static const double height = 25;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: LumePressable(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        enabled: onChanged != null,
        borderRadius: LumeRadius.full,
        minSize: LumeSpace.tap,
        excludeSemantics: true,
        child: Center(
          widthFactor: 1,
          child: AnimatedContainer(
            duration: LumeMotion.duration(context, LumeMotion.fast),
            curve: LumeMotion.ease,
            width: width,
            height: height,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? lume.accent : lume.border2,
              borderRadius: LumeRadius.full,
            ),
            child: AnimatedAlign(
              duration: LumeMotion.duration(context, LumeMotion.fast),
              curve: LumeMotion.ease,
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? lume.onAccent : lume.card,
                  shape: BoxShape.circle,
                  boxShadow: context.lumeShadows.xs,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A text field, in all six of its states: at rest, focused, filled, valid,
/// invalid and disabled — with an optional reveal control for a password.
///
/// Shared rather than screen-local. The authentication flow and the account
/// section ask for the same password, refuse it for the same reasons and draw
/// the same box; two copies would drift the first time one of them was
/// adjusted.
/// Which of the stylesheet's two field shapes this is.
///
/// `.field` is the product's ordinary form field — an uppercase 11-point
/// label over a 48-point box on `card-2`. `.auth .field` is the same element
/// with the authentication flow's own chrome: a sentence-case 13-point label
/// over a 52-point box with more room in it. Both exist in `tools/shared.css`
/// and `auth.css`, and a field drawn in the wrong one is visibly the wrong
/// size.
enum LumeFieldVariant { form, auth }

class LumeInputField extends StatefulWidget {
  /// `.auth .field__label` — 13 / 600, sentence case.
  static TextStyle labelStyle(BuildContext context) =>
      context.lumeType.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.065,
        color: context.lume.text2,
      );

  /// `.field__label` — 11 / 700, `.02em`, **uppercase**, muted. The form
  /// field's own label, and the one the account section's forms wear.
  static TextStyle formLabelStyle(BuildContext context) => LumeType.tracked(
    LumeType.natural(context, context.lumeType.metaSmall, size: 11),
    0.02,
  ).copyWith(color: context.lume.text3, fontWeight: FontWeight.w700);

  /// `.field__hint` and the message under a field — 12.5 / 500, muted.
  static TextStyle captionStyle(BuildContext context) =>
      context.lumeType.body.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: context.lume.text3,
      );

  const LumeInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.error,
    this.hint,
    this.placeholder,
    this.optionalLabel,
    this.valid = false,
    this.obscure = false,
    this.revealed = false,
    this.onToggleReveal,
    this.revealShowLabel,
    this.revealHideLabel,
    this.keyboardType,
    this.autofillHints,
    this.maxLength,
    this.textInputAction,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.variant = LumeFieldVariant.auth,
  });

  /// Which shape to draw. See [LumeFieldVariant].
  final LumeFieldVariant variant;

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  /// Fires on blur. Only the checks that can be made in isolation happen
  /// there; the rest wait for the submission.
  final VoidCallback? onEditingComplete;
  final VoidCallback? onSubmitted;

  final String? error;
  final String? hint;
  final String? placeholder;
  final String? optionalLabel;

  /// Passed a check it could be judged on alone. Draws a tick as well as a
  /// border, so the state is never colour alone.
  final bool valid;

  final bool obscure;
  final bool revealed;
  final VoidCallback? onToggleReveal;
  final String? revealShowLabel;
  final String? revealHideLabel;

  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;

  /// `.auth .field__box { min-height: 52px }`.
  static const double boxHeight = 52;
  static const double boxRadius = 14;
  static const double messageHeight = 17;
  static const double labelGap = 8;
  static const double toggleSize = 34;

  /// `.field { gap: 6px }` and `.field__box { padding: 10px 12px }` with a
  /// 14 / 700 input — measured at 48 tall, four shorter than the auth box.
  static const double formLabelGap = 6;
  static const double formBoxHeight = 48;

  /// `--r-xs`, where the auth box takes the larger radius.
  static const double formBoxRadius = 12;

  @override
  State<LumeInputField> createState() => _LumeInputFieldState();
}

class _LumeInputFieldState extends State<LumeInputField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  late final FocusNode _node = widget.focusNode ?? FocusNode();
  bool _ownsNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsNode = widget.focusNode == null;
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focused == _node.hasFocus) return;
    setState(() => _focused = _node.hasFocus);
    if (!_node.hasFocus) widget.onEditingComplete?.call();
  }

  @override
  void didUpdateWidget(LumeInputField old) {
    super.didUpdateWidget(old);
    // The controller owns the caret; only a value the flow changed out from
    // under the field is written back.
    if (widget.value != _controller.text && widget.value != old.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _node.removeListener(_onFocus);
    if (_ownsNode) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool invalid = widget.error != null;
    final bool filled = widget.value.isNotEmpty;
    final bool good = !invalid && widget.valid;

    final bool form = widget.variant == LumeFieldVariant.form;
    // `.field__label` is uppercased as presentation, which is why it is done
    // here and not baked into a translation: Urdu and Arabic have no case and
    // are unchanged by it.
    final TextStyle labelStyle = form
        ? LumeInputField.formLabelStyle(context)
        : LumeInputField.labelStyle(context);
    final String label = form
        ? LumeType.overline(context, widget.label)
        : widget.label;

    // `.field__box input` is 14 / 700 / -.026em; the authentication flow's
    // override is 16 / 600. Two sizes, because the stylesheet has two.
    final TextStyle inputStyle = form
        ? context.lumeType.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.364,
            color: lume.text,
          )
        : context.lumeType.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: -0.192,
            color: lume.text,
          );

    final Color edge = invalid
        ? Color.lerp(lume.rose, lume.border2, 0.4)!
        : good
        ? Color.lerp(lume.accent, lume.border2, 0.45)!
        : _focused
        ? lume.accent
        : lume.border2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: label),
              if (widget.optionalLabel != null)
                // `text-transform: none; font-style: normal` on the optional
                // marker: it is a word, not part of the label's kicker.
                TextSpan(
                  text: ' · ${widget.optionalLabel}',
                  // `text-transform: none; font-style: normal;
                  // font-weight: 600` — and nothing about the tracking, which
                  // it inherits.
                  style: labelStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: lume.text3,
                  ),
                ),
            ],
          ),
          style: labelStyle,
        ),
        SizedBox(
          height: form ? LumeInputField.formLabelGap : LumeInputField.labelGap,
        ),
        AnimatedContainer(
          duration: LumeMotion.fast,
          curve: LumeMotion.easeOut,
          constraints: BoxConstraints(
            minHeight: form
                ? LumeInputField.formBoxHeight
                : LumeInputField.boxHeight,
          ),
          padding: EdgeInsets.symmetric(horizontal: form ? 12 : LumeSpace.x4),
          decoration: BoxDecoration(
            color: form ? lume.card2 : (filled ? lume.cardHover : lume.card),
            borderRadius: BorderRadius.circular(
              form ? LumeInputField.formBoxRadius : LumeInputField.boxRadius,
            ),
            border: Border.all(color: edge, width: LumeSpace.border),
            boxShadow: _focused || invalid
                ? <BoxShadow>[
                    BoxShadow(
                      color: invalid
                          ? lume.rose.withValues(alpha: 0.13)
                          : lume.accent.withValues(alpha: 0.16),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                // Material's TextField wants a Material ancestor for its
                // selection handles and cursor. Lume draws its own box, so the
                // field carries a transparent one rather than making every
                // screen that holds a field also hold a Scaffold.
                child: Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    controller: _controller,
                    focusNode: _node,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    obscureText: widget.obscure && !widget.revealed,
                    // A password field must never hand its contents to the
                    // keyboard's learning dictionary or its suggestion strip.
                    enableSuggestions: !widget.obscure,
                    autocorrect: !widget.obscure,
                    keyboardType: widget.keyboardType,
                    autofillHints: widget.autofillHints,
                    textInputAction: widget.textInputAction,
                    maxLength: widget.maxLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    onChanged: widget.onChanged,
                    onSubmitted: (_) => widget.onSubmitted?.call(),
                    style: inputStyle,
                    cursorColor: lume.accent,
                    decoration: InputDecoration(
                      isDense: true,
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.placeholder,
                      hintStyle: inputStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: lume.text3,
                      ),
                    ),
                  ),
                ),
              ),
              if (good && widget.onToggleReveal == null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 10),
                  child: ExcludeSemantics(
                    child: LumeIcon(
                      LumeIcons.check,
                      size: 17,
                      color: lume.accent,
                    ),
                  ),
                ),
              if (widget.onToggleReveal != null)
                Transform.translate(
                  offset: const Offset(8, 0),
                  child: LumePressable(
                    onTap: widget.onToggleReveal,
                    semanticLabel: widget.revealed
                        ? widget.revealHideLabel
                        : widget.revealShowLabel,
                    selected: widget.revealed,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox.square(
                      dimension: LumeInputField.toggleSize,
                      child: Center(
                        child: LumeIcon(
                          widget.revealed ? LumeIcons.eyeOff : LumeIcons.eye,
                          size: LumeSpace.iconSm,
                          color: lume.text3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: LumeInputField.labelGap),
        // The message line is always in the layout, even with nothing to say,
        // so an error appearing never moves the button being reached for.
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: LumeInputField.messageHeight,
          ),
          child: invalid
              ? Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: LumeIcon(
                          LumeIcons.alert,
                          size: 12,
                          color: lume.roseInk,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.error!,
                          style: context.lumeType.body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: lume.roseInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : widget.hint != null
              ? Text(
                  widget.hint!,
                  style: LumeInputField.captionStyle(
                    context,
                  ).copyWith(fontSize: 12, height: 1.4),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
