/// Unit Converter — rollout wave 4, on the reference's own composition.
///
/// `tools/everyday/converter.tool.js` is 44 lines over `context.js:1096-1145`,
/// and it composes four things: a scrolling strip of six category chips, a
/// card with the amount on one side and the answer on the other with a round
/// swap between them, a list of the same amount in every unit of the
/// category, and a "Recent" section. This screen draws the first three.
///
/// ## The six corrections it carries
///
/// The factor table is `domain/unit_table.dart` and the policy behind it is
/// `ROLLOUT_WAVE_4.md` §3; four of these are that table, and are listed here
/// because they are what a reader would notice on this screen.
///
/// 1. **Decimal names get decimal factors.** `context.js:1116-1117` puts
///    `GB = 1024 MB` and `TB = 1024² MB` under the SI names, which overstate
///    by 2.4 % and 4.9 %. A gigabyte here is 1,000 megabytes, and `GB → MB`
///    reads 1,000.
/// 2. **The binary units are named.** KiB, MiB, GiB and TiB carry the powers
///    of 1,024 the reference hid under the decimal names, and the Data
///    category says which is which, in the one place a reader chooses
///    between them ([LumeConverterTool.dataNoteKey]).
/// 3. **Both gallons are named.** `context.js:1108` ships one `gal` at
///    3.78541 L — a US gallon, shown to every reader on earth, telling a UK
///    reader 16.7 % too little. There are two here, and neither is ever
///    written as a bare `gal` (see `lumeUnitSymbol`).
/// 4. **There is a unit picker.** The reference has none at all: `from` is
///    always the category's first unit and `to` is its second, or its
///    *fourth* on an imperial reader's screen, which serves ounces for mass,
///    cups for volume and marlas — a Pakistani land unit — for area
///    (`context.js:1129-1130`). Both units are chosen here, from a sheet.
/// 5. **The factors are the defined values.** The reference truncates every
///    imperial constant to six significant figures — `1609.34`, `0.453592`,
///    `1.60934`. A mile is exactly 1609.344 m, and the arithmetic is an
///    exact rational ([LumeRatio]) rounded once, for the display.
/// 6. **The selected chip is drawn selected.** `converter.tool.js:19` emits
///    `class="chip is-on"` and no stylesheet defines `.chip.is-on`
///    (`components.css:435-467`), so the reference never highlights the
///    category the reader is in. This one does.
///
/// ## The one subtraction
///
/// **"Recent" is gone.** `context.js:1140-1143` is two literals — `10 km → mi
/// = 6.21` and `1 kg → lb = 2.20` — presented as conversions the reader made.
/// Nothing records a conversion, so nothing can be listed back, and a
/// plausible-looking history of things the reader never did is worse than no
/// history. It is dropped rather than emptied, and nothing stands in for it:
/// `ROLLOUT_WAVE_4.md` §2 and §7 carry it as a named, approved subtraction.
///
/// ## Geometry
///
/// `tools/shared.css:1015-1041`. The card is a flex row 10 apart: two
/// `.convert__side` at `flex: 1; min-width: 0`, the `to` side ending its
/// text, and a 34-point circle between them. Each side is the symbol
/// (11 / 800 / .05em, muted), the figure (28 / 800 / −.045em, tabular) and
/// the unit's name (10 / 500, muted, one line). The figures keep their own
/// left-to-right order inside an Urdu or Arabic page, which
/// `shared.css:640-653` says of `.convert__input` and `.convert__out` by
/// name; everything else in the row mirrors.
library;

import 'package:flutter/material.dart';
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
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/lume_ratio.dart';
import '../domain/unit_table.dart';
import 'converter_units.dart';

class LumeConverterTool extends ConsumerStatefulWidget {
  const LumeConverterTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeConverterTool(request: request);

  /// The catalogue id, and the key the session is kept under.
  static const String id = 'converter';

  static const Key categoriesKey = ValueKey<String>('converter.categories');
  static const Key cardKey = ValueKey<String>('converter.card');
  static const Key amountKey = ValueKey<String>('converter.amount');
  static const Key swapKey = ValueKey<String>('converter.swap');
  static const Key fromKey = ValueKey<String>('converter.from');
  static const Key toKey = ValueKey<String>('converter.to');
  static const Key resultKey = ValueKey<String>('converter.result');
  static const Key allUnitsKey = ValueKey<String>('converter.allUnits');
  static const Key dataNoteKey = ValueKey<String>('converter.dataNote');
  static const Key unitSheetKey = ValueKey<String>('converter.unitSheet');

  static Key categoryKey(LumeUnitKind kind) =>
      ValueKey<String>('converter.category.${kind.name}');

  /// One row of the All-units list.
  static Key rowKey(String unitId) => ValueKey<String>('converter.row.$unitId');

  /// One choice in the unit sheet.
  static Key optionKey(String unitId) =>
      ValueKey<String>('converter.option.$unitId');

  /// `c.num(v, { maximumFractionDigits: 4 })` — the reference's own display
  /// precision, on both figures and every row.
  static const int places = 4;

  /// `.convert { gap: 10px }`.
  static const double gap = 10;

  /// `.convert__swap { width: 34px; height: 34px }`, drawn inside §9's
  /// 44-point target rather than being one (D6).
  static const double swapSize = LumeSpace.circleBack;

  /// `.convert__swap svg { width: 16px }`.
  static const double swapIcon = LumeSpace.iconSm;

  @override
  ConsumerState<LumeConverterTool> createState() => _LumeConverterToolState();
}

class _LumeConverterToolState extends ConsumerState<LumeConverterTool> {
  static const String _id = LumeConverterTool.id;

  late final LumeToolSession _session = ref.read(toolSessionProvider);
  TextEditingController? _amount;

  /// `fieldsFor('converter', { amount: 1 })` — the field opens on the
  /// reference's own 1 and is remembered from then on.
  TextEditingController get _amountField => _amount ??= TextEditingController(
    text: _session.field(_id, 'amount', () => kLumeConverterOpeningAmount),
  );

  @override
  void dispose() {
    _amount?.dispose();
    super.dispose();
  }

  /// `stateFor('converter').cat || 'length'`.
  LumeUnitKind get _kind {
    final String? stored = _session.read(_id, 'cat');
    for (final LumeUnitKind kind in LumeUnitKind.values) {
      if (kind.name == stored) return kind;
    }
    return LumeUnitKind.length;
  }

  /// The chosen unit, or the category's own opening one.
  ///
  /// A stored id is only honoured while it belongs to the category on the
  /// screen: the session outlives a category change, and a millilitre in the
  /// Length list would be a conversion nobody asked for. [lumeConvert] would
  /// catch it in debug; this means it cannot arise.
  LumeUnit _unit(String key) {
    final LumeUnitKind kind = _kind;
    final String? stored = _session.read(_id, key);
    if (stored != null) {
      for (final LumeUnit unit in lumeUnitsOf(kind)) {
        if (unit.id == stored) return unit;
      }
    }
    final (String from, String to) = kLumeUnitDefaults[kind]!;
    return lumeUnit(key == 'from' ? from : to);
  }

  void _write(Map<String, String> values) => setState(() {
    values.forEach((String key, String value) {
      _session.write(_id, key, value);
    });
  });

  /// `toolstate:converter:cat:<id>` — and, because both units are chosen
  /// here, the pair the new category opens on.
  void _chooseCategory(LumeUnitKind kind) {
    final (String from, String to) = kLumeUnitDefaults[kind]!;
    _write(<String, String>{'cat': kind.name, 'from': from, 'to': to});
  }

  /// `ucswap`. The reference keeps one `swapped` flag over a fixed pair; two
  /// chosen units exchange places instead, which is the same gesture.
  void _swap() {
    _write(<String, String>{'from': _unit('to').id, 'to': _unit('from').id});
  }

  Future<void> _pickUnit(String key) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeUnit current = _unit(key);
    final String? picked = await showLumeSheet<String>(
      context: context,
      barrierLabel: l.convertChooseUnit,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          tall: true,
          title: l.convertChooseUnit,
          child: SingleChildScrollView(
            child: Column(
              key: LumeConverterTool.unitSheetKey,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final LumeUnit unit in lumeUnitsOf(_kind))
                  LumeRadioRow(
                    key: LumeConverterTool.optionKey(unit.id),
                    label: lumeUnitName(l, unit.id),
                    // The symbol under the name, so the two gallons are told
                    // apart by both halves of what the card will show.
                    subtitle: lumeUnitSymbol(l, unit.id),
                    selected: unit.id == current.id,
                    onTap: () => Navigator.of(sheet).pop(unit.id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    // Choosing the unit the other side already holds swaps them rather than
    // leaving the card converting something into itself.
    final String other = key == 'from' ? 'to' : 'from';
    _write(
      picked == _unit(other).id
          ? <String, String>{key: picked, other: _unit(key).id}
          : <String, String>{key: picked},
    );
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );

    final LumeUnitKind kind = _kind;
    final LumeUnit from = _unit('from');
    final LumeUnit to = _unit('to');
    final TextEditingController amount = _amountField;

    // `Number(f.amount) * from.factor / to.factor`, exactly — and rounded
    // once, here, for the display.
    final LumeRatio value = converterAmount(amount.text, f);
    String figure(LumeUnit unit) => converterFigure(
      f,
      lumeConvert(
        value,
        from,
        unit,
      ).toStringAsFixedMax(LumeConverterTool.places),
    );

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // `.chips.chips--scroll` — six categories, and the one the reader
          // is in is drawn as such (correction 6).
          LumeToolSection(
            flush: true,
            child: LumeHorizontalStrip.chips(
              key: LumeConverterTool.categoriesKey,
              semanticLabel: l.convertCategory,
              children: <Widget>[
                for (final LumeUnitKind each in LumeUnitKind.values)
                  LumeChoiceChip(
                    key: LumeConverterTool.categoryKey(each),
                    label: lumeCategoryName(l, each),
                    icon: lumeCategoryIcon(each),
                    selected: each == kind,
                    onTap: () => _chooseCategory(each),
                  ),
              ],
            ),
          ),

          // `.convert`.
          LumeToolSection(
            child: LumeCard(
              key: LumeConverterTool.cardKey,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _ConvertSide(
                      unitKey: LumeConverterTool.fromKey,
                      label: l.convertFrom,
                      name: lumeUnitName(l, from.id),
                      symbol: lumeUnitSymbol(l, from.id),
                      onPick: () => _pickUnit('from'),
                      // The reference's `<input type="number"
                      // inputmode="decimal">`, at `.convert__input`'s own
                      // 28 / 800 with no box around it.
                      figure: _Amount(
                        controller: amount,
                        label: l.convertAmount,
                        onChanged: (String typed) =>
                            _write(<String, String>{'amount': typed}),
                      ),
                    ),
                  ),
                  const SizedBox(width: LumeConverterTool.gap),
                  _Swap(label: l.convertSwap, onTap: _swap),
                  const SizedBox(width: LumeConverterTool.gap),
                  Expanded(
                    child: _ConvertSide(
                      unitKey: LumeConverterTool.toKey,
                      label: l.convertTo,
                      name: lumeUnitName(l, to.id),
                      symbol: lumeUnitSymbol(l, to.id),
                      onPick: () => _pickUnit('to'),
                      toSide: true,
                      figure: _Result(
                        text: figure(to),
                        // Two numbers with nothing between them is not a
                        // conversion. A screen reader hears the relation.
                        spoken: l.convertEquals(
                          '${converterFigure(f, value.toStringAsFixedMax(LumeConverterTool.places))} '
                              '${lumeUnitSymbol(l, from.id)}',
                          '${figure(to)} ${lumeUnitSymbol(l, to.id)}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // `u.units.map(...)` — the amount in every unit of the category.
          LumeToolSection(
            title: l.convertAllUnits,
            child: LumeRows(
              key: LumeConverterTool.allUnitsKey,
              children: <Widget>[
                for (final LumeUnit unit in lumeUnitsOf(kind))
                  LumeCompactRow(
                    key: LumeConverterTool.rowKey(unit.id),
                    label: lumeUnitName(l, unit.id),
                    subtitle: lumeUnitSymbol(l, unit.id),
                    value: figure(unit),
                    chevron: false,
                  ),
              ],
            ),
          ),

          // Correction 2, said where it is decided. The other five categories
          // have nothing to disambiguate, so they carry no note.
          if (kind == LumeUnitKind.data)
            LumeToolSection(
              tight: true,
              child: LumeNoteCard(
                key: LumeConverterTool.dataNoteKey,
                title: lumeCategoryName(l, LumeUnitKind.data),
                text: l.convertDataNote,
                icon: lumeCategoryIcon(LumeUnitKind.data),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.convert__side` — the symbol, the figure, the unit's name.
///
/// The symbol and the name are the unit's control, and the figure sits
/// between them, so the control is drawn as its two halves: both open the
/// same sheet and both carry the same name, rather than one of them being a
/// silent target a reader has to guess at.
class _ConvertSide extends StatelessWidget {
  const _ConvertSide({
    required this.unitKey,
    required this.label,
    required this.name,
    required this.symbol,
    required this.figure,
    required this.onPick,
    this.toSide = false,
  });

  final Key unitKey;

  /// `l.convertFrom` / `l.convertTo`.
  final String label;

  final String name;
  final String symbol;
  final Widget figure;
  final VoidCallback onPick;

  /// `.convert__side--to { text-align: end }`.
  final bool toSide;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextAlign align = toSide ? TextAlign.end : TextAlign.start;
    final String spoken = '$label, $name';

    // `.convert__code` — 11 / 800 / .05em, muted.
    final Widget code = Text(
      symbol,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: LumeType.tracked(
        LumeType.natural(
          context,
          context.lumeType.metaSmall,
        ).copyWith(fontWeight: FontWeight.w800),
        0.05,
      ).copyWith(color: lume.text3),
    );

    // `.convert__name` — 10 / 500, muted, one line with an ellipsis.
    final Widget unitName = Text(
      name,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: LumeType.natural(
        context,
        context.lumeType.metaSmall,
        size: 10,
      ).copyWith(color: lume.text3),
    );

    // Neither half takes §9's 44-point floor: two stacked 44s would make the
    // card nearly twice the height the reference measures, for a control the
    // reference does not have at all. Both halves are pressable, the sheet
    // they open is a list of 44-point rows, and the keyboard and switch
    // access reach them as buttons — so the floor is kept where a miss
    // costs something, and the card stays the card. Recorded rather than
    // assumed (D6).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumePressable(
          key: unitKey,
          onTap: onPick,
          semanticLabel: spoken,
          minSize: 0,
          borderRadius: LumeRadius.brXs,
          child: ExcludeSemantics(child: code),
        ),
        // `.convert__input, .convert__out { margin-top: 4px }`.
        const SizedBox(height: 4),
        figure,
        // `.convert__name { margin-top: 3px }`.
        const SizedBox(height: 3),
        LumePressable(
          onTap: onPick,
          semanticLabel: spoken,
          minSize: 0,
          borderRadius: LumeRadius.brXs,
          child: ExcludeSemantics(child: unitName),
        ),
      ],
    );
  }
}

/// The face both figures are set in: `.convert__input, .convert__out`.
TextStyle _figureStyle(BuildContext context) => LumeType.numeric(
  LumeType.tracked(
    LumeType.natural(
      context,
      context.lumeType.display,
    ).copyWith(fontWeight: FontWeight.w800),
    -0.045,
  ),
);

/// `.convert__input` — the amount, typed.
///
/// A bare input, not a [LumeToolField]: the field component draws a label and
/// a box, and `.convert__input` is `border: 0; background: none; padding: 0`
/// at 28 points. What it does take from the field component is the keyboard —
/// `inputmode="decimal"` — and the Material the selection handles need.
class _Amount extends StatelessWidget {
  const _Amount({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;

  /// The field carries no label in the reference, and an unlabelled field is
  /// one a screen reader cannot name.
  final String label;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return Semantics(
      textField: true,
      label: label,
      child: LumeLtr(
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            key: LumeConverterTool.amountKey,
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            maxLines: 1,
            style: _figureStyle(context).copyWith(color: lume.text),
            cursorColor: lume.accent,
            // Digits — the reader's own as well as ASCII — and the separators
            // any of the three locales' keyboards write. An amount is a
            // quantity, so there is no sign key: the reference's `type=number`
            // takes one, and a negative length is not a conversion anybody
            // asked for.
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(
                RegExp('[0-9\u0660-\u0669\u06F0-\u06F9.,\u066B]'),
              ),
            ],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.convert__out` — the answer, in the accent.
class _Result extends StatelessWidget {
  const _Result({required this.text, required this.spoken});

  final String text;
  final String spoken;

  @override
  Widget build(BuildContext context) => LumeLtr(
    // `text-align: end` on an element that is itself `direction: ltr`
    // (`shared.css:646-652`) resolves to the right, in every page direction.
    child: Text(
      text,
      key: LumeConverterTool.resultKey,
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      semanticsLabel: spoken,
      style: _figureStyle(context).copyWith(color: context.lume.accent),
    ),
  );
}

/// `.convert__swap` — a 34-point accent circle between the two sides.
class _Swap extends StatelessWidget {
  const _Swap({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    return LumePressable(
      key: LumeConverterTool.swapKey,
      onTap: onTap,
      semanticLabel: label,
      borderRadius: LumeRadius.full,
      // The circle is the reference's 34; the target around it is §9's 44,
      // and `LumePressable` only floors the height, so the width is said
      // here. The ten extra points come out of the two flexible sides
      // rather than off the end of the card — the same trade as the Tip &
      // Split stepper (D6/C62), and an accessibility adaptation rather than
      // parity.
      child: SizedBox(
        width: LumeSpace.tap,
        child: Center(
          child: Container(
            width: LumeConverterTool.swapSize,
            height: LumeConverterTool.swapSize,
            decoration: BoxDecoration(
              color: lume.tintAccent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: LumeIcon(
                LumeIcons.swap,
                size: LumeConverterTool.swapIcon,
                color: lume.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
