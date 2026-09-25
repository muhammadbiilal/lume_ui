/// Zakat Calculator — the reference tool for a calculator over fixture
/// metal prices, shared with Currency & Gold rather than duplicated.
///
/// `tools/islamic/zakat.tool.js` over `context.js` `zakat()`: six asset
/// fields (cash, gold, silver, investments, business, liabilities), the
/// payable figure and whether the reader is above nisab, and the eight-row
/// breakdown. Worked out by [LumeZakatRules]; see that library for the one
/// place this port draws something other than what the reference draws (the
/// nisab figure shown, not the nisab figure computed).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/fixtures/lume_reference_rates.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_field_grid.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../goldrates/data/goldrates_fixtures.dart';
import '../../tools/application/tool_numbers.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/zakat_maths.dart';

class LumeZakatTool extends ConsumerStatefulWidget {
  const LumeZakatTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeZakatTool(request: request);

  static const String id = 'zakat';

  static const Key cashKey = ValueKey<String>('zakat.cash');
  static const Key goldKey = ValueKey<String>('zakat.gold');
  static const Key silverKey = ValueKey<String>('zakat.silver');
  static const Key investmentsKey = ValueKey<String>('zakat.investments');
  static const Key businessKey = ValueKey<String>('zakat.business');
  static const Key liabilitiesKey = ValueKey<String>('zakat.liabilities');
  static const Key summaryKey = ValueKey<String>('zakat.summary');
  static const Key breakdownKey = ValueKey<String>('zakat.breakdown');

  /// A number the way `String(n)` writes it.
  static String jsNumber(double v) => lumeJsNumber(v);

  /// `Number(text)` — an empty field is zero.
  static double parse(String text) => lumeFieldNumber(text);

  @override
  ConsumerState<LumeZakatTool> createState() => _LumeZakatToolState();
}

class _LumeZakatToolState extends ConsumerState<LumeZakatTool> {
  static const String _id = LumeZakatTool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{};

  TextEditingController _field(String key, String Function() fallback) =>
      _fields[key] ??= TextEditingController(
        text: _session.field(_id, key, fallback),
      );

  @override
  void dispose() {
    for (final TextEditingController c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _edited(String key, String value) =>
      setState(() => _session.write(_id, key, value));

  /// An entered field as [LumeMoney] of [currency] — a blank or unreadable
  /// field is zero, matching [LumeZakatTool.parse]'s `Number(text) || 0`.
  /// Never clamped beyond that: the reference reads whatever `Number()`
  /// makes of the field, including a negative one, and so does this —
  /// only a non-finite result (typing the word "Infinity") is refused,
  /// never a thrown [LumeMoneyException] over a half-typed figure.
  LumeMoney _money(TextEditingController c, LumeCurrency currency) {
    final double v = LumeZakatTool.parse(c.text);
    if (!v.isFinite) return LumeMoney.zero(currency);
    return LumeMoney.sum((v * currency.scale).round(), currency);
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    // `L.currencyCode()` — the country's currency, as GoldRates itself reads
    // it, so the two tools never disagree over what currency the reader's
    // figures are in.
    final String ccy =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;
    final LumeCurrency currency =
        LumeCurrency.tryOf(ccy) ?? LumeCurrency.of('USD');
    final double usdRate = lumeRatePerUsd(currency.code);
    final LumeMetals metals = LumeMetals.forCurrency(currency.code);

    final TextEditingController cash = _field(
      'cash',
      () => LumeZakatTool.jsNumber(
        LumeZakatRules.openingCash(usdRate, currency).minor / currency.scale,
      ),
    );
    final TextEditingController gold = _field(
      'gold',
      () => LumeZakatTool.jsNumber(LumeZakatRules.defaultGoldGrams),
    );
    final TextEditingController silver = _field(
      'silver',
      () => LumeZakatTool.jsNumber(LumeZakatRules.defaultSilverGrams),
    );
    final TextEditingController investments = _field(
      'inv',
      () => LumeZakatTool.jsNumber(
        LumeZakatRules.openingInvestments(usdRate, currency).minor /
            currency.scale,
      ),
    );
    final TextEditingController business = _field(
      'biz',
      () => LumeZakatTool.jsNumber(0),
    );
    final TextEditingController liabilities = _field(
      'liab',
      () => LumeZakatTool.jsNumber(
        LumeZakatRules.openingLiabilities(usdRate, currency).minor /
            currency.scale,
      ),
    );

    // Not clamped beyond finite, for the same reason `_money` is not: the
    // reference reads whatever `Number(f.gold)` makes of the field.
    final double goldRaw = LumeZakatTool.parse(gold.text);
    final double silverRaw = LumeZakatTool.parse(silver.text);
    final double goldGrams = goldRaw.isFinite ? goldRaw : 0;
    final double silverGrams = silverRaw.isFinite ? silverRaw : 0;
    final LumeZakatResult z = LumeZakatRules.compute(
      inputs: LumeZakatInputs(
        cash: _money(cash, currency),
        goldGrams: goldGrams,
        silverGrams: silverGrams,
        investments: _money(investments, currency),
        business: _money(business, currency),
        liabilities: _money(liabilities, currency),
      ),
      metals: metals,
    );

    // `moneyRaw(v, ccy, 0)` — the reference's own display for every zakat
    // figure is whole currency units, never minor units; `LumeMoney` keeps
    // the arithmetic exact, and only this boundary rounds for the eye.
    String money(LumeMoney m) {
      final String sign = m.isNegative ? '−' : '';
      return '$sign${f.money(m.magnitude.minor / currency.scale, code: currency.code)}';
    }

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.reminder,
        text: '${l.zakatPayable}: ${money(z.due)}',
        source:
            '${l.zakatRateLabel}: ${f.percent(LumeZakatRules.rate * 100, decimals: 1)}',
      ),
      // `exportRows('zakat')` — the eight breakdown rows, figures rounded.
      exportFile: () => LumeExportFile.csv(
        tool: _id,
        day: LumeClockScope.of(context).now(),
        rows: <List<Object?>>[
          <Object?>[l.zakatItem, l.commonValue, currency.code],
          for (final LumeZakatLine line in z.lines)
            <Object?>[
              _lineLabel(l, f, line),
              (line.amount.minor / currency.scale).round(),
              currency.code,
            ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              items: <LumeContextItem>[
                LumeContextItem(
                  label: LumeToolScreen.countryName(
                    context,
                    ref,
                    r.user.country,
                  ),
                  icon: LumeIcons.globe,
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: l.ratesOpenMarket),
              ],
            ),
          ),
          LumeToolSection(
            title: l.zakatAssets,
            child: LumeCard(
              child: LumeFieldGrid(
                wide: const <int>{0},
                children: <Widget>[
                  LumeToolField(
                    key: LumeZakatTool.cashKey,
                    label: l.zakatCash,
                    controller: cash,
                    prefix: currency.code,
                    kind: LumeFieldKind.money,
                    wide: true,
                    onChanged: (String v) => _edited('cash', v),
                  ),
                  LumeToolField(
                    key: LumeZakatTool.goldKey,
                    label: l.zakatGold,
                    controller: gold,
                    suffix: l.unitGram,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('gold', v),
                  ),
                  LumeToolField(
                    key: LumeZakatTool.silverKey,
                    label: l.zakatSilver,
                    controller: silver,
                    suffix: l.unitGram,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('silver', v),
                  ),
                  LumeToolField(
                    key: LumeZakatTool.investmentsKey,
                    label: l.zakatInvestments,
                    controller: investments,
                    prefix: currency.code,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('inv', v),
                  ),
                  LumeToolField(
                    key: LumeZakatTool.businessKey,
                    label: l.zakatBusiness,
                    controller: business,
                    prefix: currency.code,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('biz', v),
                  ),
                  LumeToolField(
                    key: LumeZakatTool.liabilitiesKey,
                    label: l.zakatLiabilities,
                    controller: liabilities,
                    prefix: currency.code,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('liab', v),
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeZakatTool.summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: l.zakatPayable,
              value: money(z.due),
              caption: z.eligible ? l.zakatAboveNisab : l.zakatBelowNisab,
              stats: <LumeStat>[
                LumeStat(value: money(z.net), label: l.zakatNetAssets),
                LumeStat(value: money(z.nisab), label: l.zakatNisab),
                LumeStat(
                  value: f.percent(LumeZakatRules.rate * 100, decimals: 1),
                  label: l.zakatRateLabel,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.zakatBreakdown,
            child: LumeTable(
              key: LumeZakatTool.breakdownKey,
              label: l.zakatBreakdown,
              columns: <LumeColumn>[
                LumeColumn(label: l.zakatItem),
                LumeColumn(label: l.commonValue, numeric: true),
              ],
              rows: <List<String>>[
                for (final LumeZakatLine line in z.lines)
                  <String>[_lineLabel(l, f, line), money(line.amount)],
              ],
            ),
          ),
          LumeToolSection(
            child: LumeButtonRow(
              children: <Widget>[
                LumeButton.accent(
                  label: l.commonExport,
                  icon: LumeIcons.download,
                  onPressed: () => _host.currentState?.export(),
                ),
                LumeButton(
                  label: l.commonShare,
                  icon: LumeIcons.share,
                  onPressed: () => _host.currentState?.share(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `t('zakat.gold') + ' (' + f.gold + ' ' + t('unit.gram') + ')'` — a
  /// weight row names its own grams; every other row is its bare label.
  String _lineLabel(AppLocalizations l, LumeFormatting f, LumeZakatLine line) {
    String label(LumeZakatLineKind k) => switch (k) {
      LumeZakatLineKind.cash => l.zakatCash,
      LumeZakatLineKind.gold => l.zakatGold,
      LumeZakatLineKind.silver => l.zakatSilver,
      LumeZakatLineKind.investments => l.zakatInvestments,
      LumeZakatLineKind.business => l.zakatBusiness,
      LumeZakatLineKind.liabilities => l.zakatLiabilities,
      LumeZakatLineKind.netAssets => l.zakatNetAssets,
      LumeZakatLineKind.payable => l.zakatPayable,
    };
    final double? grams = line.grams;
    return grams == null
        ? label(line.kind)
        : '${label(line.kind)} (${f.number(grams)} ${l.unitGram})';
  }
}
