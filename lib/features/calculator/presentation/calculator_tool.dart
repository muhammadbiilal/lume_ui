/// Calculator — the reference's composition, on arithmetic that is right.
///
/// `tools/everyday/calculator.tool.js` is thirty-six lines: a readout, a grid
/// of nineteen keys, and a History section. It holds no arithmetic; the engine
/// lives in `screens/tool.screen.js:894-957` and the rows come from
/// `tools/context.js:1772-1775`. The composition here is that one, measured
/// (`tool_calculator_default_pk_*`): the `.calc` block, then History, then the
/// frame's source bar and related tools.
///
/// The arithmetic is not that one. Seven defects were audited and all seven
/// are corrected; each is named where it is fixed, and the two that change
/// visible behaviour are stated again here so nothing hides in a tolerance:
///
/// 1. **Divide by zero returned `0`** (`:913`). `5 ÷ 0 =` showed `0`, which is
///    not a smaller wrong answer than `Infinity` — it is a wrong answer that
///    looks right. Now `l.calcErrDivZero`, and never a number.
/// 2. **`%` skipped the trim** (`:935`): `1.1 %` rendered
///    `0.011000000000000001`. Now exactly `0.011` ([LumeDecimal.perCent]).
/// 3. **The `1e10` trim failed above |r| > 900,719.925** (`:900, :914`), so
///    `10000000 ÷ 3` displayed `3333333.3333333335`. Now that division is
///    refused as one that does not end (`l.calcErrPrecision`), because it does
///    not end, and no number of displayed digits would make it end.
/// 4. **The display never passed through a formatter** (`:907`): ASCII digits
///    and an ASCII point for every reader, in every language
///    (`calculator_text.dart`).
/// 5. **The readout was emitted with a hard-coded `0`**
///    (`calculator.tool.js:22`) while the model held the real value, so a
///    reopened calculator lied about what was in it until the next keypress.
///    Here the first paint is [LumeCalcEngine.display].
/// 6. **History rendered unconditionally with no empty state**
///    (`calculator.tool.js:32-34`): a section head over two pixels of
///    border. Now `l.calcNoHistory`. This is the one deliberate difference in
///    the *geometry* — everything below History sits lower by the height of
///    the empty state, and the parity report records the amount.
/// 7. **No operator precedence**: `2 + 3 × 4 =` gave 20. Lume is algebraic
///    and gives 14; the reasoning is in `calculator_engine.dart`.
///
/// The pad is still the reference's nineteen keys in the reference's order.
/// Nothing scientific, no memory, no parentheses have been added. The one key
/// that gained a meaning is `AC`, which now clears the entry first and only
/// then everything, and says in words which it is about to do.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_numerals.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/calculator_engine.dart';
import '../domain/lume_decimal.dart';
import 'calculator_text.dart';

class LumeCalculatorTool extends ConsumerStatefulWidget {
  const LumeCalculatorTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeCalculatorTool(request: request);

  static const String id = 'calculator';

  /// The whole `.calc` block — readout and pad — so a test can measure it
  /// against the reference's own 519 points.
  static const Key blockKey = ValueKey<String>('calculator.block');
  static const Key expressionKey = ValueKey<String>('calculator.expression');
  static const Key readoutKey = ValueKey<String>('calculator.readout');
  static const Key noteKey = ValueKey<String>('calculator.note');
  static const Key keypadKey = ValueKey<String>('calculator.keypad');
  static const Key historyKey = ValueKey<String>('calculator.history');
  static const Key emptyKey = ValueKey<String>('calculator.empty');
  static const Key clearKey = ValueKey<String>('calculator.clear');
  static const Key backspaceKey = ValueKey<String>('calculator.backspace');
  static const Key perCentKey = ValueKey<String>('calculator.percent');
  static const Key pointKey = ValueKey<String>('calculator.point');
  static const Key equalsKey = ValueKey<String>('calculator.equals');

  static Key digitKey(int n) => ValueKey<String>('calculator.digit.$n');
  static Key opKey(LumeCalcOp op) =>
      ValueKey<String>('calculator.op.${op.name}');

  // ---- `.calc`, measured -------------------------------------------------

  /// `.calc__keys { gap: 9px }`.
  static const double keyGap = 9;

  /// `.calc__key { aspect-ratio: 1.15 }` — width over height.
  static const double keyAspect = 1.15;

  /// `.calc__screen { padding: 22px 6px 20px }`.
  static const EdgeInsets readoutPadding = EdgeInsets.fromLTRB(6, 22, 6, 20);

  /// `.calc__out { margin-top: 6px }`.
  static const double readoutGap = 6;

  /// `.calc__expr { min-height: 20px }`.
  static const double expressionMinHeight = 20;

  /// The height of `.calc__screen` as the browser resolves it, measured on
  /// every committed cell and the same at 390, 650, 802 and 1050 wide:
  /// 519.02 − 387.09, 701.67 − 569.70, 866.91 − 734.91, 945.11 − 813.17. The
  /// stylesheet's own `min-height: 108` is not what it comes out at, because
  /// a 46-point line box is taller than 108 − 42 − 26.
  ///
  /// A **minimum**, not a height: at 200 % the text is larger than this and
  /// the block grows rather than clipping.
  static const double readoutMinHeight = 131.95;

  /// The same, for the scripts whose line boxes are looser — measured on
  /// `..._390x844_light_ar` and `..._light_ur`, both 534.61 − 387.09.
  static const double readoutMinHeightTall = 147.52;

  @override
  ConsumerState<LumeCalculatorTool> createState() => _LumeCalculatorToolState();
}

class _LumeCalculatorToolState extends ConsumerState<LumeCalculatorTool> {
  static const String _id = LumeCalculatorTool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late LumeCalcEngine _engine = LumeCalcEngine.decode(
    _session.read(_id, 'state'),
  );

  static String _note(AppLocalizations l, LumeFormatting f) =>
      l.calcPrecisionNote(f.integer(LumeDecimal.maxScale));

  void _press(LumeCalcEngine next) {
    setState(() {
      _engine = next;
      _session.write(_id, 'state', next.encode());
    });
  }

  /// Clearing the entry is visible: the number goes. Clearing *everything*
  /// takes away a pending sum a reader cannot see, so it is announced.
  void _clear() {
    final bool everything = !_engine.clearsEntryOnly;
    _press(_engine.clear());
    if (everything) {
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          AppLocalizations.of(context).calcCleared,
          Directionality.of(context),
        ),
      );
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final LumeCalcEngine e = _engine;
    final LogicalKeyboardKey k = event.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _press(e.equals());
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.backspace) {
      _press(e.backspace());
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      _clear();
      return KeyEventResult.handled;
    }
    final String c = event.character ?? '';
    if (c.isEmpty) return KeyEventResult.ignored;
    final int? digit = calcDigitOf(c);
    if (digit != null) {
      _press(e.digit(digit));
      return KeyEventResult.handled;
    }
    final LumeCalcEngine? next = switch (c) {
      '+' => e.operate(LumeCalcOp.add),
      '-' || calcMinusSign => e.operate(LumeCalcOp.subtract),
      '*' || 'x' || 'X' || calcTimesSign => e.operate(LumeCalcOp.multiply),
      '/' || calcDivideSign => e.operate(LumeCalcOp.divide),
      calcPerCentSign => e.perCent(),
      calcEqualsSign => e.equals(),
      _ => null,
    };
    if (next != null) {
      _press(next);
      return KeyEventResult.handled;
    }
    if (calcIsPointKey(c, _separator)) {
      _press(e.dot());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _separator = '.';

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    _separator = calcDecimalSeparator(f);
    final LumeCalcEngine e = _engine;

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // `.calc` is not a section: it sits straight under the tool bar
            // and carries only the page gutter.
            LumeToolSection(
              spaceAbove: 0,
              child: Column(
                key: LumeCalculatorTool.blockKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _Readout(engine: e, l: l, f: f),
                  _Keypad(
                    engine: e,
                    l: l,
                    f: f,
                    onPress: _press,
                    onClear: _clear,
                  ),
                ],
              ),
            ),
            LumeToolSection(
              title: l.calcHistory,
              // The precision policy is stated where a reader would look for
              // it — under the rows, or under the empty state when there are
              // none, which keeps the section head the reference's own
              // nineteen points.
              subtitle: e.history.isEmpty ? null : _note(l, f),
              child: e.history.isEmpty
                  ? LumeToolState(
                      key: LumeCalculatorTool.emptyKey,
                      icon: LumeIcons.calculator,
                      title: l.calcNoHistory,
                      footnote: _note(l, f),
                    )
                  : LumeRows(
                      key: LumeCalculatorTool.historyKey,
                      children: <Widget>[
                        for (final LumeCalcSum s in e.history)
                          _HistoryRow(sum: s, l: l, f: f),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.calc__screen` — the expression above, the value below, both at the end.
class _Readout extends StatelessWidget {
  const _Readout({required this.engine, required this.l, required this.f});

  final LumeCalcEngine engine;
  final AppLocalizations l;
  final LumeFormatting f;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final bool tall = LumeType.needsTallLineHeight(
      Localizations.maybeLocaleOf(context),
    );
    final String expression = calcExpressionText(f, engine.expression);
    final LumeCalcError? error = engine.error;
    final bool halted = engine.halted;
    final String number = calcNumber(f, engine.display);
    final String spoken = halted ? calcErrorText(l, error!) : number;

    final TextStyle expressionStyle = LumeType.numeric(
      LumeType.natural(
        context,
        context.lumeType.meta,
        size: 14,
      ).copyWith(fontWeight: FontWeight.w600, color: lume.text3),
    );
    final TextStyle valueStyle = LumeType.numeric(
      LumeType.tracked(
        LumeType.natural(
          context,
          context.lumeType.display,
          size: 46,
        ).copyWith(fontWeight: FontWeight.w800, color: lume.text),
        -0.05,
      ),
    );

    // The minimum is the *padded* box, as `min-height` on a block with
    // `box-sizing: border-box` is.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: tall
            ? LumeCalculatorTool.readoutMinHeightTall
            : LumeCalculatorTool.readoutMinHeight,
      ),
      child: Padding(
        padding: LumeCalculatorTool.readoutPadding,
        child: Semantics(
          container: true,
          // The expression first, the value second: a reader hears what is
          // being worked out before they hear what it came to.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: LumeCalculatorTool.expressionMinHeight,
                ),
                child: Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: Semantics(
                    label: l.calcExpression,
                    value: expression,
                    excludeSemantics: true,
                    child: LumeNumerals(
                      expression,
                      key: LumeCalculatorTool.expressionKey,
                      style: expressionStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LumeCalculatorTool.readoutGap),
              Semantics(
                label: l.calcDisplay,
                value: spoken,
                liveRegion: true,
                excludeSemantics: true,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: halted
                      // "Never a number": a refused division shows what went
                      // wrong where the answer would have been.
                      ? Text(
                          spoken,
                          key: LumeCalculatorTool.readoutKey,
                          textAlign: TextAlign.end,
                          maxLines: 3,
                          style: LumeType.natural(
                            context,
                            context.lumeType.bodyStrong,
                            size: 17,
                          ).copyWith(color: lume.rose),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: LumeNumerals(
                            number,
                            key: LumeCalculatorTool.readoutKey,
                            style: valueStyle,
                            maxLines: 1,
                          ),
                        ),
                ),
              ),
              if (error == LumeCalcError.tooLong) ...<Widget>[
                const SizedBox(height: LumeSpace.x1),
                Text(
                  calcErrorText(l, error!),
                  key: LumeCalculatorTool.noteKey,
                  textAlign: TextAlign.end,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: lume.rose, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The tone a key is drawn in — the stylesheet's four classes.
enum _KeyTone { plain, function, operator, equals }

/// `.calc__keys` — four columns, nineteen keys, the zero two wide.
class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.engine,
    required this.l,
    required this.f,
    required this.onPress,
    required this.onClear,
  });

  final LumeCalcEngine engine;
  final AppLocalizations l;
  final LumeFormatting f;
  final ValueChanged<LumeCalcEngine> onPress;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double gap = LumeCalculatorTool.keyGap;
        final double width = (c.maxWidth - gap * 3) / 4;
        final double height = width / LumeCalculatorTool.keyAspect;
        final LumeCalcEngine e = engine;

        Widget key(
          Key id,
          String glyph,
          String label,
          LumeCalcEngine next, {
          _KeyTone tone = _KeyTone.plain,
          double span = 1,
          String? icon,
          VoidCallback? instead,
        }) => _Key(
          id: id,
          glyph: glyph,
          icon: icon,
          label: label,
          tone: tone,
          width: width * span + gap * (span - 1),
          height: height,
          onTap: instead ?? () => onPress(next),
        );

        Widget digit(int n, {double span = 1}) => key(
          LumeCalculatorTool.digitKey(n),
          f.integer(n),
          l.calcDigit(f.integer(n)),
          e.digit(n),
          span: span,
        );

        Widget op(LumeCalcOp o) => key(
          LumeCalculatorTool.opKey(o),
          calcOperatorSign(o),
          calcOperatorName(l, o),
          e.operate(o),
          tone: _KeyTone.operator,
        );

        Widget row(List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: gap),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: gap),
                children[i],
              ],
            ],
          ),
        );

        return Semantics(
          container: true,
          label: l.calcKeypad,
          explicitChildNodes: true,
          child: Column(
            key: LumeCalculatorTool.keypadKey,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              row(<Widget>[
                key(
                  LumeCalculatorTool.clearKey,
                  '',
                  // The one key whose meaning the reader has to be told in
                  // words: it clears the entry, and then everything.
                  e.clearsEntryOnly ? l.calcClearEntry : l.calcClear,
                  e.clear(),
                  tone: _KeyTone.function,
                  instead: onClear,
                ),
                op(LumeCalcOp.divide),
                op(LumeCalcOp.multiply),
                key(
                  LumeCalculatorTool.backspaceKey,
                  '',
                  l.calcBackspace,
                  e.backspace(),
                  tone: _KeyTone.function,
                  icon: LumeIcons.backspace,
                ),
              ]),
              row(<Widget>[
                digit(7),
                digit(8),
                digit(9),
                op(LumeCalcOp.subtract),
              ]),
              row(<Widget>[digit(4), digit(5), digit(6), op(LumeCalcOp.add)]),
              row(<Widget>[
                digit(1),
                digit(2),
                digit(3),
                key(
                  LumeCalculatorTool.perCentKey,
                  calcPerCentSign,
                  l.calcPercent,
                  e.perCent(),
                  tone: _KeyTone.function,
                ),
              ]),
              Row(
                children: <Widget>[
                  digit(0, span: 2),
                  const SizedBox(width: gap),
                  key(
                    LumeCalculatorTool.pointKey,
                    calcDecimalSeparator(f),
                    l.calcDecimal,
                    e.dot(),
                  ),
                  const SizedBox(width: gap),
                  key(
                    LumeCalculatorTool.equalsKey,
                    calcEqualsSign,
                    l.calcEquals,
                    e.equals(),
                    tone: _KeyTone.equals,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.id,
    required this.glyph,
    required this.label,
    required this.tone,
    required this.width,
    required this.height,
    required this.onTap,
    this.icon,
  });

  final Key id;
  final String glyph;
  final String? icon;
  final String label;
  final _KeyTone tone;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final (Color background, Color ink, double size) = switch (tone) {
      _KeyTone.plain => (lume.card, lume.text, 20.0),
      _KeyTone.function => (lume.tintNeutral, lume.text2, 17.0),
      _KeyTone.operator => (lume.tintAccent, lume.accent, 20.0),
      _KeyTone.equals => (lume.accent, lume.onAccent, 20.0),
    };
    // `.calc__key { border: 1px solid var(--border) }` — the tinted keys
    // paint their own ground and take the same hairline, so the grid reads
    // as one set of surfaces rather than two.
    final Widget face = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(LumeRadius.md)),
        border: Border.all(color: lume.border, width: LumeSpace.border),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LumeSpace.x2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: icon != null
                ? LumeIcon(icon!, size: LumeSpace.iconLg, color: ink)
                : glyph.isEmpty
                ? const SizedBox.shrink()
                : LumeNumerals(
                    glyph,
                    style: LumeType.tracked(
                      LumeType.natural(
                        context,
                        context.lumeType.body,
                        size: size,
                      ).copyWith(fontWeight: FontWeight.w600, color: ink),
                      -0.02,
                    ),
                    maxLines: 2,
                  ),
          ),
        ),
      ),
    );

    // A function key carries a word, not a glyph: the clear key has to say
    // which of the two things it is about to do.
    final Widget content = glyph.isEmpty && icon == null
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.all(
                Radius.circular(LumeRadius.md),
              ),
              border: Border.all(color: lume.border, width: LumeSpace.border),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: LumeSpace.x2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: math.max(width, 1)),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: LumeType.natural(
                        context,
                        context.lumeType.meta,
                        size: 13,
                      ).copyWith(fontWeight: FontWeight.w700, color: ink),
                    ),
                  ),
                ),
              ),
            ),
          )
        : face;

    return SizedBox(
      width: width,
      height: height,
      child: LumePressable(
        key: id,
        onTap: onTap,
        semanticLabel: label,
        minSize: 0,
        borderRadius: const BorderRadius.all(Radius.circular(LumeRadius.md)),
        // The glyph is the label's picture, not a second thing to read out:
        // a reader hears "Divided by", not "Divided by, ÷".
        child: ExcludeSemantics(child: content),
      ),
    );
  }
}

/// One finished sum. The expression and the result are both arithmetic, so
/// both are isolated left-to-right inside a right-to-left page; what the
/// screen reader hears is `l.calcHistoryRow`, in one piece.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.sum, required this.l, required this.f});

  final LumeCalcSum sum;
  final AppLocalizations l;
  final LumeFormatting f;

  @override
  Widget build(BuildContext context) {
    final String expression = calcExpressionText(f, sum.tokens);
    final String result = calcNumber(f, sum.result.toDecimalString());
    return Semantics(
      container: true,
      label: l.calcHistoryRow(expression, result),
      excludeSemantics: true,
      child: LumeCompactRow(
        icon: LumeIcons.calculator,
        label: calcIsolate(expression),
        value: calcIsolate(result),
        chevron: false,
      ),
    );
  }
}
