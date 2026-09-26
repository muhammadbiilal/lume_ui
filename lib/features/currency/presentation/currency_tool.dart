/// Currency — `tools/everyday/currency.tool.js` over `context.js`
/// `currencyBoard()`.
///
/// The reference composes four things: a convert card (an amount on one
/// side, the answer on the other, a round swap between them, and a
/// "1 FROM = X TO" line under it), a search field, a "Popular" board of
/// majors converted from the active `from`, and a 30-day chart of the active
/// pair. All figures come from [LumeCurrencyBoard], built on the shared
/// [lumeRatePerUsd] table exactly as `goldrates_fixtures.dart`'s
/// `LumeMetals` is.
///
/// ## The one addition: a currency picker
///
/// The reference has no way to choose `from` or `to` at all — `cvswap` is
/// the only action the board's state ever takes, and it only exchanges
/// whichever two currencies are already active. That leaves a "converter"
/// that can only ever convert the reader's own currency to one fixed
/// alternative. `converter.tool.js` (its sibling, same markup, same
/// `context.js` module) was already corrected the same way for the same
/// reason: "There is a unit picker. The reference has none at all... Both
/// units are chosen here, from a sheet" — recorded there as correction 4,
/// with its own new strings (`convertChooseUnit`, "the unit picker the
/// reference does not have"). This screen carries the identical correction
/// for the identical reason: both sides are chosen from a sheet, over every
/// currency [LumeCurrencyBoard.allCodes] covers, and swap keeps working
/// exactly as the reference has it. Nothing about the reference's own
/// arithmetic, board, or chart changes.
///
/// ## The one subtraction: "Recent"
///
/// See `currency_maths.dart`'s header — the same correction
/// `converter.tool.js` already carries for the same fabricated-history
/// reason, not repeated here.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_numerals.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_pressable.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_spark.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../../tools/presentation/tool_strings.dart';
import '../domain/currency_maths.dart';
import 'currency_strings.dart';

class LumeCurrencyTool extends ConsumerStatefulWidget {
  const LumeCurrencyTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeCurrencyTool(request: request);

  static const String id = 'currency';

  static const Key cardKey = ValueKey<String>('currency.card');
  static const Key amountKey = ValueKey<String>('currency.amount');
  static const Key swapKey = ValueKey<String>('currency.swap');
  static const Key fromKey = ValueKey<String>('currency.from');
  static const Key toKey = ValueKey<String>('currency.to');
  static const Key resultKey = ValueKey<String>('currency.result');
  static const Key rateKey = ValueKey<String>('currency.rate');
  static const Key searchKey = ValueKey<String>('currency.search');
  static const Key popularKey = ValueKey<String>('currency.popular');
  static const Key emptyKey = ValueKey<String>('currency.empty');
  static const Key chartKey = ValueKey<String>('currency.chart');
  static const Key sheetKey = ValueKey<String>('currency.sheet');
  static const Key sheetSearchKey = ValueKey<String>('currency.sheet.search');
  static const Key sheetEmptyKey = ValueKey<String>('currency.sheet.empty');

  /// One choice in the currency sheet.
  static Key optionKey(String code) =>
      ValueKey<String>('currency.option.$code');

  /// `fieldsFor('currency', { amount: 100 })`.
  static const String defaultAmount = '100';

  static LumeDeltaDirection directionOf(num n) => n > 0
      ? LumeDeltaDirection.up
      : n < 0
      ? LumeDeltaDirection.down
      : LumeDeltaDirection.flat;

  static LumeTrend trendOf(num n) => switch (directionOf(n)) {
    LumeDeltaDirection.up => LumeTrend.up,
    LumeDeltaDirection.down => LumeTrend.down,
    LumeDeltaDirection.flat => LumeTrend.flat,
  };

  /// `(p.code + ' ' + p.name).toLowerCase().indexOf(query)`, matched in the
  /// reader's language and in English (§47) — the Popular board's own
  /// search, over the (already short) board the active `from` leaves.
  static List<LumeCurrencyPair> filter(
    List<LumeCurrencyPair> pairs, {
    required String query,
    required List<AppLocalizations> languages,
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeCurrencyPair>[
      for (final LumeCurrencyPair p in pairs)
        if (q.isEmpty ||
            languages.any(
              (AppLocalizations l) =>
                  '${p.code} ${LumeCurrencyStrings.currency(l, p.code)}'
                      .toLowerCase()
                      .contains(q),
            ))
          p,
    ];
  }

  @override
  ConsumerState<LumeCurrencyTool> createState() => _LumeCurrencyToolState();
}

class _LumeCurrencyToolState extends ConsumerState<LumeCurrencyTool> {
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _amount = TextEditingController(
    text:
        _session.read(LumeCurrencyTool.id, 'amount') ??
        LumeCurrencyTool.defaultAmount,
  );
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeCurrencyTool.id, 'q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _amount.dispose();
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _setAmount(String v) =>
      setState(() => _session.write(LumeCurrencyTool.id, 'amount', v));

  void _search(String q) =>
      setState(() => _session.write(LumeCurrencyTool.id, 'q', q));

  void _swap(String from, String to) => setState(() {
    _session.write(LumeCurrencyTool.id, 'from', to);
    _session.write(LumeCurrencyTool.id, 'to', from);
  });

  /// `cvswap`, generalised: the reference only ever exchanges the two active
  /// currencies; this also lets either side become any of
  /// [LumeCurrencyBoard.allCodes], and swaps in place of double-booking a
  /// currency on both sides — the same rule `converter.tool.js`'s own
  /// `_pickUnit` keeps.
  Future<void> _pickCurrency(String key, String from, String to) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String currentOfKey = key == 'from' ? from : to;
    final String currentOfOther = key == 'from' ? to : from;
    final String otherKey = key == 'from' ? 'to' : 'from';
    final String? picked = await showLumeSheet<String>(
      context: context,
      barrierLabel: l.currencyChooseCurrency,
      child: _CurrencySheet(current: currentOfKey),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _session.write(LumeCurrencyTool.id, key, picked);
      if (picked == currentOfOther) {
        _session.write(LumeCurrencyTool.id, otherKey, currentOfKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();

    // `L.currencyCode()` — the reader's own currency, the board's own
    // opening `from`.
    final String home =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;
    final String from = _session.read(LumeCurrencyTool.id, 'from') ?? home;
    final String to =
        _session.read(LumeCurrencyTool.id, 'to') ??
        LumeCurrencyBoard.defaultTo(home);

    final LumeCurrencyBoard board = LumeCurrencyBoard.forPair(from, to);
    final double? result = LumeCurrencyBoard.convert(board.rate, _amount.text);
    final String resultText = result == null
        ? '—'
        : f.number(result, decimals: 2);
    final String rateText = f.number(board.rate, decimals: 4);

    final List<LumeCurrencyPair> pairs = LumeCurrencyTool.filter(
      board.popular,
      query: _query.text,
      languages: <AppLocalizations>{
        l,
        lookupAppLocalizations(const Locale('en')),
      }.toList(),
    );

    void showRate(LumeCurrencyPair p) => showLumeToast(
      context,
      LumeToastData(
        tone: LumeToastTone.info,
        // The template already says "1 {from}"; passing "1 $from" drew
        // "1 1 PKR = …".
        message: l.currencyRateLine(
          from,
          f.number(p.rate, decimals: 3),
          p.code,
        ),
      ),
    );

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.quote,
        text: l.currencyRateLine(from, rateText, to),
        source: '${LumeToolStrings.source(l, r.feature)} · ${f.dateLong(now)}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeCard(
              key: LumeCurrencyTool.cardKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ConvertSide(
                          codeKey: LumeCurrencyTool.fromKey,
                          label: l.convertFrom,
                          code: from,
                          name: LumeCurrencyStrings.currency(l, from),
                          onPick: () => _pickCurrency('from', from, to),
                          figure: _Amount(
                            controller: _amount,
                            label: l.convertAmount,
                            onChanged: _setAmount,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Swap(label: l.convertSwap, onTap: () => _swap(from, to)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ConvertSide(
                          codeKey: LumeCurrencyTool.toKey,
                          label: l.convertTo,
                          code: to,
                          name: LumeCurrencyStrings.currency(l, to),
                          onPick: () => _pickCurrency('to', from, to),
                          toSide: true,
                          figure: _Result(
                            text: resultText,
                            spoken: l.convertEquals(
                              '${_amount.text} $from',
                              '$resultText $to',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.currencyRateLine(from, rateText, to),
                    key: LumeCurrencyTool.rateKey,
                    style: LumeType.natural(
                      context,
                      context.lumeType.metaSmall,
                    ).copyWith(color: context.lume.text3),
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LumeSearchField(
                key: LumeCurrencyTool.searchKey,
                controller: _query,
                focusNode: _searchFocus,
                placeholder: l.ratesSearch,
                onChanged: _search,
              ),
            ),
          ),
          LumeToolSection(
            title: l.persPopular,
            child: pairs.isEmpty
                ? LumeToolState(
                    key: LumeCurrencyTool.emptyKey,
                    icon: LumeIcons.currency,
                    title: l.ratesNoMatch,
                    text: l.ratesNoMatchText,
                  )
                : LumeRows(
                    key: LumeCurrencyTool.popularKey,
                    children: <Widget>[
                      for (final LumeCurrencyPair p in pairs)
                        LumeRichRow(
                          logo: p.flag,
                          title: p.code,
                          subtitle: LumeCurrencyStrings.currency(l, p.code),
                          trailing: LumeSparkline(
                            values: p.spark,
                            trend: LumeCurrencyTool.trendOf(p.pct),
                          ),
                          value: f.number(p.rate, decimals: 3),
                          delta: LumeDelta(
                            text: f.signedPercent(p.pct),
                            direction: LumeCurrencyTool.directionOf(p.pct),
                          ),
                          onTap: () => showRate(p),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.currencyChart('$from/$to'),
            child: LumeCard(
              child: LumeLineChart(
                key: LumeCurrencyTool.chartKey,
                values: board.history,
                label: l.currencyChart('$from/$to'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A sheet over [LumeCurrencyBoard.allCodes], searchable — the same
/// "choose it from a sheet" shape `converter.tool.js`'s own `_pickUnit`
/// sheet uses, extended with a search field because 145 currencies, unlike a
/// category's handful of units, are too many to scan unaided.
class _CurrencySheet extends StatefulWidget {
  const _CurrencySheet({required this.current});

  final String current;

  @override
  State<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<_CurrencySheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String q = _query.text.trim().toLowerCase();
    final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
    final List<String> codes = <String>[
      for (final String code in LumeCurrencyBoard.allCodes)
        if (q.isEmpty ||
            '$code ${LumeCurrencyStrings.currency(l, code)}'
                .toLowerCase()
                .contains(q) ||
            '$code ${LumeCurrencyStrings.currency(en, code)}'
                .toLowerCase()
                .contains(q))
          code,
    ];

    return LumeSheet(
      tall: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            child: LumeSearchField(
              key: LumeCurrencyTool.sheetSearchKey,
              controller: _query,
              placeholder: l.ratesSearch,
              semanticLabel: l.currencyChooseCurrency,
              autofocus: true,
              onChanged: (String _) => setState(() {}),
            ),
          ),
          Flexible(
            child: codes.isEmpty
                ? Padding(
                    key: LumeCurrencyTool.sheetEmptyKey,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: LumeToolState(
                      icon: LumeIcons.currency,
                      title: l.ratesNoMatch,
                      text: l.ratesNoMatchText,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      key: LumeCurrencyTool.sheetKey,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (final String code in codes)
                          LumeRadioRow(
                            key: LumeCurrencyTool.optionKey(code),
                            label: code,
                            subtitle:
                                LumeCurrencyStrings.currency(l, code) == code
                                ? null
                                : LumeCurrencyStrings.currency(l, code),
                            selected: code == widget.current,
                            onTap: () => Navigator.of(context).pop(code),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// `.convert__side` — the code, the figure, the currency's name. See
/// `converter_tool.dart`'s own `_ConvertSide`, which this mirrors exactly
/// (same geometry, same reasoning for why neither half takes §9's 44-point
/// floor) with a currency code where that one has a unit symbol.
class _ConvertSide extends StatelessWidget {
  const _ConvertSide({
    required this.codeKey,
    required this.label,
    required this.code,
    required this.name,
    required this.figure,
    required this.onPick,
    this.toSide = false,
  });

  final Key codeKey;

  /// `l.convertFrom` / `l.convertTo`.
  final String label;

  final String code;
  final String name;
  final Widget figure;
  final VoidCallback onPick;
  final bool toSide;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final TextAlign align = toSide ? TextAlign.end : TextAlign.start;
    final String spoken = '$label, $name';

    final Widget codeText = Text(
      code,
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

    final Widget nameText = Text(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumePressable(
          key: codeKey,
          onTap: onPick,
          semanticLabel: spoken,
          minSize: 0,
          borderRadius: LumeRadius.brXs,
          child: ExcludeSemantics(child: codeText),
        ),
        const SizedBox(height: 4),
        figure,
        const SizedBox(height: 3),
        LumePressable(
          onTap: onPick,
          semanticLabel: spoken,
          minSize: 0,
          borderRadius: LumeRadius.brXs,
          child: ExcludeSemantics(child: nameText),
        ),
      ],
    );
  }
}

TextStyle _figureStyle(BuildContext context) => LumeType.numeric(
  LumeType.tracked(
    LumeType.natural(
      context,
      context.lumeType.display,
    ).copyWith(fontWeight: FontWeight.w800),
    -0.045,
  ),
);

/// `.convert__input` — the amount, typed. See `converter_tool.dart`'s
/// `_Amount`: a bare input at the reference's own 28/800, not a
/// [LumeToolField].
class _Amount extends StatelessWidget {
  const _Amount({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
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
            key: LumeCurrencyTool.amountKey,
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            maxLines: 1,
            style: _figureStyle(context).copyWith(color: lume.text),
            cursorColor: lume.accent,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹.,٫]')),
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
    child: Text(
      text,
      key: LumeCurrencyTool.resultKey,
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
      key: LumeCurrencyTool.swapKey,
      onTap: onTap,
      semanticLabel: label,
      borderRadius: LumeRadius.full,
      child: SizedBox(
        width: LumeSpace.tap,
        child: Center(
          child: Container(
            width: LumeSpace.circleBack,
            height: LumeSpace.circleBack,
            decoration: BoxDecoration(
              color: lume.tintAccent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: LumeIcon(
                LumeIcons.swap,
                size: LumeSpace.iconSm,
                color: lume.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
