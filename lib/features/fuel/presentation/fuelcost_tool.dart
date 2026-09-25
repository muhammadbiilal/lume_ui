/// Fuel Cost — the reference tool for a calculator over Fuel Prices' own
/// fixture, shared rather than duplicated.
///
/// `tools/money/fuelcost.tool.js` over `context.js` `fuelCost()`: distance,
/// fuel economy, price and the number of people; the trip's total cost, the
/// fuel it takes, the cost per person and per distance unit; and how the
/// same trip compares solo, shared and as a round trip. Worked out by
/// [LumeFuelCostRules]; see that library for the one place this port draws
/// less than the reference does (its own fabricated "history" rows).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_field_grid.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_numbers.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/fuel_fixtures.dart';
import '../domain/fuelcost_maths.dart';
import 'fuel_text.dart';

class LumeFuelcostTool extends ConsumerStatefulWidget {
  const LumeFuelcostTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeFuelcostTool(request: request);

  static const String id = 'fuelcost';

  static const Key distanceKey = ValueKey<String>('fuelcost.distance');
  static const Key economyKey = ValueKey<String>('fuelcost.economy');
  static const Key priceKey = ValueKey<String>('fuelcost.price');
  static const Key peopleKey = ValueKey<String>('fuelcost.people');
  static const Key summaryKey = ValueKey<String>('fuelcost.summary');
  static const Key compareKey = ValueKey<String>('fuelcost.compare');

  static String jsNumber(double v) => lumeJsNumber(v);
  static double parse(String text) => lumeFieldNumber(text);

  @override
  ConsumerState<LumeFuelcostTool> createState() => _LumeFuelcostToolState();
}

class _LumeFuelcostToolState extends ConsumerState<LumeFuelcostTool> {
  static const String _id = LumeFuelcostTool.id;

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
  /// field is zero, matching Zakat's own `_money`. Unlike a liability, a
  /// fuel price has no meaningful negative reading, so a typed negative is
  /// zero here too rather than a signed total the summary would have to
  /// explain.
  LumeMoney _money(TextEditingController c, LumeCurrency currency) {
    final double v = LumeFuelcostTool.parse(c.text);
    if (!v.isFinite || v < 0) return LumeMoney.zero(currency);
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
    final bool imperial = f.units == LumeUnits.imperial;
    // `D.fuelFor(P().country)` — the same market Fuel Prices itself reads
    // for this reader, so the two tools never disagree on the price or the
    // currency it is in.
    final LumeFuelMarket market = LumeFuel.forCountry(r.user.country);
    final LumeCurrency currency =
        LumeCurrency.tryOf(market.currency) ?? LumeCurrency.of('USD');
    final String distUnit = imperial ? l.unitMi : l.unitKm;
    final String econUnit = imperial ? l.unitMpg : l.unitKmpl;

    final TextEditingController distance = _field(
      'dist',
      () => LumeFuelcostTool.jsNumber(
        LumeFuelCostRules.defaultDistance(imperial: imperial),
      ),
    );
    final TextEditingController economy = _field(
      'econ',
      () => LumeFuelcostTool.jsNumber(
        LumeFuelCostRules.defaultEconomy(imperial: imperial),
      ),
    );
    final TextEditingController price = _field(
      'price',
      () => LumeFuelcostTool.jsNumber(
        LumeFuelCostRules.defaultPrice(r.user.country),
      ),
    );
    final TextEditingController people = _field(
      'people',
      () => LumeFuelcostTool.jsNumber(LumeFuelCostRules.defaultPeople),
    );

    final double distanceRaw = LumeFuelcostTool.parse(distance.text);
    final double economyRaw = LumeFuelcostTool.parse(economy.text);
    final double peopleRaw = LumeFuelcostTool.parse(people.text);

    final LumeFuelCostResult result = LumeFuelCostRules.compute(
      LumeFuelCostInputs(
        distance: distanceRaw,
        economy: economyRaw,
        price: _money(price, currency),
        people: peopleRaw,
      ),
    );

    String money(LumeMoney m) =>
        f.money(m.minor / currency.scale, code: currency.code, decimals: 2);
    String distLabel(double v) => '${f.number(v, decimals: 0)} $distUnit';
    String scenarioLabel(LumeFuelCostScenarioKind k) => switch (k) {
      LumeFuelCostScenarioKind.solo => l.fuelcostScSolo,
      LumeFuelCostScenarioKind.shared => l.fuelcostScShared(
        f.number(peopleRaw, decimals: 0),
      ),
      LumeFuelCostScenarioKind.roundTrip => l.fuelcostScReturn,
    };

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.reminder,
        text: '${l.fuelcostTotal}: ${money(result.total)}',
        source: l.fuelcostForTrip(distLabel(distanceRaw)),
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
                  onTap: () => showLumePersonalise(context),
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.toolInputs,
            child: LumeCard(
              child: LumeFieldGrid(
                children: <Widget>[
                  LumeToolField(
                    key: LumeFuelcostTool.distanceKey,
                    label: l.fuelcostDistance,
                    controller: distance,
                    suffix: distUnit,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('dist', v),
                  ),
                  LumeToolField(
                    key: LumeFuelcostTool.economyKey,
                    label: l.fuelcostEconomy,
                    controller: economy,
                    suffix: econUnit,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('econ', v),
                  ),
                  LumeToolField(
                    key: LumeFuelcostTool.priceKey,
                    label: l.fuelcostPrice,
                    controller: price,
                    prefix: currency.code,
                    hint: l.fuelcostPriceHint,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('price', v),
                  ),
                  LumeToolField(
                    key: LumeFuelcostTool.peopleKey,
                    label: l.fuelcostPeople,
                    controller: people,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('people', v),
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeFuelcostTool.summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: l.fuelcostTotal,
              value: money(result.total),
              caption: l.fuelcostForTrip(distLabel(distanceRaw)),
              stats: <LumeStat>[
                LumeStat(
                  value:
                      '${f.number(result.fuelUsed, decimals: 1)} '
                      '${LumeFuelStrings.unit(l, market.unit)}',
                  label: l.fuelcostUsed,
                ),
                LumeStat(
                  value: money(result.perPerson),
                  label: l.fuelcostPerPerson,
                ),
                LumeStat(
                  value: money(result.perUnit),
                  label: l.fuelcostPerUnit(distUnit),
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.fuelcostCompare,
            child: LumeTable(
              key: LumeFuelcostTool.compareKey,
              label: l.fuelcostCompare,
              columns: <LumeColumn>[
                LumeColumn(label: l.fuelcostScenario),
                LumeColumn(label: l.fuelcostConsumption, numeric: true),
                LumeColumn(label: l.fuelcostCost, numeric: true),
              ],
              rows: <List<String>>[
                for (final LumeFuelCostScenario s in result.scenarios)
                  <String>[
                    scenarioLabel(s.kind),
                    '${f.number(s.fuelUsed, decimals: 1)} '
                        '${LumeFuelStrings.unit(l, market.unit)}',
                    money(s.cost),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
