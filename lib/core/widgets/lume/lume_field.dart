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
class LumeToolField extends StatelessWidget {
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
  final bool enabled;

  /// `.field--wide` — spans both columns of a two-column grid.
  final bool wide;

  /// Measured: 42 px.
  static const double boxHeight = 42;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Measured: 11 / 800 / .02em / uppercase / muted.
        Text(
          LumeType.overline(context, label),
          style: LumeType.tracked(
            LumeType.fit(
              context,
              context.lumeType.metaSmall,
            ).copyWith(fontWeight: FontWeight.w700),
            0.02,
          ).copyWith(color: lume.text3),
        ),
        const SizedBox(height: 5),
        Container(
          constraints: const BoxConstraints(minHeight: boxHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: lume.card2,
            borderRadius: LumeRadius.brXs,
            border: Border.all(color: lume.border, width: LumeSpace.border),
          ),
          child: Row(
            children: <Widget>[
              if (prefix != null) ...<Widget>[
                _Affix(prefix!),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: _RawInput(
                  controller: controller,
                  value: value,
                  onChanged: onChanged,
                  placeholder: placeholder,
                  kind: kind,
                  enabled: enabled,
                  style: LumeType.fit(
                    context,
                    context.lumeType.bodyStrong,
                  ).copyWith(color: lume.text),
                ),
              ),
              if (suffix != null) ...<Widget>[
                const SizedBox(width: 6),
                _Affix(suffix!),
              ],
            ],
          ),
        ),
        if (hint != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            hint!,
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
  Widget build(BuildContext context) => Text(
    text,
    style: LumeType.fit(
      context,
      context.lumeType.metaSmall,
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
                    style: LumeType.fit(
                      context,
                      context.lumeType.bodyStrong,
                    ).copyWith(color: lume.text),
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
  });

  final String? placeholder;
  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;

  /// Shows a clear affordance when non-null and the field has content.
  final VoidCallback? onClear;

  final bool enabled;
  final bool autofocus;
  final String? semanticLabel;

  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool hasText = (controller?.text ?? value ?? '').isNotEmpty;

    return Semantics(
      textField: true,
      label: semanticLabel ?? placeholder,
      child: Container(
        constraints: const BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: lume.card,
          borderRadius: LumeRadius.brSm,
          border: Border.all(color: lume.border, width: LumeSpace.border),
          boxShadow: context.lumeShadows.xs,
        ),
        child: Row(
          children: <Widget>[
            LumeIcon(
              LumeIcons.search,
              size: LumeSpace.iconMd,
              color: lume.text3,
            ),
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
                style: LumeType.fit(
                  context,
                  context.lumeType.bodyStrong,
                ).copyWith(color: lume.text),
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
    );
  }
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

  static const double width = 44;
  static const double height = 26;

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
